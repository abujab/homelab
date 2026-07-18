#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/pki/create-server-issuing-ca.sh [--help]

Creates the HomeLab Server Issuing CA signed by the offline Root CA.
The Root CA key passphrase is entered through OpenSSL's interactive prompt.
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
assert_absent "${SERVER_CA_KEY}"
assert_absent "${SERVER_CA_CERT}"

csr="${SERVER_CA_DIR}/csr/homelab-server-issuing-ca.csr"
assert_absent "${csr}"

info "Creating Server Issuing CA private key"
openssl genrsa -out "${SERVER_CA_KEY}" 4096
write_private_key_permissions "${SERVER_CA_KEY}"

info "Creating Server Issuing CA CSR"
openssl req -new -sha256 \
  -key "${SERVER_CA_KEY}" \
  -out "${csr}" \
  -subj "/C=DE/O=Abdul HomeLab/OU=PKI/CN=Abdul HomeLab Server Issuing CA"
chmod 0644 "${csr}"

info "Signing Server Issuing CA with Root CA"
x509_args=(-req -sha256 -days 3650)
if [[ -n "${HOMELAB_ROOT_CA_PASSIN:-}" ]]; then
  x509_args+=(-passin "${HOMELAB_ROOT_CA_PASSIN}")
fi
openssl x509 "${x509_args[@]}" \
  -in "${csr}" \
  -CA "${ROOT_CERT}" \
  -CAkey "${ROOT_KEY}" \
  -CAcreateserial \
  -out "${SERVER_CA_CERT}" \
  -extfile "${SCRIPT_DIR}/config/profiles/server-issuing-ca.cnf" \
  -extensions server_issuing_ca
write_public_cert_permissions "${SERVER_CA_CERT}"

cat "${SERVER_CA_CERT}" "${ROOT_CERT}" > "${SERVER_CA_CHAIN}"
write_public_cert_permissions "${SERVER_CA_CHAIN}"

verify_key_matches_cert "${SERVER_CA_CERT}" "${SERVER_CA_KEY}"
verify_chain "${ROOT_CERT}" "${SERVER_CA_CERT}"
info "Server Issuing CA certificate"
print_fingerprint "${SERVER_CA_CERT}"
