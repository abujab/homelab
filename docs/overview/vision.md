
# Vision

---

## Purpose

This document defines the long-term vision for HomeLab.

It explains why the platform exists, what kind of engineering discipline it should follow, and what principles should guide future decisions.

---

## Scope

This document covers:

- project motivation
- long-term goals
- engineering principles
- intended learning outcomes
- operating philosophy

This document does not describe implementation commands, exact IP addresses, Kubernetes manifests or Ansible task syntax. Those details belong in infrastructure, operations and reference documentation.

---

## Background

HomeLab started as a practical experiment: build a Raspberry Pi cluster, run Kubernetes locally and use it as a foundation for local AI and self-hosted services.

During implementation the project expanded. It now includes:

- a management workstation running Arch Linux
- four Raspberry Pi 4 nodes
- Ansible automation
- K3s Kubernetes
- MkDocs documentation
- a future plan for x86 Linux laptops
- a future plan for Turing Pi and RK1 modules
- IBM ELM running in Ubuntu WSL on Windows
- plans for local DNS and service discovery

The project is therefore no longer just a Raspberry Pi cluster. It is becoming a small private datacenter.

---

## Architecture / Implementation

The vision is to build a hybrid private cloud using inexpensive hardware while applying professional infrastructure engineering practices.

The platform should eventually support:

- Kubernetes workloads
- internal DNS
- ingress
- monitoring
- logging
- persistent storage
- GitOps
- CI/CD experiments
- local AI workloads
- home automation
- developer tools
- IBM ELM integration

The platform should remain understandable and rebuildable. Every important decision should have a written rationale.

The target model is:

```text
Management workstation
        │
        ▼
Infrastructure as Code
        │
        ▼
Hybrid compute platform
        │
        ├── ARM64 Raspberry Pi nodes
        ├── ARM64 Turing/RK1 nodes
        └── AMD64/x86 Linux laptops
        │
        ▼
Kubernetes and supporting services
```

The platform should resemble a miniature production environment rather than a collection of individual Raspberry Pis.

```
                         Internet
                             │
                        ISP Router
                             │
                ┌────────────┴─────────────┐
                │                          │
         Management Network          WiFi Clients
                │
        ┌───────┴─────────────────────────────────────────────┐
        │                                                     │
   Raspberry Pi Cluster                                 x86 Cluster
  (Always-on services)                              (Heavy workloads)
        │                                                     │
 pi4mB01  Control Plane                              Dell 5591
 pi4mB02  Worker                                     ThinkPad
 pi4mB03  Worker                                     HP Laptop
 pi4mB04  Worker                                     ...
        │                                                     │
        └────────────── Kubernetes (single cluster) ──────────┘
                              │
                    MetalLB + Ingress + DNS
                              │
        grafana.home.arpa
        git.home.arpa
        elm.home.arpa
        ollama.home.arpa
        registry.home.arpa
```

---

## Design Decisions

### Infrastructure as Code

Manual configuration should be minimized. The desired state of the infrastructure should be expressed in code, primarily through Ansible, Kubernetes manifests and Helm charts.

### Git as the source of truth

The repository should describe the platform. If hardware fails, the platform should be recoverable from Git plus documented bootstrap steps.

### Documentation first

Documentation is not an afterthought. It is part of the platform. Every sprint should update documentation when the infrastructure changes.

### Hybrid architecture

The platform should support both ARM64 and AMD64 nodes. Raspberry Pis are excellent low-power infrastructure nodes. x86 laptops and future mini PCs are better suited for heavier compute and AI workloads.

### Service names over IP addresses

Applications should be reached by DNS names, not IP addresses. The planned internal domain is `.home.arpa`.

---

## Best Practices

Future work should follow these principles:

- prefer repeatable automation over manual commands
- prefer clear architecture over quick shortcuts
- avoid duplicating configuration values in many places
- record important trade-offs as ADRs
- use Kubernetes labels and node roles to express placement intent
- keep machine identity separate from service identity
- validate each change with an acceptance test

---

## Future Improvements

The vision will expand as the platform grows.

Potential future areas:

- high availability control plane
- GitOps with FluxCD
- MetalLB and ingress
- Pi-hole or CoreDNS for internal DNS
- TLS certificate management
- Longhorn or another persistent storage solution
- Prometheus, Grafana and Loki
- x86 compute nodes
- AI services such as Ollama and Open WebUI
- IBM ELM service publication through local DNS

---

## Related Documents

- [Architecture](architecture.md)
- [Repository Structure](repository.md)
- [Roadmap](roadmap.md)
