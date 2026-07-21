# Storage

---

## Purpose

This document describes the qualified storage hardware foundation and the direction for future persistent storage.

## Scope

This document covers:

- current storage state
- microSD-based nodes
- qualified USB storage hardware
- persistent host mounts
- Local Path Provisioner
- limitations of current storage
- future Longhorn evaluation
- future backup requirements

This document does not define a final storage architecture or backup implementation.

## Background

The current cluster runs on Raspberry Pi nodes using local microSD storage.

K3s includes Local Path Provisioner, which provides simple local persistent volume support. This is useful for early validation and lightweight experiments but does not provide a complete storage platform.

## Architecture / Implementation

Current storage model:

```text
Raspberry Pi node
|
+-- microSD card
    +-- operating system
    +-- K3s runtime state
    +-- local-path-provisioner volumes when used
```

Current Kubernetes storage component:

| Component | Current State | Purpose |
|-----------|---------------|---------|
| Local Path Provisioner | Installed by K3s | Provides node-local persistent volumes |

Local Path Provisioner stores data on the node where the volume is created. If a pod using that volume moves to another node, the data does not automatically move with it.

No Longhorn, NFS, object storage, dedicated backup system or replicated storage layer is currently implemented.

### Qualified storage inventory

The [Infrastructure Inventory](../reference/infrastructure-inventory.md) is
authoritative for current hardware state; the following table retains the
storage-specific implementation context.

| Node | Disk | Capacity | Connection | Filesystem | Mount | Status |
|------|------|----------|------------|------------|-------|--------|
| pi4mB01 | Hitachi HTS545016B9SA02, serial `091028PBDB00QCJNRTDP` | 160 GB / 149 GiB | ASMedia ASM1051 USB 3 bridge | ext4, label `pi-cl-storage` | `/srv/longhorn` | Qualified |
| pi4mB02 | WD1600BEVT | 160 GB | Not connected | Not prepared | Not mounted | Pending |
| pi4mB03 | None | — | — | — | — | Pending hardware |
| pi4mB04 | None | — | — | — | — | Pending hardware |

The pi4mB01 filesystem is persisted in `/etc/fstab` by label:

```text
LABEL=pi-cl-storage /srv/longhorn ext4 defaults,nofail 0 2
```

The Ansible `storage` role verifies the label, filesystem type, disk model and serial before mounting. It deliberately contains no partitioning or formatting operations.

### Qualification results

SMART reported `PASSED` with zero reallocated sectors, pending sectors, offline-uncorrectable sectors and UDMA CRC errors. The disk had 4,899 power-on hours and measured 29°C during initial qualification.

The file-based baseline measured:

| Workload | Result |
|----------|--------|
| Sequential read | 43.6 MB/s |
| Sequential write | 31.1 MB/s |
| 4 KiB random read | 62 IOPS / 257 kB/s |
| 4 KiB random write | 155 IOPS / 634 kB/s |

The mount survived a node reboot and temporary-file write validation. Detailed
results are stored in the [WO-0009 validation evidence](https://github.com/abujab/homelab/blob/main/artifacts/WO-0009/validation.md).

### Supplemental power validation

The NexStar CX enclosure uses a Y-cable with separate data/power and supplemental-power connectors. After connecting both USB legs, the same 30-second file-based workloads were repeated with identical fio parameters.

| Workload | Single connector | Both Y-cable connectors | Change |
|----------|-----------------:|-------------------------:|-------:|
| Sequential read | 43.6 MB/s | 61.2 MB/s | +40% |
| Sequential write | 31.1 MB/s | 59.7 MB/s | +92% |
| 4 KiB random read | 62 IOPS | 100 IOPS | +61% |
| 4 KiB random write | 155 IOPS | 218 IOPS | +41% |

Repeat sequential tests produced 61.7 MB/s read and 60.6 MB/s write. Two additional `hdparm` buffered-read tests produced 58.44 MB/s and 58.45 MB/s, confirming the improvement was reproducible.

The data path did not change: the bridge remained at USB SuperSpeed 5 Gbit/s through the `usb-storage` driver without UASP. No USB reset, disconnect, undervoltage, filesystem or block-I/O error was logged, and SMART critical counters remained zero. The improvement is therefore recorded as a benefit of providing the enclosure with its intended supplemental power, not as an increase in negotiated USB bandwidth.

## Design Decisions

### Use K3s default local storage for the foundation

Local Path Provisioner is acceptable for the current foundation because the cluster is not yet hosting critical stateful services.

### Defer persistent storage architecture

Persistent storage has broader implications for hardware, replication, backups and restore testing. It should be evaluated deliberately before important stateful services are deployed.

### Treat microSD storage as limited

microSD cards are convenient for Raspberry Pi boot disks, but they are not a strong long-term storage foundation for high-write or critical workloads.

### Identify USB disks independently of device enumeration

Persistent mounts use filesystem labels rather than `/dev/sdX` paths. Automation also validates immutable disk identity fields before accepting the mount.

### Keep hardware qualification independent of Kubernetes

The prepared path is not yet a Longhorn deployment. Kubernetes storage configuration remains unchanged until a later work order.

## Best Practices

- avoid placing critical data only on local-path volumes
- assume microSD storage can fail
- document any stateful workload before deployment
- define backup and restore expectations before storing important data
- test restore procedures, not only backup creation
- keep storage decisions tied to workload requirements
- review SMART attributes and kernel logs before accepting a disk
- run benchmarks against a disposable file on the mounted filesystem, not against the raw block device
- keep both Y-cable connectors attached so the enclosure receives its intended supplemental power

Known limitations:

- the ASMedia ASM1051 bridge negotiated USB SuperSpeed at 5 Gbit/s but uses the `usb-storage` driver rather than UASP
- the enclosure depends on both Y-cable connectors for the qualified power and performance baseline
- the qualified disk is an older 5400 RPM SATA device and is suitable for foundation testing, not high-performance workloads
- only one node currently has qualified data storage, so no replicated storage capability exists

## Future Improvements

Future storage work should evaluate:

- Longhorn for replicated Kubernetes block storage
- external SSDs or dedicated storage nodes
- backup targets
- restore procedures
- retention requirements
- monitoring for disk health and capacity
- storage classes for different workload types

Before important stateful applications are deployed, HomeLab should have a documented backup and restore model.

## Related Documents

- [Kubernetes](kubernetes.md)
- [Raspberry Pi Cluster](raspberry-pi-cluster.md)
- [Roadmap](../overview/roadmap.md)
- [Infrastructure Inventory](../reference/infrastructure-inventory.md)
- [Service Catalog](../reference/service-catalog.md)
- [ADR-0004 Persistent Storage](../decisions/ADR-0004-storage.md)
- [Backup](../operations/backup.md)
- [WO-0009 Storage Hardware Foundation](https://github.com/abujab/homelab/blob/main/work-orders/WO-0009-storage-hardware-foundation.md)
- [WO-0009 Validation Evidence](https://github.com/abujab/homelab/blob/main/artifacts/WO-0009/validation.md)
