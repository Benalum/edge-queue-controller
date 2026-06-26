# Stage 16 FC-O45-E-CK-U — Read-Only Cleanup Status Taxonomy and Mutation Plan

Date: 2026-06-26

## Summary

CK-U completed a read-only cleanup status taxonomy for the old mock/no-model Companion backlog.

No mutation was executed.

## Scope

Read-only CT203 DB status taxonomy and mutation planning only.

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no commit, no tag, no push, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start/stop/restart, no service enable, no timer install/enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Runtime preflight

CT203 was running.

Cleanup dry-run tool SHA verified:

    16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f

Scheduler/timer/worker posture before and after:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

## Candidate fingerprint

The dry-run candidate fingerprint remained stable:

    CK_U_DRY_RUN_MODE=read_only
    CK_U_DRY_RUN_COUNT=440
    CK_U_DRY_RUN_MIN_ID=24
    CK_U_DRY_RUN_MAX_ID=570
    CK_U_DRY_RUN_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2
    CK_U_DRY_RUN_MUTATED=False

Independent candidate verification:

    CK_U_CANDIDATE_COUNT=440
    CK_U_CANDIDATE_MIN_ID=24
    CK_U_CANDIDATE_MAX_ID=570
    CK_U_CANDIDATE_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2

There are no other queued Companion rows outside this candidate set:

    CK_U_NON_CANDIDATE_QUEUED_COMPANION_COUNT=0

## DB integrity

    CK_U_DB_INTEGRITY=ok

## Jobs table schema observed

    id INTEGER PRIMARY KEY
    job_type TEXT NOT NULL
    prompt TEXT NOT NULL
    requested_model TEXT
    status TEXT NOT NULL DEFAULT 'queued'
    attempts INTEGER NOT NULL DEFAULT 0
    last_error TEXT
    created_at TEXT NOT NULL
    updated_at TEXT NOT NULL
    forwarded_at TEXT
    user_id INTEGER

## Existing status taxonomy

    CK_U_STATUS_COUNT status=queued count=465 min_id=23 max_id=570
    CK_U_STATUS_COUNT status=completed count=78 min_id=25 max_id=580
    CK_U_STATUS_COUNT status=forwarded count=18 min_id=1 max_id=21
    CK_U_STATUS_COUNT status=running count=10 min_id=53 max_id=105
    CK_U_STATUS_COUNT status=failed count=4 min_id=29 max_id=574

## Companion status taxonomy

    CK_U_TYPE_STATUS_COUNT job_type=companion.chat status=queued count=440 min_id=24 max_id=570
    CK_U_TYPE_STATUS_COUNT job_type=companion.chat status=completed count=17 min_id=124 max_id=580
    CK_U_TYPE_STATUS_COUNT job_type=companion.chat status=failed count=2 min_id=123 max_id=574

## Recommendation

Because no `canceled` or `cancelled` status exists, and because `failed` already exists as a non-executable terminal status, CK-U recommended:

    CK_U_RECOMMENDED_CLEANUP_STATUS=failed
    CK_U_RECOMMENDATION_REASON=existing_non_executable_status_present

## Proposed guarded mutation

The proposed mutation was not executed.

    CK_U_PROPOSED_MUTATION_NOT_EXECUTED=yes
    CK_U_PROPOSED_MUTATION_BACKUP_REQUIRED=yes
    CK_U_PROPOSED_MUTATION_WHERE=job_type='companion.chat' AND status='queued' AND attempts=0 AND result_rows=0 AND requested_model='mock/no-model'
    CK_U_PROPOSED_MUTATION_EXPECTED_COUNT=440
    CK_U_PROPOSED_MUTATION_EXPECTED_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2
    CK_U_PROPOSED_MUTATION_SET_STATUS=failed
    CK_U_PROPOSED_MUTATION_SET_LAST_ERROR=stage16_ck_cleanup_old_mock_no_model_backlog

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Operational conclusion

The old mock/no-model Companion backlog can be safely isolated by an exact candidate fingerprint.

A future cleanup mutation must still require separate approval and should:

1. Create a DB backup first.
2. Re-run the dry-run tool with expected count 440.
3. Re-check candidate id SHA-256:
   `2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2`
4. Update only the exact candidates to `status='failed'`.
5. Set `last_error='stage16_ck_cleanup_old_mock_no_model_backlog'`.
6. Verify queued Companion count becomes zero.
7. Verify no service, timer, worker, helper, model, or frontend/backend path ran.
