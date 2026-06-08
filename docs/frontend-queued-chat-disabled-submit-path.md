# Frontend Queued Chat Disabled Submit Path — Stage 5F-33

## Purpose

Stage 5F-33 proves the disabled queued-send branch is not reachable from the normal chat submit path.

This stage does not change frontend runtime behavior.

This stage does not enable queued chat by default.

This stage does not wire queued chat into submit.

## Current foundation

Already proven:

- queued_chat_config.js defaults queued chat off
- app.js reads the queued-chat flag
- app.js exposes AI_PLATFORM_QUEUED_CHAT_UI_STATE
- app.js defines AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH
- queuedSendWired is false
- the queued-send helper is gated by AI_PLATFORM_QUEUED_CHAT_ENABLED === true

## Behavior proven by this smoke

The smoke proves:

- the queued-send helper exists
- the queued-send helper contains the queued route
- the queued route is gated by the disabled-by-default flag
- wiredToSubmit remains false
- normal app.js submit code does not call stage5f32SendQueuedChat
- app.js does not call AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH.sendQueuedChat
- app.js does not directly call sendQueuedChat
- app.js still does not use QueuedChatStatusHelper
- app.js still does not send user_id
- app.js still does not send authenticated_user_id
- app.js still does not send X-Synthetic-User-Id

## Safety

Queued chat remains disabled by default.

The current non-queued chat path remains active.

No queued jobs are submitted by this stage.

No queued status polling is started by this stage.

No assistant placeholder rendering is added by this stage.

## What this stage does not do

This stage does not:

- change chat submit behavior
- enable queued chat by default
- submit real production queued jobs
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

## Recommended Stage 5F-34

Stage 5F-34 should add a guarded frontend queued-send unit/static test for the helper itself with mocked fetch.

Production queued chat should remain disabled unless explicitly enabled.
