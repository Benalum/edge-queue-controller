# Stage 17K-Z-R12C — Anki Copy Buddies Who Study Local Browser

## Status

Narrow copy-only VM200 static deploy.

## Deployed files

Only two files were deployed:

- index.html
- privatepages/anki-manifest-panel.js

index.html changed only to cache-bust anki-manifest-panel.js.

## User-facing copy change

Replaced:

- APC reads deck names and card counts locally in this browser.

With:

- Buddies Who Study reads deck names and card counts locally in this browser.

## Safety

No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No Google Drive or OAuth activation.
No APKG mount change.
No backend route addition.
No DB write.
No signup change.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.
No service restart.
