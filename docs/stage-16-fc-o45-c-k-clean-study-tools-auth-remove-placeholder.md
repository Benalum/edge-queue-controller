# Stage 16 FC-O45-C-K — Clean Study Tools Auth and Remove Placeholder Shell

Date: 2026-06-24

## Marker

`APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K`

## Why

After removing the duplicate legacy Study wrapper preview from real `/study`, two cleanup issues remained:

1. Signed-out Study showed a private Study tools panel with a 401 message.
2. Signed-in Study showed a temporary placeholder `Study dashboard / Loading...` shell in addition to the durable Study session/deck selector.
3. Study tools were using plain fetch for `/api/study/*`, which did not carry the same auth path as the wrapper's `api()` helper.

## Change

`frontend/wrapper-ui/app.js` now:

- removes the Study tools panel when Study APIs are unauthenticated or unavailable instead of displaying a 401 panel,
- prefers the wrapper `api()` helper for `/api/study/*` calls so signed-in Study requests carry wrapper auth,
- hides the temporary clean Study placeholder shell so the durable Study session/deck selector remains the visible main page,
- keeps `/study-wrapper-preview` as the only legacy preview route.

## Live deployment

VM200 `/var/www/apc-wrapper-local/app.js` is backed up and replaced from repo source with SHA verification.

VM200 `/var/www/apc-wrapper-local/index.html` is backed up and cache-bust updated from:

`/app.js?v=20260624fco45cj`

to:

`/app.js?v=20260624fco45ck`

## Guardrails

- No DB write.
- No job mutation.
- No backend mutation.
- No service restart/reload/enable/disable.
- No nginx/cloudflared mutation.
- No CT/VM start/stop/restart.
- No worker/model/helper/runtime call.
- No scheduler/timer/persistent-worker activation.
