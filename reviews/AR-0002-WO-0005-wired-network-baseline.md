## Architecture Review — WO-0005 Wired Network Baseline

**Result:** Approved

The PR is well aligned with WO-0005 and ADR-0009.

### Review findings

- The new `network` role is correctly separated from `common` and `k3s`.
- Ethernet preflight checks run before Wi-Fi is modified.
- Wi-Fi disablement is conditional and idempotent.
- Final verification checks Ethernet state, expected node address, default route, Wi-Fi IPv4 state, NetworkManager radio state and SSH connectivity.
- The role is integrated after `common` in the baseline playbook.
- Runtime validation demonstrates all nodes remain reachable, Kubernetes remains healthy, the second baseline run produces `changed=0`, and MetalLB/Pi-hole now work over Ethernet.
- ADR-0009 clearly records the wired-network decision and links back to ADR-0008.
- Documentation and `PROJECT_STATE.md` are updated consistently.

### Non-blocking notes

- The PR description could explicitly mention the successful `pi4mB01` reboot-persistence check, since `PROJECT_STATE.md` records that validation.
- A future CI workflow should automate syntax checks and `mkdocs build --strict`; this PR currently has no reported status checks.

**Final verdict: Approve for merge and release as `v0.5.1`.**