#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REVIEWS_DIR="${PROJECT_ROOT}/reviews"

pr_number=""
repository=""
work_order=""

usage() {
  cat <<'EOF'
Usage: scripts/archive-pr-review.sh --pr NUMBER --work-order NAME [--repo OWNER/REPO]

Archives the latest approved GitHub review using the repository convention:

  reviews/AR-NNNN-WO-NNNN-description.md

Arguments:
  --pr NUMBER       Pull request number containing the approved review.
  --work-order NAME Work-order filename stem, for example
                    WO-0007-pki-tls-foundation.
  --repo OWNER/REPO GitHub repository. Defaults to the current repository.
  --help            Show this help text.

The source implementation PR must already be merged. The script refuses stale
approvals, archive-only PRs and existing work-order archives.
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_value() {
  local option="$1"
  local value="${2:-}"

  [[ -n "${value}" && "${value}" != --* ]] || die "${option} requires a value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      require_value "$1" "${2:-}"
      pr_number="$2"
      shift 2
      ;;
    --work-order)
      require_value "$1" "${2:-}"
      work_order="$2"
      shift 2
      ;;
    --repo)
      require_value "$1" "${2:-}"
      repository="$2"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ "${pr_number}" =~ ^[1-9][0-9]*$ ]] || die "--pr must be a positive number"
[[ "${work_order}" =~ ^WO-[0-9]{4}-[a-z0-9]+(-[a-z0-9]+)*$ ]] || \
  die "--work-order must match WO-NNNN-lowercase-description"
work_order_id="${work_order:0:7}"

mkdir -p "${REVIEWS_DIR}"
existing_archive="$(
  find "${REVIEWS_DIR}" -maxdepth 1 -type f \
    -name "AR-[0-9][0-9][0-9][0-9]-${work_order}.md" -print -quit
)"
[[ -z "${existing_archive}" ]] || \
  die "Review archive already exists for ${work_order}: ${existing_archive}"

command -v gh >/dev/null 2>&1 || die "Required tool not found: gh"
command -v jq >/dev/null 2>&1 || die "Required tool not found: jq"
gh auth status >/dev/null 2>&1 || die "GitHub CLI is not authenticated"

if [[ -z "${repository}" ]]; then
  repository="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"
fi
[[ "${repository}" =~ ^[^/]+/[^/]+$ ]] || die "--repo must use OWNER/REPO format"
repository_owner="${repository%%/*}"
repository_name="${repository#*/}"

read -r -d '' review_query <<'GRAPHQL' || true
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      number
      title
      state
      merged
      headRefName
      headRefOid
      mergeCommit {
        oid
      }
      files(first: 100) {
        nodes {
          path
        }
      }
      reviews(last: 100) {
        nodes {
          state
          body
          submittedAt
          author {
            login
          }
          commit {
            oid
          }
        }
      }
    }
  }
}
GRAPHQL

review_json="$(gh api graphql \
  -f query="${review_query}" \
  -f owner="${repository_owner}" \
  -f name="${repository_name}" \
  -F number="${pr_number}")"

pr_json="$(jq -cer '.data.repository.pullRequest' <<< "${review_json}")" || \
  die "Pull request not found: ${repository}#${pr_number}"

[[ "$(jq -r '.merged' <<< "${pr_json}")" == "true" ]] || \
  die "PR #${pr_number} must be merged before its review is archived"

pr_title="$(jq -r '.title' <<< "${pr_json}")"
[[ "${pr_title}" == "${work_order_id}:"* ]] || \
  die "PR #${pr_number} is not the implementation PR for ${work_order_id}"

implementation_file_count="$(jq '[.files.nodes[] | select(.path | startswith("reviews/") | not)] | length' <<< "${pr_json}")"
[[ "${implementation_file_count}" -gt 0 ]] || \
  die "PR #${pr_number} is an archive-only PR and must not itself be archived"

reviewed_head="$(jq -r '.headRefOid' <<< "${pr_json}")"
merged_commit="$(jq -er '.mergeCommit.oid' <<< "${pr_json}")" || \
  die "PR #${pr_number} has no merged commit"

approval_json="$(jq -cer --arg head "${reviewed_head}" '
  [.reviews.nodes[]
    | select(
        .state == "APPROVED"
        and .commit.oid == $head
        and (.body | length > 0)
      )]
  | sort_by(.submittedAt)
  | last
' <<< "${pr_json}")" || \
  die "PR #${pr_number} has no approval for final head ${reviewed_head}"

reviewer="$(jq -r '.author.login' <<< "${approval_json}")"
approval_timestamp="$(jq -r '.submittedAt' <<< "${approval_json}")"

review_history="$(jq -er \
  --arg reviewer "${reviewer}" \
  --arg approved_at "${approval_timestamp}" '
  [.reviews.nodes[]
    | select(
        .author.login == $reviewer
        and .submittedAt <= $approved_at
        and (.body | gsub("^\\s+|\\s+$"; "") | length >= 120)
      )]
  | sort_by(.submittedAt)
  | map(.body)
  | select(length > 0)
  | join("\n\n---\n\n")
' <<< "${pr_json}")" || \
  die "PR #${pr_number} has no substantive architecture review history"

highest_id="$(
  find "${REVIEWS_DIR}" -maxdepth 1 -type f -name 'AR-[0-9][0-9][0-9][0-9]-*.md' \
    -printf '%f\n' |
    sed -n 's/^AR-\([0-9]\{4\}\)-.*/\1/p' |
    sort -n |
    tail -n 1
)"
next_id=$((10#${highest_id:-0000} + 1))
printf -v archive_id 'AR-%04d' "${next_id}"

archive_path="${REVIEWS_DIR}/${archive_id}-${work_order}.md"
[[ ! -e "${archive_path}" ]] || die "Refusing to overwrite: ${archive_path}"

temporary_file="$(mktemp "${REVIEWS_DIR}/.${archive_id}.XXXXXX")"
trap 'rm -f "${temporary_file}"' EXIT
cat > "${temporary_file}" <<EOF
# Architecture Review Archive

- **Architecture Review:** ${archive_id}
- **Work Order:** ${work_order_id}
- **Pull Request:** ${repository}#${pr_number}
- **Reviewed Head:** \`${reviewed_head}\`
- **Merged Commit:** \`${merged_commit}\`
- **Reviewer:** ${reviewer}
- **Approved:** ${approval_timestamp}
- **Result:** Approved

---

## Review History

The final-head approval is recorded in the metadata above. Terse approval text
is intentionally omitted; the substantive reviews follow.

${review_history}
EOF
chmod 0644 "${temporary_file}"
mv "${temporary_file}" "${archive_path}"
trap - EXIT

echo "Archived approved review from PR #${pr_number}: ${archive_path}"
