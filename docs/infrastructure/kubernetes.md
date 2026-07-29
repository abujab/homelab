# Kubernetes

---

## Purpose

This document describes the current Kubernetes foundation of HomeLab.

The platform currently uses K3s to provide a lightweight Kubernetes cluster on Raspberry Pi hardware.

## Scope

This document covers:

- K3s selection
- current cluster topology
- control-plane and worker nodes
- kubeconfig handling
- cold-boot time ordering
- embedded SQLite datastore state
- CoreDNS
- Metrics Server
- Local Path Provisioner
- disabled Traefik and ServiceLB
- repository-managed Traefik ingress
- worker labels
- verification commands

This document does not describe application workloads. Application deployment belongs in future platform or application documentation.

## Background

HomeLab uses Kubernetes as the foundation for future internal services.

K3s was selected because it provides a production-grade Kubernetes distribution with a smaller footprint suitable for Raspberry Pi hardware.

The current cluster was installed through Ansible.

## Architecture / Implementation

Current cluster topology:

```text
K3s cluster
|
+-- pi4mB01 / 192.168.68.101
|   +-- control plane
|
+-- pi4mB02 / 192.168.68.102
|   +-- worker
|
+-- pi4mB03 / 192.168.68.103
|   +-- worker
|
+-- pi4mB04 / 192.168.68.104
    +-- worker
```

### Control plane

`pi4mB01` runs the K3s server.

The control-plane node hosts the Kubernetes API server and coordinates the worker nodes.

### Worker nodes

`pi4mB02`, `pi4mB03` and `pi4mB04` run the K3s agent service and join the cluster through the control-plane API.

The Ansible `k3s` role applies the worker role label:

```text
node-role.kubernetes.io/worker=worker
```

This label improves cluster readability. It does not change scheduling behavior by itself.

### Kubeconfig handling

The K3s role fetches `/etc/rancher/k3s/k3s.yaml` from the control-plane node and stores it as:

```text
ansible/kubeconfig
```

The role then replaces the default `127.0.0.1` API endpoint with the control-plane node IP so kubectl can be used from the management workstation.

This generated file contains cluster-administrator credentials. It is excluded
from Git and restricted to the workstation user with mode `0600`. Rerun the K3s
playbook to replace an expired or missing local copy.

### Cold-boot time ordering

Every Kubernetes node uses host-level Chrony as its authoritative time client.
The K3s server and agent units require and start after the packaged
`chrony-wait.service`, which completes only when `chronyc waitsync` confirms a
trusted clock. The initial probe is bounded by the packaged 180-second systemd
timeout, so K3s fails closed instead of evaluating certificates against an
untrusted clock. The Ansible-owned K3s drop-in also sets
`TimeoutStartSec=180s`, bounding the actual systemd start job even though the
installer-owned unit retains `Restart=always` with `RestartSec=5s`.

An enabled `homelab-k3s-time-recovery.timer` provides late recovery. It invokes
a short probe every 60 seconds while time is unavailable. Once synchronization
is proven, the companion oneshot service requests a non-blocking K3s start and
polls the actual unit state. Success requires `ActiveState=active`. A timeout,
failed state or restart activity explicitly stops K3s and verifies that no
start job, transitional state or automatic restart remains. The recovery
oneshot then remains active, leaving the timer with no next trigger. Its own
start timeout is 225 seconds. A K3s failure after synchronized time therefore
remains visible for operator investigation instead of entering an
infrastructure restart loop.

Fresh server and agent installations use `INSTALL_K3S_SKIP_START=true`. The
role installs the unit, asserts that it is not active, installs and reloads the
Chrony dependency, and only then starts K3s through the gated unit. Existing
nodes follow the same gated start path after relevant unit changes.

Use the local read-only health command as root:

```bash
sudo /usr/local/sbin/homelab-k3s-boot-health
```

The command and its internal recovery helper are installed as root-owned mode
`0700`. The server CA fingerprint is reported only when OpenSSL succeeds and
the result is a 64-character lowercase hexadecimal SHA-256 value.

Workers report only local Chrony and agent state. The server additionally uses
its existing root-only credentials for `/readyz`, node readiness and a public
cluster-CA hash. No administrator kubeconfig is distributed to workers.

### Datastore

The single K3s server uses the default embedded SQLite datastore at
`/var/lib/rancher/k3s/server/db/`. Embedded etcd is not configured, so K3s etcd
snapshots do not apply. The current backup gap and the required secure pairing
of SQLite state with the server token are documented in
[Backup](../operations/backup.md).

### Installed system components

K3s currently provides:

- Kubernetes API server
- CoreDNS
- Metrics Server
- Local Path Provisioner
- containerd runtime

CoreDNS provides in-cluster Kubernetes DNS.

Metrics Server provides resource metrics for Kubernetes APIs and tools such as `kubectl top`.

Local Path Provisioner provides simple node-local persistent volume support. It is suitable for the current foundation but is not the long-term storage design for important stateful services.

### Disabled bundled components

The K3s server is installed with:

```text
--disable servicelb
--disable traefik
```

ServiceLB remains disabled. MetalLB now provides explicit LAN LoadBalancer
addresses from the repository-managed pool.

Traefik is disabled so ingress can be selected and documented deliberately outside the K3s packaged component.

Repository-managed Traefik is now deployed separately through the official Helm chart in the `ingress` namespace.

## Design Decisions

### K3s for Raspberry Pi Kubernetes

K3s was selected because it is lightweight, ARM-friendly and operationally simpler than a full kubeadm deployment for this stage of the platform.

### One control-plane node for the current foundation

The current cluster uses a single control-plane node. This is simpler for the initial platform and sufficient for the current documentation and infrastructure foundation.

### Repository-managed ingress and load balancing

K3s ServiceLB and packaged Traefik remain disabled. MetalLB provides LAN LoadBalancer IPs, and repository-managed Traefik provides Kubernetes ingress.

### Use labels for readable node roles

Worker labels make the node list easier to read and prepare the platform for future placement conventions.

## Best Practices

- manage Kubernetes installation through Ansible
- keep the generated kubeconfig local, permission-restricted and outside Git
- verify node readiness after K3s changes
- verify trustworthy time and the K3s time gate after node boots
- verify system components before deploying applications
- avoid imperative workload changes where declarative manifests are practical
- use labels to express workload placement intent
- manage ingress, load balancing and DNS as documented platform capabilities

## Future Improvements

Planned Kubernetes improvements include:

- persistent storage evaluation
- GitOps-based workload delivery
- high-availability control-plane evaluation
- x86 and additional ARM worker expansion

TLS certificate management is current through cert-manager and the HomeLab
private PKI; it is not a future Kubernetes capability.

Useful verification commands:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
kubectl --kubeconfig ansible/kubeconfig get pods -n kube-system
kubectl --kubeconfig ansible/kubeconfig get storageclass
kubectl --kubeconfig ansible/kubeconfig top nodes
```

## Related Documents

- [Raspberry Pi Cluster](raspberry-pi-cluster.md)
- [Ansible](ansible.md)
- [Networking](networking.md)
- [Ingress](ingress.md)
- [Storage](storage.md)
- [Security](security.md)
- [Architecture](../overview/architecture.md)
- [Service Catalog](../reference/service-catalog.md)
- [Software Inventory](../reference/software-inventory.md)
- [Troubleshooting](../operations/troubleshooting.md)
- [Backup](../operations/backup.md)
- [Decision Register](../reference/decision-register.md)
