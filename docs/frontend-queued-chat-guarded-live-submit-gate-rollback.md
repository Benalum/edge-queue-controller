# Frontend Queued Chat Guarded Live Submit Gate Rollback — Stage 5F-65

## Purpose

Stage 5F-65 adds a final guarded live-submit gate rollback smoke after the guarded gate helper and mock test.

This stage is static verification only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is verified

The smoke verifies:

- queued chat config still defaults off
- Stage 5F-43 submit insertion marker still exists
- Stage 5F-57 guarded submit skeleton marker still exists
- Stage 5F-60 guarded live-submit marker still exists
- Stage 5F-63 guarded live-submit gate marker still exists
- guarded live-submit gate helper exists
- guarded live-submit gate helper remains unwired
- guarded live-submit readiness helper remains unwired
- guarded submit skeleton helper remains unwired
- orchestration helper remains unwired
- payload builder remains unwired
- decision helper remains unwired
- queued send helper remains unwired
- queued status poll helper remains unwired
- queued assistant placeholder helper remains unwired
- live app.js code outside isolated Stage 5F helper branches does not call queued helpers
- live app.js code outside isolated Stage 5F helper branches does not call /api/chat/queued
- no client-provided identity fields are referenced

## Required rollback behavior

Rollback must remain instant:

- AI_PLATFORM_QUEUED_CHAT_ENABLED false keeps legacy submit active
- guardedLiveSubmitGateWired false keeps guarded gate out of live submit
- guardedLiveSubmitWired false keeps guarded live submit out of live submit
- guardedSubmitWired false keeps guarded submit skeleton out of live submit
- orchestrationWired false keeps orchestration out of live submit
- payloadWired false keeps payload builder out of live submit
- decisionWired false keeps decision helper out of live submit
- wiredToSubmit false keeps queued send out of live submit
- pollerWired false keeps polling out of live submit
- placeholderWired false keeps placeholder rendering out of live rendering

## Required flag-off behavior

When AI_PLATFORM_QUEUED_CHAT_ENABLED is false:

- legacy submit path remains active
- guarded live-submit gate remains unwired
- queued submit remains blocked
- queued orchestration is not selected
- no POST /api/chat/queued is made
- no polling starts
- no queued placeholder renders
- no queued final render happens

## Required future behavior

Before any actual live submit wiring, the next stage must prove:

- flag off keeps legacy submit path unchanged
- flag on can enter a mocked guarded gate once
- queued orchestration is called at most once
- queued send is called at most once
- queued placeholder is rendered at most once
- queued polling starts at most once per job_id
- final assistant response renders at most once
- rollback flag off restores legacy submit

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Recommended Stage 5F-66

Stage 5F-66 should add a final live-submit wiring implementation plan before any real behavior change.

Stage 5F-66 should still not wire queued chat into the real submit handler.

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
