# ADR-0011 PKI and TLS Foundation

**Status:** Accepted

## Context

HomeLab uses the private `home.arpa` namespace. Public ACME certificate
authorities cannot issue publicly trusted certificates for these internal names,
and the platform needs trusted HTTPS before sensitive internal applications are
published through ingress.

## Decision

Create a private two-tier HomeLab PKI:

```text
HomeLab Root CA
├── HomeLab Server Issuing CA
└── HomeLab Client Issuing CA
```

The Root CA is an encrypted offline trust anchor that signs issuing CAs only.
The Server Issuing CA signs TLS server certificates and is imported into
Kubernetes as a cert-manager CA issuer Secret. The Client Issuing CA is created
separately and kept offline for future client authentication and mTLS work.

cert-manager is selected for automated Kubernetes server-certificate lifecycle.
Traefik remains the ingress controller and terminates TLS for
`test.home.arpa`. HTTP is redirected to HTTPS at the Traefik entry point.

Leaf server certificates are short lived and use DNS SANs. Clients must install
and verify the HomeLab Root CA certificate before trusting HomeLab HTTPS
services.

## Alternatives Considered

### Public ACME certificates

Advantages:

- broad client trust without private root distribution
- mature automation ecosystem

Disadvantages:

- not available for private `home.arpa` names
- would require public DNS or public exposure patterns outside this work order

### Self-signed per-service certificates

Advantages:

- simple to create for one service

Disadvantages:

- does not scale operationally
- weak lifecycle management
- each certificate would require separate trust decisions

### Private PKI with cert-manager

Advantages:

- works with internal names
- centralizes trust in one Root CA
- keeps the Root CA offline
- automates Kubernetes server-certificate issuance and renewal
- preserves a separate future client-certificate path

Disadvantages:

- requires root certificate distribution to clients
- CA backup and compromise response become critical operations

## Consequences

Positive:

- HomeLab can serve trusted HTTPS for internal ingress services
- routine server certificate renewal does not require the Root CA
- the Client Issuing CA is ready for future mTLS without mixing roles

Negative:

- every trusted client must install the Root CA
- compromise of the Server Issuing CA requires certificate replacement
- compromise of the Root CA requires rebuilding and redistributing the PKI

## References

- [PKI](../infrastructure/pki.md)
- [Certificate Operations](../operations/certificates.md)
- [ADR-0010 Ingress Foundation](ADR-0010-ingress-foundation.md)

https://cert-manager.io/docs/installation/helm/

https://cert-manager.io/docs/configuration/ca/
