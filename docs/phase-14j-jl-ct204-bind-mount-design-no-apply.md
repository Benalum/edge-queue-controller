# Phase 14J-JL - CT204 Bind-Mount Design, No Apply

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase designs a future CT204 bind mount to the PVEW encrypted private storage scaffold.

This phase does not mutate CT config, add a bind mount, start CT204, restore/import any DB, move controller authority, expose private data to VM200, mutate Proxmox storage, mutate persistence, or wake PVESO.

## Current checkpoint

- Phase 14J-JK
- Commit 6feaf18
- Tag controller-phase-14j-jk-controller-db-backup-retrieval-rehearsal-record-2026-06-18

## Current proven state

- PVEW encrypted storage is active at /srv/apc-private-data.
- Root-only unlock/mount helper exists at /root/apc-private-storage-unlock-mount.sh.
- CT204 private scaffold exists at /srv/apc-private-data/ct204.
- Controller backup exists under /srv/apc-private-data/ct204/backups/controller-laptop.
- Backup retrieval rehearsal passed with SQLite integrity ok.
- Live laptop edge_queue.sqlite3 remained unchanged.
- CT203 remains stopped.
- CT204 remains stopped.
- VM200 remains public/static only and has no private data access.

## Future bind-mount objective

Future CT204 bind mount should make the encrypted CT204 scaffold available inside CT204 only, after explicit approval.

Candidate mapping:

- Host path: /srv/apc-private-data/ct204
- CT204 path: /mnt/apc-private-data
- Access posture: private CT204-only data/backups path
- Initial mode: read-only preferred for first rehearsal, then read/write only after a separate approval

## Required pre-apply inspection

Before any bind mount is applied, run a read-only CT204 inspection to verify:

- CT204 exists and is stopped;
- CT204 is unprivileged;
- current CT204 config has no existing conflicting mp entries;
- proposed mount path is not already used;
- host path exists and is root-owned/private;
- encrypted mount is active;
- VM200 has no access to /srv/apc-private-data;
- CT203 remains stopped.

## Future approval phrase

APPROVE_PHASE_14J_JM_APPLY_CT204_READONLY_BIND_MOUNT_TO_PVEW_ENCRYPTED_STORAGE_NO_START

That future approval allows only a CT204 config bind-mount addition in read-only mode while CT204 remains stopped.

It must not:

- start CT204;
- restore/import a DB;
- change controller authority;
- add VM200 access;
- add Proxmox storage;
- mutate crypttab/fstab;
- create a keyfile;
- wake PVESO.

## Later separate approvals

Separate approvals are still required for:

1. starting CT204;
2. writeable CT204 bind mount;
3. importing/restoring a DB into CT204;
4. moving controller authority;
5. adding automated backup jobs;
6. adding crypttab/fstab or systemd persistence.

## Stop conditions

Stop before applying any bind mount if:

- CT204 is running unexpectedly;
- encrypted storage is not mounted;
- /srv/apc-private-data/ct204 is missing or not private;
- existing CT204 mp entries conflict;
- VM200 has private data access;
- repo is dirty;
- quorum state prevents safe Proxmox config mutation.
