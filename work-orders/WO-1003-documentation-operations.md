# WORK ORDER

**ID:** WO-1003
**Sprint:** Documentation Sprint 3  - Operations
**Status:** Completed
**Primary Agent:** Codex
**Architect:** ChatGPT
**Owner:** Abdul Jabbar

---

# Objective

Create the Operations section of the HomeLab documentation.

This sprint documents how the platform is built, maintained, updated, recovered and
troubleshot.

The Operations section should allow the entire Raspberry Pi Kubernetes platform
to be recreated from scratch using only the repository.

No infrastructure implementation changes are part of this sprint.

---

# Scope

Create the following documentation.

```text
docs/
└── operations/
    ├── bootstrap.md
    ├── updating.md
    ├── rebuilding.md
    ├── troubleshooting.md
    └── backup.md
```

Update

```text
mkdocs.yml
```

to include the Operations section.

---

# Documentation Standard

Every document shall follow the standard HomeLab template.

```markdown
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

---

# Deliverables

## bootstrap.md

Purpose

Describe the complete platform bootstrap procedure.

The document should include:

- workstation preparation
- Arch Linux packages
- Python virtual environment
- repository cloning
- SSH key creation
- Raspberry Pi imaging
- hostname configuration
- DHCP reservations
- SSH verification
- Ansible inventory
- baseline playbook
- K3s installation
- cluster verification
- MkDocs setup

This document should become the authoritative rebuild guide.

---

## updating.md

Purpose

Describe the normal maintenance workflow.

Include:

- updating the Git repository
- activating the Python environment
- updating documentation
- running update.yml
- running baseline.yml
- verification steps
- reviewing Git status
- committing infrastructure changes

Include expected command sequences.

---

## rebuilding.md

Purpose

Describe disaster recovery.

Document:

Replacing a failed Raspberry Pi

Steps:

- flash new SD card
- hostname assignment
- static IP reservation
- SSH configuration
- inventory update
- baseline playbook
- K3s join
- verification

Also include:

Replacing the management workstation.

---

## troubleshooting.md

Purpose

Consolidate all known issues solved during development.

Include at minimum:

SSH

- wrong username
- SSH key not used
- ssh-agent
- IdentityFile
- known_hosts

Ansible

- inventory not found
- role lookup
- idempotency
- package changed every run

Raspberry Pi

- hostname changes
- cmdline changes
- cgroup configuration
- zram swap
- time synchronization

Kubernetes

- kubeconfig
- worker labels
- node naming
- verification commands

Documentation

- MkDocs virtual environment
- Python externally-managed-environment
- GitHub Pages

Every issue should contain:

Problem

Cause

Resolution

Verification

---

## backup.md

Purpose

Describe backup and recovery strategy.

Current state

Document what is and is not currently backed up.

Include:

Git repository

Ansible

Documentation

Future backup targets

Persistent Volumes

Longhorn

Secrets

Cluster configuration

Kubernetes manifests

Recovery priorities

Document Recovery Objectives.

---

# mkdocs.yml

Update navigation.

Operations

Bootstrap

Updating

Rebuilding

Troubleshooting

Backup

---

# Constraints

Do not modify infrastructure.

Do not modify playbooks.

Do not introduce new technologies.

Do not create additional documentation outside this sprint.

Avoid duplication with:

Overview

Infrastructure

Reference

Link instead of repeating.

---

# Acceptance Criteria

The sprint is complete when:

✓ All five Operations documents exist.

✓ Navigation updated.

✓ Documentation builds successfully.

✓ Cross references are present.

✓ Procedures reflect the actual implemented platform.

✓ Existing troubleshooting knowledge has been consolidated.

✓ PROJECT_STATE.md updated.

---

# Validation

Run

```bash
source .venv/bin/activate

mkdocs build

mkdocs serve
```

Verify:

- navigation
- links
- code blocks
- formatting

---

# Definition of Done

After this sprint an engineer unfamiliar with the project should be able to:

- build the Raspberry Pi cluster
- maintain the cluster
- recover from hardware failure
- troubleshoot common issues
- understand operational procedures

using only the repository documentation.

---

# Successor Sprint

Documentation Sprint 4

Reference Documentation

- inventory
- naming
- IP addressing
- software inventory
- glossary
