# Phase 12R-W Disabled Warmup Control-Plane Readiness Rollup

Phase 12R-W adds a reusable rollup smoke for the disabled model warmup control plane.

## Purpose

This phase confirms the current warmup control plane remains safe after adding:

- Disabled admin model warmup endpoint skeleton.
- Static endpoint contract checks.
- Guarded controller restart verification.
- Admin-auth boundary.
- Live unauthenticated auth-block behavior.
- Optional authenticated-admin refusal smoke.

## Safety

This phase must not:

- Restart any service.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable warmup execution.
- Call Ollama directly.
- Call `/api/generate`.
- Call `/api/chat`.
- Warm any model.
- Unload any model.
- Print bearer token values.

## Checks

The rollup verifies:

- `edge_controller.py` compiles.
- Static admin-auth boundary smoke passes.
- Live admin-auth boundary smoke passes.
- Optional authenticated-admin smoke passes in no-token mode.
- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1` is not set.
- `/health` returns HTTP 200.
- `/system/status` returns HTTP 200.
- Live status still exposes the disabled admin warmup endpoint snapshot.
- Unauthenticated `POST /admin/model-warmup` remains auth/admin blocked before warmup refusal.
