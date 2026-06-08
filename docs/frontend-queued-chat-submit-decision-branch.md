# Frontend Queued Chat Submit Decision Branch — Stage 5F-40

## Purpose

Stage 5F-40 adds a disabled queued-chat submit decision helper branch to app.js.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is added

The app.js branch exposes:

- window.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH
- shouldUseQueuedChatForSubmit
- decisionWired false

## Behavior

The helper:

- returns queued_chat_flag_disabled_stage_5f40 when the frontend queued-chat flag is false
- returns shouldUseQueuedChat false while decisionWired is false
- returns queued_chat_submit_not_wired_stage_5f40 when the flag is true but submit is not wired
- keeps the current legacy chat path active
- does not call POST /api/chat/queued
- does not start status polling
- does not render placeholders

## Safety

The helper is not wired to normal chat submit.

The current non-queued chat path remains active.

No production queued jobs are submitted by this stage.

No queued status polling is started by this stage.

No real CT101 call is made by this stage.

No real Ollama call is made by this stage.

The helper does not send client-provided identity fields.

The helper does not send synthetic-user headers.

## Required future behavior

A later stage must explicitly wire this helper into submit.

That future stage must prove:

- flag off uses legacy submit path
- flag on selects queued submit path only once
- no duplicate user message is rendered
- no duplicate assistant placeholder is rendered
- no duplicate queued job is created
- rollback to flag off restores legacy path

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

## Recommended Stage 5F-41

Stage 5F-41 should add a mocked test for the disabled submit decision helper.

Production queued chat should remain disabled unless explicitly enabled.
