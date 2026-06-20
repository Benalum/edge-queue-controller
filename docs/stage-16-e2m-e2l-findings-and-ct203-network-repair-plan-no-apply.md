# Stage 16-E2M — E2L Findings and CT203 Network Repair Plan No-Apply

Date: 2026-06-20

## Purpose

Record the Stage 16-E2L CT101 start-readiness result, the safety rollback result, and the network blocker discovered afterward.

This is a **no-apply** document and smoke checkpoint. It does not mutate live infrastructure.

## Current Safe State After Rollback

After the E2L attempt and rollback:

- CT101 `llms`: stopped
- CT101 onboot: 0
- CT201: stopped
- CT202: stopped
- VM200: running
- CT203: running
- CT204: stopped
- CT203 controller service: active
- `EDGE_POWER_EXECUTE_WAKE=false`
- private storage: not mounted
- CT203 DB counts unchanged
- no scheduler activation
- no persistent worker enablement
- no intended worker registration
- no intended model job
- no intended Ollama/model endpoint call

## E2L Start-Readiness Result

CT101 did start and boot successfully.

Confirmed during E2L/E2L-R1:

- CT101 booted Ubuntu 24.04.3 LTS
- CT101 remained `onboot=0`
- `/mnt/ollama-models` mounted successfully from host `/mnt/ollama-storage`
- model storage under `/mnt/ollama-models` had:
  - 6 manifests
  - 27 blobs
  - 0 partial blobs
- CT101 network came up
- CT101 Docker/containerd came up

## E2L Safety Blocker

CT101 auto-started legacy runtime components that were outside the desired narrow readiness boundary.

Observed inside CT101:

- `app.worker.agent`
- `/opt/ai-platform/scripts/controller/local-queue-controller.sh`
- Docker/containerd active
- `ollama serve`
- listener on tcp/11434 through docker-proxy
- other legacy app/API processes

This means CT101 cannot be safely used for the next model-worker step until its legacy autostart/runtime behavior is neutralized or isolated behind a new explicit approval boundary.

## E2L Rollback Result

CT101 was cleanly shut down by `pct shutdown 101`.

After rollback:

- CT101 stopped
- CT101 still `onboot=0`
- CT201 remained stopped
- CT202 remained stopped
- no DB count changes were observed before/after rollback checks
- no further model/job/worker activation was approved

## Post-Rollback Inventory Blocker

After CT101 was stopped, CT203’s `/power/proxmox/inventory` endpoint still returned HTTP 502.

The error body showed the inventory SSH command failed with:

- returncode: 255
- stderr: SSH to configured PVESO LAN target failed with `No route to host`

## Network Split Diagnosis

Stage 16-E2L-R5 found:

- PVEW and PVESO are on one LAN/subnet.
- CT203 is on a different LAN/subnet.
- CT203’s configured `EDGE_PROXMOX_SSH_TARGET` points to an old/stale PVESO target in CT203’s subnet.
- PVESO’s current `vmbr0` address is not in CT203’s subnet.
- CT203 cannot reach either the stale target or the current PVESO `vmbr0` address on tcp/22.
- The stale configured target is in CT203’s network but not PVESO’s current network.

Conclusion:

- The current inventory failure is not because CT101 remains running.
- CT101 is stopped.
- The root cause is a network split plus stale CT203 PVESO SSH target.

## Repair Direction

The likely repair is to realign CT203 networking to the same LAN/subnet as PVEW, VM200, and PVESO, then update CT203’s PVESO inventory target to PVESO’s current reachable LAN address.

This is a real live-controller network mutation and must be handled separately.

## Required No-Apply Repair Plan Before Mutation

Before any CT203 network mutation, produce a separate no-apply plan that captures:

- current CT203 net0 config
- current VM200/PVEW/PVESO LAN pattern
- target CT203 static IP, gateway, and DNS
- rollback path through Proxmox console if SSH drops
- expected public route behavior during and after change
- exact post-change checks:
  - CT203 `/health`
  - CT203 `/system/status`
  - VM200 `/system/status`
  - VM200 `/api/system/status`
  - public `/system/status`
  - CT203 DB count guard
  - PVESO inventory endpoint HTTP 200
- hard stop if public route or CT203 health degrades

## Future Approval Boundaries

### CT203 network repair

A later mutation approval should be explicit and narrow, similar to:

`APPROVE_STAGE_16_E2N_REALIGN_CT203_NETWORK_TO_PVEW_PVESO_LAN_UPDATE_PVESO_SSH_TARGET_RESTART_CT203_NETWORK_ONLY`

That approval must still forbid:

- DB writes
- CT101 start
- worker registration
- model jobs
- scheduler activation
- Cloudflare/DNS/tunnel mutation
- CT204/private storage mutation

### CT101 legacy-autostart neutralization

Separately, before CT101 is started again for model readiness, create a no-apply plan to neutralize or quarantine legacy autostart behavior.

A later mutation approval should be separate from CT203 network repair and should forbid user traffic/model jobs until validated.

## Current Recommendation

Do not start CT101 again yet.

Next safest step:

**Stage 16-E2N — CT203 network realignment plan no-apply**

Only after that plan is reviewed should we perform the actual CT203 network mutation.
