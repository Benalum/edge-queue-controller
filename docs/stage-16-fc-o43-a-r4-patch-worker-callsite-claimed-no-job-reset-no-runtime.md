# Stage 16 FC-O43-A-R4 patch worker complete_job callsite claimed no job reset no runtime

Date: 2026-06-24

## Purpose

FC-O43-A-R4 fixed the remaining callsite bug after FC-O43-A-R3.

FC-O43-A-R3 changed `complete_job` to require the full job context, but the callsite accidentally passed `job`, while the in-scope claimed job variable is named `claimed`.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O43-A-R3.
- Base HEAD/origin/main: `b5fe2ec`.
- Base tag: `controller-stage-16-fc-o43-a-r3-recover-worker-complete-job-context-no-job-reset-no-runtime-2026-06-24`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O43_A_R4_PATCH_WORKER_COMPLETE_JOB_CALLSITE_CLAIMED_NO_JOB_RESET_NO_RUNTIME_NO_RESET_FAILED

## Mutation boundary

Allowed mutations:

- patch repo worker call site only,
- add repo callsite smoke,
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

Before:

    complete_job(config, token, job_id, profile, job, response)

After:

    complete_job(config, token, job_id, profile, claimed, response)

The `complete_job` signature remains:

    complete_job(..., job: Dict[str, Any], response_text: str)

The function parameter remains named `job` because `build_completion_payload(profile, job, response_text)` expects the full job context there.

## Worker source and deployment

    repo_worker_path_fc_o43_a_r4=ops/workers/ct101_minimal_ollama_worker.py
    old_repo_worker_sha_fc_o43_a_r4=c2744666badf4cbdf94f2d37badb290ff7463ce991c2b9b106a754a5bb032084
    new_repo_worker_sha_fc_o43_a_r4=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8
    new_repo_worker_lines_fc_o43_a_r4=926

    deployed_worker_path_fc_o43_a_r4=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
    old_deployed_worker_sha_fc_o43_a_r4=c2744666badf4cbdf94f2d37badb290ff7463ce991c2b9b106a754a5bb032084
    worker_backup_path_fc_o43_a_r4=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o43-a-r4-pre-callsite-claimed.20260624T005842Z.bak
    worker_backup_sha_fc_o43_a_r4=c2744666badf4cbdf94f2d37badb290ff7463ce991c2b9b106a754a5bb032084
    new_deployed_worker_sha_fc_o43_a_r4=884e0fcbbd7d31df5cd6027b1d4e5294c61ac2ae497e52d6d560ee5d3bf30ca8
    new_deployed_worker_lines_fc_o43_a_r4=926

## Tests

Repo tests passed:

- `python3 -m py_compile ops/workers/ct101_minimal_ollama_worker.py`
- `ops/smoke/check-stage-16-fc-o43-a-r4-callsite-claimed.py`
- `ops/smoke/check-stage-16-fc-o43-a-complete-job-context.py`

The callsite smoke asserts that `run_one_claim_complete` calls:

    complete_job(config, token, job_id, profile, claimed, response)

CT101 deployed worker callsite test also passed.

## CT203 queue state

FC-O43-A-R4 intentionally did not reset or rerun job117.

Before patch:

    job108_state_before_fc_o43_a_r4=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job109_state_before_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job110_state_before_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job111_state_before_fc_o43_a_r4=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_state_before_fc_o43_a_r4=running,1,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job118_state_before_fc_o43_a_r4=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job119_state_before_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job120_state_before_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job121_state_before_fc_o43_a_r4=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_last_error_before_fc_o43_a_r4=<none>

After patch:

    job108_state_after_fc_o43_a_r4=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job109_state_after_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job110_state_after_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job111_state_after_fc_o43_a_r4=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_state_after_fc_o43_a_r4=running,1,0,gemma4:e4b,stage16_fc_companion_chat_semantic_probe
    job118_state_after_fc_o43_a_r4=queued,0,0,gemma3:4b,stage16_fc_companion_chat_semantic_probe
    job119_state_after_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_study_tutor_semantic_probe
    job120_state_after_fc_o43_a_r4=queued,0,0,gemma4:e4b,stage16_fc_flashcards_semantic_probe
    job121_state_after_fc_o43_a_r4=queued,0,0,llama3.2:3b,stage16_fc_safe_refusal_semantic_probe
    job117_last_error_after_fc_o43_a_r4=<none>

## CT101 state

    profile_sha_after_deploy_fc_o43_a_r4=2605835c8efe00de65123486d5432f900dd6449f3a720da1befb76e8b93eac5b
    active_exact_services_after_deploy_fc_o43_a_r4=0
    active_general_services_after_deploy_fc_o43_a_r4=0
    active_exact_timers_after_deploy_fc_o43_a_r4=0
    active_general_timers_after_deploy_fc_o43_a_r4=0
    failed_general_units_before_deploy_fc_o43_a_r4=7
    failed_general_units_after_deploy_fc_o43_a_r4=7

No failed-unit evidence was cleared.

## CT203 DB validation

    quick_check_before_fc_o43_a_r4=ok
    quick_check_after_fc_o43_a_r4=ok
    ct203_before_fc_o43_a_r4_acceptance_pass=true
    ct203_after_fc_o43_a_r4_acceptance_pass=true

## Decision

FC-O43-A-R4 repaired and deployed the callsite bug without resetting job117 or running any runtime work.

Next recommended stage: FC-O43-B reset/requeue job117 only from stale running back to queued, preserving attempts/evidence and not processing it.
