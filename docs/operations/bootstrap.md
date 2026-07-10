# Bootstrap

---

## Purpose

This document describes the complete bootstrap procedure for rebuilding the current HomeLab Raspberry Pi Kubernetes platform from the repository.

It is the authoritative operational guide for creating the platform from a clean workstation and freshly imaged Raspberry Pi nodes.

## Scope

This document covers:

- management workstation preparation
- Arch Linux package installation
- Python virtual environment setup
- repository cloning
- SSH key creation and ssh-agent usage
- Raspberry Pi imaging
- hostname configuration
- DHCP reservations
- SSH verification
- Ansible inventory verification
- baseline playbook execution
- K3s installation
- networking foundation installation
- cluster verification
- MkDocs setup

This document does not introduce new infrastructure. It documents the current implemented platform.

## Background

HomeLab is designed to be reproducible from Git, documented bootstrap procedures and required installation media.

The current platform consists of:

- one Arch Linux management workstation
- four Raspberry Pi 4 nodes
- Raspberry Pi OS / Debian 13 on ARM64
- Ansible for configuration management
- K3s for Kubernetes
- MkDocs Material for documentation

## Architecture / Implementation

### 1. Prepare the management workstation

Install the required Arch Linux packages:

```bash
sudo pacman -Syu
sudo pacman -S git python python-pip python-virtualenv ansible openssh kubectl
```

Confirm the tools are available:

```bash
git --version
python --version
ansible --version
ssh -V
kubectl version --client
```

### 2. Clone the repository

Clone the repository onto the management workstation:

```bash
git clone https://github.com/abujab/homelab.git
cd homelab
```

### 3. Create the Python virtual environment

Create and activate the project virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate
```

Install documentation tooling:

```bash
pip install -r requirements/docs.txt
```

If development and testing dependencies are needed, install them from the matching files under `requirements/`.

### 4. Create or load the SSH key

Create the operator SSH key if it does not already exist:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "homelab"
```

Start `ssh-agent` and load the key:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_personal
```

The Ansible inventory expects this private key:

```text
~/.ssh/id_ed25519_personal
```

### 5. Image the Raspberry Pi nodes

Flash Raspberry Pi OS Lite 64-bit to each microSD card.

For each node, configure:

- SSH enabled
- username `abdul`
- SSH public key access
- hostname matching the inventory

Current hostnames:

| Host | Role |
|------|------|
| pi4mB01 | K3s control plane |
| pi4mB02 | K3s worker |
| pi4mB03 | K3s worker |
| pi4mB04 | K3s worker |

### 6. Configure DHCP reservations

Create DHCP reservations on the home router for the Raspberry Pi nodes:

| Host | Reserved IP |
|------|-------------|
| pi4mB01 | 192.168.68.101 |
| pi4mB02 | 192.168.68.102 |
| pi4mB03 | 192.168.68.103 |
| pi4mB04 | 192.168.68.104 |

The reservations must match the Ansible host variables under:

```text
ansible/inventories/home/host_vars/
```

### 7. Verify SSH access

From the management workstation, verify each node:

```bash
ssh -i ~/.ssh/id_ed25519_personal abdul@192.168.68.101 hostname
ssh -i ~/.ssh/id_ed25519_personal abdul@192.168.68.102 hostname
ssh -i ~/.ssh/id_ed25519_personal abdul@192.168.68.103 hostname
ssh -i ~/.ssh/id_ed25519_personal abdul@192.168.68.104 hostname
```

Each command should return the matching hostname.

### 8. Verify Ansible inventory

Run Ansible commands from the `ansible/` directory so `ansible.cfg` is applied:

```bash
cd ansible
ansible-inventory --graph
ansible pis -m ping
```

The `pis` group should contain all four Raspberry Pi nodes.

### 9. Apply the baseline configuration

Run the baseline playbook:

```bash
ansible-playbook playbooks/baseline.yml
```

The baseline configures common packages, time synchronization, swap state and kernel cgroup settings required for Kubernetes.

### 10. Install K3s

Install the current K3s cluster:

```bash
ansible-playbook playbooks/k3s.yml
```

This configures:

- `pi4mB01` as the K3s server
- `pi4mB02`, `pi4mB03` and `pi4mB04` as K3s agents
- kubeconfig at `ansible/kubeconfig`
- worker node role labels
- cluster verification

### 11. Verify Kubernetes

From the repository root, verify the cluster:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
kubectl --kubeconfig ansible/kubeconfig get pods -n kube-system
kubectl --kubeconfig ansible/kubeconfig get storageclass
```

Expected result:

- four nodes are present
- all nodes are `Ready`
- CoreDNS is running
- Metrics Server is available
- Local Path Provisioner exists

### 12. Install the networking foundation

Apply MetalLB first:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -k kubernetes/platform/networking/metallb
kubectl --kubeconfig ansible/kubeconfig wait --namespace metallb-system --for=condition=Available deployment/controller --timeout=180s
kubectl --kubeconfig ansible/kubeconfig rollout status daemonset/speaker -n metallb-system --timeout=180s
kubectl --kubeconfig ansible/kubeconfig apply -k kubernetes/platform/networking/metallb
```

The second apply ensures the `IPAddressPool` and `L2Advertisement` are created after MetalLB CRDs are established.

Apply Pi-hole:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/networking/pihole/namespace.yaml
kubectl --kubeconfig ansible/kubeconfig create secret generic pihole-admin \
  --namespace networking \
  --from-literal=password='<strong-local-password>' \
  --dry-run=client -o yaml | kubectl --kubeconfig ansible/kubeconfig apply -f -
kubectl --kubeconfig ansible/kubeconfig apply -k kubernetes/platform/networking/pihole
kubectl --kubeconfig ansible/kubeconfig rollout status deployment/pihole -n networking --timeout=300s
```

If the Secret already exists, leave it in place rather than committing its value to Git.

Verify networking:

```bash
kubectl --kubeconfig ansible/kubeconfig get ipaddresspools -A
kubectl --kubeconfig ansible/kubeconfig get l2advertisements -A
kubectl --kubeconfig ansible/kubeconfig get svc pihole -n networking
dig @192.168.68.200 openai.com +short
dig @192.168.68.200 pihole.home.arpa +short
curl -I http://192.168.68.200/admin/
```

Expected result:

- MetalLB controller and speakers are running
- `homelab-lan` address pool exists
- Pi-hole has LoadBalancer IP `192.168.68.200`
- public DNS resolves through Pi-hole
- `pihole.home.arpa` resolves to `192.168.68.200`

### 13. Verify MkDocs

From the repository root:

```bash
source .venv/bin/activate
mkdocs build
mkdocs serve
```

Open:

```text
http://127.0.0.1:8000
```

## Design Decisions

### Git is the source of truth

The repository contains the desired state and documentation needed to rebuild the platform.

### The management workstation is outside the cluster

The workstation runs Ansible, kubectl and MkDocs tooling. It is not a Kubernetes node.

### DHCP reservations are used for node addresses

DHCP reservations keep addresses stable without requiring manual static network configuration on every node.

### Ansible performs repeatable configuration

The bootstrap flow uses Ansible playbooks rather than manual node configuration after initial imaging.

### Networking is applied through Kubernetes manifests

MetalLB and Pi-hole are deployed from declarative manifests under `kubernetes/platform/networking/`.

The Pi-hole administrative password Secret is created locally outside Git until a stronger secrets-management design is introduced.

## Best Practices

- keep DHCP reservations aligned with Ansible host variables
- verify SSH before running Ansible
- run Ansible from the `ansible/` directory
- run `baseline.yml` before `k3s.yml`
- apply MetalLB before Pi-hole
- verify the Kubernetes cluster before deploying services
- verify DNS through Pi-hole before depending on `.home.arpa` service names
- keep the documentation build passing after documentation changes
- commit completed infrastructure and documentation changes together when practical

## Future Improvements

Future bootstrap improvements may include:

- documented Raspberry Pi Imager screenshots or profile export
- automated workstation bootstrap script
- bootstrap validation checklist
- secret handling procedure
- image backup procedure for management workstation recovery

## Related Documents

- [Raspberry Pi Cluster](../infrastructure/raspberry-pi-cluster.md)
- [Ansible](../infrastructure/ansible.md)
- [Kubernetes](../infrastructure/kubernetes.md)
- [Networking](../infrastructure/networking.md)
- [Repository Structure](../overview/repository.md)
