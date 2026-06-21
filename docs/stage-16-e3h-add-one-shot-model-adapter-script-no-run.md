# Stage 16 E3H — Add One-Shot Model Adapter Script No-Run

Date: 2026-06-20

## Scope

Add a repo-local one-shot PVESO model adapter script without executing it.

## Script

- `ops/model/pveso-one-shot-generate.sh`

## Safety posture

The script is intentionally gated and will not execute a model call unless this environment variable is set:

`APC_ONE_SHOT_MODEL_APPROVAL=APPROVE_STAGE_16_E3I_RUN_ONE_SHOT_MODEL_ADAPTER_NO_DB_WRITE_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED`

## What the script is designed to do later

When explicitly approved in a later stage, the script will:

1. Discover PVESO through `tailscale status`.
2. SSH to PVESO.
3. Require CT101 stopped/onboot=0.
4. Require PVESO Ollama active and bound to `127.0.0.1:11434`.
5. Require no non-localhost `11434` listener.
6. Verify `/api/version` and `/api/tags`.
7. Verify the target model is present.
8. Make one local-only `/api/generate` call.
9. Capture response JSON.
10. Print structured results.

## Explicit non-actions in E3H

- The adapter was not executed.
- No prompt/completion/generate/chat/embed calls.
- No DB writes.
- No worker registration mutation.
- No worker activation.
- No scheduler activation.
- No model pull/download.
- No CT101 start.
- No CT/VM start/stop/restart.
- No service restart/reload/start/stop.
- No private storage mount/unlock.
- No Cloudflare/DNS/tunnel/nginx mutation.
- No CT203 service restart/reload/env mutation.
- No public model endpoint exposure.

## Guards preserved

- Public login/API routes remained healthy.
- CT203 DB guard counts remained unchanged.
- PVESO Ollama remained active and localhost-only.
- CT101 remained stopped/onboot=0.

## Next recommended stage

Stage 16 E3I should require explicit approval to run `ops/model/pveso-one-shot-generate.sh` once. E3I should preserve CT203/public/CT101 guards before and after and should not write to the DB or activate scheduler/persistent workers.
