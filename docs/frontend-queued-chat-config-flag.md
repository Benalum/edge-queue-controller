# Frontend Queued Chat Config Flag — Stage 5F-30

## Purpose

Stage 5F-30 adds a disabled-by-default frontend queued-chat config flag.

This stage does not wire queued chat send behavior.

This stage does not enable queued chat by default.

This stage does not change the current chat submit path.

## Files

- frontend/wrapper-ui/queued_chat_config.js
- frontend/wrapper-ui/index.html

## Config

The config exposes:

- window.AI_PLATFORM_QUEUED_CHAT_CONFIG
- window.AI_PLATFORM_QUEUED_CHAT_ENABLED

The default value is:

- window.AI_PLATFORM_QUEUED_CHAT_ENABLED === false

## Behavior

After this stage:

- index.html loads queued_chat_config.js
- queued_chat_config.js loads before queued_chat_status.js
- queued chat remains disabled by default
- app.js still does not call /api/chat/queued
- app.js still does not use QueuedChatStatusHelper
- app.js still does not use AI_PLATFORM_QUEUED_CHAT_ENABLED
- current non-queued chat behavior remains the active path

## Safety

The config does not submit jobs.

The config does not send user_id.

The config does not send authenticated_user_id.

The config does not send X-Synthetic-User-Id.

The config does not call CT101.

The config does not call Ollama.

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

## Recommended Stage 5F-31

Stage 5F-31 should add a disabled-by-default app.js detection path that reads the config flag but keeps the legacy chat path active while the flag is false.

Production queued chat should remain disabled unless explicitly enabled.
