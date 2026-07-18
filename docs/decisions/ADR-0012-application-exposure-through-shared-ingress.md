# ADR-0012 Application Exposure Through the Shared Ingress Layer

**Status:** Accepted

## Context

HomeLab initially exposed Pi-hole DNS and its browser interface through one
LoadBalancer Service at `192.168.68.200`. This combined a non-HTTP
infrastructure protocol that requires direct LAN access with a web application
that can use the shared ingress platform.

Allocating a LoadBalancer IP to every browser-facing application would consume
the MetalLB pool, distribute TLS configuration across applications and expose
unnecessary ports directly to the LAN.

## Decision

Web applications deployed in HomeLab will normally:

- use a hostname under `home.arpa`
- resolve that hostname to Traefik at `192.168.68.201`
- use a standard Kubernetes `Ingress` with `ingressClassName: traefik`
- terminate TLS at Traefik
- obtain short-lived certificates from cert-manager through the HomeLab Server
  Issuing CA
- use an internal ClusterIP Service as the Ingress backend
- use HTTP between Traefik and the backend unless a documented exception
  requires stronger protection
- avoid dedicated LoadBalancer IPs for ordinary Web UIs

Non-HTTP infrastructure protocols may use dedicated LoadBalancer Services when
direct LAN access is required. Pi-hole DNS on TCP and UDP port 53 at
`192.168.68.200` is the first documented exception. Its Web UI is exposed only
through Traefik as `https://pihole.home.arpa/admin/`.

## Alternatives Considered

### One LoadBalancer for Pi-hole DNS and HTTP

Advantages:

- one Service manifest
- direct access is simple

Disadvantages:

- mixes infrastructure and browser-facing responsibilities
- bypasses the shared TLS and ingress platform
- exposes the administrative HTTP port directly to the LAN

### Native HTTPS in every application

Advantages:

- encryption reaches each application directly

Disadvantages:

- duplicates certificate and TLS configuration
- increases operational variation
- requires each application to support the HomeLab PKI model

### TLS from clients through Traefik and again to every backend

Advantages:

- encrypts traffic inside the Kubernetes network

Disadvantages:

- adds certificate distribution and backend trust configuration
- introduces complexity that ordinary internal Web UIs do not currently need

### TLS passthrough

Advantages:

- the backend controls the complete TLS session

Disadvantages:

- moves certificate lifecycle and TLS policy into each application
- reduces Traefik's ability to provide a consistent termination model

### Shared-ingress TLS termination

Advantages:

- centralizes TLS termination and certificate lifecycle management
- provides consistent hostname-based routing
- reduces MetalLB address consumption and direct port exposure
- creates a reusable application-deployment pattern
- keeps application configuration simple

Disadvantages:

- ordinary backend traffic is unencrypted inside the Kubernetes network
- application DNS depends on the shared ingress endpoint

## Consequences

Positive:

- future Web UIs share one ingress address and a consistent certificate model
- infrastructure protocols and browser interfaces have separate Services
- ordinary applications need only a ClusterIP Service and an Ingress
- fewer application ports are exposed directly to the LAN

Negative:

- traffic from Traefik to ordinary application backends is unencrypted
- applications requiring end-to-end TLS, mTLS or TLS passthrough require an
  explicit architectural exception
- DNS and other non-HTTP protocols cannot use a normal HTTP Ingress
- application DNS records must point to Traefik rather than application
  Services
- clients must trust the HomeLab Root CA to avoid certificate warnings

## References

- [ADR-0008 Networking Foundation](ADR-0008-networking-foundation.md)
- [ADR-0010 Ingress Foundation](ADR-0010-ingress-foundation.md)
- [ADR-0011 PKI and TLS Foundation](ADR-0011-pki-and-tls-foundation.md)
- [Ingress](../infrastructure/ingress.md)
- [Networking](../infrastructure/networking.md)
