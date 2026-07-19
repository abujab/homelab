# Storage Role

---

## Purpose

Install disk diagnostic tools and mount a pre-existing, explicitly identified filesystem for future Longhorn use.

## Scope

The role validates the filesystem label, type, disk model and serial before mounting it at `/srv/longhorn`.

## Background

Disk partitioning and filesystem creation are intentionally excluded because they are destructive operations requiring explicit operator approval.

## Architecture / Implementation

The role resolves the partition through `LABEL=pi-cl-storage`, validates its parent disk against inventory variables, and uses `ansible.posix.mount` to create an idempotent `/etc/fstab` entry.

## Design Decisions

Device names such as `/dev/sda` are never persisted because USB enumeration can change across boots.

## Best Practices

Define an exact expected model and serial for every managed storage node.

## Future Improvements

Add other nodes only after their storage hardware has passed the same qualification process.

## Related Documents

- `docs/infrastructure/storage.md`
