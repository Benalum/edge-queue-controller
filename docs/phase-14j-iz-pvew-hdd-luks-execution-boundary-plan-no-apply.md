# Phase 14J-IZ - PVEW HDD LUKS Execution Boundary Plan, No Apply

Date: 2026-06-18

## Scope

This phase records the exact approval boundary and safety checks for the later PVEW HDD encrypted-storage creation.

MUTATION_SCOPE: docs_smoke_only_no_apply

This phase does not modify disks, encryption, filesystems, keys, Proxmox storage, VM200 content, CT203, CT204, databases, routes, tunnels, DNS, or PVESO.

## Current checkpoint

Latest committed checkpoint before this phase:

- Phase 14J-IY
- Commit 6864cd4
- Tag controller-phase-14j-iy-pvew-hdd-encrypted-storage-prep-plan-no-apply-2026-06-18

Current live platform posture:

- PVEW is temporarily quorate with expected votes 1.
- VM200 website-edge is running and onboot 1.
- VM200 remains public/static only.
- CT203 edge-controller-pvew is stopped and non-authoritative.
- CT204 edge-data-pvew is stopped and non-authoritative.
- PVESO remains offline unless separately approved.
- Laptop-local edge_queue.sqlite3 remains the live controller data authority.

## Target disk identity

The only approved target candidate for the future storage mutation is:

- Stable by-id path: /dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD
- Kernel path observed during discovery: /dev/sdb
- Model: Hitachi HDS721010CLA332
- Serial: JP2940J81AMYSD
- Capacity: 1.00 TB / 931.5 GiB
- Existing signatures: old NTFS System Reserved partition and old NTFS data partition
- SMART posture: overall health passed, one reallocated sector, no pending sectors, no offline uncorrectable sectors, no SMART errors logged

The future mutation must re-confirm the by-id path immediately before any destructive action.

## Intended encrypted-storage layout

Preferred first implementation:

1. Confirm the disk by-id path resolves to the expected Hitachi disk.
2. Confirm no target partition is attached to the live filesystem tree.
3. Intentionally remove old NTFS signatures from the target disk.
4. Create a fresh partition table and one private data partition.
5. Create a LUKS2 encrypted container on that private data partition.
6. Use manual unlock first.
7. Create one Linux filesystem inside the unlocked encrypted container.
8. Attach it at a private PVEW-only data path.
9. Keep VM200 excluded from private data paths.
10. Keep CT203 and CT204 stopped until a later runtime/data plan.

## Secret handling rule

No encryption passphrase, recovery key, keyfile, random key material, or unlock secret may be printed, committed, pasted into ChatGPT, written into Source files, written into APC_LAST_OUTPUT, placed inside VM200, or placed in Cloudflare/tunnel config.

First implementation should use an interactive secret prompt on the PVEW host side, with terminal echo disabled by the underlying tool. The transcript must only show that a secret prompt happened, not the secret.

## Required future approval phrase

The future destructive storage boundary must not run until the user explicitly provides:

APPROVE_PHASE_14J_JA_PVEW_HDD_WIPE_LUKS_CREATE_MANUAL_UNLOCK_ONLY

That approval applies only to:

- the exact Hitachi by-id target listed above;
- removing old NTFS signatures from that target;
- creating the encrypted container;
- creating the initial filesystem inside the encrypted container;
- creating the private PVEW-only attach point;
- verifying the result read-only afterward.

That approval must not include:

- DB migration;
- controller authority migration;
- CT203 or CT204 runtime activation;
- VM200 private data access;
- Cloudflare, DNS, or tunnel changes;
- PVESO wake;
- deletion or reuse of vm-9300 volumes;
- use of local-lvm for private data.

## Stop conditions for the future mutation

Stop before destructive action if:

- the by-id path is missing;
- the by-id path resolves to a different model or serial;
- more than one plausible 1 TB candidate appears;
- any target partition is attached to the live filesystem tree;
- the disk shows new SMART pending or uncorrectable sectors;
- PVEW is not quorate when config changes are required;
- VM200 would gain access to private storage;
- CT203 or CT204 would be started unintentionally.

## Verification required after future mutation

The future verification must prove:

- the encrypted container exists;
- the encrypted filesystem is attached only at the intended private PVEW path;
- old NTFS signatures are gone from the target;
- VM200 still has no private data path;
- CT203 and CT204 remain stopped unless separately approved;
- Proxmox storage state is unchanged unless separately approved;
- laptop DB authority remains unchanged;
- no secrets appeared in logs.
