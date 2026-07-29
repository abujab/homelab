# Ansible

---

## Purpose

This document describes how Ansible is used to manage the HomeLab Raspberry Pi infrastructure.

Ansible provides the repeatable automation layer for operating system baseline
configuration, package maintenance, wired networking, K3s installation and
qualified host-storage mounts.

## Scope

This document covers:

- why Ansible is used
- inventory structure
- group variables
- host variables
- playbooks
- roles
- the `common` role
- the `network` role
- the `k3s` role
- the `storage` role
- idempotency
- ssh-agent usage
- verification philosophy

This document does not provide a full task-by-task reference. The task files in `ansible/roles/` remain the implementation source.

## Background

Manual configuration is manageable for one machine but does not scale cleanly across a cluster.

HomeLab uses Ansible so that node configuration is described in Git, can be reviewed, and can be safely repeated as the platform grows.

The current Ansible project is located under `ansible/`.

## Architecture / Implementation

Current Ansible structure:

```text
ansible/
+-- ansible.cfg
+-- inventories/
|   +-- home/
|       +-- group_vars/
|       |   +-- all.yml
|       +-- host_vars/
|       |   +-- pi4mB01.yml
|       |   +-- pi4mB02.yml
|       |   +-- pi4mB03.yml
|       |   +-- pi4mB04.yml
|       +-- hosts.yml
+-- playbooks/
|   +-- baseline.yml
|   +-- hardening.yml
|   +-- k3s.yml
|   +-- storage-discover.yml
|   +-- storage-onboard.yml
|   +-- storage-qualify.yml
|   +-- storage.yml
|   +-- update.yml
+-- roles/
    +-- common/
    +-- network/
    +-- k3s/
    +-- storage/
```

### Inventory

The home inventory is defined in `ansible/inventories/home/hosts.yml`.

Current groups:

| Group | Purpose |
|-------|---------|
| `pis` | All Raspberry Pi nodes |
| `k3s_server` | K3s control-plane node |
| `k3s_agents` | K3s worker nodes |
| `storage_nodes` | Nodes with independently qualified dedicated storage |

The current group membership is:

```text
pis
+-- pi4mB01
+-- pi4mB02
+-- pi4mB03
+-- pi4mB04

k3s_server
+-- pi4mB01

k3s_agents
+-- pi4mB02
+-- pi4mB03
+-- pi4mB04

storage_nodes
+-- pi4mB01
+-- pi4mB02
```

### Group variables

Shared settings are stored in `ansible/inventories/home/group_vars/all.yml`.

Current shared settings include:

- SSH user: `abdul`
- SSH private key: `~/.ssh/id_ed25519_personal`

The private key is intended to be unlocked once through `ssh-agent`, allowing Ansible to connect to all nodes without repeatedly prompting for the key passphrase.

### Host variables

Node-specific values are stored under `ansible/inventories/home/host_vars/`.

The current host variables define the Ansible connection IP for each Raspberry Pi:

| Host | `ansible_host` |
|------|----------------|
| pi4mB01 | 192.168.68.101 |
| pi4mB02 | 192.168.68.102 |
| pi4mB03 | 192.168.68.103 |
| pi4mB04 | 192.168.68.104 |

### Playbooks

Playbooks orchestrate roles or focused maintenance tasks.

| Playbook | Purpose |
|----------|---------|
| `baseline.yml` | Applies the common and network baseline roles to all Raspberry Pi nodes |
| `update.yml` | Updates APT packages across all Raspberry Pi nodes |
| `k3s.yml` | Installs and verifies the K3s cluster |
| `storage-discover.yml` | Reports attached storage, identity and system-disk relationships without changing the node |
| `storage-onboard.yml` | Initializes one explicitly authorized inventory disk, then reconciles its UUID mount |
| `storage-qualify.yml` | Exercises one prepared node with SMART, USB, fio and kernel-error checks |
| `storage.yml` | Reconciles previously qualified storage on `storage_nodes` without destructive operations |
| `hardening.yml` | Reserved for security hardening work |

### Roles

Roles contain reusable implementation logic.

The current roles are:

| Role | Responsibility |
|------|----------------|
| `common` | Shared operating system baseline for Raspberry Pi nodes |
| `network` | Wired Ethernet baseline and Wi-Fi radio disablement |
| `k3s` | K3s server, worker join, kubeconfig, labels and verification |
| `storage` | Inventory-driven disk discovery, guarded initialization, qualification and persistent mount reconciliation |

### Common role

The `common` role currently manages:

- timezone configuration
- baseline package installation
- Chrony time synchronization
- enablement and verification of the packaged Chrony synchronization wait unit
- rejection of competing active time synchronization services
- swap disablement
- Raspberry Pi kernel cgroup parameters
- baseline verification

These tasks prepare each node for Kubernetes and keep the node baseline consistent.

### Network role

The `network` role currently manages:

- Ethernet preflight validation before Wi-Fi changes
- `eth0` operational-state verification
- inventory IPv4 address verification on `eth0`
- default-route verification through gateway `192.168.68.1`
- Wi-Fi radio disablement through NetworkManager
- verification that `wlan0` carries no IPv4 address
- verification that SSH connectivity remains functional

The role is applied after `common` in `playbooks/baseline.yml`:

```yaml
roles:
  - common
  - network
```

The role is intentionally separate from `common` and `k3s` because wired transport is a platform networking responsibility.

### K3s role

The `k3s` role currently manages:

- K3s server installation on `pi4mB01`
- K3s agent installation on `pi4mB02`, `pi4mB03` and `pi4mB04`
- unit-only first installation with `INSTALL_K3S_SKIP_START=true`
- a runtime assertion that a newly installed unit remains inactive until its
  Chrony gate is present
- kubeconfig retrieval to the management workstation
- kubeconfig API endpoint rewrite from localhost to the control-plane IP
- root-only K3s-generated and workstation kubeconfig permissions
- an Ansible-owned server command drop-in without editing the generated unit
- fail-closed `chrony-wait.service` dependencies for server and agents
- a 60-second, systemd-managed bounded late-time recovery timer and a
  three-minute systemd start timeout
- read-only local cold-boot health reporting
- worker node role labels
- cluster verification

`playbooks/k3s.yml` handles the server first and waits for local API readiness.
It then reconciles workers with `serial: 1`, waiting for each agent and
Kubernetes node to return before continuing. Systemd is reloaded and a K3s
service is restarted only when its managed unit content changes. Changes to
the recovery helper, service or timer use a separate handler chain that reloads
systemd, resets the recovery oneshot and rearms the timer. An unchanged run
does not reload systemd, reset recovery state or restart K3s.

### Storage role

The `storage` role currently manages:

- one or more disks declared through `storage_disks` in host inventory
- persistent-path, model, serial, WWN and exact-capacity identity checks
- root, boot, swap and unexpected-mount protection
- read-only discovery of attached block devices and persistent identifiers
- guarded GPT and ext4 initialization through the onboarding entry point only
- exact filesystem metadata checks, UUID-based persistent mounts and exact
  fstab/mount verification
- SMART, USB topology, file-based benchmark, stability and kernel-log checks

Operational behavior is selected by `storage_mode`. Discovery and normal
reconciliation cannot partition or format a disk. Initialization additionally
requires the exact runtime token
`<inventory-hostname>:<disk-id>:ERASE` and a matching
`storage_target_disk_id`. Both are supplied at runtime and do not persist
destructive authorization in desired state. The
role detects an already prepared disk and skips all destructive tasks, making
onboarding repeatable without recreating its filesystem or UUID.

The role does not manage kernel USB quirks or reboot nodes. The obsolete quirk
workaround was removed after both current enclosures operated without it. A
future bridge that requires a kernel workaround must be evaluated explicitly
rather than extending normal storage reconciliation. SMART passthrough remains
mandatory for qualification but is not required to mount an already-qualified
filesystem.

The existing `pi4mB01` filesystem is represented by the same inventory model
with its legacy `pi-cl-storage` label preserved. The role remains independent
of Kubernetes and does not install Longhorn. The complete operator procedure is
documented in [Storage Onboarding](../operations/storage-onboarding.md).

## Design Decisions

### Ansible is agentless

Ansible works over SSH, so no long-running management agent is required on the Raspberry Pi nodes.

### Inventory represents where automation runs

Inventory groups express infrastructure intent such as all Raspberry Pis, control-plane nodes and worker nodes.

### Playbooks orchestrate, roles implement

Playbooks stay small and readable. Reusable logic lives in roles.

### Idempotency is required

Tasks should be safe to run repeatedly. Examples include using package state declarations, service state declarations, file replacement tasks and `creates` guards for K3s installation commands.

### Verification is part of automation

Automation should verify the resulting system state, not only apply changes. The existing roles include verification tasks for node baseline, wired network state and K3s cluster health.

## Best Practices

- run Ansible from the `ansible/` directory so `ansible.cfg` is applied
- unlock the SSH key with `ssh-agent` before running playbooks
- keep host-specific values in `host_vars`
- keep shared values in `group_vars`
- use roles for reusable logic
- prefer Ansible modules over shell commands
- use shell commands only when no suitable module exists
- make tasks safe to repeat
- run network changes against one node before the full `pis` group
- verify the resulting infrastructure state after each playbook run
- keep token handling under `no_log` and never retain token-derived evidence

## Future Improvements

Future Ansible work may include:

- implementation of the reserved hardening playbook
- explicit security baseline role
- additional inventory groups for x86, storage or AI nodes
- more automated validation tasks
- backup and restore automation
- controlled Kubernetes upgrade playbooks

## Related Documents

- [Raspberry Pi Cluster](raspberry-pi-cluster.md)
- [Kubernetes](kubernetes.md)
- [Security](security.md)
- [Repository Structure](../overview/repository.md)
- [Roadmap](../overview/roadmap.md)
- [Infrastructure Inventory](../reference/infrastructure-inventory.md)
- [Software Inventory](../reference/software-inventory.md)
- [Storage](storage.md)
- [ADR-0009 Wired Network for Cluster Nodes](../decisions/ADR-0009-wired-network-for-cluster-nodes.md)
