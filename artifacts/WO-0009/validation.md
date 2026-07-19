# WO-0009 Validation

---

## Purpose

Record the qualification decision for the pi4mB01 storage hardware foundation.

## Scope

Validation covers the Hitachi disk, USB bridge, ext4 filesystem, persistent mount, reboot behavior and sustained file-based I/O. Kubernetes and Longhorn are outside this work order.

## Background

The discovered disk was already partitioned and formatted with the required filesystem label. No destructive operation was performed.

## Architecture / Implementation

| Check | Result |
|-------|--------|
| Hardware identity | Pass — model and serial match inventory |
| Filesystem | Pass — ext4 labeled `pi-cl-storage` |
| SMART health | Pass — overall health passed and critical sector counts are zero |
| USB topology | Pass with limitation — 5 Gbit/s SuperSpeed, `usb-storage`, no UASP |
| Persistent mount | Pass — label-based `/srv/longhorn` fstab entry |
| Reboot persistence | Pass — automatic mount and temporary-file test succeeded |
| Baseline benchmarks | Pass — all four fio workloads returned `err=0` |
| Stability | Pass — 3,600 seconds, 15.2 GiB read, 6,677 MiB written, `err=0` |
| Kernel logs | Pass — no disconnect, reset, I/O or filesystem errors |
| Post-test SMART | Pass — critical counters unchanged; temperature 41°C |

## Design Decisions

The mount is bound to the filesystem label and automation validates model and serial. Raw-device writes and destructive filesystem preparation are excluded from automation.

## Best Practices

Continue periodic SMART monitoring and review USB/kernel errors before placing important workloads on the device.

## Future Improvements

Prefer UASP-capable SSD enclosures for production-grade performance. Qualify storage independently on additional nodes before evaluating Longhorn replication.

## Related Documents

- `docs/infrastructure/storage.md`
- `work-orders/WO-0009-storage-hardware-foundation.md`
