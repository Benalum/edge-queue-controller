# Stage 16 FB-R5D job_type/profile eligibility diagnosis no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FB-R5C-R2.
- Base HEAD/origin/main: `b4a415e`.
- Base tag: `controller-stage-16-fb-r5c-r2-job65-exact-runtime-failure-evidence-no-retry-2026-06-22`.

## Mutation boundary

This FB-R5D stage performed read-only CT203/CT101 profile, source, unit, and journal diagnosis plus repo docs/smoke only.

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

## Finding

Job65 did not fail because of marker mismatch.

Job65 failed before model generation because CT101 worker profile eligibility refused its job type.

Observed refusal marker:

    job65_journal_refusal_marker_fb_r5d=REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE

Job65 job type:

    job65_job_type_fb_r5d=stage16_fb_r5_exact_marker_sanity

Profile eligibility result from read-only profile parse:

    profile_path_fb_r5d=/etc/edge-ct101-worker/model-profiles.yaml
    profile_sha256_fb_r5d=329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d
    profile_job65_type_allowed_fb_r5d=false

## CT203 evidence

Read-only DB evidence:

    quick_check_fb_r5d=ok
    job65_status_fb_r5d=running
    job65_attempts_fb_r5d=1
    job65_result_rows_fb_r5d=0
    jobs65_72_existing_fb_r5d=8
    jobs65_72_queued_fb_r5d=7
    jobs65_72_running_fb_r5d=1
    jobs65_72_completed_fb_r5d=0
    jobs65_72_result_rows_fb_r5d=0
    ct203_fb_r5d_read_only_acceptance_pass=true

Protected prior evidence remains:

    jobs57_64_existing_fb_r5d=8
    jobs57_64_completed_fb_r5d=1
    jobs57_64_running_fb_r5d=1
    jobs57_64_queued_fb_r5d=6
    jobs57_64_result_rows_fb_r5d=1

## CT101 evidence

CT101 worker and units remain unchanged:

    ct101_worker_sha_fb_r5d=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    exact_service_sha_fb_r5d=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e
    exact_timer_sha_fb_r5d=7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390
    general_service_sha_fb_r5d=b1b4c6422e7188c7190eae2e27ae34cb520a7efc107631f560611e7f7242d68d
    general_timer_sha_fb_r5d=c70c5495365b771d32ed787e35154c4bcb7c51bd8629d229ce87bdea937c766b

Default-off posture:

    active_exact_services_fb_r5d=0
    active_exact_timers_fb_r5d=0
    active_general_services_fb_r5d=0
    active_general_timers_fb_r5d=0
    exact_timer_enabled_fb_r5d=disabled
    general_timer_enabled_fb_r5d=disabled
    edge_service_active_fb_r5d=inactive
    edge_service_enabled_fb_r5d=disabled
    legacy_main_active_fb_r5d=inactive
    legacy_main_enabled_fb_r5d=masked
    ct101_fb_r5d_profile_diagnosis_acceptance_pass=true

## Interpretation

The R5 batch introduced new job_type values such as `stage16_fb_r5_exact_marker_sanity`.

The CT101 profile eligibility gate is working as designed: it refuses job types that are not allowed by the selected model profile.

Therefore, the next recovery should not retry job65 as-is.

## Recovery options

Recommended safe recovery path:

1. Preserve job65 as evidence:
   - status running,
   - attempts 1,
   - result rows 0,
   - refusal marker `REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE`.

2. Do not process jobs66 through 72 yet.

3. Decide one of these paths in a no-apply stage:

   - **Option A, preferred:** add an approved profile/job_type mapping for Stage 16 R5 job types, then create fresh jobs 73 through 80 using the corrected job types/profile mapping. Preserve jobs65 through 72 as evidence.
   - **Option B:** create fresh jobs 73 through 80 using an existing allowed job_type from the CT101 profile, without changing the profile file.
   - **Option C:** run a general_queue-only proof for fresh jobs 73 through 79 and skip exact-marker proof in this batch, because exact-marker proof has already been proven by earlier jobs 55 through 57.

4. Any profile file mutation requires explicit approval.

5. Any DB insert for fresh jobs requires explicit approval.

6. Any runtime processing requires explicit approval.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R5E`.

Purpose: no-apply recovery contract choosing whether to modify CT101 profile allowed job types or use existing allowed job types for fresh jobs 73 through 80.

Do not retry job65 or process jobs66 through 72 before that recovery contract.
