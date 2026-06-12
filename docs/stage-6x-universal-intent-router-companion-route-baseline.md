# Stage 6X Universal Intent Router Companion Route Baseline

Stage 6X captures the Companion and Chat route baseline before any Universal Intent Router wiring.

This stage does not change runtime behavior.

## Purpose

Before the router is connected to Companion or Chat, we need a clean baseline proving:

- existing Companion routes are still present
- existing queued Chat routes are still present
- existing Companion/Chat routes are still classified as router candidates
- the router dry-run endpoint remains disabled by default
- the Stage 6V Companion shadow adapter is still not wired into runtime
- no runtime files are modified by this stage

## Baseline Companion/Chat routes

The current Companion/Chat router-candidate routes are:

- `/api/companion/chat`
- `/api/chat/queued`

These remain owned by existing behavior during Stage 6X.

## Live probe policy

The Stage 6X smoke may probe these routes with unauthenticated empty JSON.

The probe is baseline-only and must not mutate state.

The probe records HTTP status codes but does not require one exact status code because existing behavior may be auth rejection or request validation.

The probe must not return:

- `404`
- `500`
- `502`
- `503`
- `504`

## Router state

The router must remain safe:

- dry-run endpoint disabled by default
- dispatch disabled
- model calls disabled
- no Companion handler replacement
- no Chat handler replacement
- no frontend wiring
- no gateway wiring

## Shadow adapter state

The Stage 6V helper may exist only in:

- `edge_intent_router.py`

It must not be called from:

- `edge_controller.py`
- `frontend/`
- `backend/`
- `public_gateway.py`
- `ops/systemd/`

## Stage boundary

Stage 6X is a baseline checkpoint.

Stage 6X does not wire the router into Companion.

Stage 6X does not wire the router into Chat.

Stage 6X does not modify Companion routes.

Stage 6X does not modify Chat routes.

Stage 6X does not enable dispatch.

Stage 6X does not enable model calls.
