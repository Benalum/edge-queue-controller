# Phase 14J-JE - CT204 Private Data/Backups Plan, No Apply

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase plans CT204 private data/backups usage on the PVEW encrypted HDD. It does not create directories, start containers, add bind mounts, migrate databases, copy data, change controller authority, mutate Proxmox storage, expose VM200 to private data, mutate persistence, wake PVESO, or change routes.

## Current checkpoint

Latest committed checkpoint:

- Phase 14J-JD
- Commit 3935f45
- Tag controller-phase-14j-jd-pvew-root-only-private-storage-helper-record-2026-06-18

Current private storage:

- Encrypted mount path: /srv/apc-private-data
- LUKS mapper: apc_private_data
- Filesystem: ext4
- Filesystem label: apc-private-data
- Unlock helper: /root/apc-private-storage-unlock-mount.sh
- Helper permissions: root:root 700
- No keyfile, crypttab, fstab, service, or timer persistence

## Planned CT204 private data layout

Later, after separate approval, create root-owned private directories under:

- /srv/apc-private-data/ct204
- /srv/apc-private-data/ct204/backups
- /srv/apc-private-data/ct204/staging
- /srv/apc-private-data/ct204/manifests
- /srv/apc-private-data/ct204/exports

Initial permissions should be root-only unless a later CT204 bind-mount plan requires narrower UID/GID mapping.

## Boundaries

CT204 remains stopped and non-authoritative.

The future directory-creation boundary may create directories and marker files only. It must not:

- start CT204;
- add CT204 bind mounts;
- migrate the laptop controller DB;
- copy production controller data;
- move controller authority;
- add Proxmox storage;
- add crypttab or fstab persistence;
- give VM200 access to private data;
- wake PVESO.

## Required future approval phrase

APPROVE_PHASE_14J_JF_CREATE_CT204_PRIVATE_DATA_BACKUP_DIRECTORIES_ONLY

That future approval allows only directory and marker creation under /srv/apc-private-data/ct204 while the encrypted mount is already active.

## Later separate approvals

Separate approvals are required for:

1. CT204 bind mount configuration;
2. CT204 start;
3. laptop controller DB backup/copy into encrypted storage;
4. controller data authority migration;
5. automated backup jobs;
6. crypttab/fstab or service persistence;
7. Proxmox storage add/set.

## Safety notes

Do not use VM200 for private data.

Do not use local-lvm as the private data target.

Do not treat CT204 as authoritative until a later data-authority cutover is explicitly approved.

Do not reboot PVEW casually while the encrypted mount is manual/nonpersistent.
