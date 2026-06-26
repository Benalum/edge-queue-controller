# Stage 16 FC-O45-E-CL-O — Auth-Gated Last-Message Source and Deploy Record

Date: 2026-06-26

## Summary

CL-O records the CL-M and CL-N safe reimplementation/deployment of the Companion/Study `last_message` MVP.

CL-M reimplemented the `last_message` branch in repo source only, with the auth call placed before the deterministic helper return.

CL-N deployed that auth-gated source to CT203 and proved unauthenticated `last_message` now returns HTTP 401 `Missing bearer token` instead of the unsafe HTTP 200 behavior seen during CL-G.

## CL-M source-only patch

Repo advanced from:

    8e612dd

to:

    e281a6e

Commit:

    fix: gate companion study last message auth

Tag:

    controller-stage-16-fc-o45-e-cl-m-auth-gated-last-message-source-only-2026-06-26

CL-M added the source marker:

    Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch

CL-M branch order was verified by smoke:

    payload_line=23554
    action_line=23565
    branch_line=23569
    if_line=23573
    auth_line=23574
    return_line=23575
    status_line=23580

The important ordering proof is:

    _stage16_cl_m_user_id = _study_current_user_id(request)

comes before:

    return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp(...)

## Auth helper used

The branch calls:

    _study_current_user_id(request)

CL-K and CL-L recorded that `_study_current_user_id(request)` calls:

    _auth_current_user_from_request(request)

which calls:

    _auth_get_bearer_token(request)

and raises:

    HTTPException(status_code=401, detail="Missing bearer token.")

when the bearer token is missing.

## CL-M deterministic helper proof

CL-M helper unit validation returned:

    ok=True
    action=last_message
    mode=deterministic_no_model
    model=backend-deterministic/no-model
    job_id=None
    user_id=123

Guardrails were true for:

    no_model_call
    no_ollama_call
    no_pveso_call
    no_job_insert
    no_result_insert
    no_scheduler_activation
    no_timer_activation
    no_persistent_worker_activation

## CL-N backend deploy

CL-N deployed the auth-gated source to CT203 with approval:

    APPROVE_CL_N_DEPLOY_AUTH_GATED_LAST_MESSAGE_TO_CT203

Old active backend SHA:

    29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857

New active backend SHA:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

Bad CL-G deploy SHA is not active:

    ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5

CL-N runtime backup:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-cl-n-deploy-auth-gated-last-message-20260626T154445Z/edge_controller.py.before-cl-n

CL-N backup SHA:

    29f1cc92f9c6c7a6c1c89b8b8454c2d0118a820b0d9df58dc6cc947bc3c4d857

Only `edge-queue-controller.service` was restarted. It remained active.

## CL-N DB proof

DB state before and after CL-N remained unchanged:

    integrity=ok
    jobs_total=576
    results_total=83
    queued_companion=0
    cleanup_rows=440

## CL-N posture proof

The scheduler/timer/worker posture stayed safe:

    edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled
    edge-queue-scheduler-one-shot.service active=inactive enabled=static
    edge-deterministic-companion-worker-once@999999.service active=inactive enabled=static

CL-N did not activate a selector, manual wrapper, helper, model, Ollama, PVESO, scheduler, timer, or persistent worker.

## CL-N public unauthenticated proof

After deploy, public unauthenticated behavior was:

    GET /api/system/status => HTTP 200
    GET /api/companion/voice/status => HTTP 200
    POST /api/companion/study/action action=last_message => HTTP 401 Missing bearer token
    POST /api/companion/study/action action=status => HTTP 401 Missing bearer token
    POST /api/companion/chat => HTTP 401 Missing bearer token
    GET /api/companion/jobs/581/result => HTTP 401 Missing bearer token

This proves the `last_message` branch is now behind bearer auth and no longer exposes unauthenticated deterministic HTTP 200.

## Final state

Repo main and live CT203 backend are aligned with the auth-gated source.

The unauthenticated auth-bypass regression from CL-G is fixed.

The authenticated `last_message` success path still needs a separate proof using a safe non-printing bearer-token strategy.

## Recommendation

Next step should be a read-only/token-safe authenticated proof plan:

1. Identify or create a non-printing bearer-token strategy.
2. Do not echo token values.
3. Use a temp file or env value with restricted output if a token is needed.
4. Prove authenticated `POST /api/companion/study/action` with `action=last_message` returns HTTP 200.
5. Verify response fields:
   - action=last_message
   - mode=deterministic_no_model
   - model=backend-deterministic/no-model
   - job_id=null
6. Verify DB counts unchanged and no model/Ollama/PVESO/scheduler/timer/worker activation.
