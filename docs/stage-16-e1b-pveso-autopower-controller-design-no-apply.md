# Stage 16-E1B — PVESO Auto-Power Controller Design, No Apply

Date: 2026-06-19
Base checkpoint: Stage 16-E1A / HEAD 74d6084

## Scope

Stage 16-E1B converts rediscovered existing power endpoints into the auto-power controller design for PVESO as the primary on-demand model worker host.

This is a repo-only no-apply design phase.

It does not wake PVESO.

It does not mutate PVESO.

It does not mutate PVEW.

It does not deploy backend code.

It does not deploy frontend code.

It does not write the database.

It does not start, stop, restart, reload, enable, or disable services.

It does not start or stop CTs or VMs.

It does not invoke any power, wake, boot, stop, shutdown, or worker-start endpoint.

It does not activate workers.

It does not activate schedulers.

It does not call Ollama endpoints.

It does not call model endpoints.

It does not run ollama list, ollama pull, ollama run, or ollama show.

It does not call /tick/ollama-direct.

## Existing endpoint surface to reuse

Stage 16-E1A found that the deployed controller already has a mature power surface.

Reuse these existing endpoints instead of inventing a new control surface:

- /power/wake-plan
- /power/execute-wake
- /power/start-worker-plan
- /power/execute-start-worker
- /power/wake-and-start-worker-plan
- /power/execute-wake-and-start-worker
- /power/idle/tick
- /power/proxmox/inventory
- /power/stop-plan
- /power/execute-stop-plan
- /power/host-shutdown-plan
- /power/execute-host-shutdown
- /power/auto/status
- /power/auto/tick
- /power/auto/pause
- /power/auto/resume
- /system/presence/power-policy
- /system/presence/apply-power-policy
- /system/pveso/boot

Legacy/simple endpoint:

- /wake-test

The legacy/simple endpoint should remain diagnostic-only unless separately reviewed.

## Existing protection model

The rediscovered code already separates plan endpoints from execution endpoints.

Planning endpoints should be safe to call in no-apply or dry-run contexts when they do not wake, stop, start, or shut down anything.

Execution endpoints must remain guarded by explicit environment flags and confirmation values.

Known protection concepts from rediscovery:

- EDGE_POWER_DRY_RUN defaults to dry-run behavior.
- EDGE_POWER_ALLOWED_STOP_TARGETS limits what can be stopped.
- EDGE_POWER_PROTECTED_TARGETS protects manual or critical targets.
- EDGE_POWER_EXECUTE_WAKE must be enabled before wake execution.
- EDGE_POWER_EXECUTE_STOPS must be enabled before stop execution.
- EDGE_POWER_EXECUTE_HOST_SHUTDOWN must be enabled before host shutdown execution.
- EDGE_PROXMOX_HOST_ID identifies the target host, defaulting to pveso.
- EDGE_PROXMOX_WAKE_MAC must be configured for Wake-on-LAN eligibility.
- EDGE_PROXMOX_WAKE_BROADCAST must be configured for Wake-on-LAN delivery.
- EDGE_PROXMOX_WAKE_PORT controls the Wake-on-LAN UDP port.
- execute-wake requires WAKE_PROXMOX_HOST confirmation.
- execute-stop-plan requires STOP_AUTO_MANAGED_TARGETS confirmation.
- execute-host-shutdown requires SHUTDOWN_PROXMOX_HOST confirmation.

## Target architecture

PVESO is intentionally offline by default.

PVESO is the main on-demand model worker host.

PVESO contains the llms container, Ollama runtime, and model assets.

PVEW remains the always-on platform host.

CT203 on PVEW remains controller, API, queue, and decision authority.

VM200 on PVEW remains public/static edge.

CT204 on PVEW remains stopped backup-data-only.

PVEW replica/helper worker comes later after PVESO primary worker path is proven.

## Controller policy

The controller should treat PVESO worker capacity as conditional capacity.

The queue must remain durable while PVESO is offline.

Users may submit jobs while PVESO is offline.

The decision maker should classify whether a job needs real model-worker capacity.

Power policy should wake PVESO only when a queued job needs PVESO-class model capacity.

Power policy must not execute a model job merely because PVESO woke.

Worker bridge activation and model execution remain separate gates.

## Recommended auto-power flow

### Read-only planning path

For dashboards, status, and decision preview:

1. /power/auto/status
2. /power/wake-plan
3. /power/proxmox/inventory
4. /power/idle/tick
5. /power/start-worker-plan
6. /power/wake-and-start-worker-plan
7. /power/stop-plan
8. /power/host-shutdown-plan

These should be treated as plan/dry-run endpoints unless code review proves otherwise.

### Manual wake readiness path

After explicit approval:

1. verify /power/wake-plan is eligible;
2. execute /power/execute-wake only with WAKE_PROXMOX_HOST confirmation;
3. wait for PVESO reachability;
4. inventory PVESO and llms container;
5. do not start worker processing;
6. do not call Ollama endpoint;
7. do not run a model job.

### Worker bridge preparation path

After separate explicit approval:

1. use /power/start-worker-plan or /power/wake-and-start-worker-plan as plan source;
2. prepare only default-off bridge wiring;
3. keep scheduler broad activation disabled;
4. keep one real model job blocked until Stage 16-D approval.

### Idle shutdown path

After separate explicit approval:

1. use /power/idle/tick to determine idle eligibility;
2. use /power/stop-plan to identify auto-managed targets only;
3. execute /power/execute-stop-plan only with STOP_AUTO_MANAGED_TARGETS confirmation and only when EDGE_POWER_EXECUTE_STOPS is enabled;
4. use /power/host-shutdown-plan only after protected/manual workloads are clear;
5. execute /power/execute-host-shutdown only with SHUTDOWN_PROXMOX_HOST confirmation and only when EDGE_POWER_EXECUTE_HOST_SHUTDOWN is enabled.

## State machine

PVESO power state should be modeled as:

- offline
- wake_requested
- booting
- host_online
- llms_container_start_needed
- llms_container_running
- worker_bridge_default_off
- worker_available
- busy
- idle_grace
- stop_targets_pending
- host_shutdown_eligible
- shutdown_requested
- error_manual_attention_required

## Stop conditions

Do not wake PVESO if:

- wake plan is not eligible;
- wake MAC is missing;
- wake broadcast is missing;
- wake execution flag is disabled;
- recent wake attempt is inside cooldown;
- manual pause is active;
- the job can be satisfied by always-on PVEW replica/helper capacity;
- no queued job requires real model execution.

Do not stop or shut down PVESO if:

- model jobs are running;
- PVESO-assigned jobs are queued;
- llms container is not safely idle;
- protected or manual workloads are running;
- host shutdown plan is not eligible;
- wake plan is not eligible as a recovery path;
- manual keep-awake override is active;
- shutdown execution flags are disabled.

## Required separate approval gates

Stage 16-E2 PVESO wake readiness inventory:

APPROVE_STAGE_16_E2_PVESO_WAKE_READINESS_INVENTORY_NO_WORKER_NO_MODEL_JOB

Stage 16-F PVESO llms worker bridge preparation:

APPROVE_STAGE_16_F_PVESO_LLMS_WORKER_BRIDGE_PREP_NO_MODEL_JOB_NO_SCHEDULER_BROAD_ACTIVATION

Stage 16-D one controlled queued model test:

APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST

Any host shutdown execution must require a later approval that explicitly includes SHUTDOWN_PROXMOX_HOST and states that protected/manual workloads are clear.

## Required next phase

Stage 16-E2 should wake PVESO for readiness inventory only after explicit approval.

Stage 16-E2 must not:

- activate model workers;
- activate scheduler broad dispatch;
- call Ollama endpoints;
- run ollama list, pull, run, or show;
- create DB jobs;
- run a model job;
- start PVEW replica/helper worker;
- start CT204;
- unlock private storage.

Stage 16-E2 should only prove:

- PVESO wakes;
- PVESO becomes reachable;
- Proxmox inventory is readable;
- llms container identity/status is known;
- existing Ollama/model assets can be located by filesystem or service metadata without endpoint/model calls;
- rollback/shutdown plan is known.
