# WO-0009 – Storage Hardware Foundation

**Work Order ID:** WO-0009
**Sprint:** Storage Foundation
**Status:** Complete
**Owner:** Codex
**Reviewer:** Abdul / ChatGPT

---

# Objective

Prepare and validate storage hardware that will later be used by Longhorn.

This work order is intentionally **independent of Kubernetes**.

No Longhorn installation.
No StorageClass changes.
No PVC migration.

The objective is to prove that the hardware is healthy, stable, and correctly mounted before it becomes part of the cluster.

---

# Background

Current hardware:

Node | Storage
---- | -------
pi4mB01 | Hitachi HTS545016B9SA02 (160 GB) via NexStar CX USB3 enclosure
pi4mB02 | WD1600BEVT (160 GB) (not yet connected)
pi4mB03 | No storage
pi4mB04 | No storage

Long-term architecture:

```
Application
      │
PVC
      │
Longhorn
      │
USB Storage
```

This work order only prepares the bottom layer.

---

# Goals

- Detect attached storage
- Verify USB stability
- Verify SMART health
- Benchmark storage
- Create filesystem
- Label filesystem
- Configure persistent mount
- Validate persistence across reboot
- Produce evidence for review

---

# Safety Requirements

This work order MUST be safe to execute multiple times.

It MUST be idempotent.

Examples:

Already formatted
→ Skip formatting

Already mounted
→ Verify

Already labelled
→ Verify

Already in fstab
→ Verify

---

# Destructive Operations

The following operations require explicit user approval.

DO NOT perform automatically.

- wipefs
- fdisk
- parted
- mkfs.ext4
- deleting partitions
- changing partition table

Codex MUST stop and present:

Example:

Detected storage

Device:
    /dev/sda

Model:
    Hitachi HTS545016B9SA02

Capacity:
    160 GB

Filesystem:
    None

The next step will ERASE ALL DATA on this device.

Awaiting confirmation.

No formatting shall occur until confirmed.

---

# Deliverables

## Phase 1 – Hardware Discovery

Collect:

```
lsblk
lsblk -f
blkid
fdisk -l
lsusb
```

Record:

- device path
- model
- serial
- transport
- capacity
- partitions
- filesystem
- UUID

---

## Phase 2 – USB Verification

Determine:

- USB2 or USB3
- enclosure chipset (if available)
- UASP enabled
- negotiated speed

Collect:

```
dmesg
lsusb -t
```

Record any USB warnings.

---

## Phase 3 – SMART Health

Install if necessary:

```
smartmontools
```

Collect:

```
smartctl -H
smartctl -A
smartctl -x
```

Review:

- overall health
- reallocated sectors
- pending sectors
- offline uncorrectable
- power on hours
- temperature

Produce summary.

Do not continue if SMART indicates imminent failure.

---

## Phase 4 – Performance Baseline

Install if required:

```
fio
hdparm
```

Collect:

Sequential read

Sequential write

Random read

Random write

Record results.

This is informational only.

---

## Phase 5 – Filesystem Preparation

AFTER explicit confirmation only.

Create:

Filesystem:

```
ext4
```

Filesystem label:

```
pi-cl-storage
```

Verify:

```
blkid
lsblk -f
```

---

## Phase 6 – Mount Point

Create:

```
/srv/longhorn
```

Configure:

```
/etc/fstab
```

using LABEL

Never use:

```
/dev/sda
```

Use:

```
LABEL=pi-cl-storage
```

Mount.

Verify.

---

## Phase 7 – Reboot Validation

Reboot node.

After reboot verify:

```
mount
lsblk -f
df -h
```

Verify:

```
touch /srv/longhorn/testfile
```

Delete test file.

---

## Phase 8 – Stability Test

Run approximately one hour of continuous IO.

Monitor:

```
dmesg -w
```

Watch for:

- USB disconnect
- filesystem errors
- kernel errors
- resets
- IO errors

Collect final logs.

---

## Phase 9 – Documentation

Update repository:

```
docs/infrastructure/storage/
```

Include:

Storage inventory

Filesystem

Mount procedure

SMART summary

Benchmark summary

Known limitations

---

# Evidence

Produce:

```
artifacts/
└── WO-0009/
    ├── lsblk.txt
    ├── blkid.txt
    ├── fdisk.txt
    ├── lsusb.txt
    ├── lsusb-tree.txt
    ├── smart.txt
    ├── fio.txt
    ├── hdparm.txt
    ├── mount.txt
    ├── df.txt
    ├── dmesg-before.txt
    ├── dmesg-after.txt
    └── validation.md
```

---

# Validation Checklist

Hardware detected

Filesystem label correct

Persistent mount successful

SMART healthy

No USB errors

No filesystem errors

Survived reboot

Survived stress test

Evidence collected

Documentation updated

---

# Acceptance Criteria

PASS when:

✓ Storage detected correctly

✓ SMART healthy

✓ ext4 filesystem created

✓ Filesystem labelled:

```
pi-cl-storage
```

✓ Mounted at:

```
/srv/longhorn
```

✓ Mounted by LABEL

✓ Reboot successful

✓ One-hour stress test completed

✓ No kernel storage errors

✓ Documentation updated

✓ Evidence committed

---

# Explicit Non-Goals

This work order shall NOT:

- install Longhorn
- modify Kubernetes StorageClasses
- migrate PVCs
- modify applications
- deploy CSI drivers
- configure replica policies

Those belong to WO-0010.

---

# Completion Output

Codex shall conclude with:

Hardware Summary

Detected Device

Filesystem

Health Status

Benchmark Summary

Mount Status

Validation Result

Outstanding Issues (if any)

Recommendation:

READY FOR WO-0010 – Longhorn Storage Foundation
