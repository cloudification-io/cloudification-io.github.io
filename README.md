# Cloudification Openstack Helm repository

## OpenStack Helm charts

OpenStack chart sources are defined in `charts.yaml` as named releases (`2025.1`,
`2026.1`, ...). Each release pins one upstream commit and lists the charts built from
it. A chart entry can override `repo`, `commit` and `path` (directory inside the
repository, defaults to the chart name).

Resolution order: `chart.repo`, then `release.repo`, then the top-level `repo`;
`chart.commit`, then `release.commit`.

Sources are cloned into `.chart-cache/` and every commit gets its own worktree there,
so several releases can be built side by side without touching the working tree.

Packages are written to a scratch directory first and only that directory is indexed,
merged into the existing `index.yaml`. Entries for charts that were not rebuilt keep
their `created` timestamps.

## Submodules

| Submodule | Revision |
|---|---|
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
- bash 4+, GNU sed, `md5sum`

## Build charts

```bash
# All OpenStack charts of a release (names from charts.yaml)
bash ./release.sh 2026.1

# Some charts of a release
bash ./release.sh 2026.1 ovn nova

# Non-OpenStack charts by name (submodules must be initialised)
git submodule update --init --recursive
bash ./release.sh openstack-exporter gardener-cert-management gardener-external-dns-management nodepool-labels-operator

# All gardener charts
bash ./release.sh gardener-all
```
