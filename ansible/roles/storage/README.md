# Storage Role

---

## Purpose

Manage the inventory-driven lifecycle for dedicated node storage.

## Scope

The role validates persistent whole-disk identity, protects operating-system
storage, initializes only explicitly authorized disks, mounts by filesystem
UUID and runs file-based hardware qualification.

## Background

Discovery, destructive onboarding, qualification and normal reconciliation use
separate playbooks. `storage_target_disk_id` selects one entry when onboarding
or qualifying a multi-disk host. Runtime erase authorization is never stored in
inventory.

## Architecture / Implementation

`storage_disks` is a list, so a host may declare multiple disks. The role
resolves each persistent path, validates model, serial, WWN and exact capacity,
rejects root, boot, swap and unexpected mounted storage, and maintains one
exact UUID-based fstab entry per mount. Filesystem type, label and UUID are
compared as exact values. SMART passthrough is required during qualification,
not during ordinary reconciliation.

USB kernel quirk ownership is disabled by default. A host must explicitly set
`storage_manage_usb_quirks: true` before the role reads or reconciles quirk
parameters. Automatic rebooting is a separate opt-in through
`storage_reboot_after_usb_quirk_change: true`.

## Design Decisions

Device names such as `/dev/sda` are never persisted because USB enumeration can
change across boots. Correctly prepared filesystems are validated rather than
recreated.

## Best Practices

Run discovery first, use verified inventory values, keep erase tokens ephemeral,
select exactly one disk for qualification, and add hosts to `storage_nodes` only
after qualification passes. Qualification files are removed through an Ansible
`always` cleanup path even when fio fails.

## Future Improvements

Protect the future Longhorn data path against use when the external filesystem
is absent.

## Related Documents

- `docs/infrastructure/storage.md`
- `docs/operations/storage-onboarding.md`
