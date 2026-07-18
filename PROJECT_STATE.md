# HomeLab Project State

**Project:** HomeLab  
**Owner:** Abdul Jabbar  
**Status:** Active Development  
**Last Updated:** 2026-07-18

---

## Current Platform State

HomeLab has completed its first seven engineering implementation sprints and the first three documentation sprints.

The current platform is a working four-node Raspberry Pi K3s Kubernetes cluster with wired Ethernet node transport, MetalLB LoadBalancer support, Pi-hole internal DNS, trusted Traefik HTTPS, automated cert-manager certificate lifecycle, Ansible automation and MkDocs Material documentation.

---

## Completed Milestones

### Infrastructure Sprint 1 — Raspberry Pi Foundation

Status: Complete

Completed:

- Raspberry Pi OS / Debian 13 installed
- hostnames configured
- DHCP reservations configured
- SSH key-based access configured
- management workstation prepared

### Infrastructure Sprint 2 — Ansible Foundation

Status: Complete

Completed:

- Ansible project structure
- inventory split into groups, host variables and group variables
- common role
- update playbook
- baseline playbook
- idempotent package, swap, cgroup and time configuration
- verification tasks

### Infrastructure Sprint 3 — Kubernetes Foundation

Status: Complete

Completed:

- K3s installed
- pi4mB01 configured as control-plane node
- pi4mB02, pi4mB03 and pi4mB04 joined as workers
- kubeconfig fetched to management workstation
- worker nodes labelled
- cluster verification completed

### Infrastructure Sprint 4 — Networking Foundation

Status: Complete

Completed:

- MetalLB installed in Layer 2 mode
- LoadBalancer address pool `192.168.68.200-192.168.68.220` configured
- Pi-hole deployed in Kubernetes
- Pi-hole assigned stable LoadBalancer IP `192.168.68.200`
- `pihole.home.arpa` configured
- `.home.arpa` naming convention established
- `elm.home.arpa` reserved for future IBM ELM publication
- networking documentation updated

### Infrastructure Sprint 5 — Wired Network Baseline

Status: Complete

Completed:

- TP-Link TL-SG108E deployed as the wired cluster switch
- all Raspberry Pi Kubernetes nodes migrated to Ethernet transport
- dedicated Ansible `network` role created
- Ethernet preflight checks implemented before Wi-Fi changes
- Wi-Fi disabled through NetworkManager and verified through Ansible
- wired default routes through `192.168.68.1` verified
- single-node reboot persistence verified on `pi4mB01`
- full-cluster idempotency verified with `changed=0`
- MetalLB Layer 2 reachability verified through the LAN neighbor table and service traffic
- Pi-hole UI and DNS verified from the LAN
- ADR-0009 created

### Infrastructure Sprint 6 — Ingress Foundation

Status: Complete

Completed:

- Traefik selected as the standard Kubernetes Ingress Controller
- official Traefik Helm chart pinned to version `41.0.2`
- Traefik app version pinned through the chart to `v3.7.6`
- dedicated `ingress` namespace created
- Traefik deployed with two replicas
- pod anti-affinity preference configured across Kubernetes nodes
- LoadBalancer Service assigned MetalLB IP `192.168.68.201`
- HTTP and HTTPS entry points exposed on ports `80` and `443`
- Traefik dashboard kept unexposed
- `traefik` IngressClass created
- `traefik/whoami` test application deployed
- `test.home.arpa` configured for ingress validation
- ADR-0010 created

### Infrastructure Sprint 7 — PKI and TLS Foundation

Status: Complete

Completed:

- private two-tier PKI created with an offline Root CA and separate Server and Client Issuing CAs
- Root CA created as `Abdul HomeLab Root CA`, valid until 2046-07-13
- Server Issuing CA created as `Abdul HomeLab Server Issuing CA`, valid until 2036-07-15
- Client Issuing CA created as `Abdul HomeLab Client Issuing CA`, valid until 2036-07-15
- cert-manager chart and application version `v1.21.0` deployed with Helm-managed CRDs
- `homelab-server-ca` ClusterIssuer verified `Ready=True`
- 90-day `test.home.arpa` certificate issued with DNS SAN and server-authentication usage
- Traefik configured for TLS termination and permanent HTTP-to-HTTPS redirection
- trusted HTTPS verified with the HomeLab Root CA
- certificate reissuance and TLS Secret rotation verified without changing the system clock
- Root CA client distribution documented; installation remains operator-controlled and pending by platform
- ADR-0011 created

### Documentation Sprint 1 — Overview Foundation

Status: Complete

Completed:

- README.md simplified as repository landing page
- mkdocs.yml created
- docs/index.md created
- docs/overview/vision.md created
- docs/overview/architecture.md created
- docs/overview/repository.md created
- docs/overview/roadmap.md created

### Documentation Sprint 2 — Infrastructure Foundation

Status: Complete

Completed:

- docs/infrastructure/raspberry-pi-cluster.md created
- docs/infrastructure/ansible.md created
- docs/infrastructure/kubernetes.md created
- docs/infrastructure/networking.md created
- docs/infrastructure/storage.md created
- docs/infrastructure/security.md created
- mkdocs.yml navigation updated with Infrastructure section

### Documentation Sprint 3 — Operations Foundation

Status: Complete

Completed:

- docs/operations/bootstrap.md created
- docs/operations/updating.md created
- docs/operations/rebuilding.md created
- docs/operations/troubleshooting.md created
- docs/operations/backup.md created
- mkdocs.yml navigation updated with Operations section
- work order workflow moved to work-orders/CURRENT.md with completed work orders archived by ID

---

## Current Infrastructure

| Host | IP Address | Role | Status |
|------|------------|------|--------|
| pi4mB01 | 192.168.68.101 | K3s control plane | Ready |
| pi4mB02 | 192.168.68.102 | K3s worker | Ready |
| pi4mB03 | 192.168.68.103 | K3s worker | Ready |
| pi4mB04 | 192.168.68.104 | K3s worker | Ready |

Current node network baseline:

| Setting | Value |
|---------|-------|
| Switch | TP-Link TL-SG108E |
| Node interface | eth0 |
| Default gateway | 192.168.68.1 |
| Node subnet | 192.168.68.0/22 |
| Wi-Fi state | Disabled through Ansible |

Current platform service IPs:

| Service | DNS Name | IP Address | Status |
|---------|----------|------------|--------|
| Pi-hole | pihole.home.arpa | 192.168.68.200 | Ready |
| Traefik ingress | test.home.arpa | 192.168.68.201 | Ready |
| cert-manager | Kubernetes internal | ClusterIP | Ready |

Current LoadBalancer pool:

```text
192.168.68.200-192.168.68.220
```

---

## Current Documentation State

Documentation platform:

- MkDocs Material

Completed sections:

- Home
- Overview
- Vision
- Architecture
- Repository
- Roadmap
- Infrastructure
- Raspberry Pi Cluster
- Ansible
- Kubernetes
- Networking
- Ingress
- Storage
- Security
- Operations
- Bootstrap
- Updating
- Ingress
- Rebuilding
- Troubleshooting
- Backup
- PKI
- Certificates

Next documentation area:

- Reference documentation

---

## Current Risks

No blocking technical risks identified.

Known PKI risk:

- Root CA trust installation is still operator-controlled and pending on each client platform; clients without the Root CA will report the private certificate chain as untrusted.
- CA material requires two verified encrypted offline backups in separate locations; Kubernetes and the management workstation are not sufficient backup targets.

Known documentation risk:

- Reference data such as inventory, naming, IP addressing and software versions should be consolidated in the planned reference documentation sprint.

---

## Next Work Package

Reference documentation sprint.

Create `work-orders/CURRENT.md` when the next work order is prepared.
