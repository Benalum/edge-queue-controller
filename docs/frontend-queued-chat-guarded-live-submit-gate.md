# Frontend Queued Chat Guarded Live Submit Gate — Stage 5F-63

## Purpose

Stage 5F-63 adds a disabled guarded live-submit gate branch.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is added

The stage adds:

- Stage 5F-63 marker near the live submit path
- window.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH
- evaluateGuardedLiveSubmitGate
- guardedLiveSubmitGateWired false

## Safety

The gate helper is not called by live submit.

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
- guarded live-submit gate remains unwired
- queued submit remains blocked
- no queued orchestration is selected
- no queued send is called
- no queued polling starts
- no queued placeholder renders

When AI_PLATFORM_QUEUED_CHAT_ENABLED is true in a later stage:

- guardedLiveSubmitGateWired must still control whether the live branch can run
- live submit must call queued orchestration at most once
- live submit must not create duplicate queued jobs
- live submit must not create duplicate placeholders
- live submit must not start duplicate polling loops
- live submit must not render duplicate final assistant messages

## Required future order

The future guarded live submit branch should eventually use this order:

1. check frontend queued-chat flag
2. check guardedLiveSubmitGateWired
3. check guardedLiveSubmitWired
4. build safe payload once
5. make submit decision once
6. run queued orchestration once
7. render placeholder once
8. poll status once
9. render final assistant reply once

## Required payload shape

The queued submit payload may contain only:

- message
- chat_id
- requested_model

## Required security behavior

The frontend must not send client-provided identity fields.

The frontend must not send synthetic-user headers.

The frontend must rely on normal browser session credentials.

## Recommended Stage 5F-64

Stage 5F-64 should add a mocked test for the guarded live-submit gate helper.

Stage 5F-64 should still not wire queued chat into the real submit handler.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
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
