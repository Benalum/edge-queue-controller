# Stage 16 FC-O45-E-AD-E-R2 — Companion submit returned job id result-reader bridge

Date: 2026-06-24

## Result

Added a frontend-only bridge from normal Companion queued submit to the user-facing Companion result reader.

When `queuedChatSubmit` receives a returned job id from `/api/chat/queued`, the UI now stores that job id and auto-fills the Companion result reader panel.

## Behavior

- Existing submit path remains `POST /api/chat/queued`.
- Existing polling path remains unchanged.
- Existing result reader path remains `POST /api/companion/chat` with `X-APC-Companion-Result-Read-Only: FC-O45-E-AA`.
- Bridge marker: `APC_COMPANION_SUBMIT_RESULT_READER_BRIDGE_FC_O45_E_AD_E_R2`
- Cache-bust: `20260624fc045eader2`

## User-visible flow

1. Send a Companion message.
2. The queue response returns a job id.
3. The result reader panel automatically shows the latest submitted Companion job id.
4. Clicking `Read result` checks the job without creating another job.

## Guardrails

This phase did not write the DB, mutate jobs, insert result rows, patch backend code, restart backend services, run models, call workers/helpers/runtime/Ollama, activate scheduler/timer/persistent workers, change schema, restart CT/VMs, mutate nginx/cloudflared, or mutate storage.
