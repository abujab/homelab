# Certificates

---

## Purpose

This directory contains Kubernetes configuration for HomeLab certificate
automation.

## Scope

It covers cert-manager installation values, the HomeLab Server Issuing CA
ClusterIssuer and the `test.home.arpa` validation certificate.

## Background

cert-manager is installed from the official OCI Helm chart:

```text
oci://quay.io/jetstack/charts/cert-manager
```

Pinned version:

```text
v1.21.0
```

The Server Issuing CA Secret is created at runtime from external PKI material
and is intentionally not committed to Git.

## Architecture / Implementation

Install cert-manager:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/namespace.yaml

helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.21.0 \
  --namespace cert-manager \
  --values kubernetes/platform/certificates/values.yaml \
  --kubeconfig ansible/kubeconfig
```

Create the runtime CA Secret:

```bash
scripts/pki/create-server-ca-secret.sh --kubeconfig ansible/kubeconfig
```

Apply issuer and test certificate:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/issuers/homelab-server-ca.yaml
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/test/certificate.yaml
```

## Design Decisions

The ClusterIssuer reads its CA Secret from the cert-manager namespace because
ClusterIssuer resources use cert-manager's cluster resource namespace for
referenced Secrets.

The `test.home.arpa` certificate is short lived at 90 days and renews 30 days
before expiry.

## Best Practices

- keep live Secret manifests out of Git
- verify the CA certificate and key before creating the Secret
- use DNS SANs for all server certificates
- inspect CertificateRequests when issuance fails

## Future Improvements

- GitOps reconciliation for cert-manager
- certificate policy controls
- trust-manager evaluation for cluster-local trust distribution

## Related Documents

- [PKI](../../../docs/infrastructure/pki.md)
- [Certificate Operations](../../../docs/operations/certificates.md)
