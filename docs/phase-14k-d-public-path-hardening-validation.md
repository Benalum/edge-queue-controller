# Phase 14K-D — Public Path Hardening Validation

Date: 2026-06-19  
Base checkpoint: Phase 14K-B / HEAD `0439a3c`  
Mutation scope: read-only infrastructure validation plus repo docs/smoke checkpoint

## Summary

Phase 14K-C applied the approved VM200 -> CT203 public-path hardening.

Validated outcome:

- CT203 is no longer DHCP in Proxmox/LXC config.
- CT203 `net0` is static and includes a gateway.
- CT203 remained running.
- VM200 remained running.
- CT204 remained stopped.
- Private storage remained locked/unmounted.
- CT203 direct `/system/status` remained healthy.
- VM200 local wrapper route `/system/status` is healthy on `127.0.0.1:18080`.
- VM200 local wrapper route `/api/system/status` is healthy on `127.0.0.1:18080`.
- Public `/system/status` remained healthy.
- Public `/api/system/status` is now healthy and returns platform status JSON.
- Public `/api/me` remains HTTP 401 unauthenticated, expected.

## Public route validation

Expected and validated:

- `/` -> HTTP 200.
- `/system/status` -> HTTP 200.
- `/api/system/status` -> HTTP 200.
- `/api/me` -> HTTP 401 unauthenticated.

The public `/api/system/status` route now returns platform status JSON with overall state `online` and node entries including PVEW, VM200, CT203, and CT204.

## VM200 route-map note

The active local wrapper route is `127.0.0.1:18080`.

Validated on VM200:

- `127.0.0.1:18080/healthz` -> HTTP 200.
- `127.0.0.1:18080/system/status` -> HTTP 200.
- `127.0.0.1:18080/api/system/status` -> HTTP 200.
- `127.0.0.1:18080/api/me` -> HTTP 401.

Local port 80 on VM200 is not the route used for the wrapper validation and may return default-site 404 responses. That is not treated as the public wrapper path.

## Infrastructure validation

Validated:

- PVEW is quorate.
- PVEW expected votes: 1.
- PVEW total votes: 1.
- CT203 config is static, not `ip=dhcp`.
- CT203 config includes `gw=...`.
- CT203 direct `/system/status` returns HTTP 200.
- VM200 nginx is active and config test passes.
- VM200 cloudflared is active.
- VM200 compatibility snippet contains `location = /api/system/status`.
- CT204 is stopped and remains non-authority.
- `/srv/apc-private-data` is not mounted.
- `/dev/mapper/apc_private_data` is absent.

## Notes

During 14K-C apply, Proxmox reported `Address already assigned` while applying CT203 static net0 because the running container already had the current DHCP address on `eth0`. The config mutation still succeeded, CT203 remained reachable, and post-apply validation showed the LXC config now contains static `ip=.../24` and `gw=...`.

No CT203 restart was performed.

## Safety exclusions preserved

No changes were made to:

- PVEW reboot/shutdown state.
- PVESO.
- CT204 start/authority.
- Private storage unlock/mount.
- Cloudflare/DNS/tunnel config.
- DB migration/import/restore.
- Worker/model/scheduler activation.
- Live model endpoint calls.
- Proxmox cluster/corosync config.

## Result

Phase 14K public-path hardening is validated.

The platform can proceed to a final 14K-E checkpoint/source refresh, then resume feature work in the recommended order:

1. Controller/queue/Decision Maker integration.
2. Ollama/model worker re-entry.
3. Study/Flashcards durable flow.
4. Companion queued flow.
5. Speaking/listening only after text features are stable.
