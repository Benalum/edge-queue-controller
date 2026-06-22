# Stage 16 E3Z-BL — Disabled CT203 Native SQLite Worker Endpoint Skeleton

## Result

Added an additive, disabled-by-default CT203-native internal worker API skeleton to `edge_controller.py`.

## Route skeleton

- GET /internal/edge-worker/summary
- POST /internal/edge-worker/workers/register
- POST /internal/edge-worker/workers/heartbeat
- POST /internal/edge-worker/jobs/claim
- POST /internal/edge-worker/jobs/{job_id}/complete
- POST /internal/edge-worker/jobs/{job_id}/fail

## Runtime posture

The route set is guarded by `EDGE_CT203_SQLITE_WORKER_API_ENABLED`.

Default state is disabled because the env flag is absent or false.

When disabled, routes return controlled refusal before performing work.

## Activation boundary

This stage does not restart CT203, enable the feature flag, alter schemas, start CT101 worker service, start Docker, call Ollama, mutate jobs, activate scheduler, or activate timer.

## Implementation scope

This stage adds the route skeleton and request contracts only.

Only the summary route has a SQLite read path after the disabled feature flag and token guard pass.

The register, heartbeat, claim, complete, and fail routes intentionally return skeleton-only `501` after the disabled feature flag and token guard pass.

## Next stage

Stage 16 E3Z-BM should perform runtime disabled-route refusal validation after a controlled CT203 controller restart or deployment step, still with `EDGE_CT203_SQLITE_WORKER_API_ENABLED=0`.
