# WO-1004 – Documentation Architecture and Reference Refresh

**Work Order ID:** WO-1004
**Sprint:** Documentation Sprint 4 — Architecture and Reference Refresh
**Status:** Complete
**Primary Agent:** Codex
**Architect:** ChatGPT
**Owner:** Abdul Jabbar
**Reviewer:** Abdul Jabbar / ChatGPT

---

# Risk Classification

**Implementation risk:** Low
**Information-integrity risk:** Medium

This work order does not change the running infrastructure.

Its primary risk is publishing documentation that is incomplete, contradictory,
outdated, or incorrectly presents planned capabilities as already implemented.

All statements must therefore be verified against repository-controlled evidence.

---

# Objective

Refresh the HomeLab documentation so it accurately represents the platform after
Infrastructure Sprints 4 through 9, and create the planned Reference documentation
section.

The completed documentation shall provide:

- an accurate description of the current platform
- a clear separation between current and target architecture
- authoritative inventory and addressing references
- an authoritative software and service inventory
- an index of architecture decisions
- consistent terminology and cross-links
- an updated roadmap
- an accurate repository structure
- evidence that the complete documentation site builds successfully

This is a documentation-only sprint.

No infrastructure implementation is part of this work order.

---

# Background

The previous documentation foundation was completed through:

- WO-1001 — Documentation Overview
- WO-1002 — Documentation Infrastructure
- WO-1003 — Documentation Operations

Since those documentation sprints, HomeLab has added or completed:

- MetalLB Layer 2 networking
- Pi-hole internal DNS
- wired Ethernet as the managed cluster transport
- Traefik shared ingress
- private PKI
- cert-manager
- trusted internal HTTPS
- Pi-hole secure ingress
- storage hardware qualification
- a dedicated Ansible storage role
- `/srv/longhorn` storage preparation on `pi4mB01`
- additional ADRs
- additional Kubernetes manifests and Helm configuration
- validation artifacts and evidence directories
- the pull-request-based work-order workflow

Some documentation has been updated incrementally, but the documentation set has
not received a complete consistency review since Documentation Sprint 3.

The planned successor to WO-1003 was Reference Documentation covering:

- inventory
- naming
- IP addressing
- software inventory
- glossary

This work order implements that reference section and refreshes the existing
architecture documentation around it.

---

# Goals

- Establish authoritative reference documents.
- Remove stale platform descriptions.
- Correct current-versus-planned ambiguity.
- Refresh architecture diagrams and topology descriptions.
- Refresh the long-term roadmap.
- Refresh the documented repository structure.
- Create a central service and software inventory.
- Create a central ADR register.
- Improve cross-links between related documents.
- Verify documentation navigation and build integrity.
- Record all identified documentation drift.
- Preserve historical work orders and architecture decisions.

---

# Documentation Source-of-Truth Model

The documentation shall follow this responsibility model.

| Source | Responsibility |
|--------|----------------|
| `README.md` | Concise repository landing page |
| `PROJECT_STATE.md` | Current verified project state |
| `docs/overview/` | Vision, architecture, roadmap and repository model |
| `docs/infrastructure/` | How platform components are designed and implemented |
| `docs/operations/` | Procedures, maintenance, troubleshooting and recovery |
| `docs/reference/` | Authoritative lookup tables and stable reference information |
| `docs/decisions/` | Why significant architecture decisions were made |
| `work-orders/` | Planned and historical units of work |
| `artifacts/` | Evidence produced while executing work orders |
| `ansible/` | Executable host configuration truth |
| `kubernetes/` | Executable Kubernetes configuration truth |

When two documents duplicate the same data, one location must be identified as
authoritative and the other must link to it.

Stable lookup data should normally be stored under `docs/reference/`.

---

# Verification Sources

Codex shall verify documentation against repository-controlled sources, including:

```text
PROJECT_STATE.md
README.md
mkdocs.yml
ansible/inventories/
ansible/playbooks/
ansible/roles/
kubernetes/
docs/decisions/
work-orders/
artifacts/
````

Do not guess configuration values.

Do not rely solely on statements in older documentation.

Where repository sources conflict:

1. inspect executable configuration
2. inspect evidence from the latest completed work order
3. inspect `PROJECT_STATE.md`
4. record the conflict
5. correct the documentation only when the current state can be established

If the current truth cannot be established, use:

```text
Pending verification
```

and record the issue in the documentation audit.

---

# Scope

## Create

```text
docs/
└── reference/
    ├── index.md
    ├── infrastructure-inventory.md
    ├── naming-and-addressing.md
    ├── software-inventory.md
    ├── service-catalog.md
    ├── decision-register.md
    └── glossary.md
```

## Review and update

```text
README.md
PROJECT_STATE.md
mkdocs.yml

docs/index.md

docs/overview/
├── vision.md
├── architecture.md
├── repository.md
└── roadmap.md

docs/infrastructure/
docs/operations/
docs/decisions/
```

Existing infrastructure and operations documents shall only be changed where
necessary to correct drift, improve links, or clearly separate current and future
state.

---

# Deliverables

## Phase 1 — Documentation Audit

Inspect the complete current documentation tree.

Create:

```text
artifacts/WO-1004/documentation-audit.md
```

The audit shall identify:

* stale information
* contradictory information
* duplicate authoritative data
* missing cross-links
* incorrect file paths
* outdated repository diagrams
* planned capabilities presented as implemented
* implemented capabilities still presented as planned
* missing navigation entries
* inconsistent terminology
* orphaned documentation pages
* documentation referenced by MkDocs but missing
* documentation files not reachable through MkDocs navigation
* unresolved verification questions

Use a table similar to:

| Document                   | Finding                                            | Evidence                  | Required Action     | Status |
| -------------------------- | -------------------------------------------------- | ------------------------- | ------------------- | ------ |
| `docs/overview/roadmap.md` | Storage foundation still shown entirely as planned | WO-0009 and PROJECT_STATE | Update phase status | Open   |

The audit must be committed as review evidence.

---

## Phase 2 — Reference Landing Page

Create:

```text
docs/reference/index.md
```

The page shall explain:

* the purpose of reference documentation
* which data is authoritative
* how reference pages differ from architecture and operations pages
* how frequently reference information should be updated
* links to every reference page
* the relationship to `PROJECT_STATE.md`

The reference section shall be optimized for quick lookup rather than narrative
explanation.

---

## Phase 3 — Infrastructure Inventory

Create:

```text
docs/reference/infrastructure-inventory.md
```

Document the current verified physical and logical inventory.

Include at minimum:

### Cluster nodes

* hostname
* IP address
* architecture
* role
* network interface
* Kubernetes role
* storage state
* operational status

Expected current nodes:

```text
pi4mB01
pi4mB02
pi4mB03
pi4mB04
```

### Network hardware

Include known managed infrastructure such as:

* home router or gateway role
* TP-Link TL-SG108E switch
* cluster network
* default gateway
* Ethernet transport
* Wi-Fi state

Do not invent hardware model details that are not stored in the repository.

### Storage hardware

Include:

* node
* disk model
* capacity
* enclosure or bridge
* filesystem
* filesystem label
* mount path
* qualification status
* known limitation

The current and pending storage states must be explicit.

For example:

* `pi4mB01` has qualified storage.
* `pi4mB02` has a known WD disk but it is not yet qualified.
* `pi4mB03` and `pi4mB04` do not yet have qualified dedicated storage.
* Longhorn is not installed.

Detailed SMART data and benchmark evidence shall remain in the relevant work-order
artifacts and infrastructure storage documentation rather than being duplicated in
full.

---

## Phase 4 — Naming and Addressing Reference

Create:

```text
docs/reference/naming-and-addressing.md
```

Consolidate the authoritative naming and addressing conventions.

Include:

### Host naming

Document the current convention represented by:

```text
pi4mB01
pi4mB02
pi4mB03
pi4mB04
```

Explain:

* device family
* model identifier
* sequence identifier
* case sensitivity considerations
* difference between configured hostname and display formatting

Do not create a new naming convention during this sprint.

Document the convention that currently exists.

### Network addressing

Include:

* home LAN subnet
* default gateway
* node addresses
* MetalLB pool
* assigned LoadBalancer addresses
* reserved addresses where verifiable
* DNS names
* purpose of each address

### Internal DNS naming

Document:

```text
home.arpa
```

Include current names such as:

```text
pihole.home.arpa
test.home.arpa
elm.home.arpa
```

Clearly identify whether each name is:

* active
* reserved
* validation-only
* planned

### Address allocation rules

Document the current rules for:

* infrastructure node addresses
* DHCP reservations
* MetalLB addresses
* shared ingress addresses
* DNS-only services
* browser-facing applications
* future address allocation

Avoid duplicating detailed ingress design from the infrastructure documents.
Link to it instead.

---

## Phase 5 — Software Inventory

Create:

```text
docs/reference/software-inventory.md
```

Document verified platform software and version information.

Include at minimum:

* Raspberry Pi operating system
* Ansible
* K3s
* Kubernetes version, when repository evidence exists
* container runtime
* MetalLB
* Traefik Helm chart
* Traefik application
* cert-manager Helm chart or application
* Pi-hole image
* MkDocs
* MkDocs Material
* relevant Python tooling

Use version sources in the following order:

1. pinned executable repository configuration
2. dependency files
3. completed work-order evidence
4. `PROJECT_STATE.md`

Do not insert a version based only on memory or an old documentation page.

For components whose versions are not pinned or cannot be verified, document:

```text
Not pinned
```

or:

```text
Pending verification
```

Include a source column.

Example:

| Component           | Version  | Deployment Method | Source                          |
| ------------------- | -------- | ----------------- | ------------------------------- |
| Traefik Helm chart  | `41.0.2` | Helm              | Repository values/configuration |
| Traefik application | `v3.7.6` | Helm chart        | Completed ingress work order    |

---

## Phase 6 — Service Catalog

Create:

```text
docs/reference/service-catalog.md
```

Document currently implemented platform services.

Include:

* service name
* category
* namespace
* exposure method
* DNS name
* IP address where applicable
* ports
* TLS state
* persistence state
* owner or management mechanism
* operational status
* related documentation

Expected service categories include:

* Kubernetes platform
* DNS
* load balancing
* ingress
* certificate management
* test or validation services

Clearly distinguish:

* production-like platform services
* temporary validation services
* reserved future services

Do not describe a planned service as deployed.

Longhorn must be shown as:

```text
Not installed / planned evaluation
```

---

## Phase 7 — Architecture Decision Register

Create:

```text
docs/reference/decision-register.md
```

Create a concise register for all current ADRs.

Include:

* ADR number
* title
* status
* decision area
* implementation state
* related work order
* link to ADR

Review ADR-0001 through the latest ADR.

Possible status values:

```text
Accepted
Implemented
Partially implemented
Proposed
Superseded
Deprecated
```

Do not rewrite historical decisions merely to match the current architecture.

Permitted ADR changes during this sprint:

* spelling corrections
* broken-link corrections
* explicit status correction
* related-document links
* clearly factual implementation-state notes

A material architecture change requires a new ADR and is outside this work order.

If an ADR appears obsolete or contradicted, record the finding in the audit rather
than silently rewriting the decision.

---

## Phase 8 — Glossary

Create:

```text
docs/reference/glossary.md
```

Define recurring HomeLab terms and abbreviations.

Include at minimum:

* ADR
* Ansible
* CA
* cert-manager
* ClusterIP
* control plane
* CSI
* DHCP reservation
* DNS
* Helm
* ingress
* issuing CA
* K3s
* Kubernetes
* LoadBalancer
* Longhorn
* MetalLB
* namespace
* node
* PKI
* Pod
* PVC
* PV
* Root CA
* SAN
* Service
* StorageClass
* Traefik
* UASP
* worker node

Definitions shall be:

* concise
* HomeLab-specific where useful
* understandable without requiring external documentation
* linked to detailed HomeLab documentation where appropriate

The glossary must not imply that planned technologies are already installed.

---

## Phase 9 — Architecture Refresh

Review and update:

```text
docs/overview/architecture.md
```

The document must accurately describe the current architecture after WO-0009.

Update the current topology to include:

* four-node Raspberry Pi K3s cluster
* wired Ethernet transport
* TP-Link switch
* MetalLB
* Pi-hole DNS
* Traefik
* cert-manager
* private PKI
* shared HTTPS ingress
* current service addresses
* current local-path storage
* qualified host storage on `pi4mB01`

Clearly separate:

```text
Current Architecture
```

from:

```text
Target Architecture
```

The current architecture must not show Longhorn, replicated storage, NAS, GitOps,
observability or x86 compute as implemented.

The target architecture may include:

* additional qualified node storage
* Longhorn evaluation
* centralized NAS or backup target
* observability
* GitOps
* secrets management
* x86 compute
* AI workloads

Future NAS or enterprise storage ideas must be described as possible architecture,
not approved implementation.

Where useful, include separate diagrams for:

* physical topology
* service exposure
* certificate flow
* current storage topology
* target storage topology

Use text-based diagrams unless an existing repository diagram standard says
otherwise.

---

## Phase 10 — Roadmap Refresh

Review and update:

```text
docs/overview/roadmap.md
```

Correct phase statuses to reflect the current completed work.

At minimum:

* Documentation Foundation is no longer merely in progress.
* Networking Foundation reflects completed ingress and PKI work.
* Storage distinguishes hardware foundation from distributed storage.
* WO-0009 storage qualification is shown as completed.
* Longhorn remains conditional and not implemented.
* Reference Documentation is shown as the current documentation sprint.
* Observability, GitOps, secrets, NAS, AI and hybrid compute remain future work
  unless repository evidence proves otherwise.

The roadmap shall distinguish:

```text
Complete
In progress
Ready
Blocked
Planned
Exploratory
```

Dependencies must be explicit.

Example:

```text
Longhorn evaluation
    depends on
at least one additional qualified storage node
```

Do not assign work-order numbers to future work unless those work orders have been
approved.

---

## Phase 11 — Repository Documentation Refresh

Review and update:

```text
docs/overview/repository.md
```

Ensure the documented repository tree reflects the actual repository.

Include current top-level areas such as:

* Ansible
* Kubernetes
* documentation
* decisions
* work orders
* artifacts
* requirements
* scripts
* project state
* MkDocs configuration

Review and update documented:

* Ansible roles
* playbooks
* inventory layout
* Kubernetes directory structure
* documentation sections
* work-order lifecycle
* evidence directory convention
* pull-request review workflow

Remove directory descriptions that are no longer accurate.

Do not list every individual artifact file in the main repository overview.

Link to detailed documentation instead.

---

## Phase 12 — Existing Documentation Consistency Review

Review all pages under:

```text
docs/infrastructure/
docs/operations/
```

Correct only verified issues such as:

* obsolete current-state descriptions
* outdated file paths
* broken related-document links
* inconsistent service addresses
* incorrect terminology
* references to completed work as future work
* references to unimplemented work as current
* missing links to the new reference section

Avoid unnecessary rewrites.

Existing documents should retain their primary responsibility.

Examples:

* storage design remains in `docs/infrastructure/storage.md`
* backup procedures remain in `docs/operations/backup.md`
* address tables become authoritative in
  `docs/reference/naming-and-addressing.md`
* infrastructure documents link to reference tables rather than maintaining
  competing copies

---

## Phase 13 — Cross-Link Audit

Every documentation page shall contain useful related-document links where
appropriate.

Important navigation paths include:

```text
Architecture
    -> Roadmap
    -> Infrastructure
    -> Reference
    -> ADRs
    -> Operations
```

```text
Storage
    -> Infrastructure Inventory
    -> Storage ADR
    -> Backup
    -> WO-0009 evidence
```

```text
Ingress
    -> Service Catalog
    -> Naming and Addressing
    -> PKI
    -> Certificate Operations
```

```text
Work Order
    -> PROJECT_STATE
    -> Architecture documentation
    -> ADR
    -> Evidence
```

Links should be relative Markdown links where possible.

Do not add links merely for quantity. Links must help a reader continue to the
next relevant source.

---

## Phase 14 — MkDocs Navigation

Update:

```text
mkdocs.yml
```

Add a Reference section.

Expected structure:

```yaml
- Reference:
    - Overview: reference/index.md
    - Infrastructure Inventory: reference/infrastructure-inventory.md
    - Naming and Addressing: reference/naming-and-addressing.md
    - Software Inventory: reference/software-inventory.md
    - Service Catalog: reference/service-catalog.md
    - Decision Register: reference/decision-register.md
    - Glossary: reference/glossary.md
```

Retain the existing major navigation sections:

* Home
* Overview
* Architecture Decisions
* Infrastructure
* Operations
* Reference

Correct missing or incorrectly ordered navigation items where necessary.

Do not redesign the MkDocs visual theme during this sprint.

---

## Phase 15 — Project State Update

Update:

```text
PROJECT_STATE.md
```

After successful validation:

* record Documentation Sprint 4 as complete
* summarize the new reference documentation
* update the current documentation state
* remove documentation risks resolved by this sprint
* retain unresolved documentation risks
* retain accurate infrastructure risks
* update the last-updated date
* identify the next eligible work package without presenting it as approved

The next infrastructure work remains conditional on storage hardware readiness.

Do not state that Longhorn is ready for deployment unless the required storage
hardware has been qualified.

---

# Documentation Standards

All newly created documents shall follow the HomeLab documentation structure:

```markdown
# Title

---

## Purpose

## Scope

## Background

## Architecture / Implementation

## Design Decisions

## Best Practices

## Future Improvements

## Related Documents
```

Reference pages may adapt the central body into tables and lookup sections where
that improves usability, but they must still include:

* Purpose
* Scope
* authoritative-source explanation
* related documents

Use:

* consistent heading hierarchy
* fenced code blocks with language identifiers where applicable
* Markdown tables for structured reference information
* repository-relative paths in backticks
* relative documentation links
* exact product capitalization
* exact Kubernetes resource names
* explicit current/planned labels

Preferred terminology:

```text
Raspberry Pi
K3s
Kubernetes
MetalLB
Traefik
cert-manager
Pi-hole
Longhorn
MkDocs Material
StorageClass
PersistentVolume
PersistentVolumeClaim
```

Do not alternate between different spellings for the same component.

---

# Current-versus-Future Rule

Every capability must be placed into one of these states:

| State                | Meaning                                                  |
| -------------------- | -------------------------------------------------------- |
| Current              | Implemented and verified                                 |
| Partial              | Some foundation exists, but the capability is incomplete |
| Planned              | Approved direction but not implemented                   |
| Exploratory          | Being considered, not approved                           |
| Retired              | No longer used                                           |
| Pending verification | Repository evidence is insufficient                      |

Examples:

| Capability                    | Required classification |
| ----------------------------- | ----------------------- |
| MetalLB                       | Current                 |
| Traefik                       | Current                 |
| cert-manager                  | Current                 |
| Pi-hole secure ingress        | Current                 |
| Qualified disk on `pi4mB01`   | Current                 |
| Qualified disk on `pi4mB02`   | Not current             |
| Longhorn                      | Planned evaluation      |
| Replicated Kubernetes storage | Not implemented         |
| NAS                           | Exploratory             |
| Observability stack           | Planned                 |
| GitOps                        | Planned                 |
| AI platform                   | Planned                 |

---

# Security Requirements

The documentation shall not expose:

* private keys
* passwords
* Kubernetes Secrets
* Ansible Vault contents
* API tokens
* join tokens
* certificate private-key material
* confidential recovery material
* credentials embedded in command examples

Certificate names, public certificate metadata and public CA installation
procedures may be documented.

Sensitive values shall use placeholders.

Example:

```text
<REDACTED>
<SECRET>
<TOKEN>
```

---

# Allowed Repository Changes

This work order may change only:

```text
README.md
PROJECT_STATE.md
mkdocs.yml
docs/**
work-orders/CURRENT.md
work-orders/WO-1004-documentation-architecture-reference-refresh.md
artifacts/WO-1004/**
```

Changes outside this allowlist require explicit reviewer approval.

---

# Explicit Non-Goals

This work order shall not:

* install Longhorn
* install a NAS operating system
* modify Kubernetes resources
* modify Helm releases
* modify Ansible roles
* modify Ansible inventory
* modify playbooks
* modify host configuration
* modify network configuration
* change IP addresses
* create DNS records
* modify certificates
* rotate keys
* add monitoring software
* introduce GitOps
* deploy applications
* qualify the WD disk
* benchmark storage hardware
* make new architecture decisions
* rewrite historical ADRs
* delete historical work orders
* introduce a new documentation framework
* redesign the MkDocs theme

Any discovered infrastructure defect shall be documented as a finding rather than
fixed during this sprint.

---

# Evidence

Create:

```text
artifacts/
└── WO-1004/
    ├── documentation-audit.md
    ├── files-reviewed.txt
    ├── mkdocs-build.txt
    ├── link-review.md
    ├── consistency-review.md
    └── validation.md
```

## `files-reviewed.txt`

List all documentation and repository files inspected during the sprint.

## `mkdocs-build.txt`

Capture the strict MkDocs build output.

## `link-review.md`

Record:

* broken links found
* links corrected
* unresolved external links
* orphaned pages
* pages added to navigation

## `consistency-review.md`

Record checks for:

* hostnames
* IP addresses
* service names
* namespaces
* software versions
* current/planned state
* terminology
* storage state
* ADR status

## `validation.md`

Provide the final acceptance checklist and result.

---

# Validation

Use the repository’s documented Python environment.

Run:

```bash
source .venv/bin/activate
mkdocs build --strict
git diff --check
```

If the environment uses a different documented activation command, use the
repository-defined command and record it.

Also verify:

```bash
git status --short
git diff --name-only
```

Confirm that every changed path is inside the work-order allowlist.

Review MkDocs output for:

* missing files
* broken internal links
* invalid navigation
* duplicate navigation entries
* malformed Markdown
* unresolved references
* pages omitted from navigation

Where practical, preview locally:

```bash
mkdocs serve
```

Verify manually:

* navigation order
* Reference section
* tables
* diagrams
* code blocks
* dark and light theme readability
* link traversal
* mobile-width table behavior where practical

Do not mark the sprint complete when `mkdocs build --strict` fails.

---

# Validation Checklist

* [ ] Documentation audit completed
* [ ] Reference landing page created
* [ ] Infrastructure inventory created
* [ ] Naming and addressing reference created
* [ ] Software inventory created
* [ ] Service catalog created
* [ ] Decision register created
* [ ] Glossary created
* [ ] Architecture refreshed
* [ ] Roadmap refreshed
* [ ] Repository structure refreshed
* [ ] Existing infrastructure documentation reviewed
* [ ] Existing operations documentation reviewed
* [ ] ADR status and links reviewed
* [ ] Current and future capabilities clearly separated
* [ ] Storage state accurately documented
* [ ] Longhorn correctly identified as not installed
* [ ] Cross-links reviewed
* [ ] MkDocs navigation updated
* [ ] `PROJECT_STATE.md` updated
* [ ] Evidence committed
* [ ] `mkdocs build --strict` passed
* [ ] `git diff --check` passed
* [ ] No infrastructure files modified
* [ ] No sensitive values exposed

---

# Acceptance Criteria

The sprint passes when:

* all seven Reference pages exist
* Reference navigation is present in `mkdocs.yml`
* inventory data is consolidated
* naming and addressing data is consolidated
* software versions are verified or explicitly marked unverified
* the current service catalog is accurate
* every ADR appears in the decision register
* the glossary covers recurring platform terminology
* architecture documentation reflects the platform through WO-0009
* roadmap statuses reflect completed infrastructure work
* repository documentation matches the actual repository
* current and future architecture are visually and textually separated
* the storage foundation is accurately described
* Longhorn is not presented as installed
* NAS is not presented as an approved architecture
* existing documentation contains useful cross-links
* duplicate authoritative data is reduced
* unresolved discrepancies are documented
* MkDocs builds successfully in strict mode
* no executable infrastructure configuration is changed
* all validation evidence is committed
* `PROJECT_STATE.md` is updated

---

# Work-Order Lifecycle

During implementation, this work order remains at:

```text
work-orders/CURRENT.md
```

After all acceptance criteria pass:

1. archive the completed work order as:

```text
work-orders/WO-1004-documentation-architecture-reference-refresh.md
```

2. change its status to:

```text
Complete
```

3. remove:

```text
work-orders/CURRENT.md
```

4. update:

```text
PROJECT_STATE.md
```

5. create a pull request for review

Do not archive the work order before validation succeeds.

---

# Git Workflow

Recommended branch:

```text
wo-1004-documentation-architecture-reference-refresh
```

Recommended commit style:

```text
docs: add authoritative reference documentation
docs: refresh architecture roadmap and repository guides
docs: complete WO-1004 validation evidence
```

Recommended pull-request title:

```text
WO-1004: Documentation architecture and reference refresh
```

The pull-request description shall include:

* summary of reference pages created
* stale documentation corrected
* architecture and roadmap changes
* ADR register result
* MkDocs validation result
* changed-file allowlist confirmation
* unresolved findings
* explicit statement that no infrastructure was changed

---

# Completion Output

Codex shall conclude with:

```text
WO-1004 Completion Summary

Reference Documents Created:
- ...

Existing Documents Updated:
- ...

Documentation Drift Corrected:
- ...

Current-versus-Planned Corrections:
- ...

ADR Review:
- ...

Validation:
- mkdocs build --strict:
- git diff --check:
- changed-file allowlist:

Unresolved Findings:
- ...

Infrastructure Changes:
- None

Final Result:
PASS / FAIL
```

---

# Definition of Done

After this sprint, an engineer unfamiliar with HomeLab shall be able to answer,
using only the documentation:

* What hardware exists?
* Which nodes belong to the cluster?
* What are their addresses and roles?
* Which services are deployed?
* How are services exposed?
* Which DNS names are active or reserved?
* Which software versions are pinned?
* Which architecture decisions are active?
* What storage exists today?
* What storage remains planned?
* What work has been completed?
* What work is next?
* Where are operational procedures?
* Where is implementation evidence?
* Which document is authoritative for each type of information?

The documentation must describe the platform that actually exists, not merely the
platform that was originally planned.

---

# Successor Work

No successor work order is automatically approved by completing WO-1004.

The likely next infrastructure activity is storage expansion and Longhorn
evaluation, but it remains conditional on:

* arrival of the SATA-to-USB enclosure
* qualification of at least one additional storage disk
* stable USB operation
* approved storage architecture
* a separately reviewed work order

```

This scope is intentionally larger than the original five-page Reference sprint because the current roadmap still describes Documentation Foundation as in progress, and the repository guide still lists only the early Ansible roles and a pre-expansion documentation tree.
```
