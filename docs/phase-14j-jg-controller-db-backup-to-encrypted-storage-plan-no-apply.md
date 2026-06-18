# Phase 14J-JG - Controller DB Backup to Encrypted Storage Plan, No Apply

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase plans a future backup/copy of the laptop controller SQLite DB to PVEW encrypted storage. It does not dump, copy, import, migrate, or change controller authority.

## Current checkpoint

- Phase 14J-JF
- Commit 9db2a78
- Tag controller-phase-14j-jf-ct204-private-data-directories-record-2026-06-18

## Current state

- Laptop-local edge_queue.sqlite3 remains live controller data authority.
- PVEW encrypted storage is mounted at /srv/apc-private-data.
- CT204 scaffold exists at /srv/apc-private-data/ct204.
- CT203 remains stopped.
- CT204 remains stopped.
- VM200 remains public/static only and has no private data access.
- No Proxmox storage add/set occurred.
- No crypttab/fstab persistence exists for the private storage.

## Future backup target

Preferred future backup directory:

- /srv/apc-private-data/ct204/backups/controller-laptop

Planned future artifacts:

- timestamped SQLite backup copied from laptop controller;
- manifest with source path, repo commit, size, sha256, and timestamp;
- no import and no authority change.

## Future approval phrase

APPROVE_PHASE_14J_JH_CREATE_CONTROLLER_SQLITE_BACKUP_ON_PVEW_ENCRYPTED_STORAGE_NO_AUTHORITY_CHANGE

That future approval allows only a backup/copy into encrypted storage. It must not:

- stop or restart controller services;
- import DB into another runtime;
- change data authority;
- start CT203 or CT204;
- add CT bind mounts;
- expose data to VM200;
- add Proxmox storage;
- mutate crypttab/fstab;
- wake PVESO.

## Stop conditions for future backup

Stop if:

- repo is dirty;
- laptop DB path is missing;
- PVEW encrypted mount is not active;
- target backup directory is missing or not private;
- CT203 or CT204 is running unexpectedly;
- VM200 has private data access;
- any secret or DB content would be printed.
