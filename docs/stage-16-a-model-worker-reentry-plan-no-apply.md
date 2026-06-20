# Stage 16-A — Model Worker Re-entry Plan, No Apply

Date: 2026-06-19
Base checkpoint: Stage 15-F / HEAD 5dd5c0b

## Scope

This is a no-apply planning and inventory phase for controlled model-worker re-entry.

Stage 15 is now complete enough for model-worker planning because:

- authenticated /api/chat/queued creates durable mock companion.chat jobs;
- authenticated /api/chat/queued/{job_id} can poll a queued job;
- authenticated /api/chat/queue/status?job_id=... can poll the compatibility status route;
- the Companion UI now displays mock/no-model queued jobs as an intentional waiting state instead of a failure.

## Inventory result

The read-only Stage 16-A inventory completed before the smoke mismatch.

Observed platform state:

- PVEW quorum was healthy.
- VM200 was running.
- CT203 was running.
- CT204 was stopped.
- private storage was not mounted.
- private storage mapper was absent.
- CT203 controller service was active and enabled.
- VM200 nginx was active.
- VM200 cloudflared was active.
- public /app.js matched the Stage 15-F deployed hash.

Observed CT203 database counts:

- user_sessions: 235
- jobs: 23
- job_results: 6
- router_logs: 0
- router_resolution_steps: 0
- router_feedback: 0
- workers: 2
- worker_events: 3

No additional DB writes were performed in Stage 16-A.

## Clarification on inventory output

The observed pvescheduler.service is Proxmox VE scheduler, not the AI Platform model scheduler.

The long kworker process list is Linux kernel worker threads, not AI Platform worker activation.

CT203 listener inventory showed the controller listener on port 7070 only.

## Safety boundaries

This phase does not activate model work.

Prohibited until a later explicit approval:

- worker activation;
- scheduler activation;
- Ollama endpoint calls;
- live model endpoint calls;
- /tick/ollama-direct calls;
- persistent worker enablement;
- CT or VM restart;
- DB schema migration;
- Cloudflare, DNS, or tunnel changes;
- CT204 start or authority change;
- private storage unlock or mount;
- PVESO mutation.

## Re-entry principle

Users must still never talk directly to models.

The allowed future path is:

Frontend -> CT203 API -> durable job row -> scheduler/decision policy -> worker -> model -> job result -> frontend poll.

The first model re-entry must therefore go through the queue path, not through /tick/ollama-direct.

## Proposed Stage 16 sequence

### Stage 16-B — model target inventory, no apply

Read-only only.

Goals:

- identify where Ollama/model runtime should live;
- identify candidate small model for first controlled queue test;
- inspect service/unit files without starting anything;
- inspect existing worker helper code and scheduler integration points;
- confirm no live model endpoint calls are needed for inventory.

### Stage 16-C — worker/scheduler contract patch, default off

Code/docs only unless separately approved.

Goals:

- make one model worker path explicitly default-off;
- keep worker disabled until an explicit activation approval;
- require model calls to be queue-owned;
- block direct /tick/ollama-direct for this rollout path;
- emit clear evidence around job id, worker id, model, status, result, and error.

### Stage 16-D — one controlled mock-to-real queue test, explicit approval required

This must require a separate approval phrase.

Allowed only after approval:

- start or enable the minimum required worker path if needed;
- make exactly one bounded model call through the queued job path;
- write exactly one result row for the test job;
- verify frontend polling receives the result;
- stop or disable temporary worker activation if the design requires that.

Still not allowed in Stage 16-D unless separately approved:

- broad scheduler activation;
- persistent lane worker enablement;
- multiple concurrent model jobs;
- Study automatic model grading;
- voice STT or TTS activation;
- CT204 authority change;
- private storage unlock.

## First model target preference

For the first controlled real-model queue test, prefer a small and fast local model with one short Companion prompt.

The first real-model proof should prioritize:

1. safety and rollback;
2. queue correctness;
3. result persistence;
4. frontend poll display;
5. no broad worker or scheduler rollout.

## Exit criteria for Stage 16 readiness

Before any activation approval, the next no-apply phase must produce:

- exact target host or container;
- exact service or command to start;
- exact model name;
- exact queue job type;
- exact DB tables and rows expected to change;
- exact rollback or disable path;
- exact verification checks;
- proof that CT204 remains stopped and private storage remains locked.
