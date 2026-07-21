# Service Catalog

---

## Purpose

This page is the authoritative catalog of current HomeLab platform services and
explicitly identified future service states.

## Scope

The catalog includes Kubernetes platform capabilities, DNS, load balancing,
ingress, certificate automation and validation services. It distinguishes
deployed services from reserved names and planned evaluations.

## Background

Service exposure is split by protocol. Pi-hole DNS requires a direct LAN
LoadBalancer address. Browser-facing services normally use internal ClusterIP
Services behind shared Traefik HTTPS ingress.

## Architecture / Implementation

### Platform services

| Service | Category | Namespace | Exposure / Address | Ports | TLS | Persistence | Management | Status |
|---------|----------|-----------|--------------------|-------|-----|-------------|------------|--------|
| K3s control plane | Kubernetes platform | Host service | Node endpoint `192.168.68.101` | TCP `6443` | K3s-managed API TLS | Node-local K3s state | Ansible `k3s` role | Ready |
| CoreDNS | Kubernetes platform DNS | `kube-system` | Cluster internal | TCP/UDP `53` internally | Not applicable | None | K3s bundled component | Ready |
| Metrics Server | Kubernetes platform metrics | `kube-system` | Kubernetes API aggregation | Kubernetes internal | Internal platform TLS | None | K3s bundled component | Ready |
| Local Path Provisioner | Kubernetes storage | `kube-system` | `StorageClass/local-path` | Not applicable | Not applicable | Node-local volumes | K3s bundled component | Ready; not replicated |
| MetalLB | Load balancing | `metallb-system` | Layer 2 pool `192.168.68.200-192.168.68.220` | Service dependent | Service dependent | None | Kustomize | Ready |
| Traefik | Ingress | `ingress` | LoadBalancer `192.168.68.201` | TCP `80`, `443` | Terminates cert-manager certificates; HTTP redirects to HTTPS | None | Helm chart `41.0.2` | Ready |
| cert-manager | Certificate management | `cert-manager` | Cluster internal | Kubernetes internal | Manages TLS certificate lifecycle | CA Secret runtime state | OCI Helm chart `v1.21.0` | Ready |
| `ClusterIssuer/homelab-server-ca` | Certificate issuer | Cluster-scoped; Secret in `cert-manager` | Cluster internal | Not applicable | Signs HomeLab server certificates | Server Issuing CA Secret | Declarative issuer plus external PKI procedure | Ready |

### Application and validation services

| Service | Category | Namespace | Exposure | DNS / IP | Ports | TLS | Persistence | Management | Status |
|---------|----------|-----------|----------|----------|-------|-----|-------------|------------|--------|
| Pi-hole DNS | DNS | `networking` | `LoadBalancer` Service `pihole` | Resolver `192.168.68.200` | TCP/UDP `53` | No transport TLS | `pihole-config` PVC, 2 GiB `local-path` | Kustomize; password Secret created outside Git | Ready |
| Pi-hole Web | DNS administration | `networking` | Ingress to ClusterIP Service `pihole-web` | `pihole.home.arpa` via `192.168.68.201` | Client TCP `443`; backend TCP `80` | Current, cert-manager issued, Traefik terminated | Shares `pihole-config` PVC | Kustomize | Ready |
| Traefik `whoami` | Validation | `ingress` | Ingress to ClusterIP Service `whoami` | `test.home.arpa` via `192.168.68.201` | Client TCP `443`; backend TCP `80` | Current, cert-manager issued, Traefik terminated | None | Kubernetes manifests | Ready; validation-only |

### Planned and reserved entries

| Entry | Classification | Current State | Dependency |
|-------|----------------|---------------|------------|
| Longhorn | Planned evaluation | **Not installed / planned evaluation** | At least one additional qualified storage node and a separately approved work order |
| `elm.home.arpa` | Reserved service name | No DNS record or deployed workload in current manifests | Approved IBM ELM publication work |
| Observability stack | Planned | Prometheus, Grafana, Loki and Alertmanager are not installed | Approved observability architecture and work order |
| GitOps platform | Planned | FluxCD and Argo CD are not installed | ADR resolution and approved work order |
| NAS or backup target | Exploratory | No NAS platform is approved or installed | Storage and backup architecture decision |

### Authoritative sources

- Kubernetes resources and exposure: `kubernetes/platform/`
- service addresses and DNS: [Naming and Addressing](naming-and-addressing.md)
- runtime status summary: `PROJECT_STATE.md`
- software pins: [Software Inventory](software-inventory.md)

## Design Decisions

Catalog status describes deployed reality, not roadmap intent. A reserved DNS
name is not a service. A prepared host path is not a storage platform.

Browser-facing services use shared ingress unless a documented protocol or
security requirement justifies direct exposure.

## Best Practices

- add a catalog entry in the same work order that deploys a service
- record namespace, owner, exposure, TLS and persistence before declaring Ready
- label test workloads as validation-only
- keep sensitive Secret values out of the catalog and Git
- remove or retire validation services through an approved work order

## Future Improvements

- add service recovery objectives when backup architecture is implemented
- add operational ownership and maintenance windows as the service count grows
- automate catalog checks against Kubernetes manifests

## Related Documents

- [Naming and Addressing](naming-and-addressing.md)
- [Software Inventory](software-inventory.md)
- [Networking](../infrastructure/networking.md)
- [Ingress](../infrastructure/ingress.md)
- [PKI](../infrastructure/pki.md)
- [Ingress Operations](../operations/ingress.md)
- [Certificate Operations](../operations/certificates.md)
