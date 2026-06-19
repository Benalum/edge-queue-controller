# Phase 14J-NH — PVEW Quorum and CT203 Upstream Durable Root-Cause Review

Date: 2026-06-19  
Scope: no-apply documentation checkpoint after live public-site recovery.

## Status

The public website path was restored after two bounded live fixes:

1. PVEW was temporarily made quorate with `pvecm expected 1` after Proxmox refused guest starts with `cluster not ready - no quorum?`.
2. VM200 nginx CT203 upstream snippets were patched from a stale CT203 DHCP address to CT203's current address, then nginx was reloaded after `nginx -t` passed.

Current restored state from terminal evidence:

- PVEW is online and temporarily quorate.
- VM200 `website-edge` is running.
- CT203 `edge-controller-pvew` is running.
- CT204 `edge-data-pvew` remains stopped.
- Private storage remains locked/unmounted.
- VM200 `cloudflared.service` is active/enabled.
- VM200 `nginx.service` is active/enabled.
- CT203 `edge-queue-controller.service` is active/enabled and listening on port 7070.
- Public `/system/status` returns HTTP 200 with schema version 2.
- Public app hash is `afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d`.
- Stale public copy text `laptop controller-owned` remains absent.

## Confirmed root-cause chain

The outage chain was:

```text
PVESO shut down
→ PVEW was alone in a Proxmox cluster that still expected three votes
→ PVEW lacked quorum
→ Proxmox refused guest start operations
→ CT203 and VM200 did not start at boot
→ VM200 cloudflared was down
→ Cloudflare returned 530 / 1033
→ after temporary quorum and guest start, VM200 nginx still pointed at a stale CT203 DHCP address
→ public API/status paths timed out
→ nginx upstream patch + nginx reload restored public statusRun with Project Pilot
Running...
Durable blocker 1: quorum design

Read-only review found:

Cluster name: ClusterOfThings.
Current active membership: PVEW only.
Corosync config still lists three nodes:
pve
pvew
pveso
PVEW boot logs show pve-guests.service waited for quorum before starting guests.
Once quorum was available, pve-guests.service proceeded to start VM200.
Therefore VM200/CT203 autostart is not the primary root cause; missing quorum is.

The current pvecm expected 1 state is a temporary recovery condition, not the desired durable architecture.

Durable quorum options

Option A — make PVEW standalone / remove stale cluster dependency:

Best aligned with target architecture where PVEW is always-on platform host and PVESO can be off/parked.
Needs careful Proxmox cluster removal/reshape planning.
Must not be done blindly.

Option B — keep a cluster and add a QDevice/witness:

Best if PVEW and PVESO remain a real two-node Proxmox cluster.
Requires a reliable third witness that is not in the same failure path.
The laptop should not become the long-term live authority path unless explicitly accepted.

Option C — keep PVESO online for quorum:

Simplest technically, but conflicts with the current target of allowing PVESO to be off/parked when not needed.

Option D — rely on repeated pvecm expected 1:

Not acceptable as a durable production posture.
May be used only as a bounded recovery tool or to fix quorum configuration.
Durable blocker 2: CT203 addressing

Read-only review found:

CT203 is configured with DHCP on net0.
VM200 nginx active snippets now point to CT203's current address.
Backups retain the old stale address, as expected.
Active upstream mismatch count is zero.
Public status is healthy now.

This is still fragile because a future DHCP address change can break VM200 nginx again.

Durable addressing options

Option A — DHCP reservation for CT203:

Preferable if the gateway/router can reserve CT203's MAC to the desired address.
Avoids editing CT203 network config.
Must be verified after CT203 restart.

Option B — static CT203 IP in Proxmox/LXC config:

Stronger platform control.
Requires explicit network mutation and careful gateway/subnet validation.
Should be done only after choosing the final LAN/subnet layout.

Option C — hostname-based upstream:

Useful only if VM200 can reliably resolve CT203's hostname.
Requires resolver/hosts strategy and nginx reload.
Avoids raw IP drift but adds name-resolution dependency.
Secondary compatibility issue

Public /system/status works.

Public /api/system/status currently returns 404. This is not blocking the restored public status panel if the frontend uses /system/status, but it should be cleaned up later if any frontend code still calls /api/system/status.

Recommended next sequence
Keep the current live recovery state stable.
Do not proceed to PVESO worker/model readiness yet.
First choose and apply durable quorum architecture:
preferred: PVEW can boot and manage VM200/CT203 without PVESO being online.
Stabilize CT203 addressing before relying on VM200 nginx upstream long-term.
Then verify PVEW reboot behavior:
PVEW boots.
quorum is available or no longer needed.
CT203 autostarts.
VM200 autostarts.
CT204 remains stopped.
private storage remains locked/unmounted.
public site and /system/status recover without manual intervention.
Safety invariants retained
CT204 remains backup-data-only and stopped.
Private storage remains manual-unlock-only.
No worker/model/scheduler activation occurred.
No DB restore/import/migration occurred.
No Cloudflare/DNS/tunnel config mutation occurred.

No PVESO mutation occurred during public-site recovery.
