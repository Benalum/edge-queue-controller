# Stage 16 FC-O45-C-L — Study Single Owner Route and Tools

Date: 2026-06-24

## Marker

`APC_STUDY_SINGLE_OWNER_FC_O45_C_L`

## Why

After FC-O45-C-K, Study tools loaded successfully, but two Study tools panels appeared while signed in. Signed-out Study also flashed because multiple Study route/enhancer owners were still competing.

## Change

`frontend/wrapper-ui/app.js` now makes `/study` a single-owner surface:

- signed-out `/study` renders exactly one public Study page through `renderPublicFeatureGate("/study")`,
- signed-out private Study tools are removed,
- signed-in duplicate Study tools panels are deduplicated,
- the early emergency Study tools mount is redirected into a hidden scratch panel,
- a route-local cleanup observer keeps one visible Study tools panel if late enhancers fire again,
- the legacy Study wrapper preview remains limited to `/study-wrapper-preview`.

## Live deployment

VM200 `/var/www/apc-wrapper-local/app.js` is backed up and replaced from repo source with SHA verification.

VM200 `/var/www/apc-wrapper-local/index.html` is backed up and cache-bust updated from:

`/app.js?v=20260624fco45ck`

to:

`/app.js?v=20260624fco45cl`

## Guardrails

- No DB write.
- No job mutation.
- No backend mutation.
- No service restart/reload/enable/disable.
- No nginx/cloudflared mutation.
- No CT/VM start/stop/restart.
- No worker/model/helper/runtime call.
- No scheduler/timer/persistent-worker activation.
