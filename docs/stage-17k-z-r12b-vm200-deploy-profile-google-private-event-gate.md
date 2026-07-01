# Stage 17K-Z-R12B — VM200 Deploy Profile Google Private Event Gate

## Status

Narrow VM200 static deploy.

## Deployed files

Only two files were deployed:

- index.html
- privatepages/profile-google-sync-panel.js

index.html changed only to cache-bust profile-google-sync-panel.js.

## Live behavior

Google Drive sync is created only from the private page render event:

- apc-private-page-rendered
- detail.page === "profile"
- detail.user exists

Signed-out public Profile should not show Google Drive sync.

Signed-in private Profile should show Google Drive sync with Buddies Who Study local data wording.

## Safety

No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
No APKG mount change.
No backend route addition.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No Anki source file mutation.
No service restart.
