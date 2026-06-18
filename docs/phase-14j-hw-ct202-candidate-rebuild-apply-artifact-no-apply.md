# Phase 14J-HW - CT202 candidate rebuild apply artifact, no apply

Date: 2026-06-17  
Type: no-apply candidate rebuild artifact / docs-smoke record  
Previous checkpoint: Phase 14J-HV at commit `87e446f`  
Approval phrase used: `APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY`

## Purpose

Create the future CT202 candidate rebuild apply artifact in no-apply mode.

Artifact:

`ops/rebuild/phase-14j-hw-ct202-candidate-rebuild-apply-artifact-no-apply.sh`

The artifact summarizes and verifies the future mutation boundary only.

This phase does not define the real candidate rebuild approval phrase.

This phase does not execute restore, rebuild, schema apply, data import, service activation, route mutation, or cutover.

## Scope

This phase mutates the repository only by adding:

- this documentation file;
- the no-apply candidate rebuild artifact;
- the smoke check for this phase.

The artifact does not open SQLite with `sqlite3`.

The artifact does not open a remote connection in HW.

The artifact does not mutate CT202.

## Target summary

Future target DB path:

`/srv/edge-controller/data/edge_queue.sqlite3`

Future target table count:

`39`

Target schema source:

Phase 14J-HK target manifest plus runtime-compatible laptop continuity evidence.

Target omit/defer CT202-only drift tables:

- `credit_ledger`;
- `user_credit_wallets`.

Critical mismatch decisions remain:

- `workers`: target laptop runtime-compatible shape with lane/default-off metadata;
- `credit_reservations`: target runtime/laptop continuity shape.

## Future guard summary

The future real candidate rebuild phase must require:

- repo checkpoint and clean working tree;
- CT202 status `running`;
- CT202 hostname `edge-controller`;
- CT202 onboot `0`;
- `edge-queue-controller.service` not enabled;
- `edge-queue-controller.service` not active;
- no checked listener on `7070`, `8787`, or `8765`;
- laptop controller and laptop-local DB remain live authority;
- public routes unchanged;
- CT202 cutover gate CLOSED.

## Backup baseline

Expected backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Expected CT202 DB backup:

- size: `262144`;
- sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`.

Expected manifest hash:

`dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`

Expected rollback checklist hash:

`3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`

## Preservation design

Before any future candidate DB replacement, the future mutating phase must preserve current CT202 candidate DB.

Preservation metadata must include:

- timestamp;
- file size;
- sha256;
- source path;
- destination path;
- reason label.

Preservation must include no row content and no SQL dump.

The future mutating phase must fail closed if preservation fails.

## Future candidate rebuild action design, not executed

1. Confirm future real candidate rebuild approval phrase.
2. Confirm repo checkpoint and clean tree.
3. Confirm CT202 private candidate posture.
4. Confirm HM/HN backup hashes.
5. Preserve current CT202 candidate DB.
6. Create candidate DB from target schema source only.
7. Verify target table count `39`.
8. Verify CT202-only drift tables remain omitted/deferred.
9. Verify `workers` and `credit_reservations` mismatch decisions.
10. Keep service disabled/inactive.
11. Keep CT202 onboot `0`.
12. Keep cutover gate CLOSED.
13. Do not import live laptop data.
14. Do not mutate public routes.
15. Do not start services.

## Safety properties

The artifact contains no:

- rebuild implementation;
- schema apply implementation;
- restore implementation;
- data import implementation;
- service start/enable implementation;
- route mutation implementation;
- SQL dump implementation;
- row-content output implementation.

The artifact does not define the real candidate rebuild approval phrase.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HX - CT202 candidate rebuild apply artifact rehearsal, no apply`

Suggested approval phrase:

`APPROVE_PHASE_14J_HX_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_REHEARSAL_NO_APPLY`

That phase should run the HW artifact plus HT rehearsal checks in no-apply/read-only mode.

It should not execute rebuild.

It should not apply schema.

It should not import data.

It should not restore.

It should not start or enable services.

It should not mutate routes.

It should not select data authority.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

The CT202 candidate mutation gate remains CLOSED.

The CT202 restore gate remains CLOSED.

The CT202 schema apply gate remains CLOSED.

The data authority selection gate remains CLOSED.

Laptop controller and laptop-local DB remain live authority.

CT202 remains private candidate only.

Do not run migration/import/copy/dump from this phase.
