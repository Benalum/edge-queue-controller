# Stage 17K R16BV — Companion preset list with Sol

This stage is source-only.

## What changed

- Adds a Companion preset catalog helper loaded by `index.html`.
- Adds a preset picker to Companion and Profile local settings.
- The first and only built-in preset is `Sol`.
- Users can choose Sol without pasting their own companion media URLs.
- Choosing Sol stores the companion name and built-in media paths in browser-local settings.
- Custom/manual media remains available for later.
- Adds a missing private Study fragment so `/privatepages/pages/study.html` no longer 404s in local-first routing.
- Adds a safe media fallback if the Sol clip assets are not present locally yet.
- Attempts to reconcile public Sol clip assets from the live static site if they exist.

## Safety rails

- No VM deploy.
- No SSH.
- No sudo.
- No backend mutation.
- No database mutation.
- No Google Drive sync activation.
- No Anki mutation.
- No private study data copied.

## Notes

The local browser log before this stage showed local-first routes loading, but the Study private fragment and Sol clip assets returned 404. This stage fixes the missing Study fragment and makes the Sol companion selectable without requiring the user to provide their own companion media.
