# Phase 14J-GT - CT202 Cutover Design Options - NO APPLY

Date: 2026-06-17  
Phase: 14J-GT  
Scope: CT202 controller cutover design options only, no apply  
Previous checkpoint: Phase 14J-GS - CT202 controller cutover plan no apply  
Previous commit: 764c023  
Previous tag: controller-phase-14j-gs-ct202-controller-cutover-plan-no-apply-2026-06-17

## Result

Phase 14J-GT documents the available data-authority design options for a future CT202 controller cutover.

This phase does **not** select, approve, or execute a cutover.

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

## Design option A - Fresh-start CT202 authority cutover

### Summary

CT202 becomes controller authority with its existing fresh local DB.

Current known CT202 candidate DB state:

- DB path: `/srv/edge-controller/data/edge_queue.sqlite3`;
- SQLite quick_check passed at last baseline;
- application table count was `25`;
- `jobs`, `workers`, `user_sessions`, and `router_logs` row counts were `0`.

### Benefits

- simplest data path;
- lowest migration complexity;
- lowest risk of copying stale/bad live rows;
- easiest rollback because laptop DB stays untouched;
- avoids mixed authority during first CT202 runtime proof.

### Costs

- live controller history is not carried forward;
- active sessions/jobs/workers/router logs start empty on CT202;
- users may need fresh sessions depending on auth/session design;
- any required admin/account/credit state must be recreated or separately imported if needed.

### Required preflight before any apply

- confirm which tables are safe to start empty;
- confirm user/account/session impact;
- confirm credit/account data source requirements;
- confirm laptop DB backup exists before route/runtime changes;
- define exact rollback path to laptop controller;
- define post-cutover validation.

### Fresh-start apply posture

Fresh-start is the safest first authority model **only if** losing or recreating live volatile controller state is acceptable.

It should still require explicit cutover approval.

## Design option B - Selective import from laptop DB to CT202 DB

### Summary

A future phase imports only selected required tables from the laptop-local live DB into CT202 before authority cutover.

Possible import categories:

- account/user profile data;
- credit/wallet tables;
- configuration tables;
- stable metadata;
- possibly auth/session tables if intentionally preserved.

Tables likely to exclude unless explicitly justified:

- live `jobs`;
- live `workers`;
- volatile `user_sessions`;
- `router_logs`;
- transient runtime/status tables.

### Benefits

- preserves important durable user/account state;
- avoids copying volatile runtime state;
- lowers split-brain and stale-worker risk compared with full migration;
- offers a controlled middle path.

### Costs

- requires table-by-table import policy;
- requires row-count and hash validation;
- requires schema compatibility proof;
- requires backup and rollback;
- still risks partial-state mistakes if table dependencies are missed.

### Required preflight before any apply

- read-only table inventory from laptop DB and CT202 DB;
- classify each table as import, exclude, or decide-later;
- identify foreign-key/dependency constraints;
- backup laptop DB and CT202 DB;
- create dry-run import plan against copies only;
- define exact validation queries;
- define rollback plan;
- explicit approval before touching CT202 live candidate DB.

### Selective-import apply posture

Selective import is likely the best eventual production path **if durable user/account/credit state must survive cutover** while avoiding volatile queue/worker/session migration.

It must not be executed until a written table policy exists.

## Design option C - Full migration from laptop DB to CT202 DB

### Summary

A future phase copies the full laptop-local controller DB into CT202 before authority cutover.

### Benefits

- most complete state preservation;
- simplest conceptual parity if schema and runtime behavior are identical;
- may preserve historical logs and all metadata.

### Costs

- highest risk of copying stale volatile state;
- highest split-brain risk if laptop remains live during or after copy;
- requires stronger downtime/freeze window;
- requires full backup/restore proof;
- requires careful handling of jobs/workers/sessions/router logs;
- may carry laptop-specific runtime assumptions into CT202.

### Required preflight before any apply

- stop/freeze write activity plan, without stopping laptop controller until explicitly approved;
- laptop DB backup;
- CT202 DB backup;
- copy-to-staging rehearsal;
- full schema comparison;
- table row counts and hashes;
- runtime identity/host-specific data review;
- rollback plan;
- clear split-brain prevention strategy.

### Full-migration apply posture

Full migration should be treated as highest-risk and should not be the first apply path unless there is a strong requirement to preserve all controller state.

## Recommended design direction

Phase 14J-GT does not choose an apply path, but records this planning recommendation:

1. Prefer **selective import** if durable user/account/credit state must survive CT202 authority cutover.
2. Prefer **fresh-start** if CT202 can safely begin with empty volatile controller state and required durable state can be recreated or is not needed yet.
3. Avoid **full migration** unless complete state continuity is mandatory and a freeze/rollback plan is approved.

## Required next no-apply phase

Next safe phase: Phase 14J-GU - CT202 persistent secret/public API key policy, no apply.

Reason:

- data option selection depends partly on runtime/auth behavior;
- CT202 persistent runtime cannot be safely rehearsed or promoted without a secret delivery policy;
- CT202 unit currently intentionally contains no persistent public API key, token, password, secret, bearer, or auth URL.

## Explicitly not performed in this phase

- no CT202 authority cutover;
- no CT202 data migration/import;
- no laptop DB export/import;
- no SQLite copy;
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

## Phase 14J-GT conclusion

CT202 cutover design has three viable authority-data options:

1. fresh-start;
2. selective import;
3. full migration.

No option is approved for apply by this phase.

Next safe phase: Phase 14J-GU - CT202 persistent secret/public API key policy, no apply.
