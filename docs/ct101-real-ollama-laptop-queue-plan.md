# CT101 Real Ollama Laptop Queue Plan — Stage 5E-20

## Purpose

Stage 5E-20 plans real Ollama execution through the laptop-owned queue.

This stage is planning and read-only inspection only.

No CT101 files are modified in this stage.

No bounded poller calls real Ollama in this stage.

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
- CT101 bounded synthetic poller processed two synthetic jobs and exited

## Inspection notes

Read-only inspection notes are saved at:

- docs/ct101-ollama-laptop-queue-inspection-notes.md

Primary CT101 files inspected:

- backend/app/worker/agent.py
- backend/app/worker/laptop_queue_client.py
- ops/smoke/laptop_queue_bounded_synthetic_poller.py
- backend/app/routes/chat.py
- backend/app/routes/jobs.py
- backend/app/services/context_builder.py
- docker-compose.yml

## Target next behavior

A future Stage 5E-21 should add a smoke-only bounded poller mode that calls real Ollama for synthetic laptop queue jobs.

It should still be:

- disabled by default
- synthetic-only
- bounded
- not connected to Docker Compose
- not part of the production worker loop
- not used by production jobs

## Required future env flags

The real-Ollama bounded poller should require:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- LAPTOP_QUEUE_POLL_MODE=bounded
- LAPTOP_QUEUE_EXECUTION_MODE=ollama
- LAPTOP_QUEUE_BASE_URL
- LAPTOP_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env
- LAPTOP_QUEUE_WORKER_ID
- LAPTOP_QUEUE_WORKER_NODE_ID
- LAPTOP_QUEUE_JOB_TYPES=ollama_chat
- LAPTOP_QUEUE_MAX_JOBS_PER_RUN
- LAPTOP_QUEUE_POLL_INTERVAL_SECONDS
- LAPTOP_QUEUE_OLLAMA_BASE_URL=http://127.0.0.1:11434
- LAPTOP_QUEUE_OLLAMA_TIMEOUT_SECONDS
- LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK

## Execution mode safety

The current bounded poller uses deterministic synthetic replies.

A future real-Ollama poller should require:

- LAPTOP_QUEUE_EXECUTION_MODE=ollama

Without that flag, it should keep deterministic synthetic result behavior.

This prevents accidental model calls during smoke-only tests.

## Synthetic-only payload contract

For Stage 5E-21, real Ollama should only be used for synthetic payloads.

The job should be refused unless:

- job id starts with an allowed synthetic prefix
- job_type is ollama_chat
- payload_json contains a prompt or messages field
- requested_model is present or fallback model is configured

If the prompt is missing, fail the job safely with error_text.

## Result contract

Successful Ollama result should complete the laptop queue job with result_json containing:

- reply
- model
- worker
- mode
- elapsed_seconds
- source

Suggested source value:

- ct101_bounded_ollama_poller

Failure should fail the job with error_text containing a clear bounded message.

Do not include secrets, tokens, full environment, or sensitive logs in result_json or error_text.

## Timeout behavior

The real-Ollama poller must set a timeout.

Recommended initial smoke default:

- LAPTOP_QUEUE_OLLAMA_TIMEOUT_SECONDS=60

If timeout occurs:

- fail the job
- heartbeat idle after failure
- exit normally after bounded processing

Do not leave the job running.

## Heartbeat behavior

The real-Ollama poller should:

1. register worker
2. heartbeat idle
3. claim synthetic job
4. heartbeat busy with current_job_id
5. call Ollama
6. complete or fail job
7. heartbeat idle
8. exit after bounded job count or idle limit

Heartbeat must not complete jobs.

Heartbeat must not recover jobs.

## Recovery interaction

If the poller crashes during real Ollama execution:

- laptop queue recovery should mark stale worker offline
- laptop queue recovery should fail stuck running job
- late completion after recovery should be rejected by idempotent completion safety

This has already been proven synthetically, but should be re-tested after real Ollama execution is added.

## Model selection

Initial Stage 5E-21 should use a small, fast model.

Recommended behavior:

- prefer job.requested_model
- fallback to LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK
- fail safely if neither is available

Do not introduce complex routing yet.

Small/medium/large routing can be planned later.

## What Stage 5E-21 should do

Stage 5E-21 should:

- add CT101 smoke-only real-Ollama bounded poller mode
- keep deterministic mode available
- create one synthetic laptop queue job with a simple prompt
- run CT101 bounded poller with LAPTOP_QUEUE_EXECUTION_MODE=ollama
- verify job completes with real reply text
- verify worker returns idle
- cleanup synthetic rows

## What Stage 5E-21 should not do

Do not:

- modify production worker loop
- change Docker Compose
- start persistent worker
- migrate production jobs
- claim real jobs
- change chat/study behavior
- route public users through laptop queue
- add model routing complexity

## Production migration remains postponed

Production chat migration should wait until:

- real-Ollama synthetic smoke passes
- timeout/failure smoke passes
- recovery after crash is tested with real model path
- result shape is stable
- laptop UI can show queued/running/failed/complete
- rollback is documented
- backups pass

## Cleanup requirement

After full migration is complete and verified, remove unused legacy pieces in a separate cleanup stage.

Cleanup candidates:

- old CT101 queue routes
- CT101 local jobs table usage
- older one-shot smoke helpers
- duplicate queue helpers
- old CT101 frontend job pages
- obsolete wrapper compatibility routes
- obsolete SQLite tables

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5E-20 constraints

Do not:

- implement real Ollama poller yet
- modify CT101 files
- modify production worker loop
- change Docker Compose
- restart services
- run persistent workers
- migrate production jobs
- claim real jobs
- change chat behavior
- change study behavior
