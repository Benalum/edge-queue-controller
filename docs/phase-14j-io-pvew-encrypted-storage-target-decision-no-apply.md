# Phase 14J-IO - PVEW Encrypted Storage Target Decision, No Apply

## Scope

This phase records the storage target decision before any encrypted-at-rest storage mutation.

No CT/VM create, start, stop, clone, delete, modify, storage create, storage format, storage mount, storage resize, storage enable, storage disable, encryption setup, key generation, key installation, DB dump, DB copy, DB import, DB migration, service activation, onboot/autostart mutation, VM200 mutation, public route mutation, Cloudflare/DNS/tunnel mutation, PVESO power action, CT101/model/Ollama/worker call, laptop controller pause, laptop DB mutation, or production job mutation is approved or performed by this phase.

## Current completed state

Completed and recorded:

- CT203 edge-controller-pvew exists.
- CT203 is stopped.
- CT203 onboot is 0.
- CT203 is non-authoritative.
- CT204 edge-data-pvew exists.
- CT204 is stopped.
- CT204 onboot is 0.
- CT204 is non-authoritative.
- VM200 website-edge remains running.
- Laptop controller and laptop DB remain live authority.
- No platform data has been migrated to PVEW.
- No encrypted storage has been created.
- No service activation has occurred.

## Current storage evidence

The latest read-only checks show:

- PVEW local SSD is small.
- PVEW local-lvm is active but has a thin-pool overcommit risk.
- VG pve free space was 13.63 GiB.
- Thin autoextend threshold was 100.
- data-2tb is disabled and scoped to pveso.
- No usable 2TB PVEW data disk was visible.
- vm-9300-disk-0 and vm-9300-disk-1 exist on local-lvm but have no matching qm or pct guest config.
- vm-9300 volumes must not be reused or deleted without a separate explicit boundary.

## Decision

Do not create encrypted storage on PVEW local-lvm yet.

Do not use data-2tb on PVEW.

Do not reuse or delete vm-9300 volumes.

The preferred next path is to add or attach a dedicated data disk to PVEW and then create an encrypted data volume on that dedicated disk under a later explicit approval.

## Recommended storage target

Preferred target:

- dedicated disk physically attached to PVEW;
- not VM200 website-edge storage;
- not local-lvm root storage;
- not data-2tb unless separately rehomed and verified;
- not orphan-looking vm-9300 volumes;
- encrypted with LUKS or equivalent block/filesystem-level encryption;
- manually unlocked first;
- mounted only for private data paths;
- not exposed to public routes or Cloudflare tunnels.

## Why container root disks remain acceptable

CT203 and CT204 root disks can remain plain because they currently contain only base OS/container files and no migrated private platform data.

The at-rest requirement is satisfied by ensuring sensitive data paths live on encrypted storage before any real platform data is moved.

## Future sensitive data paths

Sensitive paths that should be placed on encrypted storage before migration include:

- PostgreSQL data directory.
- SQLite controller DB copy if used.
- Redis persistence if used.
- backups.
- uploads.
- study files.
- job artifacts.
- queue snapshots.
- migration staging files.
- persistent secrets that are not better handled by manual runtime injection.

## Approval paths

Path A: dedicated disk attach and read-only discovery.

- Physically attach a data disk to PVEW.
- Run a read-only disk discovery block.
- Do not format, mount, encrypt, or use it yet.

Path B: local-lvm exception.

- Explicitly accept local-lvm capacity and thin-pool risks.
- Create a small encrypted data volume on local-lvm.
- This is not recommended without resolving the thin-pool risk.

Path C: data-2tb rehome.

- Separately inspect pveso/data-2tb ownership and purpose.
- Decide whether it can be moved or recreated for PVEW.
- This is higher risk and not recommended before source/backup clarity.

Path D: pause storage migration.

- Keep CT203/CT204 empty.
- Continue non-storage planning.
- Resume once a dedicated disk is available.

## Recommended next action

Use Path A.

Attach a dedicated data disk to PVEW, then run read-only disk discovery.

No encryption, formatting, mounting, DB migration, or service startup should happen until the new disk is clearly identified and recorded.

## Still blocked

The following remain blocked until separate explicit real-mutation approval:

- encrypted storage creation;
- disk formatting;
- disk mounting;
- key generation or installation;
- local-lvm allocation for data;
- vm-9300 deletion or reuse;
- data-2tb enablement or reuse;
- DB dump/copy/import/migration;
- service activation;
- onboot/autostart changes;
- public route changes;
- PVESO shutdown.

## Result

PASS_PVEW_ENCRYPTED_STORAGE_TARGET_DECISION_NO_APPLY
