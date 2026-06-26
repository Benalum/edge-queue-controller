# Stage 16 FC-O45-E-CL-J — Rollback, Neutralization, and Safe Backend Deploy Record

Date: 2026-06-26

## Summary

CL-J records the CL-G through CL-I recovery sequence.

The CL-F-R2 source-only patch added a deterministic Companion/Study `last_message` MVP branch. CL-G deployed it to CT203, but public smoke proved the branch returned HTTP 200 without bearer authentication. The deployment was rolled back, then repo source was neutralized, then the neutralized safe source was deployed successfully.

## Key outcome

The live backend and repo main are safe again.

Unauthenticated `last_message` does not return a deterministic HTTP 200 response.

## CL-F-R2 source-only baseline

Repo commit:

    fea9291

Commit message:

    feat: add authenticated companion study last message mvp

Tag:

    controller-stage-16-fc-o45-e-cl-f-r2-authenticated-companion-study-last-message-mvp-source-only-2026-06-26

The source-only smoke passed locally, but deployment later proved the route branch did not enforce bearer auth.

## CL-G failed deploy

CL-G deployed repo source SHA:

    ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5

Old active backend SHA before CL-G:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

CL-G backup:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-cl-g-backend-last-message-mvp-deploy-20260626T151303Z/edge_controller.py.before-cl-g

CL-G backup SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

The backend service restarted and stayed active. DB counts were unchanged.

However, unauthenticated public smoke showed:

    POST /api/companion/study/action
    body: {"action":"last_message","input_text":"deploy smoke"}
    HTTP 200
    feature=stage16_fc_o45_e_cl_f_last_message_contract
    mode=deterministic_no_model
    model=backend-deterministic/no-model

This was an auth contract failure.

## CL-G-R1 rollback

CL-G-R1 restored the CL-G backup over the active CT203 backend and restarted only:

    edge-queue-controller.service

Active backend after rollback:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

DB before and after rollback remained unchanged:

    integrity=ok
    jobs_total=576
    results_total=83
    queued_companion=0
    cleanup_rows=440

CL-G-R1’s final public smoke expected `last_message` to return HTTP 401, but the rolled-back backend returned HTTP 400 unsupported. That was acceptable because the unsafe HTTP 200 behavior was removed.

## CL-G-R2 rollback verification

CL-G-R2 verified read-only:

    active backend SHA=1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2
    bad CL-G SHA not active=ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5
    CL-F markers absent from live backend
    DB integrity=ok
    jobs_total=576
    results_total=83
    queued_companion=0
    cleanup_rows=440

CL-G-R2 had a local public-smoke parser bug, later corrected by CL-G-R3.

## CL-G-R3 corrected public verification

CL-G-R3 verified public route behavior after rollback:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    POST /api/companion/study/action action=last_message => HTTP 400 unsupported_companion_study_action
    POST /api/companion/study/action action=status => HTTP 401 Missing bearer token
    POST /api/companion/chat => HTTP 401 Missing bearer token
    GET /api/companion/jobs/581/result => HTTP 401 Missing bearer token

CL-G-R3 verified:

    CL-F contract not public after rollback
    deterministic_no_model not public after rollback

## CL-H-R2 source neutralization

Repo advanced from:

    fea9291

to:

    5c80548

Commit message:

    fix: neutralize unsafe companion study last message branch

Tag:

    controller-stage-16-fc-o45-e-cl-h-r2-neutralize-unsafe-last-message-source-branch-2026-06-26

CL-H-R2 removed the unsafe direct dispatcher return path from source.

Source smoke verified:

    edge_controller.py compiles
    unsafe CL-F-R2 branch marker absent
    disabled CL-H-R1 marker present
    dispatch scoped validation passed
    helper contract remains inert
    no unsafe return call to _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp from dispatcher

The helper remains in source as inert code but is not called by the Study action dispatcher.

## CL-I safe neutralized backend deploy

CL-I deployed safe neutralized source to CT203.

Repo HEAD/origin/main:

    5c80548

Old active backend SHA before CL-I:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

New active backend SHA after CL-I:

    29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857

Bad CL-G deploy SHA not active:

    ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5

CL-I backup:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-cl-i-deploy-neutralized-safe-backend-20260626T153226Z/edge_controller.py.before-cl-i

CL-I backup SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Only `edge-queue-controller.service` was restarted. It remained active.

DB before and after CL-I remained unchanged:

    integrity=ok
    jobs_total=576
    results_total=83
    queued_companion=0
    cleanup_rows=440

Service posture remained safe:

    edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled
    edge-queue-scheduler-one-shot.service active=inactive enabled=static
    edge-deterministic-companion-worker-once@999999.service active=inactive enabled=static

## CL-I public route verification

CL-I verified after safe deploy:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    POST /api/companion/study/action action=last_message => HTTP 400 unsupported_companion_study_action
    POST /api/companion/study/action action=status => HTTP 401 Missing bearer token
    POST /api/companion/chat => HTTP 401 Missing bearer token
    GET /api/companion/jobs/581/result => HTTP 401 Missing bearer token

CL-I verified:

    public_last_message_no_unauth_200=yes
    public_last_message_returns_400_unsupported=yes
    protected_status_route_requires_bearer_401=yes
    companion_chat_requires_bearer_401=yes
    companion_job_result_requires_bearer_401=yes
    db_counts_unchanged=yes
    queued_companion_zero_verified=yes
    cleanup_rows_440_verified=yes

## Final posture

Repo main and live CT203 backend are aligned to the safe neutralized backend source.

The product path is not yet implemented, but the auth bypass is removed.

## Recommendation

Next step should be source-only auth pinpoint:

1. Identify the exact existing auth helper/dependency used by protected Companion routes.
2. Document where bearer enforcement occurs for `/api/companion/chat`, `/api/companion/context`, and `/api/companion/jobs/{job_id}/result`.
3. Only after that, add a new `last_message` branch behind the same explicit auth gate.
4. Do not deploy a new `last_message` branch until source smoke proves unauthenticated behavior remains non-200.
