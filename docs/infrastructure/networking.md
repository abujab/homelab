# Networking

---

## Purpose

This document describes the current HomeLab networking foundation and the planned direction for internal service discovery.

Networking is intentionally documented before additional platform services are introduced because future services need stable names and predictable exposure.

## Scope

This document covers:

- current LAN range
- DHCP reservations
- current host IPs
- future `.home.arpa` DNS plan
- future Pi-hole plan
- future MetalLB plan
- future ingress plan
- IBM ELM future DNS target

This document does not define a final production network architecture. VLANs, segmentation, TLS automation and external access are future topics.

## Background

The current platform runs on the home LAN:

```text
192.168.68.0/24
```

The Raspberry Pi nodes are reached by reserved LAN addresses. Ansible and kubectl run from the management workstation over this network.

## Architecture / Implementation

Current network topology:

```text
Arch Linux management laptop
        |
        v
Home LAN 192.168.68.0/24
        |
        +-- pi4mB01 / 192.168.68.101
        +-- pi4mB02 / 192.168.68.102
        +-- pi4mB03 / 192.168.68.103
        +-- pi4mB04 / 192.168.68.104
```

Current DHCP reservations:

| Host | Reserved IP |
|------|-------------|
| pi4mB01 | 192.168.68.101 |
| pi4mB02 | 192.168.68.102 |
| pi4mB03 | 192.168.68.103 |
| pi4mB04 | 192.168.68.104 |

The reserved addresses are reflected in Ansible host variables under:

```text
ansible/inventories/home/host_vars/
```

No internal DNS service, Kubernetes load balancer or ingress controller is currently implemented.

## Design Decisions

### DHCP reservations for current nodes

DHCP reservations keep node addressing stable while avoiding manual static IP configuration on each Raspberry Pi.

### `.home.arpa` for internal DNS

The planned internal DNS namespace is `.home.arpa`.

This avoids using `.local`, which is reserved for multicast DNS and can create confusing resolver behavior.

### Service names over machine names

Machine names identify hardware. Service names should identify functionality.

Examples of future service names:

```text
grafana.home.arpa
registry.home.arpa
elm.home.arpa
```

### Defer load balancing and ingress

MetalLB and ingress are planned but not currently installed. This keeps service exposure as a deliberate future architecture step rather than an implicit K3s default.

## Best Practices

- keep DHCP reservations aligned with Ansible host variables
- use DNS names for services instead of node hostnames
- avoid hardcoded IP addresses in application configuration
- reserve machine names for hardware identity
- introduce load balancer IP pools intentionally
- document every service name as it is introduced
- verify name resolution before publishing dependent services

## Future Improvements

Planned networking work includes:

- Pi-hole or equivalent internal DNS
- `.home.arpa` service records
- MetalLB for LAN-facing Kubernetes load balancer IPs
- ingress controller deployment
- first stable internal service URLs
- IBM ELM publication through a target name such as `elm.home.arpa`
- TLS certificate management
- future network segmentation or VLAN design

## Related Documents

- [Raspberry Pi Cluster](raspberry-pi-cluster.md)
- [Kubernetes](kubernetes.md)
- [Security](security.md)
- [Architecture](../overview/architecture.md)
- [Roadmap](../overview/roadmap.md)
