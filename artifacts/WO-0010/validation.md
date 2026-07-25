# WO-0010 Validation

---

## Purpose

Record the implementation and hardware qualification decision for the reusable
storage lifecycle and the second storage node.

## Scope

Validation covers read-only discovery, exact disk identity, destructive safety,
filesystem onboarding, USB and SMART health, file-based qualification, reboot
persistence, pi4mB01 regression and normal reconciliation. Longhorn and other
Kubernetes storage configuration are outside WO-0010.

## Background

The first pi4mB02 candidate failed SMART and was rejected without formatting.
The replacement disk was initialized only after its persistent identity was
declared and the exact runtime token was supplied. The existing pi4mB01 disk
was never initialized or reformatted.

## Architecture / Implementation

| Check | Result |
|-------|--------|
| Read-only discovery | Pass — both node disks, persistent paths and OS-disk relationships recorded |
| Destructive authorization | Pass — onboarding targets one declared disk and requires `<host>:<disk-id>:ERASE` |
| OS and mounted-disk protection | Pass — root, boot, swap, read-only and mounted unprepared targets are rejected |
| pi4mB01 regression | Pass — same disk, label, UUID and mount; no destructive task available in reconcile mode |
| pi4mB02 onboarding | Pass — GPT, one ext4 partition, unique label and UUID mount created |
| USB topology | Pass — externally powered USB 3 enclosure, 5000M, UAS |
| SMART health | Pass with monitored limitation — health passed; media counters zero; one stable UDMA CRC event |
| Baseline benchmarks | Pass — all four 30-second file workloads returned `err=0` |
| Stability | Pass — 3,600 seconds plus 300-second post-reboot follow-up, `err=0` |
| Kernel logs | Pass — no matched USB, UAS, block, ext4, read-only or undervoltage error |
| Reboot persistence | Pass — two boots with powered enclosure; same UUID mounted read/write |
| Idempotency | Pass — both final two-node runs reported `changed=0`, `failed=0` |
| Review safety remediation | Pass — opt-in quirks/reboots, exact metadata/fstab checks, targeted qualification and failure cleanup verified |

The evidence files in this directory contain concise, sanitized values. The
erase token is intentionally omitted from stored host state and inventory.

The first reboot incremented `UDMA_CRC_Error_Count` from 0 to 1 without a
kernel error. The count remained 1 through a second reboot and five additional
minutes of mixed I/O. This is not a media-sector failure, but it remains a
monitored cable, bridge or interface limitation. Any future increase requires
requalification before storage use expands.

### Review remediation validation

The requested safety corrections were validated on 2026-07-26:

- all USB quirk tasks were skipped on both storage nodes with the default
  `storage_manage_usb_quirks: false`
- `/boot/firmware/cmdline.txt` SHA-256 values were unchanged across two normal
  reconciliation runs: `d9be6a3b...12af60a` on pi4mB01 and
  `38d5ab57...151ca2` on pi4mB02
- boot IDs were unchanged across those runs, proving neither node rebooted
- filesystem type, label and UUID were read separately and compared exactly
- each active mount UUID matched the prepared filesystem UUID and its expected
  physical disk
- each `/etc/fstab` entry had exact UUID source, target, ext4 type, required
  options, dump `0` and pass `2`
- qualification without `storage_target_disk_id` failed in the pre-task before
  role execution
- a deliberate qualification run with `storage_fio_binary=/bin/false` retained
  the original non-zero failure, executed the `always` cleanup, and left no
  `.storage-qualification-*` files
- both final two-node reconciliation runs reported `changed=0`, `failed=0`
- all four storage playbooks passed syntax checking, `ansible-inventory --graph`
  passed, `mkdocs build --strict` passed and `git diff --check` passed
- `ansible-lint` remained unavailable in the local environment

## Design Decisions

Whole disks are selected through persistent `/dev/disk/by-id/` paths and exact
identity fields. Filesystems are mounted by UUID. Human-readable disk IDs and
labels follow the canonical host-local data-disk sequence. The qualified legacy
pi4mB01 label remains unchanged to avoid unnecessary filesystem mutation.

## Best Practices

Repeat discovery whenever the physical disk or enclosure changes. Qualify the
complete disk, bridge, cable, power and port combination. Do not promote a host
to `storage_nodes` until SMART, fio, kernel-log and reboot checks all pass.
Monitor the pi4mB02 CRC counter from its accepted baseline of one.

## Future Improvements

The future Longhorn work must prevent consumers from using the unmounted
`/srv/longhorn` fallback directory when `nofail` permits a boot without USB
storage. Ongoing SMART and USB reset monitoring also remains required.

## Related Documents

- `docs/operations/storage-onboarding.md`
- `docs/infrastructure/storage.md`
- `work-orders/WO-0010-reusable-storage-onboarding.md`
