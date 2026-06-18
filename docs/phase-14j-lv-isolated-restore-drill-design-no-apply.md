# Phase 14J-LV — Isolated Restore-Drill Design, No Apply

Updated: 2026-06-18

## Purpose

This phase records a no-apply design for a future isolated restore drill of the CT203 controller DB.

This phase does not execute a restore, create a backup, start CT204, promote CT204, mutate storage, unlock or mount encrypted private storage, change services, change CT/VM configuration, connect over SSH, wake PVESO, or change Cloudflare/DNS/tunnels.

## Prior checkpoint

- Phase: 14J-LU — CT204 Backup-Data Role Design, No Apply.
- Commit: `f9b6ebb`.
- Tag: `controller-phase-14j-lu-ct204-backup-data-role-no-apply-2026-06-18`.
- Result: `PASS_PHASE_14J_LU_CT204_BACKUP_DATA_ROLE_NO_APPLY_DONE`.

## Current baseline assumptions

- CT203 remains the live controller/API/queue authority.
- CT203 active DB remains `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
- VM200 remains public/static only.
- CT204 remains stopped, backup-data-only, and non-authoritative.
- Public CT204 expected state remains `stopped`.
- Public CT204 data authority remains `false`.
- PVEW private encrypted storage remains manual-unlock-only.
- Public private storage mount state remains `unknown`.
- PVESO remains parked/on-demand.
- Workstation `Host pvew` alias work remains separately gated.

## Non-mutation guarantee

This phase is docs/smoke only.

It performs no restore execution, no DB mutation, no DB backup creation, no DB restore/import/migration, no controller DB swap, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no SSH connection attempt, no SSH config mutation, no Tailscale config/auth mutation, no PVESO wake/start, no service restart/reload/enable/start/stop, and no Cloudflare/DNS/tunnel mutation.

## Restore-drill objective

A future restore drill should prove that a CT203 backup can be validated in isolation without touching the live CT203 DB or accidentally promoting CT204.

The drill should answer:

1. Does the backup file exist?
2. Is the backup file immutable for the duration of the test?
3. Does its sha256 match recorded metadata?
4. Does SQLite integrity check pass on an isolated copy?
5. Can basic expected tables be listed from the isolated copy?
6. Can row-count metadata be collected without exposing private data?
7. Can the drill complete without changing CT203, CT204, VM200, storage policy, services, or public routing?

## Required future drill shape

A future approved restore-drill phase should use an isolated workspace, not the live DB path.

Required properties:

- The source backup must be copied into a temporary isolated path.
- The isolated copy must be read-only where practical.
- SQLite checks must run against the isolated copy only.
- No command may write to `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
- No command may replace the live CT203 controller DB.
- No command may start or promote CT204 unless a separate explicit CT204 approval exists.
- No command may unlock or mount private storage unless a separate explicit storage approval exists.
- No command may restart or reload controller services.
- No private rows or user data may be printed.

## Future explicit approval boundary

Suggested approval phrase for a future isolated drill only:

`APPROVE_PHASE_14J_LW_ISOLATED_RESTORE_DRILL_READ_ONLY_COPY_ONLY`

Allowed scope after approval:

- Verify clean repo and public status.
- Verify backup file metadata using sanitized output.
- Copy a selected backup to a temporary isolated workspace.
- Run sha256 and SQLite integrity checks on the isolated copy.
- Collect sanitized schema/table/count metadata only.
- Delete only the temporary isolated workspace created by the drill, if the deletion scope is explicit and narrow.

Explicit non-scope:

- No live DB restore.
- No controller DB swap.
- No CT203 DB overwrite.
- No CT204 start.
- No CT204 data authority change.
- No DB import/migration into live paths.
- No storage unlock/mount/key/crypttab/fstab/auto-unlock/auto-mount mutation.
- No service restart/reload/enable/start/stop.
- No Cloudflare/DNS/tunnel mutation.
- No PVESO wake/start.
- No SSH config mutation.
- No Tailscale auth/config mutation.
- No private user data output.

## Stop conditions

Stop before any future restore drill if:

- repo is dirty;
- public `/system/status` is not online;
- CT203 authority is unclear;
- selected backup metadata is missing or inconsistent;
- backup sha256 does not match recorded metadata;
- SQLite integrity check fails on the isolated copy;
- the operation would touch the live CT203 DB path;
- the operation would require CT204 start or authority change;
- the operation would require storage unlock/mount without separate approval;
- the operation would require service restart/reload;
- secrets, keys, tokens, raw private IPs, MACs, auth URLs, or private user data would be printed.

## Relationship to CT204

CT204 is not required for the first isolated restore-drill design.

CT204 should remain stopped and non-authoritative until a separate explicit CT204 boundary exists.

A later CT204-specific drill can be designed only after:

1. backup metadata is trustworthy;
2. restore-drill steps are proven against an isolated copy;
3. CT204 role is written narrowly;
4. CT204 start and data access are explicitly approved.

## Recommended next phases

Safe next options:

1. Phase 14J-LW — status/UI polish no-apply review.
2. Approved Phase 14J-LS — add workstation `Host pvew` alias only.
3. Approved Phase 14J-LW — isolated restore-drill read-only copy only.
4. Approved Phase 14J-LV — CT204 read-only inspection only.

Any live SSH connection, DB backup, restore, CT204 start, storage unlock/mount, service restart, PVESO wake, or route/tunnel mutation requires its own explicit approval boundary.

## Exact smoke guardrail strings

The smoke script intentionally checks these exact phrases:

- No live DB restore
- No controller DB swap
- No CT203 DB overwrite
- No CT204 start
- No CT204 data authority change
- No storage unlock/mount/key/crypttab/fstab/auto-unlock/auto-mount mutation
- No service restart/reload/enable/start/stop
- No Cloudflare/DNS/tunnel mutation
- No PVESO wake/start
- No private user data output
- APPROVE_PHASE_14J_LW_ISOLATED_RESTORE_DRILL_READ_ONLY_COPY_ONLY

## Result marker

`PASS_PHASE_14J_LV_ISOLATED_RESTORE_DRILL_DESIGN_NO_APPLY_DONE`
