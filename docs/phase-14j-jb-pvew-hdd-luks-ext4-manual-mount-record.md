# Phase 14J-JB - PVEW HDD LUKS/ext4 Manual Mount Record

Date: 2026-06-18

## Scope

This phase records the completed Phase 14J-JA storage mutation.

MUTATION_SCOPE: docs_smoke_only_record

This phase itself is docs/smoke only and does not modify disks, encryption, filesystems, mounts, keys, Proxmox storage, VM200, CT203, CT204, databases, routes, tunnels, DNS, or PVESO.

## Approval boundary used

APPROVE_PHASE_14J_JA_PVEW_HDD_WIPE_LUKS_CREATE_MANUAL_UNLOCK_ONLY

## Completed result

The dedicated PVEW Hitachi HDD was converted from old NTFS signatures into private encrypted storage.

Target disk:

- Stable disk path: /dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD
- Target partition path: /dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD-part1
- Model: Hitachi HDS721010CLA332
- Serial: JP2940J81AMYSD

Completed layout:

- Disk: GPT
- Partition: one data partition
- Partition label: apc-private-luks
- Partition type/content: crypto_LUKS
- LUKS mapper name: apc_private_data
- LUKS UUID: a033a91a-7635-4b60-97d5-db7731861a9f
- Filesystem: ext4
- Filesystem label: apc-private-data
- Filesystem UUID: 6787d385-bd40-4cca-81a1-0e1bc62b6157
- Manual mount path: /srv/apc-private-data

## Final verification evidence

The final read-only verification showed:

- /dev/sdb1 is crypto_LUKS.
- /dev/mapper/apc_private_data is active and in use.
- /dev/mapper/apc_private_data is ext4 labeled apc-private-data.
- /srv/apc-private-data is mounted read/write as ext4.
- /srv/apc-private-data permissions are 700.
- README.apc-private-storage.txt exists with permissions 600.
- No NTFS signatures remain on the target disk.
- VM200 website-edge remains running.
- VM200 uses only local-lvm vm-200-disk-0 and has no private HDD mount.
- CT203 remains stopped.
- CT204 remains stopped.
- Proxmox storage remains unchanged.
- No /etc/crypttab persistence was added.
- No /etc/fstab persistence was added.
- No database dump, copy, import, migration, or controller authority move occurred.
- No keyfile was created.
- No secret was recorded in the repository or Source files.

## Operational note

The encrypted storage is currently manual/nonpersistent.

After a PVEW reboot, this storage will need a separate unlock and mount step unless a later persistence plan is explicitly approved.

Do not reboot PVEW casually until the next storage persistence/unlock plan is decided.

## Next allowed planning targets

The next safe planning targets are:

1. no-apply persistence design for manual unlock plus controlled mount;
2. CT204 private data/backups candidate usage plan;
3. laptop controller DB backup/copy plan to encrypted storage;
4. cluster quorum normalization plan.

Each runtime/data-authority/persistence change still requires a separate explicit approval boundary.
