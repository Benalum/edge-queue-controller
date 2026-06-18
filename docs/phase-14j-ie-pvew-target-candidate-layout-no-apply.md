# Phase 14J-IE - PVEW target candidate layout, no apply

Date: 2026-06-17

## Scope

Docs/smoke only. No CT/VM creation, storage mutation, key generation, data migration, service activation, route mutation, PVESO shutdown, or laptop authority removal.

Base checkpoint: Phase 14J-ID, commit e712093.

## Target layout

PVEW should become the always-on host for lightweight platform roles:

- VM 200 `website-edge`: public/static edge only.
- CT203 `edge-controller-pvew`: future private controller candidate.
- CT204 `edge-data-pvew`: future private data/backups candidate.

PVESO should remain the on-demand compute host:

- CT101/model runtime/workers.
- GPU/heavy AI jobs.
- worker capacity only when needed.

## Isolation rules

`website-edge` must not contain user DB files, controller DB files, controller secrets, encryption keys, private data mounts, Proxmox management credentials, model secrets, worker secrets, or queue/controller authority.

CT203 and CT204 must stay private and non-authoritative until a later explicit migration/cutover boundary.

## Storage rule

CT204 or its attached data volume should own the encrypted private data boundary. CT203 may use that boundary only through a defined private mount/API plan.

Preferred first encryption path remains a dedicated encrypted data volume with manual unlock after boot.

## Authority rule

Current authority remains unchanged:

- laptop controller is still live controller/queue authority;
- laptop-local database is still live data authority;
- PVEW candidates are not authority;
- PVESO remains on-demand compute.

## Future prerequisites

Before real creation or migration, define exact CT resources, storage pool, encrypted volume path, unlock procedure, backup procedure, private network rules, rollback path, and explicit real-mutation approval.

## Current recommendation

Continue no-apply PVEW target design. Do not create CTs, create storage, generate keys, copy data, stop PVESO, or alter public routes.
