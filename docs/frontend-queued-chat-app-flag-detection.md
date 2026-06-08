# Frontend Queued Chat App Flag Detection — Stage 5F-31

## Purpose

Stage 5F-31 adds disabled-by-default queued-chat flag detection to app.js.

This stage does not wire queued chat send behavior.

This stage does not enable queued chat by default.

This stage keeps the current chat submit path active.

## Behavior

After this stage:

- queued_chat_config.js still defaults queued chat off
- app.js reads window.AI_PLATFORM_QUEUED_CHAT_ENABLED
- app.js exposes window.AI_PLATFORM_QUEUED_CHAT_UI_STATE
- legacyChatPathActive is true while the flag is false
- queuedSendWired is false
- app.js still does not call /api/chat/queued
- app.js still does not use QueuedChatStatusHelper

## Runtime safety

Queued chat UI remains disabled by default.

The current non-queued chat path remains active.

No queued jobs are submitted by this stage.

No queued status polling is started by this stage.

## Security safety

app.js must not send user_id.

app.js must not send authenticated_user_id.

app.js must not send X-Synthetic-User-Id in real-user mode.

## What this stage does not do

This stage does not:

- change chat submit behavior
- enable queued chat by default
- submit real production queued jobs
- poll /api/chat/queued/{job_id}
- render queued assistant placeholders
- start persistent workers
- call CT101
- call Ollama directly
- persist assistant messages
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Recommended Stage 5F-32

Stage 5F-32 should add a disabled-by-default app.js queued-send branch that is unreachable while the flag is false.

Production queued chat should remain disabled unless explicitly enabled.
