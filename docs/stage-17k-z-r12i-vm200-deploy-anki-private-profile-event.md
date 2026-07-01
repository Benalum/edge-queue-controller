# Stage 17K-Z-R12I — VM200 Deploy Anki Private Profile Event

## Status

Narrow VM200 static deploy.

## Deployed files

Only two files were deployed:

- index.html
- privatepages/anki-manifest-panel.js

index.html changed only to cache-bust anki-manifest-panel.js.

## Live fix

Anki chooser now mounts only from:

- apc-private-page-rendered
- detail.page === "profile"
- detail.user exists

Non-private lifecycle events only run cleanup.

## Expected behavior

Signed-out hard refresh `/profile`:

- no Anki chooser flash

Signed-in private `/profile`:

- Anki chooser remains visible
- copy says Buddies Who Study

## Safety

No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No Google Drive or OAuth activation.
No local backups change.
No APKG mount change.
No backend route addition.
No DB write.
No signup change.
No server private Study persistence.
No Anki source file mutation.
No real SQLite collection parsing.
No media extraction.
No service restart.
