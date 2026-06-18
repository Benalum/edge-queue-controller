# Phase 14J-KM — Repaired public/platform baseline

Date: 2026-06-18

## Scope

This checkpoint records a read-only public/platform baseline after the Phase 14J-KK login compatibility repair and Phase 14J-KL post-login auth/session audit.

## Repository baseline

- Local HEAD matched expected checkpoint: `2d647d8`.
- Origin main matched expected checkpoint: `2d647d8`.
- Git working tree was clean.

## PVEW platform baseline

- VM200 status: running.
- CT203 status: running.
- CT204 status: stopped.

## CT203 controller checks

- `edge-queue-controller.service` is active.
- `edge-queue-controller.service` is enabled.
- CT203 SQLite DB integrity check returned `ok`.
- Admin `last_login_at` remained `2026-06-18T18:26:19.696937+00:00`.

## Public route smoke

The following public route checks passed:

- `GET /` returned 200.
- `GET /login` returned 200.
- `GET /profile` returned 200.
- `GET /admin` returned 200.
- `GET /public/status` returned 200.
- `POST /api/auth/login` returned expected 400 for empty input.
- `GET /api/me` returned expected 401 without bearer token.
- `GET /api/account/credits` returned expected 401 without bearer token.

## Current posture

The public site is reachable, admin login is repaired, and the PVEW-contained controller path is functioning. VM200 remains public edge/static/nginx/cloudflared. CT203 remains controller/API/queue candidate with boot persistence enabled. CT204 remains data/backups only and is not live data authority.
