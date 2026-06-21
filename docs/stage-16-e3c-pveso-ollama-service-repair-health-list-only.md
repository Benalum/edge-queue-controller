# Stage 16 E3C — PVESO Ollama Service Repair Health/List Only

Date: 2026-06-20

## Scope

PVESO host Ollama service bind repair and health/list validation only.

## Approval

`APPROVE_STAGE_16_E3C_PVESO_OLLAMA_SERVICE_REPAIR_START_HEALTH_LIST_ONLY_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_DB_WRITE_NO_MODEL_PULL`

## Changes

- Added late-loading PVESO systemd drop-in:
  - `/etc/systemd/system/ollama.service.d/zz-apc-stage16-e3c-bind-localhost.conf`
- Set effective `OLLAMA_HOST=127.0.0.1:11434`.
- Preserved expected runtime env:
  - `OLLAMA_MODELS=/var/lib/vz/ollama/models`
  - `OLLAMA_NUM_THREADS=20`
  - `OLLAMA_NUM_PARALLEL=1`
- Ran `systemctl daemon-reload`.
- Ran `systemctl reset-failed ollama.service`.
- Ran `systemctl restart ollama.service`.

## Validation

- PVESO `ollama.service` active after repair.
- `11434` listener bound to localhost only.
- Non-localhost `11434` listener count: 0.
- Allowed endpoint calls completed:
  - `GET /api/version`
  - `GET /api/tags`
- Ollama API version observed: `0.15.4`
- Ollama tag/model count observed: `2`

## Explicit non-actions

- No prompt/completion/generate/chat/embed calls.
- No model pull/download.
- No worker activation.
- No scheduler activation.
- No DB writes.
- No CT101 start.
- No CT/VM start/stop/restart.
- No private storage mount/unlock.
- No Cloudflare/DNS/tunnel/nginx mutation.
- No CT203 service restart/reload/env mutation.
- No public model endpoint exposure.

## Guards preserved

- Public login/API routes remained healthy after E3C.
- CT203 DB guard counts remained unchanged:
  - `user_sessions=236`
  - `jobs=23`
  - `job_results=6`
  - `router_logs=0`
  - `router_resolution_steps=0`
  - `router_feedback=0`
  - `workers=2`
  - `worker_events=3`
- CT101 remained stopped/onboot=0 on PVESO.

## Next recommended stage

Stage 16 E3D should remain no-worker/no-scheduler by default and should decide the next safe model inventory/manifests step before any prompt smoke or queue-to-model activation.
