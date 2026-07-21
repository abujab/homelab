# WO-1004 Consistency Review

---

## Scope

Record final consistency checks across documentation, Ansible inventory,
Kubernetes desired state, dependency pins, ADRs and completed work evidence.

## Results

| Category | Verified State | Primary Sources | Result |
|----------|----------------|-----------------|--------|
| Hostnames | Canonical `pi4mB01` through `pi4mB04`; lowercase runtime representation explained | Ansible inventory and K3s label task | Pass |
| Node IP addresses | `192.168.68.101` through `192.168.68.104` | Ansible `host_vars` | Pass |
| LAN and gateway | `192.168.68.0/22`, gateway `192.168.68.1`, interface `eth0` | Network role and completed evidence | Pass |
| MetalLB range | `192.168.68.200-192.168.68.220` | `IPAddressPool/homelab-lan` | Pass |
| Service IPs | Pi-hole DNS `.200`; shared Traefik ingress `.201` | Service manifest, Helm values and Pi-hole DNS configuration | Pass |
| DNS names | `pihole.home.arpa` active; `test.home.arpa` validation-only; `elm.home.arpa` reserved | Pi-hole deployment and `PROJECT_STATE.md` | Pass |
| Namespaces | `metallb-system`, `networking`, `ingress`, `cert-manager` | Kubernetes manifests and Helm configuration | Pass |
| Exposure | Pi-hole DNS direct TCP/UDP 53; Web UIs use Traefik HTTPS and ClusterIP backends | Service and Ingress manifests | Pass |
| Software versions | Repository pins recorded; uncontrolled versions labeled Not pinned or Pending verification | Kustomize, Helm values and requirements | Pass |
| Current/planned state | Current services separated from Longhorn, NAS, observability, GitOps, secrets, x86 and AI plans | Manifests, work orders and roadmap | Pass |
| Storage | Only `pi4mB01` qualified; WD disk not connected; Longhorn absent; no replication | Storage role, WO-0009 and evidence | Pass |
| ADR status | ADR-0001 through ADR-0012 registered without rewriting history | ADR source files | Pass with documented limitations |
| Terminology | Product capitalization and Kubernetes resource terms normalized | Full Markdown scan | Pass |
| Sensitive data | No password, token, private key or Secret value added to documentation or evidence | Changed-content scan | Pass |

## Documented Limitations

- ADR-0003 remains Proposed although its K3s decision is implemented.
- ADR-0007 is empty and cannot establish a decision or status.
- Exact runtime versions bundled with the unpinned K3s install remain Pending
  verification.
- The exact Raspberry Pi OS image release, home-router model and management
  workstation model are not recorded.

These limitations are represented explicitly and do not cause a contradictory
current-state claim.
