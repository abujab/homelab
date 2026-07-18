Lifecycle

Idea
    ↓
ADR (if needed)
    ↓
Work Order
    ↓
Codex Implementation
    ↓
Pull Request
    ↓
Architecture Review
    ↓
Merge
    ↓
Archive Approved Review on Separate Branch
    ↓
Review-Archive Pull Request
    ↓
Release
    ↓
PROJECT_STATE update

After the implementation PR is approved and merged, create a dedicated archive
branch from the updated default branch:

```bash
git switch main
git pull --ff-only
git switch -c review-archive/wo-0007
```

Archive the final architecture approval from the merged implementation PR:

```bash
scripts/archive-pr-review.sh \
  --pr 8 \
  --work-order WO-0007-pki-tls-foundation
```

The script verifies that the source PR is merged, is an implementation PR for
the supplied work order and is not an archive-only PR. It accepts only an
approval attached to the implementation PR's final head commit, assigns the
next `AR-NNNN` identifier and records the reviewed head, merge commit, reviewer
and approval timestamp with the review body.

Commit the generated file and open a small review-archive PR. Reviews of that
archive PR are not archived: archive-only PRs are explicitly rejected as source
PRs, preventing a recursive archive loop. Merge the archive PR before creating
the release.
