# Frontend Queued Chat First Wiring Plan — Stage 5F-39

## Purpose

Stage 5F-39 plans the first real frontend queued-chat wiring stage.

This stage is planning only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into submit.

This stage does not enable queued chat by default.

## Current proven frontend foundation

Already proven:

- queued_chat_config.js defaults queued chat off
- queued_chat_status.js is loaded in index.html
- app.js reads AI_PLATFORM_QUEUED_CHAT_ENABLED
- app.js exposes AI_PLATFORM_QUEUED_CHAT_UI_STATE
- app.js contains a disabled queued-send helper
- app.js contains a disabled queued-status polling helper
- app.js contains a disabled queued assistant placeholder helper
- queued send helper is mocked and tested
- queued status polling helper is mocked and tested
- queued assistant placeholder helper is mocked and tested
- none of the queued helpers are wired to normal submit or rendering yet

## First wiring goal

The first real frontend wiring stage should add a single guarded decision point in the existing chat submit flow.

When queued chat is disabled:

- preserve the current existing chat submit path
- preserve the current assistant rendering path
- preserve the current error behavior
- preserve current model selection behavior

When queued chat is enabled later:

- render the user message once
- call the queued-send helper once
- store job_id, chat_id, and user_message_id
- render a queued assistant placeholder once
- poll owned queued job status
- update the placeholder from queued to running, failed, timeout, or complete
- render assistant response only after complete
- avoid duplicate assistant messages on repeated polls

## Required runtime gate

The first wiring must be guarded by:

- window.AI_PLATFORM_QUEUED_CHAT_ENABLED === true

The default value must remain false.

## Required rollback behavior

Rollback must be instant:

- set AI_PLATFORM_QUEUED_CHAT_ENABLED to false
- existing chat path becomes active
- queued branch stops being selected for new messages
- existing queued jobs are not deleted
- existing queued jobs can still be inspected by backend tools

## Required duplicate protection

The first wiring stage must avoid:

- duplicate user messages
- duplicate assistant placeholders
- duplicate assistant final messages
- duplicate POST /api/chat/queued calls
- duplicate polling loops for the same job_id

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal session credentials.

## Required failure behavior

The first wiring stage must handle:

- POST failure
- missing job_id
- queued status timeout
- failed job status
- offline CT101 / job remains queued
- backend feature disabled response
- session/auth failure response

## Required future smokes

Before enabling queued chat in live UI:

- flag off submit uses legacy path smoke
- flag on submit uses queued path smoke with mocked fetch
- flag on submit does not call legacy assistant path twice
- queued placeholder appears once
- queued status polling stops on complete
- queued status polling stops on failed
- queued status polling times out safely
- duplicate polling does not duplicate assistant messages
- rollback flag off returns to legacy path
- no identity headers/body fields are sent

## What Stage 5F-40 should do

Stage 5F-40 should add a disabled-by-default submit decision helper in app.js.

Stage 5F-40 should still not change the current submit handler behavior.

Stage 5F-40 should expose a helper such as:

- shouldUseQueuedChatForSubmit

The helper should return false while AI_PLATFORM_QUEUED_CHAT_ENABLED is false.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
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
