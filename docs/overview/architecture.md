
# Architecture

---

## Purpose

This document describes the current and target architecture of HomeLab.

It connects the project vision to the physical and logical design of the platform.

---

## Scope

This document covers:

- current platform topology
- target hybrid architecture
- management model
- infrastructure tiers
- Kubernetes topology
- future networking direction
- service discovery principles

This document does not provide step-by-step operational procedures. Those belong in operations runbooks.

---

## Background

The platform currently consists of a four-node Raspberry Pi 4 Kubernetes cluster managed from an Arch Linux laptop.

The cluster was built in phases:

1. install Raspberry Pi OS / Debian 13
2. configure hostnames and IP reservations
3. establish SSH key access
4. create Ansible inventory
5. build baseline role
6. install K3s
7. verify Kubernetes nodes and system pods

The current Kubernetes cluster is healthy.

```text
pi4mb01   Ready   control-plane
pi4mb02   Ready   worker
pi4mb03   Ready   worker
pi4mb04   Ready   worker
```

---

## Architecture / Implementation

### Current physical topology

```text
Arch Linux management laptop
        │
        │ SSH / Ansible / kubectl
        ▼
Home LAN 192.168.68.0/24
        │
        ├── pi4mB01 / 192.168.68.101
        ├── pi4mB02 / 192.168.68.102
        ├── pi4mB03 / 192.168.68.103
        └── pi4mB04 / 192.168.68.104
```

### Current logical topology

```text
K3s Cluster
│
├── pi4mb01
│   └── control plane
│
├── pi4mb02
│   └── worker
│
├── pi4mb03
│   └── worker
│
└── pi4mb04
    └── worker
```

### Current platform services

K3s currently provides:

- Kubernetes API server
- CoreDNS
- Metrics Server
- Local Path Provisioner
- containerd runtime

HomeLab platform networking currently provides:

- MetalLB Layer 2 LoadBalancer support
- Pi-hole internal DNS
- `.home.arpa` service naming
- `pihole.home.arpa` at `192.168.68.200`

Traefik and ServiceLB were disabled during K3s installation so that ingress and load balancing could be introduced intentionally. MetalLB now provides the first LAN LoadBalancer implementation. Ingress remains future work.

### Target hybrid topology

```text
Management workstation
        │
        ▼
Home network
        │
        ├── Raspberry Pi infrastructure tier
        │       ├── control plane
        │       ├── DNS
        │       ├── ingress
        │       ├── monitoring
        │       └── lightweight services
        │
        ├── x86 compute tier
        │       ├── AI workloads
        │       ├── build workloads
        │       ├── IBM ELM migration candidate
        │       └── heavier services
        │
        └── edge/developer tier
                ├── Windows workstation
                ├── WSL services
                └── development tools
```

---

## Design Decisions

### K3s as Kubernetes distribution

K3s was selected because it is lightweight, ARM-friendly and suitable for Raspberry Pi hardware.

### Raspberry Pis as initial infrastructure nodes

Raspberry Pis provide low-power always-on compute and are suitable for foundational services.

### x86 laptops as future compute nodes

x86 laptops provide more CPU and memory and are better suited for heavier workloads.

### `.home.arpa` as internal naming domain

The internal domain is `.home.arpa`, because `.local` is reserved for mDNS and can cause conflicts.

### Explicit infrastructure sequencing

Networking services such as MetalLB and DNS are introduced before application services such as Grafana, Git or AI tools.

---

## Best Practices

- keep control plane and worker roles explicit in inventory
- use Ansible groups to represent infrastructure intent
- use Kubernetes labels for workload placement
- avoid hardcoded IPs in application configuration
- prefer service DNS names over machine names
- document every new platform capability
- verify each infrastructure layer before building the next one

---

## Future Improvements

Near-term architecture improvements:

- ingress controller
- TLS certificate management
- additional `.home.arpa` service records

Longer-term improvements:

- high availability control plane
- x86 worker nodes
- storage layer
- monitoring and logging
- GitOps
- AI platform
- dedicated service catalog

---

## Related Documents

- [Vision](vision.md)
- [Repository Structure](repository.md)
- [Roadmap](roadmap.md)
