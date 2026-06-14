# Phase 12S-A Inspect-Only Warmup Execution Readiness Design

Phase 12S-A starts a new phase after the Phase 12R disabled warmup control-plane final rollup.

This is an inspect-only design phase.

It does not implement warmup execution.

## Current safe state

Phase 12R ended with:

- Disabled admin model warmup endpoint.
- Admin authentication boundary.
- Disabled future execution preview.
- Disabled activation guard report.
- Lightweight public /system/status snapshot.
- Final no-restart disabled control-plane rollup.
- Optional authenticated restart verification available through Phase 12R-AN.

## Boundary

The system must remain disabled until a future execution phase explicitly changes it.

This phase must not:

- Add a runtime executor.
- Add an Ollama call.
- Add a /api/generate call.
- Add a /api/chat call.
- Warm a model.
- Unload a model.
- Enable EDGE_MODEL_WARMUP_ACTION_ENABLED.
- Restart the controller.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.

## Future activation requirements

A future warmup execution phase must require all of these before execution can be considered:

- Authenticated admin request.
- Explicit confirm phrase WARMUP_MODEL_NOW.
- dry_run set to false.
- Requested model is allowlisted.
- EDGE_MODEL_WARMUP_ACTION_ENABLED set to 1.
- Runtime executor implemented in a separate phase.
- Ollama generation call allowed by a separate phase.
- Timeout and error handling defined.
- Response includes execution result metadata.
- Audit logging includes user, model, reason, guard outcomes, and result.
- Rollback path exists before enabling.

## Future executor design constraints

A future executor should be minimal and guarded.

Expected future behavior:

- Use one tiny prompt or minimal generation request only to load the model.
- Use stream false.
- Use a short timeout.
- Never unload models in the same phase.
- Never run from public /system/status.
- Never run from unauthenticated routes.
- Never run from public wrapper status.
- Never run automatically on page load.
- Never bypass the queue/power safety model without explicit design approval.

## Recommended next implementation sequence

Recommended future phases, if execution is pursued:

1. Add a disabled executor function skeleton that returns refusal only.
2. Add static smoke proving executor cannot call Ollama.
3. Add feature-flag gate with env disabled.
4. Add authenticated dry-run route metadata only.
5. Add live authenticated dry-run smoke.
6. Add minimal execution code behind all gates.
7. Add opt-in local authenticated execution smoke.
8. Add rollback and disable smoke.
9. Only then consider any UI/admin button.

## Stop point

Phase 12S-A is only the design readiness document and smoke.

It is safe to stop here before any execution work.
