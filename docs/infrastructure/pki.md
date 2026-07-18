# PKI

---

## Purpose

This document describes the HomeLab private Public Key Infrastructure and TLS
certificate automation model.

## Scope

This document covers:

- the HomeLab Root CA
- the Server Issuing CA
- the Client Issuing CA
- cert-manager integration
- Traefik TLS termination
- trust distribution requirements

This document does not cover public ACME, internet exposure, mTLS enforcement
or application login with client certificates.

## Background

HomeLab uses internal `home.arpa` names. These names are intentionally private,
so public certificate authorities cannot issue publicly trusted certificates for
them.

HomeLab therefore uses a private two-tier PKI:

```text
HomeLab Root CA
├── HomeLab Server Issuing CA
└── HomeLab Client Issuing CA
```

This hierarchy contains three CA certificates, but it is not a three-tier PKI.
The Server and Client Issuing CAs are siblings. Neither issuing CA signs the
other.

## Architecture / Implementation

Trust flow for server certificates:

```text
test.home.arpa certificate
        |
        v
HomeLab Server Issuing CA
        |
        v
HomeLab Root CA
```

The Root CA is generated on the management workstation with an encrypted private
key. It remains offline except when signing or replacing issuing CAs.

The Server Issuing CA signs server TLS certificates for HomeLab services. Its
certificate and key are imported into Kubernetes as the cert-manager CA issuer
Secret named `homelab-server-ca` in the `cert-manager` namespace.

The Client Issuing CA is reserved for future user, device and workload client
certificates. It is not imported into Kubernetes during this work order.

Current certificate automation:

| Component | Value |
|-----------|-------|
| Tool | cert-manager |
| Chart source | `oci://quay.io/jetstack/charts/cert-manager` |
| Chart version | `v1.21.0` |
| App version | `v1.21.0` |
| Namespace | `cert-manager` |
| Issuer | `ClusterIssuer/homelab-server-ca` |
| Test certificate | `Certificate/test-home-arpa` |
| TLS Secret | `ingress/test-home-arpa-tls` |
| Leaf duration | 90 days |
| Renewal window | 30 days before expiry |

Traefik terminates TLS for `test.home.arpa` by using the cert-manager managed
TLS Secret. HTTP requests on port `80` redirect to HTTPS on port `443`.

## Design Decisions

The Root CA is excluded from Kubernetes so routine certificate issuance cannot
expose the trust anchor.

Only the Server Issuing CA enters Kubernetes because cert-manager needs a
signing key to automate server certificates.

The Client Issuing CA remains separate so future mTLS and client identity work
does not share the same authority used for server TLS.

Leaf certificates use DNS Subject Alternative Names. Common Name alone is not a
valid HomeLab issuance policy.

## Best Practices

- keep CA private keys outside Git
- keep generated Kubernetes Secret manifests outside Git
- verify Root CA fingerprints before installing trust
- use short-lived server certificates
- back up CA keys, certificates, databases and OpenSSL configuration together
- use `scripts/pki/inspect-certificate.sh` before distributing certificates
- do not use `curl --insecure` or browser exceptions as permanent fixes

## Future Improvements

- client certificate issuance policy
- mTLS for selected administrative services
- issuing CA replacement runbooks
- optional trust-manager evaluation for Kubernetes workloads
- dedicated secrets-management integration

## Related Documents

- [Certificate Operations](../operations/certificates.md)
- [Ingress](ingress.md)
- [Security](security.md)
- [ADR-0011 PKI and TLS Foundation](../decisions/ADR-0011-pki-and-tls-foundation.md)
