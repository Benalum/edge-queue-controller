# Stage 16 FC-O43-D-R2 patch worker validation-refusal fail path no job reset no runtime

Date: 2026-06-24

## Purpose

FC-O43-D-R2 patches the CT101 worker failure path so a product validation refusal after a job has been claimed calls the job fail endpoint instead of leaving the job stale running.

The immediate trigger was FC-O43-C, where job117 reached the fixed worker and failed validation with:

    REFUSE_PRODUCT_VISIBLE_THINKING

FC-O43-D first failed before mutation because the worker had no existing `fail_job` helper. R2 adds that helper and then wraps validation refusal handling.

FC-O43-D-R2 does not reset or rerun job117. It only patches and deploys the worker failure path.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O43-C-R2.
- Base HEAD/origin/main: `9961ad3`.
- Base tag: `controller-stage-16-fc-o43-c-r2-record-product-visible-thinking-refusal-read-only-docs-only-2026-06-24`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O43_D_PATCH_WORKER_VALIDATION_REFUSAL_FAIL_PATH_NO_JOB_RESET_NO_RUNTIME_NO_RESET_FAILED

## Mutation boundary

Allowed mutations:

- patch repo worker failure path,
- add `fail_job` helper if missing,
- add repo/static fail-path smoke,
- back up deployed CT101 worker file,
- deploy patched worker file to CT101,
- run static/import/local worker tests only,
- repo docs/smoke/commit/tag/push.

Explicitly not performed:

- CT203 DB write,
- job reset/retry/delete/manual completion,
- job insert,
- job mutation,
- job_results insert,
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

## Implemented fix

New helper:

    def fail_job(config: WorkerConfig, token: str, job_id: int, error: str) -> None:
        validate_allowed_job_id(config, job_id)
        status, _body = _post_json(
            config,
            token,
            f"/internal/edge-worker/jobs/{job_id}/fail",
            {
                "worker_id": config.worker_id,
                "error": error,
            },
        )
        if status // 100 != 2:
            raise WorkerRefusal(f"REFUSE_WORKER_FAIL_POST_FAILED status={status}")

Failure path:

    response = run_ollama_call(profile, str(claimed.get("prompt") or ""))
    try:
        validate_completion(profile, claimed, response)
    except WorkerRefusal as exc:
        fail_job(config, token, job_id, str(exc))
        return 1
    complete_job(config, token, job_id, profile, claimed, response)
    return 0

## Worker source and deployment

    repo_worker_path_fc_o43_d_r2=ops/workers/ct101_minimal_ollama_worker.py
    old_repo_worker_sha_fc_o43_d_r2=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8
    new_repo_worker_sha_fc_o43_d_r2=09c763048dea8f9d008069ae4988ef0701a67d94b10e4bc5b48899e044a758a2
    new_repo_worker_lines_fc_o43_d_r2=945

    deployed_worker_path_fc_o43_d_r2=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
    old_deployed_worker_sha_fc_o43_d_r2=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8
    worker_backup_path_fc_o43_d_r2=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o43-d-r2-pre-validation-refusal-fail-path.20260624T013709Z.bak
    worker_backup_sha_fc_o43_d_r2=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8
    new_deployed_worker_sha_fc_o43_d_r2=09c763048dea8f9d008069ae4988ef0701a67d94b10e4bc5b48899e044a758a2
    new_deployed_worker_lines_fc_o43_d_r2=945

## Tests

Repo tests passed:

- `python3 -m py_compile ops/workers/ct101_minimal_ollama_worker.py`
- `ops/smoke/check-stage-16-fc-o43-d-r2-validation-refusal-fail-path.py`
- `ops/smoke/check-stage-16-fc-o43-a-r4-callsite-claimed.py`
- `ops/smoke/check-stage-16-fc-o43-a-complete-job-context.py`

The contract smoke verified:

- `run_one_claim_complete` catches `WorkerRefusal` from `validate_completion`,
- it calls `fail_job(config, token, job_id, str(exc))`,
- it returns `1`,
- `fail_job` posts to `/internal/edge-worker/jobs/117/fail`,
- `fail_job` preserves allowed-job-id guard behavior.

CT101 deployed worker AST test passed.

## CT203 queue preservation

FC-O43-D-R2 intentionally did not reset or rerun job117.

Before patch:

    job108_state_before_fc_o43_d_r2=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job109_state_before_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job110_state_before_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job111_state_before_fc_o43_d_r2=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_state_before_fc_o43_d_r2=running,2,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job118_state_before_fc_o43_d_r2=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job119_state_before_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job120_state_before_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job121_state_before_fc_o43_d_r2=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_last_error_before_fc_o43_d_r2=<none>

After patch:

    job108_state_after_fc_o43_d_r2=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job109_state_after_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job110_state_after_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job111_state_after_fc_o43_d_r2=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_state_after_fc_o43_d_r2=running,2,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job118_state_after_fc_o43_d_r2=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job119_state_after_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job120_state_after_fc_o43_d_r2=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job121_state_after_fc_o43_d_r2=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_last_error_after_fc_o43_d_r2=<none>

## CT101 state

    profile_sha_after_deploy_fc_o43_d_r2=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b
    active_exact_services_after_deploy_fc_o43_d_r2=0
    active_general_services_after_deploy_fc_o43_d_r2=0
    active_exact_timers_after_deploy_fc_o43_d_r2=0
    active_general_timers_after_deploy_fc_o43_d_r2=0
    failed_general_units_before_deploy_fc_o43_d_r2=7
    failed_general_units_after_deploy_fc_o43_d_r2=7

No failed-unit evidence was cleared.

## CT203 DB validation

    quick_check_before_fc_o43_d_r2=ok
    quick_check_after_fc_o43_d_r2=ok
    ct203_before_fc_o43_d_r2_acceptance_pass=true
    ct203_after_fc_o43_d_r2_acceptance_pass=true

## Decision

FC-O43-D-R2 repaired and deployed the validation-refusal fail path without resetting job117 or running any runtime work.

Next recommended stage: FC-O43-E reset/requeue only job117 from stale running back to queued, preserving attempts/evidence and not processing it.
