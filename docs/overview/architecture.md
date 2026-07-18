
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
8. introduce MetalLB and Pi-hole networking
9. enforce wired Ethernet as the cluster node transport
10. introduce Traefik ingress
11. introduce private PKI and trusted internal TLS

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
Home LAN 192.168.68.0/22
        │
        └── TP-Link TL-SG108E Ethernet switch
            ├── pi4mB01 / eth0 / 192.168.68.101
            ├── pi4mB02 / eth0 / 192.168.68.102
            ├── pi4mB03 / eth0 / 192.168.68.103
            └── pi4mB04 / eth0 / 192.168.68.104
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
- Traefik ingress
- cert-manager certificate automation
- HomeLab private PKI
- `.home.arpa` service naming
- `pihole.home.arpa` at `192.168.68.200`
- `test.home.arpa` at `192.168.68.201` over HTTPS
- wired Ethernet node transport
- Wi-Fi disabled on dedicated cluster nodes

Traefik and ServiceLB were disabled during K3s installation so that ingress and load balancing could be introduced intentionally. MetalLB provides LAN LoadBalancer support. Repository-managed Traefik now provides the shared ingress endpoint.

HomeLab uses an offline Root CA with separate Server and Client Issuing CAs.
cert-manager uses only the Server Issuing CA to automate server certificates.
Traefik terminates TLS and redirects HTTP traffic to HTTPS.

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

### Wired Ethernet as cluster transport

Dedicated cluster nodes use wired Ethernet for Kubernetes, MetalLB and platform-service traffic. Raspberry Pi Wi-Fi is retained only as an exceptional recovery option and is disabled by the managed baseline.

### Traefik as shared ingress

Traefik is the standard Kubernetes ingress controller. Future web applications should normally publish through host-based Ingress resources instead of receiving individual LoadBalancer IPs.

### Private PKI for internal TLS

The HomeLab Root CA is the private trust anchor for `home.arpa` services. The
Root key remains offline and signs issuing CAs only. Server certificate
automation is delegated to cert-manager through the Server Issuing CA.

---

## Best Practices

- keep control plane and worker roles explicit in inventory
- use Ansible groups to represent infrastructure intent
- use Kubernetes labels for workload placement
- avoid hardcoded IPs in application configuration
- prefer service DNS names over machine names
- use wired Ethernet for cluster node transport
- publish web applications through shared ingress where practical
- use cert-manager issued TLS certificates for ingress services
- document every new platform capability
- verify each infrastructure layer before building the next one

---

## Future Improvements

Near-term architecture improvements:

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
- [Ingress](../infrastructure/ingress.md)
- [PKI](../infrastructure/pki.md)
