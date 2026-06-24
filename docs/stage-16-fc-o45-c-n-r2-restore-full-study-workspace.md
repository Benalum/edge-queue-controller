# Stage 16 FC-O45-C-N-R2 — Restore Full Signed-In Study Workspace

Date: 2026-06-24

## Marker

`APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2`

## Why

The first FC-O45-C-N attempt failed local JavaScript syntax validation before commit/deploy. VM200 was not touched. R2 resets the failed uncommitted source patch and restores the full signed-in Study workspace using safer JavaScript string construction.

## Change

`frontend/wrapper-ui/app.js` now mounts one canonical signed-in Study workspace panel:

`apcStudyFullWorkspacePanelFcO45CNR2`

The canonical panel restores:

- Create deck
- Edit deck
- Delete deck
- Add card
- Edit card
- Delete card
- Overall progress
- Weekly progress
- Deck/card statistics
- Review queue

It prefers the wrapper authenticated API path and keeps signed-out Study private tools hidden.

The single-owner cleanup now prefers the canonical full workspace panel if duplicate legacy panels try to mount later.

## Live deployment

VM200 `/var/www/apc-wrapper-local/app.js` is backed up and replaced from repo source with SHA verification.

VM200 `/var/www/apc-wrapper-local/index.html` is backed up and cache-bust updated from:

`/app.js?v=20260624fco45cl`

to:

`/app.js?v=20260624fco45cnr2`

## Guardrails

- No DB write during this deploy.
- No job mutation.
- No backend mutation.
- No service restart/reload/enable/disable.
- No nginx/cloudflared mutation.
- No CT/VM start/stop/restart.
- No worker/model/helper/runtime call.
- No scheduler/timer/persistent-worker activation.
