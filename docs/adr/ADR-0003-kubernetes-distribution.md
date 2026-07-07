# ADR-0003 Kubernetes Distribution

**Status:** Proposed

## Context

The platform requires production-grade Kubernetes while remaining lightweight enough for Raspberry Pi hardware.

## Decision

Adopt K3s.

## Alternatives Considered

### kubeadm

Advantages

- Upstream Kubernetes

Disadvantages

- Higher operational complexity

### MicroK8s

Advantages

- Easy installation

Disadvantages

- Higher resource usage
- Snap dependency

### K3s

Advantages

- Lightweight
- Excellent ARM support
- Small memory footprint
- Production proven

Disadvantages

- Bundled components require understanding

## Consequences

Positive

- Suitable for low-power hardware
- Easy upgrades
- Strong ARM ecosystem

Negative

- Less identical to upstream kubeadm deployments

## References

https://k3s.io/