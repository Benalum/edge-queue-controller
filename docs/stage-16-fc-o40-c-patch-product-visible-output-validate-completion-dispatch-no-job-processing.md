# Stage 16 FC-O40-C patch product visible output validate_completion dispatch no job processing

Date: 2026-06-23

## Purpose

FC-O40-C corrected the worker dispatch path so `validate_completion` allows `product_visible_output_v1` instead of refusing every non-`exact_marker_only` policy before product completion.

This stage keeps the exact-marker proof path intact and keeps product validation in `build_completion_payload`.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O40-B-R4.
- Base HEAD/origin/main: `0eb7df5`.
- Base tag: `controller-stage-16-fc-o40-b-r4-recover-product-visible-output-worker-support-deploy-no-job-processing-2026-06-23`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O40_C_PATCH_PRODUCT_VISIBLE_OUTPUT_VALIDATE_COMPLETION_DISPATCH_NO_PROFILE_POLICY_MUTATION_NO_JOB_PROCESSING_NO_RESET_FAILED

## Mutation boundary

Allowed mutations:

- patch repo worker source,
- add repo dispatch contract smoke,
- back up deployed CT101 worker file,
- deploy patched worker file to CT101,
- run static/import/local worker dispatch tests only,
- repo docs/smoke/commit/tag/push.

Explicitly not performed:

- CT101 profile policy mutation,
- CT203 DB write,
- job insert,
- job mutation,
- job reset/retry/delete/manual completion,
- job_results insert,
- job processing,
- runtime model call,
- service start,
- service enable,
- timer start,
- timer enable,
- systemd unit write,
- daemon-reload,
- reset-failed,
- clearing failed-unit evidence,
- Docker mutation,
- Ollama mutation,
- Ollama generation/model endpoint calls,
- Ollama model pull,
- scheduler activation,
- persistent worker activation,
- queue drain,
- CT/VM restart.

## Worker source and deployment

    repo_worker_path_fc_o40_c=ops/workers/ct101_minimal_ollama_worker.py
    old_repo_worker_sha_fc_o40_c=302f8c0e6efdc9dfee597373b9fa9fdfc010dc291ef45fc91f1c6ce045d3add4
    new_repo_worker_sha_fc_o40_c=1809af3a97e5b357d47b4ce3728ca4e5e8f6692de89e920b881f7b3b58b820d3
    new_repo_worker_lines_fc_o40_c=926

    deployed_worker_path_fc_o40_c=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
    worker_backup_path_fc_o40_c=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o40-c-pre-validate-completion-dispatch.20260624T000638Z.bak
    worker_backup_sha_fc_o40_c=302f8c0e6efdc9dfee597373b9fa9fdfc010dc291ef45fc91f1c6ce045d3add4
    new_deployed_worker_sha_fc_o40_c=1809af3a97e5b357d47b4ce3728ca4e5e8f6692de89e920b881f7b3b58b820d3
    new_deployed_worker_lines_fc_o40_c=926

## Implemented dispatch correction

Before FC-O40-C, product support existed but `validate_completion` still had the old unsupported-policy gate.

FC-O40-C added:

    if profile.completion_validation_policy == "product_visible_output_v1":
        return extract_visible_output(response_text)

before the existing exact-marker-only unsupported-policy check.

The existing exact-marker path still validates expected markers and still refuses mismatches.

Unsupported policies still refuse with `REFUSE_UNSUPPORTED_COMPLETION_VALIDATION`.

## Contract tests

Repo contract smoke:

    ops/smoke/check-stage-16-fc-o40-c-product-visible-output-dispatch.py

Test coverage passed:

- product_visible_output_v1 passes through validate_completion,
- product payload emits response_text as clean user-visible text,
- product payload emits response_json.result_contract=product_visible_output_v1,
- visible thinking still refuses,
- exact_marker_only still passes expected marker,
- exact_marker_only still refuses wrong marker,
- unsupported policies still refuse.

CT101 deployed worker dispatch tests also passed.

## CT101 state

    profile_sha_after_deploy_fc_o40_c=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    OLLAMA_NUM_PARALLEL_after_deploy_fc_o40_c=2
    OLLAMA_KEEP_ALIVE_after_deploy_fc_o40_c=30m
    active_exact_services_after_deploy_fc_o40_c=0
    active_general_services_after_deploy_fc_o40_c=0
    active_exact_timers_after_deploy_fc_o40_c=0
    active_general_timers_after_deploy_fc_o40_c=0
    failed_general_units_before_deploy_fc_o40_c=6
    failed_general_units_after_deploy_fc_o40_c=6
    ct101_fc_o40_c_worker_deploy_acceptance_pass=true

No failed-unit evidence was cleared.

## CT203 queue state

Queue state was preserved before and after worker deployment:

    job105=running,1,0
    job106=completed,1,1
    job107=completed,1,1
    job108=queued,0,0
    job109=queued,0,0
    job110=queued,0,0
    job111=queued,0,0
    job112=completed,1,1
    job113=completed,1,1
    job114=completed,1,1
    job115=completed,1,1
    job116=completed,1,1

## What remains intentionally unchanged

Product profiles still retain their previous policy until FC-O41.

Expected current profile state after FC-O40-C:

    gemma4_product_candidate.completion_validation_policy=exact_marker_only
    gemma3_companion_candidate.completion_validation_policy=exact_marker_only
    llama32_safe_refusal_candidate.completion_validation_policy=exact_marker_only

This is intentional. FC-O41 is now unblocked as the separate profile policy mutation gate.

## Rollback

Worker backup:

    /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o40-c-pre-validate-completion-dispatch.20260624T000638Z.bak

Rollback command, only if explicitly approved in a later rollback stage:

    install -o root -g root -m 0755 /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o40-c-pre-validate-completion-dispatch.20260624T000638Z.bak /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py

No rollback is required now because static/import tests passed and no jobs were processed.

## Decision

FC-O40-C successfully corrected worker validation dispatch for `product_visible_output_v1` without processing jobs or changing profile policies.

Next recommended stage: FC-O41 product profile policy update only, no job processing.
