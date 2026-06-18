# Phase 14J-KS — Encrypted storage policy no-apply

Date: 2026-06-18

## Decision

Keep PVEW encrypted private storage manual-unlock only for now.

Do not add crypttab, fstab, keyfiles, TPM auto-unlock, network unlock, systemd auto-unlock, systemd auto-mount, or CT204 auto-start behavior.

## Current posture

- VM200 remains boot-persistent public edge.
- CT203 remains boot-persistent controller/API/queue candidate.
- CT204 remains stopped and backup/data-only.
- /srv/apc-private-data is available only after manual admin unlock/mount.
- Existing helper remains /root/apc-private-storage-unlock-mount.sh, mode 700, root-owned.

## Rationale

Manual unlock avoids storing disk unlock secrets on PVEW and keeps private backups unavailable after reboot until the admin intentionally unlocks them.

## Reboot expectation

After reboot, VM200 and CT203 should return automatically. Encrypted backup storage should not mount automatically. CT204 should remain stopped.

## Next recommended step

Add admin/status visibility for encrypted backup mount state without enabling auto-unlock.

## Non-goals

No storage persistence mutation, no keyfile, no passphrase storage, no CT204 authority change, no CT203 DB move, no reboot.
