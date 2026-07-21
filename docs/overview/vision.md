# Vision

---

## Purpose

This document defines the long-term HomeLab vision and the engineering
principles that govern its evolution.

## Scope

It covers project intent, desired platform characteristics and target outcomes.
It does not define exact addresses, versions, operational commands or approved
implementation scope.

## Background

HomeLab began as a four-node Raspberry Pi Kubernetes project and has become a
small private-cloud engineering platform.

The current foundation already includes:

- an Arch Linux management workstation
- four Raspberry Pi 4 Model B nodes
- Ansible-managed Debian 13 node configuration
- a wired K3s Kubernetes cluster
- MetalLB and Pi-hole internal networking
- Traefik shared ingress
- a private PKI and cert-manager certificate automation
- one independently qualified dedicated storage disk
- MkDocs Material documentation and work-order review practices

Future compute, storage and application tiers remain separate from this current
state.

## Architecture / Implementation

The vision is a reproducible hybrid private cloud built from accessible hardware
while applying durable infrastructure engineering practices.

```text
Management and source-of-truth plane
  |
  +-- Git
  +-- Ansible
  +-- Kubernetes manifests and Helm values
  +-- ADRs, work orders, evidence and documentation
  |
Hybrid platform
  |
  +-- Current ARM64 Raspberry Pi infrastructure tier
  |
  +-- Future ARM64 expansion tier
  |
  +-- Future AMD64/x86 compute tier
  |
Platform capabilities
  |
  +-- Current: Kubernetes, DNS, load balancing, ingress and private HTTPS
  +-- Partial: qualified host storage foundation
  +-- Planned: observability, replicated storage, GitOps and secrets management
  +-- Planned: developer services and AI workloads
```

The target platform should support:

- stable always-on infrastructure services
- declarative application delivery
- observable and recoverable stateful workloads
- workload placement across ARM64 and AMD64 nodes
- internal service identities under `home.arpa`
- local developer and AI experimentation
- documented integration paths for services such as IBM ELM

## Design Decisions

### Infrastructure as Code

Desired state is expressed through Ansible, Kubernetes manifests, Helm values
and Git before manual configuration is considered.

### Git as the source of truth

The repository, documented bootstrap procedure and required installation media
must be sufficient to rebuild the platform. Runtime-only secrets and private key
material require separate protected recovery procedures.

### Documentation as implementation

Architecture, operations, reference data, validation evidence and current
project state are part of every completed sprint.

### Hybrid architecture

Raspberry Pis provide low-power infrastructure. Future x86 systems may provide
heavier build, developer and AI compute after admission and scheduling are
designed.

### Service names over machine names

Machine names identify physical hardware. Applications use functional DNS names
under the current `home.arpa` namespace.

### Incremental maturity

Each platform layer must be verified before dependent services are introduced.
For example, additional disks must be qualified before distributed storage can
be evaluated.

## Best Practices

- preserve current-versus-target distinctions
- prefer repeatable automation over manual commands
- record significant trade-offs in ADRs
- use work orders with explicit acceptance criteria
- maintain one authoritative source for stable lookup data
- verify rebuild, backup and restore behavior
- keep machine identity separate from service identity

## Future Improvements

The long-term direction may include:

- additional qualified node storage and distributed-storage evaluation
- an external backup target
- Prometheus, Grafana, Loki and Alertmanager
- a reviewed GitOps platform
- dedicated secrets management
- x86 compute and additional ARM hardware
- local AI model serving and developer applications
- high-availability control-plane evaluation

These are target capabilities, not claims about the current platform.

## Related Documents

- [Architecture](architecture.md)
- [Roadmap](roadmap.md)
- [Repository Structure](repository.md)
- [Reference](../reference/index.md)
- [Infrastructure Inventory](../reference/infrastructure-inventory.md)
- [Decision Register](../reference/decision-register.md)
