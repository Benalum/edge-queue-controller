# Phase 14J-HM - CT202 guarded backup only, no rebuild

Date: 2026-06-17  
Execution timestamp: 2026-06-18T03:12:07Z  
Type: guarded CT202 backup-only execution / docs-smoke record  
Previous checkpoint: Phase 14J-HL at commit `0a12db6`  
Approval phrase used: `APPROVE_PHASE_14J_HM_CT202_GUARDED_BACKUP_ONLY_NO_REBUILD`

## Purpose

Record the guarded CT202 backup-only execution completed by HM-R2.

This phase created CT202 candidate backup artifacts on `pveso` only.

This phase did not rebuild CT202.

This phase did not select a data authority path.

This phase did not authorize schema apply, data migration, import, runtime activation, route mutation, or cutover.

## HM-R1 note

The first HM attempt failed safely before remote work because the local machine could not resolve the `pveso` SSH hostname.

Result of HM-R1:

- repo guard passed at `0a12db6`;
- no SSH connection was made;
- no CT202 backup was created;
- no CT202/schema/service/route/cutover mutation happened;
- failure reason: `ssh: Could not resolve hostname pveso`.

## HM-R2 resolver note

HM-R2 used SSH/Tailscale fallback resolution.

During resolver probing, direct hostname and MagicDNS attempts failed, and one non-root user probe failed. A valid SSH target was then resolved and remote execution proceeded on host `pveso`.

This did not affect the backup scope.

## Mutation boundary

This phase created backup artifacts only under the guarded backup directory on `pveso`.

It did not perform:

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

## Preflight guard result

Local repo guard:

- starting HEAD: `0a12db6`;
- local `origin/main`: `0a12db6`;
- working tree: clean.

Remote CT202 posture before backup:

- remote host: `pveso`;
- CTID: `202`;
- CT status: `running`;
- CT hostname: `edge-controller`;
- CT onboot: `0`;
- service enabled state: `disabled`;
- service active state: `inactive`;
- no checked controller/smoke listener active.

CT202 candidate DB before backup:

- source path: `/srv/edge-controller/data/edge_queue.sqlite3`;
- source size: `262144`;
- source sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`.

CT202 app path existed:

- `/srv/edge-controller/app/current`.

## Backup directory

Backup artifacts were created on `pveso` under:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

## Backup artifacts

The backup directory contains:

| Artifact | Size | SHA256 |
|---|---:|---|
| `ct202-edge_queue.sqlite3` | `262144` | `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314` |
| `ct202-pct-config.txt` | `503` | `bbb21f78f92e529d5770b7e62481069e1015a62c49d21d7abdf60681d94327a2` |
| `ct202-app-summary.txt` | `6567` | `c13338ba45a38d0c8518496610bbda15f937662253a5ceb3f02265d2da4d6d31` |
| `ct202-service-summary.txt` | `271` | `67159dcb661a902bd16dfc82a753c1bd9bc4a2bc2c9571199b14e0a8877e1952` |
| `ct202-env-config-posture.txt` | `1512` | `b3575157eb07c2bf67f3993bf64cae1569c9986afda30752f0e1b4625c1290fe` |
| `rollback-checklist.txt` | `698` | `3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6` |
| `manifest.txt` | `1159` | `dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491` |

## Backup verification result

HM-R2 verified:

- DB backup size matched source size;
- DB backup SHA256 matched source SHA256;
- manifest artifact was created;
- rollback checklist artifact was created;
- no SQLite DB was opened with `sqlite3`;
- no SQL dump was performed;
- no row content was printed;
- no service start/enable was performed;
- CT202 onboot remained `0`;
- CT202 service remained `disabled/inactive`;
- no checked controller/smoke listener was active after backup;
- CT202 remained private candidate only;
- no rebuild/apply/cutover was performed.

## Post-backup CT202 posture

Remote CT202 posture after backup:

- CT status: `running`;
- CT onboot: `0`;
- service enabled state: `disabled`;
- service active state: `inactive`;
- no checked controller/smoke listener active after backup.

## Local repo post-check

Local repo after backup-only execution:

- HEAD: `0a12db6`;
- local `origin/main`: `0a12db6`;
- working tree: clean.

The live backup command did not mutate the repo.

## Authority status

Authority status after HM:

- laptop controller remains live authority;
- laptop-local DB remains live authority;
- CT202 remains private candidate only;
- CT202 cutover readiness gate remains CLOSED;
- public routes remain unchanged;
- no cutover/apply occurred.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HN - CT202 backup artifact verification record, no restore/no rebuild`

That phase should remain docs/smoke-only or read-only artifact verification only.

It should record:

- the backup directory;
- artifact names, sizes, and hashes;
- manifest hash;
- rollback checklist hash;
- CT202 posture after backup;
- that no restore/rebuild/apply was executed.

## Future approval phrase for HN

Suggested future approval phrase:

`APPROVE_PHASE_14J_HN_CT202_BACKUP_ARTIFACT_VERIFICATION_RECORD_NO_RESTORE_NO_REBUILD`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize a CT202 rebuild.

This phase does not authorize a schema apply.

This phase does not authorize restore.

Do not run migration/import/copy/dump from this phase.
