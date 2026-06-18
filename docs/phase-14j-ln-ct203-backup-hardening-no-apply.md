# Phase 14J-LN — CT203 Backup Hardening Plan, No Apply

Updated: 2026-06-18

## Purpose

This phase records a no-apply backup hardening plan for the current PVEW platform posture after Phase 14J-LM.

This phase does not create a backup, restore a backup, inspect private storage live state, start CT204, change CT204 authority, mutate services, mutate storage, or change public routes.

## Current baseline

- Latest prior checkpoint: Phase 14J-LM — Post-LL final platform baseline.
- CT203 `edge-controller-pvew` is the live controller/API/queue authority.
- CT203 active DB path is `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
- CT203 service is expected active/enabled at baseline.
- Public `/system/status` is expected `online`.
- Public status node model is `ct-203,pvew,vm-200,ct-204`.
- Public normalized schema version is `2`.
- VM200 `website-edge` is public/static only.
- CT204 `edge-data-pvew` is stopped, backup-data-only, and not data authority.
- PVEW encrypted private storage policy remains manual-unlock-only.
- PVESO remains on-demand compute/model/worker host and should stay offline unless explicitly needed.

## Non-mutation guarantees

Phase 14J-LN is repo-only documentation and smoke validation.

It performs no:

- DB mutation;
- DB backup creation;
- DB restore, import, migration, authority switch, or controller DB swap;
- storage, encryption, key, mount, crypttab, fstab, auto-unlock, or auto-mount mutation;
- CT204 start, CT204 service activation, CT204 bind-mount role change, or CT204 authority promotion;
- CT/VM configuration mutation;
- service restart, reload, enable, start, or stop;
- Cloudflare, DNS, tunnel, nginx public route, or public cutover mutation;
- PVESO wake/start or worker/model runtime activation.

## Backup hardening goals

The near-term goal is to make CT203 recoverable without accidentally promoting CT204, weakening encrypted storage policy, or mixing public/static VM200 with private/controller data.

The backup plan should eventually provide:

1. A known-good CT203 SQLite backup procedure.
2. A backup inventory format that records timestamp, source DB identity, backup path class, size, sha256, and integrity result.
3. A restore-drill design that validates a copy in isolation before any live restore is considered.
4. A retention plan that avoids unbounded backup growth.
5. A clear separation between backup storage, live authority, and future CT204 promotion.
6. A rollback plan for any future authority or restore boundary.
7. A safe public status posture that does not reveal private storage internals.

## Backup inventory classes

### Class A — CT203 controller DB backup

Critical artifact:

- Source: CT203 `/var/lib/edge-queue-controller/edge_queue.sqlite3`.
- Desired backup method: SQLite-consistent backup from the live DB, using a safe backup mechanism rather than raw copy during active writes.
- Required metadata:
  - backup timestamp;
  - source host/container identity;
  - source DB path;
  - backup filename;
  - byte size;
  - sha256;
  - SQLite `PRAGMA integrity_check` result on the backup copy;
  - git commit/tag active at backup time;
  - whether encrypted private storage was manually unlocked by the operator before backup.

No Class A backup creation is performed by this phase.

### Class B — CT203 controller source/config reference

Reference artifacts:

- Git commit and tag are the primary source reference.
- Deployed CT203 controller source hash should match the expected committed deployment hash when checked.
- Service unit and environment references may be inventoried later in sanitized form, but secrets and raw environment values must never be logged or committed.

No CT203 service or config inspection is performed by this phase.

### Class C — Source/package checkpoint

Reference artifacts:

- Repository commit and tag.
- Source refresh package at major handoff checkpoints.
- Docs and smoke scripts that explain what changed and what was intentionally not changed.

This phase adds only docs and a static smoke script.

### Class D — Encrypted private storage placement

Storage posture:

- PVEW encrypted private storage mountpoint policy is `/srv/apc-private-data`.
- Policy is manual-unlock-only.
- Public status mount state remains `unknown`.
- CT203 must not inspect or control host mount state through public status.
- No crypttab, fstab, auto-unlock, auto-mount, or keyfile changes are part of this plan.

No storage inspection or mutation is performed by this phase.

## Restore-drill requirements before any live restore

Before any future live restore/import/authority action, create a separate no-apply or explicitly approved phase that proves:

1. Fresh backup exists and has sha256 recorded.
2. Backup copy passes SQLite integrity check in isolation.
3. Restore target is isolated and cannot become accidental authority.
4. CT203 live DB is not overwritten without explicit approval.
5. CT204 is not started or promoted without explicit approval.
6. Public routes and controller service remain unchanged unless separately approved.
7. Rollback plan and stop conditions are written before execution.
8. No secrets, tokens, keys, private IPs, MACs, or bearer values are printed.

## Future phase order

Recommended next backup/data phases:

1. Phase 14J-LO — read-only backup inventory shape check, if PVEW is reachable.
2. Phase 14J-LP — optional approved fresh CT203 backup to manually unlocked encrypted storage.
3. Phase 14J-LQ — no-apply restore-drill design using an isolated copy.
4. Phase 14J-LR — CT204 backup-data role no-apply design.
5. Later explicit approval boundary — CT204 start or data authority work, only if needed.

## Success criteria

This phase is successful when:

- The no-apply backup hardening plan is committed.
- A smoke script verifies the required guardrails.
- The repo is clean after commit/tag/push.
- No live infrastructure, DB, storage, service, CT/VM, route, tunnel, Cloudflare, PVESO, or CT204 mutation occurred.

## Result marker

Planned result marker:

`PASS_PHASE_14J_LN_CT203_BACKUP_HARDENING_NO_APPLY_DONE`
