# Frontend Queued Chat Assistant Placeholder Branch — Stage 5F-37

## Purpose

Stage 5F-37 adds a disabled queued-chat assistant placeholder helper branch to app.js.

This stage does not change frontend runtime behavior.

This stage does not wire placeholders into message rendering.

This stage does not enable queued chat by default.

## What is added

The app.js branch exposes:

- window.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH
- buildQueuedAssistantPlaceholder
- placeholderWired false

## Behavior

The helper:

- returns queued_placeholder_disabled_stage_5f37 when the frontend queued-chat flag is false
- uses QueuedChatStatusHelper only when explicitly enabled and directly called
- builds placeholder display data from queued job status
- reports canRenderAssistant when the completed assistant reply is available
- keeps placeholderWired false

## Safety

The helper is not wired to normal chat submit.

The helper is not wired to normal message rendering.

The current non-queued chat path remains active.

No production queued jobs are submitted by this stage.

No queued status polling is started by this stage.

No real CT101 call is made by this stage.

No real Ollama call is made by this stage.

The helper does not send client-provided identity fields.

The helper does not send synthetic-user headers.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued assistant placeholders into normal rendering
- start automatic queued polling
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

## Recommended Stage 5F-38

Stage 5F-38 should add a mocked test for the disabled queued assistant placeholder helper.

Production queued chat should remain disabled unless explicitly enabled.
