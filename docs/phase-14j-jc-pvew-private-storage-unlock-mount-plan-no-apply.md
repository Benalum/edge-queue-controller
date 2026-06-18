# Phase 14J-JC - PVEW Private Storage Unlock/Mount Plan, No Apply

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase plans the next unlock/mount operational model for the PVEW private encrypted HDD. It does not modify disks, encryption, filesystems, mounts, keys, /etc/crypttab, /etc/fstab, systemd units, Proxmox storage, VM200, CT203, CT204, databases, routes, tunnels, DNS, or PVESO.

## Current checkpoint

Latest committed checkpoint:

- Phase 14J-JB
- Commit 1b005e6
- Tag controller-phase-14j-jb-pvew-hdd-luks-ext4-manual-mount-record-2026-06-18

Current private storage state:

- LUKS partition: /dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD-part1
- LUKS UUID: a033a91a-7635-4b60-97d5-db7731861a9f
- Mapper name: apc_private_data
- Filesystem: ext4
- Filesystem UUID: 6787d385-bd40-4cca-81a1-0e1bc62b6157
- Filesystem label: apc-private-data
- Manual mount path: /srv/apc-private-data

## Current operational posture

The encrypted storage is usable while PVEW remains running and the mapper remains open. It is intentionally manual/nonpersistent:

- no keyfile exists;
- no passphrase is stored;
- no /etc/crypttab entry exists;
- no /etc/fstab entry exists;
- no systemd unlock/mount unit exists;
- Proxmox storage was not changed;
- CT203 and CT204 remain stopped;
- VM200 has no private data access.

## Preferred near-term model

Use a manual root-only unlock and mount helper on PVEW, not automatic boot unlock.

Reasoning:

- avoids storing a keyfile on disk;
- avoids exposing private storage to VM200;
- keeps reboot behavior safe: encrypted data remains locked until explicitly unlocked;
- supports later CT204 backup/data use after a separate approval boundary.

## Future helper boundary

The future mutation should create a root-owned helper script only, with no embedded secrets:

- path: /root/apc-private-storage-unlock-mount.sh
- permissions: 700
- behavior: prompt interactively for LUKS passphrase, open mapper if inactive, mount /srv/apc-private-data if not mounted, verify permissions and marker
- no keyfile creation
- no crypttab mutation
- no fstab mutation
- no systemd service/timer enablement
- no CT203/CT204 start
- no data migration

Required future approval phrase:

APPROVE_PHASE_14J_JD_CREATE_ROOT_ONLY_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER_NO_SECRETS

## Later separate boundaries

Separate explicit approvals are still required for:

1. CT204 private data/backups candidate directory creation;
2. laptop controller DB backup/copy to encrypted storage;
3. controller data authority migration;
4. any /etc/crypttab or /etc/fstab persistence;
5. any keyfile or TPM-bound unlock design;
6. any Proxmox storage add/set;
7. any CT203/CT204 runtime activation.

## Reboot warning

Do not casually reboot PVEW until an unlock/mount runbook exists. A reboot should not lose encrypted data, but it will close the mapper and unmount /srv/apc-private-data.
