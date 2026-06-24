# Stage 16 FC-O45-E-AA-R3 — Authenticated read-only Companion result endpoint

Date: 2026-06-24

## Result

Added and recovered the narrow signed-in GET endpoint for completed Companion job result visibility:

`GET /api/companion/jobs/{job_id}/result`

The endpoint uses `_auth_current_user_from_request(request)`, scopes the lookup to the authenticated `user_id`, requires `job_type = 'companion.chat'`, and returns the existing `job_results.response_text`.

## UI update

The Companion result visibility panel now probes:

`/api/companion/jobs/124/result`

before older generic job paths.

## Cache-bust

`/app.js?v=20260624fc045eaa`

## Guardrails

This phase did not create jobs, mutate the DB, mutate jobs, run workers, call models/helpers/runtime, activate scheduler/timer, change schema, restart CT/VMs, mutate nginx/cloudflared, or mutate storage.

The earlier R1 run deployed the backend patch and restarted `edge-queue-controller.service`. R3 verified the live backend marker, then used a small in-place VM200 static patch/cache-bust instead of pushing the full app bundle.

## Verification

- Backend syntax check passed.
- CT203 service active.
- Live CT203 backend marker present.
- Public `/api/system/status`: HTTP 200.
- Public signed-out `/api/me`: HTTP 401.
- Public signed-out result endpoint preserved 401/403/404 class.
- Public app.js cache-busted: HTTP 200.
- Public root references `20260624fc045eaa`.
- Public app.js contains `/api/companion/jobs/124/result`.

## Manual proof step

Open Companion while signed in and click:

`Check Companion result for job 124`

Expected:

```text
PASS: completed Companion job 124 result is visible from signed-in UI.
```
