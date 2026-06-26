# Stage 16 FC-O45-E-CL-R — Token-Safe Authenticated Last-Message Proof Record

Date: 2026-06-26

## Summary

CL-R records the CL-P through CL-Q-R3 token-safe authenticated proof sequence for the Companion/Study `last_message` MVP.

The result is now proven end-to-end through the public route:

    POST /api/companion/study/action
    action=last_message
    authenticated HTTP 200

The route remains protected when unauthenticated:

    POST /api/companion/study/action
    action=last_message
    unauthenticated HTTP 401 Missing bearer token

## Current repo and backend state

Repo HEAD/origin/main before CL-R:

    3d229bf

Live CT203 active backend SHA:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

Source marker present:

    Stage 16 FC-O45-E-CL-M: auth-gated deterministic last_message branch

Auth call present before deterministic helper return:

    _stage16_cl_m_user_id = _study_current_user_id(request)

Deterministic helper return present:

    return _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp

Unsafe CL-F-R2 branch marker absent:

    Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse

## CL-P token-safe preflight

CL-P completed read-only.

It verified:

    active backend SHA=eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30
    auth-gated source present
    DB counts verified
    public unauthenticated last_message still HTTP 401

It printed no:

    token values
    token hashes
    password hashes
    env secret values

CL-P found the auth path:

    _auth_get_bearer_token(request)
    _auth_current_user_from_request(request)
    _study_current_user_id(request)

Behavior:

    _auth_get_bearer_token(request) reads the Authorization header
    _auth_current_user_from_request(request) hashes the bearer token
    user_sessions is joined to active app_users
    revoked_at must be NULL
    expires_at must be greater than now
    missing bearer token raises HTTP 401 Missing bearer token

Relevant auth tables:

    app_users
    user_sessions

Relevant session columns:

    token_hash
    expires_at
    revoked_at
    last_seen_at

## CL-Q caveat

CL-Q proved the local CT203 authenticated HTTP 200 path with a non-printing temporary token.

However, the public authenticated request from inside CT203 failed due to a DNS resolution error:

    Temporary failure in name resolution

The script printed a misleading conclusion claiming public authenticated 200 was proved. That public proof claim is invalid.

Valid CL-Q findings:

    local authenticated last_message HTTP 200 proved
    temporary session inserted and revoked
    no token values printed
    no token hashes printed
    public unauthenticated last_message after proof remained HTTP 401

## CL-Q-R2 caveat

CL-Q-R2 attempted to prove the public authenticated path from PVEW.

It verified PVEW DNS worked, but failed before DB temp session insert because the CT203-side insert process attempted to read a PVEW-local token hash file path:

    FileNotFoundError

The script printed a misleading conclusion claiming public authenticated proof completed. That claim is invalid.

Valid CL-Q-R2 findings:

    PVEW DNS for alexhartel.com worked
    active backend SHA verified
    live auth-gated source verified
    no temp session inserted
    PVEW token temp directory removed
    no token values printed
    no token hashes printed

## CL-Q-R3 final public authenticated proof

CL-Q-R3 fixed the PVEW-vs-CT203 temp-file issue by:

1. Creating a temporary bearer token in a restricted PVEW temp file.
2. Computing its token hash on PVEW.
3. Pushing only the token hash file to a restricted CT203 temp path.
4. Inserting one short-lived temporary user_sessions row in CT203 using the CT-local hash file.
5. Calling the public alexhartel.com route from PVEW using the PVEW-local bearer token file.
6. Revoking the temporary session row after proof.
7. Removing both CT203 and PVEW temp token directories.

No token values or token hashes were printed.

## CL-Q-R3 DB proof

Before insert:

    CL_Q_R3_DB_BEFORE_INTEGRITY=ok
    CL_Q_R3_DB_BEFORE_JOBS_TOTAL=576
    CL_Q_R3_DB_BEFORE_RESULTS_TOTAL=83
    CL_Q_R3_DB_BEFORE_QUEUED_COMPANION=0
    CL_Q_R3_DB_BEFORE_CLEANUP_ROWS=440
    CL_Q_R3_DB_BEFORE_MARKER_SESSIONS_TOTAL=0
    CL_Q_R3_DB_BEFORE_MARKER_SESSIONS_ACTIVE=0

After temporary session insert:

    CL_Q_R3_DB_AFTER_INSERT_INTEGRITY=ok
    CL_Q_R3_DB_AFTER_INSERT_JOBS_TOTAL=576
    CL_Q_R3_DB_AFTER_INSERT_RESULTS_TOTAL=83
    CL_Q_R3_DB_AFTER_INSERT_QUEUED_COMPANION=0
    CL_Q_R3_DB_AFTER_INSERT_CLEANUP_ROWS=440
    CL_Q_R3_DB_AFTER_INSERT_MARKER_SESSIONS_TOTAL=1
    CL_Q_R3_DB_AFTER_INSERT_MARKER_SESSIONS_ACTIVE=1

After revoke:

    CL_Q_R3_DB_AFTER_REVOKE_INTEGRITY=ok
    CL_Q_R3_DB_AFTER_REVOKE_JOBS_TOTAL=576
    CL_Q_R3_DB_AFTER_REVOKE_RESULTS_TOTAL=83
    CL_Q_R3_DB_AFTER_REVOKE_QUEUED_COMPANION=0
    CL_Q_R3_DB_AFTER_REVOKE_CLEANUP_ROWS=440
    CL_Q_R3_DB_AFTER_REVOKE_MARKER_SESSIONS_TOTAL=1
    CL_Q_R3_DB_AFTER_REVOKE_MARKER_SESSIONS_ACTIVE=0

## CL-Q-R3 public authenticated response proof

CL-Q-R3 public authenticated request returned:

    CL_Q_R3_PUBLIC_HTTP=200

Response fields matched:

    ok=True
    feature=stage16_fc_o45_e_cl_f_last_message_contract
    surface=companion_study
    action=last_message
    authenticated=True
    mode=deterministic_no_model
    model=backend-deterministic/no-model
    job_id=None
    user_id present=True

Guardrails matched true:

    no_model_call
    no_ollama_call
    no_pveso_call
    no_job_insert
    no_result_insert
    no_scheduler_activation
    no_timer_activation
    no_persistent_worker_activation

## CL-Q-R3 public unauthenticated protection after revoke

After the temp session was revoked, CL-Q-R3 proved:

    CL_Q_R3_PUBLIC_UNAUTH_AFTER_REVOKE_HTTP=401
    CL_Q_R3_PUBLIC_UNAUTH_AFTER_REVOKE_STILL_401=yes

It also verified the unauthenticated response did not expose:

    stage16_fc_o45_e_cl_f_last_message_contract
    deterministic_no_model

## CL-Q-R3 posture proof

Before and after proof, posture remained safe:

    edge-queue-scheduler-one-shot.timer active=inactive enabled=disabled
    edge-queue-scheduler-one-shot.service active=inactive enabled=static
    edge-deterministic-companion-worker-once@999999.service active=inactive enabled=static

No selector, manual wrapper, helper, model, Ollama, PVESO, scheduler, timer, or persistent worker was activated.

## Final conclusion

The public Companion/Study `last_message` MVP is now proven:

    authenticated path returns HTTP 200
    unauthenticated path returns HTTP 401
    deterministic no-model response is returned only after bearer auth
    no job or result is inserted
    no model/Ollama/PVESO call occurs
    no scheduler/timer/persistent-worker activation occurs
    temporary session was revoked
    no token/token-hash/password/env secret values were printed

## Recommendation

This closes the backend-safe `last_message` MVP proof.

Next options:

1. Create a source refresh zip and new-chat handoff.
2. Add a small UI button or panel that calls the authenticated `last_message` action.
3. Keep UI unchanged and move to the next Study/Companion backend action.
