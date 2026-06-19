# Phase 14J-MZ — CT204 Isolated Restore-Drill Procedure Plan No-Apply

Updated: 2026-06-18

## Status

NO-APPLY PLAN ONLY.

This phase does not unlock or mount private storage, open crypt, start CT204, restore a database, import data, migrate data, create backups, change data authority, restart services, change Cloudflare/DNS/tunnels, wake PVESO, or activate workers/models.

## Current baseline carried forward

Latest completed checkpoint before this plan:

- Phase: 14J-MX — PVEW Private Storage Reopen Procedure Plan No-Apply
- Commit: 4bb3ce8
- Tag: controller-phase-14j-mx-pvew-private-storage-reopen-procedure-plan-no-apply-2026-06-18
- Result: PASS_PHASE_14J_MX_PVEW_PRIVATE_STORAGE_REOPEN_PROCEDURE_PLAN_NO_APPLY_COMMIT_TAG_PUSH_DONE

Current platform state carried forward:

- PVEW private storage is locked/unmounted.
- `/srv/apc-private-data` is not mounted.
- `/dev/mapper/apc_private_data` is absent/closed.
- CT203 remains running and is controller/API/queue authority.
- CT203 `edge-queue-controller.service` remains active/enabled.
- VM200 remains running and public/static only.
- CT204 remains stopped, backup-data-only, and `data_authority=false`.
- PVESO remains parked/offline unless explicitly approved later.
- Public `/system/status` remains HTTP 200 and online.
- Public private storage status remains policy-only with `mount_state=unknown`.

## Purpose

Define a future isolated CT204 restore-drill procedure that can prove backup usability without promoting CT204 to data authority and without touching live CT203 data.

This plan is intentionally non-mutating. It creates only documentation and a smoke check.

## Restore-drill objective

A future restore drill should prove:

1. the latest verified CT203 backup bundle can be accessed after a separately approved private storage reopen;
2. the backup database file can be copied into an isolated CT204 drill location;
3. SQLite integrity can be verified in isolation;
4. table/page counts and expected schema indicators can be inspected;
5. CT204 remains non-authoritative;
6. no public route, Cloudflare route, DNS, tunnel, API authority, or data authority changes occur;
7. CT203 remains the live controller/API/queue authority throughout.

## Required phase separation

A future restore drill must be split into explicit boundaries:

### Boundary A — Reopen private storage

Use the already planned reopen procedure from Phase 14J-MX.

Suggested approval phrase:

`APPROVE_PHASE_14J_MY_REOPEN_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE`

This approval allows only the guarded reopen/mount procedure. It does not approve CT204 start or restore work.

### Boundary B — CT204 isolated restore drill

Suggested future approval phrase:

`APPROVE_PHASE_14J_NA_CT204_ISOLATED_RESTORE_DRILL_NO_AUTHORITY_NO_PUBLIC_ROUTE`

This approval should be requested only after private storage is already reopened and verified, or after a separate approved reopen phase completes.

### Boundary C — Storage re-lock

After restore-drill work, private storage should be locked again through a separate explicit storage lock approval, not implicitly.

## Future CT204 restore-drill allowed actions after approval

Only after explicit approval, a future isolated restore-drill phase may:

1. SSH to PVEW as root.
2. Verify public `/system/status` remains online and current.
3. Verify CT203 remains running and service active/enabled.
4. Verify VM200 remains running.
5. Verify CT204 is stopped before any CT204 action.
6. Verify private storage is mounted only if separately approved and already reopened.
7. Verify the known CT203 backup bundle exists:
   `/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z`
8. Start CT204 only if the explicit CT204 restore-drill approval is present.
9. Keep CT204 isolated and non-authoritative.
10. Copy or stage the backup database into a CT204 restore-drill-only path.
11. Run read-only SQLite integrity and schema checks against the staged copy.
12. Record counts, integrity result, and file metadata.
13. Stop CT204 again if the drill requires CT204 to be returned to stopped state.
14. Verify public status remains unchanged and CT204 remains non-authority.
15. Record sanitized output only.

## Future restore-drill forbidden actions even after approval

The future restore-drill phase must not:

- promote CT204 to data authority;
- replace CT203 DB;
- mutate CT203 DB;
- import into CT203;
- restore over live CT203 data;
- alter controller/API/queue authority;
- change public routes;
- change Cloudflare, DNS, tunnels, or cutover behavior;
- make CT204 public-facing;
- enable CT204 services as production authority;
- leave CT204 running unless explicitly approved in that phase;
- create a new backup unless separately approved;
- print secrets, env file contents, tokens, auth URLs, private IPs, Tailscale IPs, or MAC addresses;
- wake PVESO;
- activate workers or models;
- change crypttab, fstab, auto-unlock, auto-mount, or keyfiles.

## Required immediate preflight before future restore drill

The future apply phase must verify:

### Public status

- public `/system/status` HTTP 200;
- `overall_state=online`;
- `normalized.schema_version=2`;
- node IDs sorted `ct-203,ct-204,pvew,vm-200`;
- `private_storage_status.policy=manual-unlock-only`;
- `private_storage_status.mount_state=unknown`;
- `private_storage_status.mountpoint=/srv/apc-private-data`;
- `private_storage_status.ct204.expected_state=stopped`;
- `private_storage_status.ct204.data_authority=false`.

### PVEW direct state

- PVEW reachable through approved SSH target `pvew`;
- remote user is root;
- CT203 is running;
- CT203 `edge-queue-controller.service` is active/enabled;
- VM200 is running;
- CT204 is stopped before the drill;
- PVESO remains untouched.

### Private storage state

For a restore drill that needs the verified bundle, private storage must already be reopened through a separate approved phase.

Verify:

- `/srv/apc-private-data` is mounted;
- backing source is `/dev/mapper/apc_private_data`;
- filesystem is ext4;
- mountpoint mode/owner/group is `700 root root`;
- latest known CT203 backup bundle path exists;
- `SHA256SUMS` exists;
- manifest exists;
- env file contents are not printed.

### Backup drill source

Known latest verified backup bundle:

`/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z`

Known verification carried forward:

- SHA256 entries verified previously: 12 OK / 0 failed;
- SQLite integrity previously: ok;
- page count previously: 10692;
- table count previously: 40;
- env backup file mode previously: 600 root root;
- env contents were not printed.

The restore drill should re-check only what the approved scope allows.

## Isolation requirements

A CT204 restore drill must use a drill-only path and clear naming, such as:

- `/root/restore-drill/phase-14j-na/`
- `/tmp/apc-restore-drill/phase-14j-na/`

The drill must not write into any production CT203 path.

The drill must not set CT204 as data authority.

The drill must not alter public status to mark CT204 authoritative.

## Abort blockers

The future restore-drill phase must abort before mutation if any of these are true:

- approval phrase is missing or stale;
- public status is not HTTP 200;
- public overall state is not online;
- public node IDs are not `ct-203,ct-204,pvew,vm-200`;
- public status marks CT204 `data_authority=true`;
- CT203 is not running;
- CT203 service is not active/enabled;
- VM200 is not running;
- CT204 is not stopped before drill start;
- private storage is required but not mounted through an approved reopen phase;
- backup bundle path is missing;
- manifest or SHA256SUMS is missing;
- the phase would print env contents or secrets;
- the phase would modify CT203 live DB;
- the phase would promote CT204 authority;
- the phase would change public routes or Cloudflare/DNS/tunnels;
- the phase would wake PVESO or activate workers/models.

## Post-drill verification for future apply

After any future restore drill, verify:

- CT203 remains running;
- CT203 service remains active/enabled;
- VM200 remains running;
- CT204 is stopped again unless explicitly approved otherwise;
- CT204 remains `data_authority=false`;
- public `/system/status` remains HTTP 200 and online;
- public storage status remains policy-only;
- no public route/cutover change occurred;
- no Cloudflare/DNS/tunnel change occurred;
- no CT203 DB mutation occurred;
- no worker/model/PVESO activation occurred;
- drill artifacts are documented and isolated.

## Result

This phase creates the no-apply CT204 isolated restore-drill procedure plan only.

RESULT=PASS_PHASE_14J_MZ_CT204_ISOLATED_RESTORE_DRILL_PROCEDURE_PLAN_NO_APPLY_DOC_READY
