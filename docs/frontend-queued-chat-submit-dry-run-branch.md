# Frontend Queued Chat Submit Dry-Run Branch — Stage 5F-45

## Purpose

Stage 5F-45 adds a disabled queued-chat submit dry-run helper branch to app.js.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is added

The app.js branch exposes:

- window.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH
- buildQueuedChatSubmitDryRun
- dryRunWired false

## Behavior

The helper:

- returns queued_submit_dry_run_flag_disabled_stage_5f45 when the frontend queued-chat flag is false
- returns queued_submit_dry_run_unwired_stage_5f45 when the flag is true but the dry-run branch is still unwired
- keeps wouldUseQueuedChat false
- keeps legacyChatPathActive true
- reports whether the existing queued helper branches are present
- reports whether decision, send, polling, and placeholder branches are wired
- builds a safe payload containing only message, chat_id, and requested_model

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

## Required future behavior

A later wiring stage must prove:

- flag off keeps legacy submit path
- flag on only calls queued decision once
- flag on only calls queued send once
- flag on only starts one polling loop per job
- rollback returns to legacy path
- duplicate messages are not rendered

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
- call the submit decision helper from the live submit path
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

## Recommended Stage 5F-46

Stage 5F-46 should add a mocked test for the disabled submit dry-run helper.

Production queued chat should remain disabled unless explicitly enabled.
