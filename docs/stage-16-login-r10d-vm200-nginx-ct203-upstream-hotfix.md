# Stage 16 Login R10D — VM200 nginx CT203 Upstream Hotfix

Date: 2026-06-20  
Scope: public login/API timeout recovery after CT203 network/upstream drift.

## Summary

The public website static wrapper was reachable, but public API/auth routes were timing out through the platform gateway:

- `/` returned HTTP 200.
- `/login` returned HTTP 200.
- `/api/me` timed out.
- `/api/system/status` timed out.
- `/system/status` timed out.
- `/api/auth/login` timed out.

CT203 itself was healthy throughout the incident:

- CT203 controller active.
- CT203 `/health` returned HTTP 200.
- CT203 `/system/status` returned HTTP 200.
- CT203 `/public/me` returned HTTP 401.
- CT203 `/public/auth/login` returned HTTP 405.

## Root Cause

VM200 nginx APC proxy snippets were still pointing at a CT203 upstream address that VM200 could not reach after the network repair / CT203 address changes.

A VM200-to-CT203 endpoint matrix showed:

- Candidate 1 from CT203 address list: unreachable from VM200.
- Candidate 2 from CT203 address list:
  - `/health` HTTP 200
  - `/system/status` HTTP 200
  - `/public/me` HTTP 401
  - `/public/auth/login` HTTP 405
  - `/jobs` HTTP 200

## Applied Fix

R10D selected the CT203 candidate that passed both:

- `/system/status` = HTTP 200
- `/public/me` = HTTP 401

Then VM200 patched these APC nginx snippets:

- `/etc/nginx/snippets/apc-ct203-api-compat-locations.conf`
- `/etc/nginx/snippets/apc-ct203-api-bridge-locations.conf`

Backups were created before edit:

- `apc-ct203-api-compat-locations.conf.bak-r10d-login-fix-20260621T014706Z`
- `apc-ct203-api-bridge-locations.conf.bak-r10d-login-fix-20260621T014706Z`

Nginx syntax test passed and only nginx was reloaded.

No Cloudflare, DNS, tunnel, CT203 controller, DB, worker, model, scheduler, CT101, or private-storage mutation was performed.

## R10D Local VM200 Validation

After the nginx reload:

- VM200 local `/` on `127.0.0.1:18080` returned HTTP 200.
- VM200 local `/login` on `127.0.0.1:18080` returned HTTP 200.
- VM200 local `/system/status` returned HTTP 200.
- VM200 local `/api/me` returned HTTP 401.
- VM200 local `/api/auth/login` returned HTTP 405.

During R10D, VM200 local `/api/system/status` still showed a timeout immediately after reload, but the later public validation showed this route was healthy publicly.

## R10E Public Validation

After R10D:

- Public `/` returned HTTP 200.
- Public `/login` returned HTTP 200.
- Public `/api/me` returned HTTP 401 with `Missing bearer token`.
- Public `/api/auth/login` returned HTTP 405.
- Public `/system/status` returned HTTP 200.
- Public `/api/system/status` returned HTTP 200.
- Public `/api/jobs` returned HTTP 404, which is not a login blocker.

The user confirmed they could log in after the hotfix.

## Safety Guard Results

- VM200 remained running.
- CT203 remained running.
- CT204 remained stopped.
- Private storage remained not mounted.
- CT203 controller remained active.
- CT203 DB guard counts were checked.
- `user_sessions` increased from the older 235 baseline to 236 after the user successfully logged in. This is expected user activity, not a smoke-induced DB write.
- The smoke for this checkpoint uses a dynamic before/after DB guard rather than a stale hard-coded `user_sessions` count.

## Current State

Login gateway timeout is resolved.

CT101/E2X remains paused and can be resumed after this hotfix is committed/tagged.

## Next Step

Resume:

`APPROVE_STAGE_16_E2X_CT101_OFFLINE_LEGACY_AUTOSTART_NEUTRALIZATION_NO_CT_START_NO_DB_WRITE_NO_MODEL_CALL`

with the existing Stage 16 safety posture:

- keep CT101 stopped,
- no model endpoint calls,
- no DB writes,
- no scheduler activation,
- no worker activation,
- no public routing changes.
