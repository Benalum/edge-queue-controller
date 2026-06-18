# Phase 14J-IQ - PVEW Dedicated Data Disk Attach Gate, No Apply

## Scope

This phase records the gate after Phase 14J-IP confirmed that PVEW currently has no dedicated candidate data disk.

No CT/VM create, start, stop, clone, delete, modify, storage create, storage format, storage mount, storage resize, storage enable, storage disable, encryption setup, key generation, key installation, DB dump, DB copy, DB import, DB migration, service activation, onboot/autostart mutation, VM200 mutation, public route mutation, Cloudflare/DNS/tunnel mutation, PVESO power action, CT101/model/Ollama/worker call, laptop controller pause, laptop DB mutation, or production job mutation is approved or performed by this phase.

## Current blocker

Phase 14J-IP found:

- PVEW sees only the 111.8G PNY CS900 system disk.
- candidate_data_disk_count=0.
- data-2tb remains disabled and unavailable on PVEW.
- local-lvm remains unsuitable for encrypted data allocation due to prior thin-pool and free-space risk.
- vm-9300 volumes remain unknown and must not be reused or deleted.

## Decision

Encrypted storage creation is blocked until a dedicated PVEW data disk is attached or provisioned and then verified read-only.

## Preferred next action outside this repository

Attach or provision a dedicated data disk for PVEW.

Acceptable forms:

- a physical disk installed in the PVEW host;
- a USB/SATA/NVMe disk attached directly to PVEW;
- a clearly dedicated virtual disk if PVEW itself later runs nested or under a different hypervisor setup.

The disk should be dedicated to private platform data and backups.

The disk should not be VM200 website-edge storage, should not be public-route storage, and should not contain Cloudflare tunnel material.

## Required post-attach rule

After the disk is attached, run read-only disk discovery first.

Do not format, mount, encrypt, enable as Proxmox storage, create LVM, create filesystem, or write to the disk until the disk is clearly identified and a separate explicit mutation approval exists.

## Desired encrypted-at-rest path after discovery

Later approved sequence should be:

1. read-only disk discovery confirms the new disk identity;
2. docs/smoke records the disk identity;
3. explicit approval for encrypted storage creation;
4. manual LUKS setup without printing keys;
5. manual unlock verification;
6. mount path verification;
7. docs/smoke records encrypted storage result;
8. no-apply DB/data migration plan;
9. explicit data backup/export/import boundary;
10. private candidate service activation boundary;
11. candidate validation;
12. authority cutover boundary;
13. PVESO shutdown only after rollback checks pass.

## Key handling rules

Keys must not be pasted into ChatGPT, committed to git, written into Source files, stored in APC_LAST_OUTPUT, printed in terminal output, stored in VM200 website-edge, placed in Cloudflare/tunnel config, or exposed through public routes.

Manual unlock comes before any automatic unlock design.

## Still blocked

The following remain blocked until separate explicit real-mutation approval:

- encrypted storage creation;
- disk formatting;
- disk mounting;
- key generation or installation;
- Proxmox storage enablement;
- local-lvm allocation for data;
- vm-9300 deletion or reuse;
- data-2tb enablement or reuse;
- DB dump/copy/import/migration;
- service activation;
- onboot/autostart changes;
- public route changes;
- PVESO shutdown.

## Result

PASS_PVEW_DEDICATED_DATA_DISK_ATTACH_GATE_NO_APPLY
