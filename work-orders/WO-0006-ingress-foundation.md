# WORK ORDER

**ID:** WO-0006
**Title:** Ingress Foundation (Traefik)
**Status:** Complete
**Primary Agent:** Codex
**Architect:** ChatGPT
**Owner:** Abdul Jabbar
**Target Release:** v0.6.0

---

# Objective

Establish the standard ingress architecture for the HomeLab by deploying
Traefik as the Kubernetes Ingress Controller.

This work order introduces a single HTTP/HTTPS entry point for all future
web applications while retaining Pi-hole as the dedicated DNS service.

This work order deliberately creates the platform foundation only.

No production applications are deployed.

---

# Business Motivation

Today every application would require its own MetalLB IP.

Example:

192.168.68.200 → Pi-hole

192.168.68.201 → Grafana

192.168.68.202 → Harbor

192.168.68.203 → IBM Jazz

...

This does not scale.

Instead we establish a single ingress endpoint.

Example:

192.168.68.201

↓

Traefik

↓

Host based routing

↓

Grafana

Harbor

IBM Jazz

ArgoCD

etc.

Future applications require only:

- a Kubernetes Service
- an Ingress resource
- a DNS record

No additional external IPs.

---

# Architecture

Current Architecture

Internet

↓

Pi-hole

↓

MetalLB

↓

Individual LoadBalancer Services

Target Architecture

Internet

↓

Pi-hole
192.168.68.200

↓

DNS

↓

192.168.68.201

↓

MetalLB

↓

Traefik

↓

Ingress Rules

↓

Application Services

↓

Pods

Responsibilities

Pi-hole

- Local DNS
- home.arpa zone
- upstream DNS forwarding
- optional DNS filtering

MetalLB

- External IP allocation
- Layer 2 advertisement

Traefik

- HTTP routing
- HTTPS routing
- Ingress implementation
- TLS termination (future)

Kubernetes

- Service discovery
- Pod scheduling
- Internal load balancing

---

# Design Decisions

Continue using:

- MetalLB

Continue disabling:

- K3s ServiceLB

Continue disabling:

- Bundled K3s Traefik

Deploy:

Official Traefik Helm Chart

Traefik shall be managed by the repository rather than by K3s packaged
components.

---

# Scope

Included

- Traefik deployment
- dedicated namespace
- Helm deployment
- version pinning
- two replicas
- pod anti-affinity
- MetalLB integration
- LoadBalancer Service
- test application
- test Ingress
- Pi-hole DNS entry
- validation
- documentation
- ADR

Excluded

- Grafana
- Harbor
- IBM Jazz
- GitLab
- TLS
- Let's Encrypt
- Gateway API
- Authentication
- Middleware
- Internet exposure
- Port forwarding

---

# Repository Changes

Create

kubernetes/
└── platform/
    └── ingress/
        ├── namespace.yaml
        ├── values.yaml
        ├── README.md
        └── test-app/
            ├── deployment.yaml
            ├── service.yaml
            └── ingress.yaml

Documentation

docs/

Add

infrastructure/ingress.md

operations/ingress.md

Create

ADR-0010-ingress-foundation.md

Update

PROJECT_STATE.md

---

# Traefik Configuration

Deploy

Official Helm Chart

Replicas

2

Scheduling

Prefer different Kubernetes nodes.

Service

Type

LoadBalancer

Requested IP

192.168.68.201

Ports

80

443

IngressClass

traefik

Do not expose dashboard publicly.

---

# Test Application

Deploy

traefik/whoami

Service

ClusterIP

Ingress

Host

test.home.arpa

Path

/

Expected

Opening

http://test.home.arpa

returns

whoami

page.

No application specific routing yet.

---

# Pi-hole Integration

Create local DNS record

test.home.arpa

↓

192.168.68.201

Do not create wildcard DNS entries yet.

---

# Validation

Deployment

kubectl get pods -n ingress

Expected

2 Traefik pods Running

Service

kubectl get svc -n ingress

Expected

External IP

192.168.68.201

Ingress

kubectl get ingress -A

Expected

test.home.arpa

Traefik

DNS

dig test.home.arpa

Expected

192.168.68.201

HTTP

curl http://test.home.arpa

Expected

whoami

page

Browser

Open

http://test.home.arpa

Expected

Successful response

No IP address required.

---

# Documentation

Document

Ingress architecture

Traffic flow

Relationship between

Pi-hole

MetalLB

Traefik

Ingress

Service

Pod

Explain

Host header routing

Create diagrams.

---

# Operational Readiness

The ingress platform shall support future deployment of

- Grafana
- Harbor
- ArgoCD
- IBM Jazz
- GitLab
- Prometheus
- Alertmanager

without architectural modification.

---

# Pull Request

Branch

wo-0006-ingress-foundation

PR

WO-0006: Ingress Foundation (Traefik)

Release

v0.6.0

---

# Acceptance Criteria

- Official Traefik deployed
- K3s packaged Traefik remains disabled
- ServiceLB remains disabled
- Two Traefik replicas running
- Pods scheduled on different nodes
- LoadBalancer IP 192.168.68.201 assigned
- test.home.arpa resolves correctly
- whoami application reachable
- Documentation updated
- ADR-0010 created
- PROJECT_STATE updated
- mkdocs build --strict succeeds
- PR created
- Architecture review completed
- Review findings resolved
- PR merged
- Release v0.6.0 created

---

# Successor Work Order

WO-0007

TLS Foundation

- Private Certificate Authority
- Certificate distribution
- Traefik HTTPS
- Automatic certificate management
- Secure access to all HomeLab applications
