# Frontend Queued Chat Guarded Live Submit Branch Skeleton — Stage 5F-69

## Purpose

Stage 5F-69 adds a disabled guarded live-submit branch skeleton.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is added

The stage adds:

- Stage 5F-69 marker near the live submit path
- window.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH_SKELETON
- evaluateGuardedLiveSubmitBranch
- guardedLiveSubmitBranchWired false

## Safety

The branch skeleton is not called by live submit.

The current non-queued chat path remains active.

Queued chat remains disabled by default.

No production queued jobs are submitted.

No queued status polling is started.

No queued placeholder is rendered.

No real CT101 call is made.

No real Ollama call is made.

## Required flag behavior

When AI_PLATFORM_QUEUED_CHAT_ENABLED is false:

- legacy submit remains active
- guarded live-submit branch skeleton remains unwired
- queued submit remains blocked
- no queued payload builder is called
- no queued decision helper is called
- no queued orchestration is selected
- no queued send is called
- no queued polling starts
- no queued placeholder renders

When AI_PLATFORM_QUEUED_CHAT_ENABLED is true in a later stage:

- guardedLiveSubmitBranchWired must still control whether this branch can run
- guardedLiveSubmitGateWired must still control whether the gate can pass
- guardedLiveSubmitWired must still control whether live submit can proceed
- live submit must call queued orchestration at most once
- live submit must not create duplicate queued jobs
- live submit must not create duplicate placeholders
- live submit must not start duplicate polling loops
- live submit must not render duplicate final assistant messages

## Required future order

The future guarded live submit branch should eventually use this order:

1. check frontend queued-chat flag
2. evaluate guarded live-submit branch once
3. evaluate guarded live-submit gate once
4. check guardedLiveSubmitBranchWired
5. check guardedLiveSubmitGateWired
6. check guardedLiveSubmitWired
7. build safe payload once
8. make submit decision once
9. run queued orchestration once
10. render placeholder once
11. poll status once
12. render final assistant reply once

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

## Recommended Stage 5F-70

Stage 5F-70 should add a mocked test for the guarded live-submit branch skeleton.

Stage 5F-70 should still not wire queued chat into the real submit handler.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
- call the guarded branch skeleton from the live submit path
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
