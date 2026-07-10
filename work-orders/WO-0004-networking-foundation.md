# WORK ORDER

**ID:** WO-0004

**Title:** Networking Foundation

**Status:** Completed

**Primary Agent:** Codex

**Architect:** ChatGPT

**Owner:** Abdul Jabbar

**Target Release:** v0.5.0

---

# Objective

Build the networking foundation for the HomeLab Kubernetes platform.

This sprint establishes the platform services required before any production
applications are deployed.

The networking foundation shall provide:

- Layer 2 LoadBalancer support
- Internal DNS
- Stable service names
- Service exposure inside the LAN

No application workloads are part of this sprint.

---

# Scope

Infrastructure

- MetalLB
- Pi-hole
- Internal DNS
- Service naming
- Network documentation

Documentation

Update

- PROJECT_STATE.md
- Architecture documentation
- Infrastructure documentation
- Operations documentation where required

Repository

- Update ADRs if necessary.
- Update MkDocs navigation where required.

---

# Deliverables

## MetalLB

Implement MetalLB.

Requirements

- Layer 2 mode
- Dedicated address pool
- Address range documented
- Verification commands documented

Acceptance

A LoadBalancer Service receives an IP from the configured pool.

---

## Pi-hole

Deploy Pi-hole.

Requirements

- Kubernetes deployment
- Persistent configuration
- Stable LoadBalancer IP
- Administrative password documented
- DNS forwarding configured

Acceptance

Clients can successfully resolve public DNS through Pi-hole.

---

## Internal DNS

Configure the HomeLab naming convention.

Requirements

Use

```text
.home.arpa
```

Examples

```text
grafana.home.arpa

pihole.home.arpa

elm.home.arpa
```

Machine names must remain separate from service names.

---

## IBM ELM

Prepare DNS for the future IBM ELM instance.

Expected hostname

```text
elm.home.arpa
```

No migration is required.

Only reserve the naming convention.

---

## Documentation

Update:

Overview

if architectural diagrams change.

Infrastructure

Networking

Operations

if operational procedures change.

PROJECT_STATE.md

Current networking capability.

---

# Repository Standards

Codex shall:

Create a feature branch.

Example

```text
wo-0004-networking-foundation
```

Implementation must occur only on this branch.

Do not commit directly to main.

---

# Pull Request

After implementation Codex shall create a Pull Request.

PR title

```text
WO-0004: Networking Foundation
```

The PR description shall include:

## Summary

Implemented functionality.

## Validation

Commands executed.

## Documentation

Documents updated.

## Risks

Known limitations.

## Rollback

How to remove the changes.

---

# Validation

Infrastructure

```bash
kubectl get nodes

kubectl get pods -A

kubectl get svc -A

kubectl get ipaddresspools -A

kubectl get l2advertisements -A
```

Networking

DNS resolution

LoadBalancer allocation

Pi-hole UI reachable

MetalLB functioning

---

# Documentation Requirements

Documentation is mandatory.

Every infrastructure change shall update the relevant MkDocs pages.

Avoid duplicated documentation.

Link to existing documentation whenever possible.

---

# Acceptance Criteria

The sprint is complete when:

✓ MetalLB is operational.

✓ Pi-hole is operational.

✓ DNS resolution works.

✓ Internal naming convention established.

✓ IBM ELM naming reserved.

✓ Documentation updated.

✓ PROJECT_STATE.md updated.

✓ Pull Request opened.

✓ Architecture review completed.

---

# Architecture Review

After the Pull Request is created:

ChatGPT performs:

- architecture review
- documentation review
- repository review
- ADR consistency review
- implementation review

Review findings shall be addressed before merge.

---

# Release

After approval:

Merge Pull Request.

Create GitHub Release.

Release

```text
v0.5.0
```

Release Notes shall contain:

- Features
- Architecture changes
- Documentation updates
- Known limitations
- Future work

---

# Successor Work Order

WO-1004

Documentation Sprint 4

Reference Documentation

The Reference documentation shall consolidate the stable facts introduced by
the networking foundation, including:

- IP addressing
- DNS records
- Service inventory
- Naming conventions
- Software inventory
- Kubernetes labels
