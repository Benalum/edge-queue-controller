# Stage 16 FC-O45-E-CL-H-R2 — Neutralize Unsafe Last-Message Source Branch

Date: 2026-06-26

## Summary

CL-H-R2 records the source neutralization of the unsafe CL-F-R2 Companion/Study `last_message` dispatcher branch.

CL-F-R2 was source-only and passed local smoke, but CL-G deployment proved the branch returned HTTP 200 without bearer authentication when called through:

    POST /api/companion/study/action

CL-G-R1 rolled the live backend back to the pre-CL-G backup. CL-G-R2 verified the live backend SHA and DB state. CL-G-R3 verified public route behavior after rollback.

CL-H-R1 attempted to neutralize the source branch and did apply the intended edit, but its smoke failed because it searched globally for `payload = await request.json()` and found an earlier unrelated route. CL-H-R2 fixes the smoke by scoping line-order validation to `_stage16_chc_companion_study_action_dispatch`.

## Scope

Repo backend source, docs, smoke, commit, tag, and push only.

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start/stop/restart, no service enable, no timer install/enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no PVESO call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Live rollback status before CL-H-R2

CL-G-R3 verified:

    public /api/system/status => HTTP 200
    public /api/companion/voice/status => HTTP 200
    unauthenticated last_message => HTTP 400 unsupported_companion_study_action
    unauthenticated supported status action => HTTP 401 Missing bearer token
    unauthenticated /api/companion/chat => HTTP 401 Missing bearer token
    unauthenticated /api/companion/jobs/581/result => HTTP 401 Missing bearer token
    CL-F contract not public after rollback
    deterministic_no_model not public after rollback

CL-G-R2 verified live CT203 backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

CL-G bad deploy SHA is not active:

    ce49016c13871cac8968eee9567ba4db4f2e3f96b017519731640ebcf887f1a5

DB remained unchanged:

    jobs_total=576
    results_total=83
    queued_companion=0
    cleanup_rows=440

## Source issue

The unsafe source branch was:

    Stage 16 FC-O45-E-CL-F-R2: authenticated deterministic last_message branch after JSON body parse

It returned the deterministic response directly from the dispatcher when action was:

    last_message
    last_message_mvp
    study_last_message

The deployment proved that this path did not actually enforce bearer authentication before returning HTTP 200.

## CL-H-R2 source state

The unsafe direct response branch is absent from source.

The dispatcher now contains the disabled marker:

    Stage 16 FC-O45-E-CL-H-R1: CL-F-R2 direct last_message branch is intentionally disabled

After CL-H-R2, `last_message` is unsupported again in source until a later patch wires it through an explicit auth dependency.

## What remains

The helper functions remain in source as inert code:

    _stage16_fc_o45_e_cl_f_study_last_message_text
    _stage16_fc_o45_e_cl_f_companion_study_last_message_mvp

They are not called from the Study action dispatcher after CL-H-R2.

A later repair patch may reuse or replace them only after an explicit auth gate is proven.

## Required behavior after future deploy

After a future deploy of CL-H-R2 or later safe source:

    unauthenticated action=last_message must not return HTTP 200
    unauthenticated action=last_message may return HTTP 400 unsupported
    supported protected actions must continue returning HTTP 401 Missing bearer token
    no deterministic_no_model response may be public without bearer auth

## Next recommendation

Do not deploy the CL-F-R2 source.

After CL-H-R2 is recorded, run a source-only auth pinpoint step to find the correct existing bearer dependency/helper used by protected Companion routes, then implement `last_message` only behind that explicit auth check.
