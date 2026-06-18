# Phase 14J-IN - Encrypted-at-Rest Placement Design, No Apply

## Scope

This phase records the encrypted-at-rest design decision after PVEW CT203 and CT204 were created as empty, stopped, private, non-authoritative candidates.

No CT/VM create, start, stop, clone, delete, modify, storage create, storage format, storage mount, storage resize, storage enable, storage disable, encryption setup, key generation, key installation, DB dump, DB copy, DB import, DB migration, service activation, onboot/autostart mutation, VM200 mutation, public route mutation, Cloudflare/DNS/tunnel mutation, PVESO power action, CT101/model/Ollama/worker call, laptop controller pause, laptop DB mutation, or production job mutation is approved or performed by this phase.

## Design answer

The platform only requires sensitive user/platform data to be encrypted at rest.

The already-created CT203 and CT204 root disks do not need to be encrypted before private data exists inside them.

Correct order:

1. Create empty CT shells.
2. Verify they are stopped, private, onboot off, and non-authoritative.
3. Design encrypted data storage.
4. Create and verify encrypted storage under a later explicit boundary.
5. Place sensitive data paths on encrypted storage.
6. Move DB/platform data only after encrypted storage is mounted and verified.
7. Activate candidate services only after data placement is correct.
8. Cut over authority only after candidate verification passes.

## Database encryption decision

Database-native encryption alone is not the primary plan.

PostgreSQL column-level encryption or application-level encryption can be useful later for especially sensitive fields, but it does not replace encrypted storage for the full platform data directory, backups, upload files, job artifacts, logs that may contain user content, SQLite files, Redis persistence, and temporary files.

SQLite file-level encryption would require an encrypted SQLite build or a compatible encryption layer and separate key handling. That adds app/runtime complexity and still does not cover all adjacent platform artifacts.

Decision:

Use encrypted storage as the baseline at-rest control. Add database or application field encryption later only for selected high-sensitivity fields if needed.

## Preferred PVEW placement

Preferred architecture:

- CT203 edge-controller-pvew remains the private controller candidate.
- CT204 edge-data-pvew becomes the private data/backups candidate.
- Sensitive persistent data should live under a dedicated encrypted data path, not on the plain CT rootfs.
- CT204 should receive or mount the encrypted data path before any real data is migrated.
- CT203 services should point to CT204 or to the encrypted data path only after the encrypted path exists.

Candidate sensitive paths:

- PostgreSQL data directory.
- SQLite controller DB copy if used during migration.
- Redis persistence if used.
- backups.
- uploaded study files.
- job artifacts.
- private queue snapshots.
- secrets that must persist at rest.
- migration staging files.

## Current PVEW storage decision

Do not use local-lvm for encrypted data allocation yet.

Reasons carried forward from 14J-IL and 14J-IM:

- VG pve free space was only 13.63 GiB.
- Thin-pool autoextend threshold was 100.
- CT203/CT204 creation produced thin-pool overcommit warnings.
- vm-9300-disk-0 and vm-9300-disk-1 exist but have no matching qm or pct guest config.
- vm-9300 volumes must not be assumed disposable.
- data-2tb is disabled and scoped to pveso, not usable on PVEW under the current boundary.
- PVEW block-device inspection showed only the small local SSD available.

## Preferred next infrastructure option

Preferred next real infrastructure option:

Add or attach a dedicated data disk to PVEW, then use that disk for encrypted platform data storage.

The disk should be treated as the future at-rest authority for private platform data. It should not be public, should not be mounted into VM200 website-edge, and should not contain public route/tunnel material.

## Key handling direction

Key handling must remain manual-first until a separate key-management design is approved.

Rules:

- Do not paste keys into ChatGPT.
- Do not store keys in git.
- Do not store keys in Source files.
- Do not print keys in terminal output.
- Do not put keys in APC_LAST_OUTPUT.
- Do not put keys in VM200 website-edge.
- Do not put keys in public routes or Cloudflare tunnel config.
- Do not enable automatic unlock until manual unlock has been tested and documented.

## Migration order

Approved logical order for later phases:

1. Read-only plan for dedicated data disk or safe storage target.
2. Explicit approval for storage attachment or selection if needed.
3. Explicit approval for encrypted storage creation.
4. Manual unlock and mount verification.
5. Read-only verification that encrypted storage is present.
6. No-apply data migration plan.
7. Explicit approval for data backup/export.
8. Explicit approval for data import onto encrypted storage.
9. Candidate service startup in private mode.
10. Candidate validation.
11. Authority cutover.
12. PVESO shutdown only after rollback and authority checks pass.

## Still blocked

The following remain blocked until separate explicit real-mutation approval:

- encrypted storage creation;
- key generation or installation;
- storage attachment;
- local-lvm allocation for data;
- vm-9300 deletion or reuse;
- data-2tb enablement or reuse;
- DB dump/copy/import/migration;
- service activation;
- onboot/autostart changes;
- public route changes;
- PVESO shutdown.

## Result

PASS_ENCRYPTED_AT_REST_PLACEMENT_DESIGN_NO_APPLY
