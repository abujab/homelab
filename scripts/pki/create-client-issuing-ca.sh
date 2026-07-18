#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/pki/create-client-issuing-ca.sh [--help]

Creates the HomeLab Client Issuing CA signed independently by the Root CA.
The Client Issuing CA remains outside Kubernetes.
For controlled automation only, HOMELAB_ROOT_CA_PASSIN may name an OpenSSL
passphrase source such as env:VAR.
EOF
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_tools openssl realpath
assert_pki_dir_outside_repo
ensure_all_layouts
require_file "${ROOT_CERT}"
require_file "${ROOT_KEY}"
assert_absent "${CLIENT_CA_KEY}"
assert_absent "${CLIENT_CA_CERT}"

csr="${CLIENT_CA_DIR}/csr/homelab-client-issuing-ca.csr"
assert_absent "${csr}"

info "Creating Client Issuing CA private key"
openssl genrsa -out "${CLIENT_CA_KEY}" 4096
write_private_key_permissions "${CLIENT_CA_KEY}"

info "Creating Client Issuing CA CSR"
openssl req -new -sha256 \
  -key "${CLIENT_CA_KEY}" \
  -out "${csr}" \
  -subj "/C=DE/O=Abdul HomeLab/OU=PKI/CN=Abdul HomeLab Client Issuing CA"
chmod 0644 "${csr}"

info "Signing Client Issuing CA with Root CA"
x509_args=(-req -sha256 -days 3650)
if [[ -n "${HOMELAB_ROOT_CA_PASSIN:-}" ]]; then
  x509_args+=(-passin "${HOMELAB_ROOT_CA_PASSIN}")
fi
openssl x509 "${x509_args[@]}" \
  -in "${csr}" \
  -CA "${ROOT_CERT}" \
  -CAkey "${ROOT_KEY}" \
  -CAcreateserial \
  -out "${CLIENT_CA_CERT}" \
  -extfile "${SCRIPT_DIR}/config/profiles/client-issuing-ca.cnf" \
  -extensions client_issuing_ca
write_public_cert_permissions "${CLIENT_CA_CERT}"

cat "${CLIENT_CA_CERT}" "${ROOT_CERT}" > "${CLIENT_CA_CHAIN}"
write_public_cert_permissions "${CLIENT_CA_CHAIN}"

verify_key_matches_cert "${CLIENT_CA_CERT}" "${CLIENT_CA_KEY}"
verify_chain "${ROOT_CERT}" "${CLIENT_CA_CERT}"
info "Client Issuing CA certificate"
print_fingerprint "${CLIENT_CA_CERT}"
