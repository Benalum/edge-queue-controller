# Phase 14J-HR - CT202 rollback command artifact, no restore/no rebuild

Date: 2026-06-17  
Type: no-restore rollback command artifact / docs-smoke record  
Previous checkpoint: Phase 14J-HQ at commit `00cfa1e`  
Approval phrase used: `APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD`

## Purpose

Create the safe no-restore CT202 rollback command artifact designed in Phase 14J-HQ.

Artifact:

`ops/rebuild/phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild.sh`

The artifact is executable but safe by default. It verifies the no-restore approval phrase and prints rollback prerequisites, expected backup artifact hashes, required CT202 posture, and planned rollback order only.

## Scope

This phase mutates the repository only by adding:

- this documentation file;
- the no-restore rollback command artifact;
- the smoke check for this phase.

This phase does not restore, rebuild, apply schema, import data, open SQLite with `sqlite3`, dump SQL, print row content, start/enable services, change onboot, mutate routes, contact CT101/model/Ollama/workers, select data authority, or cut over authority.

## Artifact behavior

The artifact requires:

`APC_HR_APPROVAL=APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD`

The artifact supports `APC_ALLOW_DIRTY=1` only for bounded pre-commit artifact smoke.

The artifact opens no remote connection in HR.

## Verified backup prerequisite

Expected HM/HN backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Expected CT202 DB backup:

- size: `262144`;
- sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`.

Expected manifest hash:

`dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`

Expected rollback checklist hash:

`3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`

Required artifacts:

- `ct202-edge_queue.sqlite3`;
- `ct202-pct-config.txt`;
- `ct202-app-summary.txt`;
- `ct202-service-summary.txt`;
- `ct202-env-config-posture.txt`;
- `rollback-checklist.txt`;
- `manifest.txt`.

## Required CT202 posture before any future restore

- CT202 private candidate only;
- CT202 service inactive;
- CT202 service not enabled;
- CT202 onboot `0`;
- no checked listener on `7070`, `8787`, or `8765`;
- laptop controller and laptop-local DB remain live authority;
- public routes unchanged;
- CT202 cutover readiness gate CLOSED.

## Planned rollback order, design only

1. Confirm future explicit restore approval phrase.
2. Confirm CT202 is private candidate and not public authority.
3. Confirm public routes remain unchanged.
4. Confirm laptop controller and laptop-local DB remain live authority.
5. Confirm CT202 service is inactive and not enabled.
6. Confirm CT202 onboot remains `0`.
7. Verify HM/HN backup directory and artifact hashes.
8. Preserve current CT202 candidate DB as a pre-restore artifact if safe.
9. Replace CT202 candidate DB from verified HM backup only after future restore approval.
10. Verify restored file size and SHA256.
11. Keep CT202 service disabled/inactive.
12. Keep CT202 onboot `0`.
13. Keep cutover readiness gate CLOSED.
14. Do not start services.
15. Do not mutate routes.

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

For future no-apply/no-restore planning work, we can safely combine artifact creation, docs, smoke, commit, tag, and push into one compact phase like this.

Actual restore, rebuild, schema apply, service activation, data import, and route/cutover operations must remain separate approval gates.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HS - CT202 private rehearsal plan, no restore/no rebuild/no apply`

Suggested approval phrase:

`APPROVE_PHASE_14J_HS_CT202_PRIVATE_REHEARSAL_PLAN_NO_RESTORE_NO_REBUILD_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize restore, rebuild, schema apply, migration, import, route mutation, or cutover.

Do not run migration/import/copy/dump from this phase.
