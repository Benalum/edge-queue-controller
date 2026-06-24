# Stage 16 FC-O45-E-AD-F-R2 — Fresh Companion submit bridge proof for job 126

Date: 2026-06-24

## Result

The normal signed-in Companion UI submit flow created fresh Companion job `126`, and the submit/result-reader bridge exposed the returned job id to the user-facing Companion result reader.

## Browser proof

User-facing Companion UI showed:

- User message: `say hello in 1 sentence`
- Queue message: `Job created`
- Returned job id displayed: `126`
- Assistant placeholder: `Your message is queued safely. The model worker is not active yet, so no assistant reply has been generated.`
- Detail: `job 126 - mock/no-model - waiting for model worker`
- Companion status: `Complete`
- Queue status: `Queued`

The Companion result reader then checked the same job id and displayed:

- `The job was found, but no result is available yet. HTTP 200.`

## CT203 read-only verification

Read-only CT203 DB verification confirmed job `126`:

- `user_id=16`
- `job_type=companion.chat`
- `requested_model=mock/no-model`
- `attempts=0`
- `prompt=say hello in 1 sentence`
- `result_rows=0`

## What this proves

- The normal Companion submit path still creates a fresh queued Companion job through `/api/chat/queued`.
- The returned job id is visible in the UI.
- The result reader bridge can target the returned job id.
- The result reader can check that job without creating another job.
- The job remains uncompleted because this proof did not approve completion.
- No result row was inserted.

## Guardrails

This phase did not write the DB, mutate jobs, insert result rows, complete the job, patch backend/frontend runtime files, deploy, restart services, call workers/models/helpers/runtime/Ollama, activate scheduler/timer/persistent workers, change schema, restart CT/VMs, mutate nginx/cloudflared, or mutate storage.

## Current expected state after proof

Job `126` should remain queued with zero result rows until a separately approved completion or worker proof is performed.

## Next recommended milestone

Approve a bounded no-model/mock completion for exactly job `126`, then use the result reader bridge to read the returned job id result from the normal submit flow.
