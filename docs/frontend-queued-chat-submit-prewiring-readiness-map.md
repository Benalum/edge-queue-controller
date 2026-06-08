# Frontend Queued Chat Submit Pre-Wiring Readiness Map — Stage 5F-59

## Purpose

Stage 5F-59 creates the final frontend queued-chat submit pre-wiring readiness map.

This stage is planning and static verification only.

This stage does not change frontend runtime behavior.

This stage does not wire queued chat into the real submit handler.

This stage does not enable queued chat by default.

## Current completed frontend foundation

The frontend queued-submit foundation now has:

- queued chat config flag defaulted off
- queued chat status helper imported
- queued send helper branch
- queued send helper mock test
- queued status poll helper branch
- queued status poll helper mock test
- queued assistant placeholder branch
- queued assistant placeholder mock test
- submit decision branch
- submit decision mock test
- submit dry-run branch
- submit dry-run mock test
- submit payload builder branch
- submit payload builder mock test
- submit orchestration plan
- submit orchestration branch
- submit orchestration mock test
- flag-off live submit preservation smoke
- flag-on submit orchestration harness
- guarded submit skeleton near live submit
- guarded submit skeleton mock test

## Current completed backend foundation

The backend queued-chat foundation now has:

- synthetic queued chat route wiring
- synthetic queued chat lifecycle to CT101
- real-user session auth guard
- real-user queued chat creation helper
- real-user queued chat route creation
- real-user queued chat status route
- real-user rollback/offline behavior
- real-user route to CT101 bounded lifecycle
- assistant message persistence after CT101 completion
- no assistant message before job completion
- ownership checks for chat reuse
- ownership checks for job status
- client-provided user_id refusal
- CT101 bounded real-user poller guard
- CT101 bounded Ollama failure behavior

## Required future wiring order

The first real guarded frontend wiring stage must preserve this order:

1. check AI_PLATFORM_QUEUED_CHAT_ENABLED
2. build safe payload once
3. make submit decision once
4. run queued submit orchestration once
5. call queued send once
6. render assistant placeholder once
7. poll status once per job_id
8. render final assistant reply once

## Required safe payload shape

The queued submit payload may contain only:

- message
- chat_id
- requested_model

## Required duplicate protection

Future wiring must prevent:

- duplicate user messages
- duplicate assistant placeholders
- duplicate POST /api/chat/queued calls
- duplicate polling loops for the same job_id
- duplicate final assistant messages
- duplicate error messages for the same failed job

## Required rollback behavior

Rollback must remain instant:

- AI_PLATFORM_QUEUED_CHAT_ENABLED false keeps legacy submit active
- guardedSubmitWired false keeps guarded submit out of live submit
- orchestrationWired false keeps orchestration out of live submit
- payloadWired false keeps payload builder out of live submit
- decisionWired false keeps decision helper out of live submit
- wiredToSubmit false keeps queued send out of live submit
- pollerWired false keeps polling out of live submit
- placeholderWired false keeps placeholder rendering out of live rendering

## Required security behavior

The frontend must not send:

- user_id
- authenticated_user_id
- X-Synthetic-User-Id

The frontend must rely on normal browser session credentials.

## Required failure handling before production enablement

A future live wiring stage must handle:

- missing message
- payload build failure
- decision refusal
- queued send failure
- missing job_id
- queued status timeout
- failed queued job
- CT101 offline where job remains queued
- backend feature disabled response
- session/auth failure response
- wrong-user job status refusal

## Recommended Stage 5F-60

Stage 5F-60 should add the first guarded live-submit branch behind the disabled-by-default frontend flag.

Stage 5F-60 must still keep AI_PLATFORM_QUEUED_CHAT_ENABLED false by default.

Stage 5F-60 must prove flag-off live submit behavior remains unchanged.

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
