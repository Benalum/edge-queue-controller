# Frontend Queued Chat Submit Dry-Run Mock Test — Stage 5F-46

## Purpose

Stage 5F-46 adds a mocked test for the disabled queued-chat submit dry-run helper.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke tests the Stage 5F-45 dry-run helper block from app.js in isolation.

The test proves:

- submit dry-run helper exists
- submit dry-run helper is exposed as AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH
- dryRunWired remains false
- disabled flag returns queued_submit_dry_run_flag_disabled_stage_5f45
- enabled flag returns queued_submit_dry_run_unwired_stage_5f45
- wouldUseQueuedChat remains false
- legacyChatPathActive remains true
- helper branch presence is reported
- helper wiring state is reported
- payload contains only message, chat_id, and requested_model
- unsafe identity input fields are ignored
- no fetch is called
- no queued job is submitted
- no polling is started
- no placeholder rendering is started

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The queued submit dry-run helper remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
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

## Recommended Stage 5F-47

Stage 5F-47 should inspect the real submit handler payload shape and document exactly which local variables are needed for the future guarded queued-submit call.

Production queued chat should remain disabled unless explicitly enabled.
