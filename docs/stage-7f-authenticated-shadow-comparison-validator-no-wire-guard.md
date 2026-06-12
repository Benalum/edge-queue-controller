# Stage 7F Authenticated Shadow Comparison Validator No-Wire Guard

Stage 7F adds a no-wire guard around the Stage 7E artifact validator.

This stage does not change runtime behavior.

## Purpose

Stage 7E added an offline validator for future authenticated shadow comparison artifacts.

Stage 7F proves that validator is not wired into runtime request handling.

## Required state

The validator may exist in:

- `ops/validate/validate-authenticated-shadow-comparison-artifact.py`

The validator must not be referenced from:

- `edge_controller.py`
- `frontend/`
- `backend/`
- `public_gateway.py`
- `ops/systemd/`

## Safety

The validator must remain offline-only.

It must not:

- authenticate
- call HTTP routes
- dispatch router actions
- call models
- mutate Study state
- mutate Companion or Chat state
- mutate Calendar state
- mutate Profile state
- touch admin, power, worker, queue, or system behavior

## Stage boundary

Stage 7F is a guardrail stage.

Stage 7F does not expose a new HTTP endpoint.

Stage 7F does not modify runtime handlers.

Stage 7F does not modify frontend behavior.

Stage 7F does not enable router dispatch.

Stage 7F does not enable router model calls.
