# Development Workflow

---

## Purpose

This document defines the HomeLab work-order, pull-request, architecture-review
and release workflow.

## Scope

It covers implementation branches, validation, work-order archival,
implementation review and separate review-record archival. Work-order-specific
acceptance criteria remain in the active work order.

## Background

Git is the source of truth, but a commit alone does not establish architectural
approval. HomeLab separates implementation review from the later archival of
that review so the approval record can identify the exact reviewed commit.

## Architecture / Implementation

```text
Idea
  -> ADR when required
  -> approved work order
  -> implementation branch
  -> implementation, documentation and evidence
  -> validation
  -> archive completed work order and update PROJECT_STATE.md
  -> implementation pull request
  -> architecture review
  -> merge
  -> review-archive branch
  -> review-archive pull request
  -> merge
  -> release
```

### Implementation pull request

1. Create a branch named for the approved work order.
2. Keep `work-orders/CURRENT.md` as the active specification while work runs.
3. Implement only allowed paths and produce the required evidence.
4. Run all acceptance checks.
5. After validation passes, set the work order to Complete, archive it by ID,
   remove `CURRENT.md` and update `PROJECT_STATE.md`.
6. Commit intentionally, push the branch and open the implementation pull
   request.

### Architecture review archive

After the implementation pull request is approved and merged, create a
dedicated archive branch from the updated default branch:

```bash
git switch main
git pull --ff-only
git switch -c review-archive/wo-nnnn
```

Archive the final architecture approval from the merged implementation pull
request:

```bash
scripts/archive-pr-review.sh \
  --pr <implementation-pr-number> \
  --work-order WO-NNNN-work-order-slug
```

The script verifies that the source pull request is merged, represents the
supplied work order and is not itself an archive-only pull request. It accepts
only an approval attached to the implementation pull request's final head
commit, assigns the next `AR-NNNN` identifier and records review metadata.

Commit the generated review file and open a small review-archive pull request.
Reviews of that archive pull request are not archived, which prevents a
recursive archive loop. Merge the archive pull request before creating the
release.

## Design Decisions

Implementation and review archival use separate pull requests so the reviewed
commit is immutable before its approval record is added to Git.

Work orders define scope; `PROJECT_STATE.md` defines completed reality; ADRs
define architectural rationale.

## Best Practices

- start from an approved work order
- keep unrelated changes out of the implementation branch
- record command output and acceptance evidence before archival
- do not archive a work order while validation fails
- require final-head approval for the architecture review record
- keep credentials and private review data out of generated artifacts

## Future Improvements

- automate work-order allowlist validation
- add CI checks for documentation, links and formatting
- document release creation when the release workflow changes

## Related Documents

- [Repository Structure](../overview/repository.md)
- [Architecture Review Template](architecture-review.md)
- [Decision Register](../reference/decision-register.md)
