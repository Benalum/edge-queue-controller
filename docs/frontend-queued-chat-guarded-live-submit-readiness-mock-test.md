# Frontend Queued Chat Guarded Live Submit Readiness Mock Test — Stage 5F-61

## Purpose

Stage 5F-61 adds a mocked test for the guarded live-submit readiness helper.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-60 guarded live-submit readiness block from app.js in isolation.

The test proves:

- guarded live-submit readiness helper exists
- guarded live-submit readiness helper is exposed as AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH
- guardedLiveSubmitWired remains false
- flag off returns guarded_live_submit_flag_disabled_stage_5f60
- flag off keeps legacyChatPathActive true
- flag off keeps liveSubmitSelected false
- flag on returns guarded_live_submit_unwired_stage_5f60
- flag on still keeps liveSubmitSelected false while unwired
- flag on still keeps legacyChatPathActive true while unwired
- requiredBeforeEnable list is preserved
- helper presence is reported
- no fetch is called
- no queued job is submitted
- no polling is started
- no placeholder rendering is started

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The guarded live-submit readiness helper remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

## Required payload/security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Recommended Stage 5F-62

Stage 5F-62 should add a final flag-off live-submit regression smoke after Stage 5F-60/5F-61.

Stage 5F-62 should still not wire queued chat into the real submit handler.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
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
