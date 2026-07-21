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
- wired management baseline
- current limitations
- private PKI and TLS
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

Cluster node network access is managed through the wired Ethernet baseline. Wi-Fi is disabled during normal operation and should only be re-enabled deliberately for recovery.

HomeLab now uses a private two-tier PKI for internal HTTPS:

```text
HomeLab Root CA
├── HomeLab Server Issuing CA
└── HomeLab Client Issuing CA
```

The encrypted Root CA key remains outside Git and Kubernetes. Only the Server
Issuing CA is imported into Kubernetes for cert-manager server-certificate
automation. The Client Issuing CA remains offline for future client
authentication and mTLS work.

## Design Decisions

### SSH keys instead of passwords

SSH key authentication is the baseline remote access method for the Raspberry Pi nodes.

### ssh-agent for operator workflow

`ssh-agent` keeps the workflow practical while preserving encrypted private key usage.

### sudo through Ansible

Ansible uses privilege escalation for tasks that require root access. This keeps the normal connection user separate from privileged execution.

### Git as source of truth

Infrastructure state should be represented in Git through Ansible, Kubernetes manifests, Helm values and documentation.

### Wi-Fi recovery is exceptional

Wi-Fi may be re-enabled manually only through direct console access, an existing Ethernet SSH session or another explicitly documented recovery path:

```bash
sudo nmcli radio wifi on
```

The next baseline playbook run restores the managed Wi-Fi-disabled state.

## Best Practices

- use SSH keys for node access
- unlock keys with `ssh-agent` before running Ansible
- avoid direct root login as the normal operating model
- keep infrastructure changes in Git
- prefer automated, reviewable changes over manual configuration
- prefer wired Ethernet for cluster node access and platform traffic
- avoid committing secrets to the repository
- avoid committing private keys, generated Secret manifests or PKCS#12 bundles
- keep the generated administrator kubeconfig permission-restricted and outside Git
- document security assumptions and limitations explicitly

## Future Improvements

Current limitations:

- no documented hardening baseline is implemented yet
- no dedicated secrets management system is implemented yet
- no network segmentation or VLAN model is implemented yet
- K3s API access currently depends on local kubeconfig handling

Planned security improvements include:

- implementation of a hardening playbook or role
- client-certificate authentication and mTLS for selected services
- secrets management for Kubernetes and automation
- network segmentation
- role-based access control review
- backup encryption requirements
- documented access recovery procedures

## Related Documents

- [Ansible](ansible.md)
- [Kubernetes](kubernetes.md)
- [Networking](networking.md)
- [PKI](pki.md)
- [Repository Structure](../overview/repository.md)
