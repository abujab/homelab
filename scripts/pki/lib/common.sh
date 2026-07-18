#!/usr/bin/env bash

set -euo pipefail

umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOMELAB_PKI_DIR="${HOMELAB_PKI_DIR:-${HOME}/PKI/homelab}"

ROOT_DIR="${HOMELAB_PKI_DIR}/root"
SERVER_CA_DIR="${HOMELAB_PKI_DIR}/server-issuing"
CLIENT_CA_DIR="${HOMELAB_PKI_DIR}/client-issuing"
TRUST_DIR="${HOMELAB_PKI_DIR}/trust"

ROOT_KEY="${ROOT_DIR}/private/homelab-root-ca.key"
ROOT_CERT="${ROOT_DIR}/certs/homelab-root-ca.crt"
SERVER_CA_KEY="${SERVER_CA_DIR}/private/homelab-server-issuing-ca.key"
SERVER_CA_CERT="${SERVER_CA_DIR}/certs/homelab-server-issuing-ca.crt"
SERVER_CA_CHAIN="${SERVER_CA_DIR}/certs/homelab-server-issuing-ca-chain.crt"
CLIENT_CA_KEY="${CLIENT_CA_DIR}/private/homelab-client-issuing-ca.key"
CLIENT_CA_CERT="${CLIENT_CA_DIR}/certs/homelab-client-issuing-ca.crt"
CLIENT_CA_CHAIN="${CLIENT_CA_DIR}/certs/homelab-client-issuing-ca-chain.crt"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

require_tools() {
  local tool
  for tool in "$@"; do
    command -v "${tool}" >/dev/null 2>&1 || die "Required tool not found: ${tool}"
  done
}

real_path() {
  realpath -m "$1"
}

assert_pki_dir_outside_repo() {
  local repo pki
  repo="$(real_path "${PROJECT_ROOT}")"
  pki="$(real_path "${HOMELAB_PKI_DIR}")"

  case "${pki}" in
    "${repo}"|"${repo}"/*)
      die "HOMELAB_PKI_DIR resolves inside the Git repository: ${pki}"
      ;;
  esac
}

ensure_ca_layout() {
  local ca_dir="$1"
  mkdir -p \
    "${ca_dir}/private" \
    "${ca_dir}/certs" \
    "${ca_dir}/csr" \
    "${ca_dir}/database" \
    "${ca_dir}/issued"

  chmod 0700 "${ca_dir}" "${ca_dir}/private"
  touch "${ca_dir}/database/index.txt"
  test -f "${ca_dir}/database/serial" || printf '1000\n' > "${ca_dir}/database/serial"
  chmod 0600 "${ca_dir}/database/index.txt" "${ca_dir}/database/serial"
}

ensure_root_layout() {
  mkdir -p "${ROOT_DIR}/backups" "${TRUST_DIR}"
  ensure_ca_layout "${ROOT_DIR}"
}

ensure_all_layouts() {
  ensure_root_layout
  ensure_ca_layout "${SERVER_CA_DIR}"
  ensure_ca_layout "${CLIENT_CA_DIR}"
}

assert_absent() {
  local path="$1"
  test ! -e "${path}" || die "Refusing to overwrite existing file: ${path}"
}

require_file() {
  local path="$1"
  test -f "${path}" || die "Required file not found: ${path}"
}

write_private_key_permissions() {
  local path="$1"
  chmod 0600 "${path}"
}

write_public_cert_permissions() {
  local path="$1"
  chmod 0644 "${path}"
}

verify_key_matches_cert() {
  local cert="$1"
  local key="$2"
  local cert_mod key_mod

  cert_mod="$(openssl x509 -noout -modulus -in "${cert}" | openssl sha256)"
  key_mod="$(openssl rsa -noout -modulus -in "${key}" 2>/dev/null | openssl sha256)"
  test "${cert_mod}" = "${key_mod}" || die "Certificate and private key do not match"
}

print_fingerprint() {
  local cert="$1"
  openssl x509 -in "${cert}" -noout -subject -issuer -dates -fingerprint -sha256
}

verify_chain() {
  local ca_file="$1"
  local cert="$2"
  openssl verify -CAfile "${ca_file}" "${cert}"
}

make_temp_file() {
  mktemp "${TMPDIR:-/tmp}/homelab-pki.XXXXXX"
}
