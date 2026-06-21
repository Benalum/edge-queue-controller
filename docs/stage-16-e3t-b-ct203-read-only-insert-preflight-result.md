# Stage 16 E3T-B — CT203 Read-Only Insert Preflight Result

## Result

E3T-B performed a read-only CT203 DB schema and marker preflight for the future E3T scheduler-test job insert.

Outcome:

    E3T_B_CT203_READ_ONLY_INSERT_PREFLIGHT_OK

## Safety boundary

The preflight was read-only only.

No runtime/write actions were performed:

- no DB write
- no job insert
- no DB claim
- no helper call
- no adapter call
- no operator dispatch
- no model call
- no scheduler activation
- no persistent worker activation
- no CT101 start
- no service/CT/VM/Cloudflare/private-storage mutation

## Repo checkpoint before preflight

    HEAD/origin/main/remote: 655e03a
    Tag: controller-stage-16-e3t-a-fresh-scheduler-test-job-insert-plan-no-apply-2026-06-21
    Working tree: clean

## CT203 DB immutability check

Before:

    43798528 1782062257 /var/lib/edge-queue-controller/edge_queue.sqlite3

After:

    43798528 1782062257 /var/lib/edge-queue-controller/edge_queue.sqlite3

The before/after DB stat matched exactly.

## CT203 DB summary

    DB_INTEGRITY=ok
    JOBS_COUNT=26
    JOB_RESULTS_COUNT=9
    MAX_JOB_ID=27

## Discovered jobs table schema

    id
    job_type
    prompt
    requested_model
    status
    attempts
    last_error
    created_at
    updated_at
    forwarded_at
    user_id

## Discovered job_results table schema

    job_id
    model
    response_text
    response_json
    error
    created_at
    updated_at

## Insert-relevant column mapping

    ID_COLUMN=id
    STATUS_COLUMN=status
    TYPE_COLUMN=job_type
    MODEL_COLUMN=requested_model
    LANE_COLUMN=None
    PAYLOAD_COLUMNS=prompt

There is no lane column in the live jobs table. Future E3T apply should not invent or write a lane column.

## Existing queued jobs

The preflight inspected two queued jobs:

    QUEUED_JOB id=23 status=queued job_type='ollama_chat' requested_model='gemma4:e4b' lane=None
    QUEUED_JOB id=24 status=queued job_type='companion.chat' requested_model='mock/no-model' lane=None

These were known from E3S-R2 and remain unrelated to the future E3T marker job.

## E3T marker check

    E3T_MARKER_HITS=0
    E3T_JOB_TYPE_HITS=0
    E3T_INSERT_PREFLIGHT=OK_NO_EXISTING_E3T_MARKER

The future E3T apply may proceed only after explicit approval.

## Future E3T apply boundary

Required approval phrase:

    APPROVE_STAGE_16_E3T_INSERT_ONE_FRESH_SCHEDULER_TEST_JOB_ONLY

Allowed only after approval:

- insert exactly one fresh queued scheduler-test job into CT203 DB
- use the live schema discovered in this preflight
- verify exactly one new job row
- verify zero result rows for the new job
- verify job status is queued
- verify DB integrity remains ok
- document the new job id

Denied even after approval:

- scheduler activation
- DB claim
- claim/lease write
- helper call
- adapter call
- operator dispatch call
- model call
- job completion
- job_result insert
- persistent worker activation
- lane worker activation
- CT101 start
- service/CT/VM/Cloudflare/private-storage mutation
- reuse of job 27

## Proposed future insert shape

Using the discovered schema, the future insert should target only these columns:

    job_type
    prompt
    requested_model
    status
    attempts
    last_error
    created_at
    updated_at
    forwarded_at
    user_id

Recommended values:

    job_type=stage16_e3t_scheduler_dry_run_eligible_model_smoke
    prompt=APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE
    requested_model=qwen2.5:32b-instruct-q4_K_M
    status=queued
    attempts=0
    last_error=NULL
    created_at=<utc_now>
    updated_at=<utc_now>
    forwarded_at=NULL
    user_id=NULL

Do not reuse job 27.
