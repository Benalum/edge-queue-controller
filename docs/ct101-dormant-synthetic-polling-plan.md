# CT101 Dormant Synthetic Polling Plan — Stage 5E-18

## Purpose

Stage 5E-18 plans a future CT101 synthetic laptop-queue polling mode.

This stage is planning only.

No persistent worker is implemented in this stage.

## Current proven foundation

Already proven:

- laptop queue internal API exists
- laptop queue token hardening works
- CT101 can reach laptop queue over Tailscale
- CT101 can claim and complete synthetic laptop jobs
- CT101 dormant laptop queue client works
- laptop worker register and heartbeat endpoints work
- laptop synthetic recovery endpoint works
- laptop idempotent completion safety works

## Goal of future synthetic poller

A future synthetic poller should:

- run only when explicitly enabled
- process synthetic jobs only
- heartbeat while idle and busy
- process a bounded number of jobs
- exit cleanly
- never run automatically from Docker Compose during early stages
- never claim production jobs

## Required future env flags

The future poller must require:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- LAPTOP_QUEUE_BASE_URL
- LAPTOP_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env
- LAPTOP_QUEUE_WORKER_ID
- LAPTOP_QUEUE_WORKER_NODE_ID
- LAPTOP_QUEUE_JOB_TYPES=ollama_chat
- LAPTOP_QUEUE_POLL_MODE=bounded
- LAPTOP_QUEUE_MAX_JOBS_PER_RUN
- LAPTOP_QUEUE_POLL_INTERVAL_SECONDS

## Disabled-by-default rule

The future poller must be disabled by default.

It must not start from the production CT101 worker loop unless an explicit later stage enables it.

It must not be added to Docker Compose yet.

## Synthetic-only guardrails

The future poller must:

- require LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- refuse non-synthetic job IDs
- allow only stage/synthetic prefixes
- exit on guardrail failure
- never claim production jobs
- never process user-facing production queue items

## Bounded polling behavior

Initial implementation should be bounded.

Recommended defaults:

- LAPTOP_QUEUE_MAX_JOBS_PER_RUN=2
- LAPTOP_QUEUE_POLL_INTERVAL_SECONDS=1
- no infinite loop
- no daemon mode
- no Docker Compose service
- no production worker integration

The poller should exit when either:

- max jobs processed
- no job is available after a small number of idle polls
- an unrecoverable safety error occurs

## Heartbeat behavior during polling

The future poller should call:

- POST /internal/laptop-queue/workers/register before polling
- POST /internal/laptop-queue/workers/heartbeat with idle before claim
- POST /internal/laptop-queue/workers/heartbeat with busy and current_job_id after claim
- POST /internal/laptop-queue/workers/heartbeat with idle after completion/failure

Heartbeat must not complete jobs.

Heartbeat must not recover jobs.

## Recovery expectations

The poller should not directly recover jobs in early stages.

Recovery remains a separate laptop/controller endpoint:

- POST /internal/laptop-queue/recover

A future smoke can separately prove:

- poller starts job
- poller exits/crashes before completion
- recovery marks stale worker offline
- recovery marks stuck job failed

## Result behavior

The first bounded poller should support synthetic `ollama_chat` only.

For smoke testing, it can return a deterministic synthetic reply instead of calling Ollama.

Do not call real Ollama in the first bounded poller stage.

Real model execution should be a later stage.

## Stop and rollback behavior

Because the poller is bounded and smoke-only:

- stop is normal process exit
- rollback is deleting/reverting the CT101 smoke script
- no service restart should be needed
- no Docker Compose rollback should be needed

For future persistent mode:

- use explicit service flag
- support graceful shutdown
- heartbeat offline on shutdown
- keep current CT101 production worker unchanged until cutover

## Recommended Stage 5E-19

Stage 5E-19 should add a CT101 smoke-only bounded synthetic poller.

It should:

- live under CT101 ops/smoke
- import the dormant laptop queue client
- register worker
- heartbeat idle
- claim synthetic job
- heartbeat busy
- complete or fail synthetic job
- heartbeat idle
- process at most two synthetic jobs
- exit immediately
- be run only by controller smoke

## What Stage 5E-19 should not do

Do not:

- modify production worker loop
- change Docker Compose
- start a persistent worker
- call real Ollama
- migrate production jobs
- claim real jobs
- change chat/study behavior

## What must remain postponed

Postpone:

- persistent polling
- daemon service
- Docker Compose integration
- production chat migration
- production study migration
- retry/requeue behavior
- real Ollama execution through laptop queue
- cleanup of CT101 legacy queue

## Cleanup requirement

After the full laptop queue migration is complete and verified, remove unused legacy pieces in a separate cleanup stage.

Cleanup candidates:

- old CT101 queue routes
- CT101 local jobs table usage
- older one-shot smoke helpers
- duplicate queue helpers
- old CT101 frontend job pages
- obsolete wrapper compatibility routes
- obsolete SQLite tables

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5E-18 constraints

Do not:

- implement persistent polling
- modify CT101 files
- modify production worker loop
- change Docker Compose
- restart services
- migrate production jobs
- claim real jobs
- call real Ollama through laptop queue
- change chat behavior
- change study behavior
