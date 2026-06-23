# Stage 16 FC-O40-A worker source authority implementation preflight read-only

Date: 2026-06-23

## Purpose

FC-O40-A is a read-only preflight before any worker code mutation.

It verifies whether the deployed CT101 worker is controlled by a matching repo source file, so FC-O40-B can safely patch from source instead of editing an unknown deployed artifact.

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O39.
- Base HEAD/origin/main: `5a2f728`.
- Base tag: `controller-stage-16-fc-o39-product-result-worker-profile-remediation-implementation-contract-no-runtime-2026-06-23`.

## Approval

Approval phrase used:

    APPROVE_STAGE_16_FC_O40_A_WORKER_SOURCE_AUTHORITY_IMPLEMENTATION_PREFLIGHT_READ_ONLY_NO_RUNTIME_NO_JOB_MUTATION_NO_RESET_FAILED

## Mutation boundary

This stage performed only:

- read-only repo source inspection,
- read-only CT203 queue-state inspection,
- read-only CT101 deployed-worker/profile/systemd inspection,
- repo docs/smoke/commit/tag/push.

It did not write CT101 profile, mutate CT101 worker code, write CT203 DB, insert or mutate jobs, reset/retry/delete/manually complete jobs, insert job_results rows, run jobs, start services, enable services or timers, start timers, write systemd units, run daemon-reload, reset failed units, clear failed-unit evidence, mutate Docker/Ollama, call Ollama generation/model endpoints, pull models, activate scheduler/persistent workers, drain queue, or restart CTs/VMs.

## Repo source candidates

    repo_exact_candidate_count_fc_o40_a=1
    repo_exact_candidate_paths_fc_o40_a=ops/workers/ct101_minimal_ollama_worker.py

All repo worker candidates observed:

    repo_worker_candidate_fc_o40_a path=ops/workers/ct101_minimal_ollama_worker.py sha=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca lines=745

## Deployed CT101 worker

    deployed_worker_path_fc_o40_a=/opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py
    deployed_worker_sha_fc_o40_a=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    deployed_worker_lines_fc_o40_a=745
    expected_deployed_worker_sha_fc_o40_a=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca

## CT101 profile and unit state

    profile_sha_fc_o40_a=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    expected_profile_sha_fc_o40_a=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740
    general_unit_sha_fc_o40_a=b1b4c6422e7188c7190eae2e27ae34cb520a7efc107631f560611e7f7242d68d
    exact_unit_sha_fc_o40_a=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e
    OLLAMA_NUM_PARALLEL_fc_o40_a=2
    OLLAMA_KEEP_ALIVE_fc_o40_a=30m
    active_exact_services_fc_o40_a=0
    active_general_services_fc_o40_a=0
    active_exact_timers_fc_o40_a=0
    active_general_timers_fc_o40_a=0
    failed_general_units_fc_o40_a=6
    ct101_fc_o40_a_read_only_acceptance_pass=true

## CT203 queue state

    quick_check_fc_o40_a=ok
    ct203_queue_state_preserved_fc_o40_a=true
    ct203_fc_o40_a_read_only_acceptance_pass=true

Preserved queue states:

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

## Source authority decision

    source_authority_classification_fc_o40_a=repo_exact_sha_match
    fc_o40_b_worker_patch_allowed_fc_o40_a=true

Decision rules:

- If classification is `repo_exact_sha_match`, FC-O40-B may patch the matched repo worker source, then deploy/update CT101 worker under a separate explicit mutation approval.
- If classification is `deployed_worker_not_matched_in_repo`, FC-O40-B must not patch ad hoc. First create a source-authority repair plan.
- If classification is `multiple_repo_candidates_match_deployed_sha`, FC-O40-B must stop and disambiguate source authority.

## Required FC-O40-B boundary if allowed

FC-O40-B must be an explicit mutation approval and must still forbid job processing.

Allowed only after approval:

- patch repo worker source,
- add repo smoke/tests for product_visible_output_v1,
- deploy or update CT101 worker file from the patched source,
- create a deployed-worker backup before replacement,
- verify deployed worker sha after replacement,
- run only local/import/static worker tests,
- commit/tag/push.

Still forbidden in FC-O40-B:

- CT101 profile policy mutation,
- CT203 DB mutation,
- job insert,
- job mutation,
- job processing,
- service start,
- timer start,
- daemon-reload unless needed and explicitly allowed,
- reset-failed,
- Docker/Ollama mutation or generation call,
- queue drain,
- CT/VM restart.

## Rollback posture

FC-O40-A is read-only plus repo docs, so no live rollback is required.

Future FC-O40-B must include a worker file backup, expected sha gates, and a git rollback path before deployment.
