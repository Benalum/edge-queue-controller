# Stage 16 FC-O10-R2 job112 result recovery verify no further runtime

Date: 2026-06-23

## Approval

Approval phrase used for FC-O10 runtime:

    APPROVE_STAGE_16_FC_O10_RUN_ONLY_JOB112_QWEN3_SUMMARY_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION

## Recovery note

FC-O10 successfully ran job112 and completed the job. The FC-O10 script then failed during result extraction because it assumed job_results had an id column.

FC-O10-R2 performs verification only. It does not run job112 again.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O9.
- Base HEAD/origin/main: `0aba68f`.
- Base tag: `controller-stage-16-fc-o9-insert-fresh-job112-qwen3-summary-only-no-runtime-2026-06-23`.

## Mutation boundary

This recovery stage is read-only against CT203 and CT101.

It did not:

- run job112 again,
- run jobs106-111,
- reset, retry, delete, or manually complete job105,
- mutate old jobs,
- manually insert job_results rows,
- apply schema changes,
- mutate CT101 profile,
- start timers,
- enable services or timers,
- reset failed units,
- clear failed unit evidence,
- write systemd units,
- run daemon-reload,
- activate scheduler,
- enable persistent workers,
- mutate Docker,
- call Ollama endpoints,
- pull models,
- restart CTs or VMs.

## CT203 job112 result

    quick_check_fc_o10_r2=ok
    job112_status_fc_o10_r2=completed
    job112_attempts_fc_o10_r2=1
    job112_result_rows_fc_o10_r2=1
    job_results_columns_fc_o10_r2=job_id,model,response_text,response_json,error,created_at,updated_at
    job112_result_lookup_order_fc_o10_r2=rowid
    job112_result_text_column_fc_o10_r2=response_text
    job112_response_sha_fc_o10_r2=26e4867bd5ccda6d63c7a546ab1aa707586809eea0dde3ab88e70862128c4a9f
    job112_semantic_summary_pass_fc_o10_r2=true
    ct203_fc_o10_r2_read_only_acceptance_pass=true

Response preview:

    Thinking... Okay, let's see. The user wants me to write exactly one sentence using the words worker, request, result, and default-off. The example given is: "The worker handled the request, saved the result, and returned to default-off i idle posture." First, I need to make sure all four words are included. The original senten sentence uses "worker," "request," "result," and "default-off." The example example sentence is already using those words, but the user might want a di different sentence structure or maybe a different order. Wait, the example is already a valid sentence. But the user might want a va variation. Let me check the original sentence again. The example is correct correct, but maybe the user wants a different sentence. However, the user s says "write exactly one sentence using the words," so maybe the example is acceptable. But perhaps they want a different sentence. Alt

## Preserved jobs

    job105_status_fc_o10_r2=running
    job105_attempts_fc_o10_r2=1
    job105_result_rows_fc_o10_r2=0
    jobs106_111_remain_queued_attempts0_rows0=true

## CT101 default-off posture

    profile_sha_fc_o10_r2=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf
    active_exact_services_fc_o10_r2=0
    active_exact_timers_fc_o10_r2=0
    active_general_services_fc_o10_r2=0
    active_general_timers_fc_o10_r2=0
    failed_general_units_fc_o10_r2=6
    ct101_fc_o10_r2_read_only_acceptance_pass=true

## Decision

Job112 was the only runtime target and completed with one result row.

If job112_semantic_summary_pass_fc_o10_r2=true, qwen3:1.7b summary passed the post-FC-O8 queue proof and the next separately approved step can run job106 only.

If job112_semantic_summary_pass_fc_o10_r2=false, stop and diagnose summary semantics before running job106.
