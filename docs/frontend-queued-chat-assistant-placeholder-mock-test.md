# Frontend Queued Chat Assistant Placeholder Mock Test — Stage 5F-38

## Purpose

Stage 5F-38 adds a mocked test for the disabled queued-chat assistant placeholder helper.

This stage does not change frontend runtime behavior.

This stage does not wire placeholders into message rendering.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-37 placeholder helper block from app.js in isolation.

The test proves:

- queued assistant placeholder helper exists
- queued assistant placeholder helper is exposed as AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH
- disabled flag returns queued_placeholder_disabled_stage_5f37
- enabled flag requires QueuedChatStatusHelper
- queued job returns queued placeholder text
- running job returns running placeholder text
- failed job returns failed placeholder text
- complete job with assistant reply returns canRenderAssistant true
- complete job exposes assistantReply
- placeholderWired remains false

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The real frontend rendering path is not changed.

The queued placeholder helper remains disabled by default.

No production queued jobs are submitted.

No queued status polling is started.

No real CT101 call is made.

No real Ollama call is made.

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

## Recommended Stage 5F-39

Stage 5F-39 should add a queued-chat frontend integration plan for the first real wiring stage.

Production queued chat should remain disabled unless explicitly enabled.
