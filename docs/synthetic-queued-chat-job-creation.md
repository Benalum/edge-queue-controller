# Synthetic Queued Chat Job Creation — Stage 5F-8

## Purpose

Stage 5F-8 adds a synthetic queued-chat job creation helper and smoke.

This stage does not change production chat behavior.

## Helper

- edge_modules/chat_queue_creation.py

## What the helper proves

The helper proves:

- synthetic authenticated user can create a queued chat job
- new chat can be created when chat_id is absent
- existing owned chat can be reused when chat_id is present
- user message is persisted before job creation
- app_jobs row is created with status queued
- payload_json contains chat_id, user_message_id, prompt, messages, mode, route_source, and synthetic marker
- non-synthetic user ids are refused
- wrong chat ownership is refused

## Safety

This helper is not wired into production routes.

It refuses non-synthetic user ids.

It is used only by synthetic smoke tests in this stage.

## What this stage does not do

This stage does not:

- change production chat behavior
- activate POST /api/chat/queued job creation
- call CT101
- call Ollama
- create assistant messages from real jobs
- migrate real users
- migrate real chat data
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Next stage

Stage 5F-9 should connect the disabled-by-default queued chat route to this helper only when LAPTOP_CHAT_QUEUE_ENABLED=1 and a synthetic/test guard is also enabled.

Production behavior should remain unchanged unless explicitly enabled.
