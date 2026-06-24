# Stage 16 FC-O45-C-J — Remove Legacy Study Wrapper Preview from /study

Date: 2026-06-24

## Marker

`APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J`

## Why

The signed-in Study page rendered two separate page shells:

1. the main signed-in Study/durable-session surface, and
2. the old Study wrapper preview mini-app with its own banner, navigation, header, and Loading state.

The duplicate source was the legacy Study wrapper preview path being allowed to run on real `/study`.

## Change

`frontend/wrapper-ui/app.js` now treats only `/study-wrapper-preview` as the legacy Study wrapper preview route.

Real `/study` now renders a clean Study shell through:

`renderCleanStudyRouteFcO45CJ()`

The route assignment was changed to:

`const isStudyWrapperRoute = path === "/study-wrapper-preview";`

The existing durable Study session, deck selector, and Study tools enhancement hooks remain available on the real Study route.

## Live deployment plan

VM200 `/var/www/apc-wrapper-local/app.js` is backed up and replaced from repo source with SHA verification.

VM200 `/var/www/apc-wrapper-local/index.html` is backed up and cache-bust updated from:

`/app.js?v=20260624fco45cd`

to:

`/app.js?v=20260624fco45cj`

so browsers load the corrected app.js.

## Guardrails

- No DB write.
- No job mutation.
- No backend mutation.
- No service restart/reload/enable/disable.
- No nginx/cloudflared mutation.
- No CT/VM start/stop/restart.
- No worker/model/helper/runtime call.
- No scheduler/timer/persistent-worker activation.
