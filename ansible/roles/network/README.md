# Network Role

---

## Purpose

The `network` role enforces wired Ethernet as the managed network transport for HomeLab Kubernetes nodes.

## Scope

The role verifies Ethernet readiness, disables the Wi-Fi radio through NetworkManager and verifies the final wired baseline.

## Background

MetalLB Layer 2 service exposure depends on reliable Ethernet and ARP behavior. Dedicated HomeLab cluster nodes should not depend on Raspberry Pi Wi-Fi for Kubernetes, MetalLB or platform-service traffic.

## Architecture / Implementation

Task order:

```text
preflight.yml
wifi.yml
verify.yml
```

The role fails before changing Wi-Fi state if Ethernet is not ready.

## Design Decisions

- Ethernet is verified before Wi-Fi is disabled.
- Wi-Fi is disabled through `nmcli radio wifi off`.
- Wi-Fi profiles, packages and kernel modules are left intact for emergency recovery.
- Node IP addresses remain inventory data and are not duplicated in role defaults.

## Best Practices

- Run through `playbooks/baseline.yml`.
- Validate a single node before running against the full `pis` group.
- Do not reboot all nodes simultaneously.
- Re-enable Wi-Fi manually only for emergency recovery.

## Future Improvements

- Add reference documentation for interface names, network ranges and validation commands.
- Add automated CI linting for Ansible roles.

## Related Documents

- `docs/decisions/ADR-0009-wired-network-for-cluster-nodes.md`
- `docs/infrastructure/networking.md`
