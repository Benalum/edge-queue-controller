# Stage 8I Disabled Frontend Router Shadow-Read Stub

Stage 8I adds a standalone disabled-by-default frontend helper file for future Universal Intent Router shadow-read work.

## File Added

- `frontend/wrapper-ui/router_shadow_read_stub.js`

## Safety

Stage 8I does not:

- load the helper in `index.html`
- import the helper in `app.js`
- call the live router endpoint
- enable the live router endpoint
- restart the live controller
- dispatch Study commands
- call models
- change Study behavior
- change Companion behavior

## Helper Behavior

The helper is disabled by default:

- `ROUTER_SHADOW_READ_ENABLED = false`

The helper can build a dry-run payload with:

- `dry_run = true`
- `allow_dispatch = false`
- `allow_model_call = false`

The helper can extract consumer-safe fields from:

- `decision_contract`

The helper rejects unsafe dispatch state unless:

- `dispatch_performed = false`
- `allowed_to_dispatch = false`
- `would_dispatch = false`

## Not Wired Yet

This stage intentionally does not wire the helper into the live frontend.

The helper is not referenced by:

- `frontend/wrapper-ui/index.html`
- `frontend/wrapper-ui/app.js`

## Decision

Stage 8I creates a safe, testable stub only.

Stage 8J should add a no-op frontend-side unit smoke for the stub and/or plan the first real shadow-read wiring point, still disabled by default.
