# Phase 14J-GS - CT202 Controller Cutover Plan - NO APPLY

Date: 2026-06-17  
Phase: 14J-GS  
Scope: CT202 controller cutover plan only, no apply  
Previous checkpoint: Phase 14J-GR - CT202 readiness summary and cutover blocker review  
Previous commit: cb8cc3a  
Previous tag: controller-phase-14j-gr-ct202-readiness-summary-and-cutover-blocker-review-2026-06-17

## Result

Phase 14J-GS records the controller cutover plan boundaries and required decisions before any future CT202 authority change.

This phase does **not** execute cutover.

## New-chat baseline evidence

The Phase 14J-GS baseline was completed before this plan was recorded.

Verified baseline results:

- repo HEAD, origin/main, Phase 14J-GR tag, and clean state were verified;
- Phase 14J-GR smoke passed;
- laptop-local `edge_queue.sqlite3` quick_check returned `ok`;
- Tailscale SSH path to Proxmox with `pct` access was usable;
- CT202 was running for inspection only;
- CT202 onboot/autostart was `0`;
- CT202 `edge-queue-controller.service` was loaded, disabled, and inactive;
- CT202 unit contained no persistent public API key, token, password, secret, bearer, or auth URL pattern;
- CT202 had no guarded-port controller listeners on `7070`, `17070`, `17071`, or `17072`;
- CT202 had no Uvicorn controller process;
- CT202 SQLite quick_check returned `ok`;
- CT202 application table count was `25`;
- CT202 `jobs`, `workers`, `user_sessions`, and `router_logs` row counts were `0`.

## Current authority boundary

Live authority remains unchanged:

- laptop controller remains the live controller/queue authority;
- laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority;
- CT202 remains a private controller candidate only;
- CT202 is not authoritative;
- CT201 remains a private data/backups/future data-service candidate only;
- VM 200 `website-edge` remains public/static website edge only.

## Cutover blockers that remain unresolved

No future apply phase may proceed until these are resolved in writing and explicitly approved.

### 1. Data authority decision

A future phase must choose exactly one:

1. fresh-start CT202 authority cutover;
2. selective import from laptop DB to CT202 DB;
3. full migration from laptop DB to CT202 DB.

Required before any data authority mutation:

- backup plan;
- restore proof or rollback procedure;
- source and destination DB paths;
- table inclusion/exclusion list;
- row-count/hash validation plan;
- explicit approval.

### 2. Persistent secret/public API key policy

CT202 smokes used temporary in-process public API key behavior only.

A future phase must define:

- where persistent runtime secret material lives;
- owner and permissions;
- rotation procedure;
- validation method that does not print secrets;
- confirmation that secrets are not in ChatGPT, repo, Source files, or `APC_LAST_OUTPUT`.

### 3. Runtime activation/autostart policy

Current state remains:

- CT202 service disabled/inactive;
- CT202 onboot/autostart off;
- no controller listener/runtime active.

A future apply plan must define whether CT202 remains manual-only at first or becomes persistent, and must separate:

1. temporary manual start smoke;
2. persistent service start;
3. `systemctl enable`;
4. Proxmox onboot/autostart mutation.

Each step requires explicit approval when it becomes an apply action.

### 4. Public route cutover and rollback plan

No public route currently points to CT202 from this controller migration path.

A future plan must define:

- exact public hostname(s);
- exact current target;
- exact proposed CT202 target;
- validation checks;
- rollback target;
- rollback trigger conditions;
- expected downtime or no-downtime behavior;
- Cloudflare/dashboard/API boundary.

### 5. Laptop controller fallback plan

Before CT202 can become authoritative, a fallback plan must define:

- how the laptop controller remains available or recoverable;
- how public routes return to the laptop/controller path if CT202 fails;
- how DB authority is protected from divergence;
- how to avoid split-brain controller writes;
- how to prove CT202 is healthy before deprecating laptop authority.

### 6. Worker/model runtime remains out of scope

This phase does not touch:

- CT101;
- model/Ollama endpoints;
- worker starts;
- scheduler activation;
- production job mutation.

## Proposed later phase sequence

This is a planning sequence only.

### Phase 14J-GT - CT202 cutover design options, no apply

Compare fresh-start, selective import, and full migration options. Select a preferred path only after documenting tradeoffs.

### Phase 14J-GU - CT202 persistent secret policy, no apply

Define secret delivery, permissions, rotation, and validation without printing or storing secrets in unsafe locations.

### Phase 14J-GV - CT202 temporary runtime rehearsal, no enable

Manual start, loopback smoke, stop, disabled-state regression. No public route and no enable.

### Phase 14J-GW - data authority preflight, no import

Read-only source/destination DB inventory and backup validation. No migration/import.

### Phase 14J-GX - public route and rollback plan, no apply

Document exact route switch and rollback plan. No Cloudflare mutation.

### Phase 14J-GY or later - explicit cutover apply

Separate explicit approval only. Must include backup, runtime validation, route validation, rollback procedure, and post-cutover source refresh.

## Explicitly not performed in this phase

- no CT202 authority cutover;
- no CT202 data migration/import;
- no `systemctl start`;
- no `systemctl enable`;
- no `systemctl daemon-reload`;
- no CT202 onboot/autostart mutation;
- no persistent controller runtime activation;
- no public route mutation;
- no Cloudflare mutation;
- no laptop controller stop;
- no live laptop DB mutation;
- no CT101 call;
- no model/Ollama endpoint call;
- no worker start;
- no production DB/job mutation;
- no secret/token/password/public API key output;
- no rerun of the Phase 14J-AG apply wrapper;
- no destructive GitHub branch/repository deletion.

## Phase 14J-GS conclusion

CT202 is ready for further cutover planning, not cutover execution.

Next safe phase: Phase 14J-GT - CT202 cutover design options, no apply.
