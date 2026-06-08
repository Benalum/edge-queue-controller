# Frontend Chat Submit Insertion Marker — Stage 5F-43

## Purpose

Stage 5F-43 adds a static queued-chat submit insertion marker near the current frontend chat submit path.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into submit.

This stage does not enable queued chat by default.

## What is added

The marker is added in:

- frontend/wrapper-ui/app.js

The marker identifies where a later stage may add the first guarded queued-chat submit decision call.

## Marker requirements

Future wiring may call:

- AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH.shouldUseQueuedChatForSubmit

But this stage does not call it.

Future wiring must happen:

- after the user submit payload is available
- before the legacy non-queued assistant request
- behind the disabled-by-default queued-chat frontend flag

## Safety

The marker is comment-only.

The marker does not submit queued jobs.

The marker does not start status polling.

The marker does not render placeholders.

The marker does not call CT101.

The marker does not call Ollama.

The marker does not send client-provided identity fields.

The marker does not send synthetic-user headers.

## Required future behavior

A later stage must prove:

- flag off still uses legacy submit path
- flag on can select queued path only after explicit wiring
- submit decision helper is called at most once
- queued send helper is called at most once
- queued status poller starts at most once
- user message is not duplicated
- assistant placeholder is not duplicated
- assistant final response is not duplicated

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
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

## Recommended Stage 5F-44

Stage 5F-44 should add a static smoke proving the marker is near the submit path and the queued decision helper is still not called.

Production queued chat should remain disabled unless explicitly enabled.
