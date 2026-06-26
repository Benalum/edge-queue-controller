# Stage 16 FC-O45-E-CK-W — Guarded Mock Companion Backlog Cleanup

Date: 2026-06-26

## Summary

CK-W completed the guarded cleanup of the old mock/no-model queued Companion backlog.

The mutation was approved, backed up, fingerprint-checked immediately before execution, and verified after execution.

## Approval

    APPROVAL=APPROVE_CK_W_MARK_440_OLD_MOCK_COMPANION_JOBS_FAILED

## Scope

CT203 live DB backup plus exact candidate status update only.

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no commit, no tag, no push, no backend deploy, no CT203 backend runtime patch, no schema migration, no job insert, no result insert, no service start/stop/restart, no service enable, no timer install/enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Runtime preflight

CT203 was running.

Cleanup dry-run tool SHA verified:

    16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f

Scheduler/timer/worker posture before mutation:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

Scheduler/timer/worker posture after mutation:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

## Pre-mutation fingerprint check

The dry-run fingerprint was verified immediately before mutation:

    CK_W_DRY_RUN_MODE=read_only
    CK_W_DRY_RUN_COUNT=440
    CK_W_DRY_RUN_MIN_ID=24
    CK_W_DRY_RUN_MAX_ID=570
    CK_W_DRY_RUN_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2
    CK_W_DRY_RUN_MUTATED=False

## Backup

Backup directory:

    /var/lib/edge-queue-controller/stage-16-fc-o45-e-ck-w-cleanup-old-mock-companion-backlog-20260626T052209Z

Backup DB:

    /var/lib/edge-queue-controller/stage-16-fc-o45-e-ck-w-cleanup-old-mock-companion-backlog-20260626T052209Z/edge_queue.sqlite3.before-ck-w

Backup verification:

    CK_W_BACKUP_INTEGRITY=ok
    CK_W_BACKUP_JOBS_TOTAL=575
    CK_W_BACKUP_RESULTS_TOTAL=82
    CK_W_BACKUP_SHA256=2d62696dfc5d4f8365f434c6888b39e29f6b1c2861dfe9dff43207a56302b625

## Mutation

Mutation name:

    old_mock_companion_backlog_mark_failed

Exact candidate criteria:

    job_type=companion.chat
    status=queued
    attempts=0
    result_rows=0
    requested_model=mock/no-model

Mutation result:

    updated_rows=440
    cleanup_status=failed
    cleanup_last_error=stage16_ck_cleanup_old_mock_no_model_backlog
    candidate_count_before=440
    candidate_min_id=24
    candidate_max_id=570
    candidate_id_sha256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2
    jobs_total_before=575
    jobs_total_after=575
    job_results_total_before=82
    job_results_total_after=82
    remaining_candidates=0
    failed_cleanup_count=440
    updated_at=2026-06-26T05:22:19.724702Z

## Post-mutation verification

Post-mutation read-only verification passed:

    CK_W_POST_DB_INTEGRITY=ok
    CK_W_POST_JOBS_TOTAL=575
    CK_W_POST_RESULTS_TOTAL=82
    CK_W_POST_QUEUED_COMPANION=0
    CK_W_POST_REMAINING_CANDIDATES=0
    CK_W_POST_CLEANUP_ROWS=440
    CK_W_POST_CLEANUP_MIN_ID=24
    CK_W_POST_CLEANUP_MAX_ID=570
    CK_W_POST_CLEANUP_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2

The dry-run tool then correctly refused the old expected count:

    CK_W_POST_DRYRUN_RC=3
    REFUSE_EXPECTED_COUNT_MISMATCH expected=440 actual=0

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Operational conclusion

The old mock/no-model queued `companion.chat` backlog has been removed from the executable queued set.

Current verified cleanup outcome:

    queued_companion_count_after=0
    remaining_mock_no_model_candidates_after=0
    job_results_unchanged=yes

This clears the way for fresh marker-specific Companion jobs to be tested without accidentally selecting the old mock backlog.
