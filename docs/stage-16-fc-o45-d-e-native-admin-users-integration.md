# Stage 16 FC-O45-D-E — Native Admin Users Integration

Date: 2026-06-24

## Marker

`APC_NATIVE_ADMIN_USERS_INTEGRATION_FC_O45_D_E`

## Why

FC-O45-D-C-R3 proved that the backend data path works:

- `/system/admin/users` returns the real users to an authenticated admin session.
- The native Admin page still showed stale placeholders: "Online users 0", "Users returned 0", and "No users loaded yet".
- The temporary repair panel displayed the correct data, but it should not remain as the long-term UI.

## Change

`frontend/wrapper-ui/app.js` now adds a frontend-only native Admin integration that:

- fetches users from `/system/admin/users`,
- derives Online Users from returned `online`, `is_online`, or `active` flags,
- renders the real user list inside the native Admin user cards,
- hides stale native zero/empty messages,
- removes the temporary FC-O45-D-C repair panel from the rendered Admin page.

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

## Deployment

VM200 `/var/www/apc-wrapper-local/app.js` is backed up and replaced from repo source with SHA verification.

VM200 `/var/www/apc-wrapper-local/index.html` is backed up and cache-bust updated from:

`/app.js?v=20260624fc045dcr3`

to:

`/app.js?v=20260624fc045de`

## Next backend step

A later backend-approved step can add `/system/admin/online-users` as a dedicated endpoint. Until then, the native UI derives online state from `/system/admin/users`.
