# Frontend Queued Chat Submit Orchestration Plan — Stage 5F-50

## Purpose

Stage 5F-50 plans the future frontend queued-chat submit orchestration order.

This stage is planning only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## Current proven frontend foundation

Already proven:

- queued chat config defaults off
- submit insertion marker is near the real submit path
- submit payload shape is documented
- submit payload builder exists and is not wired
- submit payload builder mock test passed
- submit dry-run helper exists and is not wired
- submit dry-run mock test passed
- submit decision helper exists and is not called
- submit decision mock test passed
- queued send helper exists and is not wired
- queued send helper mock test passed
- queued status poll helper exists and is not wired
- queued status poll helper mock test passed
- queued assistant placeholder helper exists and is not wired
- queued assistant placeholder mock test passed

## Future orchestration order

A later wiring stage must use this order:

1. build safe payload
2. make submit decision
3. call queued send once
4. render queued assistant placeholder once
5. poll status once per job
6. render final assistant reply once

## Required helper order

The future queued path should call helpers in this order:

1. AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH.buildQueuedChatSubmitPayload
2. AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH.shouldUseQueuedChatForSubmit
3. AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH.sendQueuedChat
4. AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH.buildQueuedAssistantPlaceholder
5. AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH.pollQueuedChatStatus

## Required flag behavior

When AI_PLATFORM_QUEUED_CHAT_ENABLED is false:

- legacy submit path must remain active
- queued payload builder must not be called from live submit
- queued decision helper must not be called from live submit
- queued send helper must not be called from live submit
- queued placeholder helper must not be called from live render
- queued status poll helper must not be called from live submit
- no POST /api/chat/queued should happen

When AI_PLATFORM_QUEUED_CHAT_ENABLED is true in a later explicitly wired stage:

- payload builder may be called once
- decision helper may be called once
- queued send helper may be called once
- placeholder helper may be called once
- status polling may start once for the returned job_id
- final assistant message may render once after complete

## Required duplicate protection

Future wiring must prevent:

- duplicate user messages
- duplicate assistant placeholders
- duplicate POST /api/chat/queued calls
- duplicate polling loops for the same job_id
- duplicate final assistant messages
- duplicate error messages for the same failed job

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

## Required failure behavior

Future wiring must handle:

- missing message
- payload build failure
- decision helper refusal
- POST /api/chat/queued failure
- missing job_id
- queued status timeout
- failed job status
- offline CT101 where job remains queued
- backend feature disabled response
- session/auth failure response

## Required rollback behavior

Rollback must be instant:

- set AI_PLATFORM_QUEUED_CHAT_ENABLED to false
- legacy submit path becomes active for new messages
- queued branch stops being selected for new messages
- existing queued jobs are not deleted
- existing queued jobs can still be inspected by backend tools

## Required future smokes

Before live queued submit wiring:

- orchestration mock plan smoke
- flag-off legacy submit unchanged smoke
- flag-on mocked queued submit smoke
- helper call order smoke
- no duplicate queued POST smoke
- no duplicate placeholder smoke
- no duplicate polling smoke
- failed job UI smoke
- offline queued job UI smoke
- rollback flag-off smoke
- no identity fields smoke

## Recommended Stage 5F-51

Stage 5F-51 should add a mocked orchestration helper branch that runs the future order in isolation.

Stage 5F-51 should not wire the orchestration helper into live submit.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
- call the payload builder from the live submit path
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
