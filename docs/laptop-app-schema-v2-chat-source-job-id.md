# Laptop App Schema v2 Chat Source Job ID — Stage 5F-4

## Purpose

Stage 5F-4 adds the laptop Postgres schema support needed for queued chat assistant-message idempotency.

This stage changes schema only.

No production chat behavior changes happen in this stage.

## Migration file

- ops/db/laptop-app-schema-v2-chat-source-job-id.sql

## Apply script

- ops/db/apply-laptop-app-schema-v2-chat-source-job-id.sh

## Schema changes

Adds:

- app_messages.source_job_id TEXT NULL

Adds unique partial index:

- idx_app_messages_source_job_id_unique

The index applies only when source_job_id is not null.

## Why this is needed

When a queued chat job completes, the assistant message persistence layer must create exactly one assistant message.

source_job_id allows the app to link a persisted assistant message to the completed queue job.

The unique partial index prevents duplicate assistant messages for the same completed job.

## Safe behavior

This migration is idempotent.

It can be run more than once.

Existing app_messages rows remain valid because source_job_id is nullable.

## What this stage does not do

This stage does not:

- change production chat behavior
- add production queued chat routes
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

## Required proof

The smoke verifies:

- source_job_id column exists
- unique partial index exists
- migration marker exists
- duplicate non-null source_job_id is rejected
- multiple null source_job_id messages are allowed
- synthetic rows are cleaned up

## Next stage

Stage 5F-5 should add a laptop-side synthetic assistant-message persistence helper and smoke.

It should prove:

- completed queued job creates one assistant message
- duplicate persistence returns the same assistant message
- failed job creates no assistant message

Stage 5F-5 should still not change production chat behavior.
