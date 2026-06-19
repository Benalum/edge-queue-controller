# Phase 14J-NB — Worker/Model Re-entry Procedure Plan No-Apply

Updated: 2026-06-18

## Status

NO-APPLY PLAN ONLY.

This phase does not wake PVESO, start PVESO, start workers, activate models, call model endpoints, enable scheduler dispatch, enable worker lanes, restart services, start or stop CTs/VMs, unlock private storage, mount private storage, create backups, restore databases, change Cloudflare/DNS/tunnels, or mutate production data.

## Current baseline carried forward

Latest completed checkpoint before this plan:

- Phase: 14J-MZ — CT204 Isolated Restore-Drill Procedure Plan No-Apply
- Commit: faf7e78
- Tag: controller-phase-14j-mz-ct204-isolated-restore-drill-procedure-plan-no-apply-2026-06-18
- Result: PASS_PHASE_14J_MZ_CT204_ISOLATED_RESTORE_DRILL_PROCEDURE_PLAN_NO_APPLY_COMMIT_TAG_PUSH_DONE

Current platform state carried forward:

- CT203 remains controller/API/queue authority.
- CT203 `edge-queue-controller.service` remains active/enabled.
- VM200 remains running and public/static only.
- CT204 remains stopped, backup-data-only, and `data_authority=false`.
- PVEW private storage is locked/unmounted.
- `/dev/mapper/apc_private_data` is closed/absent.
- PVESO remains parked/offline unless explicitly approved.
- Worker/model runtime activation remains parked.
- Public `/system/status` remains the public-safe contract authority.

## Purpose

Define the safe future path for worker/model runtime re-entry after the PVEW controller migration, VM200 static frontend cleanup, CT203 backup verification, and private storage lock work.

This is a planning phase only. It prepares the approval boundaries and abort gates for later runtime work.

## Current runtime principle

Users must continue to flow through:

Frontend → Backend/API → Queue → Scheduler/Worker → Model

Users must not talk to models directly.

CT203 remains the controller/API/queue authority.

PVESO and any model/worker nodes remain compute/runtime resources only, not public authority and not DB authority.

## Future re-entry sequence

A safe worker/model re-entry should be split into explicit phases:

### Phase 14J-NC — Worker/model inventory read-only

Read-only only.

Allowed:

- inspect repo worker configuration;
- inspect CT203 queue/controller config;
- inspect public status;
- inspect known worker registry state from CT203 without mutation;
- inspect PVESO reachability only if already online, but do not wake it;
- inspect documented model/worker plan.

Forbidden:

- PVESO wake/start;
- worker start;
- model endpoint call;
- scheduler mutation;
- DB mutation;
- service restart/reload.

### Phase 14J-ND — PVESO wake/start plan no-apply

Planning only.

Purpose:

- define how PVESO may be woken/started later;
- define how to verify compute host readiness;
- define how to abort if PVESO is unexpectedly unavailable or unsafe;
- define how to keep PVESO out of public authority.

### Phase 14J-NE — PVESO wake/start apply

Requires explicit approval.

Suggested approval phrase:

`APPROVE_PHASE_14J_NE_WAKE_PVESO_FOR_WORKER_MODEL_READINESS_NO_WORKER_ACTIVATION`

Allowed only after approval:

- wake/start PVESO;
- verify host is reachable;
- verify no public route or authority changes;
- no worker/model activation yet.

### Phase 14J-NF — worker/model readiness read-only

Read-only only after PVESO is online.

Allowed:

- inspect model service/container/service status;
- inspect worker service files/configs;
- inspect model inventory without calling model inference;
- inspect GPU/CPU availability;
- verify no scheduler dispatch activation.

Forbidden:

- model inference call;
- worker service start;
- scheduler change;
- lane/filter activation.

### Phase 14J-NG — guarded single-worker activation plan no-apply

Planning only.

Define:

- one worker;
- one lane or one test queue;
- no public production traffic by default;
- hard stop/rollback commands;
- health checks;
- heartbeat expectations;
- no model call unless separately approved.

### Phase 14J-NH — guarded single-worker activation apply

Requires explicit approval.

Suggested approval phrase:

`APPROVE_PHASE_14J_NH_ENABLE_ONE_GUARDED_WORKER_NO_PUBLIC_MODEL_TRAFFIC`

Allowed only after approval:

- enable/start one clearly named worker/service;
- no scheduler production dispatch unless separately approved;
- verify heartbeat/registry only;
- keep production public traffic disabled.

### Phase 14J-NI — model endpoint smoke plan no-apply

Planning only.

Define one minimal model endpoint smoke, expected response shape, timeout, and abort/stop path.

### Phase 14J-NJ — model endpoint smoke apply

Requires explicit approval.

Suggested approval phrase:

`APPROVE_PHASE_14J_NJ_ONE_MODEL_ENDPOINT_SMOKE_NO_PUBLIC_TRAFFIC`

Allowed only after approval:

- one minimal model endpoint call;
- no user data;
- no production dispatch;
- record sanitized output.

### Phase 14J-NK — scheduler dispatch re-entry plan no-apply

Planning only.

Define:

- one controlled queue lane;
- one synthetic test job;
- no real user traffic;
- rollback/disable steps;
- no public promise of availability.

### Phase 14J-NL — synthetic queued job apply

Requires explicit approval.

Suggested approval phrase:

`APPROVE_PHASE_14J_NL_ONE_SYNTHETIC_QUEUE_JOB_NO_REAL_USER_TRAFFIC`

Allowed only after approval:

- one synthetic queued job;
- one worker;
- one model endpoint;
- full audit trail;
- no real user traffic.

## Required public baseline before any future worker/model apply

Every future apply phase must verify:

- public `/system/status` HTTP 200;
- `overall_state=online`;
- `normalized.schema_version=2`;
- node IDs sorted `ct-203,ct-204,pvew,vm-200`;
- VM200 public app hash remains expected unless a separate deploy occurred;
- public app legacy hits remain absent;
- CT203 remains authority;
- CT204 remains stopped/non-authority;
- private storage public policy remains `manual-unlock-only`;
- private storage public `mount_state=unknown`.

## Required PVEW/CT203 baseline before any future worker/model apply

Every future apply phase must verify:

- CT203 is running;
- CT203 `edge-queue-controller.service` is active/enabled;
- CT203 DB path remains `/var/lib/edge-queue-controller/edge_queue.sqlite3`;
- VM200 is running;
- CT204 is stopped unless a separate CT204 phase approved otherwise;
- no CT204 data authority promotion occurred;
- private storage remains locked unless a separate reopen phase approved otherwise;
- PVESO is not touched unless the phase explicitly approves PVESO wake/start.

## Hard forbidden actions without separate approval

No future worker/model re-entry phase may implicitly:

- wake or start PVESO;
- start or enable worker services;
- call model endpoints;
- enable production scheduler dispatch;
- enable persistent worker lane filters;
- route real user traffic to workers/models;
- mutate CT203 DB schema or data;
- restore/import DB data;
- start CT204;
- promote CT204 to data authority;
- unlock or mount private storage;
- change Cloudflare/DNS/tunnels;
- restart/reload CT203 or VM200 services.

## Worker/model re-entry abort blockers

Abort future apply before mutation if any of these are true:

- approval phrase is missing or stale;
- repo is not clean at the expected checkpoint;
- public status is not HTTP 200;
- public overall state is not online;
- public topology is not `ct-203,ct-204,pvew,vm-200`;
- CT203 is not running;
- CT203 service is not active/enabled;
- VM200 is not running;
- CT204 is not stopped;
- CT204 is data authority;
- storage state is not what the phase expects;
- PVESO state is unexpected;
- the phase would touch real user traffic without explicit approval;
- the phase would print secrets, env contents, auth URLs, private IPs, Tailscale IPs, or MAC addresses.

## Result

This phase creates the no-apply worker/model re-entry procedure plan only.

RESULT=PASS_PHASE_14J_NB_WORKER_MODEL_REENTRY_PROCEDURE_PLAN_NO_APPLY_DOC_READY
