# Architecture Review Archive

- **Architecture Review:** AR-0004
- **Work Order:** WO-0007
- **Pull Request:** abujab/homelab#8
- **Reviewed Head:** `70b656215094e2f264c79d7c304d2dd296017ca9`
- **Merged Commit:** `a060098a7229cb9812bb48962ee9f5cc4517db16`
- **Reviewer:** gabdul-AI
- **Approved:** 2026-07-18T05:54:51Z
- **Result:** Approved

---

## Review History

The final-head approval is recorded in the metadata above. Terse approval text
is intentionally omitted; the substantive structured reviews follow.

## Architecture Review — WO-0007 PKI and TLS Foundation

**Result: Changes requested**

The overall architecture and runtime outcome are strong: offline Root CA,
separate Server and Client Issuing CAs, cert-manager automation, Traefik TLS
termination, HTTP-to-HTTPS redirection, and documented recovery all align with
WO-0007.

### Required changes

1. **Validate certificate identity inputs before inserting them into OpenSSL
   syntax.**

   `issue-server-certificate.sh` inserts `--common-name` directly into `-subj`
   and appends each `--dns-name` directly into a generated OpenSSL configuration
   file.

   Add strict validation for DNS names and Common Names so characters such as
   `/`, newline, `=`, or configuration-section syntax cannot alter the requested
   DN or extension profile.

   Apply equivalent validation to the client-certificate script.

2. **Narrow the broad Secret ignore patterns.**

   `.gitignore` currently ignores every `*.secret.yaml` and `*-secret.yaml`
   anywhere in the repository. This can silently hide legitimate declarative
   resources or safe templates during future GitOps work.

   Retain precise ignores for known generated/live Secret paths and rely on the
   PKI scripts' outside-repository guard plus secret scanning for broader
   protection.

### Non-blocking observations

- OpenSSL CA database directories are created, but signing currently uses
  `openssl x509 -CAcreateserial`; the database is therefore not the source of
  issued-certificate history. This is acceptable while CRL and revocation
  infrastructure remain out of scope, but documentation should not imply
  otherwise.
- The PR is still marked Draft and currently has no automated status checks.

After the two required changes and rerunning the documented validation, the PR
should be ready for approval and release as `v0.7.0`.

---

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

---

## Review — Architecture Review Archiving Automation

**Result: Changes requested**

The helper script is well structured, but the proposed lifecycle creates a
self-referential review problem.

### Required change

Do not archive an approval by committing it to the same implementation PR after
that PR has been approved. That archive commit changes the reviewed head and is
not covered by the approval being archived.

Use this lifecycle instead:

1. complete implementation;
2. obtain final architecture approval;
3. merge the implementation PR;
4. archive the final review on a separate branch;
5. open and merge a small review-archive PR;
6. create the release.

The archive process must also verify that the selected approval applies to the
implementation PR's final head commit. Selecting merely the latest review with
state `APPROVED` can archive a stale approval after later commits were added.

Add review metadata to the archived file, including:

- architecture-review ID;
- work-order ID;
- PR number;
- reviewed head SHA;
- merged commit SHA;
- reviewer;
- approval timestamp;
- result.

The existing AR-0004 review text is correct, and the PKI implementation remains
approved. The requested change concerns the reusable workflow for future work
orders.
