# Architecture

---

## Purpose

This document describes the current HomeLab architecture and its separately
defined target direction.

## Scope

It covers physical topology, Kubernetes roles, service exposure, certificate
flow, current storage and potential future platform tiers. Operational commands
belong in the runbooks, and exact lookup values belong in Reference.

## Background

The current platform was built incrementally through Infrastructure Sprints 1
through 9:

1. Raspberry Pi and management workstation foundation
2. Ansible automation
3. K3s Kubernetes
4. MetalLB and Pi-hole networking
5. wired Ethernet transport
6. Traefik ingress
7. private PKI and cert-manager
8. Pi-hole secure ingress
9. qualification of one dedicated storage disk on `pi4mB01`

The platform is operational, but it is not yet highly available and does not
have replicated storage, GitOps, observability, a NAS or x86 compute nodes.

## Architecture / Implementation

### Current Architecture

#### Physical topology

```text
Arch Linux management workstation
  |  Git / SSH / Ansible / kubectl / Helm / PKI / MkDocs
  |
Home router and default gateway 192.168.68.1
  |
Home LAN 192.168.68.0/22
  |
TP-Link TL-SG108E Ethernet switch
  |
  +-- pi4mB01 / eth0 / 192.168.68.101
  |     K3s control plane
  |     qualified 160 GB disk mounted at /srv/longhorn
  |
  +-- pi4mB02 / eth0 / 192.168.68.102
  |     K3s worker; known disk not connected or qualified
  |
  +-- pi4mB03 / eth0 / 192.168.68.103
  |     K3s worker; no qualified dedicated storage
  |
  +-- pi4mB04 / eth0 / 192.168.68.104
        K3s worker; no qualified dedicated storage
```

All cluster nodes use wired Ethernet. The Ansible network role verifies `eth0`,
the inventory address and the default route before disabling Wi-Fi through
NetworkManager.

#### Kubernetes topology

```text
K3s cluster
  |
  +-- pi4mb01  Ready  control-plane
  +-- pi4mb02  Ready  worker
  +-- pi4mb03  Ready  worker
  +-- pi4mb04  Ready  worker
  |
  +-- K3s-managed platform components
  |     CoreDNS
  |     Metrics Server
  |     Local Path Provisioner
  |     containerd
  |
  +-- Repository-managed platform components
        MetalLB
        Pi-hole
        Traefik
        cert-manager
```

K3s packaged Traefik and ServiceLB remain disabled. MetalLB and the
repository-managed Traefik release provide those responsibilities explicitly.

#### Service exposure

```text
LAN client
  |
  +-- DNS query --------------------------+
  |                                      |
  |                         Pi-hole LoadBalancer
  |                         192.168.68.200:53
  |                                      |
  |                         home.arpa answer
  |                         192.168.68.201
  |
  +-- HTTPS request to 192.168.68.201 ----+
                                         |
                              MetalLB advertises Traefik
                                         |
                              Traefik :443 terminates TLS
                                         |
                         +---------------+---------------+
                         |                               |
               pihole.home.arpa                 test.home.arpa
                         |                               |
                  pihole-web Service                whoami Service
                         |                               |
                    Pi-hole Pod                    whoami Pod
```

Pi-hole DNS is the direct non-HTTP exception at `192.168.68.200`. The Pi-hole
Web UI and the validation application share Traefik at `192.168.68.201`.
The [Service Catalog](../reference/service-catalog.md) is authoritative for
service status and exposure.

#### Certificate flow

```text
Offline trust domain

HomeLab Root CA
  |
  +-- HomeLab Server Issuing CA
  |     certificate and key imported as a runtime Kubernetes Secret
  |                         |
  |                  ClusterIssuer/homelab-server-ca
  |                         |
  |                  cert-manager Certificates
  |                         |
  |                  Kubernetes TLS Secrets
  |                         |
  |                  Traefik TLS termination
  |
  +-- HomeLab Client Issuing CA
        offline; no current mTLS deployment
```

Clients trust HomeLab HTTPS only after the Root CA is installed and its
fingerprint is verified. The Root CA private key is not stored in Kubernetes.

#### Current storage topology

```text
Kubernetes workloads
  |
  +-- StorageClass/local-path
        |
        +-- node-local persistent volumes

pi4mB01 host storage foundation
  |
  +-- Hitachi 160 GB disk
        |
        +-- ext4 LABEL=pi-cl-storage
              |
              +-- /srv/longhorn
                    prepared host path only
                    no Longhorn installation
```

Only `pi4mB01` has qualified dedicated storage. Local Path Provisioner remains
the current Kubernetes storage component. No replica, failover or backup target
is provided by the prepared host mount.

#### Current architecture state

| Capability | State |
|------------|-------|
| Four-node Raspberry Pi K3s cluster | Current |
| Wired Ethernet cluster transport | Current |
| MetalLB Layer 2 load balancing | Current |
| Pi-hole internal DNS | Current |
| Traefik shared ingress | Current |
| Private PKI and cert-manager | Current |
| Trusted `home.arpa` HTTPS for configured clients | Current |
| Local Path Provisioner | Current |
| Qualified dedicated disk on `pi4mB01` | Current |
| Longhorn or another replicated storage layer | Not implemented |
| NAS or centralized backup target | Not implemented |
| Observability, GitOps and secrets management | Not implemented |
| x86 compute and AI workloads | Not implemented |

### Target Architecture

The target direction extends the current platform without presenting future
ideas as approved implementation.

```text
Management and automation plane
  |
  +-- Git / Ansible / Kubernetes manifests / Helm / documentation
  |
Hybrid Kubernetes platform
  |
  +-- ARM infrastructure tier
  |     DNS, ingress and lightweight always-on services
  |
  +-- x86 compute tier
  |     build, developer and AI workloads
  |
  +-- platform services
        observability
        GitOps
        secrets management
        persistent storage
        backup and restore
```

#### Target storage direction

```text
Stateful workload
  |
  +-- PVC
        |
        +-- evaluated replicated storage platform
              |
              +-- qualified node storage on multiple nodes
              |
              +-- possible external backup target
                    NAS is exploratory, not approved
```

Longhorn is a planned evaluation, not an approved deployment. Evaluation is
blocked until at least one additional node has independently qualified storage
and a separate work order defines architecture, safety and acceptance criteria.
A centralized NAS or enterprise storage system is only a possible future backup
or storage component.

#### Target capability classifications

| Capability | State | Dependency |
|------------|-------|------------|
| Additional qualified node storage | Planned | Enclosure availability and independent qualification |
| Longhorn evaluation | Planned, blocked | At least one additional qualified storage node and approved work order |
| Observability | Planned | Approved stack and work order |
| GitOps | Planned | Resolution of ADR-0005 and approved work order |
| Secrets management | Planned | Approved security architecture |
| Centralized NAS or backup target | Exploratory | Storage and backup architecture |
| x86 compute tier | Planned | Hardware admission and scheduling design |
| AI workloads | Planned | Suitable compute, storage and observability |

## Design Decisions

### K3s on Raspberry Pi

K3s provides the current lightweight ARM64 Kubernetes foundation. The single
control plane is accepted for this stage but remains a failure domain.

### Explicit networking layers

MetalLB supplies LAN addresses, Pi-hole supplies internal DNS and Traefik
supplies shared HTTP and HTTPS ingress. Each component has one primary role.

### Private PKI

An offline Root CA and separate issuing CAs protect the trust anchor while
cert-manager automates short-lived server certificates.

### Storage qualification before orchestration

Hardware is qualified independently before it can participate in a future
distributed storage evaluation. A mount-path name does not imply deployment.

## Best Practices

- keep current and target diagrams separate
- use reference pages for exact inventory, addresses and versions
- express implementation through Ansible, Kubernetes manifests and Helm values
- prefer service DNS names to machine names
- add storage nodes only after independent qualification
- require an ADR and work order for material architecture changes
- verify backup and restore before hosting important stateful workloads

## Future Improvements

- qualify additional storage hardware
- evaluate replicated storage only after its dependencies are met
- add observability and secrets management through approved work orders
- evaluate high-availability control-plane and x86 scheduling designs
- define backup targets and recovery objectives

## Related Documents

- [Vision](vision.md)
- [Roadmap](roadmap.md)
- [Repository Structure](repository.md)
- [Reference](../reference/index.md)
- [Infrastructure Inventory](../reference/infrastructure-inventory.md)
- [Naming and Addressing](../reference/naming-and-addressing.md)
- [Service Catalog](../reference/service-catalog.md)
- [Decision Register](../reference/decision-register.md)
- [Networking](../infrastructure/networking.md)
- [Ingress](../infrastructure/ingress.md)
- [PKI](../infrastructure/pki.md)
- [Storage](../infrastructure/storage.md)
