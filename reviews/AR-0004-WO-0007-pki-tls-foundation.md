## Architecture Re-Review — WO-0007 PKI and TLS Foundation

**Result: Approved**

The requested security hardening changes have been addressed.

### Resolved findings

- Server certificate Common Names and DNS SANs are now strictly validated before
  being inserted into OpenSSL subject or extension syntax.
- Client certificate Common Names use an appropriately restricted validation
  rule.
- The broad repository-wide `*.secret.yaml` and `*-secret.yaml` ignore patterns
  have been removed.
- Existing protection for private keys and generated PKI artifacts remains in
  place.

The overall implementation remains aligned with WO-0007:

- offline encrypted Root CA;
- separate Server and Client Issuing CAs;
- only the Server Issuing CA provided to cert-manager;
- automated short-lived server certificates;
- Traefik TLS termination;
- HTTP-to-HTTPS redirection;
- certificate reissuance and Secret rotation validation;
- documented trust distribution, backup and recovery.

**Final verdict: Approve for merge and release as `v0.7.0`.**
