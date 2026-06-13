# Phase 12L-C Controlled Model-Tiny Lane Activation Test

Phase 12L-C completed the first controlled runtime test of a lane-specific CT101 worker.

## Result

The controlled `model-tiny` lane activation test passed.

Test job:

- Job id: `phase12l-tiny-job-7ddc80a044438855`
- Queue lane: `model-tiny`
- Model tier: `tiny`
- Model lane: `model-tiny`
- Requested model: `qwen3:0.6b`
- Assigned worker: `ct101-stage5g21-managed-browser-model-tiny`
- Status: `complete`
- Worker result model: `qwen3:0.6b`
- Worker result source: `ct101_bounded_ollama_poller`
- Worker result reply: `tiny lane ok`
- Elapsed seconds: `1.625`

## Runtime sequence

The controlled test safely performed this sequence:

1. Confirmed no active queued/running `ollama_chat` jobs.
2. Confirmed tiny lane env and preflight were source-safe.
3. Stopped the primary unfiltered worker.
4. Reset failed lane-worker state.
5. Started only `ai-platform-laptop-queue-worker@model-tiny.service`.
6. Verified tiny worker registered with:
   - `queue_lane=model-tiny`
   - `allowed_models=["qwen3:0.6b"]`
   - `supported_lanes=["model-tiny"]`
   - `supported_model_tiers=["tiny"]`
7. Inserted one controlled `model-tiny` job.
8. Verified the tiny worker claimed and completed the job.
9. Stopped lane workers.
10. Restarted the primary worker.
11. Verified no active queued/running jobs remained.
12. Verified router rollout remained parked.

## Safety state after test

After the test:

- Primary worker service was active.
- Tiny lane service was inactive.
- Small lane service was inactive.
- No active queued/running `ollama_chat` jobs remained.
- Router rollout remained parked.

## Meaning

This proves the dormant lane-worker template, lane env override, worker registration metadata, queue-lane claim filter, and `qwen3:0.6b` execution path work together for a controlled `model-tiny` job.

## Important limitation

This was a controlled single-lane test.

It does not yet enable persistent lane workers.
It does not yet enable tiny/small concurrent workers.
It does not yet change public routing behavior.
