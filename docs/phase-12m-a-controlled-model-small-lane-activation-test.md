# Phase 12M-A Controlled Model-Small Lane Activation Test

Phase 12M-A completed the first controlled runtime test of the `model-small` CT101 lane worker.

## Result

The controlled `model-small` lane activation test passed.

Test job:

- Job id: `phase12m-small-job-e8ec453de2951427`
- Queue lane: `model-small`
- Model tier: `small`
- Model lane: `model-small`
- Requested model: `qwen3:1.7b`
- Assigned worker: `ct101-stage5g21-managed-browser-model-small`
- Status: `complete`
- Worker result model: `qwen3:1.7b`
- Worker result source: `ct101_bounded_ollama_poller`
- Worker result reply: `small lane ok`
- Elapsed seconds: `11.606`

## Runtime sequence

The controlled test safely performed this sequence:

1. Confirmed no active queued/running `ollama_chat` jobs.
2. Confirmed small lane env and preflight were source-safe.
3. Stopped the primary unfiltered worker.
4. Reset failed lane-worker state.
5. Started only `ai-platform-laptop-queue-worker@model-small.service`.
6. Verified small worker registered with:
   - `queue_lane=model-small`
   - `allowed_models=["qwen3:1.7b", "llama3.2:3b"]`
   - `supported_lanes=["model-small"]`
   - `supported_model_tiers=["small"]`
7. Inserted one controlled `model-small` job.
8. Verified the small worker claimed and completed the job.
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

This proves the dormant lane-worker template, small-lane env override, worker registration metadata, queue-lane claim filter, and `qwen3:1.7b` execution path work together for a controlled `model-small` job.

## Important limitation

This was a controlled single-lane test.

It does not yet enable persistent lane workers.
It does not yet enable tiny/small concurrent workers.
It does not yet change public routing behavior.
