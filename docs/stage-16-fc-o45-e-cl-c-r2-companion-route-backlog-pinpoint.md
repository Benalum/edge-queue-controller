# Stage 16 FC-O45-E-CL-C / CL-C-R2 — Companion Route and Backlog Pinpoint

Date: 2026-06-26

## Summary

CL-C performed a read-only Companion route and non-Companion backlog pinpoint.

CL-C successfully gathered the route, DB, and public behavior inventory, but had one non-mutating cleanup-tool JSON validation defect. CL-C-R2 corrected that subcheck and completed cleanly.

## Scope

Read-only repo source, CT203 active source, DB, and public route behavior inventory only.

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no commit, no tag, no push, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start/stop/restart, no service enable, no timer install/enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no PVESO call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Repo state

CL-C and CL-C-R2 ran at:

    41db87e

The repo remained clean.

## CT203 runtime

CT203 was running.

Active backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Cleanup dry-run tool SHA:

    16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f

Service posture before and after:

    edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled
    edge-queue-scheduler-one-shot.service active=inactive enabled=static
    edge-deterministic-companion-worker-once@999999.service active=inactive enabled=static

No worker, timer, scheduler, model, PVESO, or Ollama path ran.

## Route marker sanity

CL-C-R2 verified these active backend route markers are present:

    /api/companion/chat
    /public/companion/chat
    /api/companion/jobs/{job_id}/result
    /api/companion/study/action
    /public/companion/study/action
    /api/companion/context
    /public/companion/context
    /api/companion/voice/status
    /api/companion/voice/action
    companion_execution
    deterministic_exact_answer_short_circuit
    backend-deterministic/no-model

CL-C also found active backend functions for:

    api_companion_study_action
    public_companion_study_action
    api_companion_voice_status
    public_companion_voice_status
    api_companion_voice_action
    public_companion_voice_action
    _stage16_cj_j_companion_exact_answer_result
    _stage16_cj_j_companion_short_circuit_contract

## CL-C defect and CL-C-R2 correction

CL-C attempted to parse cleanup-tool JSON using a pipe into `python3 - <<'PY_CLEANUP'`.

That pattern made Python read the heredoc as the script, not the cleanup-tool JSON as stdin, producing:

    json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)

CL-C-R2 corrected this by capturing the cleanup-tool JSON into a variable and passing it as an argument.

Corrected cleanup-tool validation:

    CL_C_R2_CLEANUP_TOOL_OK=True
    CL_C_R2_CLEANUP_TOOL_MODE=read_only
    CL_C_R2_CLEANUP_TOOL_CANDIDATE_COUNT=0
    CL_C_R2_CLEANUP_TOOL_MIN_ID=None
    CL_C_R2_CLEANUP_TOOL_MAX_ID=None
    CL_C_R2_CLEANUP_TOOL_ID_SHA256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    CL_C_R2_CLEANUP_TOOL_MUTATED=False

## DB validation

CL-C-R2 DB validation:

    CL_C_R2_DB_INTEGRITY=ok
    CL_C_R2_JOBS_TOTAL=576
    CL_C_R2_RESULTS_TOTAL=83
    CL_C_R2_QUEUED_COMPANION=0
    CL_C_R2_CLEANUP_ROWS=440
    CL_C_R2_QUEUED_ANY=25
    CL_C_R2_RUNNING_ANY=10

CK-Y job 581 remained complete:

    CL_C_R2_CK_Y_JOB id=581 status=completed attempts=1 requested_model=qwen2.5:0.5b result_rows=1 result_model=backend-deterministic/no-model response_text=FC-O45-E-CK-Y-POST-CLEANUP-SELECTOR-OK

## Pending non-Companion backlog

CL-C-R2 verified 25 queued jobs and 10 running jobs remain, all outside queued `companion.chat`.

Queued:

    CL_C_R2_PENDING_TYPE job_type=ollama_chat status=queued count=1 min_id=23 max_id=23
    CL_C_R2_PENDING_TYPE job_type=stage16_e3z_limited_persistent_worker_repeat_proof status=queued count=6 min_id=59 max_id=64
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_companion_chat_general_queue status=queued count=1 min_id=66 max_id=66
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_flashcards_general_queue status=queued count=1 min_id=68 max_id=68
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_json_general_queue status=queued count=1 min_id=70 max_id=70
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_router_label_general_queue status=queued count=1 min_id=71 max_id=71
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_safe_refusal_general_queue status=queued count=1 min_id=72 max_id=72
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_study_tutor_general_queue status=queued count=1 min_id=67 max_id=67
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_summary_general_queue status=queued count=1 min_id=69 max_id=69
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_companion_chat_semantic_probe status=queued count=3 min_id=108 max_id=118
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_flashcards_semantic_probe status=queued count=3 min_id=103 max_id=120
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_safe_refusal_semantic_probe status=queued count=2 min_id=111 max_id=121
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_study_tutor_semantic_probe status=queued count=3 min_id=102 max_id=119

Running:

    CL_C_R2_PENDING_TYPE job_type=stage16_e3z_limited_persistent_worker_repeat_proof status=running count=3 min_id=53 max_id=58
    CL_C_R2_PENDING_TYPE job_type=stage16_fb_r5_exact_marker_sanity status=running count=1 min_id=65 max_id=65
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_companion_chat_semantic_probe status=running count=2 min_id=100 max_id=101
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_json_semantic_probe status=running count=1 min_id=99 max_id=99
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_safe_refusal_semantic_probe status=running count=1 min_id=104 max_id=104
    CL_C_R2_PENDING_TYPE job_type=stage16_fc_summary_semantic_probe status=running count=2 min_id=97 max_id=105

## Public unauthenticated route behavior

CL-C-R2 verified these public unauthenticated responses:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    GET /api/companion/context => HTTP 401 Missing bearer token
    POST /api/companion/chat => HTTP 401 Missing bearer token
    POST /api/companion/study/action => HTTP 401 Missing bearer token
    GET /api/companion/jobs/581/result => HTTP 401 Missing bearer token

## Operational conclusion

The Companion queue is clean and protected:

    queued_companion=0
    cleanup_rows=440
    cleanup_tool_candidate_count=0
    job581 completed exact marker
    unauthenticated Companion context/chat/study/result routes require bearer auth

The remaining backlog is stale non-Companion proof/probe traffic:

    queued_any=25
    running_any=10

Next recommended source-only step: define a guarded authenticated Companion/Study last-message MVP patch while separately planning cleanup or exclusion of the stale non-Companion proof/probe backlog.
