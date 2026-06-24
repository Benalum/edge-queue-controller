# Stage 16 FC-O45-E-AD-G-R2 — End-to-end Companion submit/result-reader proof for job 126

Date: 2026-06-24

## Result

The normal signed-in Companion submit flow is now proven end-to-end through the user-facing result reader.

## Proven browser flow

1. User sent a normal Companion message:
   - `say hello in 1 sentence`
2. The Companion UI created queued job `126`.
3. The submit/result-reader bridge exposed returned job id `126`.
4. Before completion, the result reader showed:
   - `The job was found, but no result is available yet. HTTP 200.`
5. After separately approved bounded completion, the result reader showed:
   - `PASS: Companion result read path returned a result.`
   - `job_id: 126`
   - `status: completed`
   - `job_type: companion.chat`
   - `requested_model: mock/no-model`
   - `queue_write: false`
   - `Hello! I am here and ready to help.`

## CT203 read-only verification

Final CT203 verification confirmed job `126`:

- `user_id=16`
- `job_type=companion.chat`
- `status=completed`
- `attempts=0`
- `requested_model=mock/no-model`
- `prompt=say hello in 1 sentence`
- exactly one result row
- result model: `mock/no-model`
- result text: `Hello! I am here and ready to help.`
- result proof: `FC-O45-E-AD-G`
- no real model call
- no worker call
- no scheduler activation

## Guardrails

This proof-record phase is read-only against CT203 and repo-only for documentation. It did not write the DB, mutate jobs, insert result rows, patch backend/frontend runtime files, deploy, restart services, call workers/models/helpers/runtime/Ollama, activate scheduler/timer/persistent workers, change schema, restart CT/VMs, mutate nginx/cloudflared, or mutate storage.

## Current milestone status

The Companion normal submit flow now has a proven product path:

- signed-in submit creates a queued Companion job
- returned job id is surfaced to the user
- result reader can check that returned job id
- bounded mock/no-model completion can be read back through the same UI
- the read path does not create another job
