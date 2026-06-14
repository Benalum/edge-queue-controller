# Phase 12R-U Live Admin-Auth Bound Warmup Smoke

Phase 12R-U updates the reusable live warmup endpoint smoke after the Phase 12R-S/T admin-auth boundary.

## Reason

Phase 12R-Q verified that unauthenticated `POST /admin/model-warmup` returned the disabled warmup refusal contract.

After Phase 12R-S and Phase 12R-T, unauthenticated callers should no longer reach that warmup refusal. They should be blocked by the auth/admin boundary first.

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

## Checks

The smoke verifies:

- `edge_controller.py` compiles.
- Phase 12R-S static admin boundary smoke passes.
- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1` is not set.
- `/health` returns HTTP 200.
- `/system/status` returns HTTP 200.
- Live status still exposes the disabled endpoint snapshot.
- Unauthenticated `POST /admin/model-warmup` is blocked with HTTP 401 or 403.
- The unauthenticated response does not expose warmup refusal contract internals.

Phase 12R-Q is superseded and should delegate to this smoke.
