# Phase 14J-JD - PVEW Root-Only Private Storage Helper Record

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_record

This phase records the completed creation and verification of the root-only private storage unlock/mount helper on PVEW.

The recording phase itself does not mutate PVEW, disks, encryption, mounts, keys, /etc/crypttab, /etc/fstab, services, timers, Proxmox storage, VM200, CT203, CT204, databases, routes, tunnels, DNS, or PVESO.

## Approval boundary used

APPROVE_PHASE_14J_JD_CREATE_ROOT_ONLY_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER_NO_SECRETS

## Completed helper

Created on PVEW:

- Helper path: /root/apc-private-storage-unlock-mount.sh
- Owner/group: root:root
- Permissions: 700
- Embedded secrets: none
- Keyfile creation: none
- /etc/crypttab mutation: none
- /etc/fstab mutation: none
- systemd service/timer creation: none
- Proxmox storage mutation: none

## Helper behavior

The helper:

- verifies the Hitachi HDD by-id path;
- verifies the target partition label apc-private-luks;
- verifies the partition is crypto_LUKS;
- opens mapper apc_private_data only if inactive;
- mounts /srv/apc-private-data only if not already mounted;
- verifies /srv/apc-private-data is mounted from apc_private_data;
- enforces 700 permissions on /srv/apc-private-data;
- preserves the README marker permissions when present.

## Verification result

The helper was executed while the mapper and mount were already active.

Observed result:

- mapper_state=already_open
- mount_state=already_mounted
- source: /dev/mapper/apc_private_data
- target: /srv/apc-private-data
- filesystem: ext4
- options: rw,relatime
- PASS_APC_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER
- PASS_NO_PERSISTENCE_BOUNDARIES_UNCHANGED
- PASS_PHASE_14J_JD_CREATE_ROOT_ONLY_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER_NO_SECRETS

## Boundary state after helper creation

Still true after Phase 14J-JD:

- no keyfile exists;
- no passphrase was printed or stored;
- no /etc/crypttab persistence was added;
- no /etc/fstab persistence was added;
- no systemd service/timer was created;
- no pvesm add/set occurred;
- no DB dump, copy, import, migration, or controller authority move occurred;
- CT203 remains stopped;
- CT204 remains stopped;
- VM200 remains public/static only and has no private HDD access;
- PVESO remains offline unless separately approved.

## Operational runbook note

If PVEW reboots, the encrypted storage will not auto-open or auto-mount.

Manual recovery path after reboot:

1. SSH to PVEW as root.
2. Run /root/apc-private-storage-unlock-mount.sh.
3. Enter the LUKS passphrase at the cryptsetup prompt.
4. Verify PASS_APC_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER.

Do not paste the passphrase into ChatGPT, git, logs, Source files, APC_LAST_OUTPUT, VM200, Cloudflare, or any tunnel config.

## Next planning targets

Recommended next safe phases:

1. no-apply CT204 private data/backups directory plan;
2. no-apply laptop controller DB backup/copy plan to encrypted storage;
3. no-apply PVEW cluster quorum normalization plan;
4. source refresh/new-chat handoff after the next stable milestone.
