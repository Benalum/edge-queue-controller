# Stage 16 FC-O45-C-G — Study Early Repair Bootstrap and VM200 App.js Deploy

Date: 2026-06-24  
Scope: repo source/docs/smoke plus VM200 app.js replacement only.

## Why

FC-O45-C-D/F proved the patched app.js and cache-busted root pointer were live, but the signed-in Study page still rendered the duplicate legacy Study mini-app and did not show the new Study tools panel.

The likely cause is that the previous Study repair module was appended at the end of a large wrapper script and may not run early enough.

## Change

Added an early bootstrap marker at the top of `frontend/wrapper-ui/app.js`:

`APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G`

The bootstrap:

- registers before the older wrapper code,
- hides the duplicate legacy Study block using the exact legacy phrase,
- mounts a Study tools panel near the durable Study session/deck selector area,
- loads Decks, Stats, Cards, and Review Queue from existing authenticated Study APIs,
- shows safe signed-out/unavailable states if APIs return 401 or another error,
- does not expose private Study data to signed-out visitors.

## Deployment

VM200 active app.js was replaced from the repo source with checksum verification and a timestamped backup. No services were restarted.

## Guardrails

- No DB write.
- No backend mutation.
- No service restart/reload/enable/disable.
- No nginx/cloudflared mutation.
- No CT/VM start/stop/restart.
- No worker/model/helper/runtime call.
- No scheduler/timer/persistent-worker activation.
- No VM200 index.html mutation in this checkpoint.
