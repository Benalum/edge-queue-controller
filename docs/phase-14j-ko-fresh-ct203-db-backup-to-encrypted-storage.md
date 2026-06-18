# Phase 14J-KO — Fresh CT203 DB backup to encrypted storage

Date: 2026-06-18

## Scope

This checkpoint records the approved fresh backup of CT203's current controller SQLite DB to encrypted PVEW storage.

## Approval

APPROVE_PHASE_14J_KO_FRESH_CT203_DB_BACKUP_TO_ENCRYPTED_STORAGE_NO_RESTORE_NO_DB_MUTATION_NO_SERVICE_RESTART

## Applied mutation

Only backup storage was written.

A consistent SQLite backup was created from CT203 and stored on encrypted PVEW storage under:

- `/srv/apc-private-data/ct204/backups/ct203-controller/edge_queue_ct203_backup_20260618T185019Z_head-8044621.sqlite3`

A manifest was written next to it:

- `/srv/apc-private-data/ct204/backups/ct203-controller/edge_queue_ct203_backup_20260618T185019Z_head-8044621.sqlite3.manifest`

## Verified result

- Backup size: `43794432` bytes.
- Backup sha256: `5efdad7febca35d7284506f34af57bb551a43be0db368e94603dcd2fd116cb28`.
- Backup integrity check returned `ok`.
- Encrypted storage mount was present at `/srv/apc-private-data`.
- VM200 remained running.
- CT203 remained running.
- CT204 remained stopped.

## Explicitly not changed

- No restore.
- No DB mutation.
- No service restart or reload.
- No CT/VM start or stop.
- No Cloudflare, DNS, or tunnel mutation.

## Current posture

The current CT203 controller DB now has a fresh encrypted backup after the public login repair and post-login session creation. CT203 remains controller/API/queue candidate with boot persistence enabled. CT204 remains data/backups only and is not live data authority.
