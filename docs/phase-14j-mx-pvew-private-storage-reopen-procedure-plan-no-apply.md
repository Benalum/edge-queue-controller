# Phase 14J-MX — PVEW Private Storage Reopen Procedure Plan No-Apply

Updated: 2026-06-18

## Status

NO-APPLY PLAN ONLY.

This phase does not unlock, mount, format, write keys, edit crypttab, edit fstab, start or stop CTs/VMs, restart services, create backups, restore databases, change Cloudflare/DNS/tunnels, wake PVESO, or activate workers/models.

## Current baseline carried forward

Latest completed checkpoint before this plan:

- Phase: 14J-MW-R1 — Lock PVEW Private Storage Apply with lsof Exit Repair
- Commit: d198382
- Tag: controller-phase-14j-mw-r1-lock-pvew-private-storage-lsof-exit-repair-no-service-restart-no-ct-change-2026-06-18
- Result: PASS_PHASE_14J_MW_R1_LOCKED_STATE_SMOKE_RECOVERY_COMMIT_TAG_PUSH_DONE

Current state carried forward:

- PVEW private storage is locked/unmounted.
- `/srv/apc-private-data` is not mounted.
- `/dev/mapper/apc_private_data` is absent/closed.
- CT203 remains running and is controller/API/queue authority.
- `edge-queue-controller.service` remains active/enabled.
- VM200 remains running and public/static only.
- CT204 remains stopped, backup-data-only, and `data_authority=false`.
- Public `/system/status` remains HTTP 200 and online.
- Public storage status remains policy-only with `mount_state=unknown`.

## Purpose

Define the safe future procedure to reopen PVEW encrypted private storage only when explicitly needed.

Typical future reasons:

- verify or read backup bundles;
- prepare a CT204 restore-drill;
- create a new CT203 backup after a separate backup approval;
- inspect private backup metadata.

This plan does not approve any of those operations.

## Future apply phase

Suggested future phase name:

- Phase 14J-MY — Reopen PVEW Private Storage Apply

Suggested approval phrase:

`APPROVE_PHASE_14J_MY_REOPEN_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE`

The future apply phase must be rejected unless the approval phrase is explicit and current.

## Future apply allowed actions after approval

Only after explicit approval, a future reopen apply phase may:

1. SSH to PVEW as root.
2. Run immediate read-only public/PVEW preflight.
3. Confirm `/srv/apc-private-data` is not mounted.
4. Confirm `/dev/mapper/apc_private_data` is absent.
5. Identify the intended encrypted LUKS backing device using read-only discovery.
6. Abort if zero or multiple plausible LUKS candidates are found unless the exact device was explicitly provided and verified.
7. Read the passphrase through a hidden interactive prompt only.
8. Run `cryptsetup open` for the approved backing device as `apc_private_data`.
9. Mount `/dev/mapper/apc_private_data` at `/srv/apc-private-data` as ext4.
10. Verify mountpoint mode/owner/group is `700 root root`.
11. Verify the latest known CT203 backup bundle path exists after mount.
12. Verify CT203 remains running and service active/enabled.
13. Verify VM200 remains running.
14. Verify CT204 remains stopped.
15. Verify public `/system/status` remains HTTP 200 and policy-only.
16. Record sanitized output only.

## Future apply forbidden actions even after approval

The reopen apply phase must not:

- format private storage;
- create, rotate, print, or persist new storage keys;
- write or modify crypttab;
- write or modify fstab;
- add auto-unlock or auto-mount behavior;
- start, stop, restart, or reconfigure CT203, CT204, VM200, or PVESO;
- restart, reload, enable, disable, start, or stop services;
- create a backup unless separately approved;
- restore, import, migrate, or mutate a database;
- change Cloudflare, DNS, tunnels, routes, or public cutover;
- print secrets, passphrases, tokens, env file contents, auth URLs, private IPs, Tailscale IPs, or MAC addresses;
- activate workers, models, scheduler dispatch, lane filters, warmups, or PVESO compute.

## Required immediate preflight before future reopen

### Public status preflight

The future apply phase must verify:

- public `/system/status` HTTP 200;
- `overall_state=online`;
- `normalized.schema_version=2`;
- node IDs sorted `ct-203,ct-204,pvew,vm-200`;
- `private_storage_status.policy=manual-unlock-only`;
- `private_storage_status.mount_state=unknown`;
- `private_storage_status.mountpoint=/srv/apc-private-data`;
- `private_storage_status.ct204.expected_state=stopped`;
- `private_storage_status.ct204.data_authority=false`;
- no legacy public app hits for CT101, laptop authority, PVESO-as-primary, or llms-worker;
- public app sha remains the expected deployed wrapper hash unless a separate frontend deploy occurred.

### PVEW locked-state preflight

The future apply phase must verify directly on PVEW:

- PVEW reachable through approved SSH target `pvew`;
- remote user is root;
- `/srv/apc-private-data` is not mounted;
- `/dev/mapper/apc_private_data` is absent;
- `cryptsetup status apc_private_data` is inactive;
- mountpoint directory exists and is `700 root root`;
- CT203 is running;
- `edge-queue-controller.service` inside CT203 is active/enabled;
- VM200 is running;
- CT204 is stopped;
- PVESO is not started or woken by this phase.

### LUKS device discovery preflight

The future apply phase must identify the backing LUKS device read-only.

Acceptable discovery commands include:

- `lsblk -f`;
- `blkid`;
- `find /dev/disk/by-id /dev/disk/by-uuid -type l`;
- `cryptsetup isLuks <candidate>`.

The future apply phase must not print secrets.

The future apply phase must abort if:

- no LUKS device candidate is found;
- more than one plausible candidate is found and no exact approved device path is provided;
- the candidate is already opened under an unexpected mapper;
- the candidate is not a LUKS device;
- the intended mapper name `apc_private_data` is already in use;
- `/srv/apc-private-data` is already mounted unexpectedly.

## Future apply command shape

The future apply phase should use a guarded flow equivalent to:

1. `set -euo pipefail`
2. `set +H`
3. define `APC_LAST_OUTPUT`
4. sanitize all output
5. safe trap with phase exit code
6. public preflight
7. PVEW locked-state preflight
8. LUKS device discovery
9. hard abort on ambiguity or unsafe state
10. hidden passphrase prompt
11. `cryptsetup open <approved_luks_device> apc_private_data`
12. `mount -t ext4 /dev/mapper/apc_private_data /srv/apc-private-data`
13. verify `findmnt /srv/apc-private-data`
14. verify source `/dev/mapper/apc_private_data`
15. verify fstype `ext4`
16. verify mountpoint `700 root root`
17. verify known backup bundle path exists
18. verify CT/VM/service states unchanged
19. verify public status remains online/policy-only
20. produce a clear PASS result

Do not paste or run this apply command until Phase 14J-MY is explicitly approved.

## Known backup path to verify after future reopen

After mount, the future apply phase should verify the latest known backup bundle path exists:

`/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z`

It should verify presence only unless a separate backup verification phase is approved.

## Abort blockers

The future apply phase must abort before unlocking or mounting if any of these are true:

- approval phrase is missing or stale;
- public status is not HTTP 200;
- public overall state is not online;
- node IDs are not `ct-203,ct-204,pvew,vm-200`;
- public private storage policy is not `manual-unlock-only`;
- public status explicitly marks CT204 `data_authority=true`;
- PVEW is not reachable;
- remote user is not root;
- `/srv/apc-private-data` is already mounted unexpectedly;
- `/dev/mapper/apc_private_data` already exists unexpectedly;
- CT203 is not running;
- CT203 service is not active/enabled;
- VM200 is not running;
- CT204 is not stopped;
- no LUKS candidate is found;
- multiple LUKS candidates are found without exact explicit device selection;
- passphrase would be printed or logged;
- any command would write crypttab, fstab, keyfiles, auto-unlock, or auto-mount configuration.

## Post-reopen verification

After any future successful reopen, verify:

- `/srv/apc-private-data` is mounted;
- backing source is `/dev/mapper/apc_private_data`;
- filesystem is ext4;
- mountpoint mode/owner/group is `700 root root`;
- latest known backup bundle path is present;
- CT203 service remains active/enabled;
- VM200 remains running;
- CT204 remains stopped;
- public `/system/status` remains HTTP 200;
- public storage status remains `policy=manual-unlock-only` and `mount_state=unknown`;
- no Cloudflare/DNS/tunnel mutation occurred;
- no service restart/reload occurred;
- no backup, restore, DB migration, worker activation, or PVESO wake occurred.

## Result

This phase creates the no-apply private storage reopen procedure plan only.

RESULT=PASS_PHASE_14J_MX_PVEW_PRIVATE_STORAGE_REOPEN_PROCEDURE_PLAN_NO_APPLY_DOC_READY
