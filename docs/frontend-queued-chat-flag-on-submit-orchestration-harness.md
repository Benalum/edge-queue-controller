# Frontend Queued Chat Flag-On Submit Orchestration Harness — Stage 5F-56

## Purpose

Stage 5F-56 adds a mocked flag-on submit orchestration test harness.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## What is tested

The smoke creates a mocked live-submit-style harness outside the real app submit path.

The test proves:

- flag off uses mocked legacy submit path
- flag off does not call queued orchestration
- flag on calls queued orchestration once
- queued orchestration calls payload once
- queued orchestration calls decision once
- queued orchestration calls send once
- queued orchestration calls placeholder once
- queued orchestration calls poll once
- no duplicate queued POST is simulated
- no duplicate placeholder is simulated
- no duplicate polling loop is simulated
- no duplicate final assistant reply is simulated
- unsafe identity fields are ignored by the mocked safe payload builder

## Safety

This is a smoke/unit-style test only.

The real frontend submit path is not changed.

The queued submit orchestration helper remains disabled by default.

No production queued jobs are submitted.

No real CT101 call is made.

No real Ollama call is made.

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

## Required future behavior

A later stage may begin adding an actual guarded submit branch, but must still prove:

- flag off keeps legacy submit path
- flag on calls orchestration once
- no duplicate queued POST
- no duplicate placeholder
- no duplicate polling
- no duplicate final assistant message
- rollback flag off restores legacy path

## Recommended Stage 5F-57

Stage 5F-57 should add a guarded submit branch skeleton near the Stage 5F-43 marker, disabled by default.

Stage 5F-57 should not enable queued chat by default.

Production queued chat should remain disabled unless explicitly enabled.

## What this stage does not do

This stage does not:

- change chat submit behavior
- change message rendering behavior
- enable queued chat by default
- wire queued chat into normal submit
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
