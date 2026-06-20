# Phase 14J-NL — PVEW Quorum Apply Plan No-Apply

Date: 2026-06-19  
Scope: concrete apply plan only. No live mutation.

## Current checkpoint

Latest checkpoint before this phase: Phase 14J-NK at commit `61a02af`.

Known state:

- Public `/system/status` is HTTP 200.
- Public app hash remains expected.
- PVEW is the intended always-on platform host.
- PVEW was recovered using temporary `pvecm expected 1`.
- Cluster name recorded: `ClusterOfThings`.
- Cluster config still includes `pve`, `pvew`, and `pveso`.
- VM200 is running and should remain onboot=1.
- CT203 is running and should remain onboot=1.
- CT204 is stopped and should remain onboot=0.
- Private storage is locked/unmounted.
- Workers remain offline.
- No model, scheduler, worker, DB, storage, Cloudflare, or tunnel mutation is part of quorum work.

## Preferred durable path

Preferred path:

> Convert PVEW from a fragile quorum-dependent cluster member into a host that can boot and operate local VM200/CT203 without requiring PVESO or the old PVE node to be online.

This is preferred over QDevice because the current project direction wants PVESO parked/off unless compute/model work is explicitly needed.

## Candidate apply class

The future apply phase should be a tightly guarded PVEW-only cluster reshape/removal operation.

Candidate operation class:

1. Verify PVEW is reachable and currently quorate.
2. Verify `pve` and `pveso` are absent/offline from PVEW's corosync view.
3. Verify VM200, CT203, and CT204 configs are owned/visible from PVEW.
4. Verify no HA resources are configured for stale nodes.
5. Verify no replication jobs require stale nodes.
6. Verify no shared/private storage is mounted or required for the quorum operation.
7. Backup relevant Proxmox config/state files.
8. Remove stale cluster node records using the official Proxmox cluster tooling, if and only if the preflight confirms it is safe.
9. Verify PVEW can manage VM200/CT203 without stale quorum dependency.
10. Verify public website status.
11. Commit a post-apply documentation checkpoint.

## Commands that are not approved by this no-apply phase

This phase does not approve:

- `pvecm delnode`
- editing `/etc/pve/corosync.conf`
- editing `/etc/corosync/corosync.conf`
- removing `/etc/pve/nodes/*`
- rebooting PVEW
- starting/stopping/restarting VM200, CT203, or CT204
- changing onboot settings
- changing nginx/cloudflared
- changing Cloudflare/DNS/tunnel config
- unlocking/mounting private storage
- starting CT204
- activating workers/models/scheduler
- DB migration/import/restore

## Future apply approval phrase

A future mutation phase must require a separate explicit approval phrase, proposed as:

`APPROVE_PHASE_14J_NM_PVEW_QUORUM_STALE_NODE_REMOVAL_APPLY_NO_REBOOT_NO_GUEST_RESTART`

That future apply phrase should still exclude reboot and guest restarts. Reboot validation should be a separate later approval.

## Mandatory preflight for future apply

Before any stale-node removal:

- `pvecm status` must show PVEW quorate.
- `pvecm nodes` must show PVEW local and stale peers not active.
- `corosync-cfgtool -s` must show stale peers disconnected.
- `/etc/pve/nodes/pvew/qemu-server/200.conf` or equivalent VM200 config must exist.
- `/etc/pve/nodes/pvew/lxc/203.conf` or equivalent CT203 config must exist.
- CT204 must be stopped and onboot=0.
- Private storage must be not mounted.
- `/dev/mapper/apc_private_data` must be absent.
- HA resources must be absent or irrelevant.
- Replication jobs must be absent or irrelevant.
- Public `/system/status` must be HTTP 200 before apply.

## Rollback posture

Because Proxmox cluster mutation can be high-impact, the future apply must:

- create timestamped backups of relevant config files
- record exact pre-state
- stop immediately if unexpected nodes/resources are found
- not bundle reboot testing
- not bundle guest restarts
- not bundle CT203 addressing changes
- document the result immediately after apply

## Separate later work

After quorum durability is solved:

1. Stabilize CT203 addressing.
2. Decide whether to add `/api/system/status` compatibility.
3. Reboot-test PVEW autostart behavior under a separate approval.
4. Resume platform buildout only after PVEW can recover website path unattended.
