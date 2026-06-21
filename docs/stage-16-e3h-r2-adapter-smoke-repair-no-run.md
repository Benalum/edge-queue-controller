# Stage 16 E3H-R2 — Adapter Smoke Repair No-Run

Date: 2026-06-20

## Scope

Repo-only repair for the Stage 16 E3H smoke script.

## Reason

E3H committed successfully at `3a2d314`, but the generated smoke script was not trustworthy because the PPB output showed:

`DB: unbound variable`

That came from an unquoted heredoc while generating the smoke script. E3H-R2 rewrites the smoke script using a quoted heredoc and reruns the smoke.

## Files

- Adapter script retained:
  - `ops/model/pveso-one-shot-generate.sh`
- Smoke repaired:
  - `ops/smoke/check-stage-16-e3h-add-one-shot-model-adapter-script-no-run.sh`

## E3H-R2 validation

The repaired smoke verifies:

- Adapter file exists and is executable.
- Adapter passes `bash -n`.
- Adapter `--help` works.
- Adapter contains the E3I approval gate.
- Adapter contains localhost-only Ollama endpoint logic.
- Adapter contains CT101 and non-localhost listener guards.
- Adapter without approval exits at the approval gate before any model call.
- Public routes remain healthy.
- CT203 DB guard counts remain unchanged.
- PVESO Ollama remains active and localhost-only.
- CT101 remains stopped/onboot=0.

## Explicit non-actions

- No approved adapter execution.
- No prompt/completion/generate/chat/embed calls.
- No DB writes.
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

## Next recommended stage

Stage 16 E3I can run `ops/model/pveso-one-shot-generate.sh` once only after explicit approval:

`APPROVE_STAGE_16_E3I_RUN_ONE_SHOT_MODEL_ADAPTER_NO_DB_WRITE_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED`
