# ADR-0001 Operating System for Raspberry Pi Nodes

**Status:** Accepted

## Context

The Kubernetes cluster requires a stable operating system that supports ARM64 hardware, long-term maintenance, predictable updates, and excellent Raspberry Pi compatibility.

Candidate operating systems included:

- Raspberry Pi OS Lite
- Arch Linux ARM
- Ubuntu Server

## Decision

Use Raspberry Pi OS Lite (64-bit) for all Raspberry Pi cluster nodes.

The management workstation remains Arch Linux.

## Alternatives Considered

### Raspberry Pi OS Lite

Advantages

- Official Raspberry Pi support
- Excellent hardware compatibility
- Stable kernel updates
- Large community
- Lower maintenance burden

Disadvantages

- Packages are generally older than Arch Linux.

### Arch Linux ARM

Advantages

- Rolling release
- Latest packages
- Excellent learning platform

Disadvantages

- Requires regular maintenance.
- Large upgrades after long periods may require manual intervention.
- Less suitable for infrastructure expected to remain unattended.

### Ubuntu Server

Advantages

- Enterprise ecosystem
- Long-term support

Disadvantages

- Larger footprint
- Less tightly integrated with Raspberry Pi hardware

## Consequences

Positive

- Stable cluster
- Reduced maintenance
- Excellent hardware compatibility

Negative

- Slightly older package versions

## References

https://www.raspberrypi.com/software/