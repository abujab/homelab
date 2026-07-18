# WORK ORDER

**ID:** WO-0007
**Title:** PKI and TLS Foundation
**Status:** Complete
**Primary Agent:** Codex
**Architect:** ChatGPT
**Owner:** Abdul Jabbar
**Target Release:** v0.7.0

---

## Objective

Establish the HomeLab private Public Key Infrastructure and automated TLS
certificate lifecycle.

The implementation shall provide:

- an offline HomeLab Root CA
- a Server Issuing CA for TLS server certificates
- a separate Client Issuing CA reserved for future client authentication and mTLS
- safe, repeatable PKI-generation tooling
- cert-manager deployed in Kubernetes
- automatic server-certificate issuance through the Server Issuing CA
- trusted HTTPS through Traefik
- automatic HTTP-to-HTTPS redirection
- documented CA distribution, backup and recovery procedures

The existing `test.home.arpa` ingress route shall be used to prove the complete
certificate lifecycle.

---

## Terminology

The implemented hierarchy is:

```text
HomeLab Root CA
├── HomeLab Server Issuing CA
└── HomeLab Client Issuing CA
```

This is a two-tier PKI hierarchy with separate issuing authorities.

The repository and documentation must not incorrectly describe it as a
three-tier hierarchy.

The CA roles are:

| CA | Purpose |
|----|---------|
| Root CA | Offline trust anchor; signs issuing CAs only |
| Server Issuing CA | Signs TLS server certificates for `*.home.arpa` services |
| Client Issuing CA | Reserved for future user, device and workload client certificates |

The two issuing CAs are siblings. Neither signs the other.

---

## Current State

The HomeLab currently provides:

- Pi-hole DNS at `192.168.68.200`
- Traefik ingress at `192.168.68.201`
- `test.home.arpa` resolving to `192.168.68.201`
- HTTP host-based routing through Traefik
- K3s packaged Traefik disabled
- K3s ServiceLB disabled
- MetalLB as the LoadBalancer implementation
- no trusted internal certificate authority
- no automatic certificate issuance
- no HTTP-to-HTTPS redirect
- no trusted HTTPS route for `test.home.arpa`

The Root CA private key must never enter Kubernetes or Git.

---

## Architecture

```text
                        Offline management workstation
                  ┌────────────────────────────────────┐
                  │                                    │
                  │       HomeLab Root CA               │
                  │       encrypted private key         │
                  │                                    │
                  └───────────────┬────────────────────┘
                                  │ signs
                 ┌────────────────┴────────────────┐
                 │                                 │
                 ▼                                 ▼
      Server Issuing CA                  Client Issuing CA
      certificate + key                  certificate + key
                 │                                 │
                 │ imported into Kubernetes        │ kept offline
                 ▼                                 │ initially
           cert-manager                            │
                 │                                 │
                 ▼                                 │
        Server Certificate                         │
        test.home.arpa                             │
                 │                                 │
                 ▼                                 │
        Kubernetes TLS Secret                      │
                 │                                 │
                 ▼                                 │
              Traefik                              │
                 │                                 │
                 ▼                                 │
       https://test.home.arpa             future client/mTLS work
```

### Trust flow

A client trusts the HomeLab Root CA.

Traefik presents:

```text
test.home.arpa certificate
        ↓
HomeLab Server Issuing CA
        ↓
HomeLab Root CA
```

The browser or operating system validates the chain to the trusted Root CA.

---

## Design Decisions

### Root CA

The Root CA shall:

- be generated on the Arch Linux management workstation
- use an encrypted private key
- be stored outside the Git repository
- remain offline except when signing or replacing issuing CAs
- never be copied into Kubernetes
- never sign application certificates directly
- have `CA:TRUE`
- have a constrained path length suitable for signing issuing CAs only
- use `keyCertSign` and `cRLSign`
- have a long but documented lifetime

### Server Issuing CA

The Server Issuing CA shall:

- be signed by the Root CA
- be dedicated to TLS server-certificate issuance
- have `CA:TRUE`
- have `pathLenConstraint:0`
- use `keyCertSign` and `cRLSign`
- have a shorter validity period than the Root CA
- be imported into Kubernetes for cert-manager
- be backed up securely outside Kubernetes
- not be committed to Git

Its leaf-certificate profile shall require:

- `CA:FALSE`
- `digitalSignature`
- appropriate key encipherment or key-agreement usage
- `extendedKeyUsage = serverAuth`
- DNS Subject Alternative Names
- no reliance on Common Name alone

### Client Issuing CA

The Client Issuing CA shall:

- be signed separately by the Root CA
- be dedicated to future client identity certificates
- have `CA:TRUE`
- have `pathLenConstraint:0`
- use `keyCertSign` and `cRLSign`
- remain offline during this work order
- not be imported into Kubernetes
- not issue any production client certificate in this work order

Its future leaf-certificate profile shall require:

- `CA:FALSE`
- `digitalSignature`
- `extendedKeyUsage = clientAuth`
- identity-specific subject and SAN configuration

### cert-manager

cert-manager shall:

- be installed through its official Helm chart
- use an explicitly pinned chart version
- install required CRDs declaratively
- be managed independently of K3s packaged components
- use the Server Issuing CA through a Kubernetes Secret
- expose a `ClusterIssuer` for HomeLab server certificates
- renew certificates automatically

Do not pin a version from memory. Codex must verify a current stable version
against official cert-manager release and installation documentation and record
the selected chart and application versions.

### Traefik

Traefik shall:

- continue using MetalLB IP `192.168.68.201`
- terminate TLS for ingress applications
- redirect HTTP requests to HTTPS
- use the certificate Secret issued by cert-manager
- continue keeping its dashboard externally unexposed

---

## Scope

### Included

- reusable OpenSSL configuration and profiles
- Root CA creation tooling
- Server Issuing CA creation tooling
- Client Issuing CA creation tooling
- certificate inspection and verification tooling
- optional manual server/client leaf-certificate demonstration tooling
- cert-manager installation
- Server Issuing CA Kubernetes Secret creation procedure
- server `ClusterIssuer`
- automatic certificate issuance for `test.home.arpa`
- Traefik TLS termination
- HTTP-to-HTTPS redirection
- trusted-root distribution documentation
- CA backup and recovery documentation
- ADR-0011
- project and operational documentation
- runtime validation
- idempotency validation

### Excluded

- public Internet exposure
- public ACME or Let's Encrypt certificates
- client certificate issuance for real users or devices
- mutual TLS
- certificate-based application login
- external secrets managers
- HashiCorp Vault
- automated CA private-key rotation
- online certificate-status protocol
- full CRL distribution infrastructure
- wildcard certificates
- public DNS
- router port forwarding

---

## Existing Scripts Directory

The repository already contains a scripts directory.

Codex must inspect the current repository structure and reuse its established
conventions.

Do not create a second top-level scripts directory.

Place the PKI tooling under the existing scripts hierarchy, conceptually:

```text
scripts/
└── pki/
    ├── README.md
    ├── lib/
    │   └── common.sh
    ├── config/
    │   ├── openssl.cnf
    │   └── profiles/
    │       ├── root-ca.cnf
    │       ├── server-issuing-ca.cnf
    │       ├── client-issuing-ca.cnf
    │       ├── server-certificate.cnf
    │       └── client-certificate.cnf
    ├── create-root-ca.sh
    ├── create-server-issuing-ca.sh
    ├── create-client-issuing-ca.sh
    ├── issue-server-certificate.sh
    ├── issue-client-certificate.sh
    ├── inspect-certificate.sh
    └── verify-chain.sh
```

Adapt this layout to the existing repository convention where necessary.

The scripts must not assume that private material is stored inside the
repository.

---

## External PKI Working Directory

Private and generated PKI material shall live outside Git.

Default location:

```text
${HOME}/PKI/homelab
```

Expected runtime structure:

```text
~/PKI/homelab/
├── root/
│   ├── private/
│   ├── certs/
│   ├── csr/
│   ├── database/
│   └── backups/
├── server-issuing/
│   ├── private/
│   ├── certs/
│   ├── csr/
│   ├── database/
│   └── issued/
├── client-issuing/
│   ├── private/
│   ├── certs/
│   ├── csr/
│   ├── database/
│   └── issued/
└── trust/
```

The working directory must be overridable through an environment variable such
as:

```bash
HOMELAB_PKI_DIR="${HOME}/PKI/homelab"
```

The scripts must refuse to operate when the configured PKI directory resolves
inside the Git repository.

---

## PKI Tooling Requirements

### General requirements

Every script shall:

- use Bash with `set -euo pipefail`
- provide `--help`
- validate required tools and input
- use quoted variables
- use restrictive `umask`, preferably `077`
- fail clearly rather than partially succeeding
- avoid printing private-key material
- avoid printing passphrases
- avoid embedding secrets in command history
- use temporary files safely
- clean temporary files through traps
- have clear success and failure messages
- be documented
- be suitable for repeatable use where practical

Scripts must not silently overwrite existing keys or CA certificates.

Destructive replacement must require an explicit flag and confirmation.

### Secret input

The Root CA passphrase must not be accepted as a positional command-line
argument.

Acceptable mechanisms include:

- interactive OpenSSL prompt
- protected file descriptor
- environment-based OpenSSL passphrase source only when explicitly documented

The default workflow shall use an interactive prompt.

### File permissions

Required minimum permissions:

```text
PKI directories:       0700
private key files:     0600
public certificates:   0644
configuration files:   0644
```

Generated unencrypted issuing-CA keys require particular protection because
automation must be able to use them.

---

## OpenSSL Profiles

Use explicit OpenSSL extension profiles rather than relying on defaults.

### Root CA profile

Required properties:

```text
basicConstraints = critical, CA:TRUE, pathlen:1
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
```

The Root CA shall be self-signed.

### Issuing CA profiles

Both issuing CAs require:

```text
basicConstraints = critical, CA:TRUE, pathlen:0
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
```

Do not add `serverAuth` or `clientAuth` EKUs to an issuing CA merely to
distinguish its role.

The server/client separation is implemented through:

- separate keys and certificates
- separate CA directories and databases
- separate issuance scripts
- separate leaf-certificate profiles
- documented policy
- only the Server Issuing CA being imported into cert-manager

### Server leaf profile

Required properties:

```text
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = serverAuth
subjectAltName = supplied DNS names
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
```

Add `keyEncipherment` only when appropriate for the chosen key algorithm and
TLS compatibility requirements.

### Client leaf profile

Required properties:

```text
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
```

Client-certificate issuance remains demonstrational only during this sprint.

---

## Key Algorithms and Validity

Use explicit, documented choices.

Recommended initial baseline:

| Certificate | Key | Validity |
|-------------|-----|----------|
| Root CA | RSA 4096, encrypted | approximately 15–20 years |
| Server Issuing CA | RSA 4096 | approximately 5–10 years |
| Client Issuing CA | RSA 4096 | approximately 5–10 years |
| Server leaf certificate | RSA 2048/3072 or supported ECDSA | approximately 90 days |
| Client leaf demonstration certificate | RSA 2048/3072 or supported ECDSA | short-lived |

Codex may choose equivalent modern parameters but must document the choice and
verify compatibility with cert-manager, Traefik and common HomeLab clients.

An issuing CA must never be valid beyond its parent Root CA.

A leaf certificate must never be valid beyond its issuing CA.

---

## Root and Issuing CA Creation

### Root CA creation

The root script shall:

1. create the required protected directory layout
2. initialize any OpenSSL database files and serial numbers
3. generate an encrypted private key
4. generate a self-signed Root CA certificate using the root profile
5. inspect and verify the resulting certificate
6. export a public trust copy
7. print the certificate fingerprint
8. provide the exact backup files required
9. refuse to continue if an existing Root CA is present

Suggested identity:

```text
Common Name: Abdul HomeLab Root CA
Organization: Abdul HomeLab
Organizational Unit: PKI
Country: DE
```

Avoid requiring locality or personal-address information.

### Server Issuing CA creation

The server issuing script shall:

1. generate a private key
2. create a CSR
3. use the Root CA to sign the CSR with the issuing-CA profile
4. create the server issuing certificate
5. create a chain file containing the issuing and root certificates
6. verify the complete chain
7. show the CA constraints and fingerprint
8. return the Root CA to offline storage after signing

Suggested Common Name:

```text
Abdul HomeLab Server Issuing CA
```

### Client Issuing CA creation

Use the same controlled process but an independent key and identity:

```text
Abdul HomeLab Client Issuing CA
```

The client issuing key must remain outside Kubernetes.

---

## Manual Certificate-Issuance Demonstration

The PKI scripts shall demonstrate how issuance works independently of
cert-manager.

### Server example

The command should conceptually support:

```bash
scripts/pki/issue-server-certificate.sh \
  --common-name manual-test.home.arpa \
  --dns-name manual-test.home.arpa
```

It shall:

- create a leaf private key
- create a CSR
- sign it with the Server Issuing CA
- include the DNS SAN
- generate a full-chain certificate
- verify `serverAuth`
- verify the chain to the Root CA

This certificate is for validation only and must not be deployed as the
`test.home.arpa` production certificate.

### Client example

The command should conceptually support:

```bash
scripts/pki/issue-client-certificate.sh \
  --common-name abdul-homelab-admin
```

It shall:

- generate a separate leaf private key
- sign using the Client Issuing CA
- verify `clientAuth`
- verify the chain to the Root CA

Do not deploy or distribute this demonstration certificate.

---

## Kubernetes Repository Structure

Create or adapt:

```text
kubernetes/
└── platform/
    └── certificates/
        ├── README.md
        ├── namespace.yaml
        ├── values.yaml
        ├── issuers/
        │   └── homelab-server-ca.yaml
        └── test/
            └── certificate.yaml
```

Do not store generated CA keys, certificates containing private keys, or
Kubernetes Secret manifests with live key material in Git.

---

## cert-manager Deployment

Install cert-manager into:

```text
cert-manager
```

Pin and document:

- Helm chart version
- cert-manager application version
- CRD installation method
- source repository

Expected components include:

- cert-manager controller
- cert-manager webhook
- cert-manager cainjector

Use at least the official Helm defaults required for a small cluster, with
explicit values for any changed settings.

Do not expose cert-manager externally.

---

## Server Issuing CA Secret

Create the CA Secret at runtime, not in Git.

The Secret shall contain:

```text
tls.crt
tls.key
ca.crt
```

For the CA issuer:

- `tls.crt` shall contain the Server Issuing CA certificate
- `tls.key` shall contain its private key
- `ca.crt` shall contain the trust chain needed by consumers, as appropriate

The exact chain format must be tested against cert-manager and Traefik.

Provide a controlled script or documented command to create/update the Secret
from the external PKI directory.

Conceptually:

```bash
kubectl create secret tls homelab-server-ca \
  --namespace cert-manager \
  --cert=... \
  --key=... \
  --dry-run=client \
  -o yaml |
kubectl apply -f -
```

Do not commit the generated output.

The implementation must verify that the private key matches the certificate
before creating the Secret.

---

## ClusterIssuer

Create:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: homelab-server-ca
spec:
  ca:
    secretName: homelab-server-ca
```

The Secret namespace must follow cert-manager's requirements for a
`ClusterIssuer`.

Validate the installed cert-manager version's official documentation rather
than assuming namespace behavior.

Expected state:

```text
homelab-server-ca   Ready=True
```

---

## Automated Test Certificate

Create a cert-manager `Certificate` for:

```text
test.home.arpa
```

Expected Secret:

```text
test-home-arpa-tls
```

Suggested properties:

```yaml
spec:
  secretName: test-home-arpa-tls
  commonName: test.home.arpa
  dnsNames:
    - test.home.arpa
  issuerRef:
    name: homelab-server-ca
    kind: ClusterIssuer
  privateKey:
    rotationPolicy: Always
```

Configure explicit duration and renewal timing appropriate for short-lived
internal leaf certificates.

The DNS SAN is authoritative. The implementation must not depend only on the
Common Name.

---

## Traefik HTTPS Integration

Update the existing `test.home.arpa` Ingress to:

- enable TLS
- reference `test-home-arpa-tls`
- continue using `ingressClassName: traefik`
- redirect HTTP to HTTPS

The selected redirect implementation must be declarative and documented.

Possible implementation mechanisms include:

- Traefik entry-point redirection configured through Helm values
- a Traefik middleware attached to applicable routes

Prefer a platform-wide `web` to `websecure` entry-point redirect if all current
HTTP routes are intended to use HTTPS.

Do not expose the Traefik dashboard.

---

## Root Certificate Distribution

The Root CA public certificate may be distributed.

The Root CA private key may not.

Document trust installation for at least:

### Arch Linux management workstation

Document installation into the system trust store using the Arch-supported
mechanism and verification using `curl` and OpenSSL.

### Windows

Document import into:

```text
Trusted Root Certification Authorities
```

Clarify the difference between current-user and local-machine trust.

### Android

Document user-installed CA limitations and note that some applications may not
trust user-added CAs.

### Browsers

Document that:

- Chromium-based browsers generally use or integrate with the OS trust store,
  depending on platform and version
- Firefox trust-store behavior may require separate configuration depending on
  platform and settings

Do not claim universal trust behavior without platform qualification.

The Root certificate fingerprint must be verified through a trusted channel
before installation.

---

## Backup and Recovery

Document the minimum recovery set.

### Critical offline material

```text
Root CA private key
Root CA certificate
Server Issuing CA private key
Server Issuing CA certificate
Client Issuing CA private key
Client Issuing CA certificate
OpenSSL CA databases, serial files and configuration
Passphrase recovery information
```

Use encrypted offline backups.

Maintain at least two copies in separate locations.

Do not rely solely on:

- the management workstation
- Kubernetes Secrets
- the Git repository
- one USB drive

### Recovery test

Document and, where safely practical, validate:

1. rebuilding cert-manager
2. recreating the Server Issuing CA Secret
3. applying the `ClusterIssuer`
4. reissuing the test certificate
5. confirming clients still trust the same Root CA

Do not regenerate the Root CA during normal cluster recovery.

---

## Security Requirements

- no private key is committed to Git
- no generated Secret manifest containing private material is committed
- `.gitignore` protects common key, CSR, PKCS#12 and generated-secret patterns
- scripts check whether output paths are inside the repository
- Root key is encrypted
- Root key is absent from Kubernetes
- Client Issuing CA key is absent from Kubernetes
- only the Server Issuing CA key is made available to cert-manager
- issuing keys are backed up securely
- generated leaf keys use secure permissions
- certificate fingerprints and chains are verified
- no public ingress or router exposure is introduced
- the test route contains no sensitive application data

Review existing `.gitignore` before extending it. Do not broadly ignore all
`.crt` or `.pem` files because public certificates and test fixtures may be
legitimate repository content.

---

## Validation

### PKI structure

```bash
openssl x509 -in "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt" \
  -noout -subject -issuer -dates -fingerprint -sha256

openssl x509 -in "${HOMELAB_PKI_DIR}/server-issuing/certs/homelab-server-issuing-ca.crt" \
  -noout -text

openssl x509 -in "${HOMELAB_PKI_DIR}/client-issuing/certs/homelab-client-issuing-ca.crt" \
  -noout -text
```

Verify:

- Root is self-issued
- Root is `CA:TRUE`
- Root path length is appropriate
- both issuing CAs are signed by the Root
- both issuing CAs are `CA:TRUE`
- both issuing CAs have path length zero
- neither issuing CA accidentally contains leaf-only constraints

### Chain validation

```bash
openssl verify \
  -CAfile "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt" \
  "${HOMELAB_PKI_DIR}/server-issuing/certs/homelab-server-issuing-ca.crt"

openssl verify \
  -CAfile "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt" \
  "${HOMELAB_PKI_DIR}/client-issuing/certs/homelab-client-issuing-ca.crt"
```

### cert-manager

```bash
kubectl get pods -n cert-manager
kubectl get crds | grep cert-manager
kubectl get clusterissuer homelab-server-ca
kubectl describe clusterissuer homelab-server-ca
```

Expected:

- all cert-manager components are ready
- the `ClusterIssuer` reports `Ready=True`

### Certificate issuance

```bash
kubectl get certificate -n ingress
kubectl get certificaterequest -n ingress
kubectl describe certificate test-home-arpa -n ingress
kubectl get secret test-home-arpa-tls -n ingress
```

Expected:

- Certificate reports `Ready=True`
- CertificateRequest is approved and issued
- TLS Secret exists
- Secret contains `tls.crt` and `tls.key`

### Certificate inspection

```bash
kubectl get secret test-home-arpa-tls -n ingress \
  -o jsonpath='{.data.tls\.crt}' |
base64 --decode |
openssl x509 -noout -subject -issuer -dates -ext subjectAltName -ext extendedKeyUsage
```

Expected:

- subject/SAN includes `test.home.arpa`
- issuer is the HomeLab Server Issuing CA
- EKU includes server authentication

### HTTPS validation before local trust installation

```bash
curl --resolve test.home.arpa:443:192.168.68.201 \
  --cacert "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt" \
  https://test.home.arpa/
```

Expected:

- TLS validation succeeds
- whoami output is returned

### HTTP redirect

```bash
curl --resolve test.home.arpa:80:192.168.68.201 \
  -I http://test.home.arpa/
```

Expected:

- redirect to `https://test.home.arpa/`

### HTTPS after trust installation

```bash
curl https://test.home.arpa/
```

Expected:

- no `--insecure`
- no custom `--cacert`
- valid TLS chain
- whoami response returned

### Browser validation

Expected:

- `https://test.home.arpa` loads
- certificate is trusted
- hostname validation succeeds
- certificate chain terminates at the HomeLab Root CA
- no browser certificate warning appears

### Renewal validation

Use a safe test approach to confirm cert-manager renewal logic without waiting
for normal expiry.

Do not modify the system clock.

Document the chosen renewal test and confirm that the TLS Secret is updated
while the Ingress remains functional.

---

## Idempotency

Repeated execution shall not:

- regenerate the Root CA
- regenerate either issuing CA
- overwrite private keys
- create duplicate issuers
- unnecessarily recreate Kubernetes resources
- replace a valid certificate without reason
- expose private material in output

Helm deployment shall use a repeatable upgrade/install workflow.

Declarative Kubernetes manifests shall be safe to reapply.

CA-generation scripts shall detect existing state and stop with a clear
message.

---

## Documentation

Create or update, adapting paths to the repository's established structure:

```text
docs/decisions/ADR-0011-pki-and-tls-foundation.md
docs/infrastructure/pki.md
docs/infrastructure/security.md
docs/infrastructure/ingress.md
docs/operations/certificates.md
docs/operations/ingress.md
docs/operations/backup.md
docs/operations/rebuilding.md
docs/operations/troubleshooting.md
docs/overview/architecture.md
docs/overview/roadmap.md
PROJECT_STATE.md
mkdocs.yml
```

Document:

- the exact PKI hierarchy
- why it is two-tier despite containing three CA certificates
- Root, Server Issuing and Client Issuing CA responsibilities
- why the Root key remains offline
- why only the Server Issuing CA enters Kubernetes
- how cert-manager issues and renews certificates
- how Traefik terminates TLS
- how clients trust the Root CA
- certificate inspection commands
- backup and recovery
- compromise response
- issuing-CA replacement
- Root CA replacement implications
- current limitations
- future mTLS use of the Client Issuing CA

---

## ADR-0011

Create:

```text
ADR-0011 PKI and TLS Foundation
```

Record:

- private PKI selected because `home.arpa` cannot use public certificates
- offline Root CA
- separate Server and Client Issuing CAs
- Root CA excluded from Kubernetes
- Server Issuing CA provided to cert-manager
- Client Issuing CA retained offline
- cert-manager selected for automated server-certificate lifecycle
- Traefik selected for TLS termination
- short-lived leaf certificates
- trust distribution required on clients
- public ACME and mTLS deferred

---

## Project State

Update `PROJECT_STATE.md` only after successful runtime validation.

Record:

- cert-manager version
- Root CA identity and expiry
- Server Issuing CA identity and expiry
- Client Issuing CA identity and expiry
- `homelab-server-ca` ClusterIssuer status
- trusted HTTPS for `test.home.arpa`
- HTTP-to-HTTPS redirect
- certificate renewal behavior
- Root CA distribution status by client platform

Do not record private-key locations more precisely than operationally necessary.

Do not record passphrases or sensitive backup locations.

---

## Pull Request

Branch:

```text
wo-0007-pki-tls-foundation
```

PR title:

```text
WO-0007: PKI and TLS Foundation
```

Target release:

```text
v0.7.0
```

The PR description shall include:

```markdown
## Summary

## Work Order

## PKI Hierarchy

## Architecture Decisions

## Implementation

## Secret Handling

## Validation

## Certificate Issuance

## Trust Distribution

## Idempotency

## Documentation

## Security Impact

## Risks

## Rollback

## Known Limitations

## Target Release
```

The PR must not contain:

- CA private keys
- leaf private keys
- passphrases
- live Secret manifests
- PKCS#12 bundles containing private keys
- copied Kubernetes Secret output

---

## Acceptance Criteria

- [ ] existing repository scripts convention is reused
- [ ] PKI tooling exists under the existing scripts hierarchy
- [ ] PKI output is stored outside the repository
- [ ] scripts prevent accidental output inside Git
- [ ] Root CA is generated with an encrypted private key
- [ ] Root CA has correct CA constraints and key usage
- [ ] Server Issuing CA is signed by the Root
- [ ] Client Issuing CA is signed independently by the Root
- [ ] both issuing CAs have `pathLenConstraint:0`
- [ ] Root private key is absent from Kubernetes
- [ ] Client Issuing CA private key is absent from Kubernetes
- [ ] Server Issuing CA certificate and key are backed up securely
- [ ] manual server leaf issuance is demonstrated and verified
- [ ] manual client leaf issuance is demonstrated and verified
- [ ] cert-manager is installed from a pinned official Helm chart
- [ ] cert-manager components are healthy
- [ ] Server Issuing CA Secret is created without committing private data
- [ ] `homelab-server-ca` ClusterIssuer reports Ready
- [ ] `test.home.arpa` Certificate reports Ready
- [ ] certificate SAN contains `test.home.arpa`
- [ ] certificate EKU contains server authentication
- [ ] Traefik serves `test.home.arpa` over trusted HTTPS
- [ ] HTTP redirects to HTTPS
- [ ] HTTPS succeeds using the Root certificate with `curl --cacert`
- [ ] HTTPS succeeds through the operating-system trust store after installation
- [ ] browser validation succeeds without certificate warnings
- [ ] renewal behavior is validated
- [ ] Root CA trust distribution is documented
- [ ] backup and recovery are documented
- [ ] `.gitignore` protects private generated material without hiding legitimate public files
- [ ] ADR-0011 is created
- [ ] documentation is updated
- [ ] `PROJECT_STATE.md` is updated
- [ ] Helm validation passes
- [ ] Kubernetes dry-runs pass
- [ ] `mkdocs build --strict` passes
- [ ] pull request is created
- [ ] architecture review is completed
- [ ] findings are resolved
- [ ] PR is merged
- [ ] release `v0.7.0` is created

---

## Rollback

If cert-manager deployment fails:

- preserve all external PKI material
- remove or repair the cert-manager Helm release
- do not regenerate any CA
- retain the existing HTTP ingress path until corrected

If the `ClusterIssuer` fails:

- verify the Server Issuing CA certificate and key match
- verify the CA chain
- recreate the runtime Secret
- do not substitute the Root private key

If HTTPS routing fails:

- inspect the Certificate, CertificateRequest, Secret, Ingress and Traefik logs
- temporarily retain or restore HTTP access only for the non-sensitive test app
- do not use `tls.skipVerify`, browser exceptions or `curl --insecure` as the permanent fix

If the Server Issuing CA is lost but uncompromised:

- restore it from encrypted backup
- recreate the Kubernetes Secret
- reissue leaf certificates

If the Server Issuing CA is compromised:

- remove it from cert-manager
- use the offline Root CA to create a replacement Server Issuing CA
- replace the Kubernetes Secret
- reissue all affected server certificates
- document the incident and trust implications

If the Root CA private key is lost:

- existing certificates may remain usable until expiry
- no new issuing CA can be created
- a new Root CA and trust-distribution exercise will eventually be required

If the Root CA is compromised:

- treat the entire HomeLab PKI as compromised
- replace the Root and all descendants
- redistribute trust to every client

---

## Definition of Done

The HomeLab has a documented private PKI with an offline Root CA, separate
Server and Client Issuing CAs, automated server-certificate lifecycle through
cert-manager, and trusted HTTPS termination through Traefik.

`https://test.home.arpa` is trusted by configured clients without bypassing
certificate validation, and certificates can be renewed or reissued without
using the Root CA for routine operations.

---

## Successor Work Order

The next engineering work order should address one of:

- persistent storage foundation
- GitOps foundation
- secrets-management foundation
- observability foundation

Client certificate authentication and mTLS remain a separate future security
work order.
