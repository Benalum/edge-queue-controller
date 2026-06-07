# Frontend Queued Chat Status Helper — Stage 5F-27

## Purpose

Stage 5F-27 adds a dormant frontend queued-chat status helper.

This stage does not change frontend runtime behavior.

This stage does not import the helper into app.js or index.html.

## Helper

- frontend/wrapper-ui/queued_chat_status.js

## Helper behavior

The helper defines:

- queued status normalization
- terminal status detection
- polling decision logic
- polling delay logic
- user-facing status labels
- assistant placeholder messages
- completed assistant reply extraction
- status view object building

## Runtime safety

The helper is intentionally unimported.

The helper does not submit jobs.

The helper does not call POST /api/chat/queued.

The helper does not call GET /api/chat/queued/{job_id}.

The helper does not call CT101.

The helper does not call Ollama.

The helper does not send user_id.

The helper does not send X-Synthetic-User-Id.

## Intended future use

A future frontend stage can import this helper and use it to show:

- queued
- running
- complete
- failed
- offline_or_waiting
- timed_out

## What this stage does not do

This stage does not:

- change frontend runtime behavior
- import queued_chat_status.js
- enable queued chat by default
- submit real production queued jobs
- start persistent workers
- call CT101
- call Ollama directly
- persist assistant messages
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Recommended Stage 5F-28

Stage 5F-28 should add a guarded frontend UI smoke or disabled-by-default wiring plan.

Production queued chat should remain disabled unless explicitly enabled.
