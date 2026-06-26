# Stage 16 FC-O45-E-CL-M — Auth-Gated Last-Message Source-Only Reimplementation

Date: 2026-06-26

## Summary

CL-M reimplements the Companion/Study `last_message` branch in source only, now gated by the existing Study auth helper.

The branch calls:

    user_id = _study_current_user_id(request)

before returning any deterministic response.

This directly addresses the CL-G auth bypass, where the earlier CL-F-R2 branch returned a deterministic HTTP 200 response before calling existing bearer auth.

## Scope

Repo backend source, docs, smoke, commit, tag, and push only.

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start/stop/restart, no service enable, no timer install/enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no PVESO call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Baseline

CL-L recorded the auth pinpoint at repo HEAD/origin/main:

    8e612dd

CL-K verified live CT203 active backend SHA:

    29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857

CL-K verified DB state:

    integrity=ok
    jobs_total=576
    results_total=83
    queued_companion=0
    cleanup_rows=440

CL-K verified public behavior:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    POST /api/companion/study/action action=last_message => HTTP 400 unsupported_companion_study_action
    POST /api/companion/study/action action=status => HTTP 401 Missing bearer token
    POST /api/companion/chat => HTTP 401 Missing bearer token
    GET /api/companion/jobs/581/result => HTTP 401 Missing bearer token

## Auth helper used

CL-M uses:

    _study_current_user_id(request)

CL-K proved this helper calls:

    _auth_current_user_from_request(request)

and that `_auth_current_user_from_request(request)` calls:

    _auth_get_bearer_token(request)

If no bearer token exists, the helper raises:

    HTTPException(status_code=401, detail="Missing bearer token.")

## Source change

CL-M replaces the CL-H disabled marker with a new branch:

    Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch

The branch supports:

    last_message
    last_message_mvp
    study_last_message

The branch order is:

    action normalized
    if action in last_message aliases
    user_id = _study_current_user_id(request)
    return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp(payload, user_id=user_id)

## Deterministic response

After auth succeeds, the branch returns the existing deterministic no-model helper contract:

    feature=stage16_fc_o45_e_cl_f_last_message_contract
    surface=companion_study
    action=last_message
    authenticated=True
    mode=deterministic_no_model
    model=backend-deterministic/no-model
    source=stage16_fc_o45_e_cl_f_direct_deterministic_response
    job_id=None

## Guardrails

This source-only patch does not:

    call a model
    call Ollama
    call PVESO
    insert a job
    insert a result
    start a scheduler
    start a timer
    start a persistent worker

## Required later deploy proof

A later deploy proof must verify:

    unauthenticated action=last_message returns HTTP 401 Missing bearer token
    authenticated action=last_message returns HTTP 200
    response.action=last_message
    response.mode=deterministic_no_model
    response.model=backend-deterministic/no-model
    queued_companion remains 0
    jobs_total and results_total remain unchanged unless intentionally changed
    no model/Ollama/PVESO call
    no scheduler/timer/persistent-worker activation

## Next step

CL-N should deploy this source to CT203 with a runtime backup and service restart only.

CL-O should then run an authenticated controlled proof. If no reusable bearer token is available in the test harness, CL-O should first perform a read-only token discovery strategy that does not print secret token values.
