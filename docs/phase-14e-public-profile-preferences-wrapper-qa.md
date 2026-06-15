# Phase 14E Public Profile Preferences Wrapper QA

Phase 14E confirms the public `alexhartel.com` wrapper serves the Phase 14D cache-busted Profile preferences UI assets.

## Confirmed public behavior

- `https://alexhartel.com/` serves wrapper HTML with `/app.js?v=20260614214d`.
- `https://alexhartel.com/profile` serves wrapper HTML with `/app.js?v=20260614214d`.
- `https://alexhartel.com/app.js?v=20260614214d` contains the Phase 14A Profile preferences read-only UI marker.
- `https://alexhartel.com/styles.css?v=20260614214d` contains the Phase 14A Profile preferences style marker.
- `https://alexhartel.com/api/profile/preferences` must not return `404`.

Anonymous API requests may return `401` or `403`; that is expected.

## Safety boundaries

This phase does not:

- write profile preferences
- activate microphone capture
- activate speech output
- authorize Google Calendar
- authorize Apple Calendar
- call models
- enqueue jobs
- dispatch workers
- change power automation
- restart services
