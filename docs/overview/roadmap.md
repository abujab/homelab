
# Roadmap

---

## Purpose

This document describes the planned evolution of HomeLab.

It gives structure to future work and prevents the platform from growing randomly.

---

## Scope

This roadmap covers major platform phases.

It does not replace `work-orders/CURRENT.md`. The roadmap describes long-term direction. `work-orders/CURRENT.md` describes the current sprint.

---

## Background

The platform already completed the first major build phases:

1. Raspberry Pi provisioning
2. Ansible automation
3. K3s Kubernetes installation

The next phase focuses on networking because most future services depend on stable service exposure and DNS.

---

## Architecture / Implementation

### Phase 1 — Raspberry Pi Cluster

Status: Complete

Completed:

- Raspberry Pi OS / Debian 13 installation
- hostnames
- static DHCP reservations
- SSH key access
- four-node cluster foundation

### Phase 2 — Ansible Foundation

Status: Complete

Completed:

- Ansible inventory
- group variables
- host variables
- project-level `ansible.cfg`
- common role
- update playbook
- baseline playbook
- verification tasks

### Phase 3 — Kubernetes Foundation

Status: Complete

Completed:

- K3s server on pi4mB01
- K3s agents on pi4mB02, pi4mB03, pi4mB04
- kubeconfig retrieval
- worker labels
- cluster verification
- CoreDNS running
- Metrics Server running
- Local Path Provisioner running

### Phase 4 — Documentation Foundation

Status: In progress

Objectives:

- MkDocs Material setup
- documentation structure
- overview documentation
- architecture documentation
- repository documentation
- roadmap documentation

### Phase 5 — Networking Foundation

Status: Complete

Completed:

- MetalLB
- Pi-hole internal DNS
- Traefik ingress controller
- `.home.arpa` naming
- service discovery
- IBM ELM DNS entry
- first internal service URLs
- TP-Link TL-SG108E wired switch baseline
- wired Ethernet as cluster node transport
- Wi-Fi disabled through Ansible

Remaining future work:

- TLS certificate management
- additional service records

### Phase 6 — Observability

Status: Planned

Objectives:

- Prometheus
- Grafana
- Loki
- Alertmanager
- dashboards
- alert rules

### Phase 7 — Storage

Status: Planned

Objectives:

- storage architecture decision
- Longhorn or alternative
- persistent volumes
- backup strategy
- restore testing

### Phase 8 — Developer Platform

Status: Planned

Objectives:

- internal Git service
- container registry
- CI/CD experiments
- build workloads
- image publishing

### Phase 9 — AI Platform

Status: Planned

Objectives:

- Ollama
- Open WebUI
- AnythingLLM
- x86 or RK1 workload placement
- local model experimentation

### Phase 10 — Hybrid Expansion

Status: Planned

Objectives:

- x86 Linux laptop nodes
- future Turing Pi integration
- RK1 nodes
- architecture-aware scheduling
- node labels and taints

---

## Design Decisions

The roadmap is sequenced intentionally.

Networking comes before monitoring and applications because services need stable names and exposure.

Monitoring comes before heavier workloads because observability should exist before platform complexity increases.

Storage comes before stateful services because persistent applications need a backup and restore model.

AI comes later because it benefits from the compute tier and from a mature networking and monitoring foundation.

---

## Best Practices

When adding a new roadmap item:

- identify the infrastructure dependency
- create an ADR if the decision is significant
- update documentation before or during implementation
- define acceptance criteria
- commit implementation and documentation together when practical

---

## Future Improvements

The roadmap will evolve as new hardware is added.

Likely future roadmap additions:

- VLAN segmentation
- IPv6
- external access through VPN
- secrets management
- GitOps
- service catalog
- automated backups
- disaster recovery drills

---

## Related Documents

- [Vision](vision.md)
- [Architecture](architecture.md)
- [Repository Structure](repository.md)
