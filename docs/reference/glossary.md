# Glossary

---

## Purpose

This glossary defines recurring HomeLab infrastructure terms and abbreviations.

## Scope

Definitions are concise and describe HomeLab usage where useful. A definition
does not mean that the named technology is installed; current deployment state
is recorded in the [Service Catalog](service-catalog.md).

## Background

Consistent terminology reduces ambiguity between architecture, implementation,
operations and planned work.

## Architecture / Implementation

| Term | Definition |
|------|------------|
| ADR | Architecture Decision Record: a durable explanation of why a significant design choice was made. |
| Ansible | Agentless configuration-management tool used to apply and verify the Raspberry Pi node baseline and K3s installation. |
| CA | Certificate Authority: an entity that signs and validates certificate identities. |
| cert-manager | Current Kubernetes certificate-lifecycle controller used to issue and renew HomeLab server certificates. |
| ClusterIP | Kubernetes Service type reachable only inside the cluster; the normal backend type for HomeLab ingress. |
| control plane | Kubernetes components that expose the API and coordinate the cluster; currently hosted only by `pi4mB01`. |
| CSI | Container Storage Interface: the standard through which Kubernetes integrates storage systems. No additional CSI platform such as Longhorn is currently installed. |
| DHCP reservation | Router configuration that consistently assigns the same IP address to known hardware. |
| DNS | Domain Name System. Pi-hole currently resolves HomeLab `home.arpa` names and forwards public queries. |
| Helm | Kubernetes package manager used to deploy Traefik and cert-manager from pinned charts. |
| ingress | Kubernetes HTTP and HTTPS routing from an external endpoint to internal Services. |
| issuing CA | A CA signed by the Root CA that signs leaf certificates. HomeLab separates Server and Client Issuing CAs. |
| K3s | Lightweight Kubernetes distribution used by the four-node Raspberry Pi cluster. |
| Kubernetes | Container orchestration platform underlying current HomeLab platform services. |
| LoadBalancer | Kubernetes Service type that receives a LAN address from MetalLB in HomeLab. |
| Longhorn | Candidate replicated Kubernetes block-storage platform. It is not installed and remains a planned evaluation. |
| MetalLB | Current bare-metal LoadBalancer implementation, operating in Layer 2 mode on the HomeLab LAN. |
| namespace | Kubernetes scope used to group resources, such as `networking`, `ingress` and `cert-manager`. |
| node | A machine registered in Kubernetes. HomeLab currently has four Raspberry Pi nodes. |
| PKI | Public Key Infrastructure: the CAs, certificates, keys, policy and procedures used to establish trust. |
| Pod | Smallest Kubernetes scheduling unit; one or more containers sharing network and storage context. |
| PV | PersistentVolume: Kubernetes storage made available to workloads. |
| PVC | PersistentVolumeClaim: a workload request for persistent storage; Pi-hole uses `pihole-config`. |
| Root CA | Offline HomeLab trust anchor that signs issuing CAs rather than routine service certificates. |
| SAN | Subject Alternative Name: certificate field containing valid DNS names such as `pihole.home.arpa`. |
| Service | Kubernetes resource providing a stable network endpoint for selected Pods. |
| StorageClass | Kubernetes policy and provisioner definition used when creating persistent volumes. The current default is `local-path`. |
| Traefik | Current shared Kubernetes Ingress Controller at `192.168.68.201`. |
| UASP | USB Attached SCSI Protocol. The qualified `pi4mB01` bridge does not use UASP and operates through `usb-storage`. |
| worker node | Kubernetes node that runs workloads without hosting the current K3s server role; `pi4mB02` through `pi4mB04`. |

Additional HomeLab terms:

| Term | Definition |
|------|------------|
| `home.arpa` | Standards-based private DNS namespace used for HomeLab services. |
| IaC | Infrastructure as Code: version-controlled declaration and automation of infrastructure state. |
| Layer 2 | Local network layer at which MetalLB announces service addresses using LAN neighbor-discovery behavior. |
| local-path | K3s node-local dynamic storage provisioner; current but not replicated. |
| mTLS | Mutual TLS, where both client and server present certificates. Planned for selected future use, not currently enforced. |
| work order | Reviewed unit of implementation scope, validation and acceptance stored under `work-orders/`. |

## Design Decisions

Definitions describe actual HomeLab usage where it differs from a generic
dictionary definition. Planned components are labeled explicitly.

## Best Practices

- use exact product capitalization from this glossary
- link to detailed design documents for implementation behavior
- add a term only when it recurs or has HomeLab-specific meaning
- update state in the Service Catalog rather than overloading definitions

## Future Improvements

- add observability, GitOps and backup terminology when those designs are approved
- remove ambiguity as storage and secrets-management decisions mature

## Related Documents

- [Reference Overview](index.md)
- [Service Catalog](service-catalog.md)
- [Decision Register](decision-register.md)
- [Architecture](../overview/architecture.md)
