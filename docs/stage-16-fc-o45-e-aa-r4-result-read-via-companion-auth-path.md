# Stage 16 FC-O45-E-AA-R4 — Companion result read through proven auth path

Date: 2026-06-24

## Result

Added a read-only result lookup mode to the already-proven signed-in Companion auth path:

`POST /api/companion/chat` with `X-APC-Companion-Result-Read-Only: FC-O45-E-AA`

The mode authenticates with `_auth_current_user_from_request(request)`, scopes lookup to the authenticated `user_id`, requires `job_type = 'companion.chat'`, and returns existing `job_results.response_text` without creating jobs.

## UI update

The Companion result visibility panel now probes the signed-in Companion auth path first.

## Cache-bust

`/app.js?v=20260624fc045eaar4`

## Guardrails

This phase did not create jobs, mutate the DB, mutate jobs, run workers, call models/helpers/runtime, activate scheduler/timer, change schema, restart CT/VMs, mutate nginx/cloudflared, or mutate storage.

Backend code was deployed to CT203 and `edge-queue-controller.service` was restarted under the approved scope. VM200 static UI was cache-busted under the approved scope.

## Verification

- Backend syntax check passed.
- CT203 service active.
- Public `/api/system/status`: HTTP 200.
- Signed-out `/api/me`: HTTP 401.
- Signed-out read-only Companion result mode preserved 401/403/404 class.
- Public root/app.js cache-busted and includes the read-only header.

## Manual proof step

Open Companion while signed in and click:

`Check Companion result for job 124`

Expected:

```text
PASS: completed Companion job 124 result is visible from signed-in UI.
```
