# Stage 16 FC-O45-E-CL-F-R2 — Authenticated Companion/Study Last-Message MVP Source-Only Patch

Date: 2026-06-26

## Summary

CL-F-R2 repairs and commits the CL-F source-only backend patch for the authenticated Companion/Study last-message MVP.

CL-F initially timed out after writing a partial source patch. CL-F-R0 confirmed the partial patch was compile-safe but placed the `last_message` branch before `await request.json()`, so it could not see posted JSON. CL-F-R2 moves the branch after JSON body parsing and action normalization.

## Scope

Repo backend source, docs, smoke, commit, tag, and push only.

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start/stop/restart, no service enable, no timer install/enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no PVESO call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Baseline

CL-E baseline:

    HEAD/origin/main=1f2c811
    queued_companion=0
    cleanup_rows=440
    cleanup_tool_candidate_count=0
    CK-Y job581 completed exact marker
    unauthenticated Companion routes return HTTP 401 Missing bearer token

## Source change

CL-F-R2 modifies:

    edge_controller.py

It adds or repairs:

    _stage16_fc_o45_e_cl_f_study_last_message_text
    _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp

It patches the existing dispatcher:

    _stage16_chc_companion_study_action_dispatch

The repaired branch is placed after:

    payload = await request.json()
    action = _stage16_chc_companion_study_action_normalize(...)

## MVP action

The new supported action is:

    last_message

Aliases accepted:

    last_message_mvp
    study_last_message

## Authenticated API route limit

The CL-F-R2 branch only returns the MVP response when the request path is:

    /api/companion/study/action

The public mirror route falls through to existing unsupported-action behavior for this new action.

This avoids adding new public unauthenticated behavior.

## Response contract

The deterministic response includes:

    ok=True
    feature=stage16_fc_o45_e_cl_f_last_message_contract
    surface=companion_study
    action=last_message
    authenticated=True
    mode=deterministic_no_model
    model=backend-deterministic/no-model
    source=stage16_fc_o45_e_cl_f_direct_deterministic_response
    job_id=None

The response also includes:

    response.message
    response.text
    guardrails.no_model_call=True
    guardrails.no_ollama_call=True
    guardrails.no_pveso_call=True
    guardrails.no_job_insert=True
    guardrails.no_result_insert=True
    guardrails.no_scheduler_activation=True
    guardrails.no_timer_activation=True
    guardrails.no_persistent_worker_activation=True

## Smoke validation

The CL-F-R2 smoke verifies:

    edge_controller.py compiles
    helper contract exists exactly once
    old premature branch marker is absent
    repaired branch marker exists exactly once
    repaired branch appears after request JSON parsing and action normalization
    response helper returns deterministic_no_model
    response helper returns backend-deterministic/no-model
    response helper returns job_id=None
    guardrails are true
    only intended files changed

## Important limitation

CL-F-R2 is source-only.

It does not deploy this backend change to CT203.

The live backend SHA remains unchanged until a later approved deploy step.

## Next steps

Recommended next sequence:

1. CL-G deploy backend source to CT203 with runtime backup.
2. CL-H run authenticated controlled proof for `POST /api/companion/study/action` with `action=last_message`.
3. CL-I record deploy/proof.

CL-H must verify:

    authenticated request returns HTTP 200
    unauthenticated request remains HTTP 401 Missing bearer token
    response.action=last_message
    response.authenticated=True
    response.mode=deterministic_no_model
    response.model=backend-deterministic/no-model
    queued_companion remains 0
    no model/Ollama/PVESO call
    no scheduler/timer/persistent-worker activation
