# Updating

---

## Purpose

This document describes the normal maintenance workflow for updating the HomeLab repository, documentation tooling and Raspberry Pi nodes.

The goal is to keep maintenance repeatable and reviewable.

## Scope

This document covers:

- updating the Git repository
- activating the Python environment
- updating documentation
- running `update.yml`
- running `baseline.yml`
- verification steps
- reviewing Git status
- committing infrastructure or documentation changes

This document does not define Kubernetes application upgrade procedures. Application operations will be documented when applications are introduced.

## Background

HomeLab uses Git as the source of truth and Ansible as the operational automation layer.

Routine maintenance should start from a clean understanding of the local repository state and end with verification of both infrastructure and documentation.

## Architecture / Implementation

### 1. Review local Git state

From the repository root:

```bash
git status --short
```

Understand any existing local changes before pulling or editing files.

### 2. Update the repository

If the local branch is clean or the local changes are understood:

```bash
git pull --ff-only
```

Use fast-forward pulls so history does not gain accidental merge commits during routine maintenance.

### 3. Activate the Python environment

```bash
source .venv/bin/activate
```

If documentation dependencies need to be refreshed:

```bash
pip install -r requirements/docs.txt
```

### 4. Update documentation

Edit documentation in `docs/` and update `mkdocs.yml` when adding pages to navigation.

Build the documentation:

```bash
mkdocs build
```

For local review:

```bash
mkdocs serve
```

Open:

```text
http://127.0.0.1:8000
```

### 5. Update Raspberry Pi packages

Run Ansible from the `ansible/` directory:

```bash
cd ansible
ansible-playbook playbooks/update.yml
```

This refreshes APT package metadata, upgrades installed packages and removes unused packages across the Raspberry Pi nodes.

### 6. Reapply the baseline

After package updates, reapply the baseline:

```bash
ansible-playbook playbooks/baseline.yml
```

The baseline playbook should be safe to run repeatedly. It keeps common packages, time synchronization, swap state and cgroup configuration aligned with the repository.

### 7. Verify Ansible connectivity

```bash
ansible pis -m ping
```

All nodes should return success.

### 8. Verify Kubernetes

Return to the repository root:

```bash
cd ..
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
kubectl --kubeconfig ansible/kubeconfig get pods -n kube-system
```

Expected result:

- all four nodes are present
- all nodes are `Ready`
- CoreDNS is running
- Metrics Server is available

### 9. Review changes

```bash
git status --short
git diff
```

If the changes are intended, stage and commit them:

```bash
git add <paths>
git commit -m "Describe the maintenance change"
```

## Design Decisions

### Maintenance starts with Git status

Reviewing local changes first prevents accidental overwrites or mixed unrelated updates.

### Package updates are separated from baseline configuration

`update.yml` handles package maintenance. `baseline.yml` asserts the desired node baseline.

### Documentation is validated locally

MkDocs builds are part of the maintenance workflow because documentation is part of the platform.

## Best Practices

- start with `git status --short`
- avoid mixing unrelated maintenance changes in one commit
- use `git pull --ff-only` for routine updates
- run Ansible from the `ansible/` directory
- keep SSH keys loaded in `ssh-agent`
- verify the cluster after node updates
- build documentation before committing documentation changes

## Future Improvements

Future maintenance improvements may include:

- a documented K3s upgrade procedure
- automated maintenance checklists
- backup verification before high-risk changes
- monitoring and alerting integration
- CI validation for documentation builds

## Related Documents

- [Bootstrap](bootstrap.md)
- [Troubleshooting](troubleshooting.md)
- [Ansible](../infrastructure/ansible.md)
- [Kubernetes](../infrastructure/kubernetes.md)
- [Repository Structure](../overview/repository.md)
