# Stage 16 E3S-R2 — CT203 Read-Only Scheduler Dry-Run Result

## Result

E3S-R2 ran the committed E3S scheduler dry-run artifact against the CT203 live SQLite DB in read-only mode.

Outcome:

    E3S_R2_CT203_READ_ONLY_DRY_RUN_OK

## Repo checkpoint before run

    HEAD/origin/main/remote: b049466
    Tag: controller-stage-16-e3s-scheduler-dry-run-artifact-no-db-writes-2026-06-21
    Working tree: clean

## Safety boundary

The run was read-only CT203 DB inspection only.

No runtime/write actions were performed:

- no DB write
- no DB claim
- no helper call
- no adapter call
- no operator dispatch
- no model call
- no scheduler activation
- no persistent worker activation
- no CT101 start
- no service/CT/VM/Cloudflare/private-storage mutation

The artifact was streamed over stdin; no script file was copied into CT203.

## CT203 DB immutability check

Before:

    43798528 1782062257 /var/lib/edge-queue-controller/edge_queue.sqlite3

After:

    43798528 1782062257 /var/lib/edge-queue-controller/edge_queue.sqlite3

The before/after DB stat matched exactly.

## Dry-run output summary

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
    QUEUED_INSPECTED=2
    ELIGIBLE_WOULD_CLAIM_COUNT=0
    WOULD_CLAIM none
    NO_DB_WRITE

## Rejected queued jobs

The artifact inspected two queued jobs and rejected both due to model allowlist policy:

    REJECT model_not_allowlisted job_id=23 status=queued result_rows=0 job_type='ollama_chat' requested_model='gemma4:e4b' lane='model' lane_reason=job_type_contains:chat
    REJECT model_not_allowlisted job_id=24 status=queued result_rows=0 job_type='companion.chat' requested_model='mock/no-model' lane='model' lane_reason=job_type_contains:chat

## Conclusion

E3S now has both:

1. A committed scheduler dry-run artifact.
2. A successful live CT203 read-only dry-run proving it does not mutate the DB and does not claim jobs.

Next runtime-adjacent phases remain blocked pending explicit approval:

- E3T: insert one fresh scheduler-test queued job.
- E3U: run one scheduler-controlled dispatch smoke.

Do not reuse job 27.
