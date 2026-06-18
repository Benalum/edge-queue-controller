# Phase 14J-KK — VM200 API compatibility auth bridge apply

Date: 2026-06-18

## Scope

This checkpoint records the approved VM200 nginx compatibility bridge that restored wrapper login against the CT203 controller backend.

## Approval

APPROVE_PHASE_14J_KK_VM200_API_COMPAT_AUTH_BRIDGE_NGINX_RELOAD_NO_DB_NO_CT203_SERVICE_MUTATION_NO_CLOUDFLARE

## Problem

The public wrapper frontend uses `API_BASE = "/api"` and submits login through `/api/auth/login`.

After moving the controller backend to CT203, CT203 exposed working auth endpoints under `/public/auth/*` and `/system/session/*`, but `/api/auth/login` returned 404. This prevented admin login even though the admin account existed in the CT203 SQLite DB.

## Applied mutation

Only VM200 nginx compatibility routing was changed.

A new nginx snippet was added:

- `/etc/nginx/snippets/apc-ct203-api-compat-locations.conf`

It is included before the generic CT203 `/api/` bridge in:

- `/etc/nginx/sites-enabled/apc-wrapper-local.conf`

The compatibility aliases map legacy wrapper paths to CT203 backend paths:

- `/api/auth/*` → `/public/auth/*`
- `/api/me` → `/public/me`
- `/api/account/*` → `/system/account/*`
- `/api/credits/*` → `/system/credits/*`
- `/api/gpu/*` → `/system/gpu/*`
- `/api/support/*` → `/system/support/*`

Nginx was syntax-tested, reloaded, and syntax-tested again.

## Explicitly not changed

- No DB mutation.
- No CT203 service restart/reload.
- No Cloudflare, DNS, or tunnel mutation.
- No CT204 start.
- No PVESO wake.

## Verified result

- `/api/auth/login` now reaches the backend and returns expected validation response for empty input.
- `/api/me` reaches the backend and returns expected 401 without bearer token.
- `/api/account/me` reaches the backend and returns expected 401 without bearer token.
- `/api/account/credits` reaches the backend and returns expected 401 without bearer token.
- `/public/status` still returns 200.
- `/` still returns 200.
- Browser admin login now works.

## Current posture

VM200 remains public edge/static/nginx/cloudflared. CT203 remains controller/API/queue candidate with boot persistence enabled. CT204 remains data/backups only and is not live data authority.
