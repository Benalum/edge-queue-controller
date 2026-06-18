# Phase 14J-JJ - Controller DB Restore Rehearsal Plan, No Apply

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase plans a future restore rehearsal for the laptop controller SQLite backup stored on PVEW encrypted storage.

This phase does not restore, import, copy, migrate, or change controller authority.

## Current checkpoint

- Phase 14J-JI
- Commit 25459ff
- Tag controller-phase-14j-ji-controller-sqlite-backup-record-2026-06-18

## Backup to rehearse

- Remote directory: /srv/apc-private-data/ct204/backups/controller-laptop
- Backup file: edge_queue_controller_backup_20260618T162743Z_head-128babe.sqlite3
- Expected SHA256: 60627dfba7fbced05369068511dfabe6fc38cb7505a61ccf057bd7f01893ab53
- Recorded integrity: ok

## Future rehearsal goal

The future rehearsal should prove the encrypted backup can be retrieved and validated without touching live controller authority.

Allowed future rehearsal actions, under separate approval:

- copy the backup from PVEW encrypted storage to a temporary local rehearsal directory;
- verify SHA256;
- run SQLite integrity_check;
- open read-only metadata counts only;
- write a rehearsal manifest;
- delete the temporary rehearsal copy after verification unless explicitly kept.

## Hard boundaries

The future rehearsal must not:

- overwrite edge_queue.sqlite3;
- import the backup into any running service;
- change controller authority;
- stop, restart, or reload controller services;
- start CT203 or CT204;
- add a CT bind mount;
- expose data to VM200;
- mutate Proxmox storage;
- mutate crypttab or fstab;
- wake PVESO;
- print DB row contents or secrets.

## Required future approval phrase

APPROVE_PHASE_14J_JK_REHEARSE_CONTROLLER_SQLITE_BACKUP_RETRIEVAL_NO_RESTORE_NO_AUTHORITY_CHANGE

That future approval allows only temporary rehearsal retrieval and validation. It does not authorize restore or authority changes.

## Stop conditions

Stop if:

- repo is dirty;
- backup file is missing;
- manifest is missing;
- SHA256 does not match;
- SQLite integrity is not ok;
- encrypted mount is not active;
- CT203 or CT204 is running unexpectedly;
- any DB content would be printed.
