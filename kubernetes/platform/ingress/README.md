# Ingress Foundation

---

## Purpose

This directory defines the HomeLab ingress foundation.

Traefik is deployed as the standard Kubernetes Ingress Controller through the
official Traefik Helm chart.

## Scope

This directory contains:

- the `ingress` namespace manifest
- pinned Helm values for Traefik
- a test application used to verify host-based routing

It does not define production application routes or TLS automation.

## Background

HomeLab uses MetalLB for LAN LoadBalancer IPs and Pi-hole for internal DNS.

Traefik receives one MetalLB IP and routes HTTP traffic to services by hostname.

## Architecture / Implementation

Traefik is installed with:

```bash
helm upgrade --install traefik traefik/traefik \
  --repo https://traefik.github.io/charts \
  --version 41.0.2 \
  --namespace ingress \
  --values kubernetes/platform/ingress/values.yaml \
  --kubeconfig ansible/kubeconfig
```

Current pinned versions:

| Component | Version |
|-----------|---------|
| Traefik Helm chart | `41.0.2` |
| Traefik app | `v3.7.6` |

The Traefik Service requests MetalLB IP `192.168.68.201` and exposes ports `80`
and `443`.

The dashboard is enabled internally but is not exposed through an IngressRoute
or public Service port.

## Design Decisions

Traefik is managed by this repository instead of using the K3s packaged
Traefik component.

The first test route is `test.home.arpa`.

## Best Practices

- deploy Traefik through Helm with a pinned chart version
- keep application routes in declarative manifests
- do not expose the Traefik dashboard without authentication
- use Pi-hole DNS records for `.home.arpa` names
- reserve TLS configuration for the TLS foundation sprint

## Future Improvements

- private certificate authority
- automated certificate management
- HTTPS for internal applications
- production routes for observability, registry and application services
- dashboard access protected by authentication and TLS

## Related Documents

- [Ingress](../../../docs/infrastructure/ingress.md)
- [Ingress Operations](../../../docs/operations/ingress.md)
- [ADR-0010 Ingress Foundation](../../../docs/decisions/ADR-0010-ingress-foundation.md)
