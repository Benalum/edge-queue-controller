# Phase 14J-KL — Post-login auth/session audit

Date: 2026-06-18

## Scope

This checkpoint records the read-only post-login audit after the Phase 14J-KK VM200 API compatibility auth bridge fix.

## Result

Admin login now works through the public website.

## Verified CT203 state

- `edge-queue-controller.service` is active.
- `edge-queue-controller.service` is enabled.
- CT203 SQLite DB integrity check returned `ok`.
- Admin account exists in CT203:
  - email: `alexhartel179@gmail.com`
  - status: `active`
  - role: `admin`
  - plan: `pro`
  - billing status: `active`
- Admin `last_login_at` updated to `2026-06-18T18:26:19.696937+00:00`.
- Latest admin session row observed:
  - session id: `260`
  - user id: `16`
  - created at: `2026-06-18T18:26:19.704968+00:00`
  - expires at: `2026-07-18T18:26:19.704968+00:00`

No token hashes or password hashes were printed.

## Verified public route smoke

- `POST /api/auth/login` returns expected validation response for empty input.
- `GET /api/me` returns expected 401 without bearer token.
- `GET /api/account/me` returns expected 401 without bearer token.
- `GET /api/account/credits` returns expected 401 without bearer token.
- `GET /public/status` returns 200.
- `GET /` returns 200.
- `GET /profile` returns 200.
- `GET /admin` returns 200.

## Current posture

The public login path is repaired. VM200 remains public edge/static/nginx/cloudflared. CT203 remains the controller/API/queue candidate with boot persistence enabled. CT204 remains data/backups only and is not live data authority.
