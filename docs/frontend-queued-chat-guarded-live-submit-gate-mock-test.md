# Frontend Queued Chat Guarded Live Submit Gate Mock Test — Stage 5F-64

## Purpose

Stage 5F-64 adds a mocked test for the guarded live-submit gate helper.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-63 guarded live-submit gate block from app.js in isolation.

The test proves:

- guarded live-submit gate helper exists
- guarded live-submit gate helper is exposed as AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH
- guardedLiveSubmitGateWired remains false
- flag off returns guarded_live_submit_gate_flag_disabled_stage_5f63
- flag off keeps legacyChatPathActive true
- flag off keeps liveSubmitSelected false
- flag off keeps queuedSubmitAllowed false
- flag on returns guarded_live_submit_gate_unwired_stage_5f63
- flag on still keeps liveSubmitSelected false while unwired
- flag on still keeps legacyChatPathActive true while unwired
- flag on still keeps queuedSubmitAllowed false while unwired
- readiness presence is reported
- blockedActions list is preserved
- requiredBeforeWire list is preserved
- no fetch is called
- no queued job is submitted
- no polling is started
- no placeholder rendering is started

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The guarded live-submit gate remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

## Required payload/security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Recommended Stage 5F-65

Stage 5F-65 should add a final guarded live-submit gate rollback smoke after Stage 5F-63/5F-64.

Stage 5F-65 should still not wire queued chat into the real submit handler.

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
