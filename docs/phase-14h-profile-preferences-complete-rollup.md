# Phase 14H Profile Preferences Complete Rollup

Phase 14H records the completed Profile preferences foundation.

## Completed chain

- Phase 13X: live `app_user_preferences` schema migration
- Phase 13Y: live `GET /api/profile/preferences`
- Phase 13Z: live `PATCH /api/profile/preferences`
- Phase 14A: read-only Profile preferences UI
- Phase 14B: controller runtime reload QA
- Phase 14C: served wrapper UI QA
- Phase 14D: wrapper cache-bust
- Phase 14E: public wrapper QA
- Phase 14F: editable Profile preferences UI
- Phase 14G: authenticated browser save/readback QA

## Final behavior

Logged-in users can view and edit backend-owned Profile preferences from `https://alexhartel.com/profile`.

The editable UI saves changed fields through:

- `PATCH /api/profile/preferences`

The readback path uses:

- `GET /api/profile/preferences`

## Important authentication boundary

Raw cookie-only `fetch()` returns `401 Missing bearer token`.

The working browser path uses the wrapper `api()` helper, which attaches the Bearer token through `authHeaders()`.

The working browser path uses the api() helper marker for the completed rollup smoke.

## Safety boundaries preserved

The Profile preference UI stores preferences only. It does not:

- activate microphone capture
- activate speech output
- authorize Google Calendar
- authorize Apple Calendar
- write calendar events
- call models
- enqueue jobs
- dispatch workers
- activate tools
- change power automation

Voice, listen, speak, auto-listen, and auto-speak fields remain stored preferences only.
