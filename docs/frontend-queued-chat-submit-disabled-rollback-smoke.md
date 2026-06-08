# Frontend Queued Chat Submit Disabled Rollback Smoke — Stage 5F-53

## Purpose

Stage 5F-53 proves the frontend queued-chat submit stack remains disabled and rollback-safe after the orchestration mock test.

This stage is static verification only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## Current proven frontend foundation

Already proven:

- queued submit payload builder exists
- queued submit payload builder mock test passed
- queued submit dry-run helper exists
- queued submit dry-run mock test passed
- queued submit decision helper exists
- queued submit decision mock test passed
- queued submit orchestration helper exists
- queued submit orchestration mock test passed
- queued send helper exists
- queued send helper mock test passed
- queued status poll helper exists
- queued status poll helper mock test passed
- queued assistant placeholder helper exists
- queued assistant placeholder mock test passed

## Rollback requirement

Rollback must remain instant:

- AI_PLATFORM_QUEUED_CHAT_ENABLED false keeps legacy submit active
- payloadWired false keeps payload builder out of live submit
- dryRunWired false keeps dry-run out of live submit
- decisionWired false keeps decision helper out of live submit
- wiredToSubmit false keeps queued send out of live submit
- pollerWired false keeps polling out of live submit
- placeholderWired false keeps placeholder rendering out of live rendering
- orchestrationWired false keeps orchestration out of live submit

## Default disabled requirements

The frontend must keep these defaults:

- queued chat config defaults off
- live submit does not call payload builder
- live submit does not call dry-run helper
- live submit does not call decision helper
- live submit does not call orchestration helper
- live submit does not call queued send helper
- live submit does not start queued polling
- live rendering does not call queued placeholder helper

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Required future behavior

A later stage may begin a mocked flag-on live submit test, but must still prove:

- flag off keeps legacy submit path
- flag on calls orchestration once
- no duplicate queued POST
- no duplicate placeholder
- no duplicate polling
- no duplicate final assistant message
- rollback flag off restores legacy path

## Recommended Stage 5F-54

Stage 5F-54 should add a mocked flag-off live submit preservation smoke.

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
