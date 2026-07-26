# WO-0010 — Reusable Storage Onboarding and Second Storage Node Qualification

**Work Order ID:** WO-0010
**Sprint:** Reusable Storage Lifecycle
**Status:** Complete
**Owner:** Codex
**Reviewer:** Abdul / ChatGPT
**Approved:** 2026-07-23
**Completed:** 2026-07-26

---

# Objective

Extend the existing Ansible storage implementation into a reusable, inventory-driven storage lifecycle.

The completed implementation must support:

- read-only disk discovery
- persistent hardware identity validation
- explicitly authorized disk initialization
- partitioning and filesystem creation
- persistent mounting
- hardware qualification
- verification and idempotency
- onboarding future disks through inventory changes and documented commands

The existing qualified storage on `pi4mB01` must be preserved without reformatting or data loss.

The newly connected disk on `pi4mB02` must be used as the first complete onboarding and qualification case.

After this work order, adding a new storage disk must not require another implementation work order or modification of the storage role.

The normal future process must be:

1. Connect the disk.
2. Run read-only discovery.
3. identify its persistent hardware identity.
4. Add the disk to host inventory.
5. Run the explicitly authorized onboarding playbook.
6. Run the qualification playbook.
7. Add the node to `storage_nodes` after qualification passes.
8. Run the normal non-destructive storage playbook.

---

# Background

WO-0009 created the existing storage foundation and qualified one USB-attached disk on `pi4mB01`.

The repository already contains:

```text
ansible/
├── inventories/home/
├── playbooks/storage.yml
└── roles/storage/
```

The current storage role:

- validates an expected disk model and serial number
- finds a pre-existing filesystem by label
- verifies that the filesystem is ext4
- verifies the parent disk identity
- creates `/srv/longhorn`
- mounts the filesystem persistently by label
- verifies the resulting mount

The current role deliberately performs no destructive operations.

It assumes that a correctly formatted and labelled filesystem already exists.

A second disk and enclosure are now connected to:

```text
pi4mB02
```

The existing data on this newly attached disk is not required and may be erased.

This authorization applies only to the explicitly identified non-operating-system disk attached to `pi4mB02`.

No other disk is authorized for destructive modification.

---

# Architectural Intent

This work order must evolve the existing implementation from:

```text
Validate and mount one pre-prepared disk
```

to:

```text
Discover
  ↓
Declare in inventory
  ↓
Explicitly authorize initialization
  ↓
Partition and format
  ↓
Mount
  ↓
Qualify
  ↓
Operate non-destructively
```

The storage lifecycle must remain independent of Kubernetes and Longhorn.

Longhorn installation and configuration belong to a later work order:

```text
WO-0011 — Longhorn Storage Foundation
```

---

# Scope

Codex must:

- inspect the existing storage role before making changes
- extend the existing role rather than create a parallel role
- preserve the existing `pi4mB01` storage
- introduce a reusable multi-disk inventory model
- provide read-only discovery automation
- provide a separate destructive onboarding entry point
- keep normal storage reconciliation non-destructive
- protect operating-system and mounted disks
- prepare the newly attached disk on `pi4mB02`
- qualify the `pi4mB02` disk and USB connection
- migrate persistent mounts to UUID-based entries where safe
- document the complete future disk-onboarding procedure
- update project state, inventory and infrastructure documentation
- produce reviewable validation evidence
- open a pull request

---

# Non-Goals

This work order must not:

- install Longhorn
- install another CSI driver
- configure Kubernetes StorageClasses
- create PersistentVolumes
- create PersistentVolumeClaims
- migrate existing Kubernetes workloads
- modify application manifests
- configure Longhorn replicas
- configure RAID
- configure LVM
- configure disk encryption
- build a backup platform
- automatically select and erase unused disks
- wipe any disk that is not explicitly declared
- depend on `/dev/sda`, `/dev/sdb` or similar names as persistent identity
- modify the Raspberry Pi operating-system disk
- reformat the existing `pi4mB01` filesystem

---

# Existing Storage Compatibility Requirement

The existing storage implementation on `pi4mB01` is production state for this project and must be treated as a regression case.

Current known state:

```text
Node:              pi4mB01
Disk model:        HTS545016B9SA02
Disk serial:       091028PBDB00QCJNRTDP
Filesystem:        ext4
Filesystem label:  pi-cl-storage
Mount point:       /srv/longhorn
```

The work order must preserve:

- the existing partition table
- the existing filesystem
- the existing filesystem UUID
- the existing filesystem label unless a separately justified non-destructive change is required
- all existing data
- the `/srv/longhorn` mount
- reboot persistence

The refactored storage role must be run against `pi4mB01` as a regression test.

No partitioning, formatting or filesystem recreation may occur on `pi4mB01`.

---

# Required Design

## 1. Extend the existing role

Codex must refactor and extend:

```text
ansible/roles/storage/
```

Do not create a second role such as:

```text
storage_new
storage_v2
longhorn_disk
disk_setup
```

Reusable storage lifecycle logic must remain owned by the existing `storage` role.

The role may be split into task files, for example:

```text
ansible/roles/storage/
├── defaults/main.yml
├── tasks/
│   ├── main.yml
│   ├── validate-config.yml
│   ├── resolve-device.yml
│   ├── protect-system-disk.yml
│   ├── inspect.yml
│   ├── initialize.yml
│   ├── mount.yml
│   └── verify.yml
└── handlers/main.yml
```

The exact structure may be adapted to repository conventions.

---

## 2. Separate operational modes

The implementation must provide separate playbook entry points.

At minimum:

```text
ansible/playbooks/storage-discover.yml
ansible/playbooks/storage-onboard.yml
ansible/playbooks/storage.yml
ansible/playbooks/storage-qualify.yml
```

### `storage-discover.yml`

Purpose:

- read-only discovery of attached block devices
- no partition changes
- no formatting
- no mounting changes
- no filesystem writes
- safe to run on any node

### `storage-onboard.yml`

Purpose:

- initialize only explicitly declared disks
- perform destructive operations only after exact runtime confirmation
- partition and format new disks
- establish persistent mounts
- verify the final state

### `storage.yml`

Purpose:

- normal non-destructive reconciliation
- validate configured disk identity
- validate existing partition and filesystem
- create mount-point directories
- maintain UUID-based `/etc/fstab` entries
- mount configured filesystems
- verify active mounts

This playbook must never:

- wipe signatures
- create partition tables
- create partitions
- run `mkfs`
- delete filesystems

### `storage-qualify.yml`

Purpose:

- verify disk and enclosure suitability
- perform SMART inspection
- inspect USB transport
- run safe file-based performance tests
- inspect kernel logs
- verify reboot persistence
- produce qualification evidence

---

# Inventory Data Model

Replace the current single-disk scalar configuration with a list-based model.

Use a schema similar to:

```yaml
storage_disks:
  - id: longhorn-data-01

    identity:
      by_id: /dev/disk/by-id/usb-EXAMPLE_UNIQUE_IDENTIFIER
      expected_model: EXAMPLE_MODEL
      expected_serial: EXAMPLE_SERIAL
      expected_wwn: ""
      expected_size_bytes: 160041885696

    filesystem:
      type: ext4
      label: pi-cl-storage

    mount:
      path: /srv/longhorn
      options: defaults,nofail

    partition:
      number: 1

    state: present
```

The exact nesting may be adjusted, but it must provide equivalent information.

Requirements:

- `storage_disks` must support more than one disk per host.
- Every disk must have a unique `id`.
- Every mount path on a host must be unique.
- Every filesystem label in the managed environment must be unique.
- No active inventory entry may contain placeholder values.
- The persistent identifier must refer to the whole disk, not a partition.
- `/dev/sdX` must not be stored as the persistent identity.
- Model, serial and capacity must be used as secondary validation.
- WWN must be supported when available.
- Expected capacity must be recorded in bytes from `lsblk -b`.

The role must validate the inventory structure before changing anything.

---

# Persistent Disk Identity

## Preferred identity order

Use the following identity preference:

1. WWN-based `/dev/disk/by-id/` entry
2. unique serial-based `/dev/disk/by-id/` entry
3. another unique whole-disk `/dev/disk/by-id/` entry
4. stable physical path only when the USB bridge exposes no unique identity

The selected path must resolve to exactly one whole block device.

The role must reject:

- missing identifiers
- broken symbolic links
- identifiers resolving to partitions
- identifiers resolving to more than one candidate
- identifiers resolving to the root or boot disk
- model mismatches
- serial mismatches
- WWN mismatches
- unexpected capacity
- ambiguous generic USB enclosure serials

The role must resolve the persistent identifier at runtime and may display the current kernel device name for diagnostics.

It must never treat the current `/dev/sdX` assignment as authoritative identity.

---

# Read-Only Disk Discovery

Create a reusable discovery process for new disks.

The discovery output must include:

- hostname
- kernel device name
- full device path
- block-device type
- disk size in bytes
- human-readable disk size
- model
- serial
- WWN
- transport type
- USB vendor and product where available
- `/dev/disk/by-id/` entries
- `/dev/disk/by-path/` entries where relevant
- partition layout
- filesystem types
- filesystem labels
- filesystem UUIDs
- current mount points
- swap usage
- root-disk relationship
- boot-disk relationship
- whether the candidate appears safe for onboarding

Useful source commands include:

```bash
lsblk -b -o NAME,PATH,TYPE,SIZE,MODEL,SERIAL,WWN,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
```

```bash
find -L /dev/disk/by-id -samefile /dev/sdX
```

```bash
find -L /dev/disk/by-path -samefile /dev/sdX
```

```bash
udevadm info --query=property --name=/dev/sdX
```

```bash
findmnt -no SOURCE /
```

```bash
findmnt /boot
```

```bash
findmnt /boot/firmware
```

```bash
swapon --show
```

`/dev/sdX` is an example only. The discovery implementation must determine actual devices dynamically.

The final documented command must work from the repository’s established Ansible working directory.

Expected usage should resemble:

```bash
ansible-playbook playbooks/storage-discover.yml --limit pi4mB02
```

---

# Documentation: Finding a New Disk Serial Number

Create or update an operations document that explains how to identify a newly connected disk.

The documentation must include the following process.

## Step 1 — List all physical disks

```bash
lsblk -d -b -o NAME,PATH,SIZE,MODEL,SERIAL,WWN,TRAN
```

Explain:

- `NAME` is the temporary kernel name
- `PATH` is the current device path
- `SIZE` is the exact size in bytes
- `MODEL` is the model reported by the disk or enclosure
- `SERIAL` is the serial reported through the connection
- `WWN` is the worldwide identifier when available
- `TRAN` shows transport such as USB, SATA or NVMe

## Step 2 — Inspect partitions and filesystems

```bash
lsblk -o NAME,PATH,TYPE,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL,WWN
```

Explain how to compare:

- size
- model
- existing partitions
- existing filesystem
- mount status

with the physical disk that was connected.

## Step 3 — Find persistent by-id entries

For a candidate disk:

```bash
find -L /dev/disk/by-id -samefile /dev/sda
```

Explain that:

- `/dev/sda` is only an example
- entries ending in `-part1`, `-part2` and similar represent partitions
- the whole-disk entry must be used for disk initialization
- the selected identifier must be unique

## Step 4 — Inspect udev identity properties

```bash
udevadm info --query=property --name=/dev/sda
```

Document relevant properties:

```text
ID_VENDOR=
ID_MODEL=
ID_SERIAL=
ID_SERIAL_SHORT=
ID_WWN=
ID_PATH=
ID_BUS=
```

## Step 5 — Inspect SMART identity

```bash
sudo smartctl -i /dev/sda
```

For USB SATA bridges, also document:

```bash
sudo smartctl -d sat -i /dev/sda
```

Explain that some USB bridges:

- hide the disk serial
- expose the enclosure serial instead
- expose generic serial numbers
- expose the same serial for multiple enclosures
- do not pass SMART data
- require a specific `smartctl -d` device type

## Step 6 — Verify the operating-system disk

```bash
findmnt -no SOURCE /
```

```bash
lsblk -s "$(findmnt -no SOURCE /)"
```

Also inspect:

```bash
findmnt /boot
```

```bash
findmnt /boot/firmware
```

The documentation must clearly state:

> Never declare the root, boot or microSD parent disk as an onboarding target.

## Step 7 — Confirm uniqueness

The operator must compare:

- by-id path
- model
- serial
- WWN
- capacity
- physical enclosure

before adding the disk to inventory.

The documentation must explain that a generic enclosure identifier is insufficient by itself.

---

# Operating-System Disk Protection

Before destructive or mount operations, the role must determine:

- source device for `/`
- parent disk containing `/`
- source device for `/boot`, when present
- source device for `/boot/firmware`, when present
- parent disks for boot filesystems
- active swap devices
- mounted child partitions
- existing filesystems on the candidate disk

The role must refuse to initialize a disk when:

- it is the root filesystem
- it is a parent of the root filesystem
- it contains the boot filesystem
- it contains `/boot/firmware`
- it is used for active swap
- any child partition is mounted outside the declared target mount
- it is already used by an unknown active service
- inventory identity validation fails
- the device is read-only
- the device is not a whole disk
- more than one inventory disk resolves to the same physical device

Protection must work even when kernel device names change.

---

# Explicit Destructive Authorization

The permission to destroy data must not be stored permanently in inventory.

The onboarding playbook must require a runtime confirmation value.

Use an exact convention such as:

```text
<inventory_hostname>:<storage_disk_id>:ERASE
```

For the current disk, expected invocation should resemble:

```bash
ansible-playbook playbooks/storage-onboard.yml \
  --limit pi4mB02 \
  --extra-vars \
  "storage_destroy_confirmation=pi4mB02:longhorn-data-01:ERASE"
```

The exact disk ID must match the final inventory.

Before destructive tasks, the playbook must display:

- inventory hostname
- disk ID
- persistent by-id path
- resolved current device path
- model
- serial
- WWN when available
- exact capacity
- existing partition table
- existing partitions
- existing filesystem signatures
- existing mount points
- target filesystem
- target label
- target mount path

The destructive confirmation must match exactly.

The role must fail closed when:

- the variable is absent
- the value does not match exactly
- the playbook is run for multiple hosts with one ambiguous confirmation
- the disk identity differs from inventory
- the disk is already safely prepared and no destructive action is required

The explicit authorization in this work order permits Codex to erase only the verified non-OS disk attached to `pi4mB02`.

---

# Disk Initialization

For the authorized new disk on `pi4mB02`, the onboarding implementation must:

1. resolve the persistent whole-disk identifier
2. validate exact identity
3. protect the operating-system disk
4. inspect existing partition and filesystem state
5. unmount only the authorized target if required
6. remove existing filesystem signatures
7. remove obsolete partition-table metadata
8. create a GPT partition table
9. create one partition using the available disk capacity
10. wait for the kernel to detect the new partition
11. create an ext4 filesystem
12. assign the configured filesystem label
13. retrieve the new filesystem UUID
14. create the mount path
15. configure persistent mounting by UUID
16. mount the filesystem
17. verify the active mount
18. verify that the filesystem is writable
19. remove the temporary verification file
20. run the normal non-destructive reconciliation path

Prefer Ansible modules where suitable.

If an additional Ansible collection is required:

- add it to the repository’s dependency declarations
- pin an appropriate version
- document installation
- ensure CI or local validation can reproduce it

Commands used for destructive work must have correct:

- guards
- failure handling
- changed-state handling
- idempotency behavior

---

# Filesystem and Mount Standard

## Filesystem

Use:

```text
ext4
```

## Mount point

Use the established project standard:

```text
/srv/longhorn
```

Because each node has its own local filesystem namespace, both `pi4mB01` and `pi4mB02` may use:

```text
/srv/longhorn
```

Future multiple disks on the same node must use separate unique mount paths.

## Filesystem label

The `pi4mB02` filesystem label must be unique.

Do not reuse:

```text
pi-cl-storage
```

Use a clear host- or disk-specific label, for example:

```text
pi4mb02-longhorn
```

The final value must be documented and stored in inventory.

## Persistent mount source

Use the filesystem UUID in `/etc/fstab`.

Example:

```text
UUID=<filesystem-uuid> /srv/longhorn ext4 defaults,nofail 0 2
```

Do not persist:

```text
/dev/sda1
```

or another kernel enumeration path.

The filesystem label must remain available for human identification, but the persistent mount should use UUID.

---

# Migration of pi4mB01 Mount

The current `pi4mB01` mount uses a filesystem label.

Codex must evaluate and, if safe, migrate the persistent mount to UUID.

Requirements:

- obtain the existing UUID
- verify it belongs to the expected disk and partition
- preserve the existing filesystem
- preserve the UUID
- preserve all existing data
- remove any obsolete duplicate fstab entry
- create one authoritative UUID-based entry
- verify the mount
- verify reboot persistence
- verify a second role run reports no change

No formatting or relabelling is permitted as part of this migration.

If Codex determines that migration cannot be completed safely, it must:

- leave the existing label-based mount working
- document the reason
- ensure the role supports both the existing state and UUID-based new disks
- record the limitation in the pull request

---

# Mount Safety and `nofail`

The existing configuration uses:

```text
defaults,nofail
```

This allows the Raspberry Pi to boot when a USB disk is unavailable.

Preserve this behavior unless a different decision is explicitly justified.

Document the following future Longhorn risk:

> If the external filesystem is not mounted, `/srv/longhorn` may still exist as a normal directory on the operating-system filesystem. Longhorn must not be allowed to use that fallback directory.

WO-0011 must include protection ensuring Longhorn uses only confirmed mounted storage.

This work order must record that requirement in project state or storage documentation.

---

# Multiple-Disk Support

The role must loop over `storage_disks`.

It must support future configurations similar to:

```yaml
storage_disks:
  - id: longhorn-data-01
    identity:
      by_id: /dev/disk/by-id/usb-EXAMPLE_DISK_ONE
      expected_model: EXAMPLE_MODEL_ONE
      expected_serial: EXAMPLE_SERIAL_ONE
      expected_wwn: ""
      expected_size_bytes: 1000204886016
    filesystem:
      type: ext4
      label: node02-longhorn-01
    mount:
      path: /srv/longhorn
      options: defaults,nofail
    partition:
      number: 1
    state: present

  - id: longhorn-data-02
    identity:
      by_id: /dev/disk/by-id/usb-EXAMPLE_DISK_TWO
      expected_model: EXAMPLE_MODEL_TWO
      expected_serial: EXAMPLE_SERIAL_TWO
      expected_wwn: ""
      expected_size_bytes: 1000204886016
    filesystem:
      type: ext4
      label: node02-longhorn-02
    mount:
      path: /srv/longhorn-02
      options: defaults,nofail
    partition:
      number: 1
    state: present
```

Adding the second disk must require only:

- physical connection
- discovery
- inventory declaration
- onboarding command
- qualification command

No role source-code change may be required.

---

# Normal Reconciliation Behavior

After a disk is prepared, `storage.yml` must:

- resolve its persistent identifier
- validate model
- validate serial
- validate WWN when configured
- validate capacity
- locate the configured partition
- validate filesystem type
- validate filesystem label
- read filesystem UUID
- create the mount path
- maintain one UUID-based fstab entry
- mount the filesystem
- verify source, type and target
- verify the mount source corresponds to the expected disk
- avoid any destructive operation

A prepared disk with valid state must be validated, not recreated.

If observed state differs from inventory, fail with a clear diagnostic.

Do not automatically “repair” an unexpected filesystem by formatting it.

---

# Idempotency Requirements

After successful initialization:

- a second `storage-onboard.yml` run must not wipe the disk
- a second normal `storage.yml` run must report no changes
- the partition table must not be rewritten
- the filesystem must not be recreated
- the filesystem UUID must remain unchanged
- the filesystem label must remain unchanged
- `/etc/fstab` must contain no duplicate entries
- the mount must remain active
- existing files must remain untouched

The onboarding playbook should detect that the desired state is already satisfied and skip destructive initialization.

The runtime erase token must never cause an already-correct filesystem to be recreated merely because the token is present.

---

# pi4mB02 Current Disk Onboarding

Codex must use the currently attached disk on `pi4mB02` to prove the new workflow.

## Required sequence

1. Run read-only discovery.
2. Identify all block devices.
3. Identify the root and boot parent disk.
4. Identify the newly attached storage disk.
5. Determine:
   - model
   - serial
   - WWN
   - exact capacity
   - USB bridge
   - transport
   - by-id path
   - existing partition table
   - existing partitions
   - existing filesystems
   - current mount state
6. Confirm that it is not the operating-system disk.
7. Add its actual values to `pi4mB02` host variables.
8. Run onboarding using the exact runtime erase confirmation.
9. Verify the resulting filesystem and UUID.
10. Run normal storage reconciliation.
11. Run hardware qualification.
12. Run reboot persistence validation.
13. Run a second normal reconciliation and confirm idempotency.
14. Add `pi4mB02` to `storage_nodes` only after qualification passes.

Do not commit fabricated serials, paths, UUIDs or benchmark results.

---

# Storage Hardware Qualification

The `pi4mB02` disk must be qualified to at least the same standard used for `pi4mB01`.

## USB connection

Record:

- enclosure chipset where visible
- USB vendor and product ID
- negotiated USB speed
- USB 2 versus USB 3
- UASP versus `usb-storage`
- USB topology
- relevant kernel messages
- any resets or disconnects

Useful commands may include:

```bash
lsusb
```

```bash
lsusb -t
```

```bash
dmesg
```

or the appropriate journal command.

## SMART health

Use `smartctl` with the correct USB bridge mode.

Collect:

```bash
smartctl -i
smartctl -H
smartctl -A
smartctl -x
```

Review at minimum:

- overall SMART status
- reallocated sectors
- current pending sectors
- offline uncorrectable sectors
- UDMA CRC errors
- power-on hours
- temperature
- reported self-test history
- reported disk errors

Do not qualify the disk if SMART indicates likely failure.

If the enclosure cannot expose SMART data:

- document the limitation
- do not fabricate health results
- state whether qualification is conditional
- explain the resulting risk

## Performance baseline

Use file-based tests against the mounted filesystem.

Do not benchmark the raw block device after the filesystem contains desired state.

Record:

- sequential read
- sequential write
- random read
- random write
- IOPS where available
- test file size
- block size
- queue depth
- duration
- direct-I/O setting
- exact command or fio job definition

All benchmark files must be removed after testing.

## Stability test

Run approximately one hour of mixed file-based I/O.

During and after the test, inspect for:

- USB disconnects
- USB resets
- block I/O errors
- ext4 errors
- kernel warnings
- read-only filesystem remounts
- undervoltage messages
- device disappearance
- SMART counter deterioration

Record before-and-after SMART and kernel-log summaries.

## Reboot validation

Reboot `pi4mB02` according to the established operational process.

After reboot, verify:

```bash
findmnt /srv/longhorn
```

```bash
lsblk -f
```

```bash
df -hT /srv/longhorn
```

```bash
grep /srv/longhorn /etc/fstab
```

Create and remove a temporary file:

```bash
touch /srv/longhorn/.wo-0010-write-test
rm /srv/longhorn/.wo-0010-write-test
```

The mount must return automatically with the same UUID.

---

# Storage Group Membership

Current behavior uses:

```text
storage_nodes
```

for nodes with qualified dedicated storage.

Requirements:

- keep `pi4mB01` in `storage_nodes`
- do not add `pi4mB02` until all required qualification checks pass
- add `pi4mB02` after successful qualification
- ensure `storage.yml` runs safely across both nodes
- verify both nodes in one playbook run
- verify a second run reports no changes

---

# Verification Automation

Provide automated verification covering at least:

- inventory schema validity
- unique disk IDs per host
- unique mount paths per host
- unique labels
- by-id path exists
- by-id path resolves to a whole disk
- resolved device matches expected model
- resolved device matches expected serial
- resolved device matches expected WWN when configured
- resolved device matches expected capacity
- resolved device is not root
- resolved device is not boot
- resolved device is not swap
- partition table is GPT
- configured partition exists
- filesystem type is ext4
- filesystem label matches
- filesystem UUID is present
- fstab uses UUID
- expected mount is active
- actual mount source belongs to the expected disk
- filesystem is writable
- temporary verification file can be removed
- no duplicate fstab entries exist
- second run is idempotent

Verification must not delete unrelated files.

---

# Documentation Deliverables

Update existing documentation ownership areas rather than creating redundant pages.

At minimum, review and update:

```text
docs/infrastructure/storage.md
docs/infrastructure/ansible.md
docs/reference/infrastructure-inventory.md
docs/operations/
PROJECT_STATE.md
README.md
mkdocs.yml
```

Only change files where the content genuinely requires updating.

Create a dedicated operations page when necessary, for example:

```text
docs/operations/storage-onboarding.md
```

The operations documentation must include:

- how to connect and discover a disk
- how to identify model and serial
- how to inspect WWN
- how to find whole-disk `/dev/disk/by-id` entries
- how to distinguish disk entries from `-partN` entries
- how to identify the root and boot disk
- USB enclosure identity limitations
- how to add a disk to host variables
- complete inventory examples
- exact discovery command
- exact onboarding command
- exact runtime erase confirmation format
- exact qualification command
- exact normal reconciliation command
- exact verification command
- reboot validation
- troubleshooting guidance
- process for adding the node to `storage_nodes`
- warning that destructive authorization must never be stored in Git

Update MkDocs navigation if a new documentation page is added.

---

# Project-State Updates

After completion, `PROJECT_STATE.md` must record:

- the reusable storage lifecycle capability
- the inventory-driven multi-disk model
- the read-only discovery playbook
- the explicitly authorized onboarding playbook
- the normal non-destructive storage reconciliation playbook
- the qualification playbook
- `pi4mB01` regression validation
- `pi4mB02` disk identity
- `pi4mB02` filesystem label
- `pi4mB02` filesystem UUID
- `pi4mB02` mount point
- USB bridge and driver
- SMART result
- benchmark summary
- stability-test result
- reboot-persistence result
- both qualified storage nodes
- Longhorn remaining uninstalled
- WO-0011 as the next eligible storage work
- the unmounted `/srv/longhorn` fallback-directory risk

Update the infrastructure inventory with verified values only.

---

# Evidence

Create:

```text
artifacts/
└── WO-0010/
```

Store concise, sanitized evidence.

Suggested content:

```text
artifacts/WO-0010/
├── discovery-pi4mB01.txt
├── discovery-pi4mB02.txt
├── identity-pi4mB01.txt
├── identity-pi4mB02.txt
├── lsblk-before.txt
├── lsblk-after.txt
├── blkid-after.txt
├── partition-table-after.txt
├── fstab-validation.txt
├── mount-validation.txt
├── usb-summary.txt
├── smart-before.txt
├── smart-after.txt
├── benchmark.txt
├── stability-summary.txt
├── kernel-storage-summary.txt
├── reboot-validation.txt
├── idempotency.txt
└── validation.md
```

Do not commit:

- secrets
- private keys
- kubeconfig contents
- authentication tokens
- unnecessary full journal exports
- unrelated host data
- raw personal filesystem listings

`validation.md` must summarize the evidence and link or refer to the relevant files.

---

# Testing Requirements

Run applicable repository validation.

At minimum:

```bash
ansible-playbook playbooks/storage-discover.yml --syntax-check
```

```bash
ansible-playbook playbooks/storage-onboard.yml --syntax-check
```

```bash
ansible-playbook playbooks/storage.yml --syntax-check
```

```bash
ansible-playbook playbooks/storage-qualify.yml --syntax-check
```

```bash
ansible-inventory --graph
```

```bash
ansible-lint
```

```bash
git diff --check
```

If MkDocs is available:

```bash
mkdocs build --strict
```

If a command is unavailable, record the reason in the pull request rather than claiming it passed.

## Runtime validation

Run:

1. discovery against `pi4mB01`
2. discovery against `pi4mB02`
3. non-destructive regression reconciliation against `pi4mB01`
4. explicitly authorized onboarding against `pi4mB02`
5. normal reconciliation against both storage nodes
6. qualification against `pi4mB02`
7. reboot validation against `pi4mB02`
8. normal reconciliation a second time against both nodes

The final normal run should report:

```text
changed=0
failed=0
```

for both nodes unless a clearly documented unavoidable read-only diagnostic task reports differently.

---

# Safety Requirements

Codex must:

- fail safely on unexpected state
- display disk identity before destructive work
- require exact runtime confirmation
- protect root, boot and swap disks
- avoid automatic disk selection
- avoid wildcard destructive commands
- avoid relying on `/dev/sdX`
- preserve `pi4mB01`
- use the declared disk ID in confirmation
- verify the resolved device immediately before destructive work
- re-check identity after partition-table changes
- avoid storing destructive authorization in Git
- avoid reformatting an already-correct filesystem
- avoid hiding errors with broad `failed_when: false`
- avoid reporting successful qualification without evidence

---

# Acceptance Criteria

This work order is complete when:

## Existing-role evolution

- [x] The existing `ansible/roles/storage` role has been extended.
- [x] No duplicate or parallel storage role has been created.
- [x] The role supports a list of disks per host.
- [x] Existing scalar storage variables have been migrated or safely supported during migration.
- [x] The role remains reusable across nodes.

## Discovery

- [x] A read-only disk-discovery playbook exists.
- [x] Discovery reports model, serial, WWN, capacity and persistent paths.
- [x] Discovery identifies root and boot relationships.
- [x] Discovery performs no destructive action.
- [x] Future operators can use discovery without modifying role code.

## Safety

- [x] Destructive onboarding is separate from normal reconciliation.
- [x] Runtime erase confirmation is mandatory.
- [x] Erase authorization is not stored in inventory.
- [x] Root, boot and swap disks are protected.
- [x] Mounted unknown filesystems are protected.
- [x] Missing or ambiguous disk identity causes failure.
- [x] `/dev/sdX` is not used as persistent identity.
- [x] An already-correct filesystem is never reformatted.

## pi4mB01 regression

- [x] Existing `pi4mB01` storage was not reformatted.
- [x] Existing filesystem UUID was preserved.
- [x] Existing data was preserved.
- [x] `/srv/longhorn` remains mounted.
- [x] Reboot persistence remains valid.
- [x] The refactored role is idempotent on `pi4mB01`.

## pi4mB02 onboarding

- [x] The actual connected disk was discovered.
- [x] Its persistent whole-disk identifier was recorded.
- [x] Its model was recorded.
- [x] Its serial was recorded.
- [x] Its WWN was recorded when available.
- [x] Its exact capacity was recorded.
- [x] It was verified not to be the operating-system disk.
- [x] Existing data was erased only after exact authorization.
- [x] A GPT partition table was created.
- [x] One data partition was created.
- [x] An ext4 filesystem was created.
- [x] A unique filesystem label was assigned.
- [x] A filesystem UUID was obtained.
- [x] The filesystem is mounted at `/srv/longhorn`.
- [x] `/etc/fstab` uses UUID.
- [x] The mount survives reboot.
- [x] The filesystem is writable.
- [x] A second run is idempotent.

## Qualification

- [x] USB topology and negotiated speed were recorded.
- [x] UASP or `usb-storage` status was recorded.
- [x] SMART health was reviewed.
- [x] Critical SMART counters were reviewed.
- [x] File-based performance tests were completed.
- [x] Approximately one hour of mixed-I/O stability testing was completed.
- [x] Kernel logs were reviewed for storage errors.
- [x] Post-test SMART state was reviewed.
- [x] No unresolved critical storage error remains.
- [x] Qualification evidence was committed.
- [x] `pi4mB02` was added to `storage_nodes` only after qualification passed.

## Future onboarding

- [x] Adding another disk requires no role-code modification.
- [x] Documentation explains how to find a disk serial number.
- [x] Documentation explains how to find a WWN.
- [x] Documentation explains `/dev/disk/by-id`.
- [x] USB enclosure identity limitations are documented.
- [x] Complete inventory examples are documented.
- [x] Exact discovery, onboarding, qualification and reconciliation commands are documented.
- [x] Multiple disks per host are supported.

## Repository and workflow

- [x] `PROJECT_STATE.md` was updated.
- [x] Storage infrastructure documentation was updated.
- [x] Ansible documentation was updated.
- [x] Infrastructure inventory was updated.
- [x] MkDocs navigation was updated if required.
- [x] WO-0010 was archived according to repository workflow after acceptance.
- [x] Validation evidence exists under `artifacts/WO-0010/`.
- [x] No Longhorn installation was included.
- [x] Codex opened a pull request for review.

---

# Required Pull Request Description

The pull request description must include:

## Implementation summary

- how the existing role was refactored
- new playbooks created
- inventory schema introduced
- destructive-safety mechanism
- operating-system disk protection
- multiple-disk support

## pi4mB01 regression result

- persistent identifier
- resolved device
- model and serial
- filesystem UUID before and after
- mount state
- data-preservation statement
- idempotency result

## pi4mB02 result

- selected persistent by-id path
- resolved kernel device
- model
- serial
- WWN
- exact capacity
- USB enclosure or bridge
- USB driver
- negotiated speed
- partition layout
- filesystem label
- filesystem UUID
- mount point
- fstab source
- reboot result
- idempotency result

## Qualification result

- SMART summary
- critical SMART counters
- benchmark summary
- stability-test summary
- kernel-log summary
- unresolved limitations

## Future operator commands

Include the final exact commands for:

```text
discovery
onboarding
qualification
normal reconciliation
verification
```

Do not include secrets, SSH keys, kubeconfig data or unnecessary raw logs.

---

# Completion Output

Codex must conclude the implementation with:

```text
WO-0010 Completion Summary

Existing storage regression:
- pi4mB01 status
- filesystem UUID preservation
- mount status
- idempotency status

New storage onboarding:
- pi4mB02 disk identity
- USB connection
- filesystem
- UUID
- mount
- reboot result

Qualification:
- SMART result
- benchmark result
- stability result
- kernel-log result

Reusable capability:
- discovery command
- onboarding command
- qualification command
- reconciliation command

Outstanding risks:
- USB enclosure limitations
- SMART limitations
- nofail fallback-directory risk
- remaining Longhorn prerequisites

Recommendation:
READY or NOT READY FOR WO-0011 — Longhorn Storage Foundation
```

Longhorn must proceed only if both storage nodes are qualified and no blocking storage issue remains.
