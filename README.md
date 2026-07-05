## Documentation

This repository is intentionally documented as an engineering project rather than a collection of scripts.

| Document | Purpose |
|----------|---------|
| README.md | Project overview, setup, progress and milestones |
| ARCHITECTURE.md | Architectural decisions, rationale and technology choices |

The goal is that anyone (including my future self) can understand not only **how** the infrastructure is built, but **why** each design decision was made.# HomeLab - Private Cloud Platform

## Vision

This project aims to build a small enterprise-grade private cloud using low-power ARM devices.

Rather than being "just a Raspberry Pi cluster", the objective is to learn and operate technologies commonly found in modern production environments, including:

- Linux administration
- Infrastructure as Code
- Configuration Management
- Kubernetes
- GitOps
- Monitoring & Observability
- Edge AI
- High Availability concepts

Every configuration change is version controlled and automated wherever possible.

---

# Hardware

## Current Infrastructure

| Device | Quantity |
|----------|---------:|
| Raspberry Pi 4 Model B | 4 |
| Dell Latitude 5591 (Management Node) | 1 |

### Raspberry Pi Nodes

| Hostname | IP Address |
|-----------|------------|
| pi4mB01 | 192.168.68.101 |
| pi4mB02 | 192.168.68.102 |
| pi4mB03 | 192.168.68.103 |
| pi4mB04 | 192.168.68.104 |

---

## Planned Expansion

| Device | Quantity |
|----------|---------:|
| Turing Pi 2 | 1 |
| Raspberry Pi Compute Module 4 | 2 |
| Turing RK1 | 2 |

Future hostnames:

- cm401
- cm402
- rk101
- rk102

---

# Management Workstation

Administration is performed from:

Dell Latitude 5591

Operating System:

Arch Linux

Installed management tools:

- Git
- OpenSSH
- Ansible
- kubectl
- Helm
- jq
- yq

SSH authentication uses an Ed25519 key protected by ssh-agent.

---

# Repository Structure

```
homelab/
│
├── ansible/
│   ├── ansible.cfg
│   ├── inventories/
│   ├── playbooks/
│   └── roles/
│
├── kubernetes/
│
├── monitoring/
│
├── docs/
│
├── scripts/
│
└── README.md
```

---

# Design Principles

The project follows several engineering principles.

## Infrastructure as Code

All infrastructure changes are automated.

Manual configuration is avoided wherever possible.

Ansible is used to provision and maintain every node.

---

## Single Source of Truth

Git is considered the authoritative source.

If a Raspberry Pi fails, it should be possible to rebuild it from scratch using only this repository.

---

## Idempotency

Playbooks are designed to be safely executed multiple times.

Running a playbook repeatedly should never produce unwanted side effects.

Example:

- cgroup configuration
- package installation
- timezone configuration

---

## Separation of Concerns

Responsibilities are intentionally separated.

Inventory describes **where** automation runs.

Playbooks describe **what** should happen.

Roles encapsulate reusable functionality.

---

## Documentation First

Every playbook contains detailed documentation describing:

- What problem it solves.
- Why it exists.
- Architectural trade-offs.
- Implementation details.

The objective is to create infrastructure that is understandable months or years later.

---

# Completed Milestones

## Milestone 1

Initial Infrastructure

Completed:

- Raspberry Pi OS Lite (64-bit)
- SSH enabled
- Fixed hostnames
- Fixed IP addresses
- Passwordless SSH
- Git repository
- Ansible project
- Inventory structure
- Update playbook
- Baseline playbook

---

# Next Milestones

## Phase 2

Operating System Hardening

- Security updates
- Additional packages
- Kernel tuning
- Verification tasks

---

## Phase 3

Kubernetes

- K3s
- Traefik
- MetalLB

---

## Phase 4

Storage

- Longhorn
- Backup strategy

---

## Phase 5

Monitoring

- Prometheus
- Grafana
- Loki
- Alertmanager

---

## Phase 6

GitOps

- FluxCD

---

## Phase 7

AI Platform

- Ollama
- Open WebUI
- AnythingLLM

---

## Phase 8

Turing Pi Integration

- RK1 AI Nodes
- CM4 Infrastructure Nodes

---

# Long-Term Goal

The final platform should resemble a small enterprise edge cloud capable of hosting:

- Containerized applications
- CI/CD pipelines
- Kubernetes workloads
- AI inference
- Monitoring
- VPN services
- Home automation
- Private developer tools

while remaining fully reproducible from Infrastructure as Code.
