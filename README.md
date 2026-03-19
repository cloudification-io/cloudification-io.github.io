# Cloudification Openstack Helm repository

## OpenStack Helm charts

OpenStack chart sources are defined in `charts.yaml`. Each chart can specify its own
repository and commit. Charts without overrides are built from the `openstack-helm`
submodule at the default commit.

## Submodules

| Submodule | Revision |
|---|---|
| [Openstack helm](https://github.com/openstack/openstack-helm)  |  master |
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

## Prerequisites

- [helm](https://helm.sh/)
- [yq](https://github.com/mikefarah/yq) v4+

## Build charts

```bash
git submodule update --init --recursive

# Build all charts
bash ./release.sh

# Build specific charts only (names from charts.yaml)
bash ./release.sh cloudkitty barbican

# Build non-OpenStack charts by name
bash ./release.sh openstack-exporter gardener-cert-management gardener-external-dns-management nodepool-labels-operator

# Build all gardener charts
bash ./release.sh gardener-all
```
