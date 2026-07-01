# Stage 17K-Z-R11Q — Remove Profile Google Indirect Loader, Source Only

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

Profile showed different content between hard refresh and header navigation.

This was caused by a stale Google Drive sync loader embedded inside anki-manifest-panel.js.

The stale loader only loaded profile-google-sync-panel.js indirectly, and it listened for the old event name:

- apc:privatepage:rendered

But privatepages.js dispatches:

- apc-private-page-rendered

Header navigation uses pushState, which does not fire popstate. Because of the event mismatch, the indirect Google loader did not fire on header Profile clicks.

Hard refresh on /profile worked because location.pathname already contained profile during page load, so the stale loader injected the Google sync panel.

## What changed

This stage changes only three source files:

- index.html
- privatepages/anki-manifest-panel.js
- privatepages/profile-google-sync-panel.js

Changes:

- index.html now directly loads profile-google-sync-panel.js.
- anki-manifest-panel.js no longer owns or injects the Google sync panel.
- profile-google-sync-panel.js listens to apc-private-page-rendered, the event privatepages.js already dispatches.

## Why this is not a wrapper or bandage

This removes the duplicate indirect loader.

It does not add another Profile wrapper.

It does not modify privatepages.js.

It does not modify the Profile fragment.

It does not change the session gate.

It does not alter the private shell.

## Safety boundary

This is source-only.

Live VM200 files are not changed in this stage.
