# Stage 16 FC-O16 run only job106 qwen3 JSON one-shot

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O16_RUN_ONLY_JOB106_QWEN3_JSON_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O15.
- Base HEAD/origin/main: `89a1d98`.
- Base tag: `controller-stage-16-fc-o15-ollama-concurrency-discovery-no-apply-2026-06-23`.

## Mutation boundary

This stage ran only job106 through one CT101 general_queue service instance.

It did not:

- run jobs107-113,
- reset, retry, delete, or manually complete job105,
- mutate old jobs,
- manually insert job_results rows,
- apply schema changes,
- mutate CT101 profile,
- mutate Ollama concurrency,
- start timers,
- enable services or timers,
- reset failed units,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- mutate Docker,
- pull models,
- restart CTs or VMs.

## CT101 unit result

    unit=edge-ct101-general-queue-job-worker@106.service
    unit_active_state_fc_o16=inactive
    unit_result_fc_o16=success
    unit_exec_main_status_fc_o16=0
    profile_sha_fc_o16=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    active_exact_services_after_fc_o16=0
    active_general_services_after_fc_o16=0
    active_exact_timers_after_fc_o16=0
    active_general_timers_after_fc_o16=0
    failed_general_units_after_fc_o16=6

## CT203 job106 result

    quick_check_after_fc_o16=ok
    job106_status_after_fc_o16=completed
    job106_attempts_after_fc_o16=1
    job106_result_rows_after_fc_o16=1
    job106_result_text_column_fc_o16=response_json
    job106_response_sha_fc_o16=61067975d9dc6d70f9eb50d376f0de45996f343d8f8daffbb17bf43b76d33817
    job106_response_char_len_fc_o16=101
    job106_starts_with_thinking_fc_o16=false
    job106_contains_thinking_fc_o16=false
    job106_json_like_fc_o16=true
    job106_json_parse_pass_fc_o16=true
    job106_json_top_type_fc_o16=dict
    job106_json_keys_fc_o16=exact_match,profile_id,stage
    job106_strict_json_pass_fc_o16=true
    ct203_post_fc_o16_read_only_acceptance_pass=true

Response preview:

    {"exact_match": true, "profile_id": "qwen3_1_7b_candidate", "stage": "stage-16-e3z-ec-worker-guards"}

## Preserved jobs

Job105 remained running with attempts=1 and result_rows=0.

Jobs107-111 remained queued with attempts=0 and result_rows=0.

Job112 remained completed with attempts=1 and result_rows=1.

Job113 remained completed with attempts=1 and result_rows=1.

## Decision

Job106 was the only runtime target.

If job106_strict_json_pass_fc_o16=true, qwen3:1.7b JSON output is proven clean after the no-think flags.

If job106_strict_json_pass_fc_o16=false, stop and diagnose qwen3 JSON formatting before using qwen3 for structured outputs.

## Concurrency follow-up

Do not change Ollama concurrency in this runtime stage.

If job106_strict_json_pass_fc_o16=true, the next safe path is a no-apply bounded concurrency design using the FC-O15 findings, likely starting with `OLLAMA_NUM_PARALLEL=2` and CT203 still as durable queue authority.
