# WO-0008 — Pi-hole Web Exposure and Application Ingress Standard

````markdown
# WO-0008 — Pi-hole Web Exposure and Application Ingress Standard

## Status

Complete

## Objective

Refactor Pi-hole exposure so that:

- DNS remains directly available through MetalLB at `192.168.68.200` on TCP/UDP port 53.
- The Pi-hole Web UI is exposed only through Traefik.
- `https://pihole.home.arpa` terminates TLS at Traefik.
- cert-manager automatically manages the certificate.
- Direct external access to the Pi-hole Web UI on `192.168.68.200:80` is removed.
- The resulting pattern is documented as the default application-exposure architecture for the HomeLab.

## Background

The current Pi-hole Kubernetes Service is:

- Type: `LoadBalancer`
- External IP: `192.168.68.200`
- Ports:
  - TCP 53
  - UDP 53
  - TCP 80

This combines two different responsibilities:

1. DNS infrastructure that must be directly reachable by LAN clients.
2. A web application that should be published through the shared ingress layer.

Traefik is already available at:

```text
192.168.68.201
````

The existing TLS test application demonstrates that:

* Traefik ingress works.
* cert-manager works.
* The internal Server Issuing CA works.
* Trusted HTTPS works for `*.home.arpa` hosts when explicitly configured.

The desired architecture is:

```text
DNS clients
    |
    | TCP/UDP 53
    v
192.168.68.200
Pi-hole DNS LoadBalancer Service
    |
    v
Pi-hole Pod


Browser
    |
    | HTTPS 443
    v
pihole.home.arpa
    |
    | DNS resolves to 192.168.68.201
    v
Traefik
    |
    | TLS termination
    | Internal HTTP
    v
Pi-hole Web ClusterIP Service:80
    |
    v
Pi-hole Pod:80
```

## Scope

This work order includes:

1. Splitting the current Pi-hole Service into separate DNS and Web services.
2. Keeping DNS externally reachable through MetalLB.
3. Making the Web UI reachable internally through a ClusterIP Service.
4. Creating a Kubernetes Ingress for `pihole.home.arpa`.
5. Issuing and attaching a TLS certificate through cert-manager.
6. Redirecting HTTP access to HTTPS through the established Traefik configuration.
7. Changing the Pi-hole local DNS record for `pihole.home.arpa`.
8. Updating validation scripts, documentation, and operational guidance.
9. Creating an ADR that defines the default HomeLab application-exposure standard.

## Out of Scope

Do not introduce any of the following in this work order:

* A service mesh.
* TLS between Traefik and the Pi-hole Pod.
* TLS passthrough.
* Native HTTPS configuration inside Pi-hole.
* Mutual TLS.
* Authentication proxies or single sign-on.
* External/public DNS.
* Publicly trusted certificates.
* Internet exposure.
* Changes to the Root CA or issuing CA hierarchy.
* Observability tooling.
* Changes to unrelated applications.
* Removal of the existing `test.home.arpa` validation application.

## Required Architecture

### Pi-hole DNS Service

Create or rename the DNS-facing Service so that it:

* Uses `type: LoadBalancer`.
* Retains the MetalLB IP `192.168.68.200`.
* Exposes only:

  * TCP port 53.
  * UDP port 53.
* Selects the existing Pi-hole Pod using the correct labels.
* Does not expose TCP port 80.
* Preserves any MetalLB annotations or address-pool configuration already required by the repository.

Suggested logical name:

```text
pihole-dns
```

The exact name may differ if repository conventions require another name, but the DNS and Web responsibilities must remain visibly separate.

### Pi-hole Web Service

Create a separate Service that:

* Uses `type: ClusterIP`.
* Exposes TCP port 80.
* Targets the Pi-hole container's HTTP port.
* Uses the same Pi-hole Pod selector as the DNS Service.
* Is not assigned an external IP.
* Is used as the Ingress backend.

Suggested logical name:

```text
pihole-web
```

### Ingress

Create a standard Kubernetes `Ingress` resource that:

* Is deployed in the same namespace as Pi-hole.
* Uses `ingressClassName: traefik`.
* Uses the hostname:

```text
pihole.home.arpa
```

* Routes traffic to the Pi-hole Web ClusterIP Service.
* Routes to the correct HTTP service port.
* Enables TLS using the certificate Secret created for this hostname.
* Uses the same cert-manager issuer and TLS pattern already proven by `test.home.arpa`.
* Uses the existing platform-level HTTP-to-HTTPS redirect mechanism.
* Does not introduce a Traefik `IngressRoute` unless standard Kubernetes Ingress cannot meet a documented requirement.

Inspect the existing `test.home.arpa` resources and reuse the established conventions rather than duplicating issuer details independently.

### Certificate

Create or trigger creation of a certificate for:

```text
pihole.home.arpa
```

The implementation must:

* Reuse the existing cert-manager ClusterIssuer or Issuer used successfully for `test.home.arpa`.
* Store the certificate in a clearly named Kubernetes TLS Secret.
* Include `pihole.home.arpa` as a DNS Subject Alternative Name.
* Use the Server Issuing CA.
* Produce a certificate suitable for TLS server authentication.
* Avoid committing any private key, generated certificate, CA Secret contents, or other secret material to Git.

Suggested names:

```text
Certificate: pihole-home-arpa
Secret:      pihole-home-arpa-tls
```

Repository naming conventions take precedence when consistently applied.

### DNS Record

Change the Pi-hole local DNS record from:

```text
pihole.home.arpa -> 192.168.68.200
```

to:

```text
pihole.home.arpa -> 192.168.68.201
```

This hostname is for browser access and must therefore resolve to Traefik.

The Pi-hole DNS server address used by clients remains:

```text
192.168.68.200
```

These two functions must not be confused:

```text
DNS resolver address:
192.168.68.200

Web hostname destination:
pihole.home.arpa -> 192.168.68.201
```

Where the local DNS record is managed declaratively in the repository, update that source of truth.

Do not rely on an undocumented manual-only change in the Pi-hole dashboard.

If the repository does not currently manage Pi-hole local DNS records declaratively, add an idempotent mechanism or clearly documented operational step consistent with the existing deployment model.

## Pi-hole URL Behaviour

Pi-hole installations commonly expose the dashboard below `/admin/`.

The implementation must determine the actual behaviour of the deployed Pi-hole version and configure one of these outcomes:

### Preferred outcome

```text
https://pihole.home.arpa/
```

redirects to:

```text
https://pihole.home.arpa/admin/
```

### Acceptable fallback

The dashboard is documented and accessible at:

```text
https://pihole.home.arpa/admin/
```

Do not add a path rewrite without confirming that Pi-hole requires it.

Do not create a rewrite that breaks static assets, login actions, API requests, relative paths, or redirects generated by Pi-hole.

## ADR

Create a new Architecture Decision Record following the repository's existing ADR numbering and template.

Suggested title:

```text
Application Exposure Through the Shared Ingress Layer
```

The ADR must document the following decision.

### Decision

Web applications deployed in the HomeLab will, by default:

* Be exposed through Traefik.
* Use DNS hostnames under `home.arpa`.
* Resolve application hostnames to the Traefik LoadBalancer IP.
* Terminate TLS at Traefik.
* Obtain certificates through cert-manager.
* Use certificates issued by the HomeLab Server Issuing CA.
* Use internal ClusterIP Services as Ingress backends.
* Communicate from Traefik to the application over HTTP unless stronger protection is specifically required.
* Avoid separate LoadBalancer IPs for ordinary Web UIs.

Non-HTTP infrastructure protocols may receive dedicated LoadBalancer Services when direct LAN access is required.

Pi-hole DNS on TCP/UDP 53 is the initial documented example of this exception.

### Rationale

The ADR should explain that this approach provides:

* Centralised TLS termination.
* Centralised certificate lifecycle management.
* Consistent hostname-based routing.
* Reduced MetalLB address consumption.
* Fewer externally exposed application ports.
* A reusable deployment pattern.
* Clear separation between infrastructure protocols and browser-facing interfaces.
* Simpler application configuration.

### Alternatives considered

At minimum, document:

1. A single Pi-hole LoadBalancer Service exposing DNS and HTTP.
2. Native HTTPS directly inside each application.
3. HTTPS from the client through Traefik and again from Traefik to every backend.
4. TLS passthrough.
5. The selected shared-ingress TLS-termination model.

### Consequences

Document that:

* Traffic between Traefik and ordinary application backends is unencrypted inside the Kubernetes network.
* Applications requiring end-to-end TLS, mTLS, or TLS passthrough must be handled as explicit exceptions.
* DNS and other non-HTTP protocols cannot be exposed through a normal HTTP Ingress.
* Application DNS records must point to Traefik rather than directly to application Services.
* The Root CA must be trusted by client devices to avoid browser warnings.

## Repository Changes

Inspect the repository and modify the appropriate existing files rather than creating parallel deployment structures.

Expected changes may include:

```text
Kubernetes manifests or Helm values for Pi-hole
Ingress manifest for Pi-hole
Certificate configuration
Pi-hole local DNS configuration
Deployment/playbook logic
Validation scripts
Operations documentation
Architecture documentation
ADR index
New ADR
```

Use the repository's established directory layout and naming conventions.

Do not introduce a new deployment framework solely for this work order.

## Idempotency

All configuration must be repeatable.

A second execution must not:

* Create duplicate Services.
* Create duplicate DNS records.
* Allocate a different MetalLB IP.
* Generate a second conflicting Ingress.
* Generate unnecessary certificates.
* Reset Pi-hole state.
* Replace valid secrets without cause.
* Fail merely because the desired configuration already exists.

## Availability and Migration Safety

Pi-hole currently provides DNS to the HomeLab.

The implementation must minimise DNS disruption.

The migration order should preserve DNS availability:

1. Inspect and record the existing Pi-hole Deployment and Service selectors.
2. Create or validate the Web ClusterIP Service.
3. Create the Ingress and certificate.
4. Verify the Ingress backend from inside the cluster.
5. Ensure the DNS-only LoadBalancer Service exists on `192.168.68.200`.
6. Verify TCP and UDP DNS through `192.168.68.200`.
7. Remove port 80 from the external DNS Service.
8. Change `pihole.home.arpa` to resolve to `192.168.68.201`.
9. Validate trusted HTTPS from a client.
10. Confirm no DNS outage or configuration loss occurred.

Avoid deleting the existing combined Service before the replacement DNS Service is ready, unless it is safely modified in place without changing the MetalLB IP.

Pi-hole persistent storage must not be deleted or recreated.

## Security Requirements

* Do not commit Kubernetes Secret values.
* Do not commit private keys.
* Do not expose the Root CA private key to Kubernetes.
* Do not expose the Server Issuing CA private key outside its established cert-manager mechanism.
* Do not use `--insecure` or certificate verification bypasses as the final solution.
* Do not expose the Pi-hole Web UI directly through a NodePort or LoadBalancer.
* Do not expose Pi-hole outside the private LAN.
* Preserve the existing Pi-hole authentication configuration.
* Ensure the Ingress backend references only the Web Service.
* Ensure the DNS Service exposes no Web UI port after migration.

## Required Validation

### Resource validation

Run and record the relevant output from:

```bash
kubectl get pods -n networking
kubectl get svc -n networking
kubectl get ingress -n networking
kubectl get certificate -n networking
kubectl get certificaterequest -n networking
kubectl describe ingress -n networking
kubectl describe certificate -n networking
```

Expected Service model:

```text
pihole-dns   LoadBalancer   192.168.68.200   53/TCP,53/UDP
pihole-web   ClusterIP      <none>           80/TCP
```

The exact displayed names may follow repository conventions.

### DNS validation

From the Arch Linux management workstation:

```bash
dig @192.168.68.200 pihole.home.arpa A
```

Expected answer:

```text
pihole.home.arpa. IN A 192.168.68.201
```

Verify the normal system resolver also returns the same result:

```bash
dig pihole.home.arpa A
getent hosts pihole.home.arpa
```

### DNS service validation

Verify UDP DNS:

```bash
dig @192.168.68.200 test.home.arpa A
```

Verify TCP DNS:

```bash
dig +tcp @192.168.68.200 test.home.arpa A
```

Both must succeed.

### HTTP redirect validation

```bash
curl -I http://pihole.home.arpa/
```

Expected:

* An HTTP redirect to HTTPS.
* No direct Pi-hole page served over external HTTP without redirection.

### TLS validation

Use the trusted HomeLab CA configuration:

```bash
curl -I https://pihole.home.arpa/
```

The command must succeed without `-k`.

Where the root trust configuration requires an explicit CA file for command-line validation, use the public Root CA certificate:

```bash
curl --cacert <public-root-ca-certificate> \
  -I https://pihole.home.arpa/
```

Do not use private key material.

Inspect the served chain:

```bash
openssl s_client \
  -connect pihole.home.arpa:443 \
  -servername pihole.home.arpa \
  -showcerts </dev/null
```

Verify:

* The leaf certificate is valid for `pihole.home.arpa`.
* The DNS SAN contains `pihole.home.arpa`.
* The issuer is the HomeLab Server Issuing CA.
* The certificate chain is presented correctly.
* Certificate verification succeeds when using the HomeLab Root CA.
* The certificate is intended for server authentication.

### Direct exposure validation

The external Pi-hole IP must continue to serve DNS:

```bash
dig @192.168.68.200 example.com
```

The external Pi-hole IP must no longer expose the Web UI through the Kubernetes Service:

```bash
curl --connect-timeout 5 -I http://192.168.68.200/
```

Expected:

* Connection refusal, timeout, or another result demonstrating that TCP port 80 is not exposed through the Pi-hole LoadBalancer Service.
* It must not return the Pi-hole Web UI.

Also inspect the Service manifest to confirm only TCP/UDP 53 is externally published.

### Browser validation

From a workstation that trusts the HomeLab Root CA:

1. Open:

   ```text
   http://pihole.home.arpa
   ```

2. Confirm redirection to HTTPS.

3. Confirm the Pi-hole interface is available at either:

   ```text
   https://pihole.home.arpa/
   ```

   or:

   ```text
   https://pihole.home.arpa/admin/
   ```

4. Confirm there is no browser certificate warning.

5. Inspect the certificate and verify:

   ```text
   Subject/SAN: pihole.home.arpa
   Issuer: HomeLab Server Issuing CA
   ```

6. Confirm authentication and normal Pi-hole administration still work.

## Automated Validation

Extend or create repository validation so that the following conditions can be checked automatically:

* The Pi-hole DNS Service is a LoadBalancer.
* The DNS Service retains `192.168.68.200`.
* The DNS Service exposes TCP and UDP port 53.
* The DNS Service does not expose port 80 or 443.
* The Pi-hole Web Service is a ClusterIP.
* The Web Service exposes port 80.
* The Ingress uses `pihole.home.arpa`.
* The Ingress uses Traefik.
* The Ingress backend is the Pi-hole Web Service.
* TLS is configured.
* The referenced TLS Secret exists after deployment.
* The Certificate reaches `Ready=True`.
* DNS for `pihole.home.arpa` resolves to `192.168.68.201`.
* DNS queries continue to succeed through `192.168.68.200`.

Validation scripts must provide clear failure messages.

## Documentation

Update the relevant documentation to include:

* The separation of Pi-hole DNS and Web exposure.
* The purpose of `192.168.68.200`.
* The purpose of `192.168.68.201`.
* The URL for the Pi-hole dashboard.
* The TLS termination model.
* How future applications should be exposed.
* How to add a new `home.arpa` application hostname.
* How to request a certificate through cert-manager.
* How to verify certificate issuance.
* How to troubleshoot:

  * DNS resolution.
  * Ingress routing.
  * Certificate readiness.
  * Backend Service selection.
  * Root CA trust.
* The exception process for applications requiring end-to-end TLS or non-HTTP protocols.

Update any architecture diagrams that currently show the Pi-hole Web UI being accessed directly through `192.168.68.200`.

## Rollback Plan

Document and validate a rollback procedure.

At minimum, rollback must allow an operator to:

1. Restore port 80 to the original Pi-hole LoadBalancer Service if the Ingress path fails.

2. Restore:

   ```text
   pihole.home.arpa -> 192.168.68.200
   ```

3. Remove or disable the Pi-hole Ingress without affecting DNS.

4. Preserve all Pi-hole persistent data.

5. Preserve DNS availability at `192.168.68.200`.

The rollback must not require PKI regeneration.

## Acceptance Criteria

This work order is complete when all of the following are true:

* [ ] Pi-hole DNS remains reachable at `192.168.68.200`.
* [ ] TCP DNS works on port 53.
* [ ] UDP DNS works on port 53.
* [ ] Port 80 is no longer externally exposed by the Pi-hole LoadBalancer.
* [ ] A separate Pi-hole Web ClusterIP Service exists.
* [ ] The Web Service exposes only the required internal HTTP port.
* [ ] `pihole.home.arpa` resolves to `192.168.68.201`.
* [ ] A Traefik Ingress exists for `pihole.home.arpa`.
* [ ] HTTP redirects to HTTPS.
* [ ] The certificate reaches `Ready=True`.
* [ ] The certificate contains `pihole.home.arpa` as a SAN.
* [ ] The certificate is issued by the HomeLab Server Issuing CA.
* [ ] The browser trusts the certificate without warnings.
* [ ] The Pi-hole administration interface works through HTTPS.
* [ ] Direct HTTP access through `192.168.68.200` is unavailable.
* [ ] Existing Pi-hole DNS configuration and persistent data remain intact.
* [ ] Automated validation covers the new exposure model.
* [ ] Operational documentation is updated.
* [ ] Architecture diagrams are updated where necessary.
* [ ] A new ADR documents the application-exposure standard.
* [ ] The ADR index is updated.
* [ ] No private keys, certificates containing private material, or Kubernetes Secret values are committed.
* [ ] The implementation is idempotent.
* [ ] The rollback procedure is documented.

## Implementation Constraints

* Follow existing repository conventions.
* Prefer standard Kubernetes `Ingress`.
* Reuse the existing cert-manager issuer configuration.
* Do not invent another CA or ClusterIssuer.
* Do not change fixed MetalLB addresses.
* Do not regenerate the HomeLab PKI.
* Do not delete Pi-hole persistent volumes or claims.
* Do not make unrelated refactors.
* Keep the change reviewable as one coherent implementation work order.
* Add comments only where they explain non-obvious architectural intent.
* Run formatting, linting, manifest validation, and repository tests before completion.

## Pull Request Requirements

Create a pull request after implementation.

The pull request description must include:

* Summary of the Pi-hole exposure change.
* Before-and-after architecture.
* List of modified resources.
* Confirmation that DNS remained available.
* Certificate readiness evidence.
* DNS validation output.
* HTTP redirect validation.
* Trusted HTTPS validation.
* Confirmation that `192.168.68.200:80` is no longer exposed.
* Browser validation results, where browser verification must be performed manually.
* ADR created or updated.
* Documentation changes.
* Risks and rollback procedure.
* Any deviations from this work order.

Do not archive the architecture review inside the implementation pull request.

Follow the established workflow:

```text
Implementation
    ->
Implementation pull request
    ->
Architecture review
    ->
Final approval covering the final implementation head SHA
    ->
Merge implementation pull request
    ->
Archive the approved review on a separate branch
    ->
Review archive pull request
    ->
Merge review archive pull request
    ->
Create release
```

## Suggested Release

After implementation, review approval, merge, and review archival:

```text
v0.8.0
```

Suggested release theme:

```text
Pi-hole secure ingress and application exposure standard
```

```

This makes **WO-0008** a focused platform-hardening sprint rather than starting observability prematurely. The next work order can then be **WO-0009 — Observability Foundation**, with Grafana becoming the first new application deployed according to this ADR.
```
