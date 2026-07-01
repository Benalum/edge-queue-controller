# Stage 17K-Z-R11V-R2 — Profile Local Data Copy Commit Recovery

## Status

Source-only commit recovery after interrupted R11V.

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

## What happened

R11V successfully patched user-facing Profile Google/local-data copy, then timed out before completing smoke/commit.

R11V-R2 verifies the already-applied copy change with fixed-string checks and commits it.

## User-facing naming decision

Use:

- Buddies Who Study local data

instead of exposing the internal acronym APC in Profile user-facing copy.

APC remains acceptable in internal source names, constants, markers, docs, and smoke labels.

## What changed

Only one source file is intended to change:

- privatepages/profile-google-sync-panel.js

User-facing copy now uses:

- Buddies Who Study local data
- Create hidden Buddies Who Study local data database
- Read Buddies Who Study local data metadata
- Rollback/delete Buddies Who Study local data proof files

## What did not change

This does not touch:

- index.html
- privatepages.js
- pages/profile.html
- anki-manifest-panel.js
- profile-anki-preview-mount.js
- session/auth gate
- private shell rendering
- Google OAuth behavior
- backend/runtime

## Why this is not a wrapper or bandage

This is copy-only.

It does not alter rendering, routing, storage authority, or sync behavior.
