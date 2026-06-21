# Stage 16 E3V-I — Implement Dry-Run-Only Wrapper Guard Path

## Result

E3V-I implemented the real dry-run-only guard path in the E3V Option B wrapper.

This phase did not execute the wrapper.

It only changed repo files and ran static smoke.

## Updated wrapper

    ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh

The wrapper now supports:

    --dry-run

as a real read-only guard path.

The execute-approved path remains blocked:

    REFUSE_E3V_EXECUTE_NOT_ENABLED

## Safety boundary

E3V-I did not:

- execute the wrapper
- write the DB
- apply a schema migration
- insert a job
- claim a job
- call the helper
- call the adapter
- call a model
- activate scheduler
- activate persistent workers
- start CT101
- mutate services, CTs, VMs, Cloudflare, or private storage

## Dry-run-only behavior implemented

The dry-run path is designed to emit:

    NO_DB_WRITE
    NO_SCHEMA_MIGRATION
    NO_DB_CLAIM
    NO_HELPER_CALL
    NO_ADAPTER_CALL
    NO_MODEL_CALL
    SCHEDULER_ACTIVATION=not_performed
    PERSISTENT_WORKER_ACTIVATION=not_performed
    DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
    DB_INTEGRITY=ok
    CT203_DB_STAT_UNCHANGED=true
    PVESO_PREFLIGHT_OK
    E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK

The dry-run candidate outcomes are:

    E3V_DRY_RUN_RESULT=NO_ELIGIBLE_JOB_NO_RUNTIME
    E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME

The dry-run path must not claim jobs.

## Runtime remains blocked

Even with the approval phrase:

    APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY

the execute-approved path remains blocked:

    REFUSE_E3V_EXECUTE_NOT_ENABLED

## Static smoke result

Static smoke verified the wrapper contains:

- read-only DB mode
- query_only pragma
- no DB claim markers
- no helper/adapter/model markers
- PVESO Tailscale lookup
- PVESO localhost-only listener checks
- CT101 stopped/onboot checks
- DB stat unchanged check
- dry-run final pass marker
- execute-approved refusal marker

Static smoke also rejected known runtime/write patterns.

## Next recommended phase

Next phase:

    E3V-J execute the dry-run-only wrapper guard path, read-only

That phase may execute:

    ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh --dry-run

but must still perform no DB write, no job claim, no adapter call, and no model call.
