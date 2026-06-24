# Stage 16 FC-O45-C-O — Polish Study Workspace CSS and Data Formatting

Date: 2026-06-24

## Marker

`APC_STUDY_WORKSPACE_POLISH_FC_O45_C_O`

## Why

FC-O45-C-N-R2 restored the Study workspace functionality, but the signed-in page looked rough:

- forms were visually cramped,
- buttons were not grouped,
- metrics were not styled,
- card/deck rows were hard to read,
- `Deck/card statistics → Cards` could render arrays/objects as `[object Object]`.

## Change

`frontend/wrapper-ui/app.js` now adds scoped CSS for the canonical Study workspace panel and safe display formatting:

- responsive Study workspace forms,
- styled action buttons,
- metric cards,
- compact deck/card rows,
- clearer labels: New deck name, Card front, Card back,
- array/object-safe metric formatting,
- fixed deck/card statistics value formatting.

## Live deployment

VM200 `/var/www/apc-wrapper-local/app.js` is backed up and replaced from repo source with SHA verification.

VM200 `/var/www/apc-wrapper-local/index.html` is backed up and cache-bust updated from:

`/app.js?v=20260624fco45cnr2`

to:

`/app.js?v=20260624fco45co`

## Guardrails

- No DB write.
- No job mutation.
- No backend mutation.
- No service restart/reload/enable/disable.
- No nginx/cloudflared mutation.
- No CT/VM start/stop/restart.
- No worker/model/helper/runtime call.
- No scheduler/timer/persistent-worker activation.
