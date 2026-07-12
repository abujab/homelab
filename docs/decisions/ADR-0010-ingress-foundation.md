# ADR-0010 Ingress Foundation

**Status:** Accepted

## Context

HomeLab already exposes LAN services through MetalLB and resolves internal
service names through Pi-hole.

Without ingress, each future web application would need its own MetalLB
LoadBalancer IP. That model does not scale well for platform services such as
Grafana, Harbor, ArgoCD, IBM Jazz, GitLab, Prometheus and Alertmanager.

K3s packaged Traefik and ServiceLB are disabled. This allows ingress and load
balancing to be introduced through explicit repository-managed architecture.

## Decision

Deploy Traefik as the standard Kubernetes Ingress Controller for HomeLab.

Traefik is installed from the official Traefik Helm chart and managed by this
repository.

The initial ingress endpoint is:

```text
192.168.68.201
```

The IngressClass is:

```text
traefik
```

Traefik exposes HTTP and HTTPS entry points on ports `80` and `443`.

TLS termination is intentionally deferred to the TLS foundation sprint.

The Traefik dashboard is not exposed publicly.

## Alternatives Considered

### Per-application LoadBalancer services

Advantages

- Simple for the first few services
- No ingress controller required

Disadvantages

- Consumes one LAN IP per application
- Spreads routing decisions across many Services
- Does not provide a standard HTTP routing layer
- Makes future TLS and authentication policy harder to centralize

### K3s packaged Traefik

Advantages

- Bundled with K3s
- Minimal installation work

Disadvantages

- Was intentionally disabled during K3s installation
- Less explicit than repository-managed platform configuration
- Makes chart version and values harder to review through Git

### Repository-managed Traefik

Advantages

- Uses the official Helm chart
- Keeps chart version and values visible in Git
- Provides a single HTTP and HTTPS entry point
- Supports host-based routing for future services
- Aligns with MetalLB and Pi-hole architecture

Disadvantages

- Adds another platform component
- Requires Helm operational knowledge
- TLS and dashboard exposure still require future work

## Consequences

Positive

- Future web applications can share one LAN ingress IP
- Application publication requires a Service, Ingress and DNS record
- Host-based routing becomes the standard web exposure model
- Traefik can become the future TLS termination point

Negative

- The ingress endpoint becomes a shared dependency for web applications
- DNS records must point application hostnames to the ingress IP
- HTTPS is not complete until TLS foundation work is implemented

## References

- [ADR-0008 Networking Foundation](ADR-0008-networking-foundation.md)
- [ADR-0009 Wired Network for Cluster Nodes](ADR-0009-wired-network-for-cluster-nodes.md)
- [Ingress](../infrastructure/ingress.md)

https://github.com/traefik/traefik-helm-chart

https://doc.traefik.io/traefik/providers/kubernetes-ingress/
