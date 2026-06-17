# Phase 14J-FV - Persistent SQLite backup/restore scripts, no runtime change

PHASE_14J_FV_PERSISTENT_SQLITE_BACKUP_RESTORE_SCRIPTS_NO_RUNTIME_CHANGE

## Status

Result: persistent_sqlite_backup_restore_scripts_added_no_runtime_change.

This phase adds persistent SQLite backup and verification scripts for the current live controller/platform SQLite authority, `edge_queue.sqlite3`.

This phase does not create containers, migrate data, mutate the live DB, move controller/queue, restart or reload services, start workers, call CT101, call model endpoints, mutate Cloudflare routes, or rerun the Phase 14J-AG apply wrapper.

## Starting checkpoint

Previous repo checkpoint:

- Phase: 14J-FU-R2 - FU smoke backtick marker repair
- Commit: aba6ba1
- Tag: controller-phase-14j-fu-r2-smoke-backtick-marker-repair-2026-06-17
- Repo state at FV start: clean/current

## Added scripts

### ops/db/backup-edge-queue-sqlite.sh

Purpose:

- create a consistent SQLite backup from the live DB using Python sqlite3 backup API;
- default source DB: `edge_queue.sqlite3`;
- default backup root: `~/Desktop/ai-platform-controller-backups/sqlite`;
- write backup files outside the repository by default;
- chmod backup and manifest files to 0600;
- create/update `latest.sqlite3` symlink;
- apply retention cleanup for generated backup and manifest files;
- print only file paths and summary metrics;
- never dump user rows.

Supported environment variables:

- `EDGE_QUEUE_SQLITE_DB_PATH`;
- `EDGE_QUEUE_DB_PATH`;
- `EDGE_CONTROLLER_DB_PATH`;
- `EDGE_QUEUE_SQLITE_BACKUP_DIR`;
- `EDGE_QUEUE_SQLITE_BACKUP_RETENTION_DAYS`.

### ops/db/verify-edge-queue-sqlite-backup.sh

Purpose:

- verify a SQLite backup file read-only;
- copy the backup into a temporary restore file;
- verify backup and restore quick_check;
- verify backup/restore table list, row counts, and indexes match;
- compare live DB and backup table/index shape;
- warn, not fail, if live row counts drift after backup while controller remains active;
- never dump user rows.

## Smoke coverage

The smoke uses a temporary backup directory and validates:

- previous Phase 14J-FU smoke regression;
- backup script exists and is executable;
- verification script exists and is executable;
- backup script syntax;
- verification script syntax;
- temporary backup file is created outside the repo;
- temporary manifest file is created outside the repo;
- backup file is non-empty;
- manifest file is non-empty;
- backup file mode is 600;
- manifest file mode is 600;
- backup quick_check is ok;
- backup table count is present;
- backup index count is present;
- verification script passes;
- no container is created;
- no runtime config is changed;
- no service restart/reload occurs.

## Runtime boundary

This phase intentionally does not add a timer or systemd service for backups.

A future scheduling phase may add a timer only after separate approval and after the backup location/retention policy is accepted.

## Data-container boundary

These scripts are preparation for a future data container or VM design, but this phase does not create a data container or VM.

Before a data target is created, the project still needs:

1. default-preserving controller DB path env override;
2. data target type decision;
3. storage path decision;
4. snapshot/rollback method;
5. offline restore validation on target;
6. explicit live cutover plan;
7. rollback to laptop `edge_queue.sqlite3`.

## Phase result

PHASE_14J_FV_RESULT=persistent_sqlite_backup_restore_scripts_added_no_runtime_change

NEXT_SAFE_PHASE=phase_14j_fw_default_preserving_controller_db_path_env_override_no_runtime_reload
