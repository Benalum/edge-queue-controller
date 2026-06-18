# Phase 14J-JM - CT204 Bind-Mount Pre-Apply Inspection Record

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_record

This phase records the completed read-only pre-apply inspection for a future CT204 read-only bind mount to PVEW encrypted private storage.

The recording phase itself does not mutate CT config, add a bind mount, start CT203/CT204, restore/import/migrate any DB, move controller authority, expose private data to VM200, mutate Proxmox storage, mutate persistence, or wake PVESO.

## Current checkpoint before inspection

- Phase 14J-JL
- Commit 66f5b82
- Tag controller-phase-14j-jl-ct204-bind-mount-design-no-apply-2026-06-18

## Inspection result

Read-only inspection result:

- PASS_PHASE_14J_JM_CT204_BIND_MOUNT_PREAPPLY_INSPECTION_READ_ONLY

## Quorum/config context

Observed PVEW cluster context:

- Quorate: Yes
- Expected votes: 1
- Total votes: 1
- Quorum: 1

Important note: Expected votes 1 remains a temporary PVEW single-node working state and should be normalized or deliberately documented before final production posture.

## Encrypted mount state

Observed:

- Mount path: /srv/apc-private-data
- Source: /dev/mapper/apc_private_data
- Filesystem: ext4
- Options: rw,relatime
- Owner/group: root:root
- Permissions: 700

Result:

- PASS: encrypted private mount active and root-only

## CT204 scaffold state

Observed private scaffold:

- /srv/apc-private-data/ct204
- /srv/apc-private-data/ct204/backups
- /srv/apc-private-data/ct204/staging
- /srv/apc-private-data/ct204/manifests
- /srv/apc-private-data/ct204/exports

All observed as root-owned/private.

Result:

- PASS: CT204 host scaffold exists and is private

## VM/CT boundary state

Observed:

- VM200: running
- CT203: stopped
- CT204: stopped

Result:

- PASS: VM200 running, CT203/CT204 stopped

## CT204 config state

Observed CT204 config summary:

- hostname: edge-data-pvew
- onboot: 0
- rootfs: local-lvm:vm-204-disk-0,size=8G
- unprivileged: 1
- existing mp entries: none

Result:

- PASS: CT204 is unprivileged
- PASS: no CT204 bind-mount conflict detected

## Candidate bind mount

Candidate future read-only config:

- candidate slot: mp0
- host path: /srv/apc-private-data/ct204
- CT path: /mnt/apc-private-data
- mode: ro=1

Candidate config:

```text
mp0: /srv/apc-private-data/ct204,mp=/mnt/apc-private-data,ro=1

Result:

PASS: candidate read-only bind mount can be represented without conflict
VM200 isolation

Observed:

VM200 config does not reference /srv/apc-private-data.

Result:

PASS: VM200 config does not reference private data path
Persistence boundary

Observed:

no /etc/crypttab persistence for private mount
no /etc/fstab persistence for private mount

Result:

PASS: no crypttab/fstab persistence for private mount
Proxmox storage context

Observed:

data-2tb: disabled
local: active
local-lvm: active

No pvesm add/set occurred.

Future approval phrase

APPROVE_PHASE_14J_JN_APPLY_CT204_READONLY_BIND_MOUNT_TO_PVEW_ENCRYPTED_STORAGE_NO_START

That future approval allows only adding the read-only CT204 bind mount while CT204 remains stopped.

It must not:

start CT204;
start CT203;
restore/import/migrate any DB;
move controller authority;
expose private data to VM200;
add Proxmox storage;
mutate crypttab/fstab;
create keyfiles;
wake PVESO.
Stop conditions before future apply

Stop before applying if:

repo is dirty;
PVEW is not quorate;
encrypted mount is not active;
CT204 is running;
CT204 has any conflicting mp entry;
VM200 references /srv/apc-private-data;
/srv/apc-private-data/ct204 is missing or not private.
