# Stage 8E Temporary Router Decision Contract HTTP Smoke

Stage 8E proves the Stage 8D router decision contract adapter against real router HTTP output from a temporary enabled controller process.

## Purpose

Stage 8D added a source-only adapter helper:

- `_stage8d_router_decision_contract(...)`

Stage 8E verifies that helper against enabled router HTTP responses without changing live production behavior.

## Safety

Stage 8E does not:

- restart the live controller
- enable the live router endpoint
- dispatch Study commands
- call any model
- change frontend behavior
- change Study behavior
- change Companion behavior

The live controller remains active on port `7070`.

The temporary controller runs only on a separate local port during the smoke.

## Live Router State

The live router endpoint must remain disabled:

- `POST /api/router/dry-run` returns 404
- `POST /system/router/dry-run` returns 404

## Temporary Router State

The smoke starts a temporary local controller with:

- `EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1`
- `EDGE_ROUTER_SQLITE_DB_PATH=edge_queue.sqlite3`
- temporary port `7073`

The temporary process is stopped before the smoke ends.

## Contract Cases

The smoke verifies these mappings:

- `next` from Study → `study_command`
- `skip` from Study → `study_command`
- `show answer` from Study → `study_command`
- `how are you` from Companion → `companion_chat`
- blocked Admin input → `unsupported`

Each adapted decision must include:

- `selected_path`
- `legacy_intent_name`
- `candidate_routes`
- `dispatch_plan`
- `dispatch_performed = false`
- `allowed_to_dispatch = false`

## Decision

Stage 8E proves the adapter can normalize real HTTP router dry-run output while live production routing remains disabled.

Stage 8F can decide whether to expose the contract-shaped object inside the disabled dry-run response under a nested compatibility key, without enabling live routing.
