# Stage 16 FC-O45-D-F — Recent Users Top-50 Scroll With Credits

Date: 2026-06-24

## Marker

`APC_RECENT_USERS_TOP50_CREDITS_FC_O45_D_F`

## Why

The Admin native Online Users section is now populated from `/system/admin/users`, but the page needs a better recent-user view.

The user requested:

- Recent Users,
- top 50 in a scroll window,
- free/local credits,
- paid credits.

## Change

`frontend/wrapper-ui/app.js` now adds a frontend-only **Recent Users** card that:

- loads users from `/system/admin/users`,
- sorts by latest activity,
- shows up to 50 users in a scrollable table,
- includes `Free/local credits` and `Paid credits` columns,
- displays credit values when those fields are present in the backend user payload,
- displays a pending-backend-field note when balances are not yet exposed,
- hides the duplicate fallback Admin users/Online users block.

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

`/app.js?v=20260624fc045de`

to:

`/app.js?v=20260624fc045df`

## Possible follow-up

If the credit columns show `pending backend field`, add credit balances to `/system/admin/users` or add a read-only admin credit summary endpoint in a separate backend-approved step.
