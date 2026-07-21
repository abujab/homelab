# Architecture Decision Register

---

## Purpose

This register provides a concise index of every current HomeLab Architecture
Decision Record (ADR), its recorded status and its verified implementation
state.

## Scope

The register covers ADR-0001 through ADR-0012. It does not rewrite historical
decisions or treat implementation as an implicit status change.

## Background

An ADR records why a decision was made. The implementation-state column records
what exists now. These values can differ when an ADR status was not updated or
when only a foundation has been implemented.

## Architecture / Implementation

| ADR | Title | ADR Status | Decision Area | Implementation State | Related Work Order |
|-----|-------|------------|---------------|----------------------|--------------------|
| [ADR-0001](../decisions/ADR-0001-operating-system.md) | Operating System for Raspberry Pi Nodes | Accepted | Operating system | Implemented | WO-0001 |
| [ADR-0002](../decisions/ADR-0002-configuration-management.md) | Configuration Management | Accepted | Automation | Implemented | WO-0002 |
| [ADR-0003](../decisions/ADR-0003-kubernetes-distribution.md) | Kubernetes Distribution | Proposed | Kubernetes | Implemented: K3s is current; ADR status remains Proposed | WO-0003 |
| [ADR-0004](../decisions/ADR-0004-storage.md) | Persistent Storage | Proposed | Storage | Partially implemented: Local Path Provisioner and one qualified host disk; Longhorn not installed | WO-0009 foundation only |
| [ADR-0005](../decisions/ADR-0005-gitops.md) | GitOps Platform | Proposed | Delivery automation | Not implemented | None approved |
| [ADR-0006](../decisions/ADR-0006-repository-structure.md) | Repository Structure | Accepted | Repository | Implemented | WO-0002 and documentation sprints |
| [ADR-0007](../decisions/ADR-0007-homelab-target-architecture.md) | HomeLab Target Architecture | Pending verification | Target architecture | Cannot determine: tracked ADR file is empty | None recorded |
| [ADR-0008](../decisions/ADR-0008-networking-foundation.md) | Networking Foundation | Accepted | Load balancing and DNS | Implemented; Web exposure later refined by ADR-0012 | WO-0004 |
| [ADR-0009](../decisions/ADR-0009-wired-network-for-cluster-nodes.md) | Wired Network for Cluster Nodes | Accepted | Node networking | Implemented | WO-0005 |
| [ADR-0010](../decisions/ADR-0010-ingress-foundation.md) | Ingress Foundation | Accepted | Ingress | Implemented | WO-0006 |
| [ADR-0011](../decisions/ADR-0011-pki-and-tls-foundation.md) | PKI and TLS Foundation | Accepted | PKI and TLS | Implemented | WO-0007 |
| [ADR-0012](../decisions/ADR-0012-application-exposure-through-shared-ingress.md) | Application Exposure Through the Shared Ingress Layer | Accepted | Service exposure | Implemented | WO-0008 |

Status interpretation:

| Value | Meaning in This Register |
|-------|--------------------------|
| Accepted | The ADR records an approved decision |
| Proposed | The ADR itself remains undecided, even if related implementation exists |
| Implemented | Repository and completed-work-order evidence show the decision in use |
| Partially implemented | Supporting foundation exists, but the complete decision is not deployed |
| Not implemented | No repository-controlled implementation exists |
| Pending verification | The ADR source does not contain enough information to establish status |

### Review findings

- ADR-0003 still records `Proposed` although K3s is implemented and is the
  current Kubernetes distribution.
- ADR-0004 remains correctly Proposed because its Longhorn preference has not
  been accepted or deployed; WO-0009 qualified only one host disk.
- ADR-0007 is a zero-length tracked file. Its decision and status cannot be
  reconstructed safely from its filename.
- ADR-0010 is historical: its TLS deferral was subsequently addressed by
  ADR-0011 and WO-0007, not by rewriting ADR-0010.

## Design Decisions

This register separates an ADR's recorded status from current implementation.
It does not silently promote Proposed decisions to Accepted or fill missing ADR
content from assumptions.

## Best Practices

- create or update ADR status through explicit architecture review
- link each approved work order to the decisions it implements
- preserve historical context when a later ADR extends an earlier decision
- record contradictions here and in the documentation audit
- never infer an ADR decision from its filename alone

## Future Improvements

- reconcile ADR-0003 status through architecture review
- recover or replace ADR-0007 through a separately approved decision process
- add supersession metadata if a future ADR replaces an earlier decision

## Related Documents

- [Architecture](../overview/architecture.md)
- [Roadmap](../overview/roadmap.md)
- [Repository Structure](../overview/repository.md)
- [ADR Template](../decisions/ADR-template.md)
