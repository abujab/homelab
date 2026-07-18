#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/pki/inspect-certificate.sh CERTIFICATE

Prints certificate details, including subject, issuer, dates, fingerprint,
constraints, key usages and SANs when present.
EOF
}

if [[ "${1:-}" == "--help" || $# -ne 1 ]]; then
  usage
  [[ "${1:-}" == "--help" ]] && exit 0
  exit 1
fi

openssl x509 -in "$1" -noout -subject -issuer -dates -fingerprint -sha256
openssl x509 -in "$1" -noout -text
