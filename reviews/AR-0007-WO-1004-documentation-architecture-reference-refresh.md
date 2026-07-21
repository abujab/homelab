# Architecture Review Archive

- **Architecture Review:** AR-0007
- **Work Order:** WO-1004
- **Pull Request:** abujab/homelab#14
- **Reviewed Head:** `9fe8f3c7cfc4446648154ccab8bac12515fbdf72`
- **Merged Commit:** `1770bb588fe5f866941d2326ad77e9ff03cfbc1a`
- **Reviewer:** gabdul-AI
- **Approved:** 2026-07-21T22:14:38Z
- **Result:** Approved

---

## Review History

The final-head approval is recorded in the metadata above. Terse approval text
is intentionally omitted; the substantive reviews follow.

## Review result: **Request changes — do not merge PR #14 yet**

The documentation work itself is strong. The Reference section, architecture/current-target separation, roadmap, Longhorn blocking conditions, work-order archive, and validation evidence are well structured.

I found one **critical security issue**.

### Blocking finding: live kubeconfig is committed publicly

`docs/overview/repository.md` lists `ansible/kubeconfig` as tracked repository content and describes it as an access-sensitive runtime file.

The actual tracked `ansible/kubeconfig` contains an embedded Kubernetes client private key. I will not reproduce it here.

GitHub reports that this repository is **public**. This credential therefore has to be treated as compromised. Deleting the file in a new commit is not enough, because it remains available through Git history and existing clones.

There is also a contradiction in the new documentation: it says runtime Secret values and private material are excluded from Git, while the kubeconfig private key is tracked.

The validation records the sensitive-content scan as passing, but it appears to have scanned only changed content, not the whole repository.  The current `.gitignore` also does not exclude `ansible/kubeconfig`.

## Required remediation

Before PR #14 is merged:

1. **Rotate or replace the exposed Kubernetes client credentials** so the old private key can no longer authenticate.
2. Remove `ansible/kubeconfig` from tracked repository content.
3. Address its presence in Git history. Merely committing its deletion is insufficient.
4. Add `ansible/kubeconfig` to `.gitignore`.
5. Store only a sanitized example file, such as `ansible/kubeconfig.example`, if documentation needs one.
6. Run a repository-wide secret scan, not only a changed-file scan.
7. Update the WO-1004 audit and validation from PASS to reflect the finding, then record its resolution.
8. Correct `docs/overview/repository.md` and `PROJECT_STATE.md`.

Because these changes fall outside WO-1004’s documentation-only allowlist, the clean workflow is:

```text
Urgent credential-remediation PR
    ↓
Rotate and invalidate exposed credential
    ↓
Remove kubeconfig and clean history
    ↓
Rebase PR #14
    ↓
Update WO-1004 evidence
    ↓
Review again
```

Apart from this security issue, I did not find another blocker in the architecture and reference refresh.


---

## PR #14 re-review: **Approved**

No remaining blocking findings.

The earlier security blocker has been properly addressed:

* PR #15 is merged and removed the administrator kubeconfig from tracked content.
* `ansible/kubeconfig` is now ignored on `main`.
* The repository guide now correctly treats it as a locally generated, mode-`0600`, untracked runtime credential.
* The WO-1004 audit explicitly acknowledges that the original changed-content scan was insufficient, records the credential revocation and history rewrite, and reports a clean full-history Gitleaks scan afterward.
* The validation was corrected from the invalid original PASS and now records the before-remediation failure, post-rewrite zero-finding scan, old credential rejection, restored cluster health, and successful platform validation.
* `PROJECT_STATE.md` accurately records both the completed remediation and the remaining GitHub Support cleanup.

The documentation work itself remains strong:

* Seven authoritative Reference pages.
* Clear separation of current and target architecture.
* Accurate storage state: one qualified node, no Longhorn deployment.
* Refreshed roadmap and repository model.
* ADR status versus implementation state handled without rewriting history.
* Strict MkDocs build passing after the history rewrite and rebase.

The pending cleanup of read-only pull-request refs and cached GitHub views is **non-blocking**, because the exposed credential has already been cryptographically invalidated.

**Verdict: APPROVE and merge PR #14.**
