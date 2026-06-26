# Stage 16 FC-O45-E-CL-E — Authenticated Companion/Study Last-Message MVP Plan

Date: 2026-06-26

## Summary

CL-E defines the guarded source-only plan for the next backend patch: an authenticated Companion/Study last-message MVP path.

This step is documentation and smoke only. It does not patch backend source yet and does not deploy anything.

## Current clean baseline

Latest recorded baseline:

    HEAD/origin/main=bdc0845
    queued_companion=0
    cleanup_rows=440
    cleanup_tool_candidate_count=0
    CK-Y job581 completed exact marker
    public system status=HTTP 200
    public voice status=HTTP 200
    unauthenticated Companion routes=HTTP 401 Missing bearer token

Active CT203 backend SHA recorded by CL-D:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Cleanup tool SHA recorded by CL-D:

    16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f

## Problem to solve next

The deterministic Companion execution path now works after backlog cleanup, but the product-facing path still needs a small stable MVP contract.

The next patch should prioritize a stable Study Companion last-message flow over broad UI or model complexity.

## MVP target

Add or refine an authenticated backend path that can return a stable last-message response for Study Companion use.

The MVP should support:

    surface=companion_study
    action=last_message
    input_text=<user text>
    response.message=<stable assistant text>
    response.mode=<deterministic_no_model or queued_result>
    response.job_id=<optional, when a queue job is created>
    response.source=<contract marker>
    response.authenticated=true

The route must remain protected by bearer authentication.

Unauthenticated requests must continue returning:

    HTTP 401
    Missing bearer token

## Preferred route

Use the existing authenticated route when possible:

    POST /api/companion/study/action

Public mirror route exists:

    POST /public/companion/study/action

The source patch should avoid adding new public unauthenticated behavior.

## Backend-only constraints

The next source patch must be backend-only.

It must not change:

    frontend files
    public /var/www
    nginx
    cloudflared
    systemd units
    scheduler/timer activation
    persistent worker activation
    CT/VM state

## Execution mode for first MVP proof

The first proof should use deterministic no-model execution.

Reason:

- real small-model exactness already failed in CJ-H with qwen2.5 returning `OK` instead of the exact marker
- deterministic exact-answer path is proven through job581
- no-model path avoids PVESO/Ollama/model calls while stabilizing the product contract
- model routing can be layered later after the product path is stable

Required result model for deterministic proof:

    backend-deterministic/no-model

## Queue policy

For the MVP source patch, use one of these safe patterns:

### Option A — direct deterministic response

Return a deterministic response from `/api/companion/study/action` without inserting a job.

Use for very first UI contract proof.

Expected properties:

    no DB write
    no job insert
    no result insert
    no model call
    authenticated=true
    mode=deterministic_no_model
    action=last_message

### Option B — bounded deterministic queue job

Create exactly one fresh `companion.chat` job with an explicit exact-answer marker and complete it through the existing deterministic selector path.

Use after Option A if queue-to-result behavior must be proven.

Expected properties:

    one job insert
    one result insert from helper completion
    result_model=backend-deterministic/no-model
    queued_companion returns to 0
    no model call
    no scheduler/timer activation
    no persistent worker activation

## Recommended sequence

### CL-F — source-only backend contract patch

Patch source only.

Goal:

- implement or refine authenticated `/api/companion/study/action`
- support `action=last_message`
- return a stable deterministic response
- preserve unauthenticated 401 behavior
- add source smoke
- no deploy

Expected output:

    docs/smoke/source commit/tag only

### CL-G — deploy backend contract to CT203

Deploy only the backend source to CT203 after CL-F is committed.

Expected output:

    active backend SHA changes
    edge-queue-controller service restart/reload if required
    public status remains 200
    unauthenticated Companion routes remain 401

### CL-H — authenticated local/controlled proof

Run the authenticated route proof from the trusted environment.

Expected output:

    /api/companion/study/action with bearer returns 200
    action=last_message returns stable response
    unauthenticated request remains 401
    no model/Ollama/PVESO call
    queued_companion remains 0 for Option A

### CL-I — record deployment/proof

Docs/smoke commit/tag/push.

## Required guardrails for CL-F source patch

CL-F must refuse unless:

    HEAD/origin/main matches the expected CL-E commit
    repo is clean
    focused source smoke passes
    no frontend files changed
    no public /var/www files changed
    no runtime files changed
    no DB files changed

CL-F must include a source smoke that checks:

    /api/companion/study/action marker exists
    action=last_message branch exists
    deterministic_no_model or backend-deterministic/no-model marker exists
    Missing bearer token behavior is preserved in route contract/docs
    no scheduler/timer/persistent-worker activation appears in the patch
    no model/Ollama/PVESO call appears in the patch

## Required guardrails for CL-G deployment

CL-G must create a runtime backup before deploying.

CL-G must verify:

    CT203 running
    current backend SHA before deploy
    new backend SHA after deploy
    backend service active after deploy
    public /api/system/status HTTP 200
    public /api/companion/voice/status HTTP 200
    unauthenticated /api/companion/study/action HTTP 401
    queued_companion remains 0
    no worker/timer/service activation beyond backend service operation

## Required guardrails for CL-H proof

CL-H must not print bearer tokens or secrets.

CL-H must verify:

    authenticated request succeeds
    unauthenticated request fails with 401
    response includes action=last_message
    response includes authenticated=true
    response includes deterministic no-model mode
    queued_companion remains 0 for Option A
    no model/Ollama/PVESO call
    no scheduler/timer/persistent-worker activation

## Non-Companion backlog

CL-D confirmed the remaining pending backlog is stale non-Companion proof/probe traffic:

    queued_any=25
    running_any=10

Do not activate broad queue dispatch until this stale backlog is either cleaned up or excluded.

The Companion path may continue through explicit marker-selected deterministic execution because:

    queued_companion=0
    cleanup_rows=440
    cleanup_tool_candidate_count=0
    job581 completed exact marker

## Recommendation

Proceed with CL-F as a source-only backend patch for authenticated `/api/companion/study/action` last-message MVP using Option A direct deterministic response first.

After Option A is stable, move to Option B only if queue-to-result proof is needed for the UI contract.
