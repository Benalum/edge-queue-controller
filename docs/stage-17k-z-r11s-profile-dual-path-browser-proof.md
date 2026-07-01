# Stage 17K-Z-R11S — Profile Dual-Path Browser Proof

## Status

Manual browser proof checkpoint after R11R.

No deploy.
No source patch.
No wrapper.
No bandage.
No privatepages.js change.
No Profile fragment change.
No session gate change.
No private shell change.
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

## Proof summary

After R11R, both Profile entry paths matched:

- hard refresh on Profile
- header Profile navigation after visiting Study

Both showed:

- Account panel
- Google Drive sync panel
- Anki local file chooser panel

The site did not white-screen and did not get stuck on "Checking session."

## Root cause fixed

R11R deployed the R11Q narrow fix:

- removed the stale indirect Google loader from anki-manifest-panel.js
- loaded profile-google-sync-panel.js directly from index.html
- changed profile-google-sync-panel.js to listen to apc-private-page-rendered

This fixed the mismatch without touching:

- privatepages.js
- profile.html
- session gate
- private shell
- backend/runtime

## Next direction

Continue Anki/APKG preview work only after this proof checkpoint.

Keep future changes narrow.
