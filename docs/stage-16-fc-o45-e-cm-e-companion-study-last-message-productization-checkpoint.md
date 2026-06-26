# Stage 16 FC-O45-E-CM-E — Companion Study Last-Message Productization Checkpoint

Date: 2026-06-26

## Summary

CM-E records CM-D, the read-only productization checkpoint for the Study Companion last-message MVP.

CM-E is docs/smoke only.

No frontend source patch, frontend deploy, public /var/www mutation, backend source patch, backend deploy, CT203 runtime patch, DB write, schema migration, job mutation, result insert, service mutation, timer/worker activation, model/Ollama/PVESO call, CT/VM restart, or secret printing occurs in CM-E.

## Repo baseline

Repo HEAD/origin/main before CM-E:

    3d9bd59

Previous record commit:

    docs: record authenticated companion ui proof

Previous tag:

    controller-stage-16-fc-o45-e-cm-c-record-token-safe-authenticated-public-last-message-proof-2026-06-26

Repo wrapper app SHA:

    c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

## Productized pieces

The current stable Study Companion last-message MVP includes:

    backend auth-gated last_message action
    deterministic no-model response contract
    wrapper UI control deployed to VM200 app.js
    signed-out public UI behavior verified
    authenticated public behavior verified
    temporary authenticated proof session revoked
    no job/result/model/timer/worker activation for this MVP path

## Backend checkpoint

CM-D verified active CT203 backend SHA:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

CM-D verified:

    edge-queue-controller.service active
    auth-gated last_message source marker present
    _study_current_user_id(request) used before helper return
    backend-deterministic/no-model contract present

## Database checkpoint

CM-D verified CT203 DB:

    integrity=ok
    jobs_total=576
    results_total=83
    queued_companion=0
    running_total=10
    cleanup_rows=440
    active_sessions=89
    revoked_sessions=117

The productization checkpoint made no DB writes.

## Worker and timer posture

CM-D verified checked CT203 worker/timer units were inactive or not found:

    edge-deterministic-companion-once.service inactive or not-found
    edge-deterministic-companion-once@.service not-found
    edge-queue-worker.service inactive or not-found
    edge-queue-worker.timer inactive or not-found
    edge-ct203-deterministic-companion-once.service inactive or not-found
    edge-ct203-deterministic-companion-once.timer inactive or not-found

No scheduler, timer, persistent worker, helper, selector, model, Ollama, or PVESO path was activated.

## VM200 static checkpoint

CM-D verified VM200 app.js:

    path=/var/www/apc-wrapper-local/app.js
    bytes=571050
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835
    CL-U marker present=yes
    signed-out copy present=yes

CM-D verified VM200 index.html:

    path=/var/www/apc-wrapper-local/index.html
    sha256=0a22952302d2973c6911f7b051a695df7848e7c422d3aa4c08d51a9882cddfed

VM200 index references:

    /app.js?v=20260624fc045eccmanual2

CM-D verified VM200 nginx and cloudflared were active.

## Public checkpoint

CM-D verified public root:

    GET / => HTTP 200

Public root references:

    /app.js?v=20260624fc045eccmanual2

CM-D verified public referenced app.js:

    GET /app.js?v=20260624fc045eccmanual2 => HTTP 200
    bytes=571050
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835
    CL-U marker present=yes
    signed-out copy present=yes

CM-D verified public status routes:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200

Voice status returned a disabled/safe marker.

CM-D verified signed-out protection:

    POST /api/companion/study/action action=last_message => HTTP 401
    POST /api/companion/study/action action=status => HTTP 401

## Authenticated proof already recorded

CM-C recorded CM-B-R2 token-safe authenticated public proof:

    temporary restricted PVEW token/script files
    one temporary CT203 user_sessions row inserted
    public authenticated last_message HTTP 200
    response contract matched deterministic no-model expected fields
    guardrails confirmed no job/result/model/Ollama/PVESO/scheduler/timer/worker activation
    temporary session revoked
    post-revoke unauthenticated last_message HTTP 401
    jobs_total remained 576
    results_total remained 83
    active temp sessions returned 0
    token/hash/password/env secret values not printed

## Current productization conclusion

The Study Companion last-message MVP is stable at the intended first productization level.

It is intentionally simple:

    no model call
    no queue insert
    no result insert
    no worker activation
    no timer activation
    no PVESO/Ollama call

This makes it a safe public signed-in Study Companion control while preserving backend auth and avoiding the previous Companion queue/model instability.

## Recommended next options

Option 1: Source refresh and new chat handoff.

This is the safest checkpoint handoff because the public last-message MVP is now proven signed-out and authenticated.

Option 2: UI polish.

Improve the visible Study Companion panel layout/copy while preserving the existing backend contract.

Option 3: Add a real authenticated Study Companion action.

Add one small authenticated action behind the same auth guard, still no scheduler or persistent worker activation until explicitly approved.

Option 4: Plan model-backed Companion later.

Do this only after a separate contract defines bounded model use, retries, exactness expectations, and rollback.
