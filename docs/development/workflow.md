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
Archive Approved Review
    ↓
Merge
    ↓
Release
    ↓
PROJECT_STATE update

Approved architecture reviews are archived from GitHub with:

```bash
scripts/archive-pr-review.sh \
  --pr 8 \
  --work-order WO-0007-pki-tls-foundation
```

The script selects the latest non-empty approved review, assigns the next
`AR-NNNN` identifier and writes the review under `reviews/`. It refuses to
archive a pull request without an approval and does not overwrite existing
archives.
