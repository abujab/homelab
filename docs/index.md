# HomeLab Documentation

---

## Purpose

This documentation describes the current and target HomeLab platform: a private
cloud built with reproducible automation, reviewed architecture and operational
runbooks.

## Scope

The documentation covers:

- project vision, current architecture and target direction
- the Raspberry Pi, Ansible and K3s foundations
- wired networking, MetalLB, Pi-hole, Traefik and private HTTPS
- qualified host storage and current storage limitations
- bootstrap, maintenance, recovery and troubleshooting procedures
- authoritative inventory, addressing, software, service and ADR references

Observability, replicated storage, GitOps, secrets management, NAS, x86 compute
and AI workloads remain future capabilities unless explicitly marked otherwise.

## Background

HomeLab began as a four-node Raspberry Pi cluster and now operates as a small
private-cloud foundation managed from an Arch Linux workstation.

Current platform capabilities include:

- four Raspberry Pi 4 Model B nodes running the Debian 13 baseline
- Ansible-managed operating system, wired network and K3s configuration
- a K3s cluster with one control plane and three workers
- MetalLB Layer 2 LoadBalancer support and Pi-hole internal DNS
- Traefik shared ingress at `192.168.68.201`
- a private two-tier PKI and cert-manager certificate automation
- trusted HTTPS for `test.home.arpa` and `pihole.home.arpa`
- one qualified dedicated disk on `pi4mB01`

## Architecture / Implementation

The site is organized by responsibility:

```text
Overview
    Vision, current and target architecture, roadmap and repository model.

Architecture Decisions
    Historical rationale for significant design choices.

Infrastructure
    Component design and repository-controlled implementation.

Operations
    Bootstrap, maintenance, recovery and troubleshooting procedures.

Reference
    Authoritative inventory, naming, versions, services, ADR register and terms.

Development
    Review and contribution workflow.
```

Start with [Architecture](overview/architecture.md) for the system model or
[Reference](reference/index.md) for an exact current value.

## Design Decisions

- Markdown in Git is the documentation source.
- MkDocs Material builds the navigable site.
- Reference pages own stable lookup data.
- Architecture pages separate current and target state.
- Operations pages remain command-oriented.
- ADRs preserve decision history rather than being rewritten as status reports.

## Best Practices

- update documentation in the same work order as infrastructure changes
- verify current claims against executable configuration and evidence
- link to authoritative reference tables instead of duplicating them
- label planned and exploratory capabilities explicitly
- run `mkdocs build --strict` before review

## Future Improvements

- automate documentation validation in CI
- add reference generation checks against Ansible and Kubernetes sources
- expand operations and terminology only when new platform capabilities exist

## Related Documents

- [Vision](overview/vision.md)
- [Architecture](overview/architecture.md)
- [Repository Structure](overview/repository.md)
- [Roadmap](overview/roadmap.md)
- [Reference](reference/index.md)
- [Service Catalog](reference/service-catalog.md)
- [Decision Register](reference/decision-register.md)
