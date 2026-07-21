# Repository Structure

---

## Purpose

This document explains the tracked HomeLab repository structure and the
responsibility of each major area.

## Scope

It covers current top-level files, Ansible, Kubernetes, documentation,
requirements, scripts, work orders, evidence and review history. It does not
list every task, manifest or evidence file.

## Background

The repository began with Ansible automation and now contains executable
platform configuration, architecture decisions, operational documentation,
work-order evidence and pull-request review records.

Tracked repository content is the source of truth. Empty local directories,
generated `site/` output and the local `.venv/` are not part of the reproducible
repository model.

## Architecture / Implementation

Current tracked structure:

```text
homelab/
|-- AGENTS.md
|-- README.md
|-- PROJECT_STATE.md
|-- mkdocs.yml
|-- ansible/
|   |-- ansible.cfg
|   |-- inventories/home/
|   |-- playbooks/
|   `-- roles/
|-- kubernetes/
|   `-- platform/
|       |-- certificates/
|       |-- ingress/
|       `-- networking/
|-- docs/
|   |-- overview/
|   |-- decisions/
|   |-- infrastructure/
|   |-- operations/
|   |-- reference/
|   `-- development/
|-- requirements/
|-- scripts/
|   `-- pki/
|-- work-orders/
|-- artifacts/
|-- reviews/
`-- manifests/
```

### Root files

| Path | Responsibility |
|------|----------------|
| `README.md` | Concise repository landing page |
| `PROJECT_STATE.md` | Verified current project state after completed sprints |
| `AGENTS.md` | Repository engineering and automation standards |
| `mkdocs.yml` | Documentation site configuration and navigation |

### Ansible

```text
ansible/
|-- ansible.cfg
|-- kubeconfig
|-- inventories/
|   `-- home/
|       |-- group_vars/all.yml
|       |-- host_vars/
|       `-- hosts.yml
|-- playbooks/
|   |-- baseline.yml
|   |-- hardening.yml
|   |-- k3s.yml
|   |-- storage.yml
|   `-- update.yml
`-- roles/
    |-- common/
    |-- network/
    |-- k3s/
    `-- storage/
```

Inventory describes where automation runs. Playbooks orchestrate work. Roles
implement focused, reusable responsibilities. The local kubeconfig is used by
documented operations and must be handled as an access-sensitive runtime file.

### Kubernetes

```text
kubernetes/platform/
|-- networking/
|   |-- metallb/
|   `-- pihole/
|-- ingress/
|   `-- test-app/
`-- certificates/
    |-- issuers/
    `-- test/
```

Kubernetes resources are declarative manifests, Kustomize inputs or
repository-managed Helm values. Runtime Secret values and private CA material
are excluded from Git.

The separate `manifests/` directory is a tracked placeholder and does not
currently own deployed platform configuration.

### Documentation

| Directory | Responsibility |
|-----------|----------------|
| `docs/overview/` | Vision, current and target architecture, roadmap and repository model |
| `docs/decisions/` | Historical Architecture Decision Records and template |
| `docs/infrastructure/` | Component design and implementation |
| `docs/operations/` | Bootstrap, maintenance, recovery and troubleshooting |
| `docs/reference/` | Authoritative inventory, addressing, software, services, ADR register and glossary |
| `docs/development/` | Review and contribution workflow |

### Requirements and scripts

`requirements/docs.txt` pins the MkDocs build environment.
`requirements/development.txt` and `requirements/testing.txt` are present for
their named dependency scopes.

`scripts/` contains repository workflow and validation helpers. The `pki/`
subdirectory contains certificate-generation and inspection tooling; generated
private material remains outside the repository.

### Work orders and project state

`work-orders/CURRENT.md` exists only while an approved sprint is active. After
acceptance succeeds, it is renamed to its permanent ID-based archive, its status
is changed to Complete, and `CURRENT.md` is removed.

`PROJECT_STATE.md` describes what is true after completed work. It does not
serve as the active implementation specification.

### Evidence and reviews

Work-order evidence is stored under an ID-specific directory:

```text
artifacts/WO-NNNN/
```

The directory contains validation output and reviewable evidence, not desired
infrastructure state. Main repository overviews link to evidence rather than
listing every artifact.

Architecture review records are stored under `reviews/` after the implementation
pull request is merged and its final-head approval can be archived. The review
archive is created on a separate branch and pull request to avoid recursive
review history.

### Pull-request workflow

```text
Approved work order
  -> implementation branch
  -> code, documentation and evidence
  -> validation
  -> archive work order and update PROJECT_STATE.md
  -> implementation pull request
  -> architecture review and merge
  -> review-archive branch and pull request
  -> release
```

## Design Decisions

### Playbooks and roles are separate

Playbooks remain orchestration entry points and roles own reusable logic, as
recorded in ADR-0006.

### Documentation ownership is explicit

Reference owns stable lookup data, infrastructure owns design, operations owns
procedures and ADRs own rationale.

### Evidence is not desired state

Artifacts prove a work order was validated but do not replace Ansible or
Kubernetes configuration.

### Generated and local state is excluded

The MkDocs `site/` directory, virtual environment and local secrets are
regenerated or restored and are not authoritative tracked content.

## Best Practices

- add content to an existing responsibility area whenever possible
- keep playbooks small and implementation in roles
- keep Kubernetes desired state under `kubernetes/`
- keep stable lookup values under `docs/reference/`
- archive work orders only after acceptance passes
- store evidence under the matching work-order ID
- update navigation when adding documentation pages
- keep runtime credentials and private keys outside Git

## Future Improvements

- add CI workflows only through an approved work order
- establish an application directory convention when the first production-like application is approved
- remove or assign the `manifests/` placeholder when its ownership is decided
- automate documentation and manifest consistency checks

## Related Documents

- [Vision](vision.md)
- [Architecture](architecture.md)
- [Roadmap](roadmap.md)
- [Reference](../reference/index.md)
- [Ansible](../infrastructure/ansible.md)
- [Kubernetes](../infrastructure/kubernetes.md)
- [Development Workflow](../development/workflow.md)
- [ADR-0006 Repository Structure](../decisions/ADR-0006-repository-structure.md)
