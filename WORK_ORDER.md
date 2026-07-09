# Work Order

**Sprint:** Documentation Sprint 2  
**Status:** Ready for Implementation  
**Primary Agent:** Codex  
**Reviewer:** Abdul Jabbar  

---

## Objective

Create the Infrastructure section of the HomeLab MkDocs documentation.

This sprint consolidates the infrastructure work completed so far into structured, human-readable engineering documentation.

No infrastructure changes are required in this sprint.

---

## Scope

Create and integrate the following files:

```
docs/infrastructure/
├── raspberry-pi-cluster.md
├── ansible.md
├── kubernetes.md
├── networking.md
├── storage.md
└── security.md
```

Update:

```
mkdocs.yml
```

to include the Infrastructure section in navigation.

## Documentation Standard

Each document must follow this structure:

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

## Content Requirements

```
raspberry-pi-cluster.md
```

Must document:

- four-node Raspberry Pi 4 cluster
- hostnames
- IP addresses
- Raspberry Pi OS / Debian 13
- 64-bit ARM architecture
- management from Arch Linux laptop
- node roles
- current topology
- future hardware expansion context

```
ansible.md
```
Must document:

- why Ansible is used
- inventory structure
- group variables
- host variables
- playbooks
- roles
- common role
- k3s role
- idempotency
- ssh-agent usage
- verification philosophy

```
kubernetes.md
```

Must document:

- K3s selection
- current cluster topology
- control plane and worker nodes
- kubeconfig handling
- CoreDNS
- Metrics Server
- Local Path Provisioner
- disabled Traefik and ServiceLB
- worker labels
- verification commands

```
networking.md
```
Must document:

- current LAN range 192.168.68.0/24
- DHCP reservations
- current host IPs
- future .home.arpa DNS plan
- future Pi-hole plan
- future MetalLB plan
- future ingress plan
- IBM ELM future DNS target such as elm.home.arpa

```
storage.md
```
Must document:

- current storage state
- microSD-based nodes
- local-path-provisioner
- limitations of current storage
- future Longhorn evaluation
- future backup requirements

```
security.md
```

Must document:

- SSH key authentication
- ssh-agent
- sudo usage through Ansible
- Git as source of truth
- current limitations
- future TLS
- future secrets management
- future network segmentation

## Constraints

- Do not introduce new infrastructure implementation.
- Do not change Ansible roles.
- Do not create new ADRs in this sprint.
- Do not add new documentation files outside the sprint scope.
- Do not duplicate stable reference data unnecessarily.
- Link to overview documents where appropriate.
- Keep writing style consistent with Documentation Sprint 1.

## Acceptance Criteria

The sprint is complete when:

- all six infrastructure documents exist
- mkdocs.yml navigation includes the Infrastructure section
- mkdocs build completes without errors
- documentation reflects the actual implemented system
- no placeholder TODO sections remain
- files are committed to Git

## Suggested Validation Commands

```
source .venv/bin/activate
mkdocs build
mkdocs serve
```

## Optional review:

```
git diff
git status
```

## Definition of Done

Documentation Sprint 2 is complete when the Infrastructure section provides a coherent explanation of the implemented Raspberry Pi, Ansible and K3s foundation, while clearly marking networking, storage and security future work.