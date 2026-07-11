# WORK ORDER

**ID:** WO-0005
**Title:** Wired Network Baseline
**Status:** Completed
**Primary Agent:** Codex
**Architect:** ChatGPT
**Owner:** Abdul Jabbar
**Target Release:** v0.5.1

---

## Objective

Create a dedicated Ansible `network` role that establishes wired Ethernet as the
required network transport for the HomeLab Kubernetes nodes.

The role shall:

- verify that Ethernet is operational before making changes
- ensure the default route uses `eth0`
- disable the Raspberry Pi Wi-Fi radio
- verify that Wi-Fi remains disabled
- validate Kubernetes and MetalLB after the network change

This work order hardens the networking foundation introduced by WO-0004.

---

## Current State

All four Raspberry Pi nodes are now connected through wired Ethernet using the
TP-Link TL-SG108E switch.

Current node addresses:

| Node | Ethernet address | Kubernetes role |
|------|------------------|-----------------|
| pi4mB01 | 192.168.68.101 | Control plane |
| pi4mB02 | 192.168.68.102 | Worker |
| pi4mB03 | 192.168.68.103 | Worker |
| pi4mB04 | 192.168.68.104 | Worker |

Verified current network state:

- `eth0` is `UP` on every node
- `wlan0` is currently `DOWN`
- the default route uses `eth0`
- the default gateway is `192.168.68.1`
- all Kubernetes nodes are `Ready`
- Kubernetes reports the expected internal node addresses
- existing Ansible inventory addresses remain valid

Current LAN subnet reported by the nodes:

```text
192.168.68.0/22
````

No IP address migration is required by this work order.

---

## Architectural Decision

Create:

```text
docs/decisions/ADR-0009-wired-network-for-cluster-nodes.md
```

ADR-0009 shall record the following decision:

> HomeLab Kubernetes nodes use wired Ethernet as their normal production
> transport. Wi-Fi is disabled on dedicated cluster nodes and is not relied upon
> for Kubernetes, MetalLB or platform-service traffic.

The ADR shall explain:

* the MetalLB Layer 2 limitation encountered over Raspberry Pi Wi-Fi
* why reliable ARP and memberlist communication require wired networking
* why Wi-Fi is unsuitable as the normal cluster transport
* why Ethernet is required for future storage and compute workloads
* that Wi-Fi may be re-enabled manually only for exceptional recovery work
* that cluster nodes should return to the managed wired baseline afterward

ADR-0008 shall not be rewritten.

Add a related-decision link between ADR-0008 and ADR-0009 where appropriate.

---

## Scope

### Included

* dedicated Ansible `network` role
* persistent Wi-Fi radio disablement
* Ethernet safety checks
* default-route verification
* network-state verification
* Kubernetes post-change verification
* MetalLB and Pi-hole post-change verification
* ADR-0009
* relevant documentation updates
* `PROJECT_STATE.md` update
* pull request and release preparation

### Excluded

* static IP configuration inside the operating system
* DHCP server changes
* router configuration
* VLAN configuration
* switch VLAN configuration
* network segmentation
* firewall changes
* ingress controller deployment
* certificate management
* replacement of NetworkManager
* removal of Wi-Fi drivers
* kernel module blacklisting

---

## Repository Changes

Create the following role structure:

```text
ansible/
└── roles/
    └── network/
        ├── defaults/
        │   └── main.yml
        ├── tasks/
        │   ├── main.yml
        │   ├── preflight.yml
        │   ├── wifi.yml
        │   └── verify.yml
        └── README.md
```

Update the appropriate playbook so the role is applied after the common
baseline configuration.

The role must remain separate from:

```text
ansible/roles/common/
ansible/roles/k3s/
```

---

## Role Responsibilities

### `defaults/main.yml`

Define configurable values rather than hardcoding them repeatedly.

Expected variables:

```yaml
network_ethernet_interface: eth0
network_wifi_interface: wlan0
network_expected_gateway: 192.168.68.1
network_disable_wifi: true
```

Use names that clearly indicate ownership by the `network` role.

Do not duplicate node IP addresses in role defaults. Node addresses remain
inventory data.

---

### `tasks/main.yml`

Orchestrate the role in this order:

```text
Preflight validation
        ↓
Disable Wi-Fi
        ↓
Verify final network state
```

Use `ansible.builtin.import_tasks` or the repository's existing role convention.

Do not place all implementation directly inside `main.yml`.

---

### `tasks/preflight.yml`

Before disabling Wi-Fi, verify all of the following:

* `eth0` exists
* `eth0` is operationally up
* `eth0` has an IPv4 address
* the expected node address is reachable through Ethernet
* the default route uses `eth0`
* the default gateway is `192.168.68.1`

The role must fail safely before changing Wi-Fi state if Ethernet is not ready.

The validation should use registered command output and
`ansible.builtin.assert`.

Commands used only for inspection must use:

```yaml
changed_when: false
```

Failure messages must clearly identify:

* the node
* the failed requirement
* the expected state
* the detected state

---

### `tasks/wifi.yml`

Disable Wi-Fi using NetworkManager.

The implementation should use NetworkManager's radio control equivalent to:

```bash
nmcli radio wifi off
```

The task must be idempotent.

Requirements:

* determine the current Wi-Fi radio state first
* disable Wi-Fi only when it is currently enabled
* report `changed` only when the state was modified
* do not blacklist kernel modules
* do not remove Wi-Fi packages
* do not delete existing Wi-Fi profiles
* do not reboot unless technically required
* retain the ability to recover Wi-Fi manually if Ethernet fails in the future

Do not use an unconditional command with:

```yaml
changed_when: true
```

---

### `tasks/verify.yml`

Verify:

* `eth0` exists
* `eth0` is `UP`
* `eth0` has the node's expected IPv4 address
* the default route uses `eth0`
* the default gateway is correct
* `wlan0` is not carrying an IPv4 address
* NetworkManager reports Wi-Fi as disabled
* SSH connectivity remains functional

Use assertions with clear success and failure messages.

The role must verify desired state rather than only assuming the command
succeeded.

---

## Playbook Integration

Apply the `network` role through the existing baseline orchestration.

Expected logical order:

```yaml
roles:
  - common
  - network
```

Do not move unrelated tasks between roles.

Do not rename existing playbooks or roles.

If tags are already used by the repository, add a suitable tag such as:

```text
network
```

Do not introduce a new tagging convention only for this role.

---

## Safety Requirements

The role modifies network connectivity and must be implemented conservatively.

Required safeguards:

1. Ethernet preflight checks execute before Wi-Fi is disabled.
2. The role must fail before modification if the default route is not using
   `eth0`.
3. The role must not change node IP addresses.
4. The role must not restart NetworkManager unnecessarily.
5. The role must not disconnect a node that is still being reached through
   Wi-Fi.
6. The role must support safe repeated execution.
7. The implementation should initially be validated with:

```bash
ansible-playbook playbooks/baseline.yml --limit pi4mB01
```

8. After successful single-node validation, run against the complete `pis`
   group.

---

## Idempotency Requirements

After the initial successful run, a second run must produce no network changes.

Expected second-run behavior:

```text
network role tasks: ok
changed: 0
failed: 0
```

A task may report changed only if the actual desired state was modified.

---

## Reboot Persistence

Verify that Wi-Fi remains disabled after a controlled reboot of one test node.

Suggested sequence:

```bash
ansible-playbook playbooks/baseline.yml --limit pi4mB01

ansible pi4mB01 -b -m reboot

ansible pi4mB01 -m ping

ansible pi4mB01 -m shell -a "ip -br addr"

ansible pi4mB01 -m command -a "nmcli radio wifi"
```

After successful verification on `pi4mB01`, repeat the baseline role and
verification for all nodes.

Do not reboot all four nodes simultaneously.

---

## Infrastructure Validation

### Ansible connectivity

```bash
cd ansible

ansible pis -m ping
```

Expected:

```text
pi4mB01 SUCCESS
pi4mB02 SUCCESS
pi4mB03 SUCCESS
pi4mB04 SUCCESS
```

### Interface state

```bash
ansible pis -m shell -a "ip -br addr show | grep -E 'eth0|wlan0'"
```

Expected on every node:

```text
eth0   UP     192.168.68.x/22
wlan0  DOWN
```

The exact textual Wi-Fi state may vary by NetworkManager and kernel reporting,
but `wlan0` must not have an IPv4 address and Wi-Fi radio state must be disabled.

### Default route

```bash
ansible pis -m shell -a "ip route show default"
```

Expected on every node:

```text
default via 192.168.68.1 dev eth0
```

### NetworkManager radio state

```bash
ansible pis -m command -a "nmcli radio wifi"
```

Expected:

```text
disabled
```

---

## Kubernetes Validation

```bash
kubectl get nodes -o wide
```

Expected:

* all four nodes are `Ready`
* internal addresses remain `192.168.68.101-104`
* pi4mb01 remains control plane
* pi4mb02-pi4mb04 remain workers

```bash
kubectl get pods -A
```

Expected:

* no platform pods are in `Failed`, `Pending` or `CrashLoopBackOff`
* all MetalLB speakers are running
* Pi-hole is running

---

## MetalLB and Pi-hole Validation

Verify that Ethernet resolves the previously observed Layer 2 reachability
problem.

### MetalLB service

```bash
kubectl get svc pihole -n networking
```

Expected:

```text
EXTERNAL-IP: 192.168.68.200
```

### ARP reachability

From the management workstation:

```bash
sudo arping -I enp58s0u1u4 192.168.68.200
```

The management interface name may differ and should be discovered using:

```bash
ip route get 192.168.68.200
```

Expected:

* ARP replies are received
* the LoadBalancer IP resolves to a MAC address

### Pi-hole web UI

```bash
curl -I http://192.168.68.200/admin/
```

Expected:

* HTTP response or redirect from Pi-hole

### DNS resolution

```bash
dig @192.168.68.200 google.com
dig @192.168.68.200 pihole.home.arpa
```

Expected:

* Pi-hole answers both queries
* public DNS forwarding succeeds
* `pihole.home.arpa` resolves to `192.168.68.200`

---

## Documentation Updates

Update the relevant MkDocs pages.

At minimum review and update:

```text
docs/infrastructure/raspberry-pi-cluster.md
docs/infrastructure/ansible.md
docs/infrastructure/networking.md
docs/infrastructure/security.md
docs/operations/bootstrap.md
docs/operations/rebuilding.md
docs/operations/troubleshooting.md
docs/overview/architecture.md
docs/overview/roadmap.md
PROJECT_STATE.md
```

Document:

* the TP-Link TL-SG108E switch
* the wired physical topology
* Ethernet as the required cluster transport
* Wi-Fi disablement through Ansible
* how to temporarily re-enable Wi-Fi for recovery
* MetalLB's Layer 2 dependency on reliable Ethernet/ARP behavior
* the observed Raspberry Pi Wi-Fi limitation
* the final validation commands
* ADR-0009

Avoid duplicating stable IP information beyond the existing authoritative
reference location.

---

## Recovery Procedure

Document the emergency Wi-Fi recovery command:

```bash
sudo nmcli radio wifi on
```

Also document that Wi-Fi can be re-enabled only through:

* direct console access
* an existing Ethernet SSH connection
* another explicitly documented recovery path

The next baseline run will restore the declared Wi-Fi-disabled state.

The recovery procedure must not undermine the intended managed configuration.

---

## Project State Update

Update `PROJECT_STATE.md` after successful implementation.

Add or update the networking milestone to record:

* TP-Link TL-SG108E deployed
* all Raspberry Pis migrated to Ethernet
* Wi-Fi disabled through Ansible
* wired default routes verified
* MetalLB Layer 2 reachability verified
* Pi-hole UI and DNS verified from the LAN

Do not mark the work order complete until runtime validation has succeeded.

---

## Branch and Pull Request

Create the branch:

```text
wo-0005-wired-network-baseline
```

Do not commit directly to `main`.

PR title:

```text
WO-0005: Wired Network Baseline
```

The PR description must include:

```markdown
## Summary

## Work Order

## Architecture Decisions

## Implementation

## Validation

## Idempotency

## Documentation

## Security Impact

## Risks

## Rollback

## Known Limitations

## Target Release
```

Target release:

```text
v0.5.1
```

---

## Acceptance Criteria

The work order is complete when:

* [ ] `network` role exists with the agreed structure
* [ ] Ethernet preflight checks are implemented
* [ ] preflight failure prevents Wi-Fi modification
* [ ] Wi-Fi radio is disabled through NetworkManager
* [ ] implementation is idempotent
* [ ] second baseline run reports no network changes
* [ ] Wi-Fi remains disabled after reboot
* [ ] all nodes retain addresses `192.168.68.101-104`
* [ ] all default routes use `eth0`
* [ ] all Kubernetes nodes remain `Ready`
* [ ] all core platform pods remain healthy
* [ ] MetalLB VIP `192.168.68.200` responds through Ethernet
* [ ] Pi-hole UI is reachable from the LAN
* [ ] Pi-hole answers DNS queries from the LAN
* [ ] ADR-0009 is created
* [ ] documentation is updated
* [ ] `PROJECT_STATE.md` is updated
* [ ] `mkdocs build --strict` succeeds
* [ ] pull request is opened
* [ ] architecture review is completed
* [ ] review findings are resolved
* [ ] PR is approved and merged
* [ ] release `v0.5.1` is created

---

## Validation Commands

```bash
cd ansible

ansible pis -m ping

ansible-playbook playbooks/baseline.yml --limit pi4mB01

ansible-playbook playbooks/baseline.yml --limit pi4mB01

ansible pi4mB01 -b -m reboot

ansible pi4mB01 -m ping

ansible-playbook playbooks/baseline.yml

ansible-playbook playbooks/baseline.yml

ansible pis -m shell -a "ip -br addr show | grep -E 'eth0|wlan0'"

ansible pis -m shell -a "ip route show default"

ansible pis -m command -a "nmcli radio wifi"

kubectl get nodes -o wide

kubectl get pods -A

kubectl get svc -A

ip route get 192.168.68.200

sudo arping -I enp58s0u1u4 192.168.68.200

curl -I http://192.168.68.200/admin/

dig @192.168.68.200 google.com

dig @192.168.68.200 pihole.home.arpa

source ../.venv/bin/activate

mkdocs build --strict
```

Adjust relative paths only as required by the repository's actual working
directory.

---

## Rollback

If Ethernet connectivity fails before Wi-Fi is disabled:

* stop the play
* correct Ethernet configuration
* do not proceed with Wi-Fi changes

If access remains available through Ethernet and Wi-Fi must be restored:

```bash
sudo nmcli radio wifi on
```

If remote access is unavailable:

* connect a monitor and keyboard
* log in locally
* run the recovery command
* verify NetworkManager state
* correct the wired configuration before rerunning Ansible

Do not remove the `network` role as the first recovery action. Correct the
underlying configuration or explicitly revert the relevant commit.

---

## Definition of Done

The Raspberry Pi Kubernetes cluster operates exclusively through wired Ethernet
under declarative Ansible control.

Wi-Fi is disabled persistently and safely, Ethernet connectivity is verified
before modification, and Kubernetes, MetalLB and Pi-hole remain operational and
reachable from the home LAN.

---

## Successor Work Order

Documentation Sprint 4 — Reference Documentation

The successor sprint may consolidate stable facts introduced by the completed
networking work, including:

* physical network topology
* switch inventory
* Ethernet MAC addresses
* node addressing
* service IP allocation
* DNS records
* naming conventions
* software versions

```

Your current output already satisfies the most important precondition: all four nodes retain their original IP addresses, use `eth0` as the default route, and remain healthy in Kubernetes.
```
