# Stage 16 FC-O45-E-CL-L — Companion Auth Pinpoint Record

Date: 2026-06-26

## Summary

CL-L records the CL-K read-only Companion auth pinpoint.

The purpose is to document the exact bearer-auth helper path and the safe insertion requirement before reimplementing the Companion/Study `last_message` MVP.

## Current safe state

Repo HEAD/origin/main before CL-L:

    5bf148e

Live CT203 active backend SHA verified by CL-K:

    29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857

Live DB counts verified by CL-K:

    integrity=ok
    jobs_total=576
    results_total=83
    queued_companion=0
    cleanup_rows=440

Public route behavior verified by CL-K:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    POST /api/companion/study/action action=last_message => HTTP 400 unsupported_companion_study_action
    POST /api/companion/study/action action=status => HTTP 401 Missing bearer token
    POST /api/companion/chat => HTTP 401 Missing bearer token
    GET /api/companion/jobs/581/result => HTTP 401 Missing bearer token

## Auth helper pinpoint

CL-K identified the core auth helper:

    def _auth_current_user_from_request(request: Request):

This helper calls:

    _auth_get_bearer_token(request)

If no bearer token exists, it raises:

    HTTPException(status_code=401, detail="Missing bearer token.")

CL-K also identified the study helper:

    def _study_current_user_id(request: Request) -> int:

This helper calls:

    _auth_current_user_from_request(request)

and returns:

    int(user_row["id"])

## Important lesson from CL-G

The CL-F-R2 `last_message` branch returned the deterministic response directly from the Study action dispatcher before the branch called the existing study auth helper.

That caused the CL-G deploy to expose:

    POST /api/companion/study/action
    action=last_message
    HTTP 200 unauthenticated

with:

    feature=stage16_fc_o45_e_cl_f_last_message_contract
    mode=deterministic_no_model
    model=backend-deterministic/no-model

That behavior was rolled back, source-neutralized, and safely redeployed by CL-G-R1 through CL-I.

## Safe future implementation rule

Any future `last_message` implementation must call this before returning a deterministic response:

    user_id = _study_current_user_id(request)

The auth call must happen inside the `last_message` branch and before:

    _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp(...)

A safe branch must preserve:

    unauthenticated action=last_message must not return HTTP 200
    missing bearer token must return HTTP 401 Missing bearer token
    no model/Ollama/PVESO call
    no job insert
    no result insert
    no scheduler/timer/persistent-worker activation

## Source state after CL-H-R2 and CL-I

The unsafe CL-F-R2 branch marker is absent:

    Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse

The safe disabled marker is present:

    Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled

The helper contract remains inert in source:

    _stage16_fc_o45_e_cl_f_study_last_message_text
    _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp

It must not be called from the Study action dispatcher until explicit auth is wired first.

## Recommended next step

CL-M should be source-only and should:

1. Add a new `last_message` branch after JSON parsing and action normalization.
2. Call `_study_current_user_id(request)` before returning.
3. Pass `user_id=user_id` into the deterministic helper.
4. Include source smoke proving the auth call appears before the helper return inside the branch.
5. Include a unit-style smoke check where a fake request with no auth path raises or preserves the auth requirement.
6. Make no backend deploy, no DB/job/result mutation, no service/timer/worker activation, and no model/Ollama/PVESO call.

Only after CL-M source-only passes should a later deploy step be considered.
