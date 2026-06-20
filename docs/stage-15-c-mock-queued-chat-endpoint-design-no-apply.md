# Stage 15-C — Mock Queued Chat Endpoint Design No-Apply

Date: 2026-06-19  
Base checkpoint: Stage 15-B / HEAD `3a66500`  
Mutation scope: repo docs/smoke only

## Purpose

Design the first safe implementation step for Companion queued chat compatibility.

This phase is no-apply. It does not mutate CT203 runtime files, restart services, write DB rows, activate workers, activate scheduler, call Ollama, or call any model endpoint.

## Inventory finding

The VM200 frontend references:

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}
- GET /api/chat/queue/status?job_id=...

CT203 already has durable queue primitives and DB tables:

- jobs
- job_results
- workers
- worker_events
- router tables

But the exact frontend-facing `/api/chat/queued` compatibility routes were not observed as active CT203 routes.

## Design decision

Stage 15-D should add thin CT203 product API compatibility routes:

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}
- GET /api/chat/queue/status

These routes should map to existing durable jobs/job_results tables.

Initial behavior must be mock/no-model only.

## Decision Maker boundary

The Decision Maker remains a controller-side policy layer, not a model worker.

It should produce an in-memory decision object for first apply:

- surface: companion
- intent: companion.chat
- route_type: queue_job
- job_type: companion.chat
- model_tier: medium
- requested_model: mock/no-model
- model_call: not_started
- safety_flags: no_model_call, no_worker_activation, no_scheduler_activation

The Decision Maker must not call Ollama, workers, scheduler, or models.

## POST /api/chat/queued plan

Accepted request fields should tolerate current frontend variants:

- message
- prompt
- input
- metadata

Prompt normalization:

1. prefer message
2. else prompt
3. else input
4. else return HTTP 400

Auth:

- require authenticated user/session
- return HTTP 401 if unauthenticated
- do not create anonymous companion jobs in first apply

DB write in Stage 15-D:

- insert exactly one jobs row per approved test post
- job_type=companion.chat
- requested_model=mock/no-model
- status=queued
- attempts=0
- user_id=authenticated user id

Response shape:

- ok=true
- job_id
- status=queued
- route_type=queue_job
- job_type=companion.chat
- model_tier=medium
- model_call=not_started

## GET /api/chat/queued/{job_id} plan

Rules:

- require authenticated user/session
- only return jobs owned by that user
- return 404 for missing jobs
- do not call model/worker/scheduler
- include result only if an existing job_results row exists
- otherwise result=null

## GET /api/chat/queue/status plan

Rules:

- accept job_id query parameter
- reuse GET /api/chat/queued/{job_id} logic
- keep as compatibility alias for current frontend polling

## Stage 15-D approval boundary

Do not run Stage 15-D without explicit approval.

Candidate approval phrase:

APPROVE_STAGE_15_D_MOCK_QUEUED_CHAT_COMPATIBILITY_APPLY_NO_MODEL_NO_WORKER_NO_SCHEDULER

Allowed in Stage 15-D only after approval:

- backend source code mutation for mock queued chat routes
- bounded DB writes for approved mock test posts
- controlled edge-queue-controller.service restart/reload only if required
- route validation
- commit/tag/push implementation checkpoint

Still prohibited:

- calling /tick/ollama-direct
- any Ollama endpoint call
- any model endpoint call
- worker activation
- scheduler activation
- persistent lane worker enablement
- router_logs writes
- router_resolution_steps writes
- router_feedback writes
- DB schema migration
- CT204 start
- private storage unlock/mount
- PVESO mutation
- nginx/cloudflared mutation
- Cloudflare/DNS/tunnel mutation
- CT/VM reboot

## Stage 15-D validation expectations

Before approved test:

- record jobs count
- record job_results count
- record router_logs count
- record workers count

After approved test:

- jobs increases by exactly approved mock job count
- job_results unchanged unless explicitly approved
- router_logs unchanged
- workers unchanged
- no worker activation
- no scheduler activation
- no model call
- no Ollama call

## Result

Stage 15-C selects a narrow apply path:

- add frontend-compatible queued chat product routes
- use existing CT203 durable jobs table
- create mock/no-model companion.chat jobs only
- keep Decision Maker in-memory for first apply
- avoid router evidence writes
- avoid workers, scheduler, Ollama, and models
