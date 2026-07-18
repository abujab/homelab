# Certificate Operations

---

## Purpose

This document describes operational procedures for the HomeLab private PKI and
TLS certificate lifecycle.

## Scope

This document covers:

- CA creation
- manual certificate inspection
- cert-manager installation
- Server Issuing CA Secret creation
- test certificate issuance
- Root CA trust distribution
- renewal validation
- backup and recovery
- compromise response

This document does not cover public ACME, mTLS enforcement or production client
certificate onboarding.

## Background

Private and generated PKI material lives outside Git.

Default location:

```bash
${HOME}/PKI/homelab
```

Override location:

```bash
export HOMELAB_PKI_DIR=/secure/offline/path/homelab
```

The scripts refuse to run when the resolved PKI directory is inside the
repository.

## Architecture / Implementation

### Create the CA hierarchy

Create the encrypted Root CA:

```bash
scripts/pki/create-root-ca.sh
```

The normal workflow uses OpenSSL's interactive passphrase prompts. Controlled
automation may use documented OpenSSL passphrase sources through
`HOMELAB_ROOT_CA_PASSIN` and `HOMELAB_ROOT_CA_PASSOUT`, but passphrases must not
be placed in command history or committed to Git.

Create the issuing CAs:

```bash
scripts/pki/create-server-issuing-ca.sh
scripts/pki/create-client-issuing-ca.sh
scripts/pki/verify-chain.sh
```

Inspect certificates:

```bash
scripts/pki/inspect-certificate.sh "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt"
scripts/pki/inspect-certificate.sh "${HOMELAB_PKI_DIR}/server-issuing/certs/homelab-server-issuing-ca.crt"
scripts/pki/inspect-certificate.sh "${HOMELAB_PKI_DIR}/client-issuing/certs/homelab-client-issuing-ca.crt"
```

### Demonstrate manual issuance

Server certificate:

```bash
scripts/pki/issue-server-certificate.sh \
  --common-name manual-test.home.arpa \
  --dns-name manual-test.home.arpa
```

Client certificate:

```bash
scripts/pki/issue-client-certificate.sh \
  --common-name abdul-homelab-admin
```

These certificates validate the PKI process only. They are not deployed as the
production `test.home.arpa` certificate.

### Install cert-manager

Apply the namespace:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/namespace.yaml
```

Install or upgrade cert-manager:

```bash
helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.21.0 \
  --namespace cert-manager \
  --values kubernetes/platform/certificates/values.yaml \
  --kubeconfig ansible/kubeconfig
```

Validate the rollout:

```bash
kubectl --kubeconfig ansible/kubeconfig get pods -n cert-manager
kubectl --kubeconfig ansible/kubeconfig get crds | grep cert-manager
```

### Create the Server Issuing CA Secret

Create or update the runtime Secret:

```bash
scripts/pki/create-server-ca-secret.sh --kubeconfig ansible/kubeconfig
```

The script verifies that the Server Issuing CA private key matches the
certificate before streaming a generated Secret manifest to `kubectl apply`.
The generated Secret manifest is not written to Git.

### Apply issuer and test certificate

Apply the ClusterIssuer:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/issuers/homelab-server-ca.yaml
kubectl --kubeconfig ansible/kubeconfig get clusterissuer homelab-server-ca
```

Apply the test certificate:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/test/certificate.yaml
kubectl --kubeconfig ansible/kubeconfig get certificate test-home-arpa -n ingress
```

Inspect the issued certificate:

```bash
kubectl --kubeconfig ansible/kubeconfig get secret test-home-arpa-tls -n ingress \
  -o jsonpath='{.data.tls\.crt}' |
base64 --decode |
openssl x509 -noout -subject -issuer -dates -ext subjectAltName -ext extendedKeyUsage
```

### Update Traefik and ingress

Upgrade Traefik with the repository values:

```bash
helm upgrade --install traefik traefik/traefik \
  --version 41.0.2 \
  --namespace ingress \
  --values kubernetes/platform/ingress/values.yaml \
  --kubeconfig ansible/kubeconfig
```

Apply the TLS-enabled test Ingress:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/ingress/test-app/ingress.yaml
```

### Validate HTTPS

Before installing the Root CA into local trust:

```bash
curl --resolve test.home.arpa:443:192.168.68.201 \
  --cacert "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt" \
  https://test.home.arpa/
```

Validate HTTP redirect:

```bash
curl --resolve test.home.arpa:80:192.168.68.201 \
  -I http://test.home.arpa/
```

Expected result:

```text
Location: https://test.home.arpa/
```

### Root certificate distribution

Arch Linux:

```bash
sudo trust anchor --store "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt"
trust list | grep -A2 "Abdul HomeLab Root CA"
curl https://test.home.arpa/
```

Windows:

Import the Root CA public certificate into `Trusted Root Certification
Authorities`. Current-user trust affects only the signed-in user. Local-machine
trust affects all users and requires administrative rights.

Android:

Install the Root CA through the device certificate settings. Android treats this
as a user-installed CA, and some applications may ignore user-added CAs.

Browsers:

Chromium-based browsers generally use or integrate with the operating-system
trust store, depending on platform and version. Firefox may use its own trust
store or the platform store depending on platform and settings.

Always verify the Root CA fingerprint through a trusted channel before
installation.

### Validate renewal

Do not modify system clocks.

Use `cmctl` to request renewal after recording the current certificate serial
number and TLS Secret resource version:

```bash
cmctl renew test-home-arpa --namespace ingress --kubeconfig ansible/kubeconfig
kubectl --kubeconfig ansible/kubeconfig get certificaterequest -n ingress
kubectl --kubeconfig ansible/kubeconfig get secret test-home-arpa-tls -n ingress \
  -o jsonpath='{.metadata.resourceVersion}'
```

Confirm that cert-manager creates a new CertificateRequest, changes the
certificate serial number and updates the TLS Secret while the Ingress remains
available. This exercises the same controller path used for scheduled renewal
without changing the system clock or weakening the production certificate
duration.

## Design Decisions

cert-manager is installed from the official OCI Helm chart and manages its CRDs
through `crds.enabled=true`.

The Server Issuing CA Secret is in the `cert-manager` namespace because
ClusterIssuer referenced Secrets are resolved from cert-manager's cluster
resource namespace.

## Best Practices

- verify certificate fingerprints before trust installation
- keep the Root private key offline after issuing CA creation
- keep at least two encrypted offline backups
- avoid regenerating the Root CA during normal cluster recovery
- inspect CertificateRequests before replacing CA material

## Future Improvements

- dedicated issuing CA replacement procedure
- client certificate issuance standards
- mTLS validation work order
- automated backup package verification

## Related Documents

- [PKI](../infrastructure/pki.md)
- [Ingress Operations](ingress.md)
- [Backup](backup.md)
- [Troubleshooting](troubleshooting.md)
