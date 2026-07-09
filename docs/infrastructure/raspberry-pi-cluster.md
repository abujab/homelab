# Raspberry Pi Cluster

---

## Purpose

This document describes the current Raspberry Pi infrastructure foundation for HomeLab.

It records the physical nodes, operating system baseline, network addresses and current Kubernetes roles so the cluster can be understood without relying on conversation history.

## Scope

This document covers:

- the four-node Raspberry Pi 4 cluster
- hostnames and IP addresses
- operating system and CPU architecture
- management workstation model
- current node roles
- current topology
- future hardware expansion context

This document does not describe Ansible task implementation or Kubernetes workload deployment. Those details belong in the Ansible and Kubernetes infrastructure documents.

## Background

HomeLab currently runs on four Raspberry Pi 4 Model B nodes.

The nodes form the ARM infrastructure tier of the platform. They provide the first always-on compute layer and currently host a K3s Kubernetes cluster.

The cluster is managed from an Arch Linux laptop using SSH, Ansible and kubectl.

## Architecture / Implementation

Current physical topology:

```text
Arch Linux management laptop
        |
        | SSH / Ansible / kubectl
        v
Home LAN 192.168.68.0/24
        |
        +-- pi4mB01 / 192.168.68.101
        +-- pi4mB02 / 192.168.68.102
        +-- pi4mB03 / 192.168.68.103
        +-- pi4mB04 / 192.168.68.104
```

Current node inventory:

| Host | IP Address | Hardware | Operating System | Architecture | Current Role |
|------|------------|----------|------------------|--------------|--------------|
| pi4mB01 | 192.168.68.101 | Raspberry Pi 4 Model B | Raspberry Pi OS / Debian 13 | ARM64 | K3s control plane |
| pi4mB02 | 192.168.68.102 | Raspberry Pi 4 Model B | Raspberry Pi OS / Debian 13 | ARM64 | K3s worker |
| pi4mB03 | 192.168.68.103 | Raspberry Pi 4 Model B | Raspberry Pi OS / Debian 13 | ARM64 | K3s worker |
| pi4mB04 | 192.168.68.104 | Raspberry Pi 4 Model B | Raspberry Pi OS / Debian 13 | ARM64 | K3s worker |

The current Kubernetes topology is intentionally simple:

```text
K3s cluster
|
+-- pi4mB01
|   +-- control plane
|
+-- pi4mB02
|   +-- worker
|
+-- pi4mB03
|   +-- worker
|
+-- pi4mB04
    +-- worker
```

The nodes are addressed through DHCP reservations on the home LAN. Ansible stores the current host IP addresses in `ansible/inventories/home/host_vars/`.

## Design Decisions

### Raspberry Pi OS Lite for node operating system

Raspberry Pi OS Lite was selected for hardware compatibility, stable updates and lower maintenance overhead on Raspberry Pi hardware.

### Arch Linux laptop as management workstation

The management laptop is outside the cluster and acts as the operator workstation. It runs Ansible and kubectl against the Raspberry Pi nodes.

### Machine names identify hardware

Hostnames such as `pi4mB01` identify physical machines. Service names will use DNS names such as `grafana.home.arpa` or `elm.home.arpa` rather than machine names.

### Single control plane for the current foundation

The current platform uses `pi4mB01` as the only K3s control-plane node. High availability is a future improvement, not part of the current implementation.

## Best Practices

- keep hostnames stable and tied to hardware identity
- keep DHCP reservations aligned with Ansible host variables
- manage baseline configuration through Ansible
- avoid publishing services through machine hostnames
- verify node health before introducing additional platform layers
- document hardware role changes when they happen

## Future Improvements

Planned expansion includes:

- additional ARM infrastructure nodes
- future Turing Pi and RK1 hardware
- x86 Linux laptops or mini PCs for heavier compute
- architecture-aware Kubernetes scheduling
- possible high-availability control plane design
- dedicated workload placement labels and taints

## Related Documents

- [Architecture](../overview/architecture.md)
- [Repository Structure](../overview/repository.md)
- [Roadmap](../overview/roadmap.md)
- [Ansible](ansible.md)
- [Kubernetes](kubernetes.md)
