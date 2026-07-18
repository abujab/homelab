#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

common_name=""
days="90"

usage() {
  cat <<'EOF'
Usage: scripts/pki/issue-client-certificate.sh --common-name NAME [--days DAYS]

Issues a demonstrational client certificate from the HomeLab Client Issuing CA.
Generated material is written under HOMELAB_PKI_DIR/client-issuing/issued/NAME.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --common-name) common_name="${2:-}"; shift 2 ;;
    --days) days="${2:-}"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "${common_name}" ]] || die "--common-name is required"
[[ "${days}" =~ ^[0-9]+$ ]] || die "--days must be numeric"

require_tools openssl realpath
assert_pki_dir_outside_repo
require_file "${CLIENT_CA_CERT}"
require_file "${CLIENT_CA_KEY}"
require_file "${ROOT_CERT}"

safe_name="${common_name//[^A-Za-z0-9._-]/_}"
out_dir="${CLIENT_CA_DIR}/issued/${safe_name}"
mkdir -p "${out_dir}"
chmod 0700 "${out_dir}"

key="${out_dir}/${safe_name}.key"
csr="${out_dir}/${safe_name}.csr"
cert="${out_dir}/${safe_name}.crt"
chain="${out_dir}/${safe_name}-full-chain.crt"
assert_absent "${key}"
assert_absent "${csr}"
assert_absent "${cert}"

openssl genrsa -out "${key}" 3072
write_private_key_permissions "${key}"

openssl req -new -sha256 -key "${key}" -out "${csr}" -subj "/CN=${common_name}"
chmod 0644 "${csr}"

openssl x509 -req -sha256 -days "${days}" \
  -in "${csr}" \
  -CA "${CLIENT_CA_CERT}" \
  -CAkey "${CLIENT_CA_KEY}" \
  -CAcreateserial \
  -out "${cert}" \
  -extfile "${SCRIPT_DIR}/config/profiles/client-certificate.cnf" \
  -extensions client_certificate
write_public_cert_permissions "${cert}"

cat "${cert}" "${CLIENT_CA_CHAIN}" > "${chain}"
write_public_cert_permissions "${chain}"

verify_key_matches_cert "${cert}" "${key}"
openssl verify -purpose sslclient -CAfile "${ROOT_CERT}" -untrusted "${CLIENT_CA_CERT}" "${cert}"
print_fingerprint "${cert}"
