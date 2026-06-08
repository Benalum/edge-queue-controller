# Frontend Chat Submit Payload Shape Map — Stage 5F-47

## Purpose

Stage 5F-47 inspects the real frontend submit payload shape needed for future queued-chat submit wiring.

This stage is inspection and planning only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into submit.

This stage does not enable queued chat by default.

## Inputs

- docs/frontend-chat-submit-payload-shape-inspection.md
- docs/frontend-chat-submit-marker-proximity.md
- docs/frontend-chat-submit-insertion-marker.md
- docs/frontend-chat-submit-handler-insertion-map.md
- docs/frontend-queued-chat-submit-dry-run-mock-test.md
- frontend/wrapper-ui/app.js
- frontend/wrapper-ui/index.html

## Current proven foundation

Already proven:

- Stage 5F-43 marker is near the real submit path
- queued submit decision helper exists but is not called
- queued submit dry-run helper exists but is not called
- queued send helper exists but is not wired to submit
- queued status poll helper exists but is not wired
- queued assistant placeholder helper exists but is not wired
- decisionWired remains false
- dryRunWired remains false
- wiredToSubmit remains false
- pollerWired remains false
- placeholderWired remains false

## Future queued-submit payload shape

The future queued submit path should build exactly this safe payload shape:

- message
- chat_id
- requested_model

The frontend must not include any other user identity field.

## Required local submit data

A later wiring stage must identify these values from the current submit handler:

- message text from the current chat input
- current chat identifier if an existing chat is active
- requested model from the current selected model or model state

## Required future behavior

When queued chat remains disabled:

- current submit payload behavior must stay unchanged
- current non-queued assistant request must stay unchanged
- queued dry-run helper may be tested directly but must not be called from live submit
- queued decision helper must not be called from live submit

When queued chat is later enabled and explicitly wired:

- submit decision should be called at most once
- queued send helper should be called at most once
- payload must include only message, chat_id, and requested_model
- user message must render once
- assistant placeholder must render once
- polling must start once
- final assistant response must render once

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Required future smokes

Before live queued submit wiring:

- payload extraction smoke
- flag-off legacy submit smoke
- mocked flag-on queued submit smoke
- no duplicate submit smoke
- no duplicate placeholder smoke
- no duplicate polling smoke
- no identity fields smoke
- rollback flag-off smoke

## Recommended Stage 5F-48

Stage 5F-48 should add a disabled-by-default payload builder helper branch in app.js.

The payload builder should return only message, chat_id, and requested_model.

Stage 5F-48 should not wire the payload builder into live submit.

Production queued chat should remain disabled unless explicitly enabled.

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
