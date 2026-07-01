# Stage 17K-Z-R11L — Profile Dual Render Path Inventory, No Mutation

## Status

Read-only diagnosis checkpoint.

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
No service restart.
No nginx reload.
No cloudflared mutation.

## Why this stage exists

Manual browser testing found two different Profile render paths.

Header Profile click showed:

- Account
- old Anki collection chooser

Hard-refresh on the Profile page showed:

- Account
- Google Drive sync
- old Anki collection chooser

The R11K browser verifier was also run on `/study`, where the Profile-only preview mount correctly did not attach.

This means the Profile surface must be unified before continuing Anki import/preview work.

## Goal

Inventory source and deployed static files to identify which Profile renderer is used by:

- header navigation
- hard refresh `/profile`
- private page loader
- old Anki manifest panel
- Google Drive sync panel
- new Profile Anki APKG preview mount

## Evidence captured

This stage records:

- source file presence
- source Profile route scans
- source Profile feature markers
- public route probes for `/`, `/profile`, and `/study`
- VM200 deployed source marker scan

## Safety boundary

This stage only reads source and public/static pages.

It does not:

- deploy anything
- copy files
- restart services
- mutate VM200
- mutate CT203
- write server data
- store private Study or Anki data
- activate Google Drive
- activate OAuth

## Recommended next stage

R11M should make Profile canonical in source.

Preferred direction:

- one Profile renderer only
- header navigation and hard refresh must render the same Profile content
- Google Drive sync panel remains visible only where intended
- old Anki collection chooser and new APKG preview panel should not compete
- no server private Study persistence
- no Anki source file mutation
- no deploy until source smoke passes
