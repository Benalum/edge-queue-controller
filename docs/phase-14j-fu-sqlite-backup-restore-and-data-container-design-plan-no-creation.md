# Phase 14J-FU - SQLite backup/restore drill and data-container design plan, no creation

PHASE_14J_FU_SQLITE_BACKUP_RESTORE_AND_DATA_CONTAINER_DESIGN_PLAN_NO_CREATION

## Status

Result: sqlite_backup_restore_drill_passed_data_container_design_plan_recorded_no_creation.

This phase records the temporary SQLite backup/restore drill and the data-container design boundary after Phase 14J-FT established that `edge_queue.sqlite3` is the current live controller/platform data authority.

This phase does not create containers, migrate data, mutate the live DB, move controller/queue, restart or reload services, start workers, call CT101, call model endpoints, mutate Cloudflare routes, or rerun the Phase 14J-AG apply wrapper.

## Starting checkpoint

Previous repo checkpoint:

- Phase: 14J-FT - data authority inspection and data container design boundary
- Commit: 008aa6a
- Tag: controller-phase-14j-ft-read-only-data-authority-inspection-and-data-container-design-boundary-2026-06-17
- Repo state at FU-R1 start: clean/current

## FU-R1 temporary SQLite backup/restore result

Phase 14J-FU-R1 completed with exit code 0.

Validated:

- repo clean/current at commit 008aa6a;
- Phase 14J-FT focused smoke regression passed;
- live SQLite read-only baseline completed;
- temporary SQLite online backup drill completed;
- backup integrity and count comparison completed;
- temporary restore drill completed;
- DB path configurability inspection completed;
- no container creation occurred;
- no data migration occurred;
- no live DB mutation occurred;
- no controller/queue migration occurred;
- no service restart/reload occurred;
- no worker start occurred;
- no CT101 call occurred;
- no model/Ollama endpoint call occurred;
- no user table row dumps occurred.

## Live SQLite baseline

Observed live SQLite metrics:

- live DB: `edge_queue.sqlite3`;
- live DB size: approximately 42 MB;
- live quick_check: ok;
- live table count: 39;
- live index count: 18;
- live total rows across tables: 25,354.

No table row contents were dumped.

## Temporary backup proof

The temporary backup used the Python/sqlite3 backup API from a read-only source connection.

Observed backup proof:

- backup file was created in a temporary directory;
- backup file was non-empty;
- backup quick_check: ok;
- backup table count: 39;
- backup index count: 18;
- backup total rows across tables: 25,354;
- backup table list matched live table list;
- backup index list matched live index list;
- backup table row counts matched live table row counts.

Result marker:

PHASE_14J_FU_TEMP_SQLITE_BACKUP_DRILL=passed

## Temporary restore proof

The temporary restore drill copied the temporary backup to a temporary restore DB and inspected it read-only.

Observed restore proof:

- restore file was created in a temporary directory;
- restore file was non-empty;
- restore quick_check: ok;
- restore table count: 39;
- restore total rows across tables: 25,354;
- restore table list matched backup table list;
- restore table row counts matched backup table row counts.

Result marker:

PHASE_14J_FU_TEMP_SQLITE_RESTORE_DRILL=passed

## DB path configurability finding

Observed current DB path declaration:

- `edge_controller.py` uses `DB_PATH = Path("edge_queue.sqlite3")`.

Observed service configuration:

- `edge-queue-controller.service` uses `WorkingDirectory=/home/alex/Desktop/edge-queue-controller`;
- `edge-queue-controller.service` starts `uvicorn edge_controller:app --host 0.0.0.0 --port 7070`;
- the controller service did not show DB-related environment keys during FU-R1.

Interpretation:

PHASE_14J_FU_DB_PATH_CONFIGURABILITY=current_controller_db_path_repo_relative_default_only

The current controller DB path appears tied to repo-relative `edge_queue.sqlite3` unless an env-based override is added or otherwise proven.

## Design conclusion

Live SQLite remains authoritative on the laptop.

The temporary backup/restore drill proves that a consistent SQLite backup can be made without stopping the live controller, and that a restore copy can pass integrity and row-count checks.

A future persistent backup tool should:

- use the SQLite backup API;
- source from the live DB in read-only mode;
- write outside the git repository;
- create backup files with restrictive permissions;
- record a manifest with table/index counts but no user row dumps;
- verify `PRAGMA quick_check`;
- verify table lists and row counts;
- support retention cleanup;
- never print secrets or raw private IPs.

## Required before creating a data container or VM

Before any data container or VM creation, a later phase should provide:

1. persistent SQLite backup script;
2. persistent SQLite restore verification script;
3. smoke test for backup/restore;
4. default-off/env-based controller DB path configurability patch;
5. validation that default behavior still uses repo-local `edge_queue.sqlite3`;
6. service migration plan for environment file changes;
7. stop/start or read-only freeze plan for any future live cutover;
8. rollback plan keeping laptop `edge_queue.sqlite3` authoritative until the new target is proven.

## Recommended next implementation order

Recommended next phases:

1. Phase 14J-FV: add persistent SQLite backup/restore drill scripts and smoke, no runtime change.
2. Phase 14J-FW: add default-preserving controller DB path env override, no runtime reload.
3. Phase 14J-FX: design data container or VM target, no creation.
4. Later explicit apply: create data target and copy backup for offline validation.
5. Later explicit apply: controller DB path cutover only after backup/restore and rollback are proven.

## Proposed future topology

### website-edge VM

Already active:

- public/static website;
- nginx static runtime;
- Cloudflare tunnel for apex and www.

### laptop current authority

Still active:

- `edge_queue.sqlite3` live data authority;
- controller/queue service;
- wrapper remnants;
- power/remediation timers;
- PostgreSQL foundation/parked state;
- PPB and development workflow.

### future data container or VM

Future role:

- durable SQLite file or later database service;
- persistent backups;
- restore verification;
- snapshot/rollback artifacts;
- no public exposure.

### future controller/queue container

Future role:

- controller API;
- queue authority;
- scheduler/timers;
- controller-owned APIs.

Must wait until data target proof and rollback exist.

### future worker container

Future role:

- queue workers;
- lane workers;
- model dispatch client only.

Must wait until controller/queue migration is proven.

## Still not performed

- no container creation;
- no data migration;
- no live DB mutation;
- no controller/queue migration;
- no service restart/reload;
- no worker start;
- no production DB/job mutation;
- no CT101 call;
- no model/Ollama endpoint call;
- no Cloudflare route mutation;
- no Cloudflare API token use;
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

PHASE_14J_FU_RESULT=sqlite_backup_restore_drill_passed_data_container_design_plan_recorded_no_creation

NEXT_SAFE_PHASE=phase_14j_fv_persistent_sqlite_backup_restore_scripts_no_runtime_change
