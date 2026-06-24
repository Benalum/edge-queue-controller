# Stage 16 FC-O45-E-S — Companion UI Auth Validation Test

Date: 2026-06-24  
Scope: VM200/public app UI static assets plus repo commit/tag/push  
Backend deploy: none  
CT203 restart: none  
DB writes: none

## Summary

This checkpoint adds a user-facing signed-in Companion auth validation test path to the public app UI.

The UI test calls:

- `POST /api/companion/chat`

with:

- `X-APC-Companion-Auth-Validate-Only: FC-O45-E-Q`

and expects the FC-O45-E-Q no-enqueue response:

    ok: true
    auth_validated: true
    queue_write: false
    route: /api/companion/chat
    mode: auth_validate_only

This proves the browser can reach signed-in Companion auth without creating a queue job.

## Companion page cleanup

The Companion page should no longer expose the Study tools box directly. Companion should eventually use Study tools internally through backend/tool integration. Users should not have to manage decks/cards/review controls inside the Companion page.

The UI helper removes the visible Study tools box from the Companion page while preserving Study functionality on the Study page itself.

## Safety

This checkpoint does not change CT203 backend code. FC-O45-E-Q already live-proved the backend no-enqueue validation mode, and FC-O45-E-R source-aligned it into the repo.

This checkpoint does not:

- restart CT203
- write to the DB
- create jobs
- call workers/models/helpers/runtimes
- activate scheduler/timer
- restart CT/VM
- mutate nginx/cloudflared

## R9 repo checkpoint

The FC-O45-E-S UI source patch is committed as a repo checkpoint before VM200 live deployment because PVEW SSH access timed out during recovery.

Last observed live/public state before this repo checkpoint:

- Public `/api/system/status` was 200.
- Public `/api/me` was 401 signed out.
- Public cache-busted `/app.js?v=20260624fc045es` was 200 but did not yet contain the FC-O45-E-S UI marker.
- VM200 static deployment is pending.
- No backend deploy, CT203 restart, DB write, worker/model/helper/runtime call, scheduler/timer activation, CT/VM restart, or nginx/cloudflared mutation is performed by this repo checkpoint.

Next live step should deploy the already-committed wrapper UI assets to `/var/www/apc-wrapper-local` once PVEW access is healthy.


## R20 cache-bust alignment

VM200 accepted the FC-O45-E-S inline Companion UI helper, but the public edge had already cached `/app.js?v=20260624fc045es` before the marker was present. R20 advances the wrapper UI cache-bust to `/app.js?v=20260624fc045esr20` and verifies the marker through the fresh public URL.

No backend deploy, CT203 restart, DB write, worker/model/helper/runtime call, scheduler/timer activation, CT/VM restart, or nginx/cloudflared mutation is performed.
