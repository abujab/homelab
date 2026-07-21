# Backup

---

## Purpose

This document describes the current HomeLab backup and recovery strategy.

It records what is currently protected, what is not yet protected and which backup targets must be designed before stateful workloads are introduced.

## Scope

This document covers:

- Git repository backup expectations
- Ansible backup state
- documentation backup state
- current gaps
- future backup targets
- persistent volumes
- Longhorn
- secrets
- cluster configuration
- Kubernetes manifests
- Pi-hole persistent configuration
- recovery priorities
- recovery objectives

This document does not implement backup tooling.

## Background

The current platform is mostly stateless infrastructure automation and documentation.

The most important backup asset today is the Git repository because it contains:

- Ansible inventory and playbooks
- role implementation
- MkDocs documentation
- project state
- work orders and decision history

The current cluster does not yet host documented critical persistent workloads.

## Architecture / Implementation

## Current backup state

### Git repository

Current state:

The Git repository is the primary backup mechanism for desired infrastructure state.

Protected content:

- Ansible inventory
- Ansible playbooks
- Ansible roles
- documentation
- MkDocs configuration
- requirements files
- work order history

Operational expectation:

Push completed commits to the remote repository regularly.

### Ansible

Current state:

Ansible configuration is backed up when committed and pushed to Git.

Protected content:

- inventory groups
- host variables
- group variables
- playbooks
- roles

The generated `ansible/kubeconfig` contains cluster-administrator credentials
and is intentionally excluded from Git. Recover it by rerunning the K3s
playbook rather than restoring it from the repository.

Risk:

The SSH private key used by Ansible is not stored in Git and must be protected separately.

### Documentation

Current state:

Documentation is backed up through Git.

Protected content:

- overview documentation
- infrastructure documentation
- operations documentation
- MkDocs navigation

Generated site output under `site/` is build output and should not be treated as the source backup.

## Current gaps

The following are not yet fully backed up by an implemented platform backup system:

- Raspberry Pi microSD images
- K3s server state
- Kubernetes persistent volumes
- Kubernetes secrets
- Pi-hole administrative password Secret
- future application data
- future Longhorn volumes
- Pi-hole persistent configuration restore
- router DHCP reservation configuration
- operator SSH private key
- HomeLab PKI offline CA material

## Future backup targets

### Persistent Volumes

Future stateful applications will require persistent volume backups.

Before important data is deployed, the platform should define:

- which volumes are backed up
- backup frequency
- retention period
- restore procedure
- restore testing schedule

### Longhorn

Longhorn is a future storage evaluation candidate.

If Longhorn is adopted, backup design should include:

- Longhorn backup target
- snapshot policy
- backup policy
- restore testing
- node failure behavior

### Secrets

Secrets are not currently managed by a dedicated secrets platform.

The Pi-hole administrative password Secret is created locally and is not committed to Git.

Future design must define:

- where secrets are stored
- who can access them
- how they are backed up
- how they are rotated
- how cluster recovery works without committing secrets to Git

### PKI

Current state:

HomeLab PKI material is generated outside Git under `HOMELAB_PKI_DIR`, which
defaults to:

```bash
${HOME}/PKI/homelab
```

Critical recovery set:

- Root CA private key
- Root CA certificate
- Server Issuing CA private key
- Server Issuing CA certificate and chain
- Client Issuing CA private key
- Client Issuing CA certificate and chain
- OpenSSL CA databases and serial files
- OpenSSL configuration and profiles
- Root CA passphrase recovery information

The OpenSSL database directories are retained for forward compatibility and
must be backed up with the other CA state. Current signing uses
`openssl x509 -CAcreateserial`, so these databases do not provide a complete
issued-certificate history or revocation ledger.

Backup requirements:

- use encrypted offline backups
- maintain at least two copies in separate locations
- do not rely only on the management workstation
- do not rely only on Kubernetes Secrets
- do not rely only on Git
- do not rely on a single removable drive

Normal cluster recovery restores the existing Server Issuing CA and recreates
the cert-manager Secret. It must not regenerate the Root CA.

### Cluster configuration

Kubernetes cluster configuration should eventually be represented declaratively through manifests, Helm values or GitOps.

Future backup expectations:

- manifests stored in Git
- Helm values stored in Git
- generated credentials excluded from Git
- recovery procedure tested from a clean cluster

### Kubernetes manifests

The current Kubernetes desired state is stored under `kubernetes/platform/`,
including networking, ingress and certificate configuration. These files are
protected by Git when committed and pushed. The separate `manifests/` directory
is only a tracked placeholder and does not own current deployed resources.

### Pi-hole configuration

Pi-hole uses the `pihole-config` persistent volume claim in the `networking` namespace.

Current limitation:

The PVC is not backed up by a dedicated backup system. Pi-hole can be redeployed from Git, but runtime configuration stored in the PVC is not yet protected beyond the local Kubernetes storage layer.

## Recovery objectives

Current recovery objectives:

| Area | Recovery Objective |
|------|--------------------|
| Repository | Restore from remote Git copy |
| Documentation | Rebuild from MkDocs source |
| Ansible desired state | Restore from Git |
| Raspberry Pi node | Reimage and reconfigure from bootstrap procedure |
| K3s worker | Rejoin through Ansible |
| K3s control plane | Rebuild from Ansible; server-state backup is future work |
| Pi-hole service | Redeploy from Git; PVC restore is future work |
| PKI | Restore CA material from encrypted offline backup |
| Persistent application data | Not yet guaranteed |

Recovery priority:

1. restore repository access
2. restore management workstation tooling
3. restore SSH access to nodes
4. restore Ansible baseline
5. restore K3s control plane
6. restore K3s workers
7. restore MetalLB and Pi-hole
8. restore cert-manager and the Server Issuing CA Secret
9. restore platform services
10. restore application data

## Design Decisions

### Git is the first backup layer

At the current stage, the repository is the most important recoverable artifact.

### Generated documentation is not source state

The MkDocs `site/` directory can be rebuilt and should not be treated as the canonical documentation backup.

### Stateful backup is deferred until storage architecture exists

Persistent workload backup depends on storage design. It should be decided before deploying important stateful applications.

## Best Practices

- push completed commits to the remote repository
- do not store SSH private keys in Git
- do not store secrets in Git
- validate that documentation rebuilds from source
- test node rebuild procedures before relying on them
- define restore procedures before deploying critical stateful workloads
- treat backups as incomplete until restores are tested

## Future Improvements

Future backup work should include:

- documented remote Git recovery procedure
- router configuration export procedure
- K3s server backup and restore
- Longhorn or alternative storage backup design
- Kubernetes secrets management
- persistent volume backup testing
- recovery drills
- recovery time objective and recovery point objective targets for critical services

## Related Documents

- [Bootstrap](bootstrap.md)
- [Rebuilding](rebuilding.md)
- [Storage](../infrastructure/storage.md)
- [Security](../infrastructure/security.md)
- [Repository Structure](../overview/repository.md)
- [Infrastructure Inventory](../reference/infrastructure-inventory.md)
- [Service Catalog](../reference/service-catalog.md)
