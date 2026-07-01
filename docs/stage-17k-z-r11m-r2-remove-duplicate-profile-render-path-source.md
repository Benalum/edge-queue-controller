# Stage 17K-Z-R11M-R2 — Remove Duplicate Profile Render Path Source

## Status

Source-only Profile canonicalization checkpoint.

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

Manual browser testing showed two different Profile outcomes.

Header Profile navigation showed Account plus the old Anki collection chooser.

Hard refresh on Profile showed Account plus Google Drive sync plus the old Anki collection chooser.

R11L inventory showed the source cause: Google Drive sync was being loaded through a legacy loader embedded inside the Anki manifest panel, and that loader listened for a stale private-page render event name.

R11M failed before patching because an unquoted Python heredoc allowed the shell to expand JavaScript template text. R11M-R2 retries with a quoted heredoc and removes the duplicate loader path.

## What changed

- Profile fragment now has one canonical root:
  - data-apc-profile-root
  - data-page profile
  - data-route profile

- Profile fragment now has explicit feature hosts:
  - data-apc-profile-google-sync-host
  - data-apc-profile-anki-manifest-host
  - data-apc-profile-anki-preview-host

- privatepages.js now exposes data-page and data-route on the private shell.

- anki-manifest-panel.js no longer contains the legacy Google sync Profile loader block.

- profile-google-sync-panel.js now listens to the canonical apc-private-page-rendered event.

- profile-anki-preview-mount.js now listens to the canonical apc-private-page-rendered event.

- index.html directly loads profile-google-sync-panel.js with the R11M-R2 cache-bust.

## Expected result after a later deploy

Header Profile navigation and hard-refresh Profile should show the same canonical Profile surface.

Google Drive sync is no longer loaded through the Anki panel.

The old Anki collection chooser and the new APKG preview panel mount from explicit Profile hosts instead of competing for generic page targets.

## Safety boundary

This is a source-only fix.

It does not deploy anything, mutate live VM200 files, add backend routes, write server data, upload Anki data, mutate Anki files, enable Google OAuth, parse SQLite rows, or extract media files.
