#!/bin/bash

GARDEN_REPOS="https://github.com/gardener/gardener-extension-networking-cilium.git
https://github.com/gardener/gardener-extension-networking-calico.git
https://github.com/schrodit/gardener-extension-provider-dns-cloudflare.git
https://github.com/gardener/gardener-extension-provider-openstack.git
https://github.com/gardener/gardener-extension-os-gardenlinux.git
https://github.com/gardener/gardener-extension-os-ubuntu.git"

add_garden_submodules(){
    for repo in $(echo ${GARDEN_REPOS})
    do
        git submodule add ${repo}
    done
}

# add_garden_submodules

GARDEN_DIRS="gardener-extension-networking-calico
gardener-extension-networking-cilium
gardener-extension-os-gardenlinux
gardener-extension-os-ubuntu
gardener-extension-provider-dns-cloudflare
gardener-extension-provider-openstack"

fetch_latest_tags() {
    for dir in $(echo ${GARDEN_DIRS})
    do
        cd ${dir}
        # Get new tags from remote
        git fetch --tags
        # Get latest tag name
        latestTag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
        # Checkout latest tag
        git checkout $latestTag
        cd -
    done
}

fetch_latest_tags

# build_garden_charts() {
#     for dir in $(echo ${GARDEN_DIRS})
#     do
#         helm package ./${dir}/charts/${dir}}/ --dependency-update
#     done
# }

helm package ./gardener-extension-networking-cilium/charts/gardener-extension-admission-cilium/ --dependency-update
helm package ./gardener-extension-networking-calico/charts/gardener-extension-admission-calico/ --dependency-update
helm package ./gardener-extension-provider-openstack/charts/gardener-extension-admission-openstack/ --dependency-update
