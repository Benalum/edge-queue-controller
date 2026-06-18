# Phase 14J-JK - Controller DB Backup Retrieval Rehearsal Record

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_record

This phase records the completed temporary retrieval rehearsal for the laptop controller SQLite backup stored on PVEW encrypted storage.

The recording phase itself does not restore, import, copy, migrate, or change controller authority.

## Approval boundary used

APPROVE_PHASE_14J_JK_REHEARSE_CONTROLLER_SQLITE_BACKUP_RETRIEVAL_NO_RESTORE_NO_AUTHORITY_CHANGE

## Rehearsed backup

- Remote directory: /srv/apc-private-data/ct204/backups/controller-laptop
- Backup file: edge_queue_controller_backup_20260618T162743Z_head-128babe.sqlite3
- Expected SHA256: 60627dfba7fbced05369068511dfabe6fc38cb7505a61ccf057bd7f01893ab53

## Rehearsal verification result

The backup was retrieved into a temporary local rehearsal directory and validated.

Observed result:

- Local rehearsal size bytes: 43700224
- Local rehearsal SHA256: 60627dfba7fbced05369068511dfabe6fc38cb7505a61ccf057bd7f01893ab53
- Rehearsal SQLite integrity: ok
- Rehearsal page count: 10669
- Rehearsal freelist count: 0
- Rehearsal schema object count: 57
- Rehearsal table count: 39
- Rehearsal index count: 18
- Rehearsal trigger count: 0
- Rehearsal view count: 0

Only schema/object counts and SQLite metadata were inspected. DB row contents were not printed.

## Live DB guard

The live laptop DB identity was unchanged before and after the rehearsal:

- live_db_identity_before: 51:542960:43708416:1781800223
- live_db_identity_after: 51:542960:43708416:1781800223

This confirms the rehearsal did not overwrite the live edge_queue.sqlite3 file.

## Boundary state after rehearsal

Still true after Phase 14J-JK:

- no DB restore occurred;
- no DB import occurred;
- no controller authority move occurred;
- CT203 remains stopped;
- CT204 remains stopped;
- VM200 remains public/static only and has no private data access;
- no CT bind mount was added;
- no pvesm add/set occurred;
- no /etc/crypttab mutation occurred;
- no /etc/fstab mutation occurred;
- PVESO was not woken;
- temporary local rehearsal copy was removed by trap cleanup.

## Next planning targets

Recommended next safe phases:

1. no-apply CT204 bind-mount design;
2. no-apply PVEW cluster quorum normalization plan;
3. source refresh/new-chat handoff after this stable checkpoint;
4. later CT204 start/rehearsal only after explicit approval.
