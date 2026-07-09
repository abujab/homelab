# Rebuilding

---

## Purpose

This document describes disaster recovery procedures for replacing a failed Raspberry Pi node or rebuilding the management workstation.

The goal is to make recovery possible using the repository, documented procedures and required installation media.

## Scope

This document covers:

- replacing a failed Raspberry Pi
- flashing a new microSD card
- assigning the correct hostname
- restoring DHCP reservation behavior
- configuring SSH access
- updating inventory if needed
- running the baseline playbook
- rejoining K3s
- verification
- replacing the management workstation

This document does not define persistent application data restore procedures. The current platform does not yet host a documented persistent application backup model.

## Background

The current HomeLab platform is intentionally rebuildable.

Raspberry Pi node identity is represented by:

- hostname
- DHCP reservation
- Ansible inventory membership
- Ansible host variables
- Kubernetes node role

## Architecture / Implementation

## Replacing a failed Raspberry Pi

### 1. Identify the failed node

Identify which node has failed:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
```

Current expected nodes:

| Host | IP Address | Role |
|------|------------|------|
| pi4mB01 | 192.168.68.101 | K3s control plane |
| pi4mB02 | 192.168.68.102 | K3s worker |
| pi4mB03 | 192.168.68.103 | K3s worker |
| pi4mB04 | 192.168.68.104 | K3s worker |

### 2. Flash a new microSD card

Flash Raspberry Pi OS Lite 64-bit to a replacement microSD card.

Configure:

- SSH enabled
- username `abdul`
- SSH public key for the management workstation
- hostname matching the failed node

### 3. Restore the network identity

Ensure the DHCP reservation maps the replacement Raspberry Pi to the expected IP address for that hostname.

If the hardware MAC address changed, update the DHCP reservation on the router.

### 4. Verify SSH access

```bash
ssh -i ~/.ssh/id_ed25519_personal abdul@<node-ip> hostname
```

The command should return the expected hostname.

If the host key changed, remove the old key from `known_hosts` for that IP or hostname, then reconnect and accept the new host key after verifying the replacement hardware.

### 5. Update inventory if needed

If the replacement uses the same hostname and reserved IP, no inventory change should be required.

If the IP address intentionally changed, update the matching file under:

```text
ansible/inventories/home/host_vars/
```

### 6. Run the baseline playbook

From the `ansible/` directory:

```bash
ansible pis -m ping --limit <hostname>
ansible-playbook playbooks/baseline.yml --limit <hostname>
```

This applies the required operating system baseline.

### 7. Rejoin K3s

For a worker node, rerun the K3s playbook:

```bash
ansible-playbook playbooks/k3s.yml
```

The K3s role installs agents on nodes in the `k3s_agents` group and labels workers from the control-plane node.

For the current single control-plane node, replacing `pi4mB01` is a larger recovery event because it hosts the K3s server. Rebuild it first, run the baseline, then run:

```bash
ansible-playbook playbooks/k3s.yml
```

The current platform does not yet have a high-availability control plane or documented etcd/server-state backup.

### 8. Verify recovery

From the repository root:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
kubectl --kubeconfig ansible/kubeconfig get pods -n kube-system
```

The replacement node should be present and `Ready`.

## Replacing the management workstation

### 1. Install base tools

On the replacement Arch Linux workstation:

```bash
sudo pacman -Syu
sudo pacman -S git python python-pip python-virtualenv ansible openssh kubectl
```

### 2. Restore or create the SSH key

Restore the existing private key if available:

```text
~/.ssh/id_ed25519_personal
```

If the key cannot be restored, create a new key and install the public key on each Raspberry Pi user account:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "homelab"
```

### 3. Clone the repository

```bash
git clone https://github.com/abujab/homelab.git
cd homelab
```

### 4. Recreate the Python environment

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements/docs.txt
```

### 5. Verify access

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_personal
cd ansible
ansible pis -m ping
```

### 6. Verify Kubernetes access

If `ansible/kubeconfig` is present and current:

```bash
cd ..
kubectl --kubeconfig ansible/kubeconfig get nodes
```

If kubeconfig must be refreshed, rerun the K3s playbook from `ansible/`:

```bash
ansible-playbook playbooks/k3s.yml
```

## Design Decisions

### Node identity is preserved

Replacement nodes should reuse the existing hostname and reserved IP unless there is a deliberate inventory change.

### Worker recovery is simpler than control-plane recovery

The current platform has one K3s server. Worker nodes can be rejoined more easily than the control-plane node.

### Workstation recovery depends on Git and SSH keys

The workstation can be rebuilt from the repository, but access depends on restoring or redistributing the operator SSH key.

## Best Practices

- document which node failed before making changes
- preserve hostnames and reserved IPs during replacement
- verify SSH before running Ansible
- run `baseline.yml` before K3s recovery
- verify Kubernetes after node replacement
- avoid storing unique platform knowledge only on the workstation
- keep the repository pushed to a remote Git server

## Future Improvements

Future recovery improvements should include:

- K3s server backup and restore procedure
- persistent volume backup and restore testing
- documented control-plane replacement runbook
- automated workstation bootstrap script
- secrets recovery model
- high-availability control-plane evaluation

## Related Documents

- [Bootstrap](bootstrap.md)
- [Backup](backup.md)
- [Troubleshooting](troubleshooting.md)
- [Raspberry Pi Cluster](../infrastructure/raspberry-pi-cluster.md)
- [Kubernetes](../infrastructure/kubernetes.md)
