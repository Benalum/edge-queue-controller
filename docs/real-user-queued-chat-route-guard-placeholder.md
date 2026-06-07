# Real-User Queued Chat Route Guard Placeholder — Stage 5F-14

## Purpose

Stage 5F-14 adds a route-level placeholder for future real-user queued chat.

This stage does not enable real-user queued chat.

This stage does not change default production chat behavior.

## Behavior

When LAPTOP_CHAT_QUEUE_ENABLED is unset or 0:

- queued chat routes still return feature_disabled

When LAPTOP_CHAT_QUEUE_ENABLED=1 and LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=1:

- synthetic queued chat route behavior still works

When LAPTOP_CHAT_QUEUE_ENABLED=1 and LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1 without synthetic mode:

- queued chat routes return session_auth_not_wired_stage_5f14
- no real jobs are created
- no assistant messages are persisted

## Why this stage exists

The real-user guard helper exists, but the route must not accept real users until authenticated session-derived user resolution is wired.

## What this stage does not do

This stage does not:

- enable real-user queued chat
- create real production chat jobs
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

Stage 5F-15 should inspect or implement the exact session-derived user resolver used by controller auth.

Real-user queued chat must remain disabled until that resolver is proven.
