# AGENTS.md

# HomeLab Engineering Standards

This repository is engineered as a long-term private cloud platform.

The goal is not simply to automate infrastructure, but to apply enterprise
software engineering and architecture practices to a home datacenter.

All automated changes should preserve readability, maintainability and
architectural consistency.

---

# Core Philosophy

Always optimize for:

1. Correctness
2. Maintainability
3. Reproducibility
4. Readability
5. Automation

Never optimize only for writing the fewest lines of code.

The repository is expected to remain understandable many years after it was
created.

---

# Engineering Principles

## Infrastructure as Code

Infrastructure should always be expressed as code whenever practical.

Avoid manual configuration.

Use:

- Ansible
- Kubernetes manifests
- Helm
- Git

before considering manual configuration.

---

## Git is the Source of Truth

The Git repository describes the desired state of the platform.

If infrastructure fails, rebuilding should be possible using only:

- Git
- documented bootstrap procedures
- required installation media

---

## Documentation First

Every infrastructure change should be reflected in documentation.

Documentation is part of the implementation.

Documentation is never considered optional.

---

## Architecture Before Implementation

Do not implement features before the architecture is understood.

Large implementation work should normally follow:

Vision

↓

Architecture

↓

ADR

↓

Implementation

↓

Verification

↓

Documentation

---

## Architectural Stability

Avoid introducing new files, directories, naming conventions or documentation
structures unless they solve a clearly identified problem.

Prefer evolving the existing architecture over expanding it.

Every new artifact should have a single, well-defined responsibility.

If a proposal introduces a new top-level concept, first evaluate whether the
existing architecture can accommodate it without increasing complexity.

---

## Idempotency

Automation should be safely repeatable.

Running the same playbook twice should not introduce additional changes.

Avoid:

- duplicate configuration
- duplicate kernel parameters
- duplicate package installation
- duplicate files

---

## Incremental Development

Prefer small, verifiable improvements.

Avoid large unrelated changes in one commit.

Each sprint should have a clear objective.

---

# Documentation Standards

Documentation uses MkDocs Material.

Every document should follow the standard structure.

```
# Title

---

## Purpose

## Scope

## Background

## Architecture / Implementation

## Design Decisions

## Best Practices

## Future Improvements

## Related Documents
```

Do not invent new documentation structures unless explicitly requested.

---

# Repository Standards

README.md

Repository landing page only.

Keep concise.

Do not duplicate detailed documentation.

---

PROJECT_STATE.md

Current state of the project.

Updated after every completed sprint.

---

WORK_ORDER.md

Current implementation sprint.

Only one work order should exist at any time.

---

ADRs

Architecture Decision Records describe why decisions were made.

Avoid modifying accepted ADRs except for factual corrections.

---

# Ansible Standards

Use roles for reusable logic.

Playbooks orchestrate roles.

Avoid placing implementation directly into playbooks.

Use handlers when appropriate.

Prefer Ansible modules over shell commands.

Shell commands are acceptable only when no suitable module exists.

Every role should remain focused on one responsibility.

---

# Kubernetes Standards

Use declarative manifests.

Avoid imperative kubectl commands inside automation when a declarative approach
exists.

Prefer labels over host-specific scheduling.

Avoid hardcoded IP addresses.

Prefer DNS names.

---

# Naming Standards

Machines identify hardware.

Examples

pi4mB01

pi4mB02

Services identify functionality.

Examples

grafana.home.arpa

registry.home.arpa

elm.home.arpa

Do not expose infrastructure through machine names.

---

# Documentation Ownership

Avoid duplicated information.

Reference documents should contain stable facts.

Architecture documents explain design.

Operations documents explain procedures.

Overview documents explain concepts.

---

# Coding Style

Prefer clarity over cleverness.

Avoid unnecessary abstraction.

Use descriptive task names.

Comment YAML sections.

Maintain consistent formatting.

---

# Sprint Workflow

Every sprint follows this lifecycle.

1. Read PROJECT_STATE.md

2. Read WORK_ORDER.md

3. Review relevant ADRs

4. Implement only the work described in the current work order

5. Verify changes

6. Update documentation

7. Update PROJECT_STATE.md

Do not begin future work.

---

# Constraints

Unless explicitly requested:

Do not:

- rename directories
- reorganize documentation
- introduce new technologies
- change repository structure
- rewrite completed documentation
- create additional files outside the work order

Architectural changes require explicit approval.

---

# Preferred Working Style

When implementing work:

Think like a senior infrastructure engineer.

Make the smallest change that satisfies the architecture.

Explain trade-offs when introducing a significant decision.

Preserve consistency across the repository.

When in doubt:

Prefer the existing repository conventions over creating new ones.

---

# Long-Term Vision

The target platform is a hybrid private cloud consisting of:

- ARM infrastructure
- x86 compute
- Kubernetes
- Infrastructure as Code
- Internal DNS
- Monitoring
- AI workloads
- Enterprise-quality documentation

Every contribution should move the repository closer to this vision.