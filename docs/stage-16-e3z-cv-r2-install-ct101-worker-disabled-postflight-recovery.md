# Stage 16 E3Z-CV-R2 — Install CT101 Worker Disabled Postflight Recovery

## Purpose

Recover from the Stage 16 E3Z-CV cleanup/postflight failure after the CT101 install-only mutation had already succeeded.

The original CV run successfully installed files and verified disabled posture, then failed during cleanup because a temporary CT101 cleanup variable was unset under `set -u`.

This R2 stage performs read-only live postflight validation and commits the record.

## Live mutation status from CV

The install-only mutation succeeded before the cleanup failure.

Observed from the original CV output:

- worker file installed
- README installed
- model profile installed
- disabled environment file installed
- systemd service file installed
- `systemctl daemon-reload` completed
- worker self-test passed
- disabled worker refused `--once` execution with `REFUSE_WORKER_DISABLED`
- old worker service remained inactive and masked
- new worker service remained inactive and disabled
- only `ollama` container remained running

## R2 validation scope

R2 is read-only for live systems and repo-only for documentation/smoke commit.

It validates:

- CT203 DB integrity remains ok
- jobs_total remains 43
- job_results_total remains 24
- jobs_status_running remains 0
- jobs 37 through 44 remain completed attempts=1 result_rows=1
- installed CT101 worker/profile/env/service files exist
- worker self-test passes against installed profile
- disabled env contains `EDGE_WORKER_ENABLED=0`
- disabled env contains `EDGE_CLAIM_POLICY=one_at_a_time`
- disabled env contains `EDGE_ALLOW_MODEL_CONCURRENCY=0`
- disabled worker refuses live `--once` execution
- old worker service remains inactive and masked
- new worker service remains inactive and disabled
- only `ollama` Docker container is running
- qwen2.5:0.5b and qwen3:0.6b remain present

## Installed CT101 paths

```text
/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
/opt/edge-queue-controller/ops/workers/README-ct101-minimal-ollama-worker.md
/etc/edge-ct101-worker/model-profiles.yaml
/etc/edge-ct101-worker/ct101-worker.env
/etc/systemd/system/edge-ct101-ollama-worker.service
/var/log/edge-ct101-worker/
```

## Final posture

Expected final posture after CV-R2:

- CT203 DB unchanged
- no running queue jobs
- old CT101 worker inactive and masked
- new CT101 worker inactive and disabled
- worker installed but disabled
- no model calls made
- no scheduler/timer activation
- no Docker/Ollama data mutation

## Next step

The next safe step is a no-apply activation design for a bounded one-shot worker start.

Activation must be separate from install and must require explicit approval.

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert new jobs.

Do not call models.

Do not delete models.

Do not prune Docker data.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not activate scheduler or timer.

Do not start broader `/opt/ai-platform` compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior in this stage.

Do not create or modify installed runtime files in R2.
