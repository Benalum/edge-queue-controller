# Stage 16 E3V-A — Repeatable Scheduler-Controlled Lane Design, No Apply

## Purpose

E3V-A defines the no-apply design for converting the proven E3U one-shot scheduler-selected dispatch into a repeatable scheduler-controlled model lane.

This phase is documentation and smoke only.

No runtime action is performed.

## Current proven baseline

E3U-C2 proved this full chain:

    CT203 queued job
    E3S scheduler dry-run selection gate
    controlled helper path
    PVESO one-shot adapter
    PVESO localhost-only Ollama
    CT203 DB completion
    CT203 job_results insert

E3U-C2 completed job 28 exactly once:

    RESULT=PASS_STAGE_16_E3U_C2_SCHEDULER_SELECTED_CONTROLLED_DISPATCH_JOB_28
    job_28_status=completed
    job_28_attempts=1
    job_28_result_rows=1
    job_results_total=10
    pveso_runner_count_after=0

Do not rerun job 28.

Do not reuse job 27.

## Current repo checkpoint

    HEAD/origin/main/remote: 61d736a
    Previous tag: controller-stage-16-e3u-c2-scheduler-selected-controlled-dispatch-job-28-result-2026-06-21
    Working tree before E3V-A: clean

## Current runtime posture

Scheduler activation has not been performed.

Persistent worker activation has not been performed.

Lane worker activation has not been performed.

CT101 remains stopped and onboot=0.

PVESO Ollama remains private and localhost-only.

## E3V target outcome

The E3V target is not to activate the scheduler yet.

The E3V target is to design a repeatable scheduler-controlled lane that can later run one eligible queued model job at a time while preserving all E3U guards.

The intended future chain is:

    queued eligible CT203 job
    read-only scheduler candidate scan
    one-job claim or lease guard
    controlled helper/adapter dispatch
    PVESO localhost-only model call
    exactly one CT203 job completion
    exactly one CT203 job_results insert
    read-only postflight classification
    no broad queue drain

## Required design properties

The future repeatable lane must include:

- one-job-at-a-time dispatch guard
- target-job selection from scheduler logic, not manual arbitrary job id
- allowlist gate for requested_model
- duplicate result guard before runtime
- duplicate result guard after runtime
- queued-status guard before runtime
- attempts guard before runtime
- timeout recovery classification
- no immediate rerun after timeout
- PVESO localhost-only Ollama listener guard
- PVESO non-localhost 11434 listener count must be zero
- PVESO runner count must be zero before dispatch
- PVESO runner count must return to zero after dispatch
- CT101 stopped/onboot=0 guard
- scheduler default-off guard
- persistent worker default-off guard
- durable run directory per dispatch
- durable preflight/postflight artifacts
- no frontend/browser direct model calls
- no public Ollama exposure

## Queue selection rule

The repeatable lane should select only jobs that pass the E3S eligibility shape:

    status=queued
    result_rows=0
    requested_model is allowlisted
    lane inferred as model
    job_type/prompt marker is compatible with model dispatch
    oldest eligible job first unless a later policy says otherwise

The scheduler must continue rejecting known unsafe queued jobs:

    job 23 rejected because requested_model=gemma4:e4b is not allowlisted
    job 24 rejected because requested_model=mock/no-model is not allowlisted

## Claim/lease decision

The current live DB schema has no durable claim/lease fields.

E3V must choose one of these paths before any repeatable runtime activation:

Option A: no schema apply yet; one-shot selected dispatch with status/result duplicate guards only.

Option B: add a small claim/lease schema in a separately approved migration.

Option C: use existing fields only, such as status transitions, but only if the transition can be made safely and atomically.

Recommendation:

    E3V-B should be a no-apply claim/lease design comparison.
    E3V-C should be a read-only schema capability check.
    A real claim/lease DB migration must require separate explicit approval.

## Future approval boundary

The future apply phase must require a new approval phrase before any DB write or runtime dispatch.

Suggested future approval phrase:

    APPROVE_STAGE_16_E3V_RUN_ONE_REPEATABLE_SCHEDULER_CONTROLLED_MODEL_JOB_ONLY

That future approval should allow at most:

- one selected eligible queued model job
- one helper call
- one adapter call
- one localhost-only PVESO model call
- one CT203 job completion
- one CT203 job_results insert

It must still deny:

- persistent scheduler activation
- persistent worker activation
- broad queue draining
- job 27 reuse
- job 28 rerun
- dispatch of rejected jobs 23 or 24
- CT101 start
- PVESO/Ollama public exposure
- service/CT/VM/Cloudflare/private-storage mutation
- DB schema migration unless separately approved

## Scheduler activation boundary

E3V does not activate a persistent scheduler.

Persistent scheduler activation must remain a later, separately approved phase after:

- repeatable one-shot lane succeeds
- claim/lease semantics are decided
- timeout recovery is documented
- duplicate result handling is verified
- public UI/API contract is clear
- observability artifacts are stable
- rollback/recovery procedure exists

## Persistent worker boundary

E3V does not activate persistent lane workers.

Persistent workers should remain disabled until:

- scheduler lane can safely select one eligible job
- workers can prove they only accept allowed lanes
- duplicate DB completion is impossible
- failed model calls classify cleanly
- public users cannot directly trigger model endpoints
- admin controls exist for pausing dispatch

## Timeout recovery policy

If a repeatable dispatch times out, do not rerun immediately.

Required recovery order:

    1. CT203 DB read-only classification
    2. PVESO runner/process read-only classification
    3. run directory artifact review
    4. final recovery classification
    5. only then decide whether a new approval is needed

Recovery classifications:

    completed_with_one_result_do_not_rerun
    queued_zero_results_no_runner_new_approval_required
    queued_zero_results_runner_active_do_not_rerun
    duplicate_result_failure_do_not_rerun
    ambiguous_preserve_artifacts_do_not_rerun

## Observability requirements

Each future dispatch must preserve:

    run_dir
    approval marker
    selected job id
    preflight DB classification
    scheduler dry-run selection output
    PVESO preflight output
    helper stdout/stderr
    adapter stdout/stderr
    DB postflight output
    PVESO postflight output
    final status
    recovery hint

## E3V-A no-apply result

This E3V-A document does not run the scheduler.

It does not run a helper.

It does not run an adapter.

It does not call a model.

It does not write the DB.

It does not activate persistent scheduler or workers.

It only defines the next safe design boundary.
