# Stage 16 FC-O45-E-CL-A / CL-A-R2 — Companion Productization Inventory

Date: 2026-06-26

## Summary

CL-A gathered the read-only Companion productization inventory after the mock/no-model backlog cleanup and fresh selector proof.

CL-A had one non-mutating scripting defect: the cleanup-tool JSON zero-candidate subcheck used invalid Python quoting and produced a `SyntaxError`.

CL-A-R2 corrected only that failed subcheck and completed cleanly.

## Scope

Read-only repo source, CT203 runtime, DB, and public API inventory only.

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no commit, no tag, no push, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start/stop/restart, no service enable, no timer install/enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no PVESO call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Repo state

CL-A and CL-A-R2 ran at:

    d89f376

The repo remained clean.

## CT203 runtime files

Active backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Runtime helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Runtime systemd unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

Runtime manual wrapper SHA:

    481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595

Runtime selector SHA:

    1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41

Cleanup dry-run tool SHA:

    16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f

## Service posture

Observed before and after validation:

    edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled
    edge-queue-scheduler-one-shot.service active=inactive enabled=static
    edge-deterministic-companion-worker-once@999999.service active=inactive enabled=static

No worker, timer, scheduler, model, PVESO, or Ollama path ran.

## Live backend route inventory

CL-A found these Companion-related backend routes or markers in the active CT203 backend:

    /public/companion/study/grade
    /api/companion/study/grade
    /public/companion/context
    /api/companion/context
    /public/companion/chat
    /api/companion/jobs/{job_id}/result
    /api/companion/chat
    /api/companion/study/action
    /public/companion/study/action
    /api/companion/voice/status
    /public/companion/voice/status
    /api/companion/voice/action
    /public/companion/voice/action

CL-A also found the deterministic exact-answer short-circuit backend markers:

    companion_execution
    deterministic_exact_answer_short_circuit
    backend-deterministic/no-model
    companion_exact_answer_short_circuit

## DB inventory from CL-A

DB integrity:

    CL_A_DB_INTEGRITY=ok

Totals:

    CL_A_JOBS_TOTAL=576
    CL_A_RESULTS_TOTAL=83

Status counts:

    CL_A_STATUS_COUNT status=failed count=444 min_id=24 max_id=574
    CL_A_STATUS_COUNT status=completed count=79 min_id=25 max_id=581
    CL_A_STATUS_COUNT status=queued count=25 min_id=23 max_id=121
    CL_A_STATUS_COUNT status=forwarded count=18 min_id=1 max_id=21
    CL_A_STATUS_COUNT status=running count=10 min_id=53 max_id=105

Companion status counts:

    CL_A_COMPANION_STATUS_COUNT status=failed count=442 min_id=24 max_id=574
    CL_A_COMPANION_STATUS_COUNT status=completed count=18 min_id=124 max_id=581

Key queue/productization values:

    CL_A_QUEUED_COMPANION=0
    CL_A_QUEUED_ANY=25
    CL_A_RUNNING_ANY=10
    CL_A_CLEANUP_ROWS=440

CK-Y job verification:

    CL_A_CK_Y_JOB id=581 status=completed attempts=1 requested_model=qwen2.5:0.5b result_rows=1 result_model=backend-deterministic/no-model response_text=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK

## CL-A defect and CL-A-R2 correction

CL-A attempted to validate that the cleanup dry-run tool now returns zero candidates, but the inline Python command had invalid f-string escaping and produced:

    SyntaxError: unexpected character after line continuation character

CL-A-R2 corrected that validation.

Corrected cleanup-tool JSON validation:

    CL_A_R2_CLEANUP_TOOL_OK=True
    CL_A_R2_CLEANUP_TOOL_MODE=read_only
    CL_A_R2_CLEANUP_TOOL_CANDIDATE_COUNT=0
    CL_A_R2_CLEANUP_TOOL_MIN_ID=None
    CL_A_R2_CLEANUP_TOOL_MAX_ID=None
    CL_A_R2_CLEANUP_TOOL_ID_SHA256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    CL_A_R2_CLEANUP_TOOL_MUTATED=False

Corrected DB validation:

    CL_A_R2_DB_INTEGRITY=ok
    CL_A_R2_JOBS_TOTAL=576
    CL_A_R2_RESULTS_TOTAL=83
    CL_A_R2_QUEUED_COMPANION=0
    CL_A_R2_CLEANUP_ROWS=440
    CL_A_R2_DB_VALIDATION_DONE=yes

Corrected CK-Y verification:

    CL_A_R2_CK_Y_JOB id=581 status=completed attempts=1 requested_model=qwen2.5:0.5b result_rows=1 result_model=backend-deterministic/no-model response_text=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK

## Public API observations

Public GET returned HTTP 200:

    /api/system/status
    /api/companion/voice/status

Public unauthenticated POST returned HTTP 401:

    /api/companion/study/action

The 401 body was:

    {"detail":"Missing bearer token."}

This confirms the Study action API exists and is protected.

## Productization conclusion

The post-cleanup Companion baseline is clean:

    queued_companion=0
    cleanup_rows=440
    cleanup_tool_candidate_count=0
    job581 completed exact marker
    public system and voice status healthy
    study action endpoint protected by bearer auth

The next productization step should be source-only: define the authenticated Companion/Study last-message MVP path and decide whether the next runtime proof should use deterministic no-model execution or a bounded real-model queue path.
