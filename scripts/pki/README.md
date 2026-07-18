# HomeLab PKI Tooling

---

## Purpose

This directory contains repeatable tooling for the HomeLab private PKI.

## Scope

The scripts create an offline Root CA, separate Server and Client Issuing CAs,
manual demonstration certificates and the runtime Kubernetes Secret consumed by
cert-manager.

## Background

Generated PKI material is not stored in Git. The default working directory is:

```bash
${HOME}/PKI/homelab
```

Override it with:

```bash
export HOMELAB_PKI_DIR=/secure/offline/path/homelab
```

The scripts refuse to run if the resolved PKI directory is inside this
repository.

## Architecture / Implementation

Create the hierarchy:

```bash
scripts/pki/create-root-ca.sh
scripts/pki/create-server-issuing-ca.sh
scripts/pki/create-client-issuing-ca.sh
scripts/pki/verify-chain.sh
```

The default Root CA workflow uses interactive OpenSSL passphrase prompts.
Controlled automation may use OpenSSL passphrase source variables:

```bash
export HOMELAB_ROOT_CA_PASSWORD='temporary-validation-only'
export HOMELAB_ROOT_CA_PASSOUT=env:HOMELAB_ROOT_CA_PASSWORD
export HOMELAB_ROOT_CA_PASSIN=env:HOMELAB_ROOT_CA_PASSWORD
```

Do not place passphrases in command history or commit them to Git.

Issue demonstration certificates:

```bash
scripts/pki/issue-server-certificate.sh \
  --common-name manual-test.home.arpa \
  --dns-name manual-test.home.arpa

scripts/pki/issue-client-certificate.sh \
  --common-name abdul-homelab-admin
```

Create the cert-manager runtime Secret:

```bash
scripts/pki/create-server-ca-secret.sh --kubeconfig ansible/kubeconfig
```

## Design Decisions

The Root CA key is encrypted and remains outside Kubernetes. The Server Issuing
CA key is imported into Kubernetes only as the cert-manager CA issuer Secret.
The Client Issuing CA is reserved for future client authentication and remains
offline during this work order.

## Best Practices

- keep `HOMELAB_PKI_DIR` outside the repository
- back up keys, certificates, databases and passphrase recovery records
- verify fingerprints before distributing trust
- never commit generated Secret output

## Future Improvements

- scripted encrypted backup packaging
- issuing CA replacement automation
- future client certificate and mTLS workflows

## Related Documents

- [PKI](../../docs/infrastructure/pki.md)
- [Certificate Operations](../../docs/operations/certificates.md)
