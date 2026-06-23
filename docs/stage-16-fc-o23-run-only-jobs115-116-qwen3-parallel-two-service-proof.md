# Stage 16 FC-O23 run only jobs115-116 qwen3 parallel two-service proof

Date: 2026-06-23

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O23_RUN_ONLY_JOBS115_116_QWEN3_PARALLEL_TWO_SERVICE_PROOF_NO_BULK_NO_OLD_JOB_MUTATION

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O22.
- Base HEAD/origin/main: `f443134`.
- Base tag: `controller-stage-16-fc-o22-insert-fresh-jobs115-116-qwen3-json-parallel-proof-only-no-runtime-2026-06-23`.

## Mutation boundary

This stage ran exactly two queued qwen3 JSON proof jobs with two explicit service instances:

    edge-ct101-general-queue-job-worker@115.service
    edge-ct101-general-queue-job-worker@116.service

It did not:

- run bulk jobs,
- mutate old jobs,
- reset, retry, delete, or manually complete job105,
- mutate jobs106-114,
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

## CT101/Ollama runtime state

    profile_sha_fc_o23=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    worker_sha_fc_o23=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    OLLAMA_NUM_PARALLEL_before_fc_o23=2
    OLLAMA_NUM_PARALLEL_after_fc_o23=2
    OLLAMA_KEEP_ALIVE_before_fc_o23=30m
    dual_active_observed_fc_o23=true
    unit115_active_state_fc_o23=inactive
    unit116_active_state_fc_o23=inactive
    unit115_result_fc_o23=success
    unit116_result_fc_o23=success
    unit115_exec_main_status_fc_o23=0
    unit116_exec_main_status_fc_o23=0
    active_exact_services_after_fc_o23=0
    active_general_services_after_fc_o23=0
    active_exact_timers_after_fc_o23=0
    active_general_timers_after_fc_o23=0
    failed_general_units_after_fc_o23=6
    ct101_jobs115_116_two_service_fc_o23_acceptance_pass=true

## CT203 result summary

    quick_check_after_fc_o23=ok
    job115_status_after_fc_o23=completed
    job115_result_rows_after_fc_o23=1
    job115_response_sha_fc_o23=61067975d9dc6d70f9eb50d376f0de45996f343d8f8daffbb17bf43b76d33817
    job115_strict_json_pass_fc_o23=true
    job115_json_profile_id_fc_o23=qwen3_1_7b_candidate

    job116_status_after_fc_o23=completed
    job116_result_rows_after_fc_o23=1
    job116_response_sha_fc_o23=61067975d9dc6d70f9eb50d376f0de45996f343d8f8daffbb17bf43b76d33817
    job116_strict_json_pass_fc_o23=true
    job116_json_profile_id_fc_o23=qwen3_1_7b_candidate

    preserved_jobs_105_114_fc_o23=true
    ct203_post_fc_o23_parallel_acceptance_pass=true

## Response previews

job115:

    {"exact_match": true, "profile_id": "qwen3_1_7b_candidate", "stage": "stage-16-e3z-ec-worker-guards"}

job116:

    {"exact_match": true, "profile_id": "qwen3_1_7b_candidate", "stage": "stage-16-e3z-ec-worker-guards"}

## Preserved jobs

Job105 remained running with attempts=1 and result_rows=0.

Job106 remained completed with attempts=1 and result_rows=1.

Jobs107-111 remained queued with attempts=0 and result_rows=0.

Job112 remained completed with attempts=1 and result_rows=1.

Job113 remained completed with attempts=1 and result_rows=1.

Job114 remained completed with attempts=1 and result_rows=1.

## Decision

Jobs115 and 116 were the only runtime targets.

Both qwen3 JSON parallel proof jobs completed with strict JSON pass.

Ollama remained healthy with OLLAMA_NUM_PARALLEL=2.

CT203 remained the durable queue and claim authority.

Do not enable persistent workers or bulk queue draining yet.

The next safe step is a no-apply decision point:

- either keep qwen3:1.7b as the first reliable small structured-output model tier,
- or plan a similarly bounded two-job semantic proof for summary/router labels,
- or begin a separate profile-gate remediation plan for gemma/llama companion, study, flashcards, and safe-refusal jobs107-111.
