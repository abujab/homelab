# Reference

---

## Purpose

This section provides authoritative lookup information for the current HomeLab
platform.

Use these pages when an exact hostname, address, component version, service
state or Architecture Decision Record (ADR) status is required.

## Scope

The Reference section covers:

- physical and logical infrastructure inventory
- host naming and network addressing
- software and image versions
- deployed and planned service states
- the ADR register
- recurring HomeLab terminology

Architecture documents explain how the platform is designed. Operations
documents explain how to run it. Reference pages provide concise facts without
duplicating those narratives.

## Background

HomeLab inventory and addressing data was previously repeated across overview,
infrastructure and operations pages. Documentation Sprint 4 consolidated that
lookup data here and retained executable configuration as the underlying source
of truth.

`PROJECT_STATE.md` remains the concise record of the verified platform state at
the end of each sprint. This section expands that state into stable lookup
tables. When a reference value changes, update the executable configuration,
the relevant reference page and `PROJECT_STATE.md` in the same work package.

## Architecture / Implementation

| Reference | Authoritative For |
|-----------|-------------------|
| [Infrastructure Inventory](infrastructure-inventory.md) | Nodes, network hardware and storage hardware |
| [Naming and Addressing](naming-and-addressing.md) | Hostname convention, node addresses, service addresses and DNS names |
| [Software Inventory](software-inventory.md) | Verified pins and explicitly unpinned platform software |
| [Service Catalog](service-catalog.md) | Implemented services, exposure, persistence and operational state |
| [Decision Register](decision-register.md) | ADR status, implementation state and related work orders |
| [Glossary](glossary.md) | HomeLab terminology and abbreviations |

Source responsibilities:

| Source | Responsibility |
|--------|----------------|
| `ansible/` | Executable node inventory and host configuration |
| `kubernetes/` | Executable Kubernetes manifests and Helm values |
| `requirements/` | Pinned Python documentation dependencies |
| `PROJECT_STATE.md` | Current verified sprint-level state |
| `docs/reference/` | Authoritative human-readable lookup tables |
| `docs/infrastructure/` | Component design and implementation explanation |
| `docs/operations/` | Procedures, maintenance and recovery |
| `artifacts/` | Work-order verification evidence |

## Design Decisions

Reference pages identify their repository-controlled sources and use explicit
states such as Current, Planned, Exploratory and Pending verification.

Detailed benchmark output, operational commands and architecture rationale stay
with evidence, runbooks and ADRs instead of being copied into lookup tables.

## Best Practices

- update reference data in the same change as its executable source
- mark unverifiable values as `Pending verification`
- mark uncontrolled versions as `Not pinned`
- link to the authoritative table instead of creating a competing copy
- review the Reference section at the end of every infrastructure sprint

## Future Improvements

- automate selected inventory tables from declarative sources
- add validation that detects divergence between reference tables and manifests
- add lifecycle metadata when more platform services are introduced

## Related Documents

- [Project Architecture](../overview/architecture.md)
- [Roadmap](../overview/roadmap.md)
- [Repository Structure](../overview/repository.md)
- [HomeLab Documentation](../index.md)
- [PROJECT_STATE.md](https://github.com/abujab/homelab/blob/main/PROJECT_STATE.md)
