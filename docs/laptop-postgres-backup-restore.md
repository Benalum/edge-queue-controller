# Laptop Postgres Backup and Restore — Stage 5D-3

## Purpose

Stage 5D-3 adds backup and restore tooling for the laptop/controller Postgres database before any production data is migrated into it.

Backups must exist before the laptop database becomes source of truth.

## Scripts

Backup script:

- ops/db/backup-laptop-postgres.sh

Restore script:

- ops/db/restore-laptop-postgres.sh

Smoke check:

- ops/smoke/check-laptop-postgres-backup.sh

## Backup location

Default backup location:

- ~/Desktop/ai-platform-controller-backups/postgres

The backup directory is outside the git repository.

## Backup format

Backups are created with pg_dump custom format:

- pg_dump --format=custom
- file extension: .dump

This allows pg_restore to inspect and restore the backup.

## Secret handling

The scripts read the local Postgres connection from:

- ~/.config/ai-platform-controller/postgres.env

That file must not be committed.

## Retention

The backup script keeps generated backups for a default retention window:

- AI_PLATFORM_CONTROLLER_BACKUP_RETENTION_DAYS
- default: 14 days

Only generated ai-platform-controller backup files are cleaned up by retention.

## Restore safety

The restore script requires:

1. a backup file path
2. the confirmation phrase RESTORE_AI_PLATFORM_CONTROLLER_DB
3. an interactive RESTORE confirmation

Restore is intentionally not run by the smoke check.

## Current migration state

No CT101 production data has been migrated yet.

The laptop/controller runtime still uses:

- edge_queue.sqlite3

The laptop Postgres database is still foundation-only.

## Required before app schema or migration

Before adding app tables or moving CT101 data:

1. Backup script must pass.
2. Restore process must be documented.
3. Backup location must be outside git.
4. Backup files must be non-empty.
5. pg_restore must be able to list the backup.
6. Rollback instructions must exist for each future migration stage.

## Future post-migration cleanup requirement

After the migration is complete and verified, remove unused legacy pieces in a separate cleanup stage.

Cleanup must include a review for:

- unused CT101 frontend pages
- unused CT101 database tables
- unused CT101 API routes
- unused duplicate functions
- unused laptop SQLite tables
- obsolete proxy routes
- obsolete public wrapper compatibility pages
- stale smoke tests that target removed behavior
- old backup files that are no longer needed

Cleanup must not happen until:

- laptop source-of-truth tables are live
- backups are passing
- restore has been tested
- read-only comparisons pass
- production behavior has been verified
- rollback instructions exist

## Stage 5D-3 constraints

Do not:

- migrate CT101 data
- create app schema tables
- change controller runtime database source
- change CT101 schemas
- change worker behavior
- change auth behavior
- remove old websites or databases yet
