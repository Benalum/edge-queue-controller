# Phase 14J-ID - PVEW encryption implementation comparison, no apply

Date: 2026-06-17

## Scope

Docs/smoke only. No storage mutation, key generation, data migration, CT/VM mutation, service mutation, route mutation, PVESO shutdown, or laptop authority removal.

Base checkpoint: Phase 14J-IC, commit f469a0c.

## Goal

Compare encryption-at-rest options before creating any PVEW private controller/data candidate or moving any user/platform data.

## Option A - Dedicated LUKS-backed data volume

Summary: create a dedicated encrypted block device or logical volume for private controller/data storage.

Pros:
- strong filesystem-level encryption boundary;
- simple mental model;
- protects database and backups stored inside the encrypted boundary;
- good first implementation for private CT data.

Cons:
- unlock procedure must be designed;
- automatic unlock may weaken security;
- storage creation and formatting require a later real-mutation boundary.

Initial preference: recommended first path.

## Option B - Application-level encryption

Summary: encrypt selected sensitive fields before writing to the database.

Pros:
- protects sensitive fields even if DB file is copied;
- useful future layer for highly sensitive profile or message fields.

Cons:
- more application code complexity;
- does not protect all DB metadata by itself;
- key rotation and search/index behavior are harder.

Initial preference: useful later as a second layer, not the first migration blocker.

## Option C - Encrypted backup artifacts only

Summary: keep live storage unchanged but encrypt exported backups.

Pros:
- improves backup safety;
- useful regardless of live storage design.

Cons:
- does not protect the live database at rest;
- not enough for PVEW data authority.

Initial preference: required for backups, but insufficient alone.

## Option D - Host-wide encryption

Summary: encrypt the whole PVEW host storage.

Pros:
- broad protection if the physical disk is stolen;
- simple once installed from scratch.

Cons:
- may require reinstall or disruptive host-level changes;
- harder to apply safely to an existing always-on host with VM200 running.

Initial preference: consider later, not the immediate migration path.

## Decision

Preferred first design path:

1. dedicated encrypted data volume for private controller/data;
2. encrypted backups;
3. manual unlock after boot for the first version;
4. application-level encryption later for selected sensitive fields.

## Hard rules

- no keys in ChatGPT;
- no keys in repo;
- no keys in Source files;
- no keys in APC_LAST_OUTPUT;
- no keys in website-edge;
- no user data inside website-edge;
- no migration until encryption is applied and verified under explicit approval.

## Next no-apply step

Define the PVEW target candidate layout, including CT IDs, storage boundary, backup boundary, and private/public route boundary.

Do not create CTs, create encrypted volumes, generate keys, migrate data, stop PVESO, or alter public routes.
