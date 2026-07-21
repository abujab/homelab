# Naming and Addressing

---

## Purpose

This page is the authoritative reference for HomeLab machine naming, LAN
addresses, MetalLB allocation and internal DNS names.

## Scope

It documents the convention and allocations that already exist. It does not
create a new naming scheme, allocate future service addresses or change router
configuration.

## Background

Machine names identify hardware. Service names identify functionality.
HomeLab uses stable DHCP reservations for nodes, MetalLB addresses for direct
LAN services and shared Traefik ingress for browser-facing applications.

## Architecture / Implementation

### Host naming

The current canonical machine identifiers are:

```text
pi4mB01
pi4mB02
pi4mB03
pi4mB04
```

| Segment | Meaning | Example |
|---------|---------|---------|
| `pi` | Raspberry Pi device family | `pi` |
| `4mB` | Raspberry Pi 4 Model B identifier | `4mB` |
| `01` through `04` | Two-digit hardware sequence | `01` |

Ansible inventory and HomeLab documentation preserve the mixed-case display
form. Linux and Kubernetes interfaces may normalize DNS-style hostnames to
lowercase, such as `pi4mb01`; the K3s role explicitly lowercases node names when
applying worker labels. Case variation does not create a second machine
identity. Use the inventory spelling in repository configuration and compare
runtime hostnames case-insensitively.

### Network ranges

| Allocation | Address or Range | Purpose | Authority |
|------------|------------------|---------|-----------|
| Home LAN | `192.168.68.0/22` | Management, node and service network | Verified node routes |
| Default gateway | `192.168.68.1` | Router for node default routes | Ansible network role |
| Raspberry Pi nodes | `192.168.68.101-192.168.68.104` | Stable DHCP reservations | Ansible host variables |
| MetalLB pool | `192.168.68.200-192.168.68.220` | Kubernetes LoadBalancer allocation | `IPAddressPool/homelab-lan` |

### Assigned addresses

| Address | Name or Resource | Purpose | State |
|---------|------------------|---------|-------|
| `192.168.68.101` | `pi4mB01` | K3s control plane | Current |
| `192.168.68.102` | `pi4mB02` | K3s worker | Current |
| `192.168.68.103` | `pi4mB03` | K3s worker | Current |
| `192.168.68.104` | `pi4mB04` | K3s worker | Current |
| `192.168.68.200` | `Service/pihole` | Pi-hole DNS on TCP and UDP port 53 | Current |
| `192.168.68.201` | Traefik LoadBalancer Service | Shared HTTP and HTTPS ingress | Current |
| `192.168.68.202-192.168.68.220` | No current assignment in repository manifests | Available MetalLB pool space; not individually reserved | Unassigned |

### Internal DNS

The internal namespace is `home.arpa`.

| DNS Name | Destination | Classification | Purpose |
|----------|-------------|----------------|---------|
| `pihole.home.arpa` | `192.168.68.201` | Active | Pi-hole Web UI through Traefik and HTTPS |
| `test.home.arpa` | `192.168.68.201` | Active, validation-only | Traefik, DNS and certificate validation route |
| `elm.home.arpa` | No current record or workload | Reserved | Possible future IBM ELM publication |

The Pi-hole resolver itself is reached at `192.168.68.200`; it does not need a
separate browser-facing address. `pihole.home.arpa` resolves to the shared
ingress address because the Web UI follows the application exposure standard.

### Allocation rules

| Resource Type | Current Rule |
|---------------|--------------|
| Physical nodes | Use router-managed DHCP reservations reflected in Ansible `host_vars` |
| LoadBalancer addresses | Allocate only from `192.168.68.200-192.168.68.220` and declare the request in Git |
| DNS-only or non-HTTP services | A dedicated LoadBalancer IP is allowed when direct LAN protocol access is required |
| Browser-facing applications | Use a `home.arpa` hostname, Traefik at `192.168.68.201`, a Kubernetes `Ingress` and an internal `ClusterIP` Service |
| New DNS names | Record the name, state and owner in this page and the Service Catalog when implemented |
| Future IP allocation | Confirm DHCP exclusion and address availability before committing a manifest; do not infer availability from a gap alone |

### Authoritative sources

- host addresses: `ansible/inventories/home/host_vars/`
- gateway and interfaces: `ansible/roles/network/defaults/main.yml`
- MetalLB pool: `kubernetes/platform/networking/metallb/ipaddresspool.yaml`
- service IP requests: Kubernetes Service and Helm values under `kubernetes/`
- DNS records: `kubernetes/platform/networking/pihole/deployment.yaml`

## Design Decisions

`home.arpa` is used instead of `.local`, which is reserved for multicast DNS.
Machine names never serve as public application identities.

Ordinary Web applications share ingress. Dedicated LoadBalancer addresses are
reserved for protocols that cannot use HTTP ingress or for approved exceptions.

## Best Practices

- keep router DHCP reservations aligned with Ansible host variables
- keep the MetalLB pool outside dynamic DHCP assignment
- preserve canonical mixed-case machine display names in repository content
- use lowercase DNS service names under `home.arpa`
- never present a reserved name as an active service
- update the [Service Catalog](service-catalog.md) with every service allocation

## Future Improvements

- document router export and restore procedures
- add allocation validation to CI
- allocate new service names only through approved implementation work orders

## Related Documents

- [Infrastructure Inventory](infrastructure-inventory.md)
- [Service Catalog](service-catalog.md)
- [Networking](../infrastructure/networking.md)
- [Ingress](../infrastructure/ingress.md)
- [ADR-0008 Networking Foundation](../decisions/ADR-0008-networking-foundation.md)
- [ADR-0012 Shared Ingress](../decisions/ADR-0012-application-exposure-through-shared-ingress.md)
