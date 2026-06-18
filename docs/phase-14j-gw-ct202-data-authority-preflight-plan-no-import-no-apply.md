# Phase 14J-GW - CT202 Data Authority Preflight Plan - NO IMPORT / NO APPLY

Date: 2026-06-17  
Phase: 14J-GW  
Scope: CT202 data authority preflight plan only, no import, no apply  
Previous checkpoint: Phase 14J-GV - CT202 temporary runtime rehearsal plan no enable/no apply  
Previous commit: 0f02bcf  
Previous tag: controller-phase-14j-gv-ct202-temporary-runtime-rehearsal-plan-no-enable-no-apply-2026-06-17

## Result

Phase 14J-GW documents the future read-only preflight required before any CT202 data authority decision.

This phase does **not** export, copy, import, migrate, mutate, or reconcile any database.

This phase does **not** select fresh-start, selective import, or full migration for apply.

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

## Current known CT202 candidate data state

Last verified CT202 candidate state:

- CT202 DB path: `/srv/edge-controller/data/edge_queue.sqlite3`;
- SQLite quick_check returned `ok`;
- application table count was `25`;
- `jobs` row count was `0`;
- `workers` row count was `0`;
- `user_sessions` row count was `0`;
- `router_logs` row count was `0`.

## Data authority question

Before CT202 can become authoritative, a future phase must choose one data-authority path:

1. fresh-start CT202 authority;
2. selective import from laptop DB to CT202 DB;
3. full migration from laptop DB to CT202 DB.

Phase 14J-GW does not choose or approve an apply path.

## Future read-only preflight goals

A future read-only data preflight should collect enough evidence to choose between fresh-start, selective import, and full migration without changing either database.

Required future evidence:

- laptop DB path confirmation;
- CT202 DB path confirmation;
- laptop DB quick_check;
- CT202 DB quick_check;
- table list comparison;
- schema object count comparison;
- per-table row counts;
- identification of volatile runtime tables;
- identification of durable user/account/credit/configuration tables;
- identification of table dependencies and foreign-key risks;
- candidate import/exclude/defer table classification;
- backup/restore requirement list;
- rollback and split-brain prevention requirements.

## Future table classification policy

A future no-import data preflight should classify tables into these groups.

### Group A - likely durable/import candidates

Examples may include, if present and schema-compatible:

- users/accounts/profile tables;
- credit/wallet/ledger tables;
- configuration tables;
- stable routing metadata;
- durable admin settings.

### Group B - likely volatile/exclude candidates

Examples may include, if present:

- live jobs;
- live workers;
- user sessions;
- router logs;
- runtime status tables;
- heartbeat tables;
- transient queue state.

### Group C - decide-later candidates

Examples may include tables with mixed durable/runtime meaning or unresolved dependencies.

Each table must have a documented reason before any import is approved.

## Future backup and rollback policy

Before any future migration/import apply phase:

- laptop DB backup must exist;
- CT202 DB backup must exist;
- backup paths must not expose secrets;
- backup restore method must be documented;
- rollback path to laptop controller must be documented;
- split-brain prevention must be documented;
- public routes must remain unchanged until data and runtime are validated;
- laptop controller must not be stopped without explicit approval.

## Future validation policy

Future validation should avoid dumping data content.

Allowed future read-only evidence:

- table names;
- schema object counts;
- per-table row counts;
- safe schema hashes;
- safe aggregate hashes if they do not reveal sensitive content;
- quick_check results;
- file presence and permissions.

Avoid recording:

- user personal data;
- session contents;
- secret values;
- tokens;
- passwords;
- public API keys;
- raw auth headers;
- full SQL dumps in ChatGPT or Source files.

## Fresh-start decision requirements

Fresh-start can only be selected later if:

- starting CT202 with empty volatile state is acceptable;
- durable user/account/credit state is not required or can be safely recreated;
- route/runtime rollback to laptop is clear;
- laptop DB remains preserved;
- explicit approval is given.

## Selective-import decision requirements

Selective import can only be selected later if:

- import table list is approved;
- exclude table list is approved;
- dependencies are documented;
- source/destination schemas are compatible;
- dry-run against copies is planned;
- row-count/hash validation is planned;
- rollback is planned;
- explicit approval is given.

## Full-migration decision requirements

Full migration can only be selected later if:

- complete continuity is mandatory;
- freeze/split-brain prevention is planned;
- full backup/restore is proven;
- runtime-specific rows are reviewed;
- laptop controller stop or write-freeze is separately approved if needed;
- rollback is planned;
- explicit approval is given.

## Required next no-apply phase

Next safe phase: Phase 14J-GX - CT202 public route and rollback plan, no apply.

Reason:

- data authority preflight requirements are now documented;
- public routing and rollback still need exact planning before any controller cutover;
- route planning should remain no-apply and separate from Cloudflare mutation.

## Explicitly not performed in this phase

- no CT202 authority cutover;
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
- no laptop controller stop;
- no CT101 call;
- no model/Ollama endpoint call;
- no worker start;
- no production DB/job mutation;
- no rerun of the Phase 14J-AG apply wrapper;
- no destructive GitHub branch/repository deletion.

## Phase 14J-GW conclusion

CT202 data authority preflight is planned but not executed.

No database was exported, copied, imported, migrated, dumped, mutated, backed up, restored, or reconciled by this phase.

Next safe phase: Phase 14J-GX - CT202 public route and rollback plan, no apply.
