# WO-1004 Documentation Audit

---

## Purpose

Record documentation drift discovered during WO-1004 and the action taken for
each finding.

## Scope

The audit covers `README.md`, `PROJECT_STATE.md`, `mkdocs.yml`, every tracked
page under `docs/`, relevant Ansible and Kubernetes desired state, dependency
files, completed work orders and WO-0009 storage evidence.

## Method

Current claims were compared in this order:

1. executable Ansible and Kubernetes configuration
2. latest completed work-order evidence
3. `PROJECT_STATE.md`
4. existing narrative documentation

The pre-change and updated sites were built with `mkdocs build --strict`.
Navigation coverage, terminology, addressing, versions, links, ADR state and
current-versus-planned classifications were reviewed separately.

## Findings

| Document | Finding | Evidence | Required Action | Status |
|----------|---------|----------|-----------------|--------|
| `README.md` | Networking was Planned and the next milestone although WO-0004 through WO-0008 are complete | `PROJECT_STATE.md`, Kubernetes manifests | Replace stale status and next-work summary | Resolved |
| `docs/index.md` | Claimed only the Overview sprint existed and presented DNS, ingress and storage as future | Completed work orders and current tree | Refresh current platform and site organization | Resolved |
| `docs/overview/vision.md` | Listed MetalLB, Pi-hole and TLS as future improvements | Current manifests and WO-0004 through WO-0008 | Separate current foundation from target capabilities | Resolved |
| `docs/overview/architecture.md` | Omitted WO-0009 storage topology, mixed canonical and runtime node spelling without explanation, and had an incomplete target/current split | Ansible inventory, WO-0009 evidence | Replace diagrams and add explicit state tables | Resolved |
| `docs/overview/roadmap.md` | Documentation remained In progress, storage remained entirely Planned, and an IBM ELM DNS entry was described as complete | WO-1001 through WO-1003, WO-0009, Pi-hole deployment | Refresh phase status and dependencies | Resolved |
| `docs/overview/repository.md` | Omitted the storage role and playbook, current Kubernetes layout, Reference, Development, artifacts and reviews | Tracked repository tree | Replace repository tree and lifecycle description | Resolved |
| `docs/infrastructure/ansible.md` | Omitted `storage_nodes`, `storage.yml` and the `storage` role | Ansible inventory and role tree | Add verified storage automation | Resolved |
| `docs/infrastructure/kubernetes.md` | Presented MetalLB as likely future work and TLS management as Planned | Current manifests and `PROJECT_STATE.md` | Correct current state and add reference links | Resolved |
| `docs/infrastructure/networking.md` | Presented TLS automation as future and maintained a competing future-name table | Certificate manifests and naming sources | Correct TLS state and defer authoritative allocation to Reference | Resolved |
| `docs/infrastructure/storage.md` | Correct state but no direct path to inventory, ADR, backup, work order and validation evidence | WO-1004 cross-link requirement | Add useful related links and authority note | Resolved |
| `docs/operations/bootstrap.md` | Complete bootstrap omitted restoration of the qualified host-storage mount | `ansible/playbooks/storage.yml` | Add non-destructive storage-role step | Resolved |
| `docs/operations/backup.md` | Claimed `kubernetes/` was reserved for future configuration | Current `kubernetes/platform/` tree | Describe current desired state and `manifests/` placeholder accurately | Resolved |
| `docs/operations/troubleshooting.md` | Did not cover the qualified storage mount | Storage role and WO-0009 | Add identity-safe mount troubleshooting | Resolved |
| Existing overview, infrastructure and operations pages | Repeated addresses and inventory without declaring an authoritative location | Documentation source-of-truth model | Create Reference pages and add authority notes and cross-links | Resolved |
| `mkdocs.yml` | No Reference navigation; ADR template and two Development pages were omitted | Pre-change strict build output and tracked docs tree | Add Reference, ADR template and Development navigation | Resolved |
| `docs/decisions/ADR-0003-kubernetes-distribution.md` | ADR remains Proposed although K3s is implemented | K3s Ansible role and `PROJECT_STATE.md` | Preserve ADR; record status versus implementation in register | Unresolved, documented |
| `docs/decisions/ADR-0007-homelab-target-architecture.md` | Tracked ADR file is zero length | Repository file state | Do not reconstruct; mark Pending verification | Unresolved, documented |
| `docs/decisions/ADR-0010-ingress-foundation.md` | Historical consequences say TLS remains future | ADR-0011 and WO-0007 | Preserve historical text and explain subsequent implementation in register | Documented, no change |
| Software versions | K3s, Kubernetes, containerd, Ansible, Helm, kubectl and exact OS image are not repository-pinned | Installer tasks and dependency files | Mark Not pinned or Pending verification | Resolved as explicit state |
| Storage terminology | `/srv/longhorn` could be mistaken for a deployed storage platform | Storage role and WO-0009 non-goals | State repeatedly that Longhorn is not installed | Resolved |

## Navigation Result

All Markdown pages under `docs/` are now included in `mkdocs.yml` navigation.
The empty ADR-0007 remains reachable so its missing content is visible rather
than hidden.

## Unresolved Verification Questions

- ADR-0003 requires an explicit architecture decision on whether its status
  should change from Proposed to Accepted.
- ADR-0007 requires recovery or a separately reviewed replacement decision.
- The current runtime K3s, Kubernetes, containerd, CoreDNS, Metrics Server and
  Local Path Provisioner versions are not established by repository evidence.
- The exact Raspberry Pi OS image release, home-router model and management
  workstation model are not recorded in repository-controlled evidence.
- External URL availability was not treated as repository state; internal links
  and navigation are covered by the strict MkDocs build.

## Security Review

No private key, password, token, Kubernetes Secret value or certificate private
material was copied into documentation or WO-1004 evidence. Sensitive runtime
files are outside the documentation source-of-truth model.
