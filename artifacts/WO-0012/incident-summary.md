# Incident Summary

---

## Observed Failure

After an hour-long power outage, the Kubernetes API reported `apiserver not
ready`. The `pi4mB01` K3s journal repeatedly reported `token CA hash does not
match the Cluster CA certificate hash`.

## Root Cause

The Raspberry Pi booted with a stale wall clock from 2026-07-06 while the
existing cluster CA was not valid before 2026-07-21. K3s evaluated the existing
certificate chain before network time synchronization. The resulting message
looked like a token or CA mismatch even though cluster credentials and
datastore identity were intact.

## Recovery

After Chrony synchronized the clock, restarting only `k3s.service` recovered
the existing API and workloads. No token rotation, CA replacement, K3s
reinstallation, datastore reset or cluster initialization was required.

## Preservation Result

```text
server_token_content_unchanged=true
cluster_ca_hashes_unchanged=true
sqlite_datastore_identity_unchanged=true
kube_system_namespace_uid_unchanged=true
```

Normal `state.db`/WAL writes and K3s-managed file timestamps occurred when the
server resumed. They were expected runtime activity, not identity replacement.
