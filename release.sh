#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTS_YAML="${SCRIPT_DIR}/charts.yaml"
CACHE_DIR="${SCRIPT_DIR}/.chart-cache"
REPO_URL="https://cloudification-io.github.io"
EXTRA_TARGETS=(openstack-exporter gardener-cert-management gardener-external-dns-management nodepool-labels-operator gardener-all)

cd "${SCRIPT_DIR}"

usage() {
    cat >&2 <<USAGE
Usage:
  $0 <release> [chart...]   build openstack-helm charts of a release from charts.yaml
  $0 <target...>            build non-OpenStack charts: ${EXTRA_TARGETS[*]}

Releases: $(yq '.releases | keys | join(" ")' "$CHARTS_YAML")
USAGE
    exit 1
}

[ $# -gt 0 ] || usage

export BUILD_DIR
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

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

in_list() {
    local needle="$1" item; shift
    for item in "$@"; do [ "$item" = "$needle" ] && return 0; done
    return 1
}

build_release() {
    local release="$1"; shift
    local default_repo default_commit
    default_repo=$(yq ".releases.\"${release}\".repo // .repo" "$CHARTS_YAML")
    default_commit=$(yq -e ".releases.\"${release}\".commit" "$CHARTS_YAML" 2>/dev/null) \
        || { echo "Release ${release} has no commit in charts.yaml" >&2; exit 1; }

    local name repo commit path
    for name in "$@"; do
        yq -e ".releases.\"${release}\".charts | has(\"${name}\")" "$CHARTS_YAML" >/dev/null 2>&1 \
            || { echo "Unknown chart '${name}' in release ${release}" >&2; exit 1; }
    done

    local -A groups
    while IFS=';' read -r name repo commit path; do
        if [ $# -gt 0 ] && ! in_list "$name" "$@"; then continue; fi
        groups["${repo:-$default_repo}|${commit:-$default_commit}"]+="${name};${path}"$'\n'
    done < <(yq -r ".releases.\"${release}\".charts | to_entries[] | [.key, (.value.repo // \"\"), (.value.commit // \"\"), (.value.path // .key)] | join(\";\")" "$CHARTS_YAML")

    local key checkout_dir
    for key in "${!groups[@]}"; do
        IFS='|' read -r repo commit <<< "$key"
        checkout_dir=$(ensure_checkout "$repo" "$commit")
        while IFS=';' read -r name path; do
            [ -n "$name" ] || continue
            echo "Building chart: ${name} ${release} (from ${commit:0:12})"
            git -C "$checkout_dir" clean -fdxq
            helm package "${checkout_dir}/${path}" \
                --dependency-update --destination "$BUILD_DIR"
        done <<< "${groups[$key]}"
    done
}

build_extra() {
    local target chart
    for target in "$@"; do
        in_list "$target" "${EXTRA_TARGETS[@]}" \
            || { echo "Unknown release or target '${target}'" >&2; usage; }
    done
    for target in "$@"; do
        case "$target" in
            openstack-exporter)
                echo "Building chart: prometheus-openstack-exporter"
                helm package ./openstack-exporter/charts/prometheus-openstack-exporter \
                    --dependency-update --destination "$BUILD_DIR" ;;
            gardener-cert-management|gardener-external-dns-management)
                chart="${target#gardener-}"
                echo "Building chart: ${chart}"
                helm package "./gardener-${chart}/charts/${chart}" \
                    --dependency-update --destination "$BUILD_DIR" ;;
            nodepool-labels-operator)
                echo "Building chart: nodepool-labels-operator"
                helm package ./nodepool-labels-operator/charts/nodepool-labels-operator/ \
                    --dependency-update --destination "$BUILD_DIR" ;;
            gardener-all)
                echo "Building gardener charts"
                bash build-gardener-charts.sh ;;
        esac
    done
}

if yq -e ".releases | has(\"$1\")" "$CHARTS_YAML" >/dev/null 2>&1; then
    release="$1"; shift
    build_release "$release" "$@"
else
    build_extra "$@"
fi

shopt -s nullglob
built=("$BUILD_DIR"/*.tgz)
if [ ${#built[@]} -eq 0 ]; then
    echo "Nothing was packaged; index.yaml left untouched"
    exit 0
fi

helm repo index "$BUILD_DIR" --url "$REPO_URL" --merge "${SCRIPT_DIR}/index.yaml"
sed -i "s#file:.*helm-toolkit#${REPO_URL}#g" "${BUILD_DIR}/index.yaml"
mv "${built[@]}" "${SCRIPT_DIR}/"
mv "${BUILD_DIR}/index.yaml" "${SCRIPT_DIR}/index.yaml"
echo "Indexed ${#built[@]} chart(s) into index.yaml"
