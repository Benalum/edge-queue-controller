# Frontend Queued Chat Live Submit Pre-Wiring Go/No-Go — Stage 5F-68

## Purpose

Stage 5F-68 creates the final go/no-go checklist before any real frontend queued-chat live submit behavior change.

This stage is planning and static verification only.

This stage does not change frontend runtime behavior.

This stage does not modify app.js.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## Current completed dry-run foundation

The frontend has now proven:

- queued chat config defaults off
- queued send helper exists and is mock tested
- queued status poll helper exists and is mock tested
- queued assistant placeholder helper exists and is mock tested
- submit decision helper exists and is mock tested
- submit dry-run helper exists and is mock tested
- submit payload builder exists and is mock tested
- submit orchestration helper exists and is mock tested
- guarded submit skeleton exists and is mock tested
- guarded live-submit readiness helper exists and is mock tested
- guarded live-submit gate helper exists and is mock tested
- flag-off live-submit regression passed
- guarded live-submit gate rollback passed
- live-submit wiring implementation plan passed
- live-submit wiring dry-run harness passed

## Current completed backend foundation

The backend has proven:

- real-user queued chat creation is session-authenticated
- client-provided user_id is refused
- authenticated user comes from server-side session auth
- chat ownership is checked before chat reuse
- job status ownership is checked
- queued jobs can be created while CT101 is offline
- no assistant message exists before job completion
- CT101 bounded real-user poller is explicitly guarded
- CT101 bounded poller can complete real-user queued jobs
- assistant message persistence is idempotent after completion
- rollback/offline behavior is safe

## Go criteria before Stage 5F-69

Stage 5F-69 may add the first actual guarded live-submit branch only if all of these remain true:

1. AI_PLATFORM_QUEUED_CHAT_ENABLED defaults false
2. flag-off live submit path is unchanged
3. live app.js outside isolated helpers does not call queued helpers
4. live app.js outside isolated helpers does not call /api/chat/queued
5. app.js does not reference user_id
6. app.js does not reference authenticated_user_id
7. app.js does not send X-Synthetic-User-Id
8. guardedLiveSubmitGateWired remains false before live wiring
9. guardedLiveSubmitWired remains false before live wiring
10. orchestrationWired remains false before live wiring
11. payloadWired remains false before live wiring
12. decisionWired remains false before live wiring
13. wiredToSubmit remains false before live wiring
14. pollerWired remains false before live wiring
15. placeholderWired remains false before live wiring

## No-go criteria

Do not proceed to real live-submit wiring if any of these are true:

- frontend queued flag defaults true
- live submit calls queued orchestration while flag is false
- live submit calls queued send while flag is false
- live submit starts polling while flag is false
- live submit renders queued placeholder while flag is false
- live submit sends user_id
- live submit sends authenticated_user_id
- live submit sends X-Synthetic-User-Id
- duplicate queued POST protection is not proven
- duplicate placeholder protection is not proven
- duplicate polling protection is not proven
- duplicate final render protection is not proven
- rollback flag-off behavior is not proven

## Required Stage 5F-69 constraints

The first actual guarded live-submit branch must:

- remain behind AI_PLATFORM_QUEUED_CHAT_ENABLED
- keep AI_PLATFORM_QUEUED_CHAT_ENABLED false by default
- keep guardedLiveSubmitGateWired false unless explicitly changed in that stage
- preserve flag-off legacy submit behavior
- not send client-provided identity fields
- not send synthetic-user headers
- call queued orchestration at most once
- call queued send at most once
- render queued placeholder at most once
- start one polling loop per job_id
- render final assistant response at most once
- include a rollback smoke

## Required future payload shape

The queued submit payload may contain only:

- message
- chat_id
- requested_model

## Recommended Stage 5F-69

Stage 5F-69 should add the first guarded live-submit branch skeleton in app.js.

Stage 5F-69 should keep the branch disabled by default.

Stage 5F-69 must prove flag-off behavior remains unchanged.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- modify app.js
- wire queued chat into normal submit
- call the guarded gate from the live submit path
- call the guarded live-submit helper from the live submit path
- call the guarded skeleton from the live submit path
- call the orchestration helper from the live submit path
- call the payload builder from the live submit path
- call the submit decision helper from the live submit path
- call the queued send helper from the live submit path
- wire queued assistant placeholders into normal rendering
- start automatic queued polling from live submit
- submit production queued jobs from live submit
- start persistent workers
- call CT101 directly from live submit
- call Ollama directly from live submit
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior
