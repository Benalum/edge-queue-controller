# Phase 14J-HQ - CT202 rollback command design, no restore/no rebuild

Date: 2026-06-17  
Type: no-restore rollback command design / docs-smoke record  
Previous checkpoint: Phase 14J-HP at commit `7084fba`  
Approval phrase used: `APPROVE_PHASE_14J_HQ_CT202_ROLLBACK_COMMAND_DESIGN_NO_RESTORE_NO_REBUILD`

## Purpose

Record the no-restore design for future CT202 rollback commands.

This phase follows the Phase 14J-HP no-apply rebuild script artifact.

This phase designs rollback command structure, prerequisites, guardrails, verification requirements, artifact handling, and failure boundaries only.

This phase does not create a rollback command artifact.

This phase does not execute restore.

This phase does not execute rebuild.

This phase does not select a data authority path.

This phase does not authorize restore, schema apply, data migration, import, runtime activation, route mutation, or cutover.

## Mutation boundary

This phase is docs/smoke only.

It does not perform:

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

## Required prerequisites from prior phases

A future rollback command artifact must require these completed prerequisites:

1. Phase 14J-HL backup and rollback plan exists.
2. Phase 14J-HM guarded CT202 backup artifacts exist.
3. Phase 14J-HN backup artifact verification passed.
4. Phase 14J-HP no-apply rebuild script artifact exists.
5. CT202 remains private candidate only.
6. CT202 service remains disabled/inactive.
7. CT202 onboot remains `0`.
8. CT202 cutover readiness gate remains CLOSED.
9. Laptop controller and laptop-local DB remain live authority.
10. Public routes remain unchanged.

## Verified HM/HN backup prerequisite

The future rollback command artifact must require this verified backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Verified backup artifacts include:

- `ct202-edge_queue.sqlite3`;
- `ct202-pct-config.txt`;
- `ct202-app-summary.txt`;
- `ct202-service-summary.txt`;
- `ct202-env-config-posture.txt`;
- `rollback-checklist.txt`;
- `manifest.txt`.

The verified CT202 DB backup hash is:

`43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`

The verified CT202 DB backup size is:

`262144`

## Future rollback command goal

The future rollback command artifact should provide a safe, explicit, fail-closed design for restoring CT202 candidate state from the verified HM backup only after a later explicit restore approval.

The rollback command is for CT202 candidate state only.

The rollback command must not promote CT202 to authority.

The rollback command must not mutate laptop live authority.

The rollback command must not mutate public routes.

The rollback command must not start or enable the CT202 controller service.

The rollback command must not change CT202 onboot/autostart.

## Future rollback command mode

The recommended next artifact should be a **no-restore rollback command artifact**, not a restore script.

The artifact should support a no-restore verification mode first.

Suggested initial behavior:

- verify approval phrase;
- verify repo checkpoint;
- verify CT202 posture;
- verify HM/HN backup artifact presence and hashes;
- verify rollback checklist guard text;
- print the planned rollback order;
- refuse to restore unless a later phase defines a separate restore approval phrase.

This phase intentionally does not define a restore-apply approval phrase.

## Future command guard sequence

A future rollback command artifact should begin with hard guards.

### Guard 1 - explicit phase approval

Require a future no-restore artifact approval phrase, not a restore/apply phrase.

Expected next approval phrase:

`APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD`

### Guard 2 - repo checkpoint

Require the expected repo HEAD from the phase that creates the artifact.

The artifact should fail if:

- repo HEAD is not the expected checkpoint;
- local `origin/main` is not expected;
- working tree is dirty, except for a clearly bounded pre-commit artifact smoke mode if needed.

### Guard 3 - pveso resolution

Resolve `pveso` using the SSH/Tailscale fallback pattern proven in HM/HN.

The artifact should avoid printing raw private IPs, MAC addresses, auth URLs, tokens, or env contents.

### Guard 4 - CT202 posture

Verify:

- CT202 status is `running`;
- CT202 hostname is `edge-controller`;
- CT202 onboot is `0`;
- `edge-queue-controller.service` is not enabled;
- `edge-queue-controller.service` is not active;
- no checked listener is active on `7070`, `8787`, or `8765`.

### Guard 5 - backup artifact prerequisite

Verify the HM/HN backup directory exists.

Verify artifact size/hash values match HN:

- DB backup size `262144`;
- DB backup SHA256 `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`;
- manifest SHA256 `dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491`;
- rollback checklist SHA256 `3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6`.

### Guard 6 - manifest guard flags

Require the manifest guard flags:

- `no_sqlite_open=1`;
- `no_sql_dump=1`;
- `no_row_content=1`;
- `no_service_start=1`;
- `no_service_enable=1`;
- `no_onboot_mutation=1`;
- `no_rebuild=1`;
- `no_cutover=1`.

### Guard 7 - rollback checklist guard text

Require rollback checklist guard text proving:

- do not run restore from HM;
- CT202 remains private candidate only;
- public routes unchanged;
- laptop controller remains live authority;
- CT202 onboot remains 0;
- verified backup DB artifact exists;
- backup DB SHA256 matches manifest;
- failed/rebuilt CT202 DB preserved first if safe.

### Guard 8 - no authority/cutover

Fail closed if any approval phrase or command implies:

- cutover apply;
- runtime apply;
- route apply;
- Cloudflare apply;
- schema apply;
- data migration;
- restore apply.

## Future rollback order design

A future restore-capable rollback command, if separately approved later, should follow this order.

This is a design only.

1. Confirm explicit future restore approval phrase.
2. Confirm CT202 remains private candidate and not public authority.
3. Confirm public routes still point to the current live authority path.
4. Confirm laptop controller and laptop-local DB remain live authority.
5. Confirm CT202 service is inactive.
6. Confirm CT202 service is not enabled.
7. Confirm CT202 onboot remains `0`.
8. Confirm the verified HM/HN backup directory exists.
9. Confirm backup DB hash and size match the HN record.
10. Preserve current CT202 candidate DB as a pre-restore failure artifact if safe.
11. Replace CT202 candidate DB from the verified backup artifact only after future restore approval.
12. Verify restored file exists.
13. Verify restored file size matches expected size.
14. Verify restored file SHA256 matches expected backup SHA256.
15. Keep CT202 service disabled/inactive.
16. Keep CT202 onboot `0`.
17. Keep CT202 cutover readiness gate CLOSED.
18. Record rollback result.
19. Do not start services.
20. Do not mutate routes.

Again, this phase does not execute any of the above.

## Future failure artifact handling

A future restore-capable rollback command should preserve the current CT202 candidate DB before replacing it when safe.

The preserved artifact should include:

- timestamp;
- file size;
- SHA256 hash;
- clear label indicating it is the pre-restore candidate DB;
- no row content;
- no SQL dump.

The future command should fail closed if it cannot preserve the candidate DB and preservation is required by the future restore plan.

## Future output requirements

A future no-restore rollback artifact should output:

- PASS/FAIL guard lines;
- expected backup directory;
- expected artifact hashes;
- CT202 posture summary;
- manifest guard verification;
- rollback checklist verification;
- planned rollback order;
- confirmation no restore occurred;
- confirmation no rebuild occurred;
- confirmation no service start/enable occurred;
- confirmation no route/cutover mutation occurred.

It should not output:

- row content;
- SQL dumps;
- raw DB contents;
- secrets;
- env file contents;
- raw private IPs;
- MAC addresses;
- auth URLs.

## Future command artifact location

Recommended future artifact location:

`ops/rebuild/phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild.sh`

The artifact should be executable but safe by default.

The artifact should fail closed unless the exact no-restore artifact approval phrase is set.

The artifact should not contain any restore/apply approval phrase.

## Future command sections

The future rollback command artifact should have these sections:

1. approval and mutation-boundary banner;
2. repo guard;
3. pveso SSH/Tailscale resolver;
4. CT202 posture guard;
5. backup artifact verification guard;
6. manifest guard flag verification;
7. rollback checklist verification;
8. planned rollback order summary;
9. non-goals/forbidden operations summary;
10. final no-restore PASS result.

## Deferred restore design

Actual restore remains deferred.

Before any restore, future phases must still create:

1. no-restore rollback command artifact;
2. no-apply private rehearsal plan;
3. explicit restore risk review;
4. separate restore approval phrase;
5. separate post-restore verification plan.

This HQ phase does not define the restore approval phrase.

## Relationship to HP rebuild artifact

Phase 14J-HP created a no-apply rebuild script artifact.

Phase 14J-HQ designs the rollback companion path before any rebuild apply exists.

This keeps rollback readiness ahead of any future CT202 candidate rebuild execution.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HR - CT202 rollback command artifact, no restore/no rebuild`

That phase should create the safe no-restore rollback command artifact only.

It should not restore.

It should not rebuild.

It should not apply schema.

It should not import data.

It should not start or enable services.

It should not select data authority.

It should not mutate public routes.

## Future approval phrase for HR

Suggested future approval phrase:

`APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize a CT202 rebuild.

This phase does not authorize a schema apply.

This phase does not authorize restore.

Do not run migration/import/copy/dump from this phase.
