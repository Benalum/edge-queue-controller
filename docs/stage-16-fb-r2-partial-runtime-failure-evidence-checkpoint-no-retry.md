# Stage 16 FB-R2 partial runtime failure evidence checkpoint no-retry

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 FA.
- Base HEAD/origin/main: `4278066`.
- Base tag: `controller-stage-16-fa-queue-breadth-model-routing-matrix-contract-no-apply-2026-06-22`.

## Why this checkpoint exists

FB attempted the first serial queue breadth runtime proof for jobs 57 through 64.

The PPB run timed out after inserting the jobs and after the serial runtime path had started. Follow-up reconciliation showed the attempt partially ran:

- job 57 completed successfully,
- job 58 reached the installed worker and failed with `REFUSE_EXPECTED_MARKER_NOT_FOUND`,
- job 58 remained running with attempts 1 and no result rows,
- jobs 59 through 64 remained queued with attempts 0 and no result rows,
- job58 timer remained active until cleanup,
- job58 service remained in systemd failed state as preserved evidence.

A cleanup command stopped only the exact job58 timer/service instance. It did not reset-failed. This checkpoint records the preserved systemd failed state intentionally.

## Mutation scope

This checkpoint used:

- read-only CT101 evidence collection,
- read-only CT203 DB verification,
- repo doc/smoke/commit/tag/push.

The previous cleanup command used only:

- `systemctl stop edge-ct101-exact-job-worker@58.timer`,
- `systemctl stop edge-ct101-exact-job-worker@58.service`.

No reset-failed was performed.

No job was reset, deleted, manually completed, or retried.

## Original FB insertion evidence

Original FB inserted jobs 57 through 64 and created backup:

- backup path: `/var/lib/edge-queue-controller/stage16-fb-backups/edge_queue.sqlite3.stage16-fb-pre-jobs57-64-insert.20260623T013900Z.bak`,
- backup sha256: `0955f5f4ca66709864d52cfbddf60fdaaeb51ae4f15b10006ce101ec998e2574`,
- backup size bytes: `43823104`.

## CT101 evidence after cleanup

Read-only CT101 evidence after cleanup showed:

    timer58_active_evidence=inactive
    timer58_enabled_evidence=disabled
    timer58_unit_file_state_evidence=disabled
    service58_active_evidence=failed
    service58_enabled_evidence=static
    service58_unit_file_state_evidence=static
    service58_result_evidence=exit-code
    service58_exec_status_evidence=1
    edge_service_active_evidence=inactive
    edge_service_enabled_evidence=disabled
    legacy_main_active_evidence=inactive
    legacy_main_enabled_evidence=masked
    legacy_tiny_enabled_evidence=masked
    legacy_small_enabled_evidence=masked
    active_exact_job_services_evidence=0
    active_exact_job_timers_evidence=0
    service_template_enabled_evidence=static
    timer_template_enabled_evidence=disabled
    ct101_failed_state_preserved_acceptance_pass=true

The job58 journal included:

    REFUSE_EXPECTED_MARKER_NOT_FOUND
    edge-ct101-exact-job-worker@58.service: Failed with result 'exit-code'.

## CT203 evidence

Read-only CT203 DB verification showed:

    quick_check_fb_r2_evidence=ok
    jobs_37_52_seen_fb_r2_evidence=16
    jobs_37_52_completed_with_one_result_fb_r2_evidence=16

Prior evidence remained preserved:

- job 53 remained running, attempts 1, result rows 0,
- job 54 remained running, attempts 1, result rows 0,
- job 55 remained completed, attempts 1, result rows 1, response `E3Z-EW-OK`,
- job 56 remained completed, attempts 1, result rows 1, response `E3Z-EY-OK`.

FB batch state:

    job57_status_fb_r2_evidence=completed
    job57_attempts_fb_r2_evidence=1
    job57_result_rows_fb_r2_evidence=1
    job57_response_fb_r2_evidence=STAGE16-FB-J57-OK
    job58_status_fb_r2_evidence=running
    job58_attempts_fb_r2_evidence=1
    job58_result_rows_fb_r2_evidence=0
    job59_status_fb_r2_evidence=queued
    job59_attempts_fb_r2_evidence=0
    job60_status_fb_r2_evidence=queued
    job60_attempts_fb_r2_evidence=0
    job61_status_fb_r2_evidence=queued
    job61_attempts_fb_r2_evidence=0
    job62_status_fb_r2_evidence=queued
    job62_attempts_fb_r2_evidence=0
    job63_status_fb_r2_evidence=queued
    job63_attempts_fb_r2_evidence=0
    job64_status_fb_r2_evidence=queued
    job64_attempts_fb_r2_evidence=0
    jobs57_64_existing_fb_r2_evidence=8
    jobs57_64_completed_fb_r2_evidence=1
    jobs57_64_running_fb_r2_evidence=1
    jobs57_64_queued_fb_r2_evidence=6
    jobs57_64_result_rows_fb_r2_evidence=1
    max_job_id_fb_r2_evidence=64
    fb_r2_evidence_acceptance_pass=true

## Diagnostic conclusion

FB did not fail because the queue could not insert jobs. It inserted jobs 57 through 64.

FB did not fail because the installed timer path could not complete an exact marker. Job 57 completed correctly with response `STAGE16-FB-J57-OK`.

FB failed when the strict exact-marker worker was used on job 58, a non-exact natural-language companion prompt. The worker refused with `REFUSE_EXPECTED_MARKER_NOT_FOUND`.

This confirms the currently installed CT101 exact-job worker is a proof worker for exact marker prompts, not a general queue breadth worker for companion/study/flashcard/summary/JSON/router/refusal prompts.

## Preservation rule

Jobs 57 through 64 are now FB evidence.

Do not reset, delete, manually complete, or silently retry them.

Do not process jobs 59 through 64 until a corrected strategy is documented and explicitly approved.

Do not reset-failed on job58 service until the preserved failed state is no longer needed or a cleanup-only approval is given.

## Next recommended stage

Recommended next stage: `Stage 16 FB-R3`.

Purpose: define a no-apply corrected queue breadth worker strategy before any more breadth runtime attempts.

The corrected path should separate:

- exact-marker proof worker behavior,
- general queue breadth worker behavior,
- acceptance classification behavior,
- service/timer cleanup behavior,
- evidence preservation behavior.
