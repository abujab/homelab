# Architecture Review Archive

- **Architecture Review:** AR-0005
- **Work Order:** WO-0008
- **Pull Request:** abujab/homelab#10
- **Reviewed Head:** `1516e86e555c0f7a09a0a57112a1c20cea50b9af`
- **Merged Commit:** `4840a89753f9c6ca3bcbbc5d104c15becfe6324a`
- **Reviewer:** gabdul-AI
- **Approved:** 2026-07-18T08:02:22Z
- **Result:** Approved

---

## Review History

The final-head approval is recorded in the metadata above. Terse approval text
is intentionally omitted; the substantive reviews follow.

## Architecture assessment

The implementation itself is strong and matches WO-0008:

* The existing Pi-hole LoadBalancer is modified in place, preserving `192.168.68.200`.
* The external service now exposes only TCP/UDP 53.
* `pihole-web` is correctly implemented as a ClusterIP service on port 80.
* The standard Kubernetes Ingress routes `pihole.home.arpa` through Traefik.
* TLS terminates at Traefik using `pihole-home-arpa-tls`.
* The certificate uses the existing `homelab-server-ca` ClusterIssuer.
* Pi-hole DNS now returns `192.168.68.201` for the Web hostname.
* The Root and issuing CA architecture remains unchanged.
* ADR-0012 clearly establishes the reusable application-exposure standard.
* Bootstrap ordering avoids applying the Certificate CR before cert-manager is installed.
* The validation script checks the important runtime properties, including DNS over both UDP and TCP, trusted HTTPS, redirect behaviour, and removal of direct port-80 exposure.

I found no blocking issue in the Kubernetes or PKI architecture.

## Required correction before approval

The archived work-order document is not clean:

```text
work-orders/WO-0008-pihole-web-exposure-and-application-ingress-standard.md
```

It contains:

1. An unnecessary outer ````markdown code fence.
2. The original assistant-style closing commentary.
3. All acceptance criteria still shown as unchecked:

```markdown
- [ ] Pi-hole DNS remains reachable...
```

even though the work order status says `Complete`.

The file should contain only the work order itself. Remove the outer wrapper and trailing commentary, and mark each verified acceptance criterion as complete:

```markdown
- [x]
```

This matters because the archived work order is intended to be the authoritative implementation record.

## Non-blocking observation

There are currently no GitHub Actions workflow runs associated with this head commit. The PR description records extensive manual validation, so this does not block WO-0008, but future repository CI would strengthen the evidence for manifest linting and documentation builds.

## Review decision

**Changes requested: documentation cleanup only.**

---

Architecture review complete for final head `1516e86e555c0f7a09a0a57112a1c20cea50b9af`.

The requested work-order cleanup has been completed:

- the outer Markdown wrapper and trailing assistant commentary were removed;
- verified acceptance criteria are marked complete;
- the archived work order is now a clean authoritative implementation record.

The implementation remains aligned with WO-0008 and ADR-0012: Pi-hole DNS stays directly available at `192.168.68.200` on TCP/UDP 53, the Web UI is isolated behind the `pihole-web` ClusterIP Service, `pihole.home.arpa` routes through Traefik at `192.168.68.201`, and TLS is managed by cert-manager using the existing HomeLab Server Issuing CA.

No blocking issues remain. Approved for merge.
