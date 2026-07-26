# Storage Onboarding

---

## Purpose

Provide the repeatable procedure for discovering, declaring, initializing,
qualifying and operating dedicated node storage.

## Scope

This runbook covers disks managed by the Ansible `storage` role. It does not
install Longhorn, configure Kubernetes storage resources or authorize erasing
an undeclared disk.

## Background

Kernel names such as `/dev/sda` are temporary. HomeLab identifies a whole disk
through a persistent `/dev/disk/by-id/` path when available, validates model,
serial, WWN and exact capacity, and mounts the prepared filesystem by UUID.

Discovery and normal reconciliation are non-destructive. Initialization is a
separate operation requiring an exact runtime token that must never be stored
in Git.

Normal reconciliation validates disk identity through persistent path, model,
serial, WWN and exact size without requiring SMART passthrough. SMART access is
mandatory during the separate qualification operation.

## Architecture / Implementation

### Lifecycle

```text
Connect
  -> discover read-only
  -> declare exact identity in host_vars
  -> authorize one destructive onboarding target
  -> qualify hardware and filesystem
  -> add the host to storage_nodes
  -> reconcile non-destructively
```

Run Ansible commands from `ansible/`.

### Discover attached disks

Use the repository discovery playbook first:

```bash
ansible-playbook playbooks/storage-discover.yml --limit pi4mB02
```

It reports physical disks, partitions, filesystems, mounts, root and boot
relationships, swap use, udev identity, and persistent paths without changing
the node.

For focused manual verification, list physical disks:

```bash
lsblk -d -b -o NAME,PATH,SIZE,MODEL,SERIAL,WWN,TRAN
```

- `NAME` is the temporary kernel name.
- `PATH` is its current device path.
- `SIZE` is exact capacity in bytes.
- `MODEL` and `SERIAL` identify the disk or what the bridge exposes.
- `WWN` is the disk worldwide identifier when available.
- `TRAN` identifies USB, SATA, NVMe or another transport.

Inspect partitions and filesystems:

```bash
lsblk -o NAME,PATH,TYPE,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL,WWN
```

Compare capacity, model, existing partitions, filesystem and mount state with
the disk that was physically connected.

### Find a persistent whole-disk path

For the candidate disk only:

```bash
find -L /dev/disk/by-id -samefile /dev/sda
```

`/dev/sda` is an example, never a persistent identity. Entries ending in
`-part1`, `-part2` or another `-partN` suffix represent partitions. Inventory
must identify the whole disk.

Prefer paths in this order:

1. WWN-based `/dev/disk/by-id/` path.
2. Unique disk-serial `/dev/disk/by-id/` path.
3. Another unique whole-disk `/dev/disk/by-id/` path.
4. Stable `/dev/disk/by-path/` path only when the bridge exposes no unique disk
   identity.

Inspect udev properties:

```bash
udevadm info --query=property --name=/dev/sda
```

Review `ID_VENDOR`, `ID_MODEL`, `ID_SERIAL`, `ID_SERIAL_SHORT`, `ID_WWN`,
`ID_PATH` and `ID_BUS`.

Inspect identity directly through SMART:

```bash
sudo smartctl -i /dev/sda
```

For a USB-to-SATA bridge:

```bash
sudo smartctl -d sat -i /dev/sda
```

Some bridges hide the disk serial, expose an enclosure serial, reuse a generic
serial, block SMART passthrough or require another `smartctl -d` type. A generic
enclosure identifier is insufficient by itself. Confirm uniqueness using the
persistent path, disk model, disk serial, WWN, exact capacity and physical
enclosure together.

### Protect the operating-system disk

Identify root and boot sources:

```bash
findmnt -no SOURCE /
lsblk -s "$(findmnt -no SOURCE /)"
findmnt /boot
findmnt /boot/firmware
swapon --show
```

Never declare the root, boot or microSD parent disk as an onboarding target.
Also reject a candidate with unexpected mounted children or active swap.

### Declare inventory

Use the canonical storage naming convention from
[Naming and Addressing](../reference/naming-and-addressing.md):

```yaml
storage_disks:
  - id: data-disk-01
    sequence: 1
    identity:
      persistent_path: /dev/disk/by-id/wwn-0x50014ee2ac2a2b36
      expected_model: WDC WD3200BEVT-22ZCT0
      expected_serial: WD-WXE508N88014
      expected_wwn: "0x50014ee2ac2a2b36"
      expected_size_bytes: 320072933376
    filesystem:
      type: ext4
      label: pi4mB02-data01
    mount:
      path: /srv/longhorn
      options: defaults,nofail
    partition:
      number: 1
    smart_device_type: sat
    state: present
```

Every disk ID and mount path must be unique per host. Filesystem labels must be
unique across the managed environment.

The storage role does not manage kernel USB quirks or reboot nodes. The former
`0bda:9201` workaround is absent from both boot configuration and the active
kernel command line and is not required by the qualified enclosures. Treat any
future bridge requiring a kernel quirk as a separate compatibility decision;
do not add it to normal storage reconciliation implicitly.

For another disk on the same host, append a second complete list item rather
than replacing the first. Use `sequence: 2`, `id: data-disk-02`, label
`pi4mB02-data02`, a distinct mount such as `/srv/data02`, and that disk's own
persistent identity fields. Then select only `data-disk-02` with
`storage_target_disk_id` during onboarding and qualification. No role change is
required.

### Initialize an authorized disk

The token format is:

```text
<inventory-hostname>:<disk-id>:ERASE
```

For the example above:

```bash
ansible-playbook playbooks/storage-onboard.yml \
  --limit pi4mB02 \
  --extra-vars \
  "storage_target_disk_id=data-disk-01 storage_destroy_confirmation=pi4mB02:data-disk-01:ERASE"
```

`storage_target_disk_id` restricts the operation to exactly one inventory entry,
including on hosts that already have other declared disks. The playbook
displays and revalidates the persistent path, current kernel path,
model, serial, WWN, capacity, old signatures and target state before erasing.
It then creates GPT, one ext4 partition, the declared label, a UUID-based fstab
entry and the declared mount. A correctly prepared disk is never reformatted,
even when a valid token is supplied again.

Never place `storage_destroy_confirmation` in inventory, a playbook, shell
profile, committed command file or CI variable.

### Qualify storage

Run qualification only after onboarding succeeds:

```bash
ansible-playbook playbooks/storage-qualify.yml \
  --limit pi4mB02 \
  --extra-vars "storage_target_disk_id=data-disk-01"
```

Qualification records USB topology, negotiated speed and driver; SMART health;
30-second sequential and random file workloads; approximately one hour of
mixed file I/O; post-test SMART state; and new critical kernel storage events.
All fio files are removed through an `always` cleanup path whether a workload
succeeds or fails.

Do not qualify a disk with reallocated, pending or offline-uncorrectable sectors,
a failing self-test, USB resets, disconnects, block-I/O errors, filesystem
errors or an unexplained read-only remount.

### Validate reboot persistence

Reboot one node according to the normal controlled process. After it returns:

```bash
findmnt /srv/longhorn
lsblk -f
df -hT /srv/longhorn
grep /srv/longhorn /etc/fstab
touch /srv/longhorn/.storage-reboot-write-test
rm /srv/longhorn/.storage-reboot-write-test
```

The same filesystem UUID must mount automatically. Confirm that `/etc/fstab`
contains one UUID entry for the target.

### Promote and reconcile

Only after qualification and reboot validation pass, add the node to
`storage_nodes` in `inventories/home/hosts.yml`. Then run:

```bash
ansible-playbook playbooks/storage.yml
```

Run it a second time. The final result must report `changed=0` and `failed=0`
for every storage node.

### Troubleshooting

- Missing persistent path: rerun discovery and verify enclosure, port and WWN.
- Identity mismatch: stop; do not update inventory until the physical disk is
  independently identified.
- SMART unavailable: test the documented `-d sat` mode and inspect bridge
  support; never invent health results.
- USB resets or disconnects: stop I/O and inspect enclosure power, cable,
  bridge firmware, negotiated speed and kernel logs.
- UDMA CRC increase: treat it as a cable, bridge, power or SATA-link signal;
  establish the previous SMART value and requalify after correcting the path.
- Unexpected filesystem or label: normal reconciliation must fail rather than
  format it; use onboarding only with explicit erase authorization.
- Missing mount after reboot: inspect the UUID, fstab, kernel log and hardware
  connection before allowing a storage consumer to use the directory.

## Design Decisions

Destructive onboarding is isolated from normal reconciliation. Persistent disk
identity is hardware-based, while persistent mounting is filesystem-UUID-based.
Labels remain human-readable and independent of Longhorn or another future
storage implementation.

## Best Practices

- discover before declaring inventory
- use exact verified values rather than examples
- qualify each disk and enclosure combination independently
- preserve read-only diagnostics and concise evidence
- keep destructive authorization ephemeral
- rerun normal reconciliation to prove idempotency
- verify that `/srv/longhorn` is a mount before any future Longhorn consumer is
  allowed to use it

## Future Improvements

- automate evidence export without storing full unrelated journals
- add CI validation for globally unique filesystem labels
- integrate mounted-path protection with the future Longhorn work order

## Related Documents

- [Storage](../infrastructure/storage.md)
- [Ansible](../infrastructure/ansible.md)
- [Infrastructure Inventory](../reference/infrastructure-inventory.md)
- [Naming and Addressing](../reference/naming-and-addressing.md)
- [Troubleshooting](troubleshooting.md)
