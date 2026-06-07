# Synthetic Queued Chat Route Wiring — Stage 5F-9

## Purpose

Stage 5F-9 wires the queued chat route to the synthetic queued-chat creation helper.

This stage does not change default production chat behavior.

## Routes

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}

## Required flags

Both flags are required for the synthetic route to create queued jobs:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=1

## Default behavior

When LAPTOP_CHAT_QUEUE_ENABLED is unset or 0:

- routes return HTTP 404
- error is feature_disabled

## Enabled but non-synthetic behavior

When LAPTOP_CHAT_QUEUE_ENABLED=1 but LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY is unset or 0:

- routes return HTTP 501
- error is synthetic_only_required_stage_5f9

## Synthetic enabled behavior

When both flags are enabled:

- POST /api/chat/queued creates a synthetic queued chat job
- GET /api/chat/queued/{job_id} reads synthetic queued chat job status

## Safety

The POST route requires:

- X-Synthetic-User-Id header
- synthetic user id prefix
- synthetic chat id prefix when chat_id is provided

The GET route refuses non-synthetic job ids.

## What this stage does not do

This stage does not:

- create real production chat jobs
- persist assistant messages from real jobs
- enable default queued chat behavior
- migrate real users
- migrate real chat data
- call CT101
- call Ollama
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Next stage

Stage 5F-10 should add an end-to-end synthetic queued chat route lifecycle smoke.

That should create a queued job through the route, let CT101 bounded poller complete it, persist assistant message once, and verify status.
