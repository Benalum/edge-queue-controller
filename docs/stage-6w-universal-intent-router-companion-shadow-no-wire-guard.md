# Stage 6W Universal Intent Router Companion Shadow Adapter No-Wire Guard

Stage 6W adds a safety guard around the Stage 6V Companion shadow adapter helper.

This stage does not change runtime behavior.

## Purpose

Stage 6V added `_stage6v_companion_adapter_shadow` as a dry-run-only helper.

Stage 6W proves that helper is not accidentally wired into live runtime request handling.

## Required state

The helper may exist in:

- `edge_intent_router.py`

The helper must not be wired into:

- `edge_controller.py`
- `frontend/`
- `backend/`
- `public_gateway.py`
- `ops/systemd/`

## Safety

Stage 6W proves:

- the helper exists
- the helper remains isolated
- no HTTP route calls the helper
- no frontend code calls the helper
- no gateway code calls the helper
- no systemd config enables router behavior
- `/api/router/dry-run` remains disabled by default

## Stage boundary

Stage 6W is a guardrail stage.

Stage 6W does not modify Companion handlers.

Stage 6W does not modify Chat handlers.

Stage 6W does not wire the router into Companion.

Stage 6W does not enable dispatch.

Stage 6W does not enable model calls.
