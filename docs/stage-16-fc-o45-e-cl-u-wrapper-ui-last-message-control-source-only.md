# Stage 16 FC-O45-E-CL-U — Wrapper UI Last-Message Control Source-Only Patch

Date: 2026-06-26

## Summary

CL-U adds a minimal source-only wrapper UI control for the authenticated Study Companion last-message MVP.

This patch changes only:

    frontend/wrapper-ui/app.js
    docs/stage-16-fc-o45-e-cl-u-wrapper-ui-last-message-control-source-only.md
    ops/smoke/check-stage-16-fc-o45-e-cl-u-wrapper-ui-last-message-control-source-only.sh

No frontend deploy or public /var/www mutation occurs in CL-U.

## Baseline

Repo HEAD/origin/main before CL-U:

    89edbd8

CL-T identified the safest first UI source target as:

    frontend/wrapper-ui/app.js

Live backend SHA previously proved:

    eaed8a3abea6c49b623a0dea3f22c26b9b0afaf3e120c9259a5bdd105c562d30

The backend route is already proven:

    POST /api/companion/study/action
    action=last_message
    authenticated HTTP 200
    unauthenticated HTTP 401

## Source marker

CL-U adds this marker:

    APC_COMPANION_LAST_MESSAGE_CL_U

## UI behavior

The wrapper UI now mounts a small Study Companion panel inside the existing Study tools panel.

The control:

    accepts typed input
    calls /api/companion/study/action
    sends action last_message
    sends input_text from the user
    displays signed-in-required text on HTTP 401
    displays a small deterministic response summary on HTTP 200

## Auth behavior

The source uses:

    credentials: include

and attempts common browser token storage keys only if present.

No token values are hardcoded.

No token values are printed.

No token hashes are printed.

No password hashes are printed.

No env secret values are printed.

## Guardrails

CL-U does not:

    deploy frontend assets
    mutate public /var/www
    patch backend source
    deploy backend runtime
    write DB rows
    insert jobs
    insert results
    start services
    enable services
    install or start timers
    activate workers
    call models
    call Ollama
    call PVESO
    restart CTs or VMs

## Next step

CL-V should be read-only or deploy-plan only unless explicitly approved.

A later deploy should verify:

    public signed-out UI still works
    signed-out last-message control shows signed-in-required
    signed-in last-message control returns deterministic no-model content
    public unauth direct route still returns HTTP 401
    no job/result/model/worker activation occurs
