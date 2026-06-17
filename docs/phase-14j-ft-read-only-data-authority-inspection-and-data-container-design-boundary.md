# Phase 14J-FT - Data authority inspection and data container design boundary

PHASE_14J_FT_READ_ONLY_DATA_AUTHORITY_INSPECTION_AND_DATA_CONTAINER_DESIGN_BOUNDARY

## Status

Result: data_authority_inspection_recorded_no_container_creation.

This phase records the read-only data authority inspection performed before designing a data container or VM.

This phase does not create containers, migrate data, move controller/queue, restart or reload services, start workers, call CT101, call model endpoints, mutate Cloudflare routes, mutate production DB/jobs, or rerun the Phase 14J-AG apply wrapper.

## Starting checkpoint

Previous repo checkpoint:

- Phase: 14J-FS - post-website-cutover validation and laptop migration inventory
- Commit: 5ab874e
- Tag: controller-phase-14j-fs-post-website-cutover-validation-and-laptop-migration-inventory-2026-06-17
- Repo state at FT-R1 start: clean/current

## FT-R1 read-only result

Phase 14J-FT-R1 completed with exit code 0.

Validated:

- repo clean/current at commit 5ab874e;
- Phase 14J-FS focused smoke regression passed;
- no container creation occurred;
- no data migration occurred;
- no controller/queue migration occurred;
- no service restart or reload occurred;
- no worker start occurred;
- no CT101 call occurred;
- no model/Ollama endpoint call occurred;
- no user table row dumps occurred.

## Controller runtime ownership

Observed controller service facts:

- `edge-queue-controller.service` is active and enabled.
- It runs the repo virtualenv Python.
- It serves `edge_controller:app` through uvicorn.
- It uses port 7070.
- It runs from `~/Desktop/edge-queue-controller`.
- It runs as the laptop user.
- It uses `/etc/edge-queue-controller/public-api.env` as an environment file.
- Environment values were redacted.

Interpretation:

- The laptop still owns the live controller/queue runtime.
- The controller service is still tied to the repo working directory.
- A future controller/queue container requires a separate service packaging and environment-file migration design.

## SQLite authority evidence

Observed code/runtime facts:

- `edge_controller.py` imports `sqlite3`.
- `edge_controller.py` defines `DB_PATH = Path("edge_queue.sqlite3")`.
- `edge_controller.py` repeatedly opens SQLite connections using `DB_PATH`.
- The live controller Python process had multiple open file handles to `edge_queue.sqlite3`.
- `edge_queue.sqlite3` exists, is readable, and passed SQLite quick_check.
- `edge_queue.sqlite3` size was approximately 42 MB.
- SQLite table count: 39.
- SQLite index count: 18.

Observed SQLite tables include:

- app/user/auth/session tables:
  - `app_users`;
  - `user_sessions`;
  - `pending_email_signups`;
  - `password_reset_tokens`;
  - `app_user_preferences`;
- credits/reward/billing-adjacent tables:
  - `user_credit_ledger`;
  - `credit_reservations`;
  - `ad_reward_events`;
  - `gpu_session_quotes`;
  - `gpu_sessions`;
  - `user_usage_limits`;
- queue/worker/model-control tables:
  - `jobs`;
  - `job_results`;
  - `workers`;
  - `worker_events`;
- study tables:
  - `study_decks`;
  - `study_cards`;
  - `study_reviews`;
  - `study_sessions`;
  - `study_session_events`;
  - `study_user_totals`;
  - `study_deck_totals`;
- router/language tables:
  - `intent_definitions`;
  - `intent_routes`;
  - `global_phrase_bank`;
  - `user_phrase_bank`;
  - `user_language_preferences`;
  - `user_secondary_languages`;
  - `router_logs`;
  - `router_resolution_steps`;
  - `router_feedback`;
- public/system/power/support tables:
  - `web_presence`;
  - `web_power_policy_events`;
  - `power_events`;
  - `power_auto_state`;
  - `power_idle_state`;
  - `support_tickets`;
  - `support_messages`;
  - `calendar_events`.

Interpretation:

PHASE_14J_FT_SQLITE_AUTHORITY=live_primary_controller_platform_data_authority

SQLite is currently authoritative for controller/platform state until a later phase proves otherwise.

## PostgreSQL evidence and boundary

Observed PostgreSQL facts:

- PostgreSQL 16 cluster is online on the laptop.
- `psql` is available.
- Noninteractive sudo access to inspect PostgreSQL as postgres was not available in FT-R1.
- Existing backup docs state backups must exist before laptop database becomes source of truth.
- Existing backup docs state the laptop/controller runtime still uses `edge_queue.sqlite3`.
- Existing Postgres backup and restore tooling exists:
  - `docs/laptop-postgres-backup-restore.md`;
  - `ops/db/backup-laptop-postgres.sh`;
  - `ops/db/restore-laptop-postgres.sh`;
  - `ops/smoke/check-laptop-postgres-backup.sh`.

Interpretation:

PHASE_14J_FT_POSTGRES_AUTHORITY=not_proven_authoritative_foundation_or_parked_pending_sudo_read

PostgreSQL must not be deleted, migrated, or treated as the live authority until a later approved sudo read-only inspection proves its databases/tables and consumers.

## Data-container design boundary

Based on FT-R1, the first data-container design should treat `edge_queue.sqlite3` as the current live source of truth.

A future data target must be designed around:

1. Backup of `edge_queue.sqlite3` before any mutation.
2. Restore proof for `edge_queue.sqlite3`.
3. Read-only copy/restore drill before live migration.
4. A clear path for controller to use a configurable DB path.
5. A rollback path that keeps the laptop authoritative until the new data target is proven.
6. No live controller write redirection until a later explicit apply phase.
7. PostgreSQL inspection kept separate unless a later sudo-read phase proves it is required.

## Recommended data target direction

The safest first design target is not a full controller move.

Recommended sequence:

1. Design SQLite data authority and backup/restore plan.
2. Add or verify controller DB path configurability without changing runtime behavior.
3. Create an offline copy/restore drill plan.
4. Only after backup/restore proof, create a data container or VM.
5. Only after data target proof, plan controller/queue container.
6. Only after controller/queue proof, plan worker containers.

## Proposed future topology

### website-edge VM

Already active:

- public/static website;
- nginx static runtime;
- Cloudflare tunnel for apex and www.

Must not host:

- controller/queue;
- durable database authority;
- workers;
- CT101/model controls;
- Proxmox controls.

### data container or VM

Future role:

- durable data volume for `edge_queue.sqlite3` or later database engine;
- backup/restore scripts;
- migration snapshots;
- rollback artifacts.

Not approved yet:

- no creation;
- no data copy;
- no live attach;
- no controller reconfiguration.

### controller/queue container

Future role:

- controller API;
- queue authority;
- scheduler/timer logic;
- controller-owned APIs.

Must wait for:

- data authority plan;
- data backup/restore proof;
- service packaging design;
- environment migration design;
- rollback plan.

### worker container

Future role:

- worker process;
- lane workers later;
- model dispatch client only.

Must wait for:

- controller/queue container proof;
- worker activation gates;
- no CT101/model calls without explicit approval.

## Required before any data container creation

Before creating a data container or VM, a later phase must define:

- exact target type: LXC, VM, Docker container, or other;
- storage location and backup path;
- snapshot/rollback method;
- SQLite file ownership and permissions;
- whether SQLite remains file-based or later migrates to PostgreSQL;
- controller DB path configuration method;
- read-only restore drill;
- post-restore integrity check;
- live cutover rollback method;
- service stop/start requirements, if any.

## Still not performed

- no container creation;
- no data migration;
- no controller/queue migration;
- no service restart/reload;
- no worker start;
- no production DB/job mutation;
- no CT101 call;
- no model/Ollama endpoint call;
- no Cloudflare route mutation;
- no token printing;
- no raw private IP recording;
- no Proxmox public exposure;
- no website-edge mutation;
- no nginx config mutation;
- no Docker install;
- no Node/npm install;
- no Tailscale ACL/grants/tag mutation;
- no Tailscale SSH mode enablement;
- no subnet route;
- no exit node;
- no Phase 14J-AG apply wrapper rerun.

## Phase result

PHASE_14J_FT_RESULT=data_authority_inspection_recorded_no_container_creation

NEXT_SAFE_PHASE=phase_14j_fu_sqlite_backup_restore_and_data_container_design_plan_no_creation

do not create containers
