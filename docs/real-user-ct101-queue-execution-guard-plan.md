# Real-User CT101 Queue Execution Guard Plan — Stage 5F-21

## Purpose

Stage 5F-21 plans the guardrails required before CT101 can execute real-user queued chat jobs.

This stage is planning only.

No production worker behavior changes happen in this stage.

## Current proven foundation

Already proven:

- real-user POST /api/chat/queued creates owned queued jobs behind explicit flags
- real-user GET /api/chat/queued/{job_id} returns only owned job status
- missing session tokens are refused
- wrong-user status lookups are refused
- synthetic route to CT101 lifecycle works
- assistant message persistence is idempotent
- failed jobs do not create assistant messages

## Problem being solved

CT101 currently runs bounded synthetic smoke pollers safely.

Before CT101 is allowed to claim real-user jobs, the worker path needs explicit guardrails.

## Required CT101 real-user execution flags

Real-user CT101 job execution must require explicit flags such as:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_POLL_MODE=bounded
- LAPTOP_QUEUE_EXECUTION_MODE=ollama
- LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=0
- LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1 for first smoke

Enabling LAPTOP_QUEUE_ENABLED alone must not allow real-user job execution.

## Required CT101 safety behavior

Future CT101 real-user job execution must:

1. refuse real-user jobs unless LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1
2. keep synthetic-only mode unchanged for synthetic smokes
3. run bounded one-shot first, not persistent worker loop
4. claim only ollama_chat jobs
5. complete only the claimed job
6. mark Ollama errors as failed jobs
7. return worker idle after completion or failure
8. avoid logging secrets or session tokens
9. avoid accepting user_id from CT101 input

## Required controller-side safety behavior

The laptop/controller must:

- keep real-user queued chat disabled by default
- require authenticated session for POST and GET
- return only user-owned job status
- persist assistant message only after complete job owned by the authenticated user
- preserve rollback by disabling flags

## First real-user CT101 smoke target

The first future real-user CT101 smoke should:

1. create synthetic smoke users and sessions in laptop Postgres
2. POST /api/chat/queued with real-user flags enabled
3. verify job status queued
4. run CT101 bounded one-shot poller with real-user jobs enabled
5. verify job status complete or failed
6. persist assistant message only if complete
7. verify duplicate persistence returns same assistant message
8. clean up all smoke rows

## What this stage does not do

This stage does not:

- allow CT101 to claim real-user jobs
- change CT101 worker code
- start persistent workers
- call Ollama for real-user jobs
- persist assistant messages from real-user jobs
- enable queued chat by default
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Recommended Stage 5F-22

Stage 5F-22 should add a dormant CT101 real-user execution guard or static smoke in the CT101 repo.

Stage 5F-22 should still avoid persistent worker execution.

## Cleanup requirement

Cleanup must wait until laptop queue is production source of truth and rollback is safe.
