# Stage 16 FC-O21 two-job qwen3 parallel proof design no-apply

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O21_TWO_JOB_QWEN3_PARALLEL_PROOF_DESIGN_NO_APPLY

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O20.
- Base HEAD/origin/main: `c1c4ec9`.
- Base tag: `controller-stage-16-fc-o20-run-only-job114-qwen3-json-post-concurrency-one-shot-2026-06-23`.

## Mutation boundary

This stage is repo documentation and smoke only.

It does not mutate CT101, CT203, jobs, services, timers, systemd units, Docker, Ollama, scheduler state, persistent worker state, CTs, VMs, or the queue.

## Proven state before parallel proof

### qwen3:1.7b behavior

qwen3:1.7b is now proven for:

- summary hygiene after no-think/hidethinking flags,
- JSON output before Ollama concurrency change,
- JSON output after `OLLAMA_NUM_PARALLEL=2`.

Relevant completed proofs:

    FC-O14: job113 summary hygiene passed
    FC-O16: job106 JSON strict pass
    FC-O20: job114 JSON strict pass after OLLAMA_NUM_PARALLEL=2

Latest post-concurrency proof:

    job114_status_after_fc_o20=completed
    job114_attempts_after_fc_o20=1
    job114_result_rows_after_fc_o20=1
    job114_json_like_fc_o20=true
    job114_json_parse_pass_fc_o20=true
    job114_json_top_type_fc_o20=dict
    job114_json_keys_fc_o20=exact_match,profile_id,stage
    job114_strict_json_pass_fc_o20=true

### Ollama state

From FC-O18/FC-O20:

    OLLAMA_NUM_PARALLEL=2
    OLLAMA_KEEP_ALIVE=30m
    OLLAMA_MAX_LOADED_MODELS=<unset>
    OLLAMA_MAX_QUEUE=<unset>
    OLLAMA_CONTEXT_LENGTH=<unset>
    Ollama container=running/healthy

### Queue/worker authority

CT203 remains the durable queue and claim authority.

Ollama does not own durable job state.

Persistent workers remain off.

Bulk queue draining remains prohibited.

## Parallel proof objective

Prove that two explicitly targeted qwen3:1.7b jobs can run at the same time under:

    OLLAMA_NUM_PARALLEL=2

without:

- enabling persistent workers,
- draining the queue,
- mutating unrelated jobs,
- regressing qwen3 output hygiene,
- losing CT203 durable queue authority,
- clearing failed unit evidence.

## Proposed job plan

Use two fresh qwen3 JSON proof jobs:

| Planned job | Source clone | Job type | Model | Purpose |
|---:|---:|---|---|---|
| 115 | 106 or 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | first parallel JSON proof |
| 116 | 106 or 114 | stage16_fc_json_semantic_probe | qwen3:1.7b | second parallel JSON proof |

Both jobs should be inserted in a separate no-runtime stage.

Recommended next stage:

    FC-O22 insert fresh jobs115-116 qwen3 JSON parallel proof only no-runtime

Required insert-stage properties:

- backup CT203 DB before insert,
- insert exactly jobs115 and 116,
- set both to `queued`,
- attempts=0,
- result_rows=0,
- preserve job105,
- preserve jobs106-114,
- no CT101 mutation,
- no runtime,
- no job_results insert,
- no scheduler/persistent worker activation.

## Runtime proof plan

After insertion, run exactly two explicit service instances:

    edge-ct101-general-queue-job-worker@115.service
    edge-ct101-general-queue-job-worker@116.service

The runtime stage should start both service instances back-to-back in the same bounded command block, then poll both until inactive.

Recommended runtime stage:

    FC-O23 run only jobs115-116 qwen3 parallel two-service proof

Required runtime-stage properties:

- explicit approval required,
- verify `OLLAMA_NUM_PARALLEL=2` before runtime,
- verify qwen3 profile and worker sha before runtime,
- verify exact/general timers inactive before runtime,
- verify no persistent workers active,
- start only job115 and job116 service instances,
- do not run job107-114,
- do not reset job105,
- do not bulk drain the queue,
- do not modify profiles,
- do not modify Ollama concurrency,
- do not reset failed unit evidence.

## Pass criteria

The two-job parallel proof passes only if all are true:

1. Both units exit successfully.
2. Both jobs complete with attempts=1.
3. Each job has exactly one result row.
4. Both result payloads parse as JSON.
5. Both result payloads have no visible thinking.
6. Both result payloads have no `<think>` or `</think>` markers.
7. Both result payloads have expected keys:
   - `exact_match`
   - `profile_id`
   - `stage`
8. Both result payloads show `profile_id=qwen3_1_7b_candidate`.
9. Jobs107-114 remain untouched.
10. Job105 remains running/stale and untouched.
11. CT101 exact/general timers remain inactive.
12. Persistent workers remain inactive.
13. Failed unit evidence count is unchanged.
14. Ollama remains running/healthy with `OLLAMA_NUM_PARALLEL=2`.
15. CT203 quick_check remains ok.

## Failure handling

If either job fails, times out, or returns invalid output:

- stop,
- do not run additional jobs,
- do not enable persistent workers,
- do not raise concurrency,
- preserve failed unit evidence,
- inspect unit journals and CT203 result rows read-only,
- document the failure and rollback options.

Rollback should remain simple:

- remove or stop using the FC-O18 Compose override,
- return Ollama to `OLLAMA_NUM_PARALLEL=1`,
- recreate/restart only the Ollama service if needed,
- do not mutate queue rows unless separately approved.

## Decision

Do not run parallel jobs in this design stage.

Next recommended step is FC-O22: insert exactly two fresh qwen3 JSON proof jobs, jobs115 and 116, with no runtime.
