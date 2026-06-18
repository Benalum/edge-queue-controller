# Phase 14J-JI - Controller SQLite Backup Record

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_record

This phase records the completed Phase 14J-JH laptop controller SQLite backup to PVEW encrypted storage.

The recording phase itself does not dump, copy, import, migrate, or change controller authority.

## Approval boundary used

APPROVE_PHASE_14J_JH_CREATE_CONTROLLER_SQLITE_BACKUP_ON_PVEW_ENCRYPTED_STORAGE_NO_AUTHORITY_CHANGE

## Completed backup

Source:

- Host: laptop-controller
- Source DB: edge_queue.sqlite3
- Source repo checkpoint: 128babe

Target:

- Host: PVEW
- Target directory: /srv/apc-private-data/ct204/backups/controller-laptop
- Backup file: edge_queue_controller_backup_20260618T162743Z_head-128babe.sqlite3
- Manifest file: edge_queue_controller_backup_20260618T162743Z_head-128babe.manifest.txt

Verification:

- Backup size bytes: 43700224
- Backup SHA256: 60627dfba7fbced05369068511dfabe6fc38cb7505a61ccf057bd7f01893ab53
- Local SQLite integrity: ok
- Remote SQLite integrity: ok
- Remote SHA256 matched local SHA256
- Remote file permissions were set to 600
- Manifest permissions were set to 600

## Boundary state after backup

Still true after Phase 14J-JH:

- laptop-local edge_queue.sqlite3 remains live controller data authority;
- no DB import occurred;
- no DB migration occurred;
- no controller authority move occurred;
- CT203 remains stopped;
- CT204 remains stopped;
- VM200 remains public/static only and has no private data access;
- no CT bind mount was added;
- no pvesm add/set occurred;
- no /etc/crypttab mutation occurred;
- no /etc/fstab mutation occurred;
- PVESO was not woken.

## Next planning targets

Recommended next safe phases:

1. no-apply restore rehearsal plan from encrypted backup;
2. no-apply CT204 bind-mount design;
3. no-apply PVEW cluster quorum normalization plan;
4. source refresh/new-chat handoff after the next stable checkpoint.
