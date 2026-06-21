# Stage 16 E3U-C2 — Scheduler-Selected Controlled Dispatch Job 28 Result

## Result

Stage 16 E3U-C2 completed successfully.

Job 28 was selected by the scheduler dry-run gate, then completed through the controlled helper/adapter/PVESO Ollama path.

Do not rerun job 28.

Final result:

    RESULT=PASS_STAGE_16_E3U_C2_SCHEDULER_SELECTED_CONTROLLED_DISPATCH_JOB_28
    target_job_id=28
    job_28_status=completed
    job_28_attempts=1
    job_28_result_rows=1
    job_results_total=10
    pveso_runner_count_after=0
    RECOVERY_DECISION=DO_NOT_RERUN_DOCUMENT_SUCCESS

## Repo checkpoint

Before this documentation step:

    HEAD/origin/main/remote: 5870f21
    working tree: clean

## Runtime run directory

The runtime artifacts were preserved here:

    /tmp/apc-stage16-e3u-job28-20260621T182848Z

Observed files included:

    recovery_hint.txt
    db_stat_before.txt
    ct203-preflight.py
    ct203-preflight.txt
    e3s-dry-run-before.txt
    db_stat_after_readonly.txt
    pveso-preflight.sh
    pveso-preflight.txt
    dispatch.stderr.raw.txt
    dispatch.stdout.raw.txt

The original PPB E3U-C2 wrapper timed out during the dispatch section, but the helper/adapter/model/DB path completed successfully before timeout recovery classification.

## Approved runtime boundary

The approval phrase used for E3U was:

    APPROVE_STAGE_16_E3U_RUN_ONE_SCHEDULER_CONTROLLED_DISPATCH_FOR_JOB_28_ONLY

The approved scope allowed exactly one controlled runtime attempt for job 28 only.

Still denied:

- scheduler activation
- persistent worker activation
- broad queue drain
- job 23 dispatch
- job 24 dispatch
- job 27 reuse
- second job 28 run
- CT101 start
- service/CT/VM/Cloudflare/private-storage mutation
- PVESO/Ollama public exposure

## Preflight state before runtime

The CT203 read-only preflight passed:

    STAGE=stage-16-e3u-c2-ct203-preflight
    DB_OPEN_MODE=sqlite_uri_mode_ro
    DB_INTEGRITY=ok
    JOBS_TOTAL_BEFORE=27
    JOB_RESULTS_TOTAL_BEFORE=9
    JOB_28_RESULT_ROWS_BEFORE=0
    JOB_28_STATUS_BEFORE=queued
    JOB_28_ATTEMPTS_BEFORE=0
    JOB_28_TYPE_BEFORE=stage16_e3t_scheduler_dry_run_eligible_model_smoke
    JOB_28_MODEL_BEFORE=qwen2.5:32b-instruct-q4_K_M
    JOB_28_PROMPT_BEFORE=APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE
    QUEUED_TOTAL_BEFORE=3
    E3U_C2_CT203_PREFLIGHT_OK

The E3S scheduler dry-run gate selected only job 28:

    STAGE=stage-16-e3s-scheduler-dry-run-artifact-no-db-writes
    NO_DB_WRITE
    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    RUNTIME_CALLS=disabled
    SCHEDULER_ACTIVATION=not_performed
    PERSISTENT_WORKER_ACTIVATION=not_performed
    DB_INTEGRITY=ok
    QUEUED_INSPECTED=3
    ELIGIBLE_WOULD_CLAIM_COUNT=1
    WOULD_CLAIM job_id=28 lane=model model=qwen2.5:32b-instruct-q4_K_M result_rows=0 created=2026-06-21T18:12:48Z updated=2026-06-21T18:12:48Z

The dry-run rejected the older queued jobs as expected:

    REJECT model_not_allowlisted job_id=23
    REJECT model_not_allowlisted job_id=24

The CT203 DB stat did not change during the read-only checks:

    before=43798528 1782065568 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after_readonly=43798528 1782065568 /var/lib/edge-queue-controller/edge_queue.sqlite3

## PVESO and CT101 preflight

The immediate PVESO/CT101 preflight passed before runtime:

    PVESO_PREFLIGHT=begin
    OLLAMA_SERVICE_STATE=active
    OLLAMA_11434_LOCAL_ADDRESSES_START
    127.0.0.1:11434
    OLLAMA_11434_LOCAL_ADDRESSES_END
    OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
    OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
    OLLAMA_RUNNER_COUNT=0
    CT101_STATUS=stopped
    CT101_ONBOOT=0
    PVESO_PREFLIGHT_OK

## Runtime dispatch evidence

The dispatch stdout raw artifact showed the PVESO one-shot adapter completed successfully:

    ONE_SHOT_MODEL_ADAPTER_RESULT=PASS
    adapter_rc=0
    generate_curl_rc=0
    generate_elapsed_seconds=83
    generate_json_ok=yes
    generate_done=True
    generate_model=qwen2.5:32b-instruct-q4_K_M
    generate_response_len=294
    generate_nonempty_response=yes
    ollama_active_post=active
    non_localhost_11434_listener_count_post=0
    ct_101_status_post=status: stopped
    ct_101_onboot_post=0

The helper completed exactly one DB job lifecycle:

    db_integrity_before=ok
    jobs_before=27
    job_results_before=9
    job_results_for_job_before=0
    jobs_after=27
    job_results_after=10
    jobs_rows_updated=1
    job_status_after=completed
    job_attempts_after=1
    job_results_for_job_after=1
    MANUAL_COMPLETION_HELPER_DB_RESULT=PASS
    MANUAL_COMPLETION_HELPER_RESULT=PASS

## Corrected read-only completion postflight

E3U-C2-R2 verified the completed state read-only:

    STAGE=stage-16-e3u-c2-r2-ct203-read-only-completion-postflight
    NO_DB_WRITE
    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    DB_INTEGRITY=ok
    JOBS_TOTAL=27
    JOB_RESULTS_TOTAL=10
    JOB_28_RESULT_ROWS=1
    JOB_28_STATUS=completed
    JOB_28_ATTEMPTS=1
    JOB_28_TYPE=stage16_e3t_scheduler_dry_run_eligible_model_smoke
    JOB_28_MODEL=qwen2.5:32b-instruct-q4_K_M
    JOB_28_LAST_ERROR=None
    JOB_28_RESULT_ROWID=28
    JOB_28_RESULT_MODEL=qwen2.5:32b-instruct-q4_K_M
    JOB_28_RESULT_ERROR=None
    JOB_28_RESULT_RESPONSE_TEXT_LEN=200
    JOB_28_RESULT_RESPONSE_JSON_LEN=826
    RECOVERY_CLASSIFICATION=completed_with_one_result_do_not_rerun
    E3U_C2_R2_CT203_COMPLETION_POSTFLIGHT_OK

The CT203 DB stat did not change during the corrected read-only postflight:

    before=43798528 1782066624 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43798528 1782066624 /var/lib/edge-queue-controller/edge_queue.sqlite3

## PVESO and CT101 postflight

PVESO and CT101 were verified after completion:

    PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT_AFTER=0
    CT101_STATUS_AFTER=stopped
    CT101_ONBOOT_AFTER=0
    PVESO_CT101_POSTFLIGHT_OK

## Final classification

Job 28 completed exactly once and must not be rerun.

    RECOVERY_CLASSIFICATION=completed_with_one_result_do_not_rerun
    RECOVERY_DECISION=DO_NOT_RERUN_DOCUMENT_SUCCESS
    DO_NOT_RERUN_JOB_28

## Current state after E3U-C2

    jobs_total=27
    job_results_total=10
    job_28_status=completed
    job_28_attempts=1
    job_28_result_rows=1
    pveso_runner_count_after=0
    ct101_status=stopped
    ct101_onboot=0
    scheduler_activation=not_performed
    persistent_worker_activation=not_performed

## Next recommended phase

The next safe phase should be E3V-A, a no-apply design for converting the proven one-shot scheduler-selected dispatch into a repeatable scheduler-controlled lane while keeping:

- persistent scheduler disabled until separately approved
- persistent workers disabled until separately approved
- one-job-at-a-time guard
- duplicate result guard
- PVESO localhost-only Ollama guard
- CT101 stopped guard
- timeout recovery guard
