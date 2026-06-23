# Stage 16 FC-O36-R3 recover job107 completed after timeout read-only

Date: 2026-06-23

## Why this recovery exists

FC-O36 timed out at the PPB layer while entering the PVESO discovery step, but later read-only CT203 evidence showed the one-shot job107 service did execute and complete after the visible PPB timeout.

FC-O36-R2 used an incorrect no-runtime assumption and failed because job107 was no longer queued.

FC-O36-R3 is the read-only recovery/classification checkpoint for the completed job107 result.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O35-R2.
- Base HEAD/origin/main before this recovery: `267dd5f`.
- Base tag: `controller-stage-16-fc-o35-r2-recover-remaining-loader-schema-repair-no-further-mutation-2026-06-23`.

## Recovery mutation boundary

This recovery performed only:

- read-only CT203 verification and result classification,
- read-only CT101 verification,
- repo docs/smoke/commit/tag/push.

It did not:

- write CT101 profile,
- mutate CT101 worker code,
- write CT203 DB,
- insert jobs,
- mutate jobs,
- reset, retry, delete, or manually complete jobs,
- insert job_results rows,
- run jobs again,
- start services,
- enable services or timers,
- start timers,
- write systemd units,
- run daemon-reload,
- reset failed units,
- clear failed unit evidence,
- mutate Docker,
- mutate Ollama,
- call Ollama generation/model endpoints,
- pull models,
- activate scheduler,
- activate persistent workers,
- drain the queue,
- restart CTs or VMs.

## CT203 job107 result

    quick_check_fc_o36_r3=ok
    job107_job_type_fc_o36_r3=stage16_fc_companion_chat_semantic_probe
    job107_requested_model_fc_o36_r3=gemma4:e4b
    job107_status_fc_o36_r3=completed
    job107_attempts_fc_o36_r3=1
    job107_result_rows_fc_o36_r3=1
    job107_result_text_column_fc_o36_r3=response_json
    job107_response_sha_fc_o36_r3=b306e13d87708c5ccd08e0f8d43da92d402c516cf76085795a3fae25206ebd79
    job107_response_char_len_fc_o36_r3=105
    job107_contains_thinking_fc_o36_r3=false
    job107_contains_hidden_markers_fc_o36_r3=false
    job107_mechanical_pass_fc_o36_r3=true
    job107_output_hygiene_pass_fc_o36_r3=true
    job107_semantic_pass_fc_o36_r3=false
    job107_product_surface_candidate_fc_o36_r3=false
    job107_completed_after_timeout_fc_o36_r3=true
    preserved_unrelated_jobs_fc_o36_r3=true
    ct203_fc_o36_r3_read_only_acceptance_pass=true

## Response preview

    {"exact_match": true, "profile_id": "gemma4_product_candidate", "stage": "stage-16-e3z-ec-worker-guards"}

## Preserved jobs

Job105 remained running attempts=1 rows=0.

Job106 remained completed attempts=1 rows=1.

Jobs108-111 remained queued attempts=0 rows=0.

Jobs112-116 remained completed attempts=1 rows=1.

## CT101/Ollama verification

    profile_sha_fc_o36_r3=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    worker_sha_fc_o36_r3=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    OLLAMA_NUM_PARALLEL_fc_o36_r3=2
    OLLAMA_KEEP_ALIVE_fc_o36_r3=30m
    ollama_container_state_fc_o36_r3=running
    ollama_container_health_fc_o36_r3=healthy
    active_exact_services_fc_o36_r3=0
    active_general_services_fc_o36_r3=0
    active_exact_timers_fc_o36_r3=0
    active_general_timers_fc_o36_r3=0
    failed_general_units_fc_o36_r3=6
    unit107_latest_exec_start_fc_o36_r3=<none>
    unit107_latest_exec_exit_fc_o36_r3=<none>
    unit107_latest_exec_status_fc_o36_r3=0
    unit107_latest_result_fc_o36_r3=success
    unit107_latest_active_state_fc_o36_r3=inactive
    ct101_fc_o36_r3_read_only_acceptance_pass=true

FC-O36-R3 did not reset-failed. Any failed-unit count change is a natural consequence of the prior job107 service execution, not a reset-failed action.

## Interpretation

Mechanical pass means job107 completed with attempts=1 and one result row.

Output hygiene pass means the output was non-empty and did not expose visible thinking, hidden thinking markers, traceback text, or worker refusal text.

Semantic pass means the output looked like a usable companion-chat response rather than merely echoing an exact marker or diagnostic JSON.

Product surface candidate means the result is good enough to continue toward the Companion surface with this model.

## Decision

Job107 did complete after the FC-O36 PPB timeout.

Next recommended stage depends on classification:

- If job107_product_surface_candidate_fc_o36_r3=true, continue to FC-O37 run only job108 gemma3 companion-chat one-shot.
- If false, stop and diagnose the gemma4 companion output quality before running more gemma jobs.
