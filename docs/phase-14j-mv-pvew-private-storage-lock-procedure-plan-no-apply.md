# Phase 14J-MV — PVEW Private Storage Lock Procedure Plan No-Apply

Updated: 2026-06-18

## Status

NO-APPLY PLAN ONLY.

This phase does not lock private storage, unmount private storage, close the encrypted mapper, start or stop CTs/VMs, restart services, create backups, restore databases, change Cloudflare/DNS/tunnels, wake PVESO, or activate workers/models.

## Latest baseline carried forward

Latest committed checkpoint before this plan:

- Phase: 14J-MT — Private Storage Lock Readiness Read-Only
- Commit: 4bb606d
- Tag: controller-phase-14j-mt-private-storage-lock-readiness-read-only-2026-06-18
- Result: PASS_PHASE_14J_MT_PRIVATE_STORAGE_LOCK_READINESS_READ_ONLY_DONE

New-chat baseline observed during 14J-MU-R2:

- repo head, origin/main, and dereferenced remote tag matched 4bb606d;
- public /system/status returned HTTP 200;
- overall_state was online;
- normalized.schema_version was 2;
- node IDs sorted were ct-203,ct-204,pvew,vm-200;
- private storage policy was manual-unlock-only;
- public mount_state was unknown;
- public mountpoint was /srv/apc-private-data;
- CT204 expected_state was stopped;
- CT204 public node state was planned;
- public app source remained /app.js?v=2026061814jlbr2;
- public app sha256 remained 8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751;
- public deployed legacy hits were absent.

## Public contract warning carried forward

14J-MU-R2 found:

- ct204_data_authority=missing
- data_authority_paths=absent

This is public status contract drift because the intended public contract says CT204 should expose data_authority=false. It is not evidence that CT204 is authoritative. The same baseline still showed CT204 expected_state=stopped and state=planned, with no explicit data_authority=true.

Lock/unmount apply must not rely only on the public JSON for CT204 authority. It must verify CT204 state directly from PVEW immediately before any mutation.

A later public status contract repair phase should restore an explicit public-safe CT204 data_authority=false field.

## Current private storage evidence carried forward from 14J-MT

14J-MT found:

- private_storage_active_users_detected=no;
- private_storage_active_pid_count=0;
- systemd_units_reference_private_mount=no;
- fstab_references_private_mount=no;
- crypttab_references_apc_private_data=no;
- readiness_for_lock_decision=ready_for_no_apply_lock_plan.

Private storage has not been locked/unmounted yet.

## Current verified backup carried forward

Latest verified CT203 backup bundle:

- /srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z

Verification carried forward:

- SHA256SUMS verified with 12 OK and 0 failed;
- SQLite read-only integrity_check was ok;
- sqlite_page_count was 10692;
- sqlite_table_count was 40;
- env backup file mode was 600, owner root, group root;
- env file contents were not printed.

## Intended future apply phase

The future apply phase should be Phase 14J-MW.

Suggested approval phrase:

APPROVE_PHASE_14J_MW_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE

The apply phase must be rejected unless the approval phrase is explicit and current.

## Phase 14J-MW allowed actions after approval

Only after explicit approval, Phase 14J-MW may:

1. SSH to PVEW as root.
2. Re-run immediate read-only preflight checks.
3. Abort if any blocker is found.
4. Unmount /srv/apc-private-data.
5. Close /dev/mapper/apc_private_data.
6. Verify the mountpoint is not mounted.
7. Verify the mapper is closed.
8. Verify public /system/status still returns HTTP 200 and keeps mount_state unknown.
9. Verify CT203 service remains active and VM200 remains public/static.
10. Record sanitized output only.

## Phase 14J-MW forbidden actions even after approval

The apply phase must not:

- start, stop, restart, or reconfigure CT203, CT204, VM200, or PVESO;
- restart, reload, enable, disable, start, or stop services;
- create a new backup;
- restore, import, migrate, or mutate a database;
- change Cloudflare, DNS, tunnels, routes, or public cutover;
- write crypttab, fstab, keyfiles, auto-unlock configuration, or auto-mount configuration;
- print secrets, tokens, env file contents, auth URLs, private IPs, Tailscale IPs, or MAC addresses;
- activate workers, models, scheduler dispatch, lane filters, warmups, or PVESO compute.

## Required immediate preflight before lock/unmount apply

The apply phase must check all of these immediately before mutation:

### Public status preflight

- public /system/status HTTP 200;
- overall_state online;
- normalized.schema_version 2;
- node IDs sorted ct-203,ct-204,pvew,vm-200;
- private_storage_status.policy manual-unlock-only;
- private_storage_status.mount_state unknown;
- private_storage_status.mountpoint /srv/apc-private-data;
- CT204 expected_state stopped if public field exists;
- no explicit CT204 data_authority=true anywhere in public status.

If CT204 data_authority is missing publicly, the apply phase may continue only if direct PVEW CT204 checks confirm stopped/non-authority posture.

### PVEW direct state preflight

- PVEW reachable by approved SSH target pvew;
- /srv/apc-private-data is currently mounted;
- backing mapper is /dev/mapper/apc_private_data;
- filesystem is ext4;
- mountpoint mode is 700, owner root, group root;
- CT203 is running;
- VM200 is running;
- CT204 is stopped;
- no CT204 data-authority marker or runtime state is introduced;
- PVESO is not started or woken by this phase.

### Active-user preflight

The apply phase must check:

- findmnt /srv/apc-private-data;
- fuser -vm /srv/apc-private-data or equivalent;
- lsof +f -- /srv/apc-private-data or equivalent when available;
- systemd unit files for references to /srv/apc-private-data;
- /etc/fstab for references to /srv/apc-private-data;
- /etc/crypttab for apc_private_data references.

Abort if any active process is using /srv/apc-private-data.

Abort if a service or system config depends on the mount.

### Backup preflight

The apply phase must verify the current known bundle still exists:

- /srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z

It should verify manifest and SHA256SUMS are present.

It should not create a new backup unless a separate backup-creation approval is given.

## Apply command shape for later use

The future apply phase should use a guarded shell flow equivalent to:

1. set -euo pipefail
2. set +H
3. define APC_LAST_OUTPUT
4. sanitize all output
5. trap phase exit code
6. run all public and PVEW direct preflight checks
7. abort on any active user, mount dependency, CT204 authority concern, or unexpected state
8. run umount /srv/apc-private-data
9. run cryptsetup close apc_private_data
10. verify findmnt /srv/apc-private-data fails
11. verify /dev/mapper/apc_private_data is absent
12. verify public status still safe
13. verify CT203 service still active without restart
14. produce a clear PASS result

Do not paste or run this apply command until Phase 14J-MW is explicitly approved.

## Abort blockers

The future apply phase must abort before mutation if any of these are true:

- public /system/status is not HTTP 200;
- public overall_state is not online;
- node IDs are not ct-203,ct-204,pvew,vm-200;
- public private storage policy is not manual-unlock-only;
- public mount_state is not unknown;
- public status explicitly marks CT204 data_authority=true;
- PVEW is not reachable;
- /srv/apc-private-data is not currently mounted when lock was intended;
- backing mapper is not /dev/mapper/apc_private_data;
- mount filesystem is not ext4;
- mountpoint is not mode 700 owner root group root;
- CT203 is not running;
- VM200 is not running;
- CT204 is not stopped;
- active users or active PIDs are detected on /srv/apc-private-data;
- systemd, fstab, or crypttab references create a dependency on the private mount;
- latest verified backup bundle is missing;
- env file contents would be printed;
- the operator has not given the exact Phase 14J-MW approval phrase.

## Post-lock verification for later apply

After a successful future lock/unmount apply, verify:

- findmnt /srv/apc-private-data returns not mounted;
- /dev/mapper/apc_private_data is absent;
- /srv/apc-private-data remains a root-owned directory and is not exposing private data;
- CT203 service remains active;
- VM200 remains running and public/static only;
- CT204 remains stopped;
- public /system/status remains HTTP 200;
- public status keeps mount_state unknown and policy manual-unlock-only;
- no Cloudflare/DNS/tunnel change occurred;
- no service restart/reload occurred;
- no backup, restore, DB migration, worker activation, or PVESO wake occurred.

## Rollback or reopen path

If private storage must be reopened later, use a separate explicit approval phase. That phase must be no-apply planned first unless it is an emergency recovery.

A future reopen phase must not add auto-unlock, auto-mount, keyfiles, crypttab, or fstab entries unless explicitly approved as a separate storage architecture change.

## Result

This phase creates the no-apply lock procedure plan only.

RESULT=PASS_PHASE_14J_MV_PVEW_PRIVATE_STORAGE_LOCK_PROCEDURE_PLAN_NO_APPLY_DOC_READY
