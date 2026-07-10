# Networking

---

## Purpose

This document describes the current HomeLab networking foundation and the planned direction for internal service discovery.

Networking is intentionally documented before additional platform services are introduced because future services need stable names and predictable exposure.

## Scope

This document covers:

- current LAN range
- DHCP reservations
- current host IPs
- MetalLB LoadBalancer address pool
- Pi-hole internal DNS
- `.home.arpa` DNS naming
- future ingress plan
- IBM ELM future DNS target

This document does not define a final production network architecture. VLANs, segmentation, TLS automation and external access are future topics.

## Background

The current platform runs on the home LAN:

```text
192.168.68.0/24
```

The Raspberry Pi nodes are reached by reserved LAN addresses. Ansible and kubectl run from the management workstation over this network.

HomeLab now exposes platform services on the LAN through MetalLB and uses Pi-hole as the first internal DNS service.

## Architecture / Implementation

Current network topology:

```text
Arch Linux management laptop
        |
        v
Home LAN 192.168.68.0/24
        |
        +-- pi4mB01 / 192.168.68.101
        +-- pi4mB02 / 192.168.68.102
        +-- pi4mB03 / 192.168.68.103
        +-- pi4mB04 / 192.168.68.104
        |
        +-- MetalLB service pool / 192.168.68.200-192.168.68.220
            +-- pihole.home.arpa / 192.168.68.200
```

Current DHCP reservations:

| Host | Reserved IP |
|------|-------------|
| pi4mB01 | 192.168.68.101 |
| pi4mB02 | 192.168.68.102 |
| pi4mB03 | 192.168.68.103 |
| pi4mB04 | 192.168.68.104 |

The reserved addresses are reflected in Ansible host variables under:

```text
ansible/inventories/home/host_vars/
```

### MetalLB

MetalLB provides Kubernetes `LoadBalancer` service support for the home LAN.

Current configuration:

| Setting | Value |
|---------|-------|
| Mode | Layer 2 |
| Namespace | `metallb-system` |
| Address pool | `192.168.68.200-192.168.68.220` |
| Pool name | `homelab-lan` |

The implementation lives in:

```text
kubernetes/platform/networking/metallb/
```

The address pool must remain outside normal DHCP assignment.

### Pi-hole

Pi-hole provides internal DNS and forwards public DNS queries upstream.

Current configuration:

| Setting | Value |
|---------|-------|
| Namespace | `networking` |
| Service type | `LoadBalancer` |
| Service IP | `192.168.68.200` |
| DNS name | `pihole.home.arpa` |
| Upstream DNS | `1.1.1.1`, `1.0.0.1`, `9.9.9.9` |
| Persistent volume | `pihole-config` |
| Image | `pihole/pihole@sha256:f7d1be836e3bc608b56d82fc9904f5a831cdfbc0dc9c6d58f94e4c985c70038b` |

The implementation lives in:

```text
kubernetes/platform/networking/pihole/
```

The Pi-hole administrative password is stored in a Kubernetes Secret named `pihole-admin`.

The real Secret is created locally and is not committed to Git:

```bash
kubectl --kubeconfig ansible/kubeconfig create secret generic pihole-admin \
  --namespace networking \
  --from-literal=password='<strong-local-password>'
```

The repository contains `secret.example.yaml` only as an example. The ignored local filename is:

```text
kubernetes/platform/networking/pihole/secret.yaml
```

This should move to a stronger secrets-management model before broader service deployment.

### Service names

Current service names:

| Name | IP Address | Purpose |
|------|------------|---------|
| pihole.home.arpa | 192.168.68.200 | Pi-hole DNS and web UI |

Reserved future names:

| Name | Purpose |
|------|---------|
| grafana.home.arpa | Future monitoring UI |
| registry.home.arpa | Future container registry |
| elm.home.arpa | Future IBM ELM endpoint |

## Design Decisions

### DHCP reservations for current nodes

DHCP reservations keep node addressing stable while avoiding manual static IP configuration on each Raspberry Pi.

### `.home.arpa` for internal DNS

The internal DNS namespace is `.home.arpa`.

This avoids using `.local`, which is reserved for multicast DNS and can create confusing resolver behavior.

### Service names over machine names

Machine names identify hardware. Service names should identify functionality.

Examples of service names:

```text
grafana.home.arpa
registry.home.arpa
elm.home.arpa
```

### MetalLB for LAN load balancing

MetalLB is used instead of K3s ServiceLB so LAN service exposure is explicit, declarative and tied to a documented IP pool.

### Defer ingress

Ingress is still planned but not currently installed. DNS and LoadBalancer support were introduced first so future ingress work can publish stable names.

## Best Practices

- keep DHCP reservations aligned with Ansible host variables
- use DNS names for services instead of node hostnames
- avoid hardcoded IP addresses in application configuration
- reserve machine names for hardware identity
- introduce load balancer IP pools intentionally
- document every service name as it is introduced
- verify name resolution before publishing dependent services
- keep service IPs in the MetalLB pool out of DHCP assignment
- create the Pi-hole administrative password Secret outside Git
- move administrative passwords to a stronger secrets-management model before exposing more services

## Future Improvements

Planned networking work includes:

- ingress controller deployment
- first stable internal service URLs
- IBM ELM publication through `elm.home.arpa`
- TLS certificate management
- additional `.home.arpa` service records
- future network segmentation or VLAN design

Verification commands:

```bash
kubectl --kubeconfig ansible/kubeconfig get pods -A
kubectl --kubeconfig ansible/kubeconfig get svc -A
kubectl --kubeconfig ansible/kubeconfig get ipaddresspools -A
kubectl --kubeconfig ansible/kubeconfig get l2advertisements -A
dig @192.168.68.200 openai.com +short
dig @192.168.68.200 pihole.home.arpa +short
curl -I http://192.168.68.200/admin/
```

## Related Documents

- [Raspberry Pi Cluster](raspberry-pi-cluster.md)
- [Kubernetes](kubernetes.md)
- [Security](security.md)
- [Architecture](../overview/architecture.md)
- [Roadmap](../overview/roadmap.md)
- [ADR-0008 Networking Foundation](../decisions/ADR-0008-networking-foundation.md)
