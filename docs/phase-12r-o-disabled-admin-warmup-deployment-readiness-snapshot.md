# Phase 12R-O Disabled Admin Warmup Deployment-Readiness Snapshot

Phase 12R-O records whether the running local controller service appears to have picked up the disabled admin warmup endpoint/status contract from Phase 12R-M.

## Safety

This phase must not:

- Restart any service.
- Call `POST /admin/model-warmup`.
- Call Ollama directly.
- Call `/api/generate`.
- Call `/api/chat`.
- Warm or unload models.
- Start persistent lane workers.
- Enable router rollout.
- Change CT101 worker runtime.

## What this checks

The smoke performs:

- Static syntax check of `edge_controller.py`.
- Phase 12R-M smoke.
- Phase 12R-N smoke.
- Read-only local `GET /health`.
- Read-only local `GET /system/status`.
- Optional check for `model_memory_status.admin_model_warmup_endpoint` in the live status response.

## Interpretation

If the live status field is missing, the code is still safe; it means the running service has not loaded the new commit yet.

A later phase can decide whether to perform a guarded controller-only restart.
