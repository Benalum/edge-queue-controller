# Frontend Queued Chat Status Poll Helper Branch — Stage 5F-35

## Purpose

Stage 5F-35 adds a disabled queued-chat status polling helper branch to app.js.

This stage does not change frontend runtime behavior.

This stage does not wire polling into submit.

This stage does not enable queued chat by default.

## What is added

The app.js branch exposes:

- window.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH
- pollQueuedChatStatus
- pollerWired false

## Behavior

The helper:

- returns queued_status_poll_disabled_stage_5f35 when the frontend queued-chat flag is false
- does not call fetch while disabled
- requires QueuedChatStatusHelper only when explicitly enabled and directly called
- GETs /api/chat/queued/{job_id} only in the enabled branch
- uses credentials include
- builds a status view through QueuedChatStatusHelper
- keeps pollerWired false

## Safety

The helper is not wired to normal chat submit.

The helper is not wired to an automatic polling loop.

The current non-queued chat path remains active.

No production queued jobs are submitted by this stage.

No real CT101 call is made by this stage.

No real Ollama call is made by this stage.

The helper does not send client-provided identity fields.

The helper does not send synthetic-user headers.

## What this stage does not do

This stage does not:

- change chat submit behavior
- enable queued chat by default
- wire queued status polling into normal submit
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

## Recommended Stage 5F-36

Stage 5F-36 should add a mocked test for the disabled queued status polling helper.

Production queued chat should remain disabled unless explicitly enabled.
