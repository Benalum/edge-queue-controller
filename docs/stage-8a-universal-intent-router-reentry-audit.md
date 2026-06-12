# Stage 8A Universal Intent Router Re-entry Audit

Stage 8A re-enters Universal Intent Router work after completing the Stage 7Z platform cleanup.

## Current Platform State

Before router work continues:

- public System status is online
- local System status is online
- queue is clean: queued 0, running 0, failed 0
- CT101 managed laptop queue worker is online
- old CT101 edge heartbeat is disabled
- stale legacy worker registry row was removed
- old Stage 5 failed queue test jobs were archived out of the active queue view
- legacy `/tick` scheduler is retired as a compatibility shim
- legacy scheduler timer is disabled/inactive
- modern power/remediation timers are active

## Router Safety State

The live Universal Intent Router dry-run endpoint remains disabled:

- `POST /api/router/dry-run` returns 404
- `POST /router/dry-run` returns 404

This means router work can continue without accidentally wiring production dispatch.

## Router Foundation Present

The router foundation files are present:

- `edge_router_schema.py`
- `edge_router_seed.py`
- `edge_router_lookup.py`

The controller references the disabled dry-run endpoint and router imports.

The router/controller compile check passed.

## Router Database State

SQLite contains the router foundation tables, including:

- `global_phrase_bank`
- `intent_definitions`
- `intent_routes`
- `router_feedback`
- `router_logs`
- `router_resolution_steps`
- `user_phrase_bank`

Seed phrases are present in `global_phrase_bank`.

Observed examples include:

- `next` → `study.card.next`
- `next card` → `study.card.next`
- `skip` → `study.card.skip`
- `pass` → `study.card.skip`
- `show answer` → `study.card.answer`

## Input Surface Notes

Current Study actions still call:

- `/api/study/session/command`

Current Companion/Chat surface remains separate.

The next router work should bridge the existing Study and Companion input surfaces through the router in a controlled, staged way.

## Decision

Proceed to Stage 8B as a source-only plan/contract for the router decision maker.

Stage 8B should not enable dispatch yet.

Recommended next goal:

- define the decision-maker contract for Study, Companion, and general chat inputs
- keep live router disabled
- keep outputs dry-run/shadow-only until a later controlled activation stage
