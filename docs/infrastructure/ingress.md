# Ingress

---

## Purpose

This document describes the HomeLab ingress foundation.

Ingress provides the shared HTTP and HTTPS entry point for current and future
browser-facing applications.

## Scope

This document covers:

- Traefik as the Kubernetes Ingress Controller
- MetalLB integration
- Pi-hole DNS integration
- host-based routing
- the current test application
- current limitations

This document does not cover external internet exposure, authentication
middleware or production application onboarding.

## Background

Before ingress, each web application would need its own MetalLB
LoadBalancer Service and LAN IP address.

Ingress changes the model. Pi-hole resolves application hostnames to the single
Traefik LoadBalancer IP. Traefik then routes requests to Kubernetes Services by
the HTTP `Host` header.

## Architecture / Implementation

Current application ingress traffic flow:

```text
Client browser
|
+-- DNS query: application.home.arpa
|   |
|   +-- Pi-hole / 192.168.68.200
|       |
|       +-- answer: 192.168.68.201
|
+-- HTTPS request to 192.168.68.201
    |
    +-- MetalLB advertises Traefik Service IP
        |
        +-- Traefik LoadBalancer Service
            |
            +-- Traefik pod
                |
                +-- Ingress rule for application.home.arpa
                    |
                    +-- ClusterIP Service
                        |
                        +-- application Pod
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
| HTTP redirect | Redirects to HTTPS |
| TLS certificates | Per-host Secrets including `ingress/test-home-arpa-tls` and `networking/pihole-home-arpa-tls` |
| Dashboard exposure | Not exposed |

### Relationship to Pi-hole

Pi-hole remains the dedicated DNS service.

Application DNS records point to the Traefik ingress IP:

```text
pihole.home.arpa -> 192.168.68.201
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

This address exposes only Pi-hole DNS on TCP and UDP port 53. The Pi-hole Web
UI follows the standard ingress pattern:

```text
pihole.home.arpa -> Traefik -> pihole-web Service -> Pi-hole Pod
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

TLS is terminated by Traefik using certificates issued by cert-manager from the
HomeLab Server Issuing CA.

HTTP between Traefik and ordinary application backends is the default. An
application requiring end-to-end TLS, mTLS or TLS passthrough requires an
explicit architectural exception.

HTTP-to-HTTPS redirection is configured at the Traefik `web` entry point so
current ingress routes use HTTPS by default.

No wildcard DNS record exists in the current configuration.

## Best Practices

- publish web applications with `Ingress` resources
- use `ClusterIP` Services behind ingress
- point application DNS records at the Traefik LoadBalancer IP
- keep the Traefik dashboard private until authenticated access is designed
- avoid allocating a new LoadBalancer IP for each web application
- pin Helm chart versions in repository-managed configuration
- use cert-manager managed TLS Secrets for ingress routes
- reserve dedicated LoadBalancer Services for non-HTTP protocols that require
  direct LAN access

## Future Improvements

- protected Traefik dashboard access
- middleware standards for authentication and headers
- production application ingress conventions
- optional wildcard DNS after the service naming model matures

## Related Documents

- [Networking](networking.md)
- [Kubernetes](kubernetes.md)
- [Security](security.md)
- [PKI](pki.md)
- [Ingress Operations](../operations/ingress.md)
- [Naming and Addressing](../reference/naming-and-addressing.md)
- [Service Catalog](../reference/service-catalog.md)
- [Software Inventory](../reference/software-inventory.md)
- [ADR-0010 Ingress Foundation](../decisions/ADR-0010-ingress-foundation.md)
- [ADR-0012 Application Exposure Through the Shared Ingress Layer](../decisions/ADR-0012-application-exposure-through-shared-ingress.md)
