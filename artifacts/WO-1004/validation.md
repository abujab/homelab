# WO-1004 Validation

---

## Purpose

Record the final acceptance result for Documentation Sprint 4.

## Scope

Validation covers deliverables, current-versus-planned accuracy, navigation,
internal links, strict MkDocs output, whitespace, changed paths and sensitive
content. The original WO-1004 validation did not change or live-test running
infrastructure; the security remediation triggered by review was executed and
validated separately in PR #15.

## Acceptance Checklist

- [x] Documentation audit completed
- [x] Reference landing page created
- [x] Infrastructure inventory created
- [x] Naming and addressing reference created
- [x] Software inventory created
- [x] Service catalog created
- [x] Decision register created
- [x] Glossary created
- [x] Architecture refreshed
- [x] Roadmap refreshed
- [x] Repository structure refreshed
- [x] Existing infrastructure documentation reviewed
- [x] Existing operations documentation reviewed
- [x] ADR status and links reviewed
- [x] Current and future capabilities clearly separated
- [x] Storage state accurately documented
- [x] Longhorn identified as not installed
- [x] Cross-links reviewed
- [x] MkDocs navigation updated
- [x] `PROJECT_STATE.md` updated
- [x] Required evidence included in the completed work-order change
- [x] `mkdocs build --strict` passed
- [x] `git diff --check` passed
- [x] No executable infrastructure file modified
- [x] Repository-wide secret scan completed
- [x] Exposed administrator credential revoked and removed

## Automated Results

| Check | Result |
|-------|--------|
| `.venv/bin/mkdocs build --strict` | PASS, exit 0 |
| Relative Markdown target check | PASS, zero missing targets |
| Documentation versus MkDocs navigation | PASS, zero omitted pages and zero missing targets |
| Duplicate MkDocs navigation targets | PASS, zero |
| `git diff --check` | PASS |
| Changed-file allowlist | PASS |
| Original sensitive changed-content scan | FAIL as a repository security control; it did not inspect existing history |
| Gitleaks `8.30.1` before remediation | FAIL as expected; one `private-key` finding in historical `ansible/kubeconfig` |
| Gitleaks `8.30.1` after history rewrite and PR #14 rebase | PASS, 46 commits scanned and zero findings |
| Reachable-object check after history rewrite | PASS, no `ansible/kubeconfig` path |
| Remote public branch and tag comparison | PASS, every ref matches the validated sanitized mirror |
| `main` branch-protection restoration | PASS, enforced administrators, one approval, stale-review dismissal, code-owner review and force-push prohibition restored |
| Exposed kubeconfig authentication after CA replacement | PASS, rejected as `Unauthorized` with server TLS verification disabled |
| Replacement cluster health | PASS, four nodes and 15 replacement pods Ready |
| Pi-hole DNS, ingress, TLS and exposure validation | PASS |
| Infrastructure-file change scan | PASS, none |

## Review Correction

The original `No sensitive value exposed` assertion and final PASS were
invalidated when PR #14 review found a live administrator kubeconfig in existing
Git history. The finding was treated as a compromised credential rather than a
documentation-only defect.

Security PR #15 and the associated operational response replaced the complete
K3s cluster CA hierarchy, invalidated the exposed client certificate, removed
and ignored the generated kubeconfig, restricted regenerated copies to mode
`0600`, refreshed every node and pod, and purged the path from branch and tag
history. Repository-wide Gitleaks validation then passed with zero findings.

Fifteen GitHub pull-request refs were affected by the rewrite. They are
read-only, so GitHub Support dereferencing and cached-view cleanup remain a
server-side administrative follow-up. This does not preserve access because the
credential itself has been revoked.

## Preview Review

MkDocs was served locally on `127.0.0.1:8000` and fetched successfully. Review
confirmed:

- all seven Reference navigation entries render
- infrastructure and service tables render as HTML tables
- Current Architecture and Target Architecture are separate headings
- current and target storage headings render separately
- Longhorn displays as `Not installed / planned evaluation`

The normal Material light and dark palettes remain unchanged. No theme or
frontend redesign was part of WO-1004.

## Changed-Path Allowlist

All final changes are contained in:

```text
README.md
PROJECT_STATE.md
mkdocs.yml
docs/**
artifacts/WO-1004/**
work-orders/WO-1004-documentation-architecture-reference-refresh.md
```

These paths are within the work-order allowlist. No file under `ansible/`,
`kubernetes/`, `requirements/` or `scripts/` changed.

The kubeconfig removal, ignore rule and permission hardening are intentionally
isolated in security PR #15 and are not part of the WO-1004 changed-path set.

## Unresolved Findings

- ADR-0003 status remains Proposed although K3s is implemented.
- ADR-0007 remains an empty tracked source file.
- Runtime versions not controlled by Git remain Not pinned or Pending
  verification in the Software Inventory.
- Exact router and management-workstation hardware models remain Pending
  verification.

## Final Result

PASS after review remediation
