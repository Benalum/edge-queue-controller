# Stage 16 FC-O42-R2 insert fresh product-visible-output probes no runtime

Date: 2026-06-24

## Purpose

FC-O42-R2 inserted fresh queued product-visible-output probes after FC-O40-B-R4, FC-O40-C, and FC-O41 made the worker and product profiles ready.

The first FC-O42 attempt failed safely before insert because it assumed an optional `jobs.response_json` column. R2 used schema-adaptive duplicate detection based on required columns only.

This stage did not run workers or process jobs.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O41.
- Base HEAD/origin/main: `6297bae`.
- Base tag: `controller-stage-16-fc-o41-product-profile-policy-update-only-no-job-processing-2026-06-23`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O42_INSERT_FRESH_PRODUCT_VISIBLE_OUTPUT_PROBES_NO_RUNTIME_NO_RESET_FAILED

## Mutation boundary

Allowed mutation:

- CT203 DB insert of fresh queued probe jobs only.

Explicitly not performed:

- CT101 profile mutation,
- CT101 worker mutation,
- job processing,
- worker/service/timer start,
- scheduler activation,
- persistent worker activation,
- model call,
- Ollama generation/model endpoint calls,
- Ollama model pull,
- Docker mutation,
- reset-failed,
- clearing failed-unit evidence,
- old job reset/retry/delete/manual completion,
- job_results insert,
- queue drain,
- CT/VM restart.

## Readiness verified

    worker_sha_fc_o42_r2=1809af3a97e5b357d47b4ce3728ca4e5e8f6692de89e920b881f7b3b58b820d3
    profile_sha_fc_o42_r2=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b
    profile_readiness_fc_o42_r2=true
    ct101_readiness_fc_o42_r2=true

Target profile policies:

    gemma4_product_candidate=product_visible_output_v1
    gemma3_companion_candidate=product_visible_output_v1
    llama32_safe_refusal_candidate=product_visible_output_v1

## Schema handling

    jobs_schema_columns_fc_o42_r2=attempts,created_at,forwarded_at,id,job_type,last_error,prompt,requested_model,status,updated_at,user_id

R2 avoided optional-column assumptions and used exact `job_type/requested_model/prompt` matching for duplicate detection.

## Inserted jobs

    inserted_fc_o42_r2_job_ids=117,118,119,120,121

Inserted fresh queued probes:

    inserted_fc_o42_r2_job id=117 label=gemma4_companion_product_visible model=gemma4:e4b job_type=stage16_fc_companion_chat_semantic_probe prompt_sha=fee200555520f527a42a9939d7451e0df0d8598a837a8f81cb55af52cd0e361d
    inserted_fc_o42_r2_job id=118 label=gemma3_companion_product_visible model=gemma3:4b job_type=stage16_fc_companion_chat_semantic_probe prompt_sha=3ce49730642f10bf95b6dd0a60b8cc49dfedf662eaf3556ff25ac40dbaa25f78
    inserted_fc_o42_r2_job id=119 label=gemma4_study_tutor_product_visible model=gemma4:e4b job_type=stage16_fc_study_tutor_semantic_probe prompt_sha=09e82bef89af18bdef213999158af72fe2713e304808e5cd9e601b3e26e2c1e6
    inserted_fc_o42_r2_job id=120 label=gemma4_flashcards_product_visible model=gemma4:e4b job_type=stage16_fc_flashcards_semantic_probe prompt_sha=201d6dde3a64879bd203b8c1990563916922aa8aad25d7940612131a75fe83e4
    inserted_fc_o42_r2_job id=121 label=llama32_safe_refusal_product_visible model=llama3.2:3b job_type=stage16_fc_safe_refusal_semantic_probe prompt_sha=2763fb1fbcd9941fccc4d9808d9aa84f46d79b4b36236d2904b693276ae2e3bb

New job states:

    new_job117_state_after_fc_o42_r2=queued,0,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    new_job118_state_after_fc_o42_r2=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    new_job119_state_after_fc_o42_r2=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    new_job120_state_after_fc_o42_r2=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    new_job121_state_after_fc_o42_r2=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe

## Historical stale jobs preserved

Jobs108-111 were intentionally preserved as historical stale probes and were not reset or reused.

Before insert:

    old_job108_state_before_fc_o42_r2=queued,0,0
    old_job109_state_before_fc_o42_r2=queued,0,0
    old_job110_state_before_fc_o42_r2=queued,0,0
    old_job111_state_before_fc_o42_r2=queued,0,0

After insert:

    old_job108_state_after_fc_o42_r2=queued,0,0
    old_job109_state_after_fc_o42_r2=queued,0,0
    old_job110_state_after_fc_o42_r2=queued,0,0
    old_job111_state_after_fc_o42_r2=queued,0,0

## CT101 state

    active_exact_services_fc_o42_r2=0
    active_general_services_fc_o42_r2=0
    active_exact_timers_fc_o42_r2=0
    active_general_timers_fc_o42_r2=0
    failed_general_units_fc_o42_r2=6

No failed-unit evidence was cleared.

## CT203 DB validation

    quick_check_before_insert_fc_o42_r2=ok
    quick_check_after_insert_fc_o42_r2=ok
    ct203_fc_o42_r2_insert_acceptance_pass=true

## Decision

FC-O42-R2 created a fresh product-visible-output probe set.

Next recommended stage: FC-O43 run one fresh gemma4 Companion probe only, using the inserted gemma4 Companion job from this stage.
