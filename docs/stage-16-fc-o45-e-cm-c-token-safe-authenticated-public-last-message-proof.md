# Stage 16 FC-O45-E-CM-C — Token-Safe Authenticated Public Last-Message Proof Record

Date: 2026-06-26

## Summary

CM-C records CM-B-R2, the repaired token-safe authenticated public proof for the deployed Study Companion last-message UI/backend path.

CM-C is docs/smoke only.

No frontend source patch, frontend deploy, public /var/www mutation, backend source patch, backend deploy, CT203 runtime patch, DB write, schema migration, job mutation, result insert, service mutation, timer/worker activation, model/Ollama/PVESO call, CT/VM restart, or secret printing occurs in CM-C.

## Repo baseline

Repo HEAD/origin/main before CM-C:

    c936e48

Previous record commit:

    docs: record signed-out companion ui proof

Previous tag:

    controller-stage-16-fc-o45-e-cm-a-record-signed-out-public-ui-verification-2026-06-26

Repo wrapper app SHA:

    c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

CL-U marker:

    APC_COMPANION_LAST_MESSAGE_CL_U

## Failed CM-B attempt

CM-B failed before inserting a temporary session.

Cause:

    Python SyntaxError in generated insert SQL:
    sql = f"INSERT INTO user_sessions ({,.join(names)}) VALUES ({placeholders})"

The issue was shell quoting around comma join syntax.

CM-B cleanup ran, token/hash values were not printed, and no public authenticated proof occurred in CM-B.

## CM-B-R2 repaired proof

CM-B-R2 repaired the generated SQL by constructing the INSERT statement without fragile shell quoting.

CM-B-R2 used:

    temporary restricted PVEW token/script files
    one temporary CT203 user_sessions row
    public authenticated POST /api/companion/study/action action=last_message
    temporary CT203 session revoke
    temporary PVEW file cleanup

No token values were printed.

No token hashes were printed.

No password hashes were printed.

No env secret values were printed.

## Runtime baselines verified

CM-B-R2 verified CT203 backend SHA:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

CM-B-R2 verified VM200 app SHA:

    c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

CM-B-R2 verified VM200 app has the CL-U marker.

CM-B-R2 verified VM200 nginx and cloudflared were active.

## DB baseline before temporary session

Before inserting the temporary session, CM-B-R2 verified:

    integrity=ok
    jobs_total=576
    results_total=83
    active_temp_sessions=0

## Temporary session lifecycle

CM-B-R2 inserted one temporary CT203 user_sessions row without printing:

    token value
    token hash
    user id
    session id

CM-B-R2 later revoked the temporary session.

After revoke, CM-B-R2 verified:

    active_temp_sessions=0

## Public UI source path

CM-B-R2 verified public root:

    GET / => HTTP 200

Public root referenced:

    /app.js?v=20260624fc045eccmanual2

CM-B-R2 verified that public referenced app.js returned:

    HTTP 200
    sha256=c26e1d6dded0260218418afe6312a1c0cbf25059cf255f448945f6f4bebf2835

The referenced app.js contained:

    APC_COMPANION_LAST_MESSAGE_CL_U
    Please sign in to use the Study Companion.

## Public authenticated last-message proof

CM-B-R2 performed public authenticated request:

    POST /api/companion/study/action
    action=last_message

Result:

    HTTP 200

CM-B-R2 validated the authenticated response fields:

    ok=true
    feature=stage16_fc_o45_e_cl_f_last_message_contract
    surface=companion_study
    action=last_message
    authenticated=true
    mode=deterministic_no_model
    model=backend-deterministic/no-model
    job_id=None
    user_id present

CM-B-R2 validated guardrails:

    no_model_call=true
    no_ollama_call=true
    no_pveso_call=true
    no_job_insert=true
    no_result_insert=true
    no_scheduler_activation=true
    no_timer_activation=true
    no_persistent_worker_activation=true

## Post-revoke unauthenticated safety

After revoking the temporary session, CM-B-R2 verified:

    POST /api/companion/study/action action=last_message without bearer => HTTP 401

No deterministic no-model response was exposed to unauthenticated requests.

No backend-deterministic model label was exposed to unauthenticated requests.

## DB state after proof

After the proof, CM-B-R2 verified:

    integrity=ok
    jobs_total=576
    results_total=83
    active_temp_sessions=0

CM-B-R2 verified:

    jobs_total unchanged: 576 before and 576 after
    results_total unchanged: 83 before and 83 after

## Conclusion

The deployed public Study Companion last-message path is now proven for signed-out and authenticated behavior.

Signed-out public behavior:

    UI app loads from public cache-busted app.js
    UI contains signed-in-required copy
    unauthenticated last_message remains HTTP 401

Authenticated public behavior:

    temporary session authenticated last_message returns HTTP 200
    deterministic no-model response contract matches expected fields
    no job/result/model/Ollama/PVESO/scheduler/timer/worker activation occurs
    temporary session is revoked
    DB job/result counts remain unchanged

## Recommended next step

Next stage should be CM-D read-only productization checkpoint.

It should summarize:

    backend auth-gated last_message route complete
    wrapper UI control deployed
    signed-out public proof complete
    authenticated public proof complete
    voice/speech remains disabled by design
    no model path activated for last-message MVP
    next safe feature direction: improve UI polish or add a real authenticated Study Companion action behind the same auth guard
