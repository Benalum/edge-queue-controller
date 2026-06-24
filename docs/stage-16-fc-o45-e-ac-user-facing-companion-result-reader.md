# Stage 16 FC-O45-E-AC — User-facing Companion result reader

Date: 2026-06-24

## Result

Added a user-facing signed-in Companion result reader panel.

The panel lets the signed-in user enter a Companion job id and read the completed result through the existing read-only, owner-scoped Companion result path.

## Behavior

- UI title: Companion result reader
- Input: job id
- Button: Read result
- Endpoint used: `POST /api/companion/chat`
- Read-only header: `X-APC-Companion-Result-Read-Only: FC-O45-E-AA`
- Cache-bust: `20260624fc045eac`

## Guardrails

This phase did not create jobs, mutate jobs, insert result rows, patch backend code, restart backend services, run models, call workers/helpers/runtime/Ollama, activate scheduler/timer/persistent workers, change schema, restart CT/VMs, mutate nginx/cloudflared, or mutate storage.

## Next recommended proof

Hard refresh Companion, enter job id `125`, click `Read result`, and confirm the panel displays:

`FC-O45-E-AB completed mock no-model result for Companion job 125.`
