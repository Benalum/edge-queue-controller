# Stage 8Q Temporary Controller Router Dry-Run Validation

Stage 8Q validates Universal Intent Router dry-run behavior using a temporary controller only.

This is a docs/generated-report/smoke-only stage.

## Purpose

Stage 8P planned the backend/live router dry-run boundary without enabling live traffic.

Stage 8Q proves the router dry-run endpoint can still work when explicitly enabled on a temporary controller running on a separate port.

## Temporary Controller

Stage 8Q starts a temporary controller on:

- `127.0.0.1:7076`

with:

- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`
- `EDGE_ROUTER_SQLITE_DB_PATH=edge_queue.sqlite3`

## Live Safety

Stage 8Q does not:

- enable the live controller router endpoint
- modify live systemd environment
- restart the live controller
- restart the wrapper UI
- add `/api/router/dry-run` to frontend code
- enable frontend router traffic
- dispatch Study commands
- call models

## Expected Temporary Results

Temporary enabled dry-run should return safe `decision_contract` records for:

- Study next
- Study skip
- Study show answer
- Companion chat
- Admin blocked/unsupported

Every temporary response must keep:

- `dry_run = true`
- `dispatch_performed = false`
- `model_call_required = false`
- `allowed_to_dispatch = false`
- `eligible_for_dispatch = false`

## Required Live State After Test

After the temporary controller is stopped:

- live `/api/router/dry-run` remains disabled/404
- frontend still contains no `/api/router/dry-run`
- platform remains online
- queue remains clean
- modern timers remain active
- legacy scheduler timer remains disabled/inactive

## Recommended Next Stage

Stage 8R may create a manual go/no-go decision for enabling live backend dry-run in systemd, but no browser router traffic should be enabled yet.
