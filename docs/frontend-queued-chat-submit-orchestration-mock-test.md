# Frontend Queued Chat Submit Orchestration Mock Test — Stage 5F-52

## Purpose

Stage 5F-52 adds a mocked test for the disabled queued-chat submit orchestration helper.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-51 orchestration helper block from app.js in isolation.

The test proves:

- orchestration helper exists
- orchestration helper is exposed as AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH
- orchestrationWired remains false
- disabled flag skips orchestration
- missing payload helper is refused
- payload failure is refused
- decision refusal is refused
- helper order is payload, decision, send, placeholder, poll
- payload builder is called once
- decision helper is called once
- queued send helper is called once
- placeholder helper is called once
- poll helper is called once
- final orchestration result includes job_id
- final orchestration result includes chat_id
- final orchestration result includes user_message_id
- unsafe identity fields are ignored by the mocked safe payload builder
- no duplicate queued job is created
- no duplicate placeholder is created
- no duplicate poll is started

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The queued submit orchestration helper remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

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

## Recommended Stage 5F-53

Stage 5F-53 should add a rollback/static smoke proving all queued submit orchestration branches remain disabled by default after the mocked orchestration test.

Production queued chat should remain disabled unless explicitly enabled.
