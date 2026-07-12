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
- wired Ethernet baseline
- Wi-Fi disablement
- MetalLB LoadBalancer address pool
- Pi-hole internal DNS
- Traefik ingress endpoint
- `.home.arpa` DNS naming
- IBM ELM future DNS target

This document does not define a final production network architecture. VLANs, segmentation, TLS automation and external access are future topics.

## Background

The current platform runs on the home LAN. Nodes currently report the LAN subnet as:

```text
192.168.68.0/22
```

The Raspberry Pi nodes are reached by reserved LAN addresses. Ansible and kubectl run from the management workstation over this network.

HomeLab now exposes platform services on the LAN through MetalLB and uses Pi-hole as the first internal DNS service.

All dedicated Raspberry Pi Kubernetes nodes use wired Ethernet through a TP-Link TL-SG108E switch. Wi-Fi is disabled through Ansible for normal operation.

Traefik provides the shared HTTP and HTTPS ingress endpoint for future web applications.

## Architecture / Implementation

Current network topology:

```text
Arch Linux management laptop
        |
        v
Home LAN 192.168.68.0/22
        |
        +-- TP-Link TL-SG108E Ethernet switch
            |
            +-- pi4mB01 / eth0 / 192.168.68.101
            +-- pi4mB02 / eth0 / 192.168.68.102
            +-- pi4mB03 / eth0 / 192.168.68.103
            +-- pi4mB04 / eth0 / 192.168.68.104
        |
        +-- MetalLB service pool / 192.168.68.200-192.168.68.220
            +-- pihole.home.arpa / 192.168.68.200
            +-- test.home.arpa / 192.168.68.201 / Traefik ingress
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

### Wired node transport

Current node transport:

| Setting | Value |
|---------|-------|
| Switch | TP-Link TL-SG108E |
| Node interface | `eth0` |
| Default gateway | `192.168.68.1` |
| Wi-Fi interface | `wlan0` |
| Wi-Fi radio state | Disabled through NetworkManager |

The wired baseline is enforced by the Ansible `network` role.

The role verifies that:

- `eth0` exists
- `eth0` is operationally up
- `eth0` carries the node inventory address
- the default route uses `eth0`
- the default gateway is `192.168.68.1`
- `wlan0` carries no IPv4 address
- NetworkManager reports Wi-Fi as disabled

Wi-Fi can be temporarily re-enabled only for emergency recovery:

```bash
sudo nmcli radio wifi on
```

The next baseline run restores the declared Wi-Fi-disabled state.

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

### Traefik ingress

Traefik provides the shared Kubernetes ingress endpoint.

Current configuration:

| Setting | Value |
|---------|-------|
| Namespace | `ingress` |
| Service type | `LoadBalancer` |
| Service IP | `192.168.68.201` |
| IngressClass | `traefik` |
| HTTP port | `80` |
| HTTPS port | `443` |
| Dashboard exposure | Not exposed |

The implementation lives in:

```text
kubernetes/platform/ingress/
```

The initial validation route is:

```text
test.home.arpa -> 192.168.68.201
```

Pi-hole resolves application hostnames to the Traefik IP. Traefik then uses
Ingress rules and HTTP host headers to route requests to internal Kubernetes
Services.

### Service names

Current service names:

| Name | IP Address | Purpose |
|------|------------|---------|
| pihole.home.arpa | 192.168.68.200 | Pi-hole DNS and web UI |
| test.home.arpa | 192.168.68.201 | Traefik ingress validation route |

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

MetalLB Layer 2 service exposure depends on reliable Ethernet and ARP behavior. Raspberry Pi Wi-Fi is not used as the cluster transport for MetalLB or platform-service traffic.

### Wi-Fi disabled on cluster nodes

Wi-Fi is disabled through NetworkManager rather than by removing packages, deleting profiles or blacklisting kernel modules. This keeps emergency recovery possible while preserving the managed production baseline.

### Shared ingress endpoint

Traefik is the standard shared ingress endpoint for HomeLab web applications.
Future applications should normally use a `ClusterIP` Service and an `Ingress`
resource instead of receiving their own external LoadBalancer IP.

## Best Practices

- keep DHCP reservations aligned with Ansible host variables
- keep dedicated cluster nodes on wired Ethernet
- keep Wi-Fi disabled during normal operation
- use DNS names for services instead of node hostnames
- avoid hardcoded IP addresses in application configuration
- reserve machine names for hardware identity
- introduce load balancer IP pools intentionally
- document every service name as it is introduced
- verify name resolution before publishing dependent services
- publish web applications through Traefik ingress when direct LAN exposure is not required
- keep service IPs in the MetalLB pool out of DHCP assignment
- create the Pi-hole administrative password Secret outside Git
- move administrative passwords to a stronger secrets-management model before exposing more services

## Future Improvements

Planned networking work includes:

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
ansible pis -m shell -a "ip route show default"
ansible pis -m command -a "nmcli radio wifi"
dig @192.168.68.200 openai.com +short
dig @192.168.68.200 pihole.home.arpa +short
dig @192.168.68.200 test.home.arpa +short
curl -I http://192.168.68.200/admin/
curl http://test.home.arpa
```

## Related Documents

- [Raspberry Pi Cluster](raspberry-pi-cluster.md)
- [Kubernetes](kubernetes.md)
- [Ingress](ingress.md)
- [Security](security.md)
- [Architecture](../overview/architecture.md)
- [Roadmap](../overview/roadmap.md)
- [ADR-0008 Networking Foundation](../decisions/ADR-0008-networking-foundation.md)
- [ADR-0009 Wired Network for Cluster Nodes](../decisions/ADR-0009-wired-network-for-cluster-nodes.md)
- [ADR-0010 Ingress Foundation](../decisions/ADR-0010-ingress-foundation.md)
