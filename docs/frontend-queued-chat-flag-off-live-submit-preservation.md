# Frontend Queued Chat Flag-Off Live Submit Preservation — Stage 5F-54

## Purpose

Stage 5F-54 proves the frontend flag-off live submit path remains preserved after the queued submit orchestration stack was added.

This stage is static verification only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is verified

The smoke verifies:

- queued chat config still defaults off
- Stage 5F-43 submit insertion marker still exists near the live submit path
- live app.js code outside isolated Stage 5F helper branches does not call queued helpers
- payload builder remains unwired
- dry-run helper remains unwired
- decision helper remains unwired
- orchestration helper remains unwired
- send helper remains unwired
- status poll helper remains unwired
- assistant placeholder helper remains unwired

## Live submit preservation

While AI_PLATFORM_QUEUED_CHAT_ENABLED is false:

- current legacy submit path remains active
- live submit must not call payload builder
- live submit must not call dry-run helper
- live submit must not call decision helper
- live submit must not call orchestration helper
- live submit must not call queued send helper
- live submit must not start queued polling
- live rendering must not call queued placeholder helper

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Required future behavior

A later stage may add a mocked flag-on submit test, but must still prove:

- flag off keeps legacy submit path
- flag on calls orchestration once
- no duplicate queued POST
- no duplicate placeholder
- no duplicate polling
- no duplicate final assistant message
- rollback flag off restores legacy path

## Recommended Stage 5F-55

Stage 5F-55 should add a mocked flag-on submit wiring plan before any live submit behavior changes.

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
