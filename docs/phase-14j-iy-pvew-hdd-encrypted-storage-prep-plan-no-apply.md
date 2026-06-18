# Phase 14J-IY - PVEW HDD Encrypted Storage Prep Plan, No Apply

Date: 2026-06-18

## Scope

This phase records the post-install HDD identity, health posture, and the next explicit storage/encryption boundary.

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase does not format, mount, wipe, encrypt, create keys, create LVM, add Proxmox storage, start CT203/CT204, migrate data, mutate VM200 content, mutate Cloudflare/DNS/tunnel routes, or wake PVESO.

## Current confirmed platform state

- Latest prior committed repo checkpoint: Phase 14J-IQ at commit 177149f.
- Phase 14J-IR: PVEW was shut down for physical HDD install.
- Phase 14J-IS: post-install read-only disk discovery completed.
- Phase 14J-IU: SMART health read-only check completed.
- Phase 14J-IW: PVEW temporary expected votes set to 1 and VM200 started/onboot enabled.
- Phase 14J-IX-R2: VM200 website-edge read-only verification passed.
- PVEW is temporarily quorate with expected votes 1 while PVESO remains offline.
- VM200 website-edge is running and onboot 1.
- CT203 edge-controller-pvew remains stopped and non-authoritative.
- CT204 edge-data-pvew remains stopped and non-authoritative.
- The HDD remains unmounted and has not been added as Proxmox storage.

## HDD identity

Dedicated PVEW HDD candidate:

- Kernel path observed: /dev/sdb
- Stable by-id path: /dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD
- Model: Hitachi HDS721010CLA332
- Model family: Hitachi Deskstar 7K1000.C
- Serial: JP2940J81AMYSD
- Capacity: 1,000,204,886,016 bytes / 1.00 TB / 931.5 GiB
- Transport: SATA
- Sector size: 512 bytes logical/physical
- Rotation rate: 7200 rpm
- WWN: wwn-0x5000cca396d2ee24

## Existing signatures

The HDD is not blank from the current evidence.

Observed existing partitions/signatures:

- /dev/sdb1: 100 MiB NTFS, label System Reserved
- /dev/sdb2: 931.4 GiB NTFS
- No target partitions were mounted during discovery or verification.

These existing NTFS signatures must be intentionally wiped only under a later explicit storage boundary.

## SMART health posture

Read-only SMART check result:

- SMART support: available and enabled
- SMART overall-health self-assessment: PASSED
- Power_On_Hours: 13256
- Start_Stop_Count: 3408
- Power_Cycle_Count: 2747
- Temperature at check: 26 C
- Reallocated_Sector_Ct: 1
- Reallocated_Event_Count: 1
- Current_Pending_Sector: 0
- Offline_Uncorrectable: 0
- UDMA_CRC_Error_Count: 0
- SMART error log: no errors logged
- SMART self-test log: no self-tests logged

Decision posture: acceptable as a candidate for encrypted backups/private data with monitoring and backups, but not as the only copy of important data.

## Next no-apply design target

Preferred storage design direction:

1. Confirm by-id path before every storage mutation.
2. Wipe old NTFS signatures intentionally.
3. Create a new GPT layout.
4. Create a LUKS container on the dedicated HDD.
5. Use manual unlock first.
6. Create an ext4 or XFS filesystem inside the unlocked encrypted mapper device, or create an LVM-on-LUKS layout if needed.
7. Mount under a private PVEW path not exposed by VM200.
8. Keep encryption keys/passphrases out of ChatGPT, git, Source files, terminal output, APC_LAST_OUTPUT, website-edge, and Cloudflare/tunnel config.
9. Only after encrypted storage is verified, plan CT204 private data/backups usage.
10. Only after CT204/private storage is verified, plan laptop DB/data migration and authority cutover.

## Explicit future boundary required

The next storage mutation requires a separate explicit approval boundary and must include:

- exact target disk by-id path;
- final wipe plan;
- final encryption layout;
- key/passphrase handling plan that does not print or store secrets in logs;
- mount path;
- rollback/stop conditions;
- verification that VM200 remains public/static only;
- verification that CT203/CT204 remain non-authoritative unless separately approved.

## Hard blocks

- Do not use /dev/sdb directly when mutating storage; use the stable by-id path.
- Do not reuse/delete unknown vm-9300 volumes.
- Do not use local-lvm for private encrypted data in the current plan.
- Do not place private DBs, controller DBs, keys, private mounts, or controller authority inside VM200.
- Do not migrate data before encrypted storage exists and is verified.
- Do not wake PVESO unless compute/cluster work requires it under a separate boundary.
