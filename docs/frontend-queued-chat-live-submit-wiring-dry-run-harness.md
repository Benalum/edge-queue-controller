# Frontend Queued Chat Live Submit Wiring Dry-Run Harness — Stage 5F-67

## Purpose

Stage 5F-67 adds a mocked live-submit wiring dry-run harness.

This stage is smoke-test only.

This stage does not change frontend runtime behavior.

This stage does not modify app.js.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke simulates the future live-submit branch outside the real app submit path.

The dry-run harness proves:

- flag off keeps mocked legacy submit path
- flag off does not call queued gate
- flag off does not call queued orchestration
- flag on but real gate unwired blocks queued submit
- flag on with mocked future gate wiring calls orchestration once
- payload builder is called once
- decision helper is called once
- queued send helper is called once
- assistant placeholder helper is called once
- status poll helper is called once
- final assistant render is simulated once
- no duplicate queued POST is simulated
- no duplicate placeholder is simulated
- no duplicate polling loop is simulated
- no duplicate final assistant reply is simulated
- unsafe identity fields are excluded from the mocked safe payload

## Required simulated live order

The mocked future live-submit branch must use this order:

1. check AI_PLATFORM_QUEUED_CHAT_ENABLED
2. evaluate guarded live-submit gate once
3. check mocked guardedLiveSubmitGateWired
4. check mocked guardedLiveSubmitWired
5. build safe payload once
6. make submit decision once
7. run queued submit orchestration once
8. render placeholder once
9. poll status once
10. render final assistant reply once

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

No database rows are created.

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

## Recommended Stage 5F-68

Stage 5F-68 should add a final pre-wiring go/no-go checklist.

Stage 5F-68 should still not wire queued chat into the real submit handler.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- modify app.js
- wire queued chat into normal submit
- call the guarded gate from the live submit path
- call the guarded live-submit helper from the live submit path
- call the guarded skeleton from the live submit path
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
