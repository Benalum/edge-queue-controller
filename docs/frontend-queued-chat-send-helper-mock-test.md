# Frontend Queued Chat Send Helper Mock Test — Stage 5F-34

## Purpose

Stage 5F-34 adds a mocked test for the disabled queued-chat send helper.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into submit.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-32 helper block from app.js in isolation.

The test proves:

- queued send helper exists
- queued send helper is exposed as AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH
- disabled flag returns queued_chat_disabled_stage_5f32
- disabled flag does not call fetch
- enabled flag calls /api/chat/queued only in mocked isolated execution
- mocked queued request uses credentials include
- mocked queued request sends only message, chat_id, and requested_model
- mocked queued request does not send user_id
- mocked queued request does not send authenticated_user_id
- mocked queued request does not send X-Synthetic-User-Id
- wiredToSubmit remains false

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The queued helper remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

## What this stage does not do

This stage does not:

- change chat submit behavior
- enable queued chat by default
- wire queued chat into normal submit
- poll /api/chat/queued/{job_id}
- render queued assistant placeholders
- use QueuedChatStatusHelper in app.js
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

## Recommended Stage 5F-35

Stage 5F-35 should add a disabled-by-default queued status polling helper branch in app.js, still not wired to normal submit.

Production queued chat should remain disabled unless explicitly enabled.
