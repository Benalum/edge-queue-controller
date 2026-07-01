# Stage 17K-Z-R12K — Profile Copy Cleanup

## Status

Narrow copy/status cleanup and VM200 static deploy.

## Deployed files

Only four files were deployed:

- index.html
- privatepages/profile-local-backups-panel.js
- privatepages/profile-local-backups-mount.js
- privatepages/anki-manifest-panel.js

index.html changed only to cache-bust those scripts.

## Copy changes

Local backups now says:

- Save your data locally.

Removed from visible local backups card:

- This does not upload anything, does not modify Anki files, and does not browse your other files.
- Do not choose your Anki profile folder. Use a separate backup folder.
- Storage: browser-local export. Server upload: no. Anki source mutation: no.
- Ready. Choose a local backup folder or download a backup file.

Anki now says:

- Choose your Anki collection file. Buddies Who Study will not edit any of your Anki files.

## Safety

No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No Google Drive sync logic change.
No APKG mount change.
No backend route addition.
No DB write.
No signup change.
No server private Study persistence.
No Anki source file mutation.
No real SQLite collection parsing.
No media extraction.
No service restart.
