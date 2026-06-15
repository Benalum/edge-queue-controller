# Phase 14D Wrapper Cache-Bust Profile Preferences UI

Phase 14D updates the wrapper HTML asset version strings so browsers fetch the Phase 14A Profile preferences UI JavaScript and CSS instead of using older cached assets.

## Changed assets

- `frontend/wrapper-ui/index.html`
- `/app.js?v=20260614214d`
- `/styles.css?v=20260614214d`

The separate Study preview stylesheet reference, `/study/styles.css?v=20260612000409`, is intentionally unchanged because this phase only cache-busts the wrapper-owned Profile UI assets.

## Safety boundaries

This phase does not:

- change backend routes
- write profile preferences
- activate microphone capture
- activate speech output
- authorize Google Calendar
- authorize Apple Calendar
- call models
- enqueue jobs
- dispatch workers
- change power automation
