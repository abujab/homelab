# WO-0012 — Power-Loss and Cold-Boot Resilience

**Status:** Complete — implemented and validated 2026-07-28
**Owner:** Abdul Jabbar
**Implementation agent:** Codex
**Reviewers:** Independent AI review followed by human approval
**Target repository:** `abujab/homelab`
**Created:** 2026-07-28
**Priority:** High — control-plane availability and recovery safety

---

## 1. Background

A site-wide power outage left the Raspberry Pi cluster without running services after power returned.

The K3s control-plane service on `pi4mB01` started before the system clock had synchronized. During this cold boot, certificate-chain verification occurred while the local clock was earlier than the cluster CA certificate's `notBefore` time. K3s then entered a persistent retry loop reporting:

```text
token CA hash does not match the cluster CA certificate hash
```

The incident was recovered without rotating credentials, replacing certificates, deleting the K3s datastore, or rebuilding the cluster. Once the clock was correct, restarting only `k3s` allowed the existing cluster identity and datastore to start normally.

This work order must prevent recurrence and add evidence-based cold-boot recovery controls.

`WO-0011` remains reserved for the planned Longhorn work. This incident-response
work therefore uses `WO-0012` and must not change the scope or status of
`WO-0011`.

---

## 2. Objective

Make K3s startup resilient to complete power loss by ensuring that:

1. K3s server and agent services do not start before trustworthy system time is available.
2. The implementation is idempotent and managed through Ansible.
3. Startup failure remains safe when accurate time cannot be obtained.
4. The cluster recovers automatically after a normal cold boot once network time is available.
5. Ansible and operators do not modify K3s token credentials, cluster CA
   identity or datastore identity as part of time recovery; normal K3s-managed
   metadata updates, database writes and legitimate leaf-certificate renewal
   are observed and recorded rather than treated as automatic failure.
6. Operators receive a documented diagnosis and recovery procedure.
7. External resilience layers are clearly separated from repository automation.

---

## 3. Resilience layers

| Layer | Control | Ownership in this work order |
|---|---|---|
| 1 | Gate K3s startup on trustworthy time | Implement fully through Ansible |
| 2 | Battery-backed external RTC | Operator hardware task; document and prepare later automation |
| 3 | Independent local NTP source | Operator infrastructure task; document requirements and support client configuration |
| 4 | UPS for Pi, switch, storage and time source | Operator hardware task; document requirements and future NUT integration |
| 5 | Boot-health validation and alert-ready checks | Implement local checks and documentation; external alert delivery may follow later |
| 6 | K3s datastore snapshot and token recovery readiness | Verify and document existing state without exposing secrets |

Layers 2, 3 and 4 require operator work outside Git because they involve selecting, purchasing, installing, wiring or configuring external hardware or infrastructure. Their software configuration may be automated in a later work order after the exact components and endpoints are known.

---

## 4. Scope

### 4.1 Repository discovery

Before changing anything, inspect and document:

- the existing Ansible inventory groups and host variables;
- the role that currently owns time configuration;
- the role or playbook that installs K3s;
- the generated `k3s.service` and `k3s-agent.service` units;
- the active time synchronization implementation on every node;
- whether `systemd-timesyncd`, Chrony or another NTP client is authoritative;
- the enabled network wait-online implementation;
- the current K3s server and agent restart handlers;
- the existing troubleshooting, backup and rebuilding documentation;
- the current work-order and evidence conventions.

Do not assume filenames, role names or inventory group names. Reuse the repository's established structure.

### 4.2 Chrony synchronization baseline

Repository discovery has established that the existing `common` role installs
and owns Chrony. Chrony is therefore the required implementation for this work
order.

For every Kubernetes node, manage and verify:

- `chrony` is installed; `chrony.service` is enabled and active, with the `chronyd` process running;
- `chrony-wait.service` is available and its effective command and timeout are
  recorded;
- `chrony-wait.service` is enabled when required by the selected systemd design;
- `chronyc tracking` reports a synchronized system clock before K3s starts;
- `chronyc sources` exposes at least one usable source during the normal
  acceptance path;
- record whether the active Chrony sources are package-managed, host-managed
  or inventory-managed;
- preserve the existing source configuration during WO-0012;
- do not bring NTP endpoints under Ansible ownership until the independent local
  source and fallback design are selected in a later operator-approved work
  order;
- no competing NTP implementation such as `systemd-timesyncd`, `ntpd` or another
  Chrony instance is introduced;
- timezone configuration remains unchanged unless the existing desired state
  requires otherwise.

Do not replace Chrony with `systemd-timesyncd`. Fail clearly if the node has an
unsupported or ambiguous time-service state.

### 4.3 Fail-closed K3s time gate

Implement a direct, fail-closed systemd relationship for:

- `k3s.service` on `pi4mB01`;
- `k3s-agent.service` on worker nodes.

The intended effective relationship is:

```ini
[Unit]
Wants=network-online.target
After=network-online.target
Requires=chrony-wait.service
After=chrony-wait.service
```

The exact implementation remains subject to validation against the generated
K3s units and the installed Chrony package, but it must preserve these
properties:

1. K3s cannot start successfully when `chrony-wait.service` fails.
2. Merely reaching `time-sync.target` is not accepted as proof of synchronized
   time.
3. Vendor-generated K3s unit files are not edited directly.
4. Managed drop-ins are deterministic and owned by Ansible.
5. The effective unit configuration proves the dependency, not merely the
   presence of a drop-in file.

The current `chrony-wait.service` timeout is finite. The implementation must
inspect and record the effective timeout and define a safe recovery path after
that timeout.

The required recovery behavior is:

- the initial K3s start fails closed when Chrony cannot synchronize within the
  wait period;
- failure remains visible in systemd and the journal;
- SSH and other management access remain available;
- a rate-limited, systemd-managed retry mechanism may periodically recheck
  Chrony and start the applicable K3s service only after synchronization is
  proven;
- each synchronization probe is bounded;
- only one retry mechanism may be active per node;
- the mechanism stops retrying after K3s starts successfully;
- no uncontrolled K3s restart loop is permitted;
- the operator recovery command is documented even when automatic late recovery
  is implemented.

Codex must validate whether a dedicated prerequisite unit plus timer, or another
systemd-native implementation, is the simplest reliable design. It must not
assume that `Restart=on-failure` alone retries a service whose required
dependency failed before the K3s process started.

### 4.4 Fail-safe behavior

If the network or time source is unavailable during boot:

- K3s must not be reinstalled, reinitialized or started against an untrusted
  clock;
- Ansible and operators must not rotate, rewrite or replace token credentials,
  CA files, certificate material or datastore files;
- token credential content must remain identical;
- cluster CA certificate hashes must remain identical;
- no datastore reset, replacement or cluster-identity change may occur;
- normal K3s-managed token-file metadata updates, SQLite/WAL writes and
  legitimate leaf-certificate renewal are permitted when K3s later starts and
  must be recorded rather than misclassified as credential rotation;
- the node must remain remotely diagnosable through SSH when networking is
  otherwise available;
- the service state and logs must clearly distinguish waiting for time,
  synchronization timeout and K3s failure after synchronized time;
- once accurate time becomes available, K3s must be able to start without
  credential or CA changes;
- any automatic recovery must be rate-limited, observable and free of
  uncontrolled restart loops.

### 4.5 K3s service ownership

The Ansible implementation must:

- create deterministic systemd drop-ins;
- run `systemctl daemon-reload` only when needed;
- restart a K3s service only when its effective configuration changes;
- restart server nodes and worker nodes sequentially;
- avoid restarting all cluster nodes simultaneously;
- verify local K3s readiness after a server restart;
- verify the Kubernetes node returns to `Ready`;
- preserve the K3s server-token credential content and cluster CA hashes;
- preserve cluster and datastore identity without reset or replacement;
- permit and record normal K3s-managed token-file metadata changes, SQLite/WAL
  writes and legitimate leaf-certificate renewal;
- preserve the existing administrator-kubeconfig ownership and distribution
  model.

Normal reconciliation must remain idempotent.

### 4.6 Boot-health command or script

Add read-only health checks with explicit credential scope.

Every node reports:

- hostname;
- boot ID;
- current UTC time;
- Chrony service state;
- `chronyc tracking` synchronization state;
- selected and usable Chrony sources where available;
- state and latest result of `chrony-wait.service`;
- state of `k3s.service` or `k3s-agent.service`;
- presence of the known token/CA mismatch message in the current boot journal.

The K3s server additionally reports:

- local `/readyz` using existing root-only K3s credentials;
- local API-server service health;
- the cluster CA hash without printing private material.

Workers must:

- check only local time state and `k3s-agent` health;
- not receive an administrator kubeconfig;
- not treat absence of cluster-admin credentials as a health failure.

Cluster-wide node readiness must run from either:

- `pi4mB01` using its existing root-only local K3s credentials; or
- the management workstation using `ansible/kubeconfig`.

Token-content preservation checks must run locally on `pi4mB01` under root.
The comparison may use temporary in-memory values or protected temporary files
that are removed immediately after comparison. Committed evidence must record
only:

```text
server_token_content_unchanged=true
```

Do not retain:

- the token itself;
- a partial token;
- the token's CA-hash prefix as preservation evidence;
- a full checksum derived from the complete token;
- any reversible or reusable token-derived value.

The health tooling must:

- redact all tokens and credentials;
- never print private keys;
- not modify system state;
- return a non-zero exit code when a required local condition is unhealthy;
- distinguish `waiting-for-time`, `time-wait-failed`,
  `k3s-failed-after-time-sync` and `healthy`;
- be usable manually and from future monitoring automation.

### 4.7 Incident runbook

Update or create an operations runbook covering:

1. symptoms of wrong-time K3s startup;
2. confirmation commands;
3. safe recovery sequence;
4. conditions under which restarting only `k3s` is appropriate;
5. conditions requiring investigation before restart;
6. explicit prohibitions against:
   - rotating the server token;
   - replacing CA files;
   - deleting `/var/lib/rancher/k3s`;
   - reinstalling K3s;
   - initializing a new cluster;
   - updating all agents to trust an unverified new CA;
7. commands that expose only CA hashes rather than complete tokens;
8. verification that the original datastore and cluster identity remain in use;
9. post-recovery workload checks;
10. escalation path for filesystem, datastore or certificate corruption.

### 4.8 SQLite backup and recovery readiness

The current K3s server uses the embedded SQLite datastore, including
`state.db` and its associated write-ahead-log files. It does not use embedded
etcd.

Read-only verification must confirm and document:

- the effective K3s datastore type;
- the location and ownership of `state.db` and related SQLite/WAL files;
- the currently documented or automated SQLite-consistent backup mechanism;
- the timestamp and result of the most recent applicable backup, when one
  exists;
- gaps in current backup readiness without treating absence of etcd snapshots
  as an acceptance failure;
- that the K3s server token must be backed up securely with the datastore;
- that neither the token nor kubeconfig credentials are stored in plaintext in
  Git or retained evidence.

Explicit requirements:

- do not run `k3s etcd-snapshot` for this SQLite-backed cluster;
- scheduled etcd snapshots are `not applicable`;
- do not perform an etcd restore;
- do not copy a live `state.db` file in a way that can produce an inconsistent
  backup;
- do not implement a datastore restore in this work order;
- document a future SQLite-consistent backup and restore procedure where current
  automation is insufficient.

---

## 5. External operator tasks

These are not to be silently implemented or simulated by Codex.

### 5.1 Layer 2 — External RTC

**Operator actions:**

- select a Raspberry Pi 4-compatible battery-backed RTC;
- confirm GPIO/I2C compatibility with existing HATs, cases and cabling;
- purchase the RTC and battery;
- physically install it on `pi4mB01`;
- decide whether all future control-plane nodes require one;
- validate that the clock remains reasonable after network-disconnected power loss.

**Repository follow-up after hardware selection:**

- add the exact device-tree overlay and package configuration;
- configure system-to-hardware and hardware-to-system clock behavior;
- keep the RTC in UTC;
- verify `/dev/rtc*` and `hwclock`;
- add RTC health checks and documentation.

RTC work is not an acceptance dependency for the software startup gate in this work order.

### 5.2 Layer 3 — Local NTP source

**Operator actions:**

- select an NTP source independent of the Kubernetes cluster;
- prefer an always-on router, firewall, NAS or dedicated management host;
- assign it a stable IP or stable internal DNS name;
- ensure it remains available during cluster cold boot;
- provide at least one fallback time source;
- define whether the local source itself synchronizes externally or uses a hardware time source.

Do not make a Kubernetes workload the only time source required for Kubernetes to start. That would create a circular bootstrap dependency.

**Repository follow-up after endpoint selection:**

- explicitly transfer ownership of the chosen NTP server list to Ansible;
- document the previous source-management mechanism before replacing it;
- validate reachability and synchronization;
- document fallback behavior;
- add configuration drift checks.

WO-0012 must preserve the existing Chrony source configuration and must not
introduce new NTP endpoints.

### 5.3 Layer 4 — UPS

**Operator actions:**

- size a UPS for the control-plane Pi, Ethernet switch, powered storage enclosure and local NTP source;
- purchase and install the UPS;
- choose USB, serial or network management capability;
- document expected runtime;
- test mains-loss and mains-return behavior safely;
- define the low-battery shutdown threshold.

**Repository follow-up after UPS selection:**

- evaluate Network UPS Tools or the vendor-supported interface;
- manage graceful shutdown configuration;
- define node shutdown order;
- preserve enough runtime for Kubernetes and storage shutdown;
- test restoration after power returns;
- add UPS state to monitoring.

No destructive UPS shutdown test may be automated until the operator explicitly approves a test plan.

---

## 6. Safety constraints

The implementation must not:

- rotate or rewrite K3s tokens;
- rotate, recreate or copy K3s CA material;
- delete, move or replace the K3s datastore;
- execute `k3s server --cluster-reset`;
- reinstall K3s;
- regenerate the administrator kubeconfig;
- change Kubernetes workload configuration merely to mask startup failure;
- weaken certificate validation;
- use short tokens to bypass CA verification;
- expose complete token values in output, logs, evidence or Git;
- reboot the full cluster at once;
- manipulate the system clock to simulate failure;
- alter certificate validity periods for testing;
- block SSH or all node networking during delayed-time validation;
- require internet access when a configured local NTP source is available;
- install an RTC, UPS or external NTP appliance without an operator-approved hardware decision.

Any unexpected CA, token, certificate, datastore or filesystem inconsistency must stop the playbook with a clear diagnostic rather than attempting repair.

---

## 7. Implementation requirements

### 7.1 Ansible quality

All changes must be:

- declarative;
- idempotent;
- inventory-driven where node roles differ;
- implemented in the existing owning roles rather than an unrelated new role unless repository structure justifies it;
- protected by assertions for unsupported states;
- tagged consistently with the existing project;
- accompanied by handlers only where required;
- free of shell commands when an appropriate Ansible module exists;
- explicit about commands that are read-only;
- compatible with check mode where practical.

### 7.2 Systemd validation

Validate the effective service configuration with commands equivalent to:

```bash
systemctl cat k3s
systemctl show k3s -p After -p Wants -p Requires
systemd-analyze verify <managed-unit-or-drop-in-context>
```

Use the corresponding `k3s-agent` commands on worker nodes.

Evidence must demonstrate that the managed dependency is active in the effective unit, not merely that a file exists.

### 7.3 Time validation

Evidence must show:

- the actual active time service;
- synchronization status;
- selected time source where exposed;
- `time-sync.target` ordering;
- successful completion of the synchronization-wait mechanism;
- K3s startup occurring after trusted time is established.

Use monotonic boot timing or carefully interpreted current-boot journal evidence where wall-clock timestamps may have changed during synchronization.

### 7.4 Cluster validation

After each controlled change:

```bash
KUBECONFIG=ansible/kubeconfig kubectl get nodes -o wide
KUBECONFIG=ansible/kubeconfig kubectl get pods -A -o wide
KUBECONFIG=ansible/kubeconfig kubectl get --raw='/readyz?verbose'
```

Also verify:

- all four nodes return to `Ready`;
- existing services regain expected endpoints;
- Pi-hole DNS remains functional;
- Traefik ingress remains functional;
- persistent storage mounts remain correct;
- no application data is recreated;
- server-token credential content remains identical;
- cluster CA hashes remain identical;
- no datastore reset, replacement or cluster-identity change occurred;
- normal SQLite/WAL writes, token-file metadata changes and legitimate
  K3s-managed leaf-certificate renewal are recorded separately.

---

## 8. Required validation scenarios

### Scenario A — Normal reconciliation

Run the relevant playbooks twice.

Expected:

- first run changes only the required configuration;
- second run reports `changed=0` and `failed=0`;
- no K3s service restarts on the second run;
- no node reboots;
- cluster remains healthy.

### Scenario B — Controlled K3s restart with synchronized time

On `pi4mB01`:

- confirm time is synchronized;
- restart only `k3s`;
- verify local `/readyz`;
- verify API access from the management workstation;
- verify all nodes and workloads recover.

Expected:

- no token/CA mismatch;
- no operator or Ansible credential changes;
- server-token credential content remains identical;
- cluster CA hashes remain identical;
- same cluster and datastore identity;
- normal database writes or legitimate leaf-certificate renewal are recorded
  rather than treated as failure;
- workloads retain their expected state.

### Scenario C — Single-node cold boot

Reboot only `pi4mB01` after confirming the other nodes and services are stable.

Expected sequence:

1. network becomes operational;
2. accurate time synchronization completes;
3. K3s starts afterward;
4. API server becomes ready;
5. workers reconnect;
6. workloads become healthy.

Retain evidence showing this ordering.

### Scenario D — Controlled worker cold boot

Select one suitable worker, preferably `pi4mB03` or `pi4mB04`, and perform a
controlled reboot after confirming the cluster is otherwise healthy.

Expected sequence:

1. the worker's network becomes operational;
2. Chrony synchronization completes;
3. `chrony-wait.service` succeeds;
4. `k3s-agent.service` starts afterward;
5. the node reconnects and returns to `Ready`;
6. workloads previously scheduled on the node recover or reschedule normally.

Retain evidence proving the effective boot ordering and the node's return to
service. Do not reboot more than one worker at a time.

### Scenario E — Delayed time-source availability

Use a safe, operator-approved method to delay access to the configured time source during a controlled restart of a testable node or service.

Expected:

- K3s does not start against an untrusted clock;
- no operator or Ansible token/CA/certificate/datastore modification;
- token credential content and cluster CA hashes remain identical;
- no datastore reset, replacement or identity change;
- no K3s-managed database writes are expected while K3s remains blocked; any
  writes after successful startup are recorded and explained;
- the system remains diagnosable;
- after time service access returns, synchronization completes;
- K3s starts or can be started through the documented bounded recovery path;
- no permanent retry loop remains.

The test must initially target one worker where practical. It must not:

- change the system clock with `date`, `timedatectl` or equivalent commands;
- alter certificate validity dates;
- change, replace or rotate CA or token material;
- block SSH;
- block all networking on the node;
- affect all cluster nodes simultaneously.

Do not block management access or perform this test on all nodes simultaneously.

### Scenario F — Power-loss simulation

A real power-cut test is optional and requires explicit operator approval after all lower-risk scenarios pass.

Without that approval, use a normal shutdown followed by removal and restoration of power to `pi4mB01`, or another safe cold-boot method agreed by the operator.

A forced power cut must not be initiated by Codex.

---

## 9. Acceptance criteria

The work order is complete only when all applicable criteria pass:

- [x] Active time synchronization implementation is discovered and documented.
- [x] NTP is enabled and unambiguous on every Kubernetes node.
- [x] K3s server startup is gated on accurate synchronized time.
- [x] K3s agent startup is gated on accurate synchronized time.
- [x] Effective systemd dependencies are verified.
- [x] Normal Ansible reconciliation is idempotent.
- [x] No second-run service restart occurs.
- [x] A controlled `pi4mB01` restart completes successfully.
- [x] A single-node cold boot proves time synchronization precedes K3s startup.
- [x] A controlled worker cold boot proves Chrony and `chrony-wait.service`
      complete before `k3s-agent.service` starts.
- [x] The tested worker returns to `Ready` and its workloads recover.
- [x] Delayed time availability produces safe waiting or bounded failure.
- [x] K3s starts normally after time becomes trustworthy.
- [x] No operator or Ansible modification of K3s token credentials.
- [x] Server-token credential content remains identical, verified locally under root without retaining a token-derived checksum.
- [x] Cluster CA certificate hashes remain identical.
- [x] No datastore reset, replacement or cluster-identity change.
- [x] Normal token-file metadata changes, SQLite/WAL writes and legitimate
      K3s-managed leaf-certificate renewal are recorded and do not create false
      acceptance failures.
- [x] Existing Kubernetes resources and application data remain intact.
- [x] All four nodes return to `Ready`.
- [x] Pi-hole DNS and Traefik ingress are functional after recovery.
- [x] Read-only boot-health tooling is implemented.
- [x] Troubleshooting documentation covers the incident and safe recovery.
- [x] SQLite-consistent backup readiness and secure server-token backup are
      documented.
- [x] Etcd snapshots are explicitly recorded as not applicable.
- [x] External RTC, NTP and UPS tasks are recorded separately.
- [x] Strict MkDocs build passes.
- [x] Repository whitespace and validation checks pass.
- [x] Final relevant playbooks run twice with `changed=0`, `failed=0` on the second run.

---

## 10. Evidence requirements

Store concise, sanitized evidence under:

```text
artifacts/WO-0012/
```

Include at minimum:

```text
artifacts/WO-0012/
├── README.md
├── incident-summary.md
├── chrony-baseline.txt
├── systemd-effective-dependencies.txt
├── synchronized-restart.txt
├── control-plane-cold-boot-ordering.txt
├── worker-cold-boot-ordering.txt
├── delayed-time-source-test.txt
├── cluster-health-after-recovery.txt
├── idempotency-run-1.txt
├── idempotency-run-2.txt
├── sqlite-backup-readiness.txt
└── external-resilience-plan.md
```

Evidence must:

- record token-content comparison only as `server_token_content_unchanged=true`
  or `false`;
- omit full K3s tokens;
- omit full or partial token-derived checksums;
- omit private keys;
- omit kubeconfig client credentials;
- redact secrets and sensitive headers;
- record commands and meaningful results;
- distinguish observed results from assumptions;
- retain enough timing information to prove startup ordering;
- identify any test that was not performed and why.

Do not commit complete raw journals when concise extracted evidence is sufficient.

---

## 11. Documentation updates

Update the relevant existing pages, expected to include:

- Kubernetes infrastructure documentation;
- Ansible infrastructure documentation;
- troubleshooting operations documentation;
- backup and recovery documentation;
- rebuilding or cold-boot operations documentation;
- roadmap or project state;
- software or service reference pages if their managed behavior changes.

Document:

- the outage symptom;
- the time/certificate relationship;
- the startup gate;
- safe manual recovery;
- external RTC, local NTP and UPS follow-ups;
- why a cluster-hosted NTP service cannot be the only bootstrap time source;
- why tokens and CA files must not be changed for this failure mode.

Add a new ADR only if the implementation establishes a durable architecture decision not already covered by an existing ADR.

---

## 12. Expected changed-path boundary

Codex must determine the exact paths after repository discovery. Expected categories are:

```text
ansible/
docs/
artifacts/WO-0012/
PROJECT_STATE.md
work-orders/
mkdocs.yml
```

Changes outside these areas require explicit justification in the PR.

Do not modify application manifests, storage disk definitions, PKI material or GitHub workflows unless they are demonstrably required and separately approved.

---

## 13. Pull-request requirements

Create a dedicated branch using the repository convention, expected to resemble:

```text
codex/wo-0012-power-loss-cold-boot-resilience
```

The pull request must include:

- a concise incident summary;
- the discovered root cause and supporting evidence;
- implementation design;
- changed files;
- safety analysis;
- exact validation performed;
- tests intentionally not performed;
- external operator tasks still pending;
- idempotency evidence;
- confirmation that server-token credential content remained identical,
  recorded only as `unchanged=true`, and that cluster CA hashes remained
  identical;
- confirmation that no datastore reset, replacement or identity change occurred;
- record of normal token metadata, SQLite/WAL or K3s-managed leaf-certificate
  changes;
- rollback instructions;
- remaining risks;
- human approval requirement.

Use commit trailers or PR disclosure consistent with the repository's AI-attribution policy once that policy is available.

Codex must not merge the pull request.

The implementation PR is not the final workflow step. Work-order archival,
review-record archival and release `v0.12.0` must follow Section 14.

---

## 14. Completion workflow and release

Follow `docs/development/workflow.md`.

After all validation and evidence requirements pass:

1. set this work order to `Complete`;
2. archive it under the repository's work-order archive convention using the
   `WO-0012` identifier;
3. remove `work-orders/CURRENT.md`;
4. update `PROJECT_STATE.md` with the verified completed state;
5. commit and open the implementation pull request;
6. obtain architecture approval against the implementation PR's final head
   commit;
7. merge the implementation PR;
8. create a separate branch:

   ```text
   review-archive/wo-0012
   ```

9. archive the final implementation-PR approval with the repository script;
10. open and merge the separate review-archive PR;
11. do not archive reviews of the review-archive PR;
12. create release `v0.12.0` only after the review-archive PR is merged.

Codex must not merge either pull request and must not create the release without
the operator's explicit instruction.

The release notes must summarize:

- the outage root cause;
- the Chrony fail-closed K3s startup gate;
- the bounded late-synchronization recovery behavior;
- the validated cold-boot result;
- the SQLite backup-readiness conclusion;
- pending operator work for RTC, local NTP and UPS.

---

## 15. Rollback

Rollback must remove only the configuration introduced by this work order and restore the previous effective systemd dependencies.

Before rollback:

- capture service status and current-boot logs;
- confirm current time synchronization state;
- confirm server-token credential content and cluster CA hashes remain
  identical;
- confirm no datastore reset, replacement or identity change occurred;
- record normal K3s-managed metadata, SQLite/WAL and leaf-certificate changes.

After rollback:

- run `systemctl daemon-reload`;
- restart services sequentially only when necessary;
- verify local API readiness;
- verify all nodes and workloads;
- rerun the relevant Ansible playbook to confirm the intended state.

Rollback must never delete K3s data or rotate credentials.

---

## 16. Completion report

At completion, Codex must provide:

1. summary of implementation;
2. exact repository paths changed;
3. active time synchronization design;
4. effective K3s startup dependencies;
5. cold-boot validation result;
6. delayed-time validation result;
7. cluster health result;
8. idempotency result;
9. server-token preservation result recorded only as `unchanged=true`,
   cluster-CA hash and datastore-identity preservation confirmation, plus any
   normal K3s-managed changes;
10. external operator tasks remaining for RTC, local NTP and UPS;
11. unresolved risks or follow-up work;
12. proposed next work order, without implementing it.

---

## 17. Suggested follow-up work

Do not implement these automatically as part of WO-0012:

- install and automate a battery-backed RTC;
- deploy or configure the selected independent local NTP source;
- purchase and integrate the UPS;
- deploy Network UPS Tools or vendor UPS monitoring;
- implement remote alerts;
- conduct destructive mains-loss or low-battery shutdown testing;
- expand the K3s control plane to additional server nodes;
- change datastore architecture.

Those require separate operator decisions and, where appropriate, separate work orders.
