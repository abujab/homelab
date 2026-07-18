#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

kubeconfig="${KUBECONFIG:-ansible/kubeconfig}"
namespace="cert-manager"
name="homelab-server-ca"

usage() {
  cat <<'EOF'
Usage: scripts/pki/create-server-ca-secret.sh [--kubeconfig PATH] [--namespace NAME] [--name NAME]

Creates or updates the cert-manager CA Secret from the external PKI directory.
The generated Secret manifest is streamed to kubectl and is not written to Git.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kubeconfig) kubeconfig="${2:-}"; shift 2 ;;
    --namespace) namespace="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

require_tools openssl kubectl realpath
assert_pki_dir_outside_repo
require_file "${SERVER_CA_CERT}"
require_file "${SERVER_CA_KEY}"
require_file "${SERVER_CA_CHAIN}"
verify_key_matches_cert "${SERVER_CA_CERT}" "${SERVER_CA_KEY}"

tmp_secret="$(make_temp_file)"
trap 'rm -f "${tmp_secret}"' EXIT

kubectl --kubeconfig "${kubeconfig}" create secret generic "${name}" \
  --namespace "${namespace}" \
  --from-file=tls.crt="${SERVER_CA_CHAIN}" \
  --from-file=tls.key="${SERVER_CA_KEY}" \
  --from-file=ca.crt="${ROOT_CERT}" \
  --dry-run=client \
  -o yaml > "${tmp_secret}"

kubectl --kubeconfig "${kubeconfig}" apply -f "${tmp_secret}"
