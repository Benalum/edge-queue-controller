# Stage 17K-Z-R11Y — Profile Google Sync Signed-In Private-Only, Source

## Status

Source-only narrow fix.

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

## Root cause

R11X found that profile-google-sync-panel.js was loaded directly from index.html and rendered when it saw a Profile surface by path, title, or DOM hints.

That allowed the Google Drive sync panel to appear on the signed-out public Profile page.

privatepages.js intentionally lets signed-out /profile fall through to the public page, so profile-google-sync-panel.js must require the signed-in private Profile render before showing the panel.

## What changed

Only one source file changed:

- privatepages/profile-google-sync-panel.js

The Google sync panel now requires both:

- .private-shell[data-private-page="profile"]
- window.APC_PRIVATEPAGES.me() returning a user

If those conditions are not true, it removes its panel and returns.

It also listens to apc-auth-changed so sign-out/sign-in transitions can remove or re-render the panel.

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

This does not add another Profile shell.

This does not change routing.

This does not duplicate rendering.

It simply gates the existing Google sync card to the signed-in private Profile page where it belongs.

## Expected follow-up

If this source-only proof passes, deploy only:

- index.html for cache-bust
- privatepages/profile-google-sync-panel.js
