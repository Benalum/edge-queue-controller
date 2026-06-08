# Frontend Queued Chat Guarded Submit Skeleton — Stage 5F-57

## Purpose

Stage 5F-57 adds a guarded queued-chat submit skeleton near the live submit path.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is added

The stage adds:

- Stage 5F-57 marker near the live submit listener
- window.AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH
- buildGuardedQueuedSubmitSkeleton
- guardedSubmitWired false

## Safety

The skeleton is not called by live submit.

The current non-queued chat path remains active.

Queued chat remains disabled by default.

No production queued jobs are submitted.

No queued status polling is started.

No queued placeholder is rendered.

No real CT101 call is made.

No real Ollama call is made.

The frontend does not send client-provided identity fields.

The frontend does not send synthetic-user headers.

## Planned future order

The future guarded submit branch should eventually use this order:

1. build safe payload
2. make submit decision
3. run orchestration once
4. render placeholder once
5. poll status once
6. render final assistant reply once

## Required future behavior

A later stage may wire a guarded branch, but must still prove:

- flag off keeps legacy submit path
- flag on calls orchestration once
- no duplicate queued POST
- no duplicate placeholder
- no duplicate polling
- no duplicate final assistant message
- rollback flag off restores legacy path

## Recommended Stage 5F-58

Stage 5F-58 should add a mocked test for the guarded queued submit skeleton branch.

Stage 5F-58 should still not wire queued chat into the real submit handler.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
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
