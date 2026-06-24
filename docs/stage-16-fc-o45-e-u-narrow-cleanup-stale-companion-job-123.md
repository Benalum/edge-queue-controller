# Stage 16 FC-O45-E-U — Narrow DB cleanup for stale Companion job 123

Date: 2026-06-24

## Result

Stale queued Companion test job `123` was cleaned up by marking exactly that job as `failed`.

The cleanup was intentionally narrow:

- Verified job id: `123`
- Required pre-cleanup status: `queued`
- Required job_type: `companion.chat`
- Required requested_model: `mock/no-model`
- Required attempts: `0`
- Row deletion: none
- Schema change: none

A sqlite backup was created before mutation under the controller DB directory for this phase.

## Guardrails

This phase did not run workers, models, helpers, runtime calls, scheduler/timer activation, service restarts, deploys, CT/VM restarts, nginx/cloudflared changes, or storage mutations.

## Public verification

After cleanup:

- Public `/api/system/status`: HTTP 200
- Signed-out `/api/me`: HTTP 401
- Signed-out `/api/companion/chat`: HTTP 401

## Prior proof preserved

FC-O45-E-T recorded the signed-in Companion UI result:

```text
PASS: signed-in Companion auth validated; queue_write=false.
```

## Next recommended step

Continue from signed-in no-enqueue Companion auth proof to a controlled Companion enqueue proof that does not activate a model/worker until explicitly approved.
