# Stage 16 FC-O17 bounded Ollama concurrency design no-apply

Date: 2026-06-23

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O16.
- Base HEAD/origin/main: `65732c9`.
- Base tag: `controller-stage-16-fc-o16-run-only-job106-qwen3-json-one-shot-2026-06-23`.

## Mutation boundary

This stage is repo documentation and smoke only.

It does not mutate CT101, CT203, jobs, services, timers, systemd units, Docker, Ollama, scheduler state, persistent worker state, CTs, or VMs.

## Current proven model state

Stage 16 FC-O14 proved qwen3:1.7b summary hygiene after no-think flags.

Stage 16 FC-O16 proved qwen3:1.7b JSON structured output after no-think flags:

    job106_status_after_fc_o16=completed
    job106_attempts_after_fc_o16=1
    job106_result_rows_after_fc_o16=1
    job106_json_like_fc_o16=true
    job106_json_parse_pass_fc_o16=true
    job106_json_top_type_fc_o16=dict
    job106_json_keys_fc_o16=exact_match,profile_id,stage
    job106_strict_json_pass_fc_o16=true

Therefore qwen3:1.7b is now a viable small model candidate for router/light study structured queue work.

## Current concurrency discovery baseline

From Stage 16 FC-O15:

    OLLAMA_NUM_PARALLEL=1
    OLLAMA_MAX_LOADED_MODELS=<unset>
    OLLAMA_MAX_QUEUE=<unset>
    OLLAMA_CONTEXT_LENGTH=<unset>
    OLLAMA_KEEP_ALIVE=30m
    OLLAMA_MAX_TRANSFER_STREAMS=1
    Ollama version=0.30.3
    CT101 memory=31Gi total, 29Gi available
    /mnt/ollama-models=246G size, 226G available

Current profile throttles:

    qwen2.5:0.5b max_concurrent_model_calls=2
    qwen3:0.6b max_concurrent_model_calls=2
    qwen3:1.7b max_concurrent_model_calls=1
    gemma3:4b max_concurrent_model_calls=1
    gemma4:e4b max_concurrent_model_calls=1
    llama3.2:3b max_concurrent_model_calls=1

All candidate profiles currently use:

    claim_policy=one_at_a_time

## Architecture decision

CT203 must remain the durable queue and claim authority.

Ollama should not become the durable job queue.

Ollama may later handle bounded per-model request parallelism underneath CT101 workers, but CT203 must still own:

- durable job rows,
- claim lease authority,
- status transitions,
- retry/error records,
- result persistence,
- auditability.

## Proposed bounded concurrency target

First apply target, if approved later:

    OLLAMA_NUM_PARALLEL=2
    OLLAMA_KEEP_ALIVE=30m
    leave OLLAMA_MAX_LOADED_MODELS unset
    leave OLLAMA_MAX_QUEUE unset unless a later queue-pressure test proves a need
    do not change OLLAMA_CONTEXT_LENGTH initially
    do not change Docker image
    do not pull models

Rationale:

- It is the smallest meaningful increase from current single-parallel Ollama behavior.
- CT101 has enough RAM headroom for a conservative first trial.
- qwen3:1.7b is now clean for summary and JSON.
- Larger models are still unproven and should not receive increased concurrency yet.
- Keeping CT203 in charge avoids losing durable queue state.

## Worker/profile alignment

The first concurrency apply should not enable global bulk draining.

It should do one of these two safe patterns:

### Pattern A: Ollama-only concurrency first

- Set `OLLAMA_NUM_PARALLEL=2` in the Ollama container/service environment.
- Keep all CT101 profiles unchanged.
- Continue running explicit one-job service instances only.
- Validate no regression using a single qwen3 job.
- Later decide whether to raise qwen3:1.7b `max_concurrent_model_calls`.

This is the safest first mutation because the worker still serializes claims.

### Pattern B: Ollama plus qwen3 profile alignment

- Set `OLLAMA_NUM_PARALLEL=2`.
- Raise only qwen3:1.7b `max_concurrent_model_calls` from 1 to 2.
- Do not change gemma, llama, or qwen2.5 profiles.
- Do not start persistent workers.
- Validate with two explicit qwen3 queued jobs, not a broad queue drain.

Pattern A is recommended first.

## Apply-stage safety gates

A future FC-O18 apply stage should require explicit approval and should:

1. Verify repo clean and current HEAD.
2. Verify CT101 profile sha and worker sha.
3. Verify Ollama container is running and current `OLLAMA_NUM_PARALLEL=1`.
4. Backup any file or container config that will be changed.
5. Apply only the approved Ollama concurrency environment change.
6. Restart only the Ollama container/service if required by the approved change.
7. Verify Ollama container returns healthy.
8. Verify no job processing occurred during the change.
9. Verify CT101 exact/general timers and services are inactive.
10. Verify failed unit evidence count is unchanged.
11. Commit/tag/push docs and smoke.

## Runtime proof after apply

After the apply stage, do not run bulk.

Use a fresh qwen3 proof job:

- insert one fresh qwen3 summary or JSON proof job,
- run only that job,
- verify response hygiene/JSON parsing,
- preserve job105 and unproven model jobs.

Only after that should we test limited two-job qwen3 parallelism.

## Decision

Do not mutate concurrency yet.

Recommended next stage: explicit approval for a bounded Ollama-only apply stage that sets `OLLAMA_NUM_PARALLEL=2` without changing CT203 durable queue authority and without enabling persistent workers or bulk queue draining.
