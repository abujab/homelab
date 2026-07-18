#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: scripts/pki/create-root-ca.sh [--help]

Creates the encrypted offline HomeLab Root CA under HOMELAB_PKI_DIR.
Default HOMELAB_PKI_DIR: ${HOME}/PKI/homelab

The private key passphrase is entered through OpenSSL's interactive prompt.
For controlled automation only, HOMELAB_ROOT_CA_PASSOUT and
HOMELAB_ROOT_CA_PASSIN may name OpenSSL passphrase sources such as env:VAR.
Existing Root CA files are never overwritten.
EOF
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_tools openssl realpath
assert_pki_dir_outside_repo
ensure_root_layout
assert_absent "${ROOT_KEY}"
assert_absent "${ROOT_CERT}"

info "Creating encrypted HomeLab Root CA private key"
genrsa_args=(-aes256 -out "${ROOT_KEY}" 4096)
if [[ -n "${HOMELAB_ROOT_CA_PASSOUT:-}" ]]; then
  genrsa_args=(-aes256 -passout "${HOMELAB_ROOT_CA_PASSOUT}" -out "${ROOT_KEY}" 4096)
fi
openssl genrsa "${genrsa_args[@]}"
write_private_key_permissions "${ROOT_KEY}"

info "Creating self-signed HomeLab Root CA certificate"
req_args=(-new -x509 -sha256 -days 7300)
if [[ -n "${HOMELAB_ROOT_CA_PASSIN:-}" ]]; then
  req_args+=(-passin "${HOMELAB_ROOT_CA_PASSIN}")
fi
openssl req "${req_args[@]}" \
  -key "${ROOT_KEY}" \
  -out "${ROOT_CERT}" \
  -config "${SCRIPT_DIR}/config/profiles/root-ca.cnf" \
  -extensions root_ca
write_public_cert_permissions "${ROOT_CERT}"

cp "${ROOT_CERT}" "${TRUST_DIR}/homelab-root-ca.crt"
write_public_cert_permissions "${TRUST_DIR}/homelab-root-ca.crt"

info "Root CA certificate"
print_fingerprint "${ROOT_CERT}"

info "Backup required: ${ROOT_KEY}, ${ROOT_CERT}, ${ROOT_DIR}/database, and the Root CA passphrase recovery record"
