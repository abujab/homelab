# ADR-0008 Networking Foundation

**Status:** Accepted

## Context

HomeLab needs stable LAN service exposure before production applications are deployed.

The K3s cluster currently has Traefik and ServiceLB disabled so that ingress, load balancing and service naming can be introduced intentionally.

The platform requires:

- Layer 2 LoadBalancer support on the home LAN
- internal DNS for `.home.arpa`
- stable service names
- a foundation for future ingress and application services

## Decision

Use MetalLB in Layer 2 mode for Kubernetes LoadBalancer services.

Use Pi-hole as the initial internal DNS service.

Reserve `.home.arpa` for internal service names.

The first service IP pool is:

```text
192.168.68.200-192.168.68.220
```

The first stable service endpoint is:

```text
pihole.home.arpa -> 192.168.68.200
```

Reserve the future IBM ELM service name:

```text
elm.home.arpa
```

No IBM ELM migration is part of this decision.

## Alternatives Considered

### K3s ServiceLB

Advantages

- Built into K3s
- Simple default behavior

Disadvantages

- Less explicit than a dedicated load balancer configuration
- Does not establish a clear platform IP pool
- Was intentionally disabled during K3s installation

### MetalLB

Advantages

- Designed for bare-metal Kubernetes clusters
- Supports Layer 2 mode for simple LAN environments
- Uses Kubernetes custom resources for address pools and advertisements
- Keeps service exposure declarative

Disadvantages

- Adds another platform component
- Requires careful IP pool selection outside normal DHCP assignment

### Router-only DNS

Advantages

- Simple if the home router supports local DNS records

Disadvantages

- Router feature support varies
- DNS configuration would live outside the Git repository
- Harder to keep service naming documented and reproducible

### Pi-hole

Advantages

- Provides internal DNS and DNS forwarding
- Runs as a Kubernetes workload
- Configuration can be managed declaratively
- Establishes a foundation for `.home.arpa` service records

Disadvantages

- Requires persistent configuration
- Secrets management for the administrative password is still basic

## Consequences

Positive

- Kubernetes LoadBalancer services can receive LAN IPs
- Internal service naming has a concrete implementation
- Pi-hole provides DNS forwarding and local service records
- Future ingress and application work can use stable service names
- Pi-hole uses an immutable image digest for reproducible deployment

Negative

- The MetalLB address pool must not overlap with DHCP-assigned addresses
- Pi-hole becomes an important infrastructure service
- Administrative password handling is local-only and should be improved in a future secrets-management sprint

## References

- [ADR-0009 Wired Network for Cluster Nodes](ADR-0009-wired-network-for-cluster-nodes.md)

https://metallb.universe.tf/installation/

https://metallb.universe.tf/configuration/

https://docs.pi-hole.net/docker/configuration/
