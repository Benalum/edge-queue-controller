# Stage 16-E0 — PVESO Offline Auto-Power Primary Worker Plan, No Apply

Date: 2026-06-19
Base checkpoint: Stage 16-D1 / HEAD bdd800f

## Scope

Stage 16-E0 records the corrected worker architecture.

This is a repo-only no-apply planning phase.

It does not wake PVESO.

It does not mutate PVESO.

It does not mutate PVEW.

It does not deploy backend code.

It does not deploy frontend code.

It does not write the database.

It does not start, stop, restart, reload, enable, or disable services.

It does not start or stop CTs or VMs.

It does not activate workers.

It does not activate schedulers.

It does not call Ollama endpoints.

It does not call model endpoints.

It does not run ollama list, ollama pull, ollama run, or ollama show.

It does not call /tick/ollama-direct.

## Corrected architecture

PVESO is intentionally offline by default.

PVESO should become the main on-demand model worker host because it has the llms container, Ollama, model assets, and more compute resources.

PVEW remains the always-on platform host.

CT203 on PVEW remains controller, API, queue, and decision authority.

VM200 on PVEW remains public/static edge.

CT204 on PVEW remains stopped backup-data-only.

PVEW may later host a replica/helper model worker, but it should not replace PVESO as the primary model worker.

## Auto-power principle

PVESO should be controlled by an auto-power layer.

Auto-power must decide when PVESO should be powered on or powered off.

PVESO should not need to stay online all the time.

The controller must treat PVESO worker capacity as conditional capacity.

The queue should remain durable while PVESO is offline.

Users should be able to submit jobs while PVESO is offline.

The decision maker should be able to classify whether a job needs PVESO.

The power policy should wake PVESO only for jobs that need model-worker capacity.

The power policy should shut PVESO down only after safe idle conditions are met.

## Initial auto-power policy draft

Wake PVESO when all are true:

- a queued job requires real model execution;
- no active PVEW replica/helper worker can satisfy the job;
- PVESO is offline;
- wake cooldown has expired;
- the job is allowed to wait for worker boot.

Keep PVESO online when any are true:

- model jobs are running;
- model jobs are queued and assigned to PVESO class workers;
- recent model activity is inside the idle grace window;
- health checks are still settling after boot.

Power off PVESO when all are true:

- no model jobs are running;
- no PVESO-assigned model jobs are queued;
- idle grace window has elapsed;
- no maintenance lock is active;
- no manual keep-awake override is active;
- last health check is clean enough for safe shutdown.

## Safety boundaries

Auto-power must be separate from model execution.

Waking PVESO must not automatically run a model job.

Starting the llms container must not automatically process the queue unless explicitly approved.

Worker bridge activation must remain separate from PVESO power control.

The one real queued model job must remain separately approved.

## Required phases after this

### Stage 16-E1 — auto-power design, no apply

Define:

- wake mechanism, likely Wake-on-LAN or controlled smart power path;
- shutdown mechanism;
- health checks;
- cooldowns;
- idle grace period;
- manual override flags;
- audit log fields;
- failure states;
- rollback path.

### Stage 16-E2 — PVESO wake readiness inventory, explicit approval required

This may wake PVESO only if explicitly approved.

It must not run model jobs.

It must not activate workers.

It must not activate schedulers.

It must inventory the llms container, Ollama runtime, model storage, and worker bridge possibilities.

### Stage 16-F — PVESO llms worker bridge prep, explicit approval required

This may prepare a default-off worker bridge.

It must not run real model jobs unless separately approved.

### Stage 16-D — one controlled queued model test, explicit approval required

This remains the separate approval for exactly one real model job through the queue.

## Future approval phrases

Auto-power design/no-apply does not need mutation approval.

PVESO wake readiness must require:

APPROVE_STAGE_16_E2_PVESO_WAKE_READINESS_INVENTORY_NO_WORKER_NO_MODEL_JOB

PVESO worker bridge preparation must require:

APPROVE_STAGE_16_F_PVESO_LLMS_WORKER_BRIDGE_PREP_NO_MODEL_JOB_NO_SCHEDULER_BROAD_ACTIVATION

The one real queued model test must require:

APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

## Current decision

Do not attempt Stage 16-D real model execution yet.

Do not install Ollama on PVEW as the first path.

Do design PVESO auto-power first.

Do use PVESO llms as primary worker target after wake/readiness inventory.

Do add PVEW replica/helper later after PVESO primary path is proven.
