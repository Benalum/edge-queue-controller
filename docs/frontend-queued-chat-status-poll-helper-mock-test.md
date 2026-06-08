# Frontend Queued Chat Status Poll Helper Mock Test — Stage 5F-36

## Purpose

Stage 5F-36 adds a mocked test for the disabled queued-chat status polling helper.

This stage does not change frontend runtime behavior.

This stage does not wire polling into submit.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-35 polling helper block from app.js in isolation.

The test proves:

- queued status poll helper exists
- queued status poll helper is exposed as AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH
- disabled flag returns queued_status_poll_disabled_stage_5f35
- disabled flag does not call fetch
- enabled flag requires QueuedChatStatusHelper
- missing job id is refused
- enabled flag calls GET /api/chat/queued/{job_id} only in mocked isolated execution
- mocked queued status request uses credentials include
- mocked queued status request sends no body
- mocked queued status request sends no user_id
- mocked queued status request sends no authenticated_user_id
- mocked queued status request sends no X-Synthetic-User-Id
- mocked queued status response builds a status view
- pollerWired remains false

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The real frontend polling loop is not changed.

The queued status helper remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

## What this stage does not do

This stage does not:

- change chat submit behavior
- enable queued chat by default
- wire queued polling into normal submit
- start automatic queued polling
- render queued assistant placeholders
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

## Recommended Stage 5F-37

Stage 5F-37 should add a disabled-by-default queued assistant placeholder helper branch, still not wired into normal rendering.

Production queued chat should remain disabled unless explicitly enabled.
