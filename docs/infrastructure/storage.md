# Storage

---

## Purpose

This document describes the current HomeLab storage state and the direction for future persistent storage.

Storage is currently minimal and suitable for the Kubernetes foundation stage, but it is not yet designed for important stateful workloads.

## Scope

This document covers:

- current storage state
- microSD-based nodes
- Local Path Provisioner
- limitations of current storage
- future Longhorn evaluation
- future backup requirements

This document does not define a final storage architecture or backup implementation.

## Background

The current cluster runs on Raspberry Pi nodes using local microSD storage.

K3s includes Local Path Provisioner, which provides simple local persistent volume support. This is useful for early validation and lightweight experiments but does not provide a complete storage platform.

## Architecture / Implementation

Current storage model:

```text
Raspberry Pi node
|
+-- microSD card
    +-- operating system
    +-- K3s runtime state
    +-- local-path-provisioner volumes when used
```

Current Kubernetes storage component:

| Component | Current State | Purpose |
|-----------|---------------|---------|
| Local Path Provisioner | Installed by K3s | Provides node-local persistent volumes |

Local Path Provisioner stores data on the node where the volume is created. If a pod using that volume moves to another node, the data does not automatically move with it.

No Longhorn, NFS, object storage, dedicated backup system or replicated storage layer is currently implemented.

## Design Decisions

### Use K3s default local storage for the foundation

Local Path Provisioner is acceptable for the current foundation because the cluster is not yet hosting critical stateful services.

### Defer persistent storage architecture

Persistent storage has broader implications for hardware, replication, backups and restore testing. It should be evaluated deliberately before important stateful services are deployed.

### Treat microSD storage as limited

microSD cards are convenient for Raspberry Pi boot disks, but they are not a strong long-term storage foundation for high-write or critical workloads.

## Best Practices

- avoid placing critical data only on local-path volumes
- assume microSD storage can fail
- document any stateful workload before deployment
- define backup and restore expectations before storing important data
- test restore procedures, not only backup creation
- keep storage decisions tied to workload requirements

## Future Improvements

Future storage work should evaluate:

- Longhorn for replicated Kubernetes block storage
- external SSDs or dedicated storage nodes
- backup targets
- restore procedures
- retention requirements
- monitoring for disk health and capacity
- storage classes for different workload types

Before important stateful applications are deployed, HomeLab should have a documented backup and restore model.

## Related Documents

- [Kubernetes](kubernetes.md)
- [Raspberry Pi Cluster](raspberry-pi-cluster.md)
- [Roadmap](../overview/roadmap.md)
