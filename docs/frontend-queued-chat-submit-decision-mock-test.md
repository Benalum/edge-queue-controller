# Frontend Queued Chat Submit Decision Mock Test — Stage 5F-41

## Purpose

Stage 5F-41 adds a mocked test for the disabled queued-chat submit decision helper.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-40 submit decision helper block from app.js in isolation.

The test proves:

- submit decision helper exists
- submit decision helper is exposed as AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH
- disabled flag returns queued_chat_flag_disabled_stage_5f40
- enabled flag still returns shouldUseQueuedChat false while decisionWired is false
- decisionWired false is authoritative
- mocked send branch wiredToSubmit true does not select queued submit
- legacyChatPathActive remains true while decisionWired is false
- no fetch is called
- no queued job is submitted
- no polling is started
- no user_id is sent
- no authenticated_user_id is sent
- no X-Synthetic-User-Id is sent

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The queued submit decision remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
- wire queued assistant placeholders into normal rendering
- start automatic queued polling
- submit production queued jobs
- start persistent workers
- call CT101 directly
- call Ollama directly
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Recommended Stage 5F-42

Stage 5F-42 should inspect the real chat submit handler and identify the smallest safe insertion point for a future guarded decision call.

Production queued chat should remain disabled unless explicitly enabled.
