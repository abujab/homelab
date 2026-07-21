# Software Inventory

---

## Purpose

This page records verified HomeLab software pins and identifies components whose
runtime versions are not controlled by the repository.

## Scope

The inventory covers node, Kubernetes, networking, ingress, certificate and
documentation software. It does not claim a runtime version when repository
evidence is insufficient.

## Background

Versions are selected from sources in this order:

1. pinned executable repository configuration
2. dependency files
3. completed work-order evidence
4. `PROJECT_STATE.md`

`Not pinned` means installation is not constrained to an exact version.
`Pending verification` means the currently running version cannot be established
from repository-controlled evidence.

## Architecture / Implementation

### Platform software

| Component | Repository Version State | Deployment Method | Source |
|-----------|--------------------------|-------------------|--------|
| Raspberry Pi OS Lite 64-bit | Debian 13 baseline; image release not pinned | Raspberry Pi imaging, then Ansible | ADR-0001 and `PROJECT_STATE.md` |
| Ansible | Not pinned | Management workstation package; repository playbooks and roles | `docs/operations/bootstrap.md`, `ansible/` |
| K3s | Not pinned | `get.k3s.io` installer through Ansible | `ansible/roles/k3s/tasks/install_server.yml` |
| Kubernetes | Pending verification; follows installed K3s release | Bundled with K3s | No repository version pin |
| containerd | Not pinned separately; follows installed K3s release | Bundled with K3s | K3s platform state |
| kubectl | Not pinned | Management workstation package | `docs/operations/bootstrap.md` |
| Helm | Not pinned | Management workstation package | Ingress and certificate runbooks |

### Kubernetes platform components

| Component | Version | Deployment Method | Source |
|-----------|---------|-------------------|--------|
| MetalLB | `v0.16.1` | Remote Kustomize resource plus local custom resources | `kubernetes/platform/networking/metallb/kustomization.yaml` |
| Traefik Helm chart | `41.0.2` | Helm | `kubernetes/platform/ingress/values.yaml` |
| Traefik application | `v3.7.6` | Traefik Helm chart | `kubernetes/platform/ingress/values.yaml` |
| cert-manager Helm chart | `v1.21.0` | OCI Helm chart | `kubernetes/platform/certificates/values.yaml` |
| cert-manager application | `v1.21.0` | cert-manager Helm chart | `kubernetes/platform/certificates/values.yaml` |
| Pi-hole | Image digest `sha256:f7d1be836e3bc608b56d82fc9904f5a831cdfbc0dc9c6d58f94e4c985c70038b`; release tag not recorded | Kubernetes Deployment | `kubernetes/platform/networking/pihole/deployment.yaml` |
| Traefik `whoami` | `v1.11` | Kubernetes Deployment | `kubernetes/platform/ingress/test-app/deployment.yaml` |
| Local Path Provisioner | Pending verification; follows installed K3s release | Bundled with K3s | K3s current platform state |
| CoreDNS | Pending verification; follows installed K3s release | Bundled with K3s | K3s current platform state |
| Metrics Server | Pending verification; follows installed K3s release | Bundled with K3s | K3s current platform state |

### Documentation and Python tooling

| Component | Version | Deployment Method | Source |
|-----------|---------|-------------------|--------|
| Python | Not pinned | Local virtual environment | Bootstrap procedure |
| MkDocs | `1.6.1` | Python virtual environment | `requirements/docs.txt` |
| MkDocs Material | `9.7.6` | Python virtual environment | `requirements/docs.txt` |
| Markdown | `3.10.2` | Python virtual environment | `requirements/docs.txt` |
| PyMdown Extensions | `11.0.1` | Python virtual environment | `requirements/docs.txt` |
| PyYAML | `6.0.3` | Python virtual environment | `requirements/docs.txt` |

The local virtual environment used for WO-1004 ran Python `3.14.6`, but that
interpreter version is not a repository pin and therefore is not the platform
requirement.

## Design Decisions

Exact versions are reported only when Git controls the version or immutable
image digest. A locally installed version is evidence for a validation run, not
an implicit platform pin.

Component and chart versions are listed separately where a chart declares both.

## Best Practices

- pin Helm charts and container images in executable configuration
- record application and chart versions separately
- verify bundled K3s component versions before version-sensitive maintenance
- update this inventory in the same work order as a version change
- do not replace `Pending verification` with an assumed upstream default

## Future Improvements

- pin K3s explicitly after an upgrade policy is approved
- record current Kubernetes and bundled component versions as validation evidence
- define version controls for Ansible, Helm and kubectl
- automate comparison between dependency files and this inventory

## Related Documents

- [Service Catalog](service-catalog.md)
- [Kubernetes](../infrastructure/kubernetes.md)
- [Ingress](../infrastructure/ingress.md)
- [PKI](../infrastructure/pki.md)
- [Updating](../operations/updating.md)
