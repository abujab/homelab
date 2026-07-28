# External Resilience Plan

---

## Operator-Owned Work

The following layers are intentionally not implemented by WO-0012:

1. install and automate a battery-backed RTC on each required Raspberry Pi;
2. select an independent LAN NTP source that does not depend on Kubernetes;
3. configure Chrony with public sources retained as fallback;
4. purchase and size a UPS for the Pis, switch, router and powered storage;
5. design Network UPS Tools or vendor monitoring and graceful shutdown;
6. define alerts for unsynchronized time, UPS state and failed cold boots;
7. perform a separately approved mains-loss and low-battery shutdown test.

## Constraints

- A Kubernetes-hosted NTP workload cannot be the only bootstrap source for the
  Kubernetes nodes it is meant to start.
- RTC, NTP and UPS choices require their own architecture and work order.
- Codex did not initiate a forced power cut in WO-0012.

## Recommended Sequence

Independent local NTP design should precede RTC fleet automation. UPS sizing
and graceful shutdown should then include the selected time appliance and all
network dependencies needed for a recoverable boot.
