#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTS_YAML="${SCRIPT_DIR}/charts.yaml"
CACHE_DIR="${SCRIPT_DIR}/.chart-cache"

cd "${SCRIPT_DIR}"

SELECTED_CHARTS=()
if [ $# -gt 0 ]; then
    SELECTED_CHARTS=("${@}")
fi

should_build() {
    if [ ${#SELECTED_CHARTS[@]} -eq 0 ]; then return 0; fi
    for s in "${SELECTED_CHARTS[@]}"; do [ "$s" = "$1" ] && return 0; done
    return 1
}

ensure_checkout() {
    local repo="$1" commit="$2"
    local repo_hash
    repo_hash=$(printf '%s' "$repo" | md5sum | cut -d' ' -f1)
    local clone_dir="${CACHE_DIR}/repos/${repo_hash}"
    local checkout_dir="${CACHE_DIR}/checkouts/${repo_hash}/${commit}"

    if [ -f "$checkout_dir/.git" ]; then echo "$checkout_dir"; return; fi

    if [ ! -d "$clone_dir/.git" ]; then
        mkdir -p "${CACHE_DIR}/repos"
        echo "Cloning ${repo} ..." >&2
        git clone "$repo" "$clone_dir"
    else
        git -C "$clone_dir" fetch origin >&2
    fi

    mkdir -p "${CACHE_DIR}/checkouts/${repo_hash}"
    git -C "$clone_dir" worktree prune
    git -C "$clone_dir" worktree add --detach "$checkout_dir" "$commit" >&2
    echo "$checkout_dir"
}

resolve_field() {
    local val
    val=$(yq ".charts.\"$1\".$2 // \"\"" "$CHARTS_YAML")
    echo "${val:-$3}"
}

DEFAULT_REPO=$(yq '.defaults.repo' "$CHARTS_YAML")
DEFAULT_COMMIT=$(yq '.defaults.commit' "$CHARTS_YAML")
DEFAULT_SUBMODULE=$(yq '.defaults.submodule' "$CHARTS_YAML")

mapfile -t ALL_CHART_NAMES < <(yq '.charts | keys | .[]' "$CHARTS_YAML")

needs_submodule=false
for chart_name in "${ALL_CHART_NAMES[@]}"; do
    should_build "$chart_name" || continue
    commit=$(resolve_field "$chart_name" "commit" "")
    if [ -z "$commit" ]; then
        needs_submodule=true
        break
    fi
done

if $needs_submodule; then
    echo "Syncing submodule ${DEFAULT_SUBMODULE} to ${DEFAULT_COMMIT:0:12} ..."
    git -C "${SCRIPT_DIR}/${DEFAULT_SUBMODULE}" fetch origin
    git -C "${SCRIPT_DIR}/${DEFAULT_SUBMODULE}" checkout --detach "$DEFAULT_COMMIT"
fi

declare -A OVERRIDE_GROUPS

for chart_name in "${ALL_CHART_NAMES[@]}"; do
    should_build "$chart_name" || continue

    commit=$(resolve_field "$chart_name" "commit" "")
    path=$(resolve_field "$chart_name" "path" "$chart_name")

    if [ -z "$commit" ]; then
        echo "Building chart: ${chart_name} (from submodule)"
        helm package "${SCRIPT_DIR}/${DEFAULT_SUBMODULE}/${path}" \
            --dependency-update --destination "${SCRIPT_DIR}"
    else
        repo=$(resolve_field "$chart_name" "repo" "$DEFAULT_REPO")
        OVERRIDE_GROUPS["${repo}|${commit}"]+="${chart_name}:${path} "
    fi
done

for key in "${!OVERRIDE_GROUPS[@]}"; do
    IFS='|' read -r repo commit <<< "$key"
    checkout_dir=$(ensure_checkout "$repo" "$commit")

    for entry in ${OVERRIDE_GROUPS["$key"]}; do
        IFS=':' read -r chart_name chart_path <<< "$entry"
        echo "Building chart: ${chart_name} (from ${commit:0:12})"
        helm package "${checkout_dir}/${chart_path}" \
            --dependency-update --destination "${SCRIPT_DIR}"
    done
done

if should_build "openstack-exporter"; then
    echo "Building Chart for openstack-exporter"
    helm package ./openstack-exporter/charts/prometheus-openstack-exporter --dependency-update
fi

for chart in cert-management external-dns-management; do
    if should_build "gardener-$chart"; then
        echo "Build Chart for gardener-$chart"
        helm package ./gardener-$chart/charts/${chart} --dependency-update
    fi
done

if should_build "nodepool-labels-operator"; then
    echo "Building Chart for Node-label-operator"
    helm package ./nodepool-labels-operator/charts/nodepool-labels-operator/ --dependency-update
fi

if should_build "gardener-all"; then
    echo "Building Gardener charts"
    bash build-gardener-charts.sh
fi

helm repo index . --url https://cloudification-io.github.io --merge index.yaml
sed -i 's/file:.*helm-toolkit/https:\/\/cloudification-io.github.io/g' index.yaml
