# Frontend Queued Chat Flag-On Submit Wiring Plan — Stage 5F-55

## Purpose

Stage 5F-55 plans the first future flag-on queued-chat submit wiring test.

This stage is planning only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## Current proven frontend foundation

Already proven:

- queued chat config defaults off
- flag-off live submit preservation smoke passed
- disabled rollback smoke passed
- orchestration helper mock test passed
- orchestration helper exists but is not wired
- payload builder helper exists but is not wired
- submit decision helper exists but is not wired
- queued send helper exists but is not wired
- queued status poll helper exists but is not wired
- queued assistant placeholder helper exists but is not wired
- Stage 5F-43 marker is near the real submit path

## Future mocked flag-on submit goal

A later stage may create a mocked flag-on live-submit-style test.

That test should prove the future queued path can run in this order:

1. build safe payload once
2. make submit decision once
3. call queued send once
4. render queued assistant placeholder once
5. poll queued status once for the returned job_id
6. render final assistant reply once

## Required safety before any live wiring

Before any live submit behavior changes, the mocked test must prove:

- flag off keeps legacy submit path
- flag on enters queued path only behind AI_PLATFORM_QUEUED_CHAT_ENABLED
- orchestration helper is called once
- payload builder is called once
- decision helper is called once
- queued send helper is called once
- placeholder helper is called once
- poll helper is called once
- no duplicate POST /api/chat/queued
- no duplicate placeholder
- no duplicate polling loop
- no duplicate final assistant message
- no client-provided identity fields
- rollback flag off restores legacy submit path

## Required payload shape

The queued submit payload may contain only:

- message
- chat_id
- requested_model

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Required failure states

The future mocked flag-on test must cover:

- missing message
- payload build failure
- decision refusal
- queued send failure
- missing job_id
- poll timeout
- failed queued job
- backend feature disabled response
- session/auth failure response

## Required rollback behavior

Rollback must remain instant:

- AI_PLATFORM_QUEUED_CHAT_ENABLED false keeps legacy submit active
- queued orchestration is not selected for new messages
- existing queued jobs are not deleted
- existing queued jobs can still be inspected by backend tools

## Recommended Stage 5F-56

Stage 5F-56 should add a mocked flag-on submit orchestration test harness.

Stage 5F-56 should still not wire queued chat into the real submit handler.

Production queued chat should remain disabled unless explicitly enabled.

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
