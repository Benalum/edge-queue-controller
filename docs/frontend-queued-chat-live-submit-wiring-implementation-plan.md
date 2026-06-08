# Frontend Queued Chat Live Submit Wiring Implementation Plan — Stage 5F-66

## Purpose

Stage 5F-66 creates the final live-submit wiring implementation plan before any real frontend queued-chat submit behavior change.

This stage is planning and static verification only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## Current completed safety foundation

The frontend now has:

- queued chat config defaulted off
- queued send helper branch and mock test
- queued status poll helper branch and mock test
- queued assistant placeholder branch and mock test
- submit decision branch and mock test
- submit dry-run branch and mock test
- submit payload builder branch and mock test
- submit orchestration branch and mock test
- guarded submit skeleton and mock test
- guarded live-submit readiness helper and mock test
- guarded live-submit gate helper and mock test
- flag-off live-submit regression smoke
- guarded live-submit gate rollback smoke

## First real wiring target

The first actual live-submit wiring stage should only add a guarded branch near the Stage 5F-63 marker.

The live branch must be selected only when all of these are true:

1. AI_PLATFORM_QUEUED_CHAT_ENABLED is true
2. guardedLiveSubmitGateWired is true
3. guardedLiveSubmitWired is true
4. the safe payload builder returns ok
5. the submit decision helper returns shouldUseQueuedChat true
6. the queued orchestration helper returns ok

## Required flag-off behavior

When AI_PLATFORM_QUEUED_CHAT_ENABLED is false:

- legacy submit path remains unchanged
- no queued payload builder is called
- no queued decision helper is called
- no queued orchestration is called
- no POST /api/chat/queued is made
- no queued assistant placeholder is rendered
- no queued polling starts
- no queued final assistant message renders

## Required flag-on but unwired behavior

When AI_PLATFORM_QUEUED_CHAT_ENABLED is true but any wire flag is false:

- legacy submit path remains active
- queued submit is not selected
- no queued orchestration is called from live submit
- no POST /api/chat/queued is made
- no queued polling starts
- no queued placeholder renders

## Required future live wiring order

The eventual guarded live submit branch must use this exact order:

1. check AI_PLATFORM_QUEUED_CHAT_ENABLED
2. evaluate guarded live-submit gate once
3. check guardedLiveSubmitGateWired
4. check guardedLiveSubmitWired
5. build safe payload once
6. make submit decision once
7. run queued submit orchestration once
8. render assistant placeholder once
9. poll status once per job_id
10. render final assistant reply once

## Required duplicate protection

Future live wiring must prevent:

- duplicate user messages
- duplicate assistant placeholders
- duplicate POST /api/chat/queued calls
- duplicate polling loops for the same job_id
- duplicate final assistant messages
- duplicate error messages for the same failed job

## Required payload shape

The queued submit payload may contain only:

- message
- chat_id
- requested_model

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Required backend assumptions

The backend route already proves:

- client-provided user_id is refused
- authenticated user comes from session token
- chat ownership is checked before reuse
- job status ownership is checked
- assistant message is persisted after CT101 completion
- no assistant message exists before job completion
- duplicate assistant persistence is idempotent
- CT101 bounded real-user polling is guarded
- rollback/offline behavior is safe

## Required rollback behavior

Rollback must remain instant:

- setting AI_PLATFORM_QUEUED_CHAT_ENABLED false restores legacy submit selection
- guardedLiveSubmitGateWired false blocks the live queued branch
- guardedLiveSubmitWired false blocks the live queued branch
- existing queued jobs are not deleted
- existing queued jobs can still be inspected by backend tools
- no database cleanup is part of frontend rollback

## Recommended Stage 5F-67

Stage 5F-67 should add a mocked live-submit wiring dry-run harness that simulates the future live submit branch without changing the real submit handler.

Stage 5F-67 should still not wire queued chat into the real submit handler.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
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
