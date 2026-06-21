# Stage 16 E3T-C + E3S-R4 — Insert One Scheduler-Test Job and Prove Read-Only Would-Claim

## Result

E3T-C inserted exactly one fresh scheduler-test queued job into the CT203 DB under the approved E3T boundary.

E3S-R4 then reran the committed scheduler dry-run artifact against the live CT203 DB in read-only mode and proved it would select the new job without mutating the DB.

Outcomes:

    E3T_C_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_OK
    E3S_R4_CT203_READ_ONLY_DRY_RUN_WOULD_CLAIM_JOB_28_OK

## Repo checkpoint during runtime work

    HEAD/origin/main/remote: 2c5af87
    Tag: controller-stage-16-e3t-b-r2-ct203-read-only-insert-preflight-result-2026-06-21
    Working tree: clean

## E3T-C approval boundary

Approval phrase used:

    APPROVE_STAGE_16_E3T_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_ONLY

Allowed by approval:

- insert exactly one fresh queued scheduler-test job into CT203 DB
- verify one new job row
- verify zero result rows for the new job
- verify DB integrity remains ok
- record the new job id

Denied and not performed:

- DB claim
- helper call
- adapter call
- operator dispatch
- model call
- scheduler activation
- persistent worker activation
- CT101 start
- job completion
- job_result insert
- service/CT/VM/Cloudflare/private-storage mutation

## E3T-C insert result

Before insert:

    JOBS_BEFORE=26
    JOB_RESULTS_BEFORE=9
    MAX_JOB_ID_BEFORE=27
    E3T_MARKER_HITS_BEFORE=0
    E3T_JOB_TYPE_HITS_BEFORE=0
    DB_INTEGRITY_BEFORE=ok

After insert:

    NEW_JOB_ID=28
    JOBS_AFTER=27
    JOB_RESULTS_AFTER=9
    MAX_JOB_ID_AFTER=28
    E3T_MARKER_HITS_AFTER=1
    E3T_JOB_TYPE_HITS_AFTER=1
    DB_INTEGRITY_AFTER=ok

New job fields:

    NEW_JOB_STATUS=queued
    NEW_JOB_TYPE=stage16_e3t_scheduler_dry_run_eligible_model_smoke
    NEW_JOB_MODEL=qwen2.5:32b-instruct-q4_K_M
    NEW_JOB_PROMPT=APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE
    NEW_JOB_ATTEMPTS=0
    NEW_JOB_RESULT_ROWS=0
    NEW_JOB_CREATED_AT=2026-06-21T18:12:48Z
    NEW_JOB_UPDATED_AT=2026-06-21T18:12:48Z

CT203 DB stat changed as expected for the approved insert:

    before=43798528 1782062257 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43798528 1782065568 /var/lib/edge-queue-controller/edge_queue.sqlite3

## E3S-R4 read-only dry-run result

E3S-R4 streamed the committed E3S artifact over stdin into CT203 and did not copy a script file into CT203.

The dry-run output included:

    STAGE=stage-16-e3s-scheduler-dry-run-artifact-no-db-writes
    NO_DB_WRITE
    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    RUNTIME_CALLS=disabled
    SCHEDULER_ACTIVATION=not_performed
    PERSISTENT_WORKER_ACTIVATION=not_performed
    HELPER_CALL=not_performed
    ADAPTER_CALL=not_performed
    OPERATOR_DISPATCH_CALL=not_performed
    MODEL_CALL=not_performed
    DB_INTEGRITY=ok
    QUEUED_INSPECTED=3
    ELIGIBLE_WOULD_CLAIM_COUNT=1
    WOULD_CLAIM job_id=28 lane=model model=qwen2.5:32b-instruct-q4_K_M result_rows=0 created=2026-06-21T18:12:48Z updated=2026-06-21T18:12:48Z
    NO_DB_WRITE

E3S-R4 rejected the two older queued jobs as expected:

    REJECT model_not_allowlisted job_id=23 status=queued result_rows=0 job_type='ollama_chat' requested_model='gemma4:e4b' lane='model' lane_reason=job_type_contains:chat
    REJECT model_not_allowlisted job_id=24 status=queued result_rows=0 job_type='companion.chat' requested_model='mock/no-model' lane='model' lane_reason=job_type_contains:chat

E3S-R4 DB stat remained unchanged before and after the read-only dry-run:

    before=43798528 1782065568 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43798528 1782065568 /var/lib/edge-queue-controller/edge_queue.sqlite3

## Current state after E3T-C and E3S-R4

    jobs=27
    job_results=9
    job 28 status=queued
    job 28 attempts=0
    job 28 result rows=0
    scheduler activation=not performed
    persistent worker activation=not performed
    helper/adapter/operator/model path=not performed

## Next recommended phase

Stage 16 E3U should be a scheduler-controlled dispatch runtime design or preflight.

E3U is runtime-adjacent and must require a new explicit approval before any of the following:

- DB claim
- claim/lease write
- helper call
- adapter call
- operator dispatch call
- model call
- job completion
- job_result insert
- scheduler activation
- persistent worker activation

Do not reuse job 27.
