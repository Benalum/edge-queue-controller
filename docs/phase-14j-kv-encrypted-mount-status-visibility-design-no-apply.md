# Phase 14J-KV — Encrypted mount status visibility design no-apply

Date: 2026-06-18

## Scope

No-apply design checkpoint for showing encrypted backup mount status in the admin/system UI.

## KU finding

The natural backend insertion point is /system/status in edge_controller.py.

However CT203 runs inside a container and cannot directly inspect the PVEW host mount /srv/apc-private-data unless an explicit host-visible signal, bind mount, or host probe is added.

## Policy

Do not fake mount visibility from CT203 by checking a CT-local path.

Do not add auto-unlock, keyfiles, crypttab, fstab, or storage systemd persistence.

Do not use model/job/power execution paths for storage status.

## Preferred future design

Add a public-safe host storage status signal that exposes only non-secret facts:

- mounted true/false/unknown,
- mountpoint name,
- status checked timestamp,
- policy manual-unlock-only,
- CT204 remains stopped/data-only.

The signal should not expose device UUIDs, passphrases, keys, raw disks, or private file inventory.

## Implementation options

Option A: admin UI displays static policy only. Lowest risk, least useful.

Option B: PVEW host writes a non-secret marker file after manual unlock/mount. CT203 reads it through a tightly scoped read-only bind mount. Recommended later.

Option C: CT203 probes the PVEW host over SSH for findmnt status. Not preferred until separately threat-modeled.

## Recommended next apply phase

Add static policy visibility to /system/status first, with mount_state=unknown and policy=manual-unlock-only. This requires only backend source change and service reload after explicit approval.
