# Stage 16 E2X — CT101 Offline Legacy Autostart Neutralization

Date: 2026-06-20  
Scope: PVESO CT101 stopped-rootfs legacy autostart neutralization.

## Purpose

Prepare CT101 for a future controlled start/readiness inspection by neutralizing legacy services that previously auto-started unsafe or out-of-authority runtime components.

This was required because an earlier CT101 start/readiness inspection showed legacy services starting automatically, including old worker/controller/model-related processes. Those services could hijack ports, register old workers, touch job paths, or confuse the current CT203 authority model.

## Approved Boundary

Approval:

`APPROVE_STAGE_16_E2X_CT101_OFFLINE_LEGACY_AUTOSTART_NEUTRALIZATION_NO_CT_START_NO_DB_WRITE_NO_MODEL_CALL`

Allowed:

- Verify CT101 is stopped.
- Verify CT101 `onboot=0`.
- Mount CT101 rootfs while stopped.
- Back up existing CT101 systemd unit entries.
- Mask legacy CT101 systemd units offline.
- Unmount CT101 rootfs.
- Confirm CT101 remains stopped.

Explicitly forbidden:

- No CT101 start.
- No CT201/CT202 mutation.
- No VM mutation.
- No CT203 controller restart or environment mutation.
- No nginx/cloudflared/Cloudflare/DNS/tunnel mutation.
- No DB write.
- No worker activation.
- No scheduler activation.
- No model/Ollama endpoint calls.
- No private-storage mount/unlock.

## Preflight State

Before E2X:

- VM200 running.
- CT203 running.
- CT204 stopped.
- Private storage not mounted.
- CT203 controller active.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 DB guard counts unchanged:
  - `user_sessions=236`
  - `jobs=23`
  - `job_results=6`
  - `router_logs=0`
  - `router_resolution_steps=0`
  - `router_feedback=0`
  - `workers=2`
  - `worker_events=3`

PVESO container posture before E2X:

- CT101 stopped.
- CT201 stopped.
- CT202 stopped.
- CT101 `onboot=0`.

## Applied Offline Neutralization

CT101 rootfs was mounted while CT101 was stopped.

A backup/manifest directory was created on PVESO under the Stage 16 E2X backup root.

A manifest was written for the offline operation.

Masked unit count: 11  
Already masked unit count: 0  
Backed-up existing unit count: 6  
Skipped unit count: 0

The following CT101 systemd units were masked offline:

- `ai-platform-edge-heartbeat.service`
- `ai-platform-edge-heartbeat.timer`
- `ai-platform-laptop-queue-worker.service`
- `ai-platform-laptop-queue-worker@.service`
- `ai-platform-queue-controller.service`
- `containerd.service`
- `docker.service`
- `docker.socket`
- `llm-stack-compose.service`
- `ollama.service`
- `ollama.socket`

Mandatory mask verification passed for:

- `docker.service`
- `docker.socket`
- `containerd.service`
- `ollama.service`
- `ollama.socket`

## Post-State

After E2X:

- CT101 rootfs was unmounted.
- CT101 remained stopped.
- CT101 remained `onboot=0`.
- CT201 remained stopped.
- CT202 remained stopped.
- VM200 remained running.
- CT203 remained running.
- CT204 remained stopped.
- Private storage remained not mounted.
- CT203 controller remained active.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 DB guard counts remained unchanged:
  - `user_sessions=236`
  - `jobs=23`
  - `job_results=6`
  - `router_logs=0`
  - `router_resolution_steps=0`
  - `router_feedback=0`
  - `workers=2`
  - `worker_events=3`

## Safety Result

E2X completed successfully.

The major legacy autostart risk inside CT101 is now neutralized before any future CT101 start.

## Remaining Risk

E2X does not prove CT101 can start cleanly. It only neutralizes known legacy autostart sources offline.

A future CT101 start/readiness inspection must still be separately approved and must verify:

- no Docker/containerd service activation,
- no old Ollama service activation,
- no old queue/controller/worker service activation,
- no old uvicorn/Whisper/Kokoro services,
- no docker-proxy on 11434,
- no scheduler activation,
- no DB writes,
- no model calls.

## Next Step

Prepare and run a separate controlled CT101 start/readiness inspection approval.

Recommended next approval phrase:

`APPROVE_STAGE_16_E2Y_CONTROLLED_CT101_START_READINESS_INSPECTION_NO_DB_WRITE_NO_MODEL_CALL_NO_WORKER_SCHEDULER_ACTIVATION`

The inspection should start CT101 temporarily for diagnostics only, verify legacy services are inactive/masked, inspect model/runtime readiness, and shut CT101 back down or leave it stopped unless a later approval changes its role.
