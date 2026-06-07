# Chat Assistant Message Idempotency Schema Plan — Stage 5F-3

## Purpose

Stage 5F-3 plans the schema needed to safely persist assistant messages from laptop-owned queued chat jobs.

This stage is planning only.

No schema changes happen in this stage.

No production chat behavior changes happen in this stage.

## Problem being solved

When queued chat becomes real, a completed job should create exactly one assistant message.

Duplicate assistant messages could happen if:

- a worker retries completion after a network failure
- a frontend polls completion more than once
- a backend persistence step is retried
- a job is completed twice idempotently
- recovery and late completion interact badly

The queue already protects job completion state, but chat message persistence also needs its own idempotency key.

## Current proven queue safety

Already proven:

- duplicate successful completion returns existing complete job without mutation
- late failure after success is rejected
- late success after recovered failure is rejected
- duplicate failure returns existing failed job without mutation
- failed Ollama jobs remain failed and return worker idle
- successful Ollama jobs complete and return worker idle

## Recommended schema approach

Recommended first production-safe approach:

- add source_job_id to app_messages
- create a unique index on app_messages.source_job_id where source_job_id is not null

This lets each completed queued job create at most one assistant message.

## Proposed future column

Future column:

ALTER TABLE app_messages ADD COLUMN source_job_id TEXT NULL;

## Proposed future unique index

Future index:

CREATE UNIQUE INDEX IF NOT EXISTS idx_app_messages_source_job_id_unique
ON app_messages(source_job_id)
WHERE source_job_id IS NOT NULL;

## Why source_job_id belongs on app_messages

source_job_id makes the assistant message directly traceable to the completed queue job.

Benefits:

- prevents duplicate assistant messages
- supports debugging
- supports retry-safe persistence
- supports status-to-message linking
- avoids trusting frontend state
- keeps app_jobs as durable execution records

## Alternative considered

Alternative:

- app_jobs.result_message_id

Downside:

- requires updating app_jobs after app_messages insert
- can still race unless app_messages has a uniqueness rule
- makes the message less directly searchable by job id

Recommended: use app_messages.source_job_id first.

## Future persistence rule

A future queued chat persistence function should:

1. verify job.status = complete
2. verify job.result_json.reply is non-empty
3. verify job.user_id matches authenticated user
4. verify chat belongs to authenticated user
5. insert assistant app_messages row with source_job_id = job.id
6. use ON CONFLICT or unique-index handling to return existing message if already created
7. never create assistant message for failed jobs

## Future failed-job rule

A failed queued chat job must not create an assistant message.

The UI should show failed job state separately.

## Future duplicate-completion rule

If the same complete job is processed again:

- do not insert a second assistant message
- return the existing assistant message
- preserve original created_at
- preserve original content unless an explicit repair tool exists later

## Future rollback rule

If queued chat is disabled:

- existing source_job_id values remain harmless
- current chat path remains active
- no old CT101 route deletion should happen
- no cleanup should happen until migration is stable

## Required future smokes

Before production queued chat persistence:

- schema migration smoke
- source_job_id unique index smoke
- complete job creates one assistant message smoke
- duplicate persistence returns same assistant message smoke
- failed job creates no assistant message smoke
- wrong-user job cannot create message smoke
- rollback flag leaves existing messages readable smoke

## Recommended Stage 5F-4

Stage 5F-4 should implement the laptop Postgres schema migration for source_job_id and the unique partial index.

Stage 5F-4 should still not migrate production chat behavior.

## Cleanup requirement

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

Cleanup candidates after full migration:

- old CT101 queue routes
- CT101 local jobs table usage
- old CT101 frontend chat pages
- duplicate queue helpers
- obsolete wrapper compatibility routes
- obsolete SQLite tables

## Stage 5F-3 constraints

Do not:

- change schemas
- change production chat behavior
- add production queued chat route
- persist assistant messages from real jobs
- migrate real users
- migrate real chat data
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior
