#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

common_name=""
dns_names=()
days="90"

usage() {
  cat <<'EOF'
Usage: scripts/pki/issue-server-certificate.sh --common-name NAME --dns-name NAME [--dns-name NAME...] [--days DAYS]

Issues a demonstrational server certificate from the HomeLab Server Issuing CA.
Generated material is written under HOMELAB_PKI_DIR/server-issuing/issued/NAME.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --common-name) common_name="${2:-}"; shift 2 ;;
    --dns-name) dns_names+=("${2:-}"); shift 2 ;;
    --days) days="${2:-}"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -n "${common_name}" ]] || die "--common-name is required"
[[ "${#dns_names[@]}" -gt 0 ]] || die "At least one --dns-name is required"
[[ "${days}" =~ ^[0-9]+$ ]] || die "--days must be numeric"

require_tools openssl realpath
assert_pki_dir_outside_repo
require_file "${SERVER_CA_CERT}"
require_file "${SERVER_CA_KEY}"
require_file "${ROOT_CERT}"

safe_name="${common_name//[^A-Za-z0-9._-]/_}"
out_dir="${SERVER_CA_DIR}/issued/${safe_name}"
mkdir -p "${out_dir}"
chmod 0700 "${out_dir}"

key="${out_dir}/${safe_name}.key"
csr="${out_dir}/${safe_name}.csr"
cert="${out_dir}/${safe_name}.crt"
chain="${out_dir}/${safe_name}-full-chain.crt"
assert_absent "${key}"
assert_absent "${csr}"
assert_absent "${cert}"

tmp_ext="$(make_temp_file)"
trap 'rm -f "${tmp_ext}"' EXIT

cat "${SCRIPT_DIR}/config/profiles/server-certificate.cnf" > "${tmp_ext}"
{
  echo "subjectAltName = @server_alt_names"
  echo
  echo "[ server_alt_names ]"
  index=1
  for dns in "${dns_names[@]}"; do
    [[ -n "${dns}" ]] || die "Empty --dns-name value"
    echo "DNS.${index} = ${dns}"
    index=$((index + 1))
  done
} >> "${tmp_ext}"

openssl genrsa -out "${key}" 3072
write_private_key_permissions "${key}"

openssl req -new -sha256 -key "${key}" -out "${csr}" -subj "/CN=${common_name}"
chmod 0644 "${csr}"

openssl x509 -req -sha256 -days "${days}" \
  -in "${csr}" \
  -CA "${SERVER_CA_CERT}" \
  -CAkey "${SERVER_CA_KEY}" \
  -CAcreateserial \
  -out "${cert}" \
  -extfile "${tmp_ext}" \
  -extensions server_certificate
write_public_cert_permissions "${cert}"

cat "${cert}" "${SERVER_CA_CHAIN}" > "${chain}"
write_public_cert_permissions "${chain}"

verify_key_matches_cert "${cert}" "${key}"
openssl verify -purpose sslserver -CAfile "${ROOT_CERT}" -untrusted "${SERVER_CA_CERT}" "${cert}"
print_fingerprint "${cert}"
