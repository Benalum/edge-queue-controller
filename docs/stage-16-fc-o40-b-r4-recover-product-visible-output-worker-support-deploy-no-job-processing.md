# Stage 16 FC-O40-B-R4 recover product visible output worker support deploy no job processing

Date: 2026-06-23

## Purpose

FC-O40-B-R4 recovered the FC-O40-B worker support mutation after R3 failed before deployment because the wrapper omitted PROFILE_PATH.

R4 used the already-patched and already-tested repo worker from R3, deployed it to CT101 with backup and SHA gates, and checkpointed the source-controlled worker support.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O40-A.
- Base HEAD/origin/main: `2cd7355`.
- Base tag: `controller-stage-16-fc-o40-a-worker-source-authority-implementation-preflight-read-only-2026-06-23`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O40_B_APPLY_PRODUCT_VISIBLE_OUTPUT_WORKER_SUPPORT_AND_TESTS_NO_JOB_PROCESSING_NO_PROFILE_POLICY_MUTATION_NO_RESET_FAILED

## Mutation boundary

Allowed mutations:

- use existing patched repo worker from failed R3,
- use existing repo contract smoke from failed R3,
- back up deployed CT101 worker file,
- deploy patched worker file to CT101,
- run static/import/local worker contract tests only,
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

    repo_worker_path_fc_o40_b_r4=ops/workers/ct101_minimal_ollama_worker.py
    old_repo_worker_sha_fc_o40_b_r4=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    new_repo_worker_sha_fc_o40_b_r4=302f8c0e6efdc9dfee597373b9fa9fdfc010dc291ef45fc91f1c6ce045d3add4
    new_repo_worker_lines_fc_o40_b_r4=924

    deployed_worker_path_fc_o40_b_r4=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
    worker_backup_path_fc_o40_b_r4=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o40-b-r4-pre-product-visible-output.20260623T235657Z.bak
    worker_backup_sha_fc_o40_b_r4=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    new_deployed_worker_sha_fc_o40_b_r4=302f8c0e6efdc9dfee597373b9fa9fdfc010dc291ef45fc91f1c6ce045d3add4
    new_deployed_worker_lines_fc_o40_b_r4=924

## Implemented product worker support

FC-O40-B-R4 installed source-controlled worker support for:

    product_visible_output_v1
    ProductValidationResult
    extract_visible_output
    detect_visible_thinking
    detect_hidden_thinking_markers
    detect_guard_metadata_output
    detect_internal_surface_terms
    validate_product_visible_output
    build_product_response_json
    build_completion_payload

Stable product refusal codes now present:

    REFUSE_PRODUCT_EMPTY_VISIBLE_OUTPUT
    REFUSE_PRODUCT_VISIBLE_THINKING
    REFUSE_PRODUCT_HIDDEN_THINKING
    REFUSE_PRODUCT_GUARD_JSON
    REFUSE_PRODUCT_INTERNAL_TERMS
    REFUSE_PRODUCT_SHAPE_MISMATCH
    REFUSE_PRODUCT_UNSUPPORTED_JOB_TYPE

The existing `exact_marker_only` path remains present and tested.

## Contract tests

Repo contract smoke:

    ops/smoke/check-stage-16-fc-o40-b-r3-product-visible-output-worker-contract.py

Test coverage passed:

- Companion clean paragraph passes.
- Companion visible thinking fails with REFUSE_PRODUCT_VISIBLE_THINKING.
- Hidden thinking marker fails with REFUSE_PRODUCT_HIDDEN_THINKING.
- Guard JSON fails with REFUSE_PRODUCT_GUARD_JSON.
- Internal worker/queue/system terms fail for Companion.
- Flashcard JSON with prompt/answer fields passes.
- Flashcard JSON plus prose fails with REFUSE_PRODUCT_SHAPE_MISMATCH.
- Safe refusal text with required terms passes.
- Unsupported product job type fails with REFUSE_PRODUCT_UNSUPPORTED_JOB_TYPE.
- Existing exact_marker_only tests still pass.
- build_completion_payload preserves guard payloads for exact_marker_only.
- build_completion_payload emits product_visible_output_v1 metadata for product policy.

CT101 deployed worker import tests also passed.

## CT101 state

    profile_sha_after_deploy_fc_o40_b_r4=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    OLLAMA_NUM_PARALLEL_after_deploy_fc_o40_b_r4=2
    OLLAMA_KEEP_ALIVE_after_deploy_fc_o40_b_r4=30m
    active_exact_services_after_deploy_fc_o40_b_r4=0
    active_general_services_after_deploy_fc_o40_b_r4=0
    active_exact_timers_after_deploy_fc_o40_b_r4=0
    active_general_timers_after_deploy_fc_o40_b_r4=0
    failed_general_units_before_deploy_fc_o40_b_r4=6
    failed_general_units_after_deploy_fc_o40_b_r4=6
    ct101_fc_o40_b_r4_worker_deploy_acceptance_pass=true

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

Expected current profile state after FC-O40-B-R4:

    gemma4_product_candidate.completion_validation_policy=exact_marker_only
    gemma3_companion_candidate.completion_validation_policy=exact_marker_only
    llama32_safe_refusal_candidate.completion_validation_policy=exact_marker_only

This is intentional. FC-O41 is the separate profile policy mutation gate.

## Rollback

Worker backup:

    /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o40-b-r4-pre-product-visible-output.20260623T235657Z.bak

Rollback command, only if explicitly approved in a later rollback stage:

    install -o root -g root -m 0755 /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py.stage16-fc-o40-b-r4-pre-product-visible-output.20260623T235657Z.bak /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py

No rollback is required now because static/import tests passed and no jobs were processed.

## Decision

FC-O40-B-R4 successfully installed source-controlled worker support for `product_visible_output_v1` without processing jobs or changing profile policies.

Next recommended stage: FC-O41 product profile policy update only, no job processing.
