# Phase 12A CT101 Dormant Worker Queue Lane Patch

Phase 12A adds dormant CT101 worker-side queue_lane support.

## Result

CT101 /opt/ai-platform was patched, committed, tagged, and pushed.

- CT101 commit: bc829ca
- CT101 commit message: feat: add dormant worker queue lane support phase 12a
- CT101 tag: ai-platform-phase-12a-dormant-worker-queue-lane-2026-06-13

## Files changed on CT101

- backend/app/worker/laptop_queue_client.py
- ops/smoke/laptop_queue_bounded_synthetic_poller.py

## Behavior added

LaptopQueueClient.claim_one now accepts optional queue_lane.
The claim payload includes queue_lane only when queue_lane is explicitly provided.
The bounded poller reads optional LAPTOP_QUEUE_QUEUE_LANE from environment.
The bounded poller passes queue_lane to claim_one only through that optional env-derived value.

## Dormant safety state

LAPTOP_QUEUE_QUEUE_LANE remains unset in persistent CT101 env files.
The CT101 worker service was not restarted during Phase 12A.
LAPTOP_QUEUE_MAX_JOBS_PER_RUN remains pinned to 1 by preflight.
OLLAMA_NUM_PARALLEL was not changed.
No schema changes were made.
Router rollout remains parked.

## Verification performed

Static markers were verified in both CT101 target files.
CT101 py_compile passed for both target files.
A dynamic payload test verified backward-compatible claim payload when queue_lane is omitted.
A dynamic payload test verified queue_lane is included when explicitly provided.
The CT101 worker service remained active.
Only the two intended CT101 target files were staged and committed.

## Existing unrelated CT101 dirty state left untouched

- modified docker-compose.yml
- modified ops/ct101-scripts/ai-platform-send-edge-heartbeat
- untracked .stage-backups/
- untracked ops/runtime/

## Next phase

Next phase should source-map node concurrency and capacity fields before enabling queue_lane on CT101 or raising any worker concurrency.
