#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/pki/verify-chain.sh [--help]

Verifies the HomeLab issuing CA chains against the Root CA.
EOF
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_tools openssl realpath
assert_pki_dir_outside_repo
require_file "${ROOT_CERT}"
require_file "${SERVER_CA_CERT}"
require_file "${CLIENT_CA_CERT}"

verify_chain "${ROOT_CERT}" "${SERVER_CA_CERT}"
verify_chain "${ROOT_CERT}" "${CLIENT_CA_CERT}"
