
# HomeLab

Enterprise-inspired private cloud and hybrid homelab platform.

HomeLab is a long-term engineering project to design, build, operate and document a reproducible private infrastructure platform using commodity hardware. The initial platform is a four-node Raspberry Pi Kubernetes cluster. The target platform will expand into a hybrid ARM and x86 homelab with internal DNS, ingress, monitoring, storage, automation and AI workloads.

---

## Current status

| Area | Status |
|------|--------|
| Raspberry Pi 4 cluster | Complete |
| Raspberry Pi OS / Debian 13 baseline | Complete |
| SSH key access | Complete |
| Ansible inventory and roles | Complete |
| K3s Kubernetes cluster | Complete |
| MkDocs documentation platform | In progress |
| Networking services | Planned |
| Monitoring | Planned |
| Storage | Planned |
| AI platform | Planned |

---

## Documentation

The documentation site is built with MkDocs Material.

To preview locally:

```bash
cd homelab
source .venv/bin/activate
mkdocs serve
```

Then open:

```text
http://127.0.0.1:8000
```

The documentation starts at:

```text
docs/index.md
```

---

## Guiding principles

HomeLab follows these principles:

- Infrastructure as Code
- Git as the source of truth
- Idempotent automation
- Documentation-first engineering
- Architecture Decision Records
- Human-readable operational runbooks
- Hybrid ARM and x86 design
- Reproducibility over manual configuration

---

## Current cluster

| Host | IP address | Role |
|------|------------|------|
| pi4mB01 | 192.168.68.101 | K3s control plane |
| pi4mB02 | 192.168.68.102 | K3s worker |
| pi4mB03 | 192.168.68.103 | K3s worker |
| pi4mB04 | 192.168.68.104 | K3s worker |

---

## Next milestone

The next infrastructure milestone is the networking foundation:

- MetalLB
- Ingress controller
- Pi-hole / internal DNS
- `.home.arpa` naming
- internal service URLs
