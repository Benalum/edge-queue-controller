# Frontend Queued Chat Submit Payload Builder Branch — Stage 5F-48

## Purpose

Stage 5F-48 adds a disabled queued-chat submit payload builder branch to app.js.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is added

The app.js branch exposes:

- window.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH
- buildQueuedChatSubmitPayload
- payloadWired false

## Behavior

The helper:

- builds a safe queued-chat submit payload
- requires message
- includes chat_id only when available
- includes requested_model only when available
- returns missing_message_stage_5f48 when message is empty
- keeps payloadWired false
- does not call fetch
- does not submit queued jobs
- does not start polling
- does not render placeholders

## Safe payload shape

The payload may contain only:

- message
- chat_id
- requested_model

## Safety

The helper is not wired to normal chat submit.

The current non-queued chat path remains active.

No production queued jobs are submitted by this stage.

No queued status polling is started by this stage.

No queued placeholder is rendered by this stage.

No real CT101 call is made by this stage.

No real Ollama call is made by this stage.

The helper does not call fetch.

The helper does not send client-provided identity fields.

The helper does not send synthetic-user headers.

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

## Recommended Stage 5F-49

Stage 5F-49 should add a mocked test for the disabled submit payload builder helper.

Production queued chat should remain disabled unless explicitly enabled.
