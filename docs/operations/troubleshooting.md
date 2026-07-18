# Troubleshooting

---

## Purpose

This document consolidates known troubleshooting patterns for the current HomeLab Raspberry Pi, Ansible, K3s and MkDocs platform.

Each issue includes the problem, cause, resolution and verification.

## Scope

This document covers:

- SSH issues
- Ansible issues
- Raspberry Pi baseline issues
- Kubernetes issues
- networking issues
- certificate and HTTPS issues
- documentation tooling issues

This document does not replace future service-specific troubleshooting guides.

## Background

Most current operational issues fall into a small number of categories:

- authentication and SSH key selection
- Ansible inventory or role lookup
- Raspberry Pi kernel and swap settings
- K3s kubeconfig and node naming
- MetalLB and Pi-hole service exposure
- wired Ethernet and Wi-Fi baseline
- cert-manager certificate issuance
- Traefik HTTPS routing
- local Python and MkDocs environment setup

## Architecture / Implementation

## SSH

### Wrong username

Problem:

SSH or Ansible cannot connect to a Raspberry Pi.

Cause:

The current inventory expects the SSH user `abdul`. A different username was used during imaging or in a manual SSH command.

Resolution:

Use the expected username:

```bash
ssh abdul@192.168.68.101
```

If the node was imaged with the wrong username, recreate the user or reimage the node with the correct account.

Verification:

```bash
ssh abdul@192.168.68.101 hostname
```

### SSH key not used

Problem:

SSH prompts for a password or rejects authentication.

Cause:

The expected private key was not selected.

Resolution:

Use the configured key:

```bash
ssh -i ~/.ssh/id_ed25519_personal abdul@192.168.68.101
```

Confirm Ansible references the same key in `ansible/inventories/home/group_vars/all.yml`.

Verification:

```bash
cd ansible
ansible pis -m ping
```

### ssh-agent does not have the key

Problem:

Ansible repeatedly prompts for the SSH key passphrase or fails to authenticate.

Cause:

The key is encrypted but not loaded into `ssh-agent`.

Resolution:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_personal
```

Verification:

```bash
ssh-add -l
cd ansible
ansible pis -m ping
```

### IdentityFile mismatch

Problem:

Manual SSH works with one key, but Ansible uses another key.

Cause:

The key in `group_vars/all.yml` does not match the key used manually or in SSH config.

Resolution:

Align the key path with the intended operator key:

```yaml
ansible_ssh_private_key_file: ~/.ssh/id_ed25519_personal
```

Verification:

```bash
cd ansible
ansible pi4mB01 -m ping
```

### known_hosts conflict

Problem:

SSH reports that the remote host identification has changed.

Cause:

A Raspberry Pi was reimaged or replaced and now has a different SSH host key at the same IP address.

Resolution:

Remove the stale host key after confirming the node replacement is expected:

```bash
ssh-keygen -R 192.168.68.101
```

Reconnect and accept the new host key.

Verification:

```bash
ssh abdul@192.168.68.101 hostname
```

## Ansible

### Inventory not found

Problem:

Ansible cannot find the `pis` group or uses localhost only.

Cause:

Ansible was run outside the `ansible/` directory, so `ansible.cfg` was not applied.

Resolution:

```bash
cd ansible
ansible-inventory --graph
```

Verification:

The output should include `pis`, `k3s_server` and `k3s_agents`.

### Role lookup failure

Problem:

`ansible-playbook` cannot find the `common` or `k3s` role.

Cause:

The configured `roles_path` from `ansible/ansible.cfg` was not loaded, or the command was run from an unexpected location.

Resolution:

Run from the `ansible/` directory:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml
```

Verification:

The playbook starts role tasks from `roles/common`.

### Idempotency concern

Problem:

A playbook reports changes on every run.

Cause:

Some tasks legitimately check state, but repeated changes may also indicate non-idempotent task behavior.

Resolution:

Review the changed task. Prefer Ansible modules and state declarations. Use guards such as `creates` only where a shell command is required.

Verification:

Run the same playbook twice and compare the recap:

```bash
ansible-playbook playbooks/baseline.yml
ansible-playbook playbooks/baseline.yml
```

### Package task changes every run

Problem:

Package-related tasks appear noisy during repeated baseline runs.

Cause:

Package cache refresh or package updates can report changes depending on cache age and available upgrades.

Resolution:

The baseline package cache task uses a cache validity window. Routine upgrades should be handled through `playbooks/update.yml`.

Verification:

```bash
ansible-playbook playbooks/update.yml
ansible-playbook playbooks/baseline.yml
```

## Raspberry Pi

### Hostname mismatch

Problem:

The hostname returned by SSH does not match the inventory host.

Cause:

The node was imaged with the wrong hostname or the wrong SD card was inserted.

Resolution:

Set the hostname to the expected machine name or reimage the node with the correct hostname.

Verification:

```bash
ssh abdul@192.168.68.101 hostname
```

### Kernel cmdline cgroup settings

Problem:

K3s fails or Kubernetes cannot manage memory and CPU resources correctly.

Cause:

Required Raspberry Pi cgroup kernel parameters are missing, or `cgroup_disable=memory` is present.

Resolution:

Run the baseline playbook:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml
```

The `common` role manages cgroup settings in `/boot/firmware/cmdline.txt` and reboots when required.

Verification:

```bash
ssh abdul@192.168.68.101 'cat /proc/cmdline'
```

Confirm memory cgroups are enabled.

### zram swap enabled

Problem:

Kubernetes reports swap-related problems or node readiness is unstable.

Cause:

Swap or zram swap is active.

Resolution:

Run:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml
```

The `common` role disables active swap, disables `zramswap.service` when present and comments swap entries in `/etc/fstab`.

Verification:

```bash
ssh abdul@192.168.68.101 'swapon --show'
```

The command should return no active swap devices.

### Time synchronization

Problem:

TLS, Kubernetes or package operations behave inconsistently.

Cause:

Node time is incorrect or time synchronization is not running.

Resolution:

Run the baseline playbook. The `common` role installs and configures Chrony.

Verification:

```bash
ssh abdul@192.168.68.101 'timedatectl status'
ssh abdul@192.168.68.101 'systemctl status chrony --no-pager'
```

## Kubernetes

### kubeconfig points to localhost

Problem:

kubectl on the management workstation cannot reach the cluster API.

Cause:

The K3s kubeconfig originally points to `127.0.0.1`, which only works on the control-plane node.

Resolution:

Run the K3s playbook so the kubeconfig is fetched and rewritten:

```bash
cd ansible
ansible-playbook playbooks/k3s.yml
```

Verification:

```bash
cd ..
kubectl --kubeconfig ansible/kubeconfig get nodes
```

### Worker labels missing

Problem:

Worker nodes do not display the expected worker role.

Cause:

Kubernetes does not automatically add the worker role label in this setup.

Resolution:

Run the K3s playbook. The role applies:

```text
node-role.kubernetes.io/worker=worker
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes
```

### Node naming mismatch

Problem:

Kubernetes node names do not match inventory hostnames.

Cause:

The operating system hostname was wrong when K3s registered the node.

Resolution:

Correct the node hostname, then rebuild or rejoin the node as needed.

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
```

### Cluster verification commands

Problem:

Cluster health is uncertain after changes.

Cause:

Installation success does not guarantee all system components are healthy.

Resolution:

Run:

```bash
kubectl --kubeconfig ansible/kubeconfig get nodes -o wide
kubectl --kubeconfig ansible/kubeconfig get pods -n kube-system
kubectl --kubeconfig ansible/kubeconfig get storageclass
kubectl --kubeconfig ansible/kubeconfig top nodes
```

Verification:

Nodes should be `Ready`, system pods should be running, and Metrics Server should return node metrics.

## Networking

### Ethernet preflight fails

Problem:

The baseline playbook fails before disabling Wi-Fi.

Cause:

The `network` role requires `eth0` to exist, be operationally up, carry the node inventory address and provide the default route through `192.168.68.1`.

Resolution:

Check physical cabling, the TP-Link TL-SG108E switch port, DHCP reservation and the node's Ethernet state:

```bash
cd ansible
ansible <hostname> -m shell -a "ip -br addr show dev eth0"
ansible <hostname> -m shell -a "ip route show default"
```

Verification:

```bash
ansible-playbook playbooks/baseline.yml --limit <hostname>
```

The play should pass preflight before any Wi-Fi change is attempted.

### Wi-Fi needs emergency recovery

Problem:

Ethernet access is unavailable and temporary Wi-Fi recovery is required.

Cause:

Dedicated cluster nodes normally keep Wi-Fi disabled through Ansible.

Resolution:

Re-enable Wi-Fi only through direct console access, an existing Ethernet SSH session or another explicitly documented recovery path:

```bash
sudo nmcli radio wifi on
```

Correct the wired network issue before returning the node to normal operation.

Verification:

After Ethernet is restored, rerun the baseline:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml --limit <hostname>
ansible <hostname> -m command -a "nmcli radio wifi"
```

The final Wi-Fi radio state should be `disabled`.

### Wi-Fi has an IPv4 address

Problem:

`wlan0` has an IPv4 address after baseline execution.

Cause:

Wi-Fi may have been manually re-enabled for recovery, or NetworkManager may not have applied the radio state.

Resolution:

Run the baseline playbook:

```bash
cd ansible
ansible-playbook playbooks/baseline.yml --limit <hostname>
```

Verification:

```bash
ansible <hostname> -m shell -a "ip -br addr show | grep -E 'eth0|wlan0'"
ansible <hostname> -m command -a "nmcli radio wifi"
```

`eth0` should carry the node address, `wlan0` should have no IPv4 address and Wi-Fi should be `disabled`.

### LoadBalancer IP is pending

Problem:

A `LoadBalancer` service does not receive an external IP.

Cause:

MetalLB may not be installed, the address pool may be missing, or the service may request an address outside the configured pool.

Resolution:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -k kubernetes/platform/networking/metallb
kubectl --kubeconfig ansible/kubeconfig get ipaddresspools -A
kubectl --kubeconfig ansible/kubeconfig describe svc pihole -n networking
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get svc pihole -n networking
```

The Pi-hole service should show `192.168.68.200` as its external IP.

### MetalLB custom resources fail on first apply

Problem:

Applying the MetalLB kustomization reports that `IPAddressPool` or `L2Advertisement` has no resource mapping.

Cause:

The MetalLB CRDs were created during the same apply operation, but the Kubernetes API had not established them before custom resources were submitted.

Resolution:

Wait for MetalLB and apply the same kustomization again:

```bash
kubectl --kubeconfig ansible/kubeconfig wait --namespace metallb-system --for=condition=Available deployment/controller --timeout=180s
kubectl --kubeconfig ansible/kubeconfig rollout status daemonset/speaker -n metallb-system --timeout=180s
kubectl --kubeconfig ansible/kubeconfig apply -k kubernetes/platform/networking/metallb
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get ipaddresspools,l2advertisements -A
```

### Pi-hole DNS does not resolve public names

Problem:

Queries sent to Pi-hole do not resolve public names.

Cause:

The Pi-hole pod may not be running, upstream DNS may be misconfigured, or the LoadBalancer path may not be reachable from the client.

Resolution:

Check Pi-hole state:

```bash
kubectl --kubeconfig ansible/kubeconfig get pods,svc,pvc -n networking
kubectl --kubeconfig ansible/kubeconfig logs deployment/pihole -n networking
```

Verification:

```bash
dig @192.168.68.200 openai.com +short
```

### Pi-hole pod waits for the admin Secret

Problem:

The Pi-hole pod does not start and reports that `pihole-admin` is missing.

Cause:

The real administrative password Secret is intentionally not committed to Git.

Resolution:

Create the Secret locally:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/networking/pihole/namespace.yaml
kubectl --kubeconfig ansible/kubeconfig create secret generic pihole-admin \
  --namespace networking \
  --from-literal=password='<strong-local-password>' \
  --dry-run=client -o yaml | kubectl --kubeconfig ansible/kubeconfig apply -f -
kubectl --kubeconfig ansible/kubeconfig rollout restart deployment/pihole -n networking
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get pods -n networking
```

### `.home.arpa` service name does not resolve

Problem:

`pihole.home.arpa` does not resolve.

Cause:

Pi-hole local DNS configuration may not include the expected `dnsmasq` line, or the pod may need to be restarted after configuration changes.

Resolution:

Confirm the deployment includes:

```text
address=/pihole.home.arpa/192.168.68.201
```

The expected value is `192.168.68.201`. The earlier `.200` value is the
rollback destination only; it must not remain in the desired deployment.

Reapply the Pi-hole manifests:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -k kubernetes/platform/networking/pihole
kubectl --kubeconfig ansible/kubeconfig rollout restart deployment/pihole -n networking
kubectl --kubeconfig ansible/kubeconfig rollout status deployment/pihole -n networking --timeout=300s
```

Verification:

```bash
dig @192.168.68.200 pihole.home.arpa +short
```

### LoadBalancer IP works from nodes but not from the management environment

Problem:

The Pi-hole LoadBalancer IP works from Kubernetes node networking, but not from the execution environment used by automation.

Cause:

The execution environment may not be attached to the same Layer 2 network path as the Raspberry Pi LAN, even if it can reach the Kubernetes API.

Resolution:

Validate from a host-network pod:

```bash
kubectl --kubeconfig ansible/kubeconfig run lb-dns-public-test --rm -i --restart=Never --image=busybox:1.36 --overrides='{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}' -- nslookup openai.com 192.168.68.200
```

Verification:

The test pod should receive DNS answers from `192.168.68.200`.

## Ingress

### test.home.arpa does not resolve from the workstation

Problem:

`dig test.home.arpa` returns no answer or `curl http://test.home.arpa` reports
that the host cannot be resolved.

Cause:

The workstation or browser client is not using Pi-hole as its DNS resolver.

Resolution:

First verify that Pi-hole has the record:

```bash
dig @192.168.68.200 test.home.arpa +short
```

If this returns `192.168.68.201`, update the client or router DNS configuration
so the client uses Pi-hole for `.home.arpa` names.

Verification:

```bash
dig test.home.arpa +short
```

Expected result:

```text
192.168.68.201
```

### Pi-hole hostname resolves but the dashboard is unavailable

Problem:

`pihole.home.arpa` resolves to `192.168.68.201`, but the dashboard returns a
Traefik error or does not load.

Cause:

The Ingress may reference the wrong backend, the `pihole-web` endpoints may be
empty, or `Certificate/pihole-home-arpa` may not be ready.

Resolution:

```bash
kubectl --kubeconfig ansible/kubeconfig get ingress pihole -n networking
kubectl --kubeconfig ansible/kubeconfig describe ingress pihole -n networking
kubectl --kubeconfig ansible/kubeconfig get service,endpoints pihole-web -n networking
kubectl --kubeconfig ansible/kubeconfig get certificate,certificaterequest -n networking
kubectl --kubeconfig ansible/kubeconfig describe certificate pihole-home-arpa -n networking
```

The Ingress backend must be `pihole-web:http`. Do not point it at the DNS
LoadBalancer Service.

Verification:

```bash
curl --resolve pihole.home.arpa:443:192.168.68.201 \
  --cacert "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt" \
  https://pihole.home.arpa/admin/
```

If certificate verification fails, verify Root CA trust and inspect the served
chain before changing the Ingress or issuer.

### Traefik Service has no external IP

Problem:

The Traefik Service remains pending or does not receive `192.168.68.201`.

Cause:

MetalLB is not running, the address pool is missing, or another Service is
already using the requested IP.

Resolution:

```bash
kubectl --kubeconfig ansible/kubeconfig get pods -n metallb-system
kubectl --kubeconfig ansible/kubeconfig get ipaddresspools -A
kubectl --kubeconfig ansible/kubeconfig get svc -A
kubectl --kubeconfig ansible/kubeconfig describe svc traefik -n ingress
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get svc traefik -n ingress
```

Expected external IP:

```text
192.168.68.201
```

### Ingress route returns 404

Problem:

DNS resolves and the Traefik Service is reachable, but the request returns
`404`.

Cause:

The request Host header does not match an Ingress rule, or Traefik has not
accepted the `traefik` IngressClass route.

Resolution:

```bash
kubectl --kubeconfig ansible/kubeconfig get ingressclass
kubectl --kubeconfig ansible/kubeconfig get ingress -A
kubectl --kubeconfig ansible/kubeconfig describe ingress whoami -n ingress
kubectl --kubeconfig ansible/kubeconfig logs deployment/traefik -n ingress
```

If local DNS is not configured yet, test with an explicit Host header:

```bash
curl -H 'Host: test.home.arpa' http://192.168.68.201
```

Verification:

The response should contain:

```text
Hostname:
```

## Documentation

### MkDocs virtual environment not active

Problem:

`mkdocs` command is not found.

Cause:

The project virtual environment is not active or dependencies are not installed.

Resolution:

```bash
source .venv/bin/activate
pip install -r requirements/docs.txt
```

Verification:

```bash
mkdocs --version
```

### Python externally managed environment

Problem:

`pip install` fails because the system Python environment is externally managed.

Cause:

Modern Linux distributions protect system Python packages.

Resolution:

Use the project virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements/docs.txt
```

Verification:

```bash
which python
which pip
```

Both should point under `.venv`.

### GitHub Pages publication

Problem:

Documentation builds locally but is not published.

Cause:

GitHub Pages deployment is not yet defined as an automated workflow in the current repository.

Resolution:

For now, validate the local MkDocs build. Add GitHub Pages automation in a future sprint if desired.

Verification:

```bash
mkdocs build
```

## Certificates and HTTPS

### ClusterIssuer is not ready

Problem:

`ClusterIssuer/homelab-server-ca` does not report `Ready=True`.

Cause:

The `homelab-server-ca` Secret may be missing from the `cert-manager`
namespace, the certificate and private key may not match, or cert-manager may
not be healthy.

Resolution:

Verify cert-manager and recreate the runtime Secret from external PKI material:

```bash
kubectl --kubeconfig ansible/kubeconfig get pods -n cert-manager
scripts/pki/create-server-ca-secret.sh --kubeconfig ansible/kubeconfig
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/issuers/homelab-server-ca.yaml
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get clusterissuer homelab-server-ca
kubectl --kubeconfig ansible/kubeconfig describe clusterissuer homelab-server-ca
```

### Certificate is not issued

Problem:

`Certificate/test-home-arpa` does not report `Ready=True`.

Cause:

The ClusterIssuer may not be ready, the CertificateRequest may be denied or
failed, or the target namespace may not exist.

Resolution:

Inspect the certificate and related requests:

```bash
kubectl --kubeconfig ansible/kubeconfig describe certificate test-home-arpa -n ingress
kubectl --kubeconfig ansible/kubeconfig get certificaterequest -n ingress
kubectl --kubeconfig ansible/kubeconfig describe certificaterequest -n ingress
```

Correct the issuer or Secret issue, then reapply:

```bash
kubectl --kubeconfig ansible/kubeconfig apply -f kubernetes/platform/certificates/test/certificate.yaml
```

Verification:

```bash
kubectl --kubeconfig ansible/kubeconfig get secret test-home-arpa-tls -n ingress
```

### HTTPS certificate is not trusted

Problem:

`curl https://test.home.arpa/` or a browser reports an untrusted certificate.

Cause:

The HomeLab Root CA may not be installed in the client trust store, the wrong
certificate may be served, or the client may be using a DNS path that does not
reach Traefik.

Resolution:

Validate directly with the Root CA:

```bash
curl --resolve test.home.arpa:443:192.168.68.201 \
  --cacert "${HOMELAB_PKI_DIR}/root/certs/homelab-root-ca.crt" \
  https://test.home.arpa/
```

If this succeeds, install the Root CA into the client trust store and verify the
fingerprint through a trusted channel.

Verification:

```bash
curl https://test.home.arpa/
```

### HTTP does not redirect to HTTPS

Problem:

`http://test.home.arpa/` serves plain HTTP or does not redirect.

Cause:

Traefik may not have been upgraded with the entry-point redirection values.

Resolution:

Reapply the Traefik Helm values:

```bash
helm upgrade --install traefik traefik/traefik \
  --version 41.0.2 \
  --namespace ingress \
  --values kubernetes/platform/ingress/values.yaml \
  --kubeconfig ansible/kubeconfig
```

Verification:

```bash
curl --resolve test.home.arpa:80:192.168.68.201 \
  -I http://test.home.arpa/
```

The response should contain a `Location` header for `https://test.home.arpa/`.

## Design Decisions

### Troubleshooting follows operational layers

Issues are grouped by SSH, Ansible, Raspberry Pi, Kubernetes and documentation because failures usually occur at one of those layers.

### Verification is required after every fix

Each issue includes a verification step so the operator can confirm the result.

## Best Practices

- verify SSH before debugging Ansible
- verify Ansible before debugging Kubernetes installation
- verify DNS and certificate readiness before debugging ingress routing
- run playbooks from the `ansible/` directory
- use `ssh-agent` for encrypted keys
- preserve node hostnames and reserved IPs
- use `kubectl --kubeconfig ansible/kubeconfig` from the repository root
- build MkDocs after documentation changes
- avoid `curl --insecure` and browser exceptions as permanent fixes

## Future Improvements

Future troubleshooting improvements may include:

- service-specific troubleshooting guides
- Kubernetes event collection procedures
- log collection commands
- cert-manager event collection procedures
- monitoring dashboard links
- documented GitHub Pages deployment workflow

## Related Documents

- [Bootstrap](bootstrap.md)
- [Updating](updating.md)
- [Rebuilding](rebuilding.md)
- [Ansible](../infrastructure/ansible.md)
- [Kubernetes](../infrastructure/kubernetes.md)
- [Ingress](../infrastructure/ingress.md)
- [Certificate Operations](certificates.md)
- [Security](../infrastructure/security.md)
