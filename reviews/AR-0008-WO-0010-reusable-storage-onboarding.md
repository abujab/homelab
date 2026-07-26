# Architecture Review Archive

- **Architecture Review:** AR-0008
- **Work Order:** WO-0010
- **Pull Request:** abujab/homelab#17
- **Reviewed Head:** `3a576c214c171cec1739baf6e3dc43f02a190a12`
- **Merged Commit:** `e002d058cb3e1879068f1320319a81f4d6dde572`
- **Reviewer:** gabdul-AI
- **Approved:** 2026-07-25T23:59:30Z
- **Result:** Approved

---

## Review History

The final-head approval is recorded in the metadata above. Terse approval text
is intentionally omitted; the substantive reviews follow.

````markdown
# Review — Changes Requested

The overall implementation is strong and substantially satisfies WO-0010. The reusable storage lifecycle, persistent disk identity, destructive-operation safeguards, UUID-backed mounts, `pi4mB01` regression protection, and `pi4mB02` hardware qualification are all valuable improvements.

However, I found one serious safety issue and several correctness problems that should be resolved before merge.

## Blocking issue: USB quirk management is not safely scoped

The storage role always imports:

```text
ansible/roles/storage/tasks/configure-usb-quirks.yml
````

The default values are:

```yaml
storage_usb_storage_quirks: []
storage_usb_core_quirks: []
storage_reboot_after_usb_quirk_change: true
```

The current implementation interprets an empty quirk list as a request to remove any existing `usb-storage.quirks` or `usbcore.quirks` parameters from `/boot/firmware/cmdline.txt`.

This means that an ordinary run of:

```bash
ansible-playbook playbooks/storage.yml
```

could:

1. remove manually configured kernel quirks that are unrelated to the declared storage disk
2. change the node boot configuration
3. automatically reboot the node

That is too dangerous for normal storage reconciliation.

### Required change

Make USB quirk ownership explicitly opt-in, for example:

```yaml
storage_manage_usb_quirks: false
```

Expected behavior:

* when `storage_manage_usb_quirks: false`, do not inspect, add, update or remove quirk parameters
* when `storage_manage_usb_quirks: true`, reconcile only the explicitly declared quirk configuration
* an empty managed list may remove managed quirks only when management is explicitly enabled
* normal storage reconciliation must not reboot a node unless reboot behavior was explicitly enabled for that host
* the role must not assume ownership of kernel command-line settings merely because the storage role is running

Please also document this behavior and add validation proving that an unmanaged existing quirk remains untouched.

---

## Required correction: filesystem metadata comparisons must be exact

Prepared-state detection currently checks values using substring searches similar to:

```yaml
('TYPE=' ~ expected_type) in blkid_output
('LABEL=' ~ expected_label) in blkid_output
```

This could accept incorrect values. For example, an expected label:

```text
pi4mB02-data01
```

could incorrectly match:

```text
pi4mB02-data010
```

### Required change

Parse filesystem metadata into structured or separate exact values:

```bash
blkid -s TYPE -o value <partition>
blkid -s LABEL -o value <partition>
blkid -s UUID -o value <partition>
```

Then compare using exact equality:

```yaml
observed_type == expected_type
observed_label == expected_label
observed_uuid | length > 0
```

Use the same exact comparison in both onboarding-state detection and normal reconciliation.

---

## Required correction: qualification must select exactly one disk

`storage-qualify.yml` currently verifies that the host has at least one declared disk, but does not require `storage_target_disk_id`.

On a future host with multiple disks, omitting the target ID could run benchmarks and the one-hour stability test against every declared disk.

### Required change

Require:

* exactly one host through `--limit`
* a non-empty `storage_target_disk_id`
* exactly one inventory disk matching that ID

The qualification invocation should remain:

```bash
ansible-playbook playbooks/storage-qualify.yml \
  --limit <host> \
  --extra-vars "storage_target_disk_id=<disk-id>"
```

Qualification should fail before role execution when the target ID is missing or ambiguous.

---

## Required correction: qualification files must be removed after failures

The qualification task removes fio files only after all benchmark and stability commands complete successfully.

If one fio task fails, Ansible stops before cleanup, potentially leaving several gigabytes of temporary files under the storage mount.

### Required change

Wrap the benchmark and stability operations in an Ansible `block` and place cleanup under `always`, for example:

```yaml
- name: Run storage qualification
  block:
    - name: Run benchmarks
      ...

    - name: Run stability test
      ...

  always:
    - name: Remove qualification files
      ansible.builtin.file:
        path: "{{ storage_disk.mount.path }}/{{ item }}"
        state: absent
      loop:
        ...
```

Cleanup must happen whether fio:

* succeeds
* fails
* is interrupted by a later assertion
* returns a non-zero exit code

Cleanup should not hide the original qualification failure.

---

## Required correction: normal reconciliation should not depend on SMART passthrough

`resolve-device.yml` runs:

```bash
smartctl -d <type> -i <device>
```

for every storage operation.

The result is not used in the subsequent exact identity assertions, but a bridge that does not support SMART passthrough could cause ordinary reconciliation and mounting to fail.

SMART validation belongs to qualification and health monitoring. It should not be a mandatory dependency for mounting an already-qualified filesystem.

### Required change

One of the following approaches is acceptable:

1. move mandatory SMART inspection entirely into `storage-qualify.yml`
2. run SMART identity opportunistically during reconciliation without failing when passthrough is unsupported
3. introduce an explicit inventory setting controlling whether SMART passthrough is required

Normal reconciliation must continue to enforce:

* persistent path
* model
* serial
* WWN where configured
* exact size
* root/boot/swap protection

It should not fail solely because `smartctl` cannot communicate through a particular USB bridge.

---

## Required correction: verify the exact UUID-backed fstab contract

The role currently counts `/etc/fstab` entries for the mount point, but does not verify that the entry’s source is exactly:

```text
UUID=<expected-filesystem-uuid>
```

The active mount assertion also allows either the UUID string or the partition path to appear.

This is weaker than the WO-0010 requirement.

### Required change

Parse the matching `/etc/fstab` entry and assert:

* exactly one entry exists for the target path
* field 1 equals `UUID=<expected UUID>`
* field 2 equals the configured mount path
* field 3 equals the configured filesystem type
* mount options contain the expected configured options
* dump and pass values match the intended contract

Also verify that the active mount resolves to the same filesystem UUID and expected physical disk.

Do not accept a persistent `/dev/sdX1` entry merely because the active mount currently works.

---

## Required correction: fix variable names in the PR description

The PR description currently documents variables resembling:

```text
storage_onboarding_target_id
storage_onboarding_erase_confirmation
storage_qualification_target_id
```

The implementation and runbook actually use:

```text
storage_target_disk_id
storage_destroy_confirmation
```

### Required change

Update the PR description so the documented commands exactly match the implementation.

Use:

```bash
ansible-playbook playbooks/storage-onboard.yml \
  --limit <host> \
  --extra-vars \
  "storage_target_disk_id=<disk-id> storage_destroy_confirmation=<host>:<disk-id>:ERASE"
```

and:

```bash
ansible-playbook playbooks/storage-qualify.yml \
  --limit <host> \
  --extra-vars "storage_target_disk_id=<disk-id>"
```

---

## Positive findings

The following areas are well implemented:

* the existing storage role was extended rather than duplicated
* storage is represented as a list supporting multiple disks per host
* persistent whole-disk `/dev/disk/by-id/` identities are used
* model, serial, WWN and exact byte capacity are validated
* root, boot, swap, read-only and unexpected mounted-device protections are present
* destructive onboarding is separate from normal reconciliation
* the erase token is ephemeral and host/disk specific
* an already-prepared filesystem is not reformatted
* filesystems are mounted by UUID
* `pi4mB01` was preserved without destructive modification
* the original unhealthy `pi4mB02` candidate was correctly rejected before formatting
* the replacement `pi4mB02` disk completed SMART, benchmark, stability and reboot validation
* the stable UDMA CRC baseline is transparently documented
* the final two-node reconciliation was reported as idempotent
* the storage onboarding runbook is detailed and operationally useful

## Re-review requirements

Please update the implementation and provide evidence for:

* [ ] USB quirk management is explicitly opt-in
* [ ] unmanaged existing kernel quirks remain unchanged
* [ ] normal reconciliation cannot unexpectedly reboot a node
* [ ] filesystem type and label comparisons use exact equality
* [ ] qualification requires exactly one selected disk
* [ ] fio temporary files are removed even after task failure
* [ ] normal reconciliation does not require SMART passthrough
* [ ] `/etc/fstab` is verified as exactly UUID-backed
* [ ] PR description commands use the actual variable names
* [ ] syntax checks still pass
* [ ] `mkdocs build --strict` still passes
* [ ] final reconciliation on both nodes reports `changed=0`, `failed=0`




---

````markdown
# Approval — WO-0010 Storage Lifecycle

Re-review completed against PR head:

```text
3a576c214c171cec1739baf6e3dc43f02a190a12
````

The requested safety and correctness changes have been addressed.

## Verified remediation

* USB quirk management and automatic reboot logic were removed from normal storage reconciliation.
* Normal reconciliation no longer edits kernel command-line settings.
* Filesystem type, label and UUID are read separately and compared using exact equality.
* Storage qualification requires one explicitly selected `storage_target_disk_id`.
* fio temporary files are removed through an Ansible `always` cleanup path, including after failure.
* SMART passthrough is mandatory for qualification but no longer blocks normal reconciliation.
* `/etc/fstab` is verified to contain exactly one UUID-backed entry with the expected:

  * source
  * mount point
  * filesystem type
  * mount options
  * dump value
  * filesystem-check pass value
* The active mount UUID is verified against the prepared filesystem.
* The active mount source is verified to belong to the expected physical disk.
* The PR description now uses the actual implemented variables:

  * `storage_target_disk_id`
  * `storage_destroy_confirmation`

## Validation evidence reviewed

* Qualification without a target disk ID fails before role execution.
* A deliberate fio failure preserves the original failure and still removes qualification files.
* Kernel command-line checksums remained unchanged during normal reconciliation.
* Boot IDs remained unchanged, confirming that reconciliation did not reboot either node.
* Both final storage reconciliation runs completed with:

```text
changed=0
failed=0
```

* All storage playbooks passed syntax checking.
* Inventory validation passed.
* `mkdocs build --strict` passed.
* `git diff --check` passed.
* `ansible-lint` was unavailable and is transparently documented.

## Decision

The implementation now satisfies the safety, idempotency, documentation and reusable-onboarding requirements of WO-0010.

**Approved for merge.**

After merge, proceed with:

1. archiving the final review
2. creating the WO-0010 release
