# Stage 15-B — Decision Maker Boundary and Queue Contract No-Apply

Date: 2026-06-19  
Base checkpoint: Phase 14K-E / HEAD `64b8354`  
Mutation scope: repo docs/smoke only

## Purpose

Define the safe controller-side Decision Maker boundary and frontend queue contract before implementing or activating any worker, scheduler, Ollama/model, or live model path.

This phase is no-apply. It does not change runtime services, database schema, nginx/cloudflared config, workers, scheduler, or model endpoints.

## Inventory summary from Stage 15-A / 15-A1

Validated platform state:

- PVEW is quorate.
- VM200 is running.
- CT203 is running.
- CT203 `net0` is static and no longer DHCP.
- CT204 is stopped.
- Private storage is locked/unmounted.
- Public `/` is HTTP 200.
- Public `/system/status` is HTTP 200.
- Public `/api/system/status` is HTTP 200.
- Public `/api/me` is HTTP 401 unauthenticated, expected.

Observed CT203 controller state:

- Service: `edge-queue-controller.service`
- Service active/enabled.
- Listener: port `7070`.
- Working directory: `/opt/edge-queue-controller/current`
- Running release path: `/opt/edge-queue-controller/releases/head-a39021f`
- Main app source: `edge_controller.py`
- Public gateway source: `public_gateway.py`
- OpenAPI endpoint: `/openapi.json`
- Direct CT203 `/system/status`: HTTP 200.
- Direct CT203 `/api/system/status`: HTTP 404, with compatibility intentionally provided by VM200 nginx.

Observed CT203 routes include:

- `POST /jobs`
- `GET /jobs`
- `GET /queue/summary`
- `POST /tick`
- `GET /workers/registry`
- `GET /scheduler/preview`
- `POST /workers/heartbeat`
- `GET /workers/events`
- `POST /tick/ollama-direct`
- `POST /public/jobs`
- `GET /public/jobs/{job_id}`
- `GET /public/jobs`
- `GET /public/status`
- auth/account routes
- Study routes under `/api/study/...`

Observed database facts:

- SQLite DB: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- `jobs`: 22 rows
- `job_results`: 6 rows
- `workers`: 2 rows
- `worker_events`: 3 rows
- `router_logs`: 0 rows
- `router_resolution_steps`: 0 rows
- `router_feedback`: 0 rows
- `intent_definitions`: 14 rows
- `intent_routes`: 14 rows
- `global_phrase_bank`: 34 rows

Relevant existing tables:

- `jobs`
- `job_results`
- `workers`
- `worker_events`
- `intent_definitions`
- `intent_routes`
- `router_logs`
- `router_resolution_steps`
- `router_feedback`
- `global_phrase_bank`
- `user_phrase_bank`
- `user_language_preferences`
- `user_secondary_languages`

Observed frontend route references include:

- `/api/chat/queued`
- `/api/chat/queued/`
- `/api/chat/queue/status`
- `/api/chat/queue/status?job_id`
- `/api/study/decks`
- `/api/study/progress`
- `/api/study/session/status`
- `/api/study/session/start`
- `/api/study/session/command`
- `/api/calendar/`
- `/api/companion/`
- `/api/profile/preferences`

## Key blocker found

The frontend expects companion/chat queue routes under:

- `/api/chat/queued`
- `/api/chat/queued/{job_id}`
- `/api/chat/queue/status`
- `/api/chat/queue/status?job_id=...`

The backend inventory shows generic queue/job primitives, but not the exact frontend-facing `/api/chat/queued*` routes as active CT203 route decorators.

Therefore, the first implementation step should reconcile the frontend-facing queued chat API with existing CT203 job queue primitives. It should not activate workers, scheduler, Ollama, or models.

## Decision Maker boundary

The Decision Maker is a controller-side policy layer, not a model worker.

It should:

1. Receive normalized user request context from a product API endpoint.
2. Determine surface, intent, route type, job type, and model tier.
3. Decide whether the request is a status read, local action, queue job, auth-required request, confirmation-required request, or rejection.
4. Produce a decision object.
5. Never call Ollama or models directly.
6. Never activate workers or scheduler directly.
7. Never bypass backend authority.
8. Preserve auth/session checks.
9. Avoid exposing secrets or raw internal infrastructure values.
10. Write router/job records only in later approved apply phases.

The Decision Maker must output a decision object, not a model response.

## Decision object contract

Recommended shape:

```json
{
  "decision_version": 1,
  "request_id": "string",
  "user_id": "integer_or_null",
  "session_id": "string_or_null",
  "surface": "companion|study|calendar|profile|system|unknown",
  "input_text": "string",
  "normalized_input": "string",
  "detected_language": "string_or_null",
  "intent": "string",
  "intent_confidence": 0.0,
  "route_type": "local_action|queue_job|status_read|auth_required|confirmation_required|reject",
  "job_type": "string_or_null",
  "model_tier": "none|tiny|small|medium|large",
  "requested_model": "string_or_null",
  "requires_confirmation": false,
  "reason": "string",
  "safety_flags": [],
  "metadata": {}
}Run with Project Pilot
Running...
Queue job contract

When route_type=queue_job, the controller should map the decision into existing durable queue primitives.

Existing jobs table fields support a minimal queue write:

job_type
prompt
requested_model
status
attempts
created_at
updated_at
user_id

Recommended job types:

companion.chat
study.grade
study.tutor
calendar.assist
profile.assist
system.status_read

Initial Stage 15 implementation should start with companion.chat using mock/no-model execution only.

Frontend queued chat compatibility contract
POST /api/chat/queued

Purpose: create a queued companion chat job.

Initial no-model response shape:

{
  "ok": true,
  "job_id": 123,
  "status": "queued",
  "route_type": "queue_job",
  "job_type": "companion.chat",
  "model_tier": "medium",
  "model_call": "not_started"
}
GET /api/chat/queued/{job_id}

Purpose: retrieve queued companion job status/result.

Initial response shape:

{
  "ok": true,
  "job_id": 123,
  "status": "queued|running|complete|failed",
  "result": null,
  "error": null
}
GET /api/chat/queue/status?job_id=...

Purpose: compatibility alias for queued chat polling if current frontend still uses this route.

The response should match GET /api/chat/queued/{job_id} or wrap it without exposing internal queue details.

API compatibility design

Do not make the browser know about internal primitives such as /jobs or /public/jobs.

The browser should call stable product APIs:

/api/chat/queued
/api/study/...
/api/calendar/...
/api/companion/...

The backend may internally map those routes to:

jobs
job_results
router_logs
scheduler/preview
worker registry
Router evidence contract

Router tables exist but are currently empty.

Before writing router evidence, a later apply phase must define:

when to write router_logs
when to write router_resolution_steps
how to avoid logging sensitive raw input unnecessarily
how to map user/session IDs
how to handle anonymous traffic
how to summarize execution result safely
Model/Ollama activation boundary

Observed route /tick/ollama-direct exists, but Stage 15-B does not authorize its use.

Still prohibited until explicit approval:

calling /tick/ollama-direct
calling any Ollama endpoint
activating workers
enabling scheduler dispatch
live model endpoint calls
persistent lane worker enablement
DB migration/import/restore
Recommended next phases
Stage 15-C — no-apply endpoint implementation design

Plan exact code changes for:

POST /api/chat/queued
GET /api/chat/queued/{job_id}
GET /api/chat/queue/status
decision object builder
mock/no-model queue job creation flow
route smoke checks

No runtime mutation.

Stage 15-D — apply mock queued chat compatibility

Requires explicit approval if it involves:

service code mutation
DB writes
service restart/reload
creating jobs
changing frontend/backend deployed files

Allowed behavior should be limited to mock/no-model job creation and polling.

Stage 15-E — validation checkpoint

Validate:

frontend route can create a mock queued companion job
polling works
no model call occurs
no worker activation occurs
DB writes are exactly expected and bounded
Result

Stage 15-B chooses the safe direction:

Use frontend product APIs as stable public contracts.
Map product APIs to existing CT203 queue primitives.
Add Decision Maker as a controller-side policy layer.
Keep model/Ollama/worker/scheduler activation parked.

Start implementation with mock/no-model queued companion compatibility.

## Recovery note

Initial Stage 15 implementation should start with `companion.chat` using mock/no-model execution only.

## Smoke validation anchors

The Decision Maker is a controller-side policy layer, not a model worker.

The Decision Maker must output a decision object, not a model response.

POST /api/chat/queued

GET /api/chat/queued/{job_id}

GET /api/chat/queue/status?job_id=...

Initial Stage 15 implementation should start with `companion.chat` using mock/no-model execution only.

Still prohibited until explicit approval:

calling `/tick/ollama-direct`

activating workers

live model endpoint calls

Use frontend product APIs as stable public contracts.
