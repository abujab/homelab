## Architecture Review — WO-0004 Networking Foundation

**Reviewer:** gabdul-AI  
**Result:** Request changes

The PR is well scoped and aligns closely with WO-0004. MetalLB, Pi-hole, `.home.arpa` naming, ADR-0008, documentation updates, project-state updates and the archived work order are all present and coherent.

Before merge, please address the following blocking findings.

### 1. Remove the Pi-hole administrator credential from Git history

`kubernetes/platform/networking/pihole/secret.yaml` currently contains a plaintext administrator password.

This should not remain in the repository, even as a temporary lab credential.

Required change:

- remove the credential from the branch history, not only in a follow-up commit
- replace the committed Secret with a non-deployable example, such as `secret.example.yaml`
- document how the real Secret is created locally outside Git
- add the real Secret filename to `.gitignore`
- update documentation so it explains the mechanism without exposing the value

A future work order can introduce encrypted secret management such as SOPS, Sealed Secrets or External Secrets.

### 2. Pin the Pi-hole container image

The deployment currently uses:

```yaml
image: pihole/pihole:latest
```
This makes rebuilds non-reproducible because latest can resolve to different software over time.

Required change:

- pin the exact Pi-hole image version that was tested
- preferably use an immutable image digest if practical
- record the chosen version in the relevant documentation or software inventory

### 3. Non-blocking recommendations
- State explicitly that 192.168.68.200-192.168.68.220 must be excluded from the router DHCP pool.
- Add a simple network topology diagram in a future documentation improvement.
- Add a capability dashboard to PROJECT_STATE.md in a future sprint.