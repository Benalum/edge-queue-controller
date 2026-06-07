# Frontend Queued Chat Helper Import — Stage 5F-29

## Purpose

Stage 5F-29 imports the dormant queued chat status helper in index.html.

This stage does not wire queued chat send behavior.

This stage does not enable queued chat by default.

This stage does not change the current chat submit path.

## Files

- frontend/wrapper-ui/index.html
- frontend/wrapper-ui/queued_chat_status.js

## Behavior

After this stage:

- index.html loads queued_chat_status.js
- window.QueuedChatStatusHelper is available in the browser
- app.js still does not import queued_chat_status.js
- app.js still does not call QueuedChatStatusHelper
- app.js still does not POST to /api/chat/queued
- current non-queued chat behavior remains the active path

## Safety

Queued chat UI remains disabled by default.

The helper does not submit jobs.

The helper does not send user_id.

The helper does not send authenticated_user_id.

The helper does not send X-Synthetic-User-Id.

The helper does not call CT101.

The helper does not call Ollama.

## Required future gate

Future frontend queued-chat behavior must be gated by a disabled-by-default value such as:

- window.AI_PLATFORM_QUEUED_CHAT_ENABLED === true

or an equivalent server-provided config value.

## What this stage does not do

This stage does not:

- change chat submit behavior
- enable queued chat by default
- submit real production queued jobs
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

## Recommended Stage 5F-30

Stage 5F-30 should add a disabled-by-default frontend queued-chat config flag and smoke that proves the flag defaults off.

Production queued chat should remain disabled unless explicitly enabled.
