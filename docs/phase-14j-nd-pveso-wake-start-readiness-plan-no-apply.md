# Phase 14J-ND — PVESO Wake/Start Readiness Plan No-Apply

Updated: 2026-06-18

## Status

NO-APPLY PLAN ONLY.

This phase does not wake PVESO, start PVESO, SSH to PVESO, ping PVESO, send Wake-on-LAN, start workers, activate models, call model endpoints, enable scheduler dispatch, enable worker lanes/filters, start or stop CTs/VMs, restart services, unlock private storage, mount private storage, create backups, restore databases, change CT204 authority, change Cloudflare/DNS/tunnels, or print secrets/env contents.

## Baseline carried forward

Latest completed checkpoint before this plan:

- Phase: 14J-NC-R2 — Worker/Model Inventory Record Read-Only
- Commit: 474f41e
- Tag: controller-phase-14j-nc-r2-worker-model-inventory-record-read-only-2026-06-18
- Result: PASS_PHASE_14J_NC_R2_WORKER_MODEL_INVENTORY_RECORD_READ_ONLY_COMMIT_TAG_PUSH_DONE

Current known platform posture:

- CT203 is running and remains controller/API/queue authority.
- CT203 `edge-queue-controller.service` is active/enabled.
- VM200 is running and public/static only.
- CT204 is stopped, backup-data-only, and `data_authority=false`.
- PVEW private storage is locked/unmounted.
- `/dev/mapper/apc_private_data` is closed/absent.
- PVESO remains parked/offline unless explicitly approved.
- Worker/model runtime activation remains parked.
- Public `/system/status` remains HTTP 200 and online.
- Public node topology remains `ct-203,ct-204,pvew,vm-200`.

## Inventory carried forward from 14J-NC-R2

CT203 SQLite inventory:

- SQLite integrity: ok
- SQLite table count: 40
- worker/queue/model-related tables: `job_results,jobs,worker_events,workers`
- `workers` rows: 2
- `jobs` rows: 22
- `worker_events` rows: 3
- `job_results` rows: 6

Worker inventory:

- workers status counts: `offline:2`
- workers health counts: `offline:2`
- workers lane counts: `primary:1,study:1`
- workers accepts-lane-jobs counts: `0:1,1:1`

Jobs inventory:

- jobs status counts: `failed:1,forwarded:20,queued:1`
- jobs type counts: `ollama_chat:22`

Interpretation:

- Worker rows exist.
- Lane metadata exists.
- No worker is currently available.
- At least one queued `ollama_chat` job exists.
- This does not approve worker activation, model calls, or real user traffic routing.

## Purpose

Define the future safe boundary for waking or starting PVESO only far enough to inspect compute readiness for worker/model re-entry.

PVESO must remain a compute/model/worker host only. It must not become public authority, DB authority, controller authority, or CT204 data authority.

## Future apply phase

Suggested future phase:

- Phase 14J-NE — Wake PVESO for Worker/Model Readiness Apply

Suggested approval phrase:

`APPROVE_PHASE_14J_NE_WAKE_PVESO_FOR_WORKER_MODEL_READINESS_NO_WORKER_ACTIVATION`

This approval should allow only PVESO wake/start/readiness checks. It should not allow worker activation, model endpoint calls, scheduler dispatch, lane filter activation, real user traffic, private storage reopen, CT204 start, backup creation, DB mutation, or public route changes.

## Future apply allowed actions after approval

Only after explicit approval, a future PVESO readiness apply phase may:

1. Verify repo is clean at the expected checkpoint.
2. Verify public `/system/status` remains HTTP 200 and online.
3. Verify public node topology remains `ct-203,ct-204,pvew,vm-200`.
4. Verify CT203 remains controller/API/queue authority.
5. Verify CT203 service is active/enabled.
6. Verify VM200 remains running and public/static only.
7. Verify CT204 remains stopped and non-authoritative.
8. Verify private storage remains locked unless a separate reopen approval was granted.
9. Wake or start PVESO using the existing approved host power path.
10. Wait for PVESO reachability through the approved private/admin path.
11. Verify PVESO host identity and basic health.
12. Verify compute services are not automatically activated unless already configured safe and documented.
13. Verify no worker is registered as newly available unless a separate worker activation approval was granted.
14. Verify no model endpoint call occurred.
15. Verify no scheduler dispatch activation occurred.
16. Record sanitized readiness evidence.

## Future apply forbidden actions even after approval

The PVESO wake/start readiness apply phase must not:

- start or enable worker services;
- start or enable model-serving services unless that is already part of PVESO boot and documented as passive;
- call Ollama/model endpoints;
- create synthetic jobs;
- dispatch queued jobs;
- route real user traffic to models/workers;
- enable scheduler production dispatch;
- enable persistent lane filters;
- mutate CT203 DB schema or data;
- start CT204;
- promote CT204 to data authority;
- unlock or mount private storage;
- create backups;
- restore or import databases;
- change Cloudflare, DNS, tunnels, or public routes;
- print secrets, env contents, tokens, auth URLs, private IPs, Tailscale IPs, or MAC addresses.

## Required public preflight before future PVESO wake/start

The future apply must verify:

- public `/system/status` HTTP 200;
- `overall_state=online`;
- `normalized.schema_version=2`;
- node IDs sorted `ct-203,ct-204,pvew,vm-200`;
- public private storage policy `manual-unlock-only`;
- public private storage mount state `unknown`;
- public private storage mountpoint `/srv/apc-private-data`;
- CT204 expected state `stopped`;
- CT204 `data_authority=false`;
- public app hash unchanged unless a separate deploy occurred;
- public app legacy hits absent.

## Required PVEW/CT203 preflight before future PVESO wake/start

The future apply must verify on PVEW/CT203:

- CT203 status is running;
- CT203 `edge-queue-controller.service` is active/enabled;
- CT203 DB path remains `/var/lib/edge-queue-controller/edge_queue.sqlite3`;
- CT203 DB integrity is ok if inspected read-only;
- VM200 status is running;
- CT204 status is stopped;
- private storage host mount state is not mounted unless a separate reopen approval exists;
- private storage mapper is absent unless a separate reopen approval exists;
- private storage crypt status is inactive unless a separate reopen approval exists.

## Future PVESO readiness checks

After approved PVESO wake/start, readiness evidence should include:

- PVESO reachable through approved admin/private path;
- host identity confirmed without printing private IPs;
- uptime or boot timestamp;
- basic CPU/RAM availability;
- GPU presence if safely inspectable;
- model/worker service states inspected without starting/restarting them;
- no model endpoint call;
- no worker heartbeat activation unless separately approved;
- no scheduler dispatch activation.

## Abort blockers

Abort future PVESO wake/start before mutation if any of these are true:

- approval phrase missing or stale;
- repo not clean at expected checkpoint;
- public status not HTTP 200;
- public overall state not online;
- public topology not `ct-203,ct-204,pvew,vm-200`;
- CT203 not running;
- CT203 service not active/enabled;
- VM200 not running;
- CT204 not stopped;
- CT204 is data authority;
- private storage state is unexpected;
- the phase would start workers;
- the phase would call model endpoints;
- the phase would dispatch jobs;
- the phase would route real user traffic;
- the phase would print secrets or private network details;
- the phase would change Cloudflare/DNS/tunnels.

## Expected next phases

After this plan, safe future sequencing is:

1. Phase 14J-NE — approved PVESO wake/start readiness apply.
2. Phase 14J-NF — worker/model readiness read-only after PVESO is online.
3. Phase 14J-NG — guarded single-worker activation plan no-apply.
4. Phase 14J-NH — approved one-worker activation, no public model traffic.
5. Phase 14J-NI — model endpoint smoke plan no-apply.
6. Phase 14J-NJ — approved one model endpoint smoke, no public traffic.
7. Phase 14J-NK — scheduler dispatch re-entry plan no-apply.
8. Phase 14J-NL — approved one synthetic queue job, no real user traffic.

## Result

This phase creates the PVESO wake/start readiness no-apply plan only.

RESULT=PASS_PHASE_14J_ND_PVESO_WAKE_START_READINESS_PLAN_NO_APPLY_DOC_READY
