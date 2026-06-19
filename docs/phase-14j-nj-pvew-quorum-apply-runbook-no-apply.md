# Phase 14J-NJ — PVEW Quorum Apply Runbook No-Apply

Date: 2026-06-19  
Scope: documentation-only apply runbook. No live Proxmox, corosync, guest, storage, nginx, Cloudflare, worker, scheduler, model, or DB mutation.

## Purpose

This runbook prepares the durable quorum fix required before continuing platform buildout.

The immediate outage was resolved by:

1. Temporary `pvecm expected 1`.
2. Starting VM200 and CT203.
3. Patching VM200 nginx CT203 upstream snippets to CT203's current address.
4. Reloading nginx after config test passed.

This runbook does **not** apply a cluster mutation. It defines the inspection, gates, preferred mutation path, rollback, and verification needed before any future apply.

## Current known state

- Latest repo checkpoint before this runbook: Phase 14J-NI.
- Public `/system/status` is HTTP 200.
- Public app hash is `afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d`.
- PVEW is temporarily quorate with expected votes set to 1.
- Proxmox cluster name is `ClusterOfThings`.
- Corosync config still lists three nodes:
  - `pve`
  - `pvew`
  - `pveso`
- Only PVEW was active during the incident.
- VM200 `website-edge` is running and onboot=1.
- CT203 `edge-controller-pvew` is running and onboot=1.
- CT204 `edge-data-pvew` is stopped and onboot=0.
- Private storage remains locked/unmounted.
- Workers remain offline.
- No model or scheduler activation occurred.

## Preferred durable architecture decision

Preferred path from Phase 14J-NI:

> Make PVEW independent enough to boot and operate VM200/CT203 without requiring PVESO quorum.

This likely means removing or reshaping stale/undesired cluster dependency, not relying on manual `pvecm expected 1`.

A QDevice remains a valid alternative only if the project intentionally keeps a multi-node Proxmox cluster and has a reliable non-laptop witness.

## Safety principles

Any apply phase must preserve these invariants:

- PVEW remains the always-on platform host.
- PVESO can remain off/parked until compute/model work is explicitly needed.
- VM200 autostarts and serves the website/tunnel.
- CT203 autostarts and serves controller/API/status.
- CT204 remains stopped and non-authority.
- Private storage remains locked/unmounted until a separate storage approval.
- No worker/model/scheduler activation is bundled into quorum work.
- No Cloudflare/DNS/tunnel config mutation is bundled into quorum work.
- No DB restore/import/migration is bundled into quorum work.
- The laptop does not return to live authority path.

## Required no-apply inspection before any apply

Before mutating quorum/cluster membership, run a read-only capture that records:

### Cluster

- `pvecm status`
- `pvecm nodes`
- `corosync-quorumtool -s`
- `corosync-cfgtool -s`
- `/etc/pve/corosync.conf`
- `/etc/pve/.members`
- `/etc/pve/nodes`
- `/etc/pve/storage.cfg`
- `/etc/pve/ha/resources.cfg`
- `/etc/pve/ha/groups.cfg`
- `/etc/pve/replication.cfg` if present

### Guests

- `qm list`
- `pct list`
- `qm config 200`
- `pct config 203`
- `pct config 204`
- status for VM200/CT203/CT204
- onboot/startup flags
- ownership/location under `/etc/pve/nodes/*/qemu-server` and `/etc/pve/nodes/*/lxc`

### Storage

- `pvesm status`
- `pvesm list local-lvm`
- `findmnt`
- `cryptsetup status apc_private_data`
- confirmation `/srv/apc-private-data` is not mounted
- confirmation `/dev/mapper/apc_private_data` is absent

### Services

- PVEW `pve-cluster`, `corosync`, `pve-guests`, `pvedaemon`, `pveproxy`, `pvestatd`
- VM200 `cloudflared`, `nginx`, `qemu-guest-agent`
- CT203 `edge-queue-controller`

### Public checks

- `/`
- `/system/status`
- `/api/me`
- `/api/account/credit-pools`
- app hash
- stale public text absence

## Apply option A: PVEW independent / stale cluster dependency removal

This is the preferred direction, but the exact mutation must be generated only after the inspection confirms all gates.

Potential procedure class:

1. Confirm PVEW has the needed guest configs locally visible under `/etc/pve/nodes/pvew`.
2. Confirm no HA resources depend on stale nodes.
3. Confirm no replication jobs depend on stale nodes.
4. Confirm no shared storage or guest placement requires stale nodes.
5. Confirm CT204 remains stopped and backup-only.
6. Backup Proxmox cluster config.
7. Apply a controlled cluster reshape/removal procedure.
8. Verify PVEW can manage guests without requiring unavailable peers.
9. Verify VM200 and CT203 can start/autostart.
10. Reboot test only under a separate explicit approval.

Important: do not run `pvecm delnode` or edit corosync config until the apply command sequence and rollback path are fully specified and approved.

## Apply option B: QDevice/witness

This is acceptable only if we intentionally keep PVEW/PVESO as a cluster.

Required gates:

- choose reliable witness host
- confirm witness is not the laptop unless explicitly approved
- confirm firewall/network reachability
- install/configure QDevice using a separate explicit approval
- verify quorum with PVEW alone and PVESO off
- verify VM200/CT203 autostart behavior

## Apply option C: keep PVESO online

Not recommended because it conflicts with the desired architecture.

## Explicit non-goals for the quorum apply

- No storage encryption work.
- No CT204 authority change.
- No CT204 start.
- No worker activation.
- No model endpoint call.
- No scheduler dispatch.
- No frontend feature work.
- No Cloudflare/DNS/tunnel mutation.
- No DB migration/import/restore.

## Rollback requirements

A future apply must include:

- path to restore backed-up Proxmox config
- expected state if rollback succeeds
- public website health check
- VM200/CT203 status check
- CT204 stopped check
- private storage locked/unmounted check
- repo documentation checkpoint after rollback or success

## Post-apply verification requirements

After a successful durable quorum apply:

- PVEW is quorate or no longer blocked by stale peers for local guest management.
- VM200 running.
- CT203 running.
- CT204 stopped.
- private storage not mounted.
- `/dev/mapper/apc_private_data` absent.
- VM200 `cloudflared.service` active/enabled.
- VM200 `nginx.service` active/enabled.
- CT203 `edge-queue-controller.service` active/enabled.
- Public `/` HTTP 200.
- Public `/system/status` HTTP 200 schema 2.
- Public app hash unchanged.
- workers remain offline.
- no new jobs dispatched.
- no model endpoint called.
