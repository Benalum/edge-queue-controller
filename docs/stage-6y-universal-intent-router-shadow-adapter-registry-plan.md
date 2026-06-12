# Stage 6Y Universal Intent Router Shadow Adapter Registry Plan

Stage 6Y defines a future registry plan for Universal Intent Router shadow adapters.

This stage is docs-only.

This stage does not change runtime behavior.

## Purpose

Study and Companion now both have shadow adapter plans, helpers, no-wire guards, and live route baselines.

Stage 6Y defines how those shadow adapters should eventually be managed by one registry before any runtime wiring is allowed.

## Current shadow adapters

### Study

Study shadow adapter:

- helper: `_stage6q_study_adapter_shadow`
- helper file: `edge_intent_router.py`
- plan stage: 6P
- helper stage: 6Q
- no-wire guard stage: 6R
- route baseline stage: 6S
- HTTP probe plan stage: 6T

Study candidate routes:

- `/api/study/intent/parse`
- `/api/study/session/command`

### Companion

Companion shadow adapter:

- helper: `_stage6v_companion_adapter_shadow`
- helper file: `edge_intent_router.py`
- plan stage: 6U
- helper stage: 6V
- no-wire guard stage: 6W
- route baseline stage: 6X

Companion candidate routes:

- `/api/companion/chat`
- `/api/chat/queued`

## Future registry requirements

A future registry should:

- provide a single lookup by adapter id
- keep helpers dry-run-only until a future explicit wiring stage
- require source/surface policy
- require confirmation policy
- require decision trace
- keep dispatch disabled by default
- keep model calls disabled by default unless a future model policy explicitly allows them

## Required no-wire state

During Stage 6Y, the registry plan must not be wired into:

- `edge_controller.py`
- `frontend/`
- `backend/`
- `public_gateway.py`
- `ops/systemd/`

## Stage boundary

Stage 6Y only creates a registry plan and smoke coverage.

Stage 6Y does not create a runtime registry.

Stage 6Y does not wire the router into Study.

Stage 6Y does not wire the router into Companion.

Stage 6Y does not expose any new HTTP endpoint.

Stage 6Y does not enable dispatch.

Stage 6Y does not enable model calls.
