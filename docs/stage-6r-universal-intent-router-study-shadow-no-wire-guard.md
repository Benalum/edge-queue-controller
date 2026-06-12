# Stage 6R Universal Intent Router Study Shadow Adapter No-Wire Guard

Stage 6R adds a safety guard around the Stage 6Q Study shadow adapter helper.

This stage does not change runtime behavior.

## Purpose

Stage 6Q added `_stage6q_study_adapter_shadow` as a dry-run-only helper.

Stage 6R proves that helper is not accidentally wired into live runtime request handling.

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

Stage 6R proves:

- the helper exists
- the helper remains isolated
- no HTTP route calls the helper
- no frontend code calls the helper
- no gateway code calls the helper
- no systemd config enables router behavior
- `/api/router/dry-run` remains disabled by default

## Stage boundary

Stage 6R is a guardrail stage.

Stage 6R does not modify Study handlers.

Stage 6R does not wire the router into Study.

Stage 6R does not enable dispatch.

Stage 6R does not enable model calls.
