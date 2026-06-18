# Phase 14J-HS - CT202 private rehearsal plan, no restore/no rebuild/no apply

Date: 2026-06-17  
Type: private rehearsal plan / docs-smoke record  
Previous checkpoint: Phase 14J-HR at commit `23d2152`  
Approval phrase used: `APPROVE_PHASE_14J_HS_CT202_PRIVATE_REHEARSAL_PLAN_NO_RESTORE_NO_REBUILD_NO_APPLY`

## Purpose

Record the private rehearsal plan for CT202 before any future restore, rebuild, schema apply, data import, service activation, or cutover.

This phase is planning only.

This phase does not create a rehearsal script artifact.

This phase does not execute rehearsal commands.

This phase does not restore, rebuild, apply schema, import data, start services, enable services, mutate onboot, mutate routes, select data authority, or cut over authority.

## Scope

This phase mutates the repository only by adding:

- this documentation file;
- the smoke check for this phase.

No runtime systems are changed.

## Required existing safety artifacts

The private rehearsal plan depends on these already-recorded artifacts:

- Phase 14J-HK target schema manifest;
- Phase 14J-HL backup and rollback plan;
- Phase 14J-HM guarded CT202 backup-only execution;
- Phase 14J-HN backup artifact verification;
- Phase 14J-HP no-apply rebuild script artifact;
- Phase 14J-HQ rollback command design;
- Phase 14J-HR no-restore rollback command artifact.

## Verified backup baseline

Expected HM/HN backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Expected CT202 DB backup:

- size: `262144`;
- sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`.

Expected manifest hash:

`dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`

Expected rollback checklist hash:

`3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`

## Private rehearsal goal

The private rehearsal should prove that CT202 can be checked, planned, and guarded without becoming authority.

The rehearsal must remain private and non-authoritative.

It should validate:

- repo checkpoint;
- CT202 private posture;
- CT202 service disabled/inactive posture;
- CT202 onboot `0`;
- no checked listener on `7070`, `8787`, or `8765`;
- backup artifact availability;
- rollback artifact availability;
- rebuild no-apply artifact availability;
- target table manifest availability;
- hard no-apply/no-restore/no-cutover boundaries.

## Private rehearsal non-goals

The private rehearsal must not perform:

- CT202 authority cutover;
- data authority path selection;
- Path C execution;
- CT202 rebuild execution;
- CT202 schema apply;
- CT202 data migration or import;
- SQLite open with `sqlite3`;
- SQL dump;
- table data dump;
- row content output;
- live laptop DB mutation;
- CT202 DB mutation;
- backup creation;
- restore operation;
- `systemctl start`;
- `systemctl enable`;
- CT202 onboot/autostart mutation;
- VM start, stop, or reboot;
- Cloudflare, DNS, or tunnel mutation;
- public route mutation;
- laptop controller stop or pause;
- CT101 call;
- model/Ollama endpoint call;
- worker start;
- production DB/job mutation;
- secret generation, printing, or installation;
- destructive GitHub branch or repository deletion.

## Proposed rehearsal order

The future rehearsal artifact should perform only bounded, read-only or local no-apply checks:

1. Confirm explicit no-apply rehearsal artifact approval phrase.
2. Confirm repo HEAD and clean working tree.
3. Resolve `pveso` using the SSH/Tailscale fallback pattern.
4. Verify CT202 status is `running`.
5. Verify CT202 hostname is `edge-controller`.
6. Verify CT202 onboot is `0`.
7. Verify `edge-queue-controller.service` is disabled/inactive.
8. Verify no checked listener on `7070`, `8787`, or `8765`.
9. Verify HM/HN backup directory exists.
10. Verify backup DB size/hash.
11. Verify manifest and rollback checklist hashes.
12. Run the HP no-apply rebuild artifact in no-apply mode only.
13. Run the HR no-restore rollback artifact in no-restore mode only.
14. Verify target include count remains `39`.
15. Verify CT202-only drift tables remain omitted/deferred:
    - `credit_ledger`;
    - `user_credit_wallets`.
16. Verify critical mismatch decisions remain explicit:
    - `workers`;
    - `credit_reservations`.
17. Confirm no restore/rebuild/schema apply/import/cutover occurred.
18. Confirm CT202 posture remains disabled/inactive/onboot off after rehearsal.
19. Confirm laptop authority remains unchanged.
20. Record rehearsal result.

## Expected rehearsal artifact behavior

A future rehearsal artifact should:

- be executable but safe by default;
- require an exact no-apply approval phrase;
- fail closed on unexpected repo state;
- fail closed on CT202 posture drift;
- fail closed on backup artifact hash drift;
- fail closed if HP/HR artifacts are missing;
- print bounded PASS/FAIL lines;
- avoid secrets, env contents, row content, SQL dumps, raw private IPs, MAC addresses, and auth URLs.

## Faster-safe workflow note

This HS plan keeps the compact style introduced in HR.

For planning/artifact phases, compact docs/smoke checkpoints are acceptable when they still assert:

- current checkpoint;
- exact approval phrase;
- hard no-apply/no-restore boundary;
- artifact paths and hashes;
- next gate.

For real mutation phases, compact mode is not enough. Restore, rebuild, schema apply, data import, service activation, and route/cutover must remain separate, explicit approval gates.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HT - CT202 private rehearsal artifact, no restore/no rebuild/no apply`

Suggested approval phrase:

`APPROVE_PHASE_14J_HT_CT202_PRIVATE_REHEARSAL_ARTIFACT_NO_RESTORE_NO_REBUILD_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize restore, rebuild, schema apply, migration, import, route mutation, service activation, or cutover.

Do not run migration/import/copy/dump from this phase.
