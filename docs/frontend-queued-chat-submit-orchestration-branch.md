# Frontend Queued Chat Submit Orchestration Branch — Stage 5F-51

## Purpose

Stage 5F-51 adds a disabled queued-chat submit orchestration helper branch to app.js.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is added

The app.js branch exposes:

- window.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH
- runQueuedChatSubmitOrchestration
- orchestrationWired false

## Behavior

When directly called in a future/mock test, the helper can run this order:

1. build safe payload
2. make submit decision
3. call queued send once
4. build queued assistant placeholder once
5. poll queued status once
6. return final orchestration result

## Safety

The helper is not wired to normal chat submit.

The helper is not called by live submit.

The current non-queued chat path remains active.

No production queued jobs are submitted by this stage.

No queued status polling is started by live submit.

No queued placeholder is rendered by live rendering.

No real CT101 call is made by this stage unless a future test explicitly mocks or enables the helper.

No real Ollama call is made by this stage.

The helper does not send client-provided identity fields.

The helper does not send synthetic-user headers.

## Required payload shape

The queued submit payload may contain only:

- message
- chat_id
- requested_model

## Required future test behavior

Stage 5F-52 should mock the helper branches and prove:

- disabled flag skips orchestration
- helper order is payload, decision, send, placeholder, poll
- payload builder is called once
- decision helper is called once
- queued send helper is called once
- placeholder helper is called once
- poll helper is called once
- no duplicate queued job is created
- no duplicate placeholder is created
- no duplicate poll is started
- unsafe identity fields are ignored

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
- call the orchestration helper from the live submit path
- call the payload builder from the live submit path
- call the submit decision helper from the live submit path
- call the queued send helper from the live submit path
- wire queued assistant placeholders into normal rendering
- start automatic queued polling from live submit
- submit production queued jobs from live submit
- start persistent workers
- call CT101 directly from live submit
- call Ollama directly from live submit
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Recommended Stage 5F-52

Stage 5F-52 should add a mocked test for the disabled queued submit orchestration helper.

Production queued chat should remain disabled unless explicitly enabled.
