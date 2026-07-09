# Security

---

## Purpose

This document describes the current HomeLab security baseline and the planned direction for future security improvements.

The current model is appropriate for an early private lab foundation but is not the final security architecture.

## Scope

This document covers:

- SSH key authentication
- ssh-agent usage
- sudo usage through Ansible
- Git as source of truth
- current limitations
- future TLS
- future secrets management
- future network segmentation

This document does not define a complete hardening baseline, identity platform or secrets architecture.

## Background

HomeLab is managed from an Arch Linux workstation using SSH and Ansible.

The repository is the source of truth for desired infrastructure state. Manual changes should be minimized so that configuration can be reviewed, repeated and rebuilt.

## Architecture / Implementation

Current access model:

```text
Arch Linux management laptop
        |
        | SSH key authentication
        v
Raspberry Pi nodes
        |
        | sudo through Ansible become
        v
Privileged configuration tasks
```

Current Ansible connection settings are stored in:

```text
ansible/inventories/home/group_vars/all.yml
```

Current shared settings:

| Setting | Value |
|---------|-------|
| SSH user | `abdul` |
| SSH private key | `~/.ssh/id_ed25519_personal` |

The SSH key is expected to be unlocked with `ssh-agent` before running Ansible. This avoids repeated passphrase prompts while keeping key-based authentication.

Ansible playbooks that modify system configuration use:

```yaml
become: true
```

This means privileged changes are performed through sudo rather than by logging in directly as root.

## Design Decisions

### SSH keys instead of passwords

SSH key authentication is the baseline remote access method for the Raspberry Pi nodes.

### ssh-agent for operator workflow

`ssh-agent` keeps the workflow practical while preserving encrypted private key usage.

### sudo through Ansible

Ansible uses privilege escalation for tasks that require root access. This keeps the normal connection user separate from privileged execution.

### Git as source of truth

Infrastructure state should be represented in Git through Ansible, Kubernetes manifests, Helm values and documentation.

## Best Practices

- use SSH keys for node access
- unlock keys with `ssh-agent` before running Ansible
- avoid direct root login as the normal operating model
- keep infrastructure changes in Git
- prefer automated, reviewable changes over manual configuration
- avoid committing secrets to the repository
- document security assumptions and limitations explicitly

## Future Improvements

Current limitations:

- no documented hardening baseline is implemented yet
- no internal TLS automation is implemented yet
- no dedicated secrets management system is implemented yet
- no network segmentation or VLAN model is implemented yet
- K3s API access currently depends on local kubeconfig handling

Planned security improvements include:

- implementation of a hardening playbook or role
- TLS for internal services
- certificate management
- secrets management for Kubernetes and automation
- network segmentation
- role-based access control review
- backup encryption requirements
- documented access recovery procedures

## Related Documents

- [Ansible](ansible.md)
- [Kubernetes](kubernetes.md)
- [Networking](networking.md)
- [Repository Structure](../overview/repository.md)
