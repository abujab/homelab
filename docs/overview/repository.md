
# Repository Structure

---

## Purpose

This document explains the HomeLab repository structure and the responsibility of each major directory.

The goal is to keep the repository understandable as it grows from a Raspberry Pi cluster into a hybrid private cloud platform.

---

## Scope

This document covers:

- repository layout
- top-level directories
- Ansible structure
- documentation structure
- future Kubernetes structure
- rules for adding new content

This document does not describe every individual Ansible task or Kubernetes manifest. Those details belong in infrastructure-specific documentation.

---

## Background

The repository started with Ansible inventory and playbooks. It has since grown to include roles, ADRs and MkDocs documentation.

To avoid drift, the repository follows a separation-of-responsibilities model.

Each folder should have one clear reason to exist.

---

## Architecture / Implementation

Current structure:

```text
homelab/
├── README.md
├── mkdocs.yml
├── PROJECT_STATE.md
├── WORK_ORDER.md
├── ansible/
├── kubernetes/
├── docs/
├── requirements/
└── scripts/
```

### `README.md`

The repository landing page.

It should remain short and should not become the main documentation body.

### `PROJECT_STATE.md`

Current state of the project.

This file changes after sprint completion.

### `WORK_ORDER.md`

Current implementation work package.

This file changes when a new sprint starts.

### `mkdocs.yml`

MkDocs site configuration.

### `ansible/`

Infrastructure configuration and automation.

Current structure:

```text
ansible/
├── ansible.cfg
├── inventories/
│   └── home/
├── playbooks/
└── roles/
```

### `ansible/playbooks/`

Playbooks are orchestration entry points.

Examples:

```text
baseline.yml
update.yml
k3s.yml
```

### `ansible/roles/`

Roles contain reusable implementation logic.

Current roles:

```text
common/
k3s/
```

### `docs/`

MkDocs source documentation.

Current structure:

```text
docs/
├── index.md
└── overview/
    ├── vision.md
    ├── architecture.md
    ├── repository.md
    └── roadmap.md
```

### `kubernetes/`

Reserved for Kubernetes manifests, Helm values and future GitOps configuration.

### `requirements/`

Python dependency files for local tooling.

### `scripts/`

Helper scripts for the development workflow.

---

## Design Decisions

### Playbooks and roles are separated

Roles are first-class reusable implementation units, not subfolders of playbooks.

### Documentation is part of the repository

Documentation evolves with the infrastructure and is version controlled.

### Work order and project state are separate

`WORK_ORDER.md` describes what is being done next.

`PROJECT_STATE.md` describes what is true now.

### README is intentionally short

The README is not the engineering knowledge base. The MkDocs site is.

---

## Best Practices

When adding new files:

- place them in the directory that matches their responsibility
- avoid mixing architecture and operations in the same document
- update `mkdocs.yml` when adding documentation pages
- update `PROJECT_STATE.md` at the end of a sprint
- update `WORK_ORDER.md` at the beginning of a sprint
- do not duplicate stable reference data in many places

---

## Future Improvements

Planned repository additions:

```text
docs/infrastructure/
docs/operations/
docs/reference/
docs/decisions/
kubernetes/platform/
kubernetes/apps/
```

Potential future additions:

```text
docs/images/
docs/diagrams/
tests/
.github/workflows/
```

---

## Related Documents

- [Vision](vision.md)
- [Architecture](architecture.md)
- [Roadmap](roadmap.md)
