# Stage 17K-Z-R11M-R4 — Bounded Push Recovery, No Fetch

## Status

Push recovery checkpoint for the Profile duplicate-render removal.

No deploy.
No frontend live mutation.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.
No service restart.
No nginx reload.
No cloudflared mutation.

## Why this stage exists

R11M-R2 successfully removed the duplicate Profile render path in source and created local commit 2a7fe0a.

R11M-R3 then timed out during git fetch before creating recovery docs.

R11M-R4 avoids git fetch entirely and uses bounded push commands.

## Recovered commit

- 2a7fe0a fix: remove duplicate profile render path

## Recovered tag

- controller-stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source-2026-07-01

## What R11M-R2 changed

R11M-R2 removed the duplicate Profile path by:

- removing the legacy Google sync loader from anki-manifest-panel.js
- loading profile-google-sync-panel.js directly from index.html
- making Profile expose explicit feature hosts
- making Profile modules listen to apc-private-page-rendered
- keeping the fix source-only with no live deploy

## Safety boundary

This recovery stage does not patch app behavior again.

It does not deploy anything, mutate VM200 live files, add backend routes, write server data, upload Anki data, mutate Anki files, enable Google OAuth, parse SQLite rows, or extract media files.
