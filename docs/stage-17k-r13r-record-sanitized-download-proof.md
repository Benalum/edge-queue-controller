# Stage 17K-R13R — Record Sanitized Download Snapshot Proof

## Status

Browser proof passed.

## Current repo baseline

R13Q-R7 fixed the Download snapshot click handler by defining `getPanelApi()` in `profile-local-backups-mount.js`.

## Proof file

Browser-downloaded snapshot:

- buddies-who-study-local-backup-v2-2026-07-05T23-33-14-803Z.json

Backup payload timestamp:

- 2026-07-05T23:33:14.795Z

## Verified contents

The downloaded snapshot retained the expected valid backup shape:

- kind: buddies-who-study-local-backup
- version: 2
- docs: 11
- decks: 2
- cards: 2
- sessions: 16
- media count: 0
- media bytes: 0

## Sanitized fields proof

The downloaded snapshot no longer contains the legacy backend cache fields:

- backendProgress
- backendReviewSummary
- backendSessions
- backendSyncedAt

The `study/store-state/v1.state` object now contains only local browser state fields:

- version
- activeDeckId
- decks
- cards
- sessions
- runtime

## Privacy proof

The downloaded snapshot still keeps local-only privacy flags:

- serverUpload false
- uploadsToServer false
- ankiSourceMutation false
- sourceMutation false
- modifiesAnkiSourceFiles false
- includesAnkiSourceFileBytes false
- originalAnkiBytesIncluded false
- localOnly true

## Safety

Docs/evidence only.

No source mutation.
No frontend deploy.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study restore write.
No current-file save.
No same-file write path.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
