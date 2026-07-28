# WO-0012 Evidence

---

## Purpose

This directory contains concise, sanitized verification for power-loss and
cold-boot resilience. No token, token-derived checksum, private key or
kubeconfig credential is retained.

## Evidence Index

- `incident-summary.md` — outage root cause and recovery
- `chrony-baseline.txt` — active time implementation on all nodes
- `systemd-effective-dependencies.txt` — effective K3s prerequisite and recovery units
- `synchronized-restart.txt` — controlled synchronized-time restart
- `control-plane-cold-boot-ordering.txt` — `pi4mB01` reboot ordering
- `worker-cold-boot-ordering.txt` — `pi4mB04` reboot ordering
- `delayed-time-source-test.txt` — NTP-only delay and late recovery
- `cluster-health-after-recovery.txt` — nodes, services and storage checks
- `idempotency-run-1.txt` and `idempotency-run-2.txt` — final clean runs
- `sqlite-backup-readiness.txt` — datastore discovery and backup gap
- `external-resilience-plan.md` — operator-owned RTC, NTP and UPS work

## Test Boundary

A forced mains-loss test was not performed. The approved lower-risk validation
used one controlled worker reboot, one controlled server reboot and an NTP-only
firewall delay on one worker. SSH and non-NTP networking remained available.
