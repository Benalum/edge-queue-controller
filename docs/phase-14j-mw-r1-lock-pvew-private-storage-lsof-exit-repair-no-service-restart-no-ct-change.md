# Phase 14J-MW-R1 — Lock PVEW Private Storage Apply with lsof Exit Repair

Updated: 2026-06-18

## Status

COMPLETED.

## Approval

The operator explicitly approved:

`APPROVE_PHASE_14J_MW_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE`

## Why R1 was needed

The first Phase 14J-MW apply attempt aborted before mutation during active-user preflight. It reached:

- private_storage_active_users_detected=no
- private_storage_active_pid_count=0

Then it exited before unmount/crypt close because `lsof` can return nonzero when no files are open, and the first script used `set -euo pipefail`.

R1 corrected this by capturing the `lsof` exit code and accepting nonzero only when the active-entry count is zero.

## Mutation scope

Allowed and completed:

- immediate read-only repo/public/PVEW preflight;
- unmount `/srv/apc-private-data`;
- close encrypted mapper `apc_private_data`;
- post-lock public and PVEW verification;
- repo documentation/smoke/commit/tag/push record.

Forbidden and not performed:

- no storage unlock/mount/format/key/crypttab/fstab mutation;
- no CT/VM start/stop/restart/config mutation;
- no service restart/reload/enable/start/stop;
- no backup creation;
- no DB restore/import/migration;
- no Cloudflare/DNS/tunnel mutation;
- no PVESO wake/start;
- no worker/model activation;
- no env file contents printed.

## Repo preflight

- head_before: `6e6d699`
- origin_main_before: `6e6d699`
- previous tag head: `6e6d699`
- repo status before: clean

## Public preflight

- public_status_http_code_before: `200`
- overall_state_before: `online`
- schema_version_before: `2`
- node_ids_sorted_before: `ct-203,ct-204,pvew,vm-200`
- private_storage_policy_before: `manual-unlock-only`
- private_storage_mount_state_before: `unknown`
- private_storage_mountpoint_before: `/srv/apc-private-data`
- ct204_expected_state_before: `stopped`
- ct204_data_authority_before: `false`
- public_app_sha256_before: `8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- public_app_legacy_hits_before: absent

## PVEW apply result

PVEW reported:

- private storage active users detected before mutation: no
- private storage active PID count before mutation: 0
- lsof active entries before mutation: 0
- systemd references to private mount: no
- fstab references to private mount: no
- crypttab references to apc_private_data: no
- verified backup bundle present: yes
- backup bundle path: `/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z`
- unmount result: `/srv/apc-private-data` not mounted
- mapper close result: `/dev/mapper/apc_private_data` absent
- CT203 remained running
- CT203 edge-queue-controller.service remained active/enabled
- VM200 remained running
- CT204 remained stopped

Remote result:

`RESULT_REMOTE=PASS_PHASE_14J_MW_R1_PVEW_PRIVATE_STORAGE_UNMOUNTED_AND_MAPPER_CLOSED`

## Public post-lock verification

- public_status_http_code_after: `200`
- overall_state_after: `online`
- schema_version_after: `2`
- node_ids_sorted_after: `ct-203,ct-204,pvew,vm-200`
- private_storage_policy_after: `manual-unlock-only`
- private_storage_mount_state_after: `unknown`
- private_storage_mountpoint_after: `/srv/apc-private-data`
- ct204_expected_state_after: `stopped`
- ct204_data_authority_after: `false`
- public_app_sha256_after: `8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- public_app_legacy_hits_after: absent

## Current state after this phase

- PVEW private storage is locked/unmounted.
- `/srv/apc-private-data` is not mounted.
- `/dev/mapper/apc_private_data` is closed/absent.
- CT203 remains controller/API/queue authority.
- VM200 remains public/static only.
- CT204 remains stopped, backup-data-only, and data_authority=false.
- PVESO remains parked/offline unless explicitly approved later.
- Public status remains online and policy-only for private storage.

## Smoke recovery note

The Phase 14J-MW-R1 apply operation succeeded and public/PVEW post-lock checks passed, but the first R1 PPB wrapper run exited during the repo smoke step because the smoke used an overly exact grep for the backticked `lsof` phrase.

This recovery step did not rerun storage mutation. It verified the locked state read-only and repaired the smoke assertion before committing the completed R1 record.

## Next safe work

Next safe options:

1. source refresh/new-chat handoff;
2. no-apply private storage reopen procedure plan;
3. no-apply CT204 restore-drill plan;
4. no-apply worker/model re-entry plan.

Any private storage reopen/unlock/mount requires a separate explicit approval boundary.

## Result

RESULT=PASS_PHASE_14J_MW_R1_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE_DONE
