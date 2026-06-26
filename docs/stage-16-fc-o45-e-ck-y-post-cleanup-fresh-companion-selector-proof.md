# Stage 16 FC-O45-E-CK-Y — Post-Cleanup Fresh Companion Selector Proof

Date: 2026-06-26

## Summary

CK-Y proved that after the old mock/no-model Companion backlog cleanup, a fresh marker-specific `companion.chat` job can be inserted and completed through the installed marker-selected selector wrapper.

The fresh job completed exactly and did not call a model.

## Approval

    APPROVAL=APPROVE_CK_Y_INSERT_ONE_FRESH_COMPANION_JOB_AND_RUN_SELECTOR_ONCE

## Scope

CT203 insert one fresh Companion job plus installed selector one-shot only.

Allowed actions:

- insert exactly one fresh `companion.chat` job
- run installed marker-selected selector wrapper exactly once for that marker
- start exactly one deterministic Companion one-shot systemd instance for the fresh job

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no commit, no tag, no push, no backend deploy, no CT203 backend runtime patch, no schema migration, no result insert except wrapper/helper completion for the one fresh job, no service enable, no timer install/enable/start, no persistent worker activation, no scheduler activation, no model/helper/Ollama call, no PVESO call, no CT/VM restart, no package install, and no secret values printed.

## Runtime component verification

Runtime helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Runtime systemd unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

Runtime manual wrapper SHA:

    481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595

Runtime selector SHA:

    1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41

Cleanup tool SHA:

    16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f

## Backlog cleanup remained clean

Before inserting the fresh job, the cleanup tool refused the old expected mock backlog count:

    CK_Y_PRE_CLEANUP_TOOL_RC=3
    REFUSE_EXPECTED_COUNT_MISMATCH expected=440 actual=0

Pre-insert DB snapshot:

    CK_Y_PRE_DB_INTEGRITY=ok
    CK_Y_PRE_JOBS_TOTAL=575
    CK_Y_PRE_RESULTS_TOTAL=82
    CK_Y_PRE_QUEUED_COMPANION=0

## Fresh job insertion

Inserted job:

    CK_Y_JOB_ID=581

Insert details:

    job_type=companion.chat
    requested_model=qwen2.5:0.5b
    status=queued
    attempts=0
    marker=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK
    created_at=2026-06-26T05:25:23.145463Z

## Selector preflight

The selector preflight found exactly one matching job:

    CK_Y_SELECTOR_PREFLIGHT_MATCH_COUNT=1
    CK_Y_SELECTOR_PREFLIGHT_MATCH id=581 status=queued attempts=0 job_type=companion.chat requested_model=qwen2.5:0.5b result_rows=0

## Selector and one-shot service proof

The installed marker-selected selector wrapper ran once.

It selected job 581 and delegated to:

    /opt/edge-queue-controller/ops/workers/run-deterministic-companion-systemd-once.sh

The manual wrapper started exactly:

    edge-deterministic-companion-worker-once@581.service

Service result:

    service_active_state=inactive
    service_result=success
    service_exec_main_status=0

The per-job env file was created and removed.

## Final job verification

Final job result:

    CK_Y_FINAL_JOB_ID=581
    CK_Y_FINAL_STATUS=completed
    CK_Y_FINAL_ATTEMPTS=1
    CK_Y_FINAL_RESULT_ROWS=1
    CK_Y_FINAL_RESULT_MODEL=backend-deterministic/no-model
    CK_Y_FINAL_RESPONSE_TEXT=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK
    CK_Y_FINAL_RESULT_ERROR=None
    CK_Y_FINAL_JOBS_TOTAL=576
    CK_Y_FINAL_RESULTS_TOTAL=83
    CK_Y_FINAL_QUEUED_COMPANION=0

## Posture

Before and after CK-Y:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

No persistent worker, scheduler, model, PVESO, or Ollama path ran.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Operational conclusion

The old mock/no-model Companion backlog cleanup did not break the deterministic Companion selector path.

After cleanup, a fresh marker-specific Companion job can be safely selected and completed with exact output:

    FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK

This is the clean post-backlog baseline for the next Companion work.
