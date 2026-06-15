# Phase 14B Profile Preferences Runtime Reload QA

Phase 14B performs a controlled reload of the running Edge Queue Controller so the runtime process loads the already-committed profile preferences code from Phase 13Y, Phase 13Z, and Phase 14A.

## Goals

- Confirm `/health` remains healthy after reload.
- Confirm `/api/profile/preferences` is no longer a missing route at runtime.
- Confirm the wrapper-served `app.js` contains the Phase 14A read-only Profile preferences UI marker.
- Confirm power automation safety remains unchanged.
- Confirm the Profile preferences UI remains read-only.

## Safety boundaries

This phase must not:

- enable full auto power tick
- pause or resume power automation
- write profile preferences from the browser
- activate microphone capture
- activate speech output
- authorize Google Calendar
- authorize Apple Calendar
- call models
- enqueue jobs
- dispatch workers

The endpoint may return an auth-related status for anonymous curl requests, but it must not return `404`.
