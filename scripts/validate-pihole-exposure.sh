#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-${PROJECT_ROOT}/ansible/kubeconfig}"
ROOT_CA_CERT="${HOMELAB_ROOT_CA_CERT:-${HOME}/PKI/homelab/root/certs/homelab-root-ca.crt}"
NAMESPACE="networking"
DNS_SERVICE="pihole"
WEB_SERVICE="pihole-web"
HOSTNAME="pihole.home.arpa"
DNS_IP="192.168.68.200"
INGRESS_IP="192.168.68.201"

usage() {
  cat <<'EOF'
Usage: scripts/validate-pihole-exposure.sh [--help]

Validates the deployed Pi-hole DNS and Web exposure architecture.

Environment overrides:
  KUBECONFIG_PATH       Kubernetes kubeconfig path.
  HOMELAB_ROOT_CA_CERT  Public HomeLab Root CA certificate path.
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

if [[ "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
[[ $# -eq 0 ]] || die "Unknown argument: $1"

for tool in kubectl jq dig curl openssl; do
  command -v "${tool}" >/dev/null 2>&1 || die "Required tool not found: ${tool}"
done
[[ -f "${KUBECONFIG_PATH}" ]] || die "Kubeconfig not found: ${KUBECONFIG_PATH}"
[[ -f "${ROOT_CA_CERT}" ]] || die "Public Root CA certificate not found: ${ROOT_CA_CERT}"

kubectl_cmd=(kubectl --kubeconfig "${KUBECONFIG_PATH}")

info "Validating DNS LoadBalancer Service"
dns_service="$("${kubectl_cmd[@]}" get service "${DNS_SERVICE}" -n "${NAMESPACE}" -o json)"
jq -e --arg ip "${DNS_IP}" '
  .spec.type == "LoadBalancer"
  and .spec.loadBalancerIP == $ip
  and ([.spec.ports[] | select(.port == 53 and .protocol == "TCP")] | length == 1)
  and ([.spec.ports[] | select(.port == 53 and .protocol == "UDP")] | length == 1)
  and ([.spec.ports[] | select(.port == 80 or .port == 443)] | length == 0)
' <<< "${dns_service}" >/dev/null || die "DNS Service exposure does not match the required model"

info "Validating Web ClusterIP Service"
web_service="$("${kubectl_cmd[@]}" get service "${WEB_SERVICE}" -n "${NAMESPACE}" -o json)"
jq -e '
  .spec.type == "ClusterIP"
  and (.spec.ports | length == 1)
  and .spec.ports[0].port == 80
  and .spec.ports[0].protocol == "TCP"
' <<< "${web_service}" >/dev/null || die "Web Service exposure does not match the required model"

info "Validating Ingress routing and TLS"
ingress="$("${kubectl_cmd[@]}" get ingress pihole -n "${NAMESPACE}" -o json)"
jq -e --arg host "${HOSTNAME}" --arg secret "pihole-home-arpa-tls" '
  .spec.ingressClassName == "traefik"
  and .spec.rules[0].host == $host
  and .spec.rules[0].http.paths[0].backend.service.name == "pihole-web"
  and .spec.rules[0].http.paths[0].backend.service.port.name == "http"
  and .spec.tls[0].secretName == $secret
  and (.spec.tls[0].hosts | index($host) != null)
' <<< "${ingress}" >/dev/null || die "Pi-hole Ingress does not match the required model"

info "Validating certificate readiness and TLS Secret"
certificate="$("${kubectl_cmd[@]}" get certificate pihole-home-arpa -n "${NAMESPACE}" -o json)"
jq -e '[.status.conditions[]? | select(.type == "Ready" and .status == "True")] | length == 1' \
  <<< "${certificate}" >/dev/null || die "Pi-hole certificate is not Ready"
"${kubectl_cmd[@]}" get secret pihole-home-arpa-tls -n "${NAMESPACE}" >/dev/null

info "Validating Pi-hole DNS over UDP and TCP"
udp_answer="$(dig @"${DNS_IP}" "${HOSTNAME}" A +short)"
tcp_answer="$(dig +tcp @"${DNS_IP}" test.home.arpa A +short)"
[[ "${udp_answer}" == "${INGRESS_IP}" ]] || die "${HOSTNAME} resolved to ${udp_answer:-no address}, expected ${INGRESS_IP}"
[[ "${tcp_answer}" == "${INGRESS_IP}" ]] || die "TCP DNS query failed or returned ${tcp_answer:-no address}"

info "Validating HTTPS and HTTP redirect"
curl --noproxy '*' --fail --silent --show-error \
  --resolve "${HOSTNAME}:443:${INGRESS_IP}" \
  --cacert "${ROOT_CA_CERT}" \
  "https://${HOSTNAME}/admin/" >/dev/null || die "Trusted Pi-hole HTTPS validation failed"
redirect_location="$(curl --noproxy '*' --silent --show-error --head \
  --resolve "${HOSTNAME}:80:${INGRESS_IP}" \
  "http://${HOSTNAME}/" | awk 'BEGIN {IGNORECASE=1} /^location:/ {gsub("\r", "", $2); print $2}')"
[[ "${redirect_location}" == "https://${HOSTNAME}/" ]] || die "HTTP did not redirect to the expected HTTPS URL"

info "Validating that the DNS LoadBalancer no longer exposes HTTP"
if curl --noproxy '*' --silent --show-error --connect-timeout 5 \
  "http://${DNS_IP}/admin/" >/dev/null 2>&1; then
  die "Pi-hole Web UI remains reachable through ${DNS_IP}:80"
fi

info "Pi-hole exposure validation passed"
