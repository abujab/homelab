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
WO-0009, WO-0010 and their evidence. Hardware details that are not recorded in the
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
| `pi4mB02` | `192.168.68.102` | Raspberry Pi 4 Model B / ARM64 | `eth0`; Wi-Fi disabled | K3s worker | Qualified 320 GB disk mounted at `/srv/longhorn` | Ready |
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
| `pi4mB02` | WDC WD3200BEVT-22ZCT0; 320 GB / 298 GiB | Externally powered Sabrent/JMicron; USB `152d:a578` | ext4; label `pi4mB02-data01` | `/srv/longhorn` | Qualified by WO-0010 | UAS at 5000M; 5400 RPM; accepted UDMA CRC baseline 1 requires monitoring |
| `pi4mB03` | None recorded | Not applicable | Not applicable | Not mounted | No qualified storage | Additional hardware required |
| `pi4mB04` | None recorded | Not applicable | Not applicable | Not mounted | No qualified storage | Additional hardware required |

The directory name `/srv/longhorn` reserves a possible future data path. It does
not indicate that Longhorn is installed. The cluster currently has Local Path
Provisioner only and no replicated storage layer.

### Authoritative sources

- node membership: `ansible/inventories/home/hosts.yml`
- node addresses: `ansible/inventories/home/host_vars/`
- network baseline: `ansible/roles/network/`
- qualified storage identity: `ansible/inventories/home/host_vars/`
- storage mount contract: `ansible/roles/storage/`
- current operational state: `PROJECT_STATE.md`
- detailed storage results: `artifacts/WO-0009/` and `artifacts/WO-0010/`

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

- monitor the accepted pi4mB02 UDMA CRC baseline and requalify after any increase
- review and approve the Longhorn architecture before deployment work
- record management workstation hardware only when verified
- add future compute or storage hardware only after it exists

## Related Documents

- [Naming and Addressing](naming-and-addressing.md)
- [Raspberry Pi Cluster](../infrastructure/raspberry-pi-cluster.md)
- [Networking](../infrastructure/networking.md)
- [Storage](../infrastructure/storage.md)
- [Roadmap](../overview/roadmap.md)
- [WO-0009 Validation](https://github.com/abujab/homelab/blob/main/artifacts/WO-0009/validation.md)
- [WO-0010 Validation](https://github.com/abujab/homelab/blob/main/artifacts/WO-0010/validation.md)
