# Stage 7K Runner No-Wire Runtime Isolation Guard

Stage 7K proves the Stage 7J authenticated shadow comparison runner remains isolated.

This stage does not change runtime behavior.

This stage does not wire the router into Study, Companion, or Chat.

## Purpose

Stage 7J intentionally created:

- `ops/compare/run-authenticated-shadow-comparison.py`

Stage 7K proves that runner exists only as a manual ops tool.

## Runner isolation

The runner must not be referenced from:

- `edge_controller.py`
- `frontend/`
- `backend/`
- `public_gateway.py`
- `ops/systemd/`

The runner must not be:

- imported by runtime handlers
- exposed as an HTTP endpoint
- referenced by frontend code
- referenced by backend runtime code
- referenced by the public gateway
- referenced by systemd units
- scheduled automatically

## Required runner behavior

The runner must remain safe:

- offline mode is the default
- offline mode generates sanitized artifacts
- authenticated execution requires an explicit flag
- authenticated execution requires explicit confirmation
- authenticated execution fails closed without auth
- auth values are not printed
- auth values are not stored

## Stage boundary

Stage 7K is a guardrail stage.

Stage 7K does not modify runtime handlers.

Stage 7K does not modify frontend behavior.

Stage 7K does not expose a new HTTP endpoint.

Stage 7K does not enable router dispatch.

Stage 7K does not enable router model calls.
