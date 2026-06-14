# Phase 12R-AF Guarded Restart Live Authenticated Admin Warmup Preview Verification

Phase 12R-AF performs a guarded controller-only restart so the running FastAPI service loads Phase 12R-AE.

## Purpose

Phase 12R-AE enriched the disabled authenticated admin warmup refusal with:

- `future_warmup_execution_preview`

Phase 12R-AF verifies the live service returns that preview for a valid admin request.

## Allowed runtime action

This phase may restart only:

- `edge-queue-controller`

## Local-only token handling

The stage script prompts for the admin bearer token locally using a silent prompt.

The token must not be:

- Printed.
- Written to a file.
- Committed.
- Passed to curl on the command line.
- Shared with ChatGPT.

The token is used only inside a local Python process.

## Safety

This phase must not:

- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Call Ollama directly.
- Call `/api/generate`.
- Call `/api/chat`.
- Warm any model.
- Unload any model.

## Expected authenticated behavior

`POST /admin/model-warmup` with a valid admin bearer token must return HTTP 403.

The response detail must still be disabled and must include:

- `future_warmup_execution_preview.runtime_action_available: false`
- `future_warmup_execution_preview.would_call: none`
- `future_warmup_execution_preview.future_ollama_request.execute_now: false`
- `future_warmup_execution_preview.reason: runtime_action_unavailable`
