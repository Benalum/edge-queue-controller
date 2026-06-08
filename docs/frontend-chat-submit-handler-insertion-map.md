# Frontend Chat Submit Handler Insertion Map — Stage 5F-42

## Purpose

Stage 5F-42 inspects the current frontend chat submit path and maps the safest future queued-chat insertion point.

This stage is inspection and planning only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into submit.

This stage does not enable queued chat by default.

## Inputs

- docs/frontend-chat-submit-handler-inspection.md
- docs/frontend-queued-chat-submit-decision-mock-test.md
- docs/frontend-queued-chat-submit-decision-branch.md
- docs/frontend-queued-chat-first-wiring-plan.md
- frontend/wrapper-ui/app.js
- frontend/wrapper-ui/index.html
- frontend/wrapper-ui/dev_server.py

## Current proven foundation

Already proven:

- queued chat config defaults off
- queued send helper exists and is not wired
- queued status poll helper exists and is not wired
- queued assistant placeholder helper exists and is not wired
- submit decision helper exists and is not called
- decisionWired false is authoritative
- mocked submit decision cannot select queued chat yet
- current legacy chat path remains active

## Future insertion rule

The future queued decision call must be inserted at exactly one point in the existing chat submit flow.

It must happen after the user submit payload is available.

It must happen before the existing non-queued assistant request is made.

It must not render duplicate user messages.

It must not render duplicate assistant placeholders.

It must not create duplicate queued jobs.

It must not start duplicate polling loops.

## Required future decision call

A later stage may call:

- AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH.shouldUseQueuedChatForSubmit

But only behind the disabled-by-default frontend flag.

While decisionWired remains false, the decision helper must continue returning shouldUseQueuedChat false.

## Future flag-off behavior

When AI_PLATFORM_QUEUED_CHAT_ENABLED is false:

- current submit path must run exactly as before
- no queued helper should be called from the live submit path
- no POST /api/chat/queued should happen from the live submit path
- no queued status polling should start
- no queued assistant placeholder should render

## Future flag-on behavior

A later wiring stage must prove, with mocked fetch first:

- submit decision is called once
- queued send helper is called once
- user message is rendered once
- queued placeholder is rendered once
- polling starts once for the returned job_id
- final assistant message renders once after complete
- failed status renders an error state
- timeout state does not duplicate messages

## Security requirements

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Required future smokes

Before production enablement:

- flag off submit path unchanged smoke
- flag on mocked queued submit smoke
- duplicate-submit protection smoke
- duplicate-poll protection smoke
- failed queued job UI smoke
- offline queued job UI smoke
- rollback flag-off smoke
- no identity fields smoke

## Recommended Stage 5F-43

Stage 5F-43 should add a static submit insertion guard marker near the current chat submit path.

Stage 5F-43 should not call the decision helper yet.

Stage 5F-43 should not change live submit behavior.

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
