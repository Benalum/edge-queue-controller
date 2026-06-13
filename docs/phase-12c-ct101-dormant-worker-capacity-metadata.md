# Phase 12C CT101 Dormant Worker Capacity Metadata

Phase 12C adds dormant CT101 worker capacity metadata to the worker registration payload.

## Result

CT101 /opt/ai-platform was patched, verified, committed, tagged, and pushed.

- CT101 commit: 4d74475
- CT101 commit message: feat: add dormant worker capacity metadata phase 12c
- CT101 tag: ai-platform-phase-12c-dormant-worker-capacity-metadata-2026-06-13

## CT101 file changed

- ops/smoke/laptop_queue_bounded_synthetic_poller.py

## Metadata added

The CT101 bounded poller registration capabilities now include dormant metadata fields:

- max_jobs_per_run
- node_max_concurrent_jobs
- queue_lane
- supported_lanes
- supported_model_tiers
- allowed_models
- lane_capacity
- runtime_backend
- ollama_num_parallel

## Dormant safety state

No runtime concurrency was raised.
LAPTOP_QUEUE_MAX_JOBS_PER_RUN remains pinned to 1 by preflight.
LAPTOP_QUEUE_QUEUE_LANE remains unset in persistent env files.
Future capacity env keys remain unset in persistent env files.
OLLAMA_NUM_PARALLEL was not changed.
The CT101 worker service was not restarted during Phase 12C.
No schema changes were made.
Router rollout remains parked.

## Verification performed

Static Phase 12C markers were verified.
CT101 py_compile passed for the modified poller.
A dynamic payload test verified default dormant capacity metadata is safe.
A dynamic payload test verified optional env-derived capacity metadata is represented safely.
The CT101 worker service remained active.
Only the intended CT101 poller file was staged and committed.

## Existing unrelated CT101 dirty state left untouched

- modified docker-compose.yml
- modified ops/ct101-scripts/ai-platform-send-edge-heartbeat
- untracked .stage-backups/
- untracked ops/runtime/

## Next phase

Next phase should expose this registered worker capacity metadata in controller status/diagnostics before enabling any queue lane routing or raising concurrency.
