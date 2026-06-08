# Frontend Queued Chat Submit Payload Builder Mock Test — Stage 5F-49

## Purpose

Stage 5F-49 adds a mocked test for the disabled queued-chat submit payload builder helper.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-48 payload builder block from app.js in isolation.

The test proves:

- submit payload builder helper exists
- submit payload builder helper is exposed as AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH
- payloadWired remains false
- missing message returns missing_message_stage_5f48
- message is trimmed
- safe payload can contain message only
- safe payload can contain message, chat_id, and requested_model
- unsafe identity input fields are ignored
- payload never contains user_id
- payload never contains authenticated_user_id
- payload never contains X-Synthetic-User-Id
- no fetch is called
- no queued job is submitted
- no polling is started
- no placeholder rendering is started

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The queued submit payload builder remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
- call the payload builder from the live submit path
- call the submit decision helper from the live submit path
- call the queued send helper from the live submit path
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

## Recommended Stage 5F-50

Stage 5F-50 should add a disabled-by-default queued submit orchestration plan that defines the future order:

1. build safe payload
2. make submit decision
3. call queued send once
4. render placeholder once
5. poll status once per job
6. render final assistant reply once

Production queued chat should remain disabled unless explicitly enabled.
