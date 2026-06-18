# Phase 14J-HT - CT202 private rehearsal artifact, no restore/no rebuild/no apply

Date: 2026-06-17  
Type: private rehearsal artifact / docs-smoke record  
Previous checkpoint: Phase 14J-HS at commit `bac3a4b`  
Approval phrase used: `APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY`

## Purpose

Create and smoke the CT202 private rehearsal artifact.

Artifact:

`ops/rehearsal/phase-14j-ht-ct202-private-rehearsal-artifact-no-restore-no-rebuild-no-apply.sh`

The artifact performs bounded rehearsal checks only:

- approval and repo guard;
- HP no-apply rebuild artifact execution;
- HR no-restore rollback artifact execution;
- remote read-only CT202 posture verification;
- remote read-only HM/HN backup artifact verification.

## Scope

This phase mutates the repository only by adding:

- this documentation file;
- the private rehearsal artifact;
- the smoke check for this phase.

The artifact may perform remote read-only checks on `pveso`/CT202 during smoke.

It does not restore, rebuild, apply schema, import data, open SQLite with `sqlite3`, dump SQL, print row content, start/enable services, change onboot, mutate routes, contact CT101/model/Ollama/workers, select data authority, or cut over authority.

## Verified backup baseline

Expected backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Expected CT202 DB backup:

- size: `262144`;
- sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`.

Expected manifest hash:

`dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`

Expected rollback checklist hash:

`3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`

## Rehearsal checks

The HT artifact verifies:

- CT202 status is `running`;
- CT202 hostname is `edge-controller`;
- CT202 onboot is `0`;
- `edge-queue-controller.service` is not enabled;
- `edge-queue-controller.service` is not active;
- no checked listener is active on `7070`, `8787`, or `8765`;
- HM/HN backup DB size and hash match expected values;
- manifest and rollback checklist hashes match expected values;
- manifest guard flags remain present;
- HP no-apply artifact runs without applying;
- HR no-restore artifact runs without restoring.

## Safety properties

The artifact contains no:

- restore implementation;
- rebuild implementation;
- schema apply implementation;
- data import implementation;
- service start/enable implementation;
- route mutation implementation;
- SQL dump implementation;
- row-content output implementation.

## Faster-safe workflow note

This is the compact pattern to keep using for no-apply/no-restore artifact phases.

Actual restore, rebuild, schema apply, DB import, service activation, and route/cutover must remain separate explicit gates.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HU - CT202 private rehearsal result review and pre-apply risk gate, no apply`

Suggested approval phrase:

`APPROVE_PHASE_14J_HU_CT202_PRIVATE_REHEARSAL_RESULT_REVIEW_PRE_APPLY_RISK_GATE_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize restore, rebuild, schema apply, migration, import, route mutation, service activation, or cutover.
