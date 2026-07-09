# Troubleshooting

---

## Purpose

This document consolidates known troubleshooting patterns for the current HomeLab Raspberry Pi, Ansible, K3s and MkDocs platform.

Each issue includes the problem, cause, resolution and verification.

## Scope

This document covers:

- SSH issues
- Ansible issues
- Raspberry Pi baseline issues
- Kubernetes issues
- documentation tooling issues

This document does not replace future service-specific troubleshooting guides.

## Background

Most current operational issues fall into a small number of categories:

- authentication and SSH key selection
- Ansible inventory or role lookup
- Raspberry Pi kernel and swap settings
- K3s kubeconfig and node naming
- local Python and MkDocs environment setup

## Architecture / Implementation

## SSH

### Wrong username

Problem:

SSH or Ansible cannot connect to a Raspberry Pi.

Cause:

The current inventory expects the SSH user `abdul`. A different username was used during imaging or in a manual SSH command.

Resolution:

Use the expected username:

```bash
ssh abdul@192.168.68.101
```

If the node was imaged with the wrong username, recreate the user or reimage the node with the correct account.

Verification:

```bash
ssh abdul@192.168.68.101 hostname
```

### SSH key not used

Problem:

SSH prompts for a password or rejects authentication.

Cause:

The expected private key was not selected.

Resolution:

Use the configured key:

```bash
ssh -i ~/.ssh/id_ed25519_personal abdul@192.168.68.101
```

Confirm Ansible references the same key in `ansible/inventories/home/group_vars/all.yml`.

Verification:

```bash
cd ansible
ansible pis -m ping
```

### ssh-agent does not have the key

Problem:

Ansible repeatedly prompts for the SSH key passphrase or fails to authenticate.

Cause:

The key is encrypted but not loaded into `ssh-agent`.

Resolution:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_personal
```

Verification:

```bash
ssh-add -l
cd ansible
ansible pis -m ping
```

### IdentityFile mismatch

Problem:

Manual SSH works with one key, but Ansible uses another key.

Cause:

The key in `group_vars/all.yml` does not match the key used manually or in SSH config.

Resolution:

Align the key path with the intended operator key:

```yaml
ansible_ssh_private_key_file: ~/.ssh/id_ed25519_personal
```

Verification:

```bash
cd ansible
ansible pi4mB01 -m ping
```

### known_hosts conflict

Problem:

SSH reports that the remote host identification has changed.

Cause:

A Raspberry Pi was reimaged or replaced and now has a different SSH host key at the same IP address.

Resolution:

Remove the stale host key after confirming the node replacement is expected:

```bash
ssh-keygen -R 192.168.68.101
```

Reconnect and accept the new host key.

Verification:

```bash
ssh abdul@192.168.68.101 hostname
```

## Ansible

### Inventory not found

Problem:

Ansible cannot find the `pis` group or uses localhost only.

Cause:

Ansible was run outside the `ansible/` directory, so `ansible.cfg` was not applied.

Resolution:

```bash
cd ansible
ansible-inventory --graph
```

Verification:

The output should include `pis`, `k3s_server` and `k3s_agents`.

### Role lookup failure

Problem:

`ansible-playbook` cannot find the `common` or `k3s` role.

Cause:

The configured `roles_path` from `ansible/ansible.cfg` was not loaded, or the command was run from an unexpected location.

Resolution:

Run from the `ansible/` directory:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml
```

Verification:

The playbook starts role tasks from `roles/common`.

### Idempotency concern

Problem:

A playbook reports changes on every run.

Cause:

Some tasks legitimately check state, but repeated changes may also indicate non-idempotent task behavior.

Resolution:

Review the changed task. Prefer Ansible modules and state declarations. Use guards such as `creates` only where a shell command is required.

Verification:

Run the same playbook twice and compare the recap:

```bash
ansible-playbook playbooks/baseline.yml
ansible-playbook playbooks/baseline.yml
```

### Package task changes every run

Problem:

Package-related tasks appear noisy during repeated baseline runs.

Cause:

Package cache refresh or package updates can report changes depending on cache age and available upgrades.

Resolution:

The baseline package cache task uses a cache validity window. Routine upgrades should be handled through `playbooks/update.yml`.

Verification:

```bash
ansible-playbook playbooks/update.yml
ansible-playbook playbooks/baseline.yml
```

## Raspberry Pi

### Hostname mismatch

Problem:

The hostname returned by SSH does not match the inventory host.

Cause:

The node was imaged with the wrong hostname or the wrong SD card was inserted.

Resolution:

Set the hostname to the expected machine name or reimage the node with the correct hostname.

Verification:

```bash
ssh abdul@192.168.68.101 hostname
```

### Kernel cmdline cgroup settings

Problem:

K3s fails or Kubernetes cannot manage memory and CPU resources correctly.

Cause:

Required Raspberry Pi cgroup kernel parameters are missing, or `cgroup_disable=memory` is present.

Resolution:

Run the baseline playbook:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml
```

The `common` role manages cgroup settings in `/boot/firmware/cmdline.txt` and reboots when required.

Verification:

```bash
ssh abdul@192.168.68.101 'cat /proc/cmdline'
```

Confirm memory cgroups are enabled.

### zram swap enabled

Problem:

Kubernetes reports swap-related problems or node readiness is unstable.

Cause:

Swap or zram swap is active.

Resolution:

Run:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml
```

The `common` role disables active swap, disables `zramswap.service` when present and comments swap entries in `/etc/fstab`.

Verification:

```bash
ssh abdul@192.168.68.101 'swapon --show'
```

The command should return no active swap devices.

### Time synchronization

Problem:

TLS, Kubernetes or package operations behave inconsistently.

Cause:

Node time is incorrect or time synchronization is not running.

Resolution:

Run the baseline playbook. The `common` role installs and configures Chrony.

Verification:

```bash
ssh abdul@192.168.68.101 'timedatectl status'
ssh abdul@192.168.68.101 'systemctl status chrony --no-pager'
```

## Kubernetes

### kubeconfig points to localhost

Problem:

kubectl on the management workstation cannot reach the cluster API.

Cause:

The K3s kubeconfig originally points to `127.0.0.1`, which only works on the control-plane node.

Resolution:

Run the K3s playbook so the kubeconfig is fetched and rewritten:

```bash
cd ansible
ansible-playbook playbooks/k3s.yml
```

Verification:

```bash
cd ..
kubectl --kubeconfig ansible/kubeconfig get nodes
```

### Worker labels missing

Problem:

Worker nodes do not display the expected worker role.

Cause:

Kubernetes does not automatically add the worker role label in this setup.

Resolution:

Run the K3s playbook. The role applies:

```text
node-role.kubernetes.io/worker=worker
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes
```

### Node naming mismatch

Problem:

Kubernetes node names do not match inventory hostnames.

Cause:

The operating system hostname was wrong when K3s registered the node.

Resolution:

Correct the node hostname, then rebuild or rejoin the node as needed.

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
```

### Cluster verification commands

Problem:

Cluster health is uncertain after changes.

Cause:

Installation success does not guarantee all system components are healthy.

Resolution:

Run:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
kubectl --kubeconfig ansible/kubeconfig get pods -n kube-system
kubectl --kubeconfig ansible/kubeconfig get storageclass
kubectl --kubeconfig ansible/kubeconfig top nodes
```

Verification:

Nodes should be `Ready`, system pods should be running, and Metrics Server should return node metrics.

## Documentation

### MkDocs virtual environment not active

Problem:

`mkdocs` command is not found.

Cause:

The project virtual environment is not active or dependencies are not installed.

Resolution:

```bash
source .venv/bin/activate
pip install -r requirements/docs.txt
```

Verification:

```bash
mkdocs --version
```

### Python externally managed environment

Problem:

`pip install` fails because the system Python environment is externally managed.

Cause:

Modern Linux distributions protect system Python packages.

Resolution:

Use the project virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements/docs.txt
```

Verification:

```bash
which python
which pip
```

Both should point under `.venv`.

### GitHub Pages publication

Problem:

Documentation builds locally but is not published.

Cause:

GitHub Pages deployment is not yet defined as an automated workflow in the current repository.

Resolution:

For now, validate the local MkDocs build. Add GitHub Pages automation in a future sprint if desired.

Verification:

```bash
mkdocs build
```

## Design Decisions

### Troubleshooting follows operational layers

Issues are grouped by SSH, Ansible, Raspberry Pi, Kubernetes and documentation because failures usually occur at one of those layers.

### Verification is required after every fix

Each issue includes a verification step so the operator can confirm the result.

## Best Practices

- verify SSH before debugging Ansible
- verify Ansible before debugging Kubernetes installation
- run playbooks from the `ansible/` directory
- use `ssh-agent` for encrypted keys
- preserve node hostnames and reserved IPs
- use `kubectl --kubeconfig ansible/kubeconfig` from the repository root
- build MkDocs after documentation changes

## Future Improvements

Future troubleshooting improvements may include:

- service-specific troubleshooting guides
- Kubernetes event collection procedures
- log collection commands
- monitoring dashboard links
- documented GitHub Pages deployment workflow

## Related Documents

- [Bootstrap](bootstrap.md)
- [Updating](updating.md)
- [Rebuilding](rebuilding.md)
- [Ansible](../infrastructure/ansible.md)
- [Kubernetes](../infrastructure/kubernetes.md)
- [Security](../infrastructure/security.md)
