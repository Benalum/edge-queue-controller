# Phase 14A Profile Preferences UI Read

Phase 14A adds a read-only Profile UI display for backend-owned profile preferences.

The Profile page now attempts to read:

- `GET /api/profile/preferences`

The UI displays preference values when available and shows a safe unavailable state when the running service has not yet loaded the route.

## Safety boundaries

This phase must not:

- add save/edit controls
- call `PATCH /api/profile/preferences`
- write profile preferences from the browser
- activate microphone capture
- activate speech output
- authorize Google Calendar
- authorize Apple Calendar
- store calendar events in the controller
- call models
- enqueue jobs
- dispatch workers

Typed input must remain available.

## Future phase

A later phase will add editable controls and saving through the backend-owned `PATCH /api/profile/preferences` endpoint.
