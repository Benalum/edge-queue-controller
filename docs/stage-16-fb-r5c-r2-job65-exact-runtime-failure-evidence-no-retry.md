# Stage 16 FB-R5C-R2 job65 exact runtime failure evidence no-retry

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FB-R5B.
- Base HEAD/origin/main: `526aab4`.
- Base tag: `controller-stage-16-fb-r5b-insert-jobs-65-72-only-no-runtime-2026-06-22`.

## Why this checkpoint exists

The first FB-R5C serial runtime attempt timed out. Reconciliation showed job65 had started through the exact-marker unit family and failed before any general_queue job started.

This checkpoint records the failure evidence and preserves the state for a deliberate next decision.

## Mutation boundary

This FB-R5C-R2 stage performed read-only CT203/CT101 evidence capture and repo docs/smoke only.

It did not:

- write CT203 DB,
- insert, reset, delete, retry, or manually complete jobs,
- retry job65,
- reset-failed job65,
- process jobs66 through 72,
- process jobs59 through 64,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- write systemd unit files,
- run daemon-reload,
- mutate Docker,
- call Ollama generate, chat, embed, or model endpoints,
- pull or download models,
- restart CTs or VMs.

## CT203 evidence

Read-only DB evidence:

    quick_check_fb_r5c_r2=ok
    job65_status_fb_r5c_r2=running
    job65_attempts_fb_r5c_r2=1
    job65_result_rows_fb_r5c_r2=0
    jobs65_72_existing_fb_r5c_r2=8
    jobs65_72_queued_fb_r5c_r2=7
    jobs65_72_running_fb_r5c_r2=1
    jobs65_72_completed_fb_r5c_r2=0
    jobs65_72_failed_fb_r5c_r2=0
    jobs65_72_result_rows_fb_r5c_r2=0
    ct203_fb_r5c_r2_evidence_acceptance_pass=true

Protected prior evidence remains:

    jobs57_64_existing_fb_r5c_r2=8
    jobs57_64_completed_fb_r5c_r2=1
    jobs57_64_running_fb_r5c_r2=1
    jobs57_64_queued_fb_r5c_r2=6
    jobs57_64_result_rows_fb_r5c_r2=1

## Jobs 65-72 current state

- job 65: running, attempts 1, result rows 0,
- jobs 66 through 72: queued, attempts 0, result rows 0.

## CT101 evidence

CT101 worker and units remain unchanged:

    ct101_worker_sha_fb_r5c_r2=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    exact_service_sha_fb_r5c_r2=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e
    exact_timer_sha_fb_r5c_r2=7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390
    general_service_sha_fb_r5c_r2=b1b4c6422e7188c7190eae2e27ae34cb520a7efc107631f560611e7f7242d68d
    general_timer_sha_fb_r5c_r2=c70c5495365b771d32ed787e35154c4bcb7c51bd8629d229ce87bdea937c766b

Job65 exact unit evidence:

    job65_exact_service_active_fb_r5c_r2=failed_or_inactive
    job65_exact_service_result_fb_r5c_r2=exit-code
    job65_exact_timer_active_fb_r5c_r2=inactive
    job65_exact_timer_enabled_fb_r5c_r2=disabled
    journal_refusal_marker_fb_r5c_r2=REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE
    ct101_fb_r5c_r2_evidence_acceptance_pass=true

Default-off posture:

    active_exact_services_fb_r5c_r2=0
    active_exact_timers_fb_r5c_r2=0
    active_general_services_fb_r5c_r2=0
    active_general_timers_fb_r5c_r2=0
    exact_timer_enabled_fb_r5c_r2=disabled
    general_timer_enabled_fb_r5c_r2=disabled
    edge_service_active_fb_r5c_r2=inactive
    edge_service_enabled_fb_r5c_r2=disabled
    legacy_main_active_fb_r5c_r2=inactive
    legacy_main_enabled_fb_r5c_r2=masked

## Interpretation

The exact-marker path is still too strict for model-generated output unless the model returns the exact marker. This is the same class of failure seen earlier with exact-marker mismatch / marker-not-found failures.

The new general_queue units were not exercised in this attempt. Jobs66 through 72 remain queued and untouched.

## Do not do next

Do not retry job65 blindly.

Do not process jobs66 through 72 until job65 handling is explicitly decided.

Do not reset-failed job65 until a cleanup-only approval or a combined recovery plan explicitly covers it.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R5D`.

Purpose: no-apply recovery strategy for job65 exact-marker failure and remaining jobs66 through 72.

Likely safe strategy:

1. Preserve job65 as failed-running evidence.
2. Create a fresh exact-marker-compatible job73 or a manually constrained deterministic no-model exact marker path if available.
3. Process remaining general_queue jobs with fresh job ids only after a new contract, or explicitly skip exact-marker proof and run a general_queue-only breadth proof.

No retry should happen without a new explicit approval.
