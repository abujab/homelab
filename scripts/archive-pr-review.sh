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

The script refuses to archive a PR without an approved review and never
overwrites an existing archive.
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

review_json="$(gh pr view "${pr_number}" --repo "${repository}" \
  --json number,reviews,url)"

review_body="$(jq -er '
  [.reviews[] | select(.state == "APPROVED" and (.body | length > 0))]
  | sort_by(.submittedAt)
  | last
  | .body
' <<< "${review_json}")" || die "PR #${pr_number} has no approved review body"

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
printf '%s\n' "${review_body}" > "${temporary_file}"
chmod 0644 "${temporary_file}"
mv "${temporary_file}" "${archive_path}"
trap - EXIT

echo "Archived approved review from PR #${pr_number}: ${archive_path}"
