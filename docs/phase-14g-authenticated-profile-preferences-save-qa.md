# Phase 14G Authenticated Profile Preferences Save QA

Phase 14G records successful browser-authenticated save QA for the editable Profile preferences UI.

## Browser QA result

The test was run from Firefox Web Console while logged in at:

- `https://alexhartel.com/profile`

The QA script used the wrapper app's `api()` helper so the existing Bearer token was attached.

Observed result:

- `PHASE_14G_BROWSER_SAVE_QA PATCH_STATUS 200`
- `PHASE_14G_BROWSER_SAVE_QA GET_STATUS 200`
- `PHASE_14G_BROWSER_SAVE_QA PASS`

The saved values were read back successfully:

- `companion_tone=encouraging`
- `notification_preference=none`

## Important auth finding

A raw browser `fetch()` using cookies only returned:

- `401`
- `Missing bearer token.`

That is expected. The Profile UI must use the wrapper `api()` helper because it attaches the Bearer token through `authHeaders()`.

The Profile UI uses the api() helper for authenticated reads and writes.
This QA does not use cookie-only raw fetch for the passing save path.

## Safety boundaries confirmed

This QA did not:

- activate microphone capture
- activate speech output
- authorize Google Calendar
- authorize Apple Calendar
- call models
- enqueue jobs
- dispatch workers
- activate tools
- write calendar events
- change power automation

The repeated presence logs were deferred wrapper power-policy acceptance messages and did not block page load.
