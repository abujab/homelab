# ADR-0009 Wired Network for Cluster Nodes

**Status:** Accepted

## Context

HomeLab exposes platform services on the LAN through MetalLB in Layer 2 mode.

During networking foundation validation, Raspberry Pi Wi-Fi was not reliable enough for normal cluster transport. MetalLB Layer 2 depends on predictable ARP behavior and on speaker communication between nodes. Those assumptions are better served by wired Ethernet than by Raspberry Pi Wi-Fi.

The current cluster nodes are connected through a TP-Link TL-SG108E Ethernet switch.

## Decision

HomeLab Kubernetes nodes use wired Ethernet as their normal production transport.

Wi-Fi is disabled on dedicated cluster nodes and is not relied upon for Kubernetes, MetalLB or platform-service traffic.

Wi-Fi may be re-enabled manually only for exceptional recovery work. After recovery, nodes should return to the managed wired baseline by running the Ansible baseline playbook.

## Alternatives Considered

### Continue using Wi-Fi as a cluster transport

Advantages

- No switch or cabling requirement
- Useful for temporary bootstrap or emergency recovery

Disadvantages

- Less predictable ARP behavior for MetalLB Layer 2 service IPs
- Less reliable memberlist communication between MetalLB speakers
- More sensitive to signal quality, interference and power management
- Unsuitable as the normal transport for future storage and compute workloads

### Use wired Ethernet as the cluster transport

Advantages

- Stable Layer 2 behavior for MetalLB
- Predictable default routes and node addresses
- Better fit for Kubernetes node traffic
- Better foundation for future storage, observability and compute workloads
- Easier operational model for dedicated infrastructure nodes

Disadvantages

- Requires switch ports and cabling
- Recovery requires direct console, existing Ethernet SSH or another documented access path if Ethernet fails

## Consequences

Positive

- MetalLB Layer 2 service exposure has a reliable Ethernet and ARP foundation
- Kubernetes node traffic uses the same managed transport on every Raspberry Pi
- Future platform services can assume wired cluster connectivity
- Wi-Fi state is managed through Ansible and can be verified repeatedly

Negative

- Wi-Fi is no longer a normal access path for cluster nodes
- Emergency Wi-Fi recovery must be deliberate and followed by a return to the managed baseline
- Ethernet cabling and switch availability become part of the infrastructure baseline

## References

- [ADR-0008 Networking Foundation](ADR-0008-networking-foundation.md)
- [Networking](../infrastructure/networking.md)
- [Ansible](../infrastructure/ansible.md)
