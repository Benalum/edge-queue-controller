# Stage 16 FC-O45-D-C-R3 — Admin Users Frontend Route Repair Finalize

Date: 2026-06-24

## Marker

`APC_ADMIN_USERS_ROUTE_REPAIR_FC_O45_D_C_R2`

## Why

The D-C-R2 source patch passed source checks, but the generated focused smoke script failed on a brittle documentation string check before commit/tag/push and before VM200 deployment.

This R3 checkpoint keeps the existing D-C-R2 source patch and replaces only the generated documentation/smoke wrapper.

## Findings from read-only audit

- CT203 exposes `/system/admin/users`.
- `/system/admin/users` returns `401 Missing bearer token` when signed out, confirming the route exists and requires admin auth.
- `/system/admin/online-users` returns `404`; it is not implemented yet.
- Older/public aliases such as `/api/account/users` and `/api/admin/users` return `404`.

## Source behavior

The frontend Admin repair panel:

- loads the users table from `/system/admin/users`,
- displays a clear online-users pending-backend message for `/system/admin/online-users`,
- performs no backend, database, service, nginx, CT/VM, job, worker, helper, runtime, scheduler, or model mutation.

## Deployment

VM200 `/var/www/apc-wrapper-local/app.js` is backed up and replaced from repo source with SHA verification.

VM200 `/var/www/apc-wrapper-local/index.html` is backed up and cache-bust updated from:

`/app.js?v=20260624fco45co`

to:

`/app.js?v=20260624fc045dcr3`

## Guardrails

- No CT203 backend mutation.
- No database write.
- No job mutation.
- No worker/model/helper/runtime call.
- No scheduler/timer/persistent-worker activation.
- No VM/CT start/stop/restart.
- No service restart/reload/enable/disable.
- No nginx/cloudflared mutation.
- No GitHub branch/repo deletion.

## Next backend step

Add CT203 `/system/admin/online-users` as a read-only admin endpoint under a separate approval that allows backend change and service restart.
