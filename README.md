# HomeLab

Enterprise-inspired private cloud and hybrid homelab platform.

HomeLab is a long-term engineering project for building and operating a
reproducible private infrastructure platform with commodity hardware. The
current platform is a four-node Raspberry Pi K3s cluster; the target platform
adds x86 compute, stronger storage, observability, GitOps and AI workloads only
through approved incremental work.

---

## Current Status

| Area | Status |
|------|--------|
| Raspberry Pi, Ansible and K3s foundations | Complete |
| Wired networking, MetalLB and Pi-hole DNS | Complete |
| Traefik ingress, private PKI and trusted HTTPS | Complete |
| MkDocs overview, infrastructure, operations and reference documentation | Complete |
| Storage hardware foundation | Partial: one node qualified |
| Replicated Kubernetes storage | Not installed |
| Observability, GitOps, secrets management and AI platform | Planned |

The current verified platform state is maintained in `PROJECT_STATE.md`.

---

## Documentation

The documentation site is built with MkDocs Material.

```bash
source .venv/bin/activate
mkdocs serve
```

Open `http://127.0.0.1:8000`. Documentation sources begin at
`docs/index.md`; authoritative lookup tables are under `docs/reference/`.

---

## Guiding Principles

- Infrastructure as Code
- Git as the source of truth
- idempotent automation
- documentation-first engineering
- Architecture Decision Records
- reproducible operational runbooks
- service identities separate from machine identities

---

## Current Cluster

| Host | IP Address | Role |
|------|------------|------|
| `pi4mB01` | `192.168.68.101` | K3s control plane |
| `pi4mB02` | `192.168.68.102` | K3s worker |
| `pi4mB03` | `192.168.68.103` | K3s worker |
| `pi4mB04` | `192.168.68.104` | K3s worker |

See the documentation [Infrastructure Inventory](docs/reference/infrastructure-inventory.md)
and [Service Catalog](docs/reference/service-catalog.md) for current details.

---

## Next Eligible Work

Storage expansion and Longhorn evaluation remain conditional on at least one
additional qualified storage node, stable USB operation, approved storage
architecture and a separately reviewed work order.
