# Stage 6S Universal Intent Router Study Route Baseline

Stage 6S captures the Study route baseline before any Universal Intent Router wiring.

This stage does not change runtime behavior.

## Purpose

Before the router is connected to Study, we need a clean baseline proving:

- existing Study routes are still present
- existing Study routes are still classified as router candidates
- the router dry-run endpoint remains disabled by default
- the Stage 6Q Study shadow adapter is still not wired into runtime
- no runtime files are modified by this stage

## Baseline Study routes

The current Study router-candidate routes are:

- `/api/study/intent/parse`
- `/api/study/session/command`

These remain owned by existing Study behavior during Stage 6S.

## Router state

The router must remain safe:

- dry-run endpoint disabled by default
- dispatch disabled
- model calls disabled
- no Study handler replacement
- no frontend wiring
- no gateway wiring

## Shadow adapter state

The Stage 6Q helper may exist only in:

- `edge_intent_router.py`

It must not be called from:

- `edge_controller.py`
- `frontend/`
- `backend/`
- `public_gateway.py`
- `ops/systemd/`

## Stage boundary

Stage 6S is a baseline checkpoint.

Stage 6S does not wire the router into Study.

Stage 6S does not modify Study routes.

Stage 6S does not enable dispatch.

Stage 6S does not enable model calls.
