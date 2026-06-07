# Queued Chat Route Skeleton — Stage 5F-7

## Purpose

Stage 5F-7 adds disabled-by-default queued chat route skeletons.

This stage does not change production chat behavior.

## Routes added

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}

## Default behavior

By default, LAPTOP_CHAT_QUEUE_ENABLED is unset or 0.

The queued chat routes return:

- HTTP 404
- error: feature_disabled

## Enabled skeleton behavior

When LAPTOP_CHAT_QUEUE_ENABLED=1, the routes return:

- HTTP 501
- error: not_implemented_stage_5f7

This proves the routes exist without creating jobs or changing production behavior.

## What this stage does not do

This stage does not:

- create real production chat jobs
- persist assistant messages from real jobs
- migrate real users
- migrate real chat data
- change the existing chat route
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Next stage

Stage 5F-8 should add a synthetic queued-chat job creation helper and smoke.

Stage 5F-8 should still keep production queued chat disabled by default.
