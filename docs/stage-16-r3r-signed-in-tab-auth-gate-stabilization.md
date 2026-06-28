# Stage 16 R3R Signed-In Tab Auth Gate Stabilization

This checkpoint adds a static front-end auth gate to reduce public-page flashes while a signed-in session is still being checked.

## Behavior

- Adds an early auth gate in index.html.
- Starts page load in checking state.
- Hides public/private page content behind a Checking session overlay until api/me resolves or a private page render event fires.
- Tracks auth status as checking, signed_in, or signed_out.
- Remembers the last signed-in email for stable local storage ownership during short auth refreshes.
- Updates Companion and Study owner fallback so they do not immediately fall back to local-user while auth is checking.

## Scope

Static source patch and VM200 static file deploy only. No backend changes, DB writes, service restarts, CT/VM restarts, OAuth work, Google API integration, or runtime/model/scheduler mutation.
