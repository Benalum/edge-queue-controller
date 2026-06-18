# Phase 14J-JF - CT204 Private Data Directories Record

Date: 2026-06-18

## Scope

MUTATION_SCOPE: docs_smoke_only_record

This phase records the completed creation of CT204 private data/backups directory scaffolding under the already-mounted PVEW encrypted storage.

The recording phase itself does not mutate PVEW, directories, bind mounts, containers, databases, controller authority, VM200, Proxmox storage, persistence, routes, tunnels, DNS, or PVESO.

## Approval boundary used

APPROVE_PHASE_14J_JF_CREATE_CT204_PRIVATE_DATA_BACKUP_DIRECTORIES_ONLY

## Completed directories

Created under the encrypted mount:

- /srv/apc-private-data/ct204
- /srv/apc-private-data/ct204/backups
- /srv/apc-private-data/ct204/staging
- /srv/apc-private-data/ct204/manifests
- /srv/apc-private-data/ct204/exports

All directories were verified as:

- owner/group: root:root
- permissions: 700

## Marker files

Created marker files:

- /srv/apc-private-data/ct204/README.ct204-private-data.txt
- /srv/apc-private-data/ct204/manifests/phase-14j-jf-directory-scaffold.marker

Marker permissions were set to 600.

## Boundary state after Phase 14J-JF

Still true after this phase:

- encrypted mount /srv/apc-private-data is active;
- mapper apc_private_data is active;
- VM200 is running and remains public/static only;
- CT203 remains stopped;
- CT204 remains stopped;
- no CT bind mount was added;
- no CT was started;
- no DB dump, copy, import, migration, or controller authority move occurred;
- no pvesm add/set occurred;
- no /etc/crypttab mutation occurred;
- no /etc/fstab mutation occurred;
- no keyfile was created;
- no Cloudflare, DNS, or tunnel mutation occurred;
- PVESO was not woken.

## Next planning targets

Recommended next safe phase:

- no-apply laptop controller DB backup/copy plan to encrypted storage.

Separate explicit approval remains required before any DB backup/copy, CT bind mount, CT start, controller authority migration, service activation, or persistence change.
