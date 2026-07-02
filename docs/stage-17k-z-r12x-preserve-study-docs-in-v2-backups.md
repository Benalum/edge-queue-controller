# Stage 17K-Z-R12X — Preserve Study Docs in V2 Backups

## Status

Narrow VM200 static deploy.

## User-facing fix

V2 local backup downloads now preserve the real Study docs while also including the empty media docs.

Required Study docs preserved:

- study/cards/v1
- study/decks/v1
- study/progress/v1
- study/sessions/v1
- study/store-state/v1

Media docs still included:

- study/media/v1
- study/media-blobs/v1
- study/card-media-refs/v1
- study/media-manifest/v1
- study/anki-media/v1
- study/anki-imports/v1

## Safety

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
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.

## Deploy files

- index.html
- privatepages/profile-local-backups-panel.js

## Next test

Download a new backup file from signed-in Profile and verify that docs contains both Study docs and media docs.
