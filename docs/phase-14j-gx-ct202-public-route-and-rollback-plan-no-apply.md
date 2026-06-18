# Phase 14J-GX - CT202 Public Route and Rollback Plan - NO APPLY

Date: 2026-06-17  
Phase: 14J-GX  
Scope: CT202 public route and rollback planning only, no apply  
Previous checkpoint: Phase 14J-GW - CT202 data authority preflight plan no import/no apply  
Previous commit: 18a98fe  
Previous tag: controller-phase-14j-gw-ct202-data-authority-preflight-plan-no-import-no-apply-2026-06-17

## Result

Phase 14J-GX documents the future public route and rollback plan required before any CT202 controller cutover.

This phase does **not** mutate Cloudflare, DNS, tunnels, public routes, CT202, systemd, laptop controller, or any database.

This phase does **not** approve CT202 public routing.

## Current unchanged authority boundary

Live authority remains unchanged:

- laptop controller remains the live controller/queue authority;
- laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority;
- CT202 remains a private controller candidate only;
- CT202 is not authoritative;
- CT202 service remains disabled/inactive;
- CT202 onboot/autostart remains off;
- no CT202 controller listener/runtime should be active;
- CT201 remains private data/backups/future data-service candidate only;
- VM 200 `website-edge` remains public/static website edge only.

## Current public edge boundary

Current public website edge boundary remains:

- VM 200 `website-edge` is the public/static website edge role only;
- website-edge must not host controller/queue/worker/model authority;
- website-edge must not expose Proxmox management;
- website-edge must not expose direct model endpoints;
- website-edge must not become DB authority.

CT202 remains private and must not be exposed publicly until a later explicit route apply phase.

## Required future route plan inputs

Before any route apply phase, the following must be written and approved:

1. exact public hostname or hostname set;
2. exact current public route target;
3. exact proposed CT202 route target;
4. exact rollback target;
5. expected Cloudflare/tunnel/dashboard/API boundary;
6. public health-check URL or route;
7. private CT202 loopback health-check route;
8. expected success response;
9. expected failure response;
10. validation timeout;
11. rollback trigger conditions;
12. post-rollback validation;
13. explicit approval phrase.

No future route plan may use Source files alone as approval.

## Required future CT202 readiness before route apply

Before any public route can point to CT202, a future phase must prove:

- CT202 data authority path has been selected and approved;
- CT202 runtime secret/public API key delivery has been applied safely if required;
- CT202 service runtime has passed private rehearsal;
- CT202 service activation policy has been approved;
- CT202 public/auth route contract is known;
- CT202 rollback target is available;
- laptop controller fallback is preserved;
- no split-brain controller writes are possible.

## Public route cutover strategy

A future route apply phase should be split into small stages:

### Stage 1 - preflight only

- verify repo clean state;
- verify current approved checkpoint;
- verify CT202 service state;
- verify laptop fallback state;
- verify current public route target;
- verify rollback target;
- verify no public route points to CT202 before cutover.

### Stage 2 - CT202 private readiness

- verify CT202 private runtime is healthy;
- verify required auth/secret policy without printing values;
- verify DB authority state;
- verify route target readiness privately;
- verify rollback remains available.

### Stage 3 - public route switch

This stage must be separate and explicitly approved.

It must include:

- exact hostname;
- exact target;
- exact command or dashboard steps;
- exact validation;
- exact rollback command or dashboard steps.

### Stage 4 - post-cutover validation

Validation must prove:

- public route reaches intended CT202-backed path;
- auth/session behavior is expected;
- controller status endpoint is healthy;
- no Proxmox management surface is exposed;
- no model/Ollama/worker endpoint is exposed;
- laptop fallback remains available until decommission is separately approved.

### Stage 5 - rollback if needed

Rollback must be ready before route switch.

Rollback must return public traffic to the approved previous target and then verify:

- public route responds from rollback target;
- CT202 is no longer receiving public traffic;
- CT202 can be stopped or left private according to the approved runtime plan;
- laptop controller remains or resumes authority;
- no data divergence or split-brain has occurred.

## Rollback trigger conditions

A future apply phase should rollback immediately if any of these occur:

- public health check fails;
- auth/session route fails unexpectedly;
- CT202 runtime becomes unhealthy;
- CT202 DB integrity check fails;
- route points to the wrong target;
- any secret appears in output;
- Proxmox management appears reachable from public traffic;
- model/Ollama/worker endpoint appears reachable from public traffic;
- laptop fallback is lost before CT202 is proven;
- unexpected write activity occurs against the wrong DB authority.

## Required future public safety checks

A future public route apply phase must confirm:

- no public Proxmox management exposure;
- no public CT201 exposure;
- no public CT101 exposure unless separately approved;
- no public model/Ollama exposure;
- no public worker control exposure;
- no public DB exposure;
- no raw internal IP or auth URL output;
- no secret/token/password/public API key output.

## Cloudflare boundary

A future Cloudflare or route mutation must not happen from this phase.

Before any future Cloudflare mutation:

- exact target must be documented;
- rollback target must be documented;
- route owner must be clear;
- validation must be documented;
- rollback must be documented;
- approval must be explicit;
- no broad/global Cloudflare API key should be used.

## Laptop fallback requirements

Before public route apply, laptop fallback must define:

- whether the laptop controller remains running;
- whether laptop DB remains writable;
- how CT202 and laptop avoid split-brain writes;
- how public traffic returns to laptop/controller path;
- how to verify laptop route after rollback;
- who has authority if rollback occurs mid-request;
- how to handle any in-flight queue jobs.

## Explicitly not performed in this phase

- no CT202 authority cutover;
- no CT202 public route approval;
- no CT202 data migration/import;
- no laptop DB export/import;
- no SQLite copy;
- no SQL dump;
- no table data dump;
- no live DB mutation;
- no backup creation;
- no restore operation;
- no secret generation;
- no secret printing;
- no secret file creation;
- no environment file creation;
- no systemd unit mutation;
- no `systemctl start`;
- no `systemctl enable`;
- no `systemctl daemon-reload`;
- no CT202 onboot/autostart mutation;
- no persistent controller runtime activation;
- no public route mutation;
- no Cloudflare mutation;
- no DNS mutation;
- no tunnel mutation;
- no laptop controller stop;
- no CT101 call;
- no model/Ollama endpoint call;
- no worker start;
- no production DB/job mutation;
- no rerun of the Phase 14J-AG apply wrapper;
- no destructive GitHub branch/repository deletion.

## Required next no-apply phase

Next safe phase: Phase 14J-GY - CT202 laptop fallback and split-brain prevention plan, no apply.

Reason:

- public route and rollback requirements are now documented;
- laptop fallback and split-brain prevention must be explicit before any cutover apply can be considered;
- controller authority cannot move safely until fallback and write-authority behavior are resolved.

## Phase 14J-GX conclusion

CT202 public route and rollback planning is documented but not applied.

No route, Cloudflare, DNS, tunnel, runtime, database, or authority mutation was performed by this phase.

Next safe phase: Phase 14J-GY - CT202 laptop fallback and split-brain prevention plan, no apply.
