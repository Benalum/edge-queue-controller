# Real-User Queued Chat Creation Helper — Stage 5F-18

## Purpose

Stage 5F-18 adds a real-user queued chat creation helper.

This stage does not wire production routes to real-user job creation.

This stage does not change default production chat behavior.

## Helper

- edge_modules/chat_queue_real_user_creation.py

## Required flags

The helper requires:

- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1

## What the helper proves

The helper proves:

- helper is disabled by default
- authenticated_user_id must come from server-side auth
- client-provided user_id is refused
- wrong-user chat reuse is refused
- owned existing chat can create a queued job
- absent chat_id creates a new chat
- user message is persisted before job creation
- app_jobs row is created with status queued
- payload_json contains chat_id, user_message_id, prompt, messages, mode, route_source, synthetic false, and requested_model

## Safety

This helper is not wired into production routes.

This helper does not call CT101.

This helper does not call Ollama.

This helper does not persist assistant messages.

## What this stage does not do

This stage does not:

- enable real-user queued chat by default
- wire real-user route job creation
- call CT101
- call Ollama
- persist assistant messages from real user jobs
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

Stage 5F-19 should wire POST /api/chat/queued to this helper only behind explicit real-user flags.

Production queued chat should remain disabled unless explicitly enabled.
