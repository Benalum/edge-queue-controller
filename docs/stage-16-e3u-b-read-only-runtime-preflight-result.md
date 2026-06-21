# Stage 16 E3U-B — Read-Only Runtime Preflight Result

## Result

E3U-B completed the read-only runtime preflight for the future scheduler-controlled dispatch of job 28.

The preflight was split because the first PVESO SSH attempt used the unresolved host alias `pveso`. The CT203 DB and E3S dry-run checks passed in the first run. PVESO/CT101 checks passed in E3U-B-R6 using the Tailscale status address with `root@<redacted-tailscale-ip>`.

Final outcome:

    E3U_B_READ_ONLY_RUNTIME_PREFLIGHT_OK
    E3U_B_R6_PVESO_CT101_PREFLIGHT_OK

## Repo checkpoint

    HEAD/origin/main/remote: 24266ef
    Tag: controller-stage-16-e3u-a-scheduler-controlled-dispatch-runtime-plan-no-apply-2026-06-21
    Working tree: clean

## Safety boundary

The full E3U-B preflight was read-only only.

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
- no job completion
- no job_result insert
- no service/CT/VM/Cloudflare/private-storage mutation

## CT203 DB preflight

The CT203 DB was opened read-only with immutable SQLite URI mode.

Markers:

    STAGE=stage-16-e3u-b-ct203-db-read-only-runtime-preflight
    NO_DB_WRITE
    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    TARGET_JOB_ID=28
    DB_CLAIM=not_performed
    HELPER_CALL=not_performed
    ADAPTER_CALL=not_performed
    OPERATOR_DISPATCH_CALL=not_performed
    MODEL_CALL=not_performed
    SCHEDULER_ACTIVATION=not_performed
    PERSISTENT_WORKER_ACTIVATION=not_performed
    JOB_COMPLETION=not_performed
    JOB_RESULT_INSERT=not_performed
    DB_INTEGRITY=ok

Current DB counts:

    JOBS_TOTAL=27
    JOB_RESULTS_TOTAL=9

Job 28 state:

    JOB_28_RESULT_ROWS=0
    JOB_28_STATUS=queued
    JOB_28_ATTEMPTS=0
    JOB_28_TYPE=stage16_e3t_scheduler_dry_run_eligible_model_smoke
    JOB_28_MODEL=qwen2.5:32b-instruct-q4_K_M
    JOB_28_PROMPT=APC_STAGE16_E3T_SCHEDULER_DRY_RUN_CANDIDATE
    JOB_28_CREATED_AT=2026-06-21T18:12:48Z
    JOB_28_UPDATED_AT=2026-06-21T18:12:48Z

Queued inventory:

    QUEUED_TOTAL=3
    QUEUED_JOB id=23 status=queued attempts=3 job_type='ollama_chat' requested_model='gemma4:e4b'
    QUEUED_JOB id=24 status=queued attempts=0 job_type='companion.chat' requested_model='mock/no-model'
    QUEUED_JOB id=28 status=queued attempts=0 job_type='stage16_e3t_scheduler_dry_run_eligible_model_smoke' requested_model='qwen2.5:32b-instruct-q4_K_M'

DB preflight result:

    E3U_CT203_DB_PREFLIGHT_OK
    NO_DB_WRITE

## E3S dry-run recheck

The committed E3S dry-run artifact was streamed over stdin into CT203 and run read-only.

Markers:

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

The dry-run rejected older queued jobs 23 and 24 as expected:

    REJECT model_not_allowlisted job_id=23 status=queued result_rows=0 job_type='ollama_chat' requested_model='gemma4:e4b' lane='model' lane_reason=job_type_contains:chat
    REJECT model_not_allowlisted job_id=24 status=queued result_rows=0 job_type='companion.chat' requested_model='mock/no-model' lane='model' lane_reason=job_type_contains:chat

The DB stat before and after the read-only CT203 checks remained unchanged:

    before=43798528 1782065568 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43798528 1782065568 /var/lib/edge-queue-controller/edge_queue.sqlite3

## PVESO SSH target recovery

The host alias `pveso` did not resolve from the laptop:

    ssh pveso failed with Temporary failure in name resolution

Tailscale status still showed a PVESO node. Root SSH to the Tailscale status address worked:

    PVESO_TAILSCALE_STATUS_LOOKUP=OK
    PVESO_TARGET=<redacted-tailscale-ip>
    root SSH_OK

Future PVESO PPB checks should derive the PVESO address from `tailscale status` or repair the SSH alias separately in a no-runtime maintenance step.

## PVESO and CT101 read-only preflight

E3U-B-R6 passed the PVESO/CT101 read-only preflight.

Markers:

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
    PVESO_CT101_PREFLIGHT_OK

## Current runtime readiness state

E3U runtime conditions are satisfied:

    job 28 is queued
    job 28 attempts=0
    job 28 result rows=0
    E3S dry-run WOULD_CLAIM job_id=28
    CT203 DB integrity=ok
    PVESO Ollama service=active
    PVESO Ollama listener=127.0.0.1:11434 only
    PVESO non-localhost Ollama listener count=0
    PVESO runner count=0
    CT101 status=stopped
    CT101 onboot=0

## Next approval boundary

The future E3U runtime apply requires this exact approval phrase:

    APPROVE_STAGE_16_E3U_RUN_ONE_SCHEDULER_CONTROLLED_DISPATCH_FOR_JOB_28_ONLY

Allowed only after approval:

- run exactly one scheduler-controlled dispatch attempt for job 28
- use the already-proven controlled dispatch path
- verify job 28 completes exactly once
- verify exactly one result row for job 28
- verify job_results total becomes 10
- verify PVESO runner count returns to zero

Denied even after approval:

- persistent scheduler activation
- persistent worker activation
- lane worker activation
- broad queue draining
- dispatch of job 23 or job 24
- reuse of job 27
- a second run for job 28
- CT101 start
- PVESO/Ollama public exposure
- service/CT/VM/Cloudflare/private-storage mutation

Do not reuse job 27.
