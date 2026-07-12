# Ingress

---

## Purpose

This document describes the HomeLab ingress foundation.

Ingress provides a shared HTTP and HTTPS entry point for future web
applications.

## Scope

This document covers:

- Traefik as the Kubernetes Ingress Controller
- MetalLB integration
- Pi-hole DNS integration
- host-based routing
- the current test application
- current limitations

This document does not cover TLS automation, external internet exposure,
authentication middleware or production application onboarding.

## Background

Before ingress, each web application would need its own MetalLB
LoadBalancer Service and LAN IP address.

Ingress changes the model. Pi-hole resolves application hostnames to the single
Traefik LoadBalancer IP. Traefik then routes requests to Kubernetes Services by
the HTTP `Host` header.

## Architecture / Implementation

Current ingress traffic flow:

```text
Client browser
|
+-- DNS query: test.home.arpa
|   |
|   +-- Pi-hole / 192.168.68.200
|       |
|       +-- answer: 192.168.68.201
|
+-- HTTP request to 192.168.68.201
    |
    +-- MetalLB advertises Traefik Service IP
        |
        +-- Traefik LoadBalancer Service
            |
            +-- Traefik pod
                |
                +-- Ingress rule for test.home.arpa
                    |
                    +-- whoami Service
                        |
                        +-- whoami Pod
```

Current ingress endpoint:

| Setting | Value |
|---------|-------|
| Namespace | `ingress` |
| Ingress controller | Traefik |
| Helm chart | `traefik/traefik` |
| Chart version | `41.0.2` |
| App version | `v3.7.6` |
| IngressClass | `traefik` |
| LoadBalancer IP | `192.168.68.201` |
| HTTP port | `80` |
| HTTPS port | `443` |
| Dashboard exposure | Not exposed |

### Relationship to Pi-hole

Pi-hole remains the dedicated DNS service.

Application DNS records point to the Traefik ingress IP:

```text
test.home.arpa -> 192.168.68.201
```

Pi-hole does not proxy HTTP traffic. It only answers DNS queries.

Clients must use Pi-hole, or another resolver forwarding `.home.arpa` records
to Pi-hole, before browser access by hostname works without extra client-side
configuration.

### Relationship to MetalLB

MetalLB assigns and advertises the Traefik LoadBalancer IP on the LAN.

Traefik uses:

```text
192.168.68.201
```

Pi-hole continues to use:

```text
192.168.68.200
```

Both IPs are in the MetalLB address pool:

```text
192.168.68.200-192.168.68.220
```

### Relationship to Kubernetes Services

Applications do not need their own external LoadBalancer IP when they are
published through ingress.

The normal pattern is:

```text
Ingress -> ClusterIP Service -> Pods
```

The test application follows this pattern:

```text
test.home.arpa -> Traefik -> whoami Service -> whoami Pod
```

### Host header routing

Ingress routing depends on the HTTP `Host` header.

For example:

```text
Host: test.home.arpa
```

Traefik matches that hostname to an Ingress rule and forwards the request to the
configured Kubernetes Service.

This is why DNS must resolve the application name to the Traefik IP instead of
to the backend Pod or Service directly.

## Design Decisions

Traefik is deployed through the official Helm chart instead of the K3s packaged
component.

K3s ServiceLB remains disabled. MetalLB remains the LAN LoadBalancer
implementation.

TLS is deferred to the successor TLS foundation work order.

No wildcard DNS records are created in this sprint.

## Best Practices

- publish web applications with `Ingress` resources
- use `ClusterIP` Services behind ingress
- point application DNS records at the Traefik LoadBalancer IP
- keep the Traefik dashboard private until authentication and TLS exist
- avoid allocating a new LoadBalancer IP for each web application
- pin Helm chart versions in repository-managed configuration

## Future Improvements

- private certificate authority
- cert-manager or another certificate automation mechanism
- HTTPS for `.home.arpa` applications
- protected Traefik dashboard access
- middleware standards for authentication and headers
- production application ingress conventions
- optional wildcard DNS after the service naming model matures

## Related Documents

- [Networking](networking.md)
- [Kubernetes](kubernetes.md)
- [Security](security.md)
- [Ingress Operations](../operations/ingress.md)
- [ADR-0010 Ingress Foundation](../decisions/ADR-0010-ingress-foundation.md)
