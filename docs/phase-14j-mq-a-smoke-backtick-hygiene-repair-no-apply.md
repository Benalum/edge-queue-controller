# Phase 14J-MQ-A — Smoke Backtick Hygiene Repair No-Apply

Updated: 2026-06-18

## Purpose

This phase repairs a repo-only smoke-script hygiene issue found after Phase 14J-MQ.

The 14J-MQ plan itself was committed and tagged successfully at `97d7009`, but the smoke script contained one raw Markdown-backtick path inside a double-quoted Bash argument. That caused Bash command substitution to attempt to execute `/srv/apc-private-data/backups/ct203` during smoke execution.

The smoke still passed, but the warning was undesirable before the real backup creation phase.

## Prior checkpoint

- Phase: 14J-MQ — CT203 Private-Storage Backup Execution Plan No-Apply.
- Commit: `97d7009`.
- Tag: `controller-phase-14j-mq-ct203-private-storage-backup-execution-plan-no-apply-2026-06-18`.
- Result: `PASS_PHASE_14J_MQ_CT203_PRIVATE_STORAGE_BACKUP_EXECUTION_PLAN_NO_APPLY_DONE`.

## Repair

Changed the affected MQ smoke assertion from a double-quoted literal containing raw Markdown backticks to a single-quoted literal.

Repaired file:

- `ops/smoke/check-phase-14j-mq-ct203-private-storage-backup-execution-plan-no-apply.sh`

Validation:

- `bash -n` passed.
- Repaired MQ smoke passed.
- `mq_smoke_command_substitution_warning=absent`.

## Safety posture

This was repo-only. No SSH connection, CT start/stop/restart, VM start/stop/restart, service restart/reload/enable/start/stop, storage unlock/mount/format/key/crypttab/fstab mutation, private storage write, DB mutation, DB backup creation, DB restore/import/migration, Cloudflare/DNS/tunnel mutation, frontend deploy, app source mutation, Tailscale config/auth mutation, or PVESO wake/start occurred.

## Backup approval remains unchanged

`APPROVE_PHASE_14J_MR_CREATE_CT203_BACKUP_ON_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART`

## Result marker

`PASS_PHASE_14J_MQ_A_SMOKE_BACKTICK_HYGIENE_REPAIR_NO_APPLY_DONE`
