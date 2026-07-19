# Architecture Review Archive

- **Architecture Review:** AR-0006
- **Work Order:** WO-0009
- **Pull Request:** abujab/homelab#12
- **Reviewed Head:** `01fb70d32d495f318215f2ffd69e4e7cfb68c179`
- **Merged Commit:** `555a2d7659c3fc86a2e3da996561c2e0adbee74d`
- **Reviewer:** gabdul-AI
- **Approved:** 2026-07-19T21:10:14Z
- **Result:** Approved

---

## Review History

The final-head approval is recorded in the metadata above. Terse approval text
is intentionally omitted; the substantive reviews follow.

## Review Findings

Overall this is another very high quality work order. The separation between hardware qualification and the future Longhorn deployment is excellent, the evidence is comprehensive, and the automation is largely idempotent.

I found one issue that I recommend addressing before merge.

---

### 🔴 Finding 1 – Empty inventory values bypass storage identity validation

**Severity:** High

The role correctly validates that the discovered storage matches the expected model and serial:

```yaml
storage_expected_model in storage_disk_identity.stdout
storage_expected_serial in storage_disk_identity.stdout
```

However, the role defaults are:

```yaml
storage_expected_model: ""
storage_expected_serial: ""
```

Since an empty string is considered to be contained in every string, any host added to the `storage_nodes` inventory without overriding these variables would satisfy the identity assertion.

This weakens one of the primary safety mechanisms of the role.

**Recommendation**

Add an explicit preflight assertion before any storage discovery or mount operations:

```yaml
- name: Assert expected storage identity is configured
  ansible.builtin.assert:
    that:
      - storage_expected_model | trim | length > 0
      - storage_expected_serial | trim | length > 0
    fail_msg: >-
      storage_expected_model and storage_expected_serial must be configured
      explicitly for every storage node.
```

This ensures that storage qualification cannot proceed unless the inventory explicitly defines the expected hardware identity.

---

### Summary

**Strengths**

- Excellent separation of hardware qualification from Longhorn deployment.
- Strong evidence collection and validation artifacts.
- SMART, benchmark, reboot and stability validation are comprehensive.
- Label-based mounting is correctly implemented.
- Identity verification using both model and serial is an excellent safeguard.
- The documentation clearly records the current hardware limitations (single storage node, non-UASP bridge, mechanical HDD).

**Recommendation**

Approve after addressing **Finding 1**.

---

Final Review

Result: ✅ Approved

Highlights
Excellent separation of hardware qualification from Longhorn deployment.
Strong idempotent Ansible role.
Hardware identity validation (model + serial) is an excellent safety mechanism.
Label-based mounting is the correct design choice.
Comprehensive evidence collection (SMART, fio, reboot, kernel logs).
Clear documentation of current limitations (single storage node, mechanical HDD, no UASP).
The added preflight assertion closes the only safety gap identified during review.
Recommendation

Approve and merge PR #12.

This work order establishes a solid storage foundation and gives us confidence to proceed with WO-0010 – Longhorn Storage Foundation.
