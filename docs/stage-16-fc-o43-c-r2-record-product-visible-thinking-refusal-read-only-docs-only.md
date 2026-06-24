# Stage 16 FC-O43-C-R2 record product visible thinking refusal read-only docs only

Date: 2026-06-24

## Purpose

FC-O43-C-R2 records the failed FC-O43-C runtime attempt without changing CT203 or CT101.

The fixed worker no longer failed with the prior Python callsite bug. It reached the product-visible-output validator and refused the gemma4 Companion output with:

    REFUSE_PRODUCT_VISIBLE_THINKING

This means the product gate is working: visible model thinking is blocked before writing user-visible output.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O43-B.
- Base HEAD/origin/main: `5418317`.
- Base tag: `controller-stage-16-fc-o43-b-reset-requeue-only-job117-no-runtime-no-reset-failed-2026-06-24`.

FC-O43-C itself failed before docs/commit and therefore has no checkpoint tag.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O43_C_R2_RECORD_PRODUCT_VISIBLE_THINKING_REFUSAL_READ_ONLY_DOCS_ONLY_NO_RESET_FAILED

## Mutation boundary

Allowed actions:

- read-only CT203 DB inspection,
- read-only CT101 worker/profile/service/journal inspection,
- repo docs/smoke/commit/tag/push.

Explicitly not performed:

- CT203 DB write,
- CT101 profile mutation,
- CT101 worker mutation,
- CT203 schema mutation,
- job insert,
- job mutation,
- job reset/retry/delete/manual completion,
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

## CT203 evidence

    quick_check_fc_o43_c_r2=ok
    job117_state_fc_o43_c_r2=running,2,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job117_last_error_fc_o43_c_r2=<none>
    job117_result_rows_fc_o43_c_r2=0
    job_results_columns_fc_o43_c_r2=job_id,model,response_text,response_json,error,created_at,updated_at

Observed queue state:

    job108_state_fc_o43_c_r2=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job109_state_fc_o43_c_r2=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job110_state_fc_o43_c_r2=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job111_state_fc_o43_c_r2=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_state_fc_o43_c_r2=running,2,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job118_state_fc_o43_c_r2=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job119_state_fc_o43_c_r2=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job120_state_fc_o43_c_r2=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job121_state_fc_o43_c_r2=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe

## CT101 evidence

    worker_sha_fc_o43_c_r2=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8
    profile_sha_fc_o43_c_r2=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b
    active_general_services_fc_o43_c_r2=0
    failed_general_units_fc_o43_c_r2=7
    unit_active_state_fc_o43_c_r2=failed
    unit_result_fc_o43_c_r2=exit-code
    unit_exec_status_fc_o43_c_r2=1
    journal_refusal_matches_fc_o43_c_r2=1
    journal_nameerror_matches_fc_o43_c_r2=1

Relevant journal evidence:

    Jun 24 00:38:39 llms systemd[1]: Starting edge-ct101-general-queue-job-worker@117.service - AI Platform Control CT101 general_queue Ollama worker (117)...
    Jun 24 00:38:39 llms systemd[1]: Started edge-ct101-general-queue-job-worker@117.service - AI Platform Control CT101 general_queue Ollama worker (117).
    Jun 24 00:39:10 llms bash[381498]: NameError: name 'job' is not defined
    Jun 24 00:39:10 llms systemd[1]: edge-ct101-general-queue-job-worker@117.service: Failed with result 'exit-code'.
    Jun 24 01:06:46 llms systemd[1]: Starting edge-ct101-general-queue-job-worker@117.service - AI Platform Control CT101 general_queue Ollama worker (117)...
    Jun 24 01:06:46 llms systemd[1]: Started edge-ct101-general-queue-job-worker@117.service - AI Platform Control CT101 general_queue Ollama worker (117).
    Jun 24 01:07:01 llms bash[388720]: REFUSE_PRODUCT_VISIBLE_THINKING
    Jun 24 01:07:01 llms systemd[1]: edge-ct101-general-queue-job-worker@117.service: Failed with result 'exit-code'.

No reset-failed command was run. Failed-unit evidence remains preserved.

## Interpretation

FC-O43-C moved from implementation failure to product validation failure:

- Earlier failure: Python `NameError` in product completion path.
- Current failure: `REFUSE_PRODUCT_VISIBLE_THINKING`.

That is the intended gate behavior for non-product-safe output, but the current worker leaves the job stale running when validation refuses before completion/fail reporting.

## Decision

FC-O43-C-R2 records a read-only diagnosis checkpoint.

Next recommended stage: FC-O43-D worker failure-path remediation contract, no runtime. The goal is to ensure validation refusals such as `REFUSE_PRODUCT_VISIBLE_THINKING` mark the claimed job failed cleanly instead of leaving it stale running.
