# Stage 16 FC-O20 run only job114 qwen3 JSON post-concurrency one-shot

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O20_RUN_ONLY_JOB114_QWEN3_JSON_POST_CONCURRENCY_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O19.
- Base HEAD/origin/main: `a27b5e4`.
- Base tag: `controller-stage-16-fc-o19-insert-fresh-job114-qwen3-json-post-concurrency-proof-only-no-runtime-2026-06-23`.

## Mutation boundary

This stage ran only job114 through one CT101 general_queue service instance.

It did not:

- run bulk jobs,
- mutate old jobs,
- reset, retry, delete, or manually complete job105,
- mutate jobs106-113,
- manually insert job_results rows,
- apply schema changes,
- mutate CT101 profile,
- mutate CT101 worker code,
- mutate Ollama concurrency,
- start timers,
- enable services or timers,
- reset failed units,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- pull models,
- restart CTs or VMs.

## CT101 unit result

    unit=edge-ct101-general-queue-job-worker@114.service
    unit_active_state_fc_o20=inactive
    unit_result_fc_o20=success
    unit_exec_main_status_fc_o20=0
    profile_sha_fc_o20=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    worker_sha_fc_o20=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    OLLAMA_NUM_PARALLEL_before_fc_o20=2
    OLLAMA_NUM_PARALLEL_after_fc_o20=2
    active_exact_services_after_fc_o20=0
    active_general_services_after_fc_o20=0
    active_exact_timers_after_fc_o20=0
    active_general_timers_after_fc_o20=0
    failed_general_units_after_fc_o20=6
    ct101_job114_one_shot_fc_o20_acceptance_pass=true

## CT203 job114 result

    quick_check_after_fc_o20=ok
    job114_status_after_fc_o20=completed
    job114_attempts_after_fc_o20=1
    job114_result_rows_after_fc_o20=1
    job114_result_text_column_fc_o20=response_json
    job114_response_sha_fc_o20=61067975d9dc6d70f9eb50d376f0de45996f343d8f8daffbb17bf43b76d33817
    job114_response_char_len_fc_o20=101
    job114_starts_with_thinking_fc_o20=false
    job114_contains_thinking_fc_o20=false
    job114_json_like_fc_o20=true
    job114_json_parse_pass_fc_o20=true
    job114_json_top_type_fc_o20=dict
    job114_json_keys_fc_o20=exact_match,profile_id,stage
    job114_strict_json_pass_fc_o20=true
    ct203_post_fc_o20_read_only_acceptance_pass=true

Response preview:

    {"exact_match": true, "profile_id": "qwen3_1_7b_candidate", "stage": "stage-16-e3z-ec-worker-guards"}

## Preserved jobs

Job105 remained running with attempts=1 and result_rows=0.

Job106 remained completed with attempts=1 and result_rows=1.

Jobs107-111 remained queued with attempts=0 and result_rows=0.

Job112 remained completed with attempts=1 and result_rows=1.

Job113 remained completed with attempts=1 and result_rows=1.

## Decision

Job114 was the only runtime target.

If job114_strict_json_pass_fc_o20=true, qwen3:1.7b JSON remained clean after OLLAMA_NUM_PARALLEL=2.

If job114_strict_json_pass_fc_o20=false, stop and diagnose before any parallel two-job test.

Do not enable persistent workers or bulk queue draining yet.

The next safe step after a pass is a no-apply two-job qwen3 parallel proof design, then fresh two-job insert, then a separately approved two-service bounded runtime proof.
