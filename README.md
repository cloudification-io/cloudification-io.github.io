# Cloudification Openstack Helm repository

## Submodules

| Submodule | Revision |
|---|---|
| [Openstack helm](https://github.com/openstack/openstack-helm)  |  master |
| [Openstack helm infra](https://github.com/openstack/openstack-helm-infra)  | master |
| [Openstack-exporter](https://github.com/openstack-exporter/helm-charts.git)  | master |
| [Nodelabel-operator](https://github.com/banzaicloud/nodepool-labels-operator.git)  | 35e99b1 |
| [gardener-cert-management](https://github.com/gardener/cert-management.git)  | master |
| [gardener-extension-networking-calico](https://github.com/gardener/gardener-extension-networking-calico.git)  | v1.43.0 |
| [gardener-extension-networking-cilium](https://github.com/gardener/gardener-extension-networking-cilium.git)  | v1.37.0 |
| [gardener-extension-os-gardenlinux](https://github.com/gardener/gardener-extension-os-gardenlinux.git)  | v0.24.0 |
| [gardener-extension-os-ubuntu](https://github.com/gardener/gardener-extension-os-ubuntu.git)  | v1.25.0 |
| [gardener-extension-provider-dns-cloudflare](https://github.com/schrodit/gardener-extension-provider-dns-cloudflare.git)  | v0.0.6 |
| [gardener-extension-provider-openstack](https://github.com/gardener/gardener-extension-provider-openstack.git)  | v1.42.1 |
| [gardener-external-dns-management](https://github.com/gardener/external-dns-management.git)  | 366f39b7 |

## Build charts
```
git submodule update --init --recursive --remote
git submodule foreach 'git fetch origin; git checkout $(git config -f $toplevel/.gitmodules submodule.$name.branch || echo "master"); git pull'

bash ./release.sh
```