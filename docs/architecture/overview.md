# HomeLab Architecture

## Purpose

This document records the architectural decisions behind the HomeLab platform.

It is intentionally written like an Architecture Decision Record (ADR) rather than a tutorial.

The objective is to explain **why** technologies were chosen and the trade-offs involved.

---

# Architectural Vision

The goal is to build a small enterprise-grade edge cloud capable of hosting:

- Kubernetes workloads
- Monitoring platforms
- AI inference
- Developer services
- Home automation
- Infrastructure experiments

while remaining:

- reproducible
- version controlled
- fully automated

The platform should resemble a miniature production environment rather than a collection of individual Raspberry Pis.

```
                         Internet
                             │
                        ISP Router
                             │
                ┌────────────┴─────────────┐
                │                          │
         Management Network          WiFi Clients
                │
        ┌───────┴─────────────────────────────────────────────┐
        │                                                     │
   Raspberry Pi Cluster                                 x86 Cluster
  (Always-on services)                              (Heavy workloads)
        │                                                     │
 pi4mB01  Control Plane                              Dell 5591
 pi4mB02  Worker                                     ThinkPad
 pi4mB03  Worker                                     HP Laptop
 pi4mB04  Worker                                     ...
        │                                                     │
        └────────────── Kubernetes (single cluster) ──────────┘
                              │
                    MetalLB + Ingress + DNS
                              │
        grafana.home.arpa
        git.home.arpa
        elm.home.arpa
        ollama.home.arpa
        registry.home.arpa
```

---

# Design Principles

## 1. Infrastructure as Code

### Decision

All infrastructure changes are performed through automation.

### Rationale

Manual configuration eventually leads to configuration drift.

Infrastructure should be reproducible from source control.

### Implementation

Ansible

---

## 2. Git as the Single Source of Truth

### Decision

The Git repository is the authoritative description of the platform.

### Rationale

If a Raspberry Pi fails, rebuilding should consist of:

1. Install Raspberry Pi OS
2. Clone repository
3. Execute playbooks

No undocumented manual configuration should exist.

---

## 3. Idempotent Automation

### Decision

All playbooks must be safe to execute repeatedly.

### Rationale

Infrastructure maintenance should not depend on remembering previous execution history.

Running a playbook multiple times should produce the same final state.

Example:

Correct:

- install package if missing
- enable service if disabled

Incorrect:

- append configuration repeatedly
- duplicate users
- duplicate firewall rules

---

## 4. Separation of Responsibilities

Responsibilities are deliberately separated.

### Inventory

Describes:

WHERE automation runs.

Example:

```
pi4mB01
pi4mB02
rk101
```

---

### Playbooks

Describe:

WHAT should happen.

Example:

```
baseline.yml
update.yml
k3s.yml
```

---

### Roles

Describe:

HOW functionality is implemented.

Example:

```
roles/

common/
security/
k3s/
monitoring/
ai/
```

---

## 5. Documentation First

Every playbook should answer:

- What problem does this solve?
- Why is this necessary?
- What alternatives exist?
- Why was this implementation chosen?

The repository should remain understandable years later.

---

# Hardware Architecture

## Current

```
Management Laptop
        │
        │
 Gigabit Network
        │
─────────────────────────────
│
├── pi4mB01
├── pi4mB02
├── pi4mB03
└── pi4mB04
```

---

## Planned

```
                 Management Laptop
                        │
                        │
                Home Network
                        │
──────────────────────────────────────────────

 Raspberry Pi Cluster

 pi4mB01
 pi4mB02
 pi4mB03
 pi4mB04

──────────────────────────────────────────────

 Turing Pi

 cm401
 cm402
 rk101
 rk102
```

---

# Operating System

## Decision

Raspberry Pi OS Lite (64-bit)

### Alternatives

Arch Linux ARM

Ubuntu Server

### Rationale

Although Arch Linux provides newer software, Raspberry Pi OS was selected because:

- official Raspberry Pi support
- excellent hardware compatibility
- lower maintenance
- stable long-term operation

The management workstation remains Arch Linux to provide a modern administration environment while keeping the cluster itself stable.

---

# Configuration Management

## Decision

Ansible

### Alternatives

Shell scripts

Puppet

Chef

SaltStack

### Rationale

Ansible requires no agent.

Communication occurs entirely over SSH.

It is easy to understand, highly portable and well suited for small and medium environments.

---

# Kubernetes

## Decision

K3s

### Alternatives

kubeadm

MicroK8s

RKE2

### Rationale

K3s provides:

- low memory footprint
- ARM support
- production-quality Kubernetes
- simple installation
- excellent Raspberry Pi compatibility

---

# Storage

## Planned Decision

Longhorn

### Alternatives

NFS

Ceph

OpenEBS

### Rationale

Longhorn provides distributed persistent storage using local disks without requiring dedicated storage hardware.

Decision will be revisited after Kubernetes deployment.

---

# GitOps

## Planned Decision

FluxCD

### Alternatives

ArgoCD

### Initial Rationale

Flux integrates naturally with Git.

It has a lightweight architecture suitable for ARM clusters.

Decision will be revisited later.

---

# Monitoring

Planned stack:

- Prometheus
- Grafana
- Loki
- Alertmanager

Purpose:

Provide observability equivalent to production Kubernetes environments.

---

# AI Platform

Planned components:

- Ollama
- Open WebUI
- AnythingLLM

Primary AI workloads will execute on the future RK1 nodes.

---

# Security Principles

- SSH public-key authentication
- Infrastructure managed through Git
- Principle of least privilege
- Automatic security updates
- No manual configuration drift

---

# Growth Strategy

The platform is expected to evolve incrementally.

Phase 1

Linux

↓

Phase 2

Automation

↓

Phase 3

Kubernetes

↓

Phase 4

Storage

↓

Phase 5

Monitoring

↓

Phase 6

GitOps

↓

Phase 7

AI

↓

Phase 8

Edge Computing

---

# Guiding Philosophy

The objective is not merely to build a Raspberry Pi cluster.

The objective is to build the knowledge and operational discipline required to design, automate and operate modern cloud-native infrastructure using inexpensive hardware.

Every decision should prioritize:

- simplicity
- reproducibility
- maintainability
- observability
- scalability
- automation
