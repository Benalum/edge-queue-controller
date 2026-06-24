# Stage 16 FC-O43-B reset/requeue only job117 no runtime no reset-failed

Date: 2026-06-24

## Purpose

FC-O43-B requeued only job117 after the FC-O43 runtime attempt left it stale running.

This stage changed job117 from `running` to `queued`, while preserving attempts and result evidence.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O43-A-R4.
- Base HEAD/origin/main: `69113f8`.
- Base tag: `controller-stage-16-fc-o43-a-r4-patch-worker-callsite-claimed-no-job-reset-no-runtime-2026-06-24`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O43_B_RESET_REQUEUE_ONLY_JOB117_NO_RUNTIME_NO_RESET_FAILED

## Mutation boundary

Allowed mutation:

- update only job117 status from `running` to `queued`.

Preserved:

- job117 attempts,
- job117 result rows,
- job117 prompt/model/job_type,
- job117 last_error,
- jobs108-111,
- jobs118-121.

Explicitly not performed:

- CT101 profile mutation,
- CT101 worker mutation,
- CT203 schema mutation,
- job insert,
- old job mutation,
- job reset/retry/delete/manual completion beyond job117 status requeue,
- manual job_results insert,
- job processing,
- runtime model call,
- worker/service/timer start,
- scheduler activation,
- persistent worker activation,
- service enable,
- timer enable,
- systemd unit write,
- daemon-reload,
- reset-failed,
- clearing failed-unit evidence,
- Docker mutation,
- Ollama mutation,
- Ollama generation/model endpoint calls,
- Ollama model pull,
- queue drain,
- CT/VM restart.

## CT101 posture

    worker_sha_fc_o43_b=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8
    profile_sha_fc_o43_b=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b
    active_exact_services_fc_o43_b=0
    active_general_services_fc_o43_b=0
    active_exact_timers_fc_o43_b=0
    active_general_timers_fc_o43_b=0
    failed_general_units_fc_o43_b=7

No failed-unit evidence was cleared.

## Job117 before and after

Before:

    job117_state_before_fc_o43_b=running,1,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job117_last_error_before_fc_o43_b=<none>

Update:

    job117_pre_update_fc_o43_b=running,1,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job117_rows_updated_fc_o43_b=1
    job117_post_update_fc_o43_b=queued,1,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job117_last_error_post_update_fc_o43_b=<none>

## Untouched jobs

Before:

    job108_state_before_fc_o43_b=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job109_state_before_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job110_state_before_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job111_state_before_fc_o43_b=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job118_state_before_fc_o43_b=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job119_state_before_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job120_state_before_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job121_state_before_fc_o43_b=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe

After:

    job108_state_post_update_fc_o43_b=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job109_state_post_update_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job110_state_post_update_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job111_state_post_update_fc_o43_b=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job118_state_post_update_fc_o43_b=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job119_state_post_update_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job120_state_post_update_fc_o43_b=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job121_state_post_update_fc_o43_b=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe

## CT203 DB validation

    quick_check_before_fc_o43_b=ok
    quick_check_before_update_fc_o43_b=ok
    quick_check_after_update_fc_o43_b=ok
    ct203_before_fc_o43_b_acceptance_pass=true
    ct203_fc_o43_b_requeue_acceptance_pass=true

## Decision

FC-O43-B restored job117 to queued state with attempts preserved.

Next recommended stage: FC-O43-C run only job117 again with the fixed worker.
