# Frontend Queued Chat Disabled Send Branch — Stage 5F-32

## Purpose

Stage 5F-32 adds a disabled queued-chat send branch to app.js.

This stage does not wire the branch into the current chat submit flow.

This stage does not enable queued chat by default.

The current chat submit path remains active.

## Behavior

After this stage:

- app.js contains a future queued-chat send helper
- the helper is gated by window.AI_PLATFORM_QUEUED_CHAT_ENABLED === true
- the helper returns queued_chat_disabled_stage_5f32 when the flag is false
- the helper can POST to /api/chat/queued only when explicitly called and the flag is true
- the helper is exposed as window.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH
- wiredToSubmit remains false
- the current chat submit path is not changed

## Safety

Queued chat UI remains disabled by default.

The queued-send helper is not called by the existing chat submit handler.

The helper does not send user_id.

The helper does not send authenticated_user_id.

The helper does not send X-Synthetic-User-Id.

The helper uses credentials: include for normal session auth.

## What this stage does not do

This stage does not:

- change chat submit behavior
- enable queued chat by default
- start polling queued status
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

## Recommended Stage 5F-33

Stage 5F-33 should add a disabled-by-default frontend smoke that confirms the queued branch is unreachable through the normal submit path while the flag is false.

Production queued chat should remain disabled unless explicitly enabled.
