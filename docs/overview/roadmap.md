# Roadmap

---

## Purpose

This document describes the sequenced evolution of HomeLab and the dependencies
that prevent planned capabilities from being mistaken for approved work.

## Scope

The roadmap records platform phases and their states. It does not approve work,
allocate work-order numbers or replace `work-orders/CURRENT.md`.

## Background

HomeLab has completed the Raspberry Pi, Ansible, Kubernetes, networking,
ingress, PKI and documentation foundations. Storage hardware qualification has
started, but distributed storage remains blocked by insufficient qualified
hardware.

## Architecture / Implementation

Status meanings:

| Status | Meaning |
|--------|---------|
| Complete | Implemented, verified and documented |
| In progress | An approved work order is being executed |
| Ready | Dependencies are met, but work is not automatically approved |
| Blocked | A required dependency is not met |
| Planned | Intended future direction without current implementation |
| Exploratory | An option under consideration, not an approved direction |

### Phase 1 - Raspberry Pi Foundation

Status: Complete

- four Raspberry Pi 4 Model B nodes
- Raspberry Pi OS Lite 64-bit / Debian 13 baseline
- hostnames, DHCP reservations and SSH key access
- Arch Linux management workstation workflow

### Phase 2 - Ansible Foundation

Status: Complete

- inventory, group variables and host variables
- `common`, `network`, `k3s` and `storage` roles
- baseline, update, K3s and storage playbooks
- idempotent state and verification tasks

### Phase 3 - Kubernetes Foundation

Status: Complete

- K3s control plane on `pi4mB01`
- three K3s workers
- CoreDNS, Metrics Server, Local Path Provisioner and containerd
- kubeconfig retrieval, worker labels and cluster verification

### Phase 4 - Networking, Ingress and TLS Foundation

Status: Complete

- TP-Link TL-SG108E wired transport
- Wi-Fi disabled through the Ansible baseline
- MetalLB Layer 2 address pool
- Pi-hole internal DNS
- Traefik shared ingress
- private Root, Server Issuing and Client Issuing CAs
- cert-manager server-certificate automation
- HTTP-to-HTTPS redirection
- secure Pi-hole Web exposure through shared ingress

`elm.home.arpa` is reserved only. IBM ELM is not deployed or published.

### Phase 5 - Documentation Foundation

Status: Complete

| Documentation Sprint | Result |
|----------------------|--------|
| WO-1001 Overview | Complete |
| WO-1002 Infrastructure | Complete |
| WO-1003 Operations | Complete |
| WO-1004 Architecture and Reference Refresh | Complete |

The current documentation includes overview, ADR, infrastructure, operations,
reference and development workflow navigation.

### Phase 6A - Storage Hardware Foundation

Status: Complete for `pi4mB01`; incomplete cluster-wide

- Hitachi 160 GB disk independently qualified on `pi4mB01`
- ext4 label and persistent `/srv/longhorn` host mount
- exact model and serial validation through Ansible
- SMART, performance, reboot and sustained-I/O evidence

The host path is preparatory. It does not provide Kubernetes replication.

### Phase 6B - Storage Expansion and Distributed Storage

Status: Blocked

```text
Longhorn evaluation
    depends on
at least one additional independently qualified storage node
    and
approved storage architecture and work order
```

The known WD1600BEVT disk for `pi4mB02` is not connected or qualified.
Longhorn is not installed. NAS and enterprise storage options remain
Exploratory.

### Phase 7 - Observability

Status: Planned

Potential scope includes Prometheus, Grafana, Loki, Alertmanager, dashboards and
alert rules. No stack or work order is currently approved.

### Phase 8 - Secrets and GitOps

Status: Planned

- secrets-management architecture
- resolution of the proposed GitOps decision
- declarative reconciliation and delivery controls

These capabilities require architecture review before tool selection or
deployment.

### Phase 9 - Developer Platform

Status: Planned

- internal Git or source services
- container registry
- CI/CD experiments
- build workloads

Dependencies include observability, storage and secrets appropriate to the
selected services.

### Phase 10 - Hybrid Compute and AI

Status: Planned

- x86 Linux compute nodes
- possible future Turing Pi or RK1 integration
- architecture-aware scheduling
- AI model serving and supporting applications

AI workloads depend on suitable compute, storage, monitoring and workload
placement. No AI service is currently deployed.

### Dependency summary

| Capability | Status | Primary Dependency |
|------------|--------|--------------------|
| Additional disk qualification | Ready when enclosure and disk are available | Stable USB hardware |
| Longhorn evaluation | Blocked | At least two qualified storage nodes total |
| Backup target | Exploratory | Storage and recovery architecture |
| Observability | Planned | Approved stack and work order |
| GitOps | Planned | ADR-0005 resolution |
| Secrets management | Planned | Security architecture |
| x86 compute | Planned | Hardware admission and scheduling design |
| AI platform | Planned | Compute, storage and observability |

## Design Decisions

Networking and trusted service exposure precede application growth. Hardware
qualification precedes distributed storage. Observability, backup and secrets
controls should precede important stateful workloads.

Completion of a dependency does not automatically approve its successor.

## Best Practices

- use only the defined roadmap statuses
- state dependencies next to blocked or planned work
- assign a work-order number only after review and approval
- update the roadmap when a sprint changes a phase state
- keep exploratory technology choices out of current architecture diagrams

## Future Improvements

- refine sequencing after additional storage is qualified
- add recovery objectives before stateful services
- add release-level milestones when observability and GitOps are approved

## Related Documents

- [Vision](vision.md)
- [Architecture](architecture.md)
- [Repository Structure](repository.md)
- [Infrastructure Inventory](../reference/infrastructure-inventory.md)
- [Service Catalog](../reference/service-catalog.md)
- [Decision Register](../reference/decision-register.md)
- [Storage](../infrastructure/storage.md)
