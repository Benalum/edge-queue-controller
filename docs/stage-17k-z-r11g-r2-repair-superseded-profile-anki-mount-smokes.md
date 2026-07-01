# Stage 17K-Z-R11G-R2 — Repair Superseded Profile Anki Mount Smokes

## Status

Source-only smoke repair checkpoint.

No deploy.
No frontend live mutation.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth work.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.

## Why this repair exists

R11G intentionally mounted the Profile Anki preview source in local wrapper source, but the historical R11E and R11F smokes still asserted that the bridge and panel were not mounted.

The R11G run committed successfully, but its evidence captured failing R11E/R11F regression smoke outputs.

R11G-R2 repairs that evidence gap by updating the older smokes to accept the R11G source mount as the new expected boundary.

## Updated files

- ops/smoke/check-stage-17k-z-r11e-profile-anki-apkg-preview-bridge-no-ui.sh
- ops/smoke/check-stage-17k-z-r11f-profile-anki-apkg-preview-panel-source-no-mount.sh

## New expected behavior

If profile-anki-preview-mount.js is loaded from index.html, the older R11E/R11F no-mount assertions are superseded and pass.

If the R11G source mount is absent, the older no-mount checks still protect against accidental early mounting.

## Safety boundary

This repair changes smoke expectations only.

It does not:

- deploy anything
- call network APIs
- call backend routes
- write APC_LOCAL_SAVE docs
- write localStorage
- open IndexedDB
- mutate original Anki files
- parse SQLite rows
- extract media files
