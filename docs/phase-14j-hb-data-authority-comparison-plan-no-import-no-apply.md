# Phase 14J-HB - Data authority comparison plan, no import/no apply

Date: 2026-06-17  
Type: no-apply planning / docs-smoke record  
Previous checkpoint: Phase 14J-HA at commit `ce886c5`

## Purpose

Record the safe plan for a future read-only data-authority comparison between:

- the laptop-local live controller DB, `edge_queue.sqlite3`;
- the CT202 local candidate DB, `/srv/edge-controller/data/edge_queue.sqlite3`.

This phase exists because Phase 14J-GZ and Phase 14J-HA confirmed that the CT202 cutover readiness gate remains closed and that the data authority path is still unresolved.

## Mutation boundary

This phase is docs/smoke only.

It does not perform:

- CT202 authority cutover;
- CT202 data migration or import;
- SQLite file copy;
- SQL dump;
- table data dump;
- backup creation;
- restore operation;
- live laptop DB mutation;
- CT202 DB mutation;
- `systemctl start`;
- `systemctl enable`;
- CT202 onboot/autostart mutation;
- public route mutation;
- Cloudflare, DNS, or tunnel mutation;
- laptop controller stop or pause;
- CT101 call;
- model/Ollama endpoint call;
- worker start;
- production DB/job mutation;
- secret generation, printing, or installation;
- destructive GitHub branch or repository deletion.

## Current authority facts from Phase 14J-HA

Phase 14J-HA confirmed:

- laptop controller remains the live controller/queue authority;
- laptop-local `edge_queue.sqlite3` remains the live primary controller platform data authority;
- laptop DB quick_check was `ok`;
- laptop application table count was `39`;
- laptop safe metadata counts were:
  - `jobs`: `22`;
  - `workers`: `2`;
  - `user_sessions`: `233`;
  - `router_logs`: `0`;
- CT202 remains private and non-authoritative;
- CT202 service is disabled/inactive;
- CT202 onboot/autostart is off;
- CT202 has no checked controller/smoke listener active;
- CT202 DB quick_check was `ok`;
- CT202 application table count was `25`;
- CT202 safe metadata counts were:
  - `jobs`: `0`;
  - `workers`: `0`;
  - `user_sessions`: `0`;
  - `router_logs`: `0`.

## Why a comparison is needed

The live laptop DB and CT202 candidate DB are not equivalent at the Phase 14J-HA checkpoint.

Known differences:

- laptop DB has live operational rows;
- CT202 DB is a fresh local candidate DB;
- laptop DB has more application tables than CT202;
- CT202 has no live job, worker, session, or router log rows in the checked tables.

A controller cutover cannot be considered until the project chooses one explicit data authority path.

## Candidate data authority paths

The future decision must choose exactly one path before any apply:

### Path 1 - Fresh-start CT202 authority

CT202 becomes authority with its fresh candidate DB.

Requirements:

- accept that live laptop controller state is not migrated;
- define what happens to active jobs, workers, sessions, credits, router logs, and audit history;
- ensure public/users are not depending on omitted state;
- prove rollback expectations before route mutation.

### Path 2 - Selective import

Only approved tables or records are copied into CT202.

Requirements:

- explicit table allowlist;
- explicit row-count expectations;
- backup before import;
- no secrets in dumps or logs;
- rollback and reconciliation plan;
- proof that skipped tables are safe to skip.

### Path 3 - Full migration

Laptop controller DB is migrated to CT202.

Requirements:

- backup before migration;
- quiesce or freeze production writes before final copy;
- verify schema and row counts;
- prevent split-brain writes;
- define rollback and reconciliation if CT202 accepts writes;
- avoid printing or storing data dumps in ChatGPT, `APC_LAST_OUTPUT`, repo, or Source.

## Future read-only comparison scope

A future read-only comparison phase may collect only safe structure and metadata:

- DB path existence;
- DB file size;
- SQLite quick_check;
- application table count;
- table name lists;
- schema SQL hashes;
- index/trigger/view counts;
- selected safe row counts;
- selected sequence values if applicable;
- migration/version table presence if applicable.

It must avoid:

- row content;
- user/session tokens;
- passwords;
- API keys;
- bearer tokens;
- auth URLs;
- SQL dumps;
- table data dumps;
- full DB file copies;
- secrets in terminal output;
- secrets in ChatGPT;
- secrets in `APC_LAST_OUTPUT`;
- secrets in repo or Source.

## Proposed future read-only comparison output

The future comparison should report only sanitized summaries such as:

- `laptop_db_quick_check=ok`;
- `ct202_db_quick_check=ok`;
- `laptop_app_table_count=<number>`;
- `ct202_app_table_count=<number>`;
- `tables_only_on_laptop=<count>`;
- `tables_only_on_ct202=<count>`;
- `tables_on_both=<count>`;
- `schema_hash_laptop=<safe-hash>`;
- `schema_hash_ct202=<safe-hash>`;
- `schema_hash_match=yes/no`;
- safe row counts for explicitly approved tables.

The output should not include raw table row data.

## Future explicit approval phrase

Before running the future read-only comparison, use an explicit approval phrase similar to:

`APPROVE_PHASE_14J_HC_READ_ONLY_DATA_AUTHORITY_PREFLIGHT_NO_IMPORT_NO_APPLY`

That future phase must still be read-only and must not migrate, import, copy, dump, or mutate data.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not select a data authority path.

This phase does not open the cutover gate.

## Recommended next safe step

After Phase 14J-HB, the next safe step is either:

1. run a future read-only data-authority preflight only after the explicit no-import/no-apply approval phrase; or
2. continue no-apply planning for temporary runtime rehearsal, rollback drill, or split-brain prevention.

