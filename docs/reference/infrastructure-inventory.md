# Infrastructure Inventory

---

## Purpose

This page is the authoritative human-readable inventory of current HomeLab
hardware and cluster nodes.

## Scope

The inventory covers the management plane, Raspberry Pi cluster, managed
network hardware and known dedicated storage. It does not list prospective x86,
NAS, Turing Pi or RK1 hardware as current infrastructure.

## Background

Node membership and addresses are verified against the Ansible inventory.
Storage identity and qualification state are verified against the storage role,
WO-0009 and its evidence. Hardware details that are not recorded in the
repository are explicitly marked Pending verification.

## Architecture / Implementation

### Management plane

| Item | Platform | Role | Cluster Member | Status |
|------|----------|------|----------------|--------|
| Management workstation | Arch Linux laptop; model Pending verification | Git, Ansible, kubectl, Helm, PKI and documentation operations | No | Current |

### Cluster nodes

| Host | IP Address | Hardware / Architecture | Network | Kubernetes Role | Dedicated Storage | Operational Status |
|------|------------|-------------------------|---------|-----------------|-------------------|--------------------|
| `pi4mB01` | `192.168.68.101` | Raspberry Pi 4 Model B / ARM64 | `eth0`; Wi-Fi disabled | Single K3s control plane | Qualified 160 GB disk mounted at `/srv/longhorn` | Ready |
| `pi4mB02` | `192.168.68.102` | Raspberry Pi 4 Model B / ARM64 | `eth0`; Wi-Fi disabled | K3s worker | WD1600BEVT known but not connected or qualified | Ready |
| `pi4mB03` | `192.168.68.103` | Raspberry Pi 4 Model B / ARM64 | `eth0`; Wi-Fi disabled | K3s worker | No qualified dedicated storage | Ready |
| `pi4mB04` | `192.168.68.104` | Raspberry Pi 4 Model B / ARM64 | `eth0`; Wi-Fi disabled | K3s worker | No qualified dedicated storage | Ready |

All four nodes run the Raspberry Pi OS Lite 64-bit / Debian 13 baseline. Node
addresses are DHCP reservations represented by `ansible_host` values under
`ansible/inventories/home/host_vars/`.

### Network hardware

| Item | Verified Detail | Responsibility | Status |
|------|-----------------|----------------|--------|
| Home router | Model Pending verification; gateway `192.168.68.1` | LAN routing and DHCP reservations | Current, externally configured |
| TP-Link TL-SG108E | Ethernet switch | Wired cluster transport and Layer 2 path | Current |
| Home LAN | `192.168.68.0/22` | Node, management and service network | Current |
| Node Ethernet | `eth0` on every Raspberry Pi | Kubernetes, MetalLB and management traffic | Current |
| Node Wi-Fi | `wlan0`; disabled by NetworkManager through Ansible | Exceptional recovery only | Disabled |

### Dedicated storage

| Node | Disk / Capacity | Enclosure or Bridge | Filesystem | Mount | Qualification | Known Limitation |
|------|-----------------|---------------------|------------|-------|---------------|------------------|
| `pi4mB01` | Hitachi HTS545016B9SA02; 160 GB / 149 GiB | NexStar CX enclosure; ASMedia ASM1051 USB 3 bridge | ext4; label `pi-cl-storage` | `/srv/longhorn` | Qualified by WO-0009 | `usb-storage`, no UASP; 5400 RPM; both Y-cable connectors required |
| `pi4mB02` | WD1600BEVT; 160 GB | Not connected | Not prepared | Not mounted | Not qualified | Enclosure and runtime behavior Pending verification |
| `pi4mB03` | None recorded | Not applicable | Not applicable | Not mounted | No qualified storage | Additional hardware required |
| `pi4mB04` | None recorded | Not applicable | Not applicable | Not mounted | No qualified storage | Additional hardware required |

The directory name `/srv/longhorn` reserves a possible future data path. It does
not indicate that Longhorn is installed. The cluster currently has Local Path
Provisioner only and no replicated storage layer.

### Authoritative sources

- node membership: `ansible/inventories/home/hosts.yml`
- node addresses: `ansible/inventories/home/host_vars/`
- network baseline: `ansible/roles/network/`
- qualified storage identity: `ansible/inventories/home/host_vars/pi4mB01.yml`
- storage mount contract: `ansible/roles/storage/`
- current operational state: `PROJECT_STATE.md`
- detailed storage results: `artifacts/WO-0009/`

## Design Decisions

Machine inventory describes hardware identity. Service identities and virtual
addresses are maintained in [Naming and Addressing](naming-and-addressing.md).

Only independently qualified disks may place a node in the Ansible
`storage_nodes` group.

## Best Practices

- update Ansible inventory before updating this table
- preserve exact machine identifiers and reserved addresses
- qualify storage independently on each node
- keep detailed SMART and benchmark data in work-order evidence
- never infer missing router or storage hardware details

## Future Improvements

- qualify the known `pi4mB02` disk after its enclosure is available
- add at least one additional qualified storage node before Longhorn evaluation
- record management workstation hardware only when verified
- add future compute or storage hardware only after it exists

## Related Documents

- [Naming and Addressing](naming-and-addressing.md)
- [Raspberry Pi Cluster](../infrastructure/raspberry-pi-cluster.md)
- [Networking](../infrastructure/networking.md)
- [Storage](../infrastructure/storage.md)
- [Roadmap](../overview/roadmap.md)
- [WO-0009 Validation](https://github.com/abujab/homelab/blob/main/artifacts/WO-0009/validation.md)
