# Phase 12R-AC Disabled Future Warmup Pre-Execution Readiness Rollup

Phase 12R-AC adds a reusable pre-execution readiness rollup for the disabled future model warmup control plane.

## Purpose

This rollup confirms that all current warmup-related surfaces remain safe before any future phase adds a real runtime warmup action.

It validates:

- Admin auth boundary.
- Disabled admin warmup endpoint behavior.
- Optional authenticated-admin refusal smoke in no-token mode.
- Disabled future warmup helper skeleton.
- Disabled future warmup skeleton status attachment.
- Live disabled future warmup skeleton status.
- No warmup execution path is wired into `POST /admin/model-warmup`.

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

## Expected outcome

The control plane remains parked:

- `EDGE_MODEL_WARMUP_ACTION_ENABLED=1` is not set.
- `runtime_action_available` remains false.
- `would_call` remains `none`.
- Future skeletons may document `/api/generate`, but `execute_now` remains false.
- Unauthenticated admin warmup requests remain blocked before warmup refusal.
