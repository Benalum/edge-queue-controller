# Phase 14J-HL - CT202 rebuild backup and rollback plan, no apply

Date: 2026-06-17  
Type: no-apply backup and rollback plan / docs-smoke record  
Previous checkpoint: Phase 14J-HK at commit `f23688e`  
Approval phrase used: `APPROVE_PHASE_14J_HL_CT202_REBUILD_BACKUP_ROLLBACK_PLAN_NO_APPLY`

## Purpose

Record the no-apply backup and rollback plan required before any future CT202 candidate rebuild work.

This phase follows the Phase 14J-HK target schema manifest.

This phase designs backup, verification, rollback, and guard requirements only.

This phase does not create backups.

This phase does not execute a rebuild.

This phase does not select a data authority path.

This phase does not authorize schema apply, data migration, import, runtime activation, route mutation, or cutover.

## Mutation boundary

This phase is docs/smoke only.

It does not perform:

- CT202 authority cutover;
- data authority path selection;
- Path C execution;
- CT202 rebuild execution;
- guarded backup execution;
- CT202 data migration or import;
- schema migration;
- SQLite open;
- SQLite copy;
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

## Current authority posture

The current authority posture remains:

- laptop controller remains live authority;
- laptop-local `edge_queue.sqlite3` remains live DB authority;
- CT202 remains private candidate only;
- CT202 controller service must remain disabled/inactive;
- CT202 onboot/autostart must remain off;
- CT202 cutover readiness gate remains CLOSED;
- VM200 website-edge remains separate from CT202 controller authority;
- public routes remain unchanged.

## Backup plan objective

The future guarded backup-only phase must create enough evidence to safely roll back CT202 candidate state before any rebuild.

The goal is to protect CT202 candidate artifacts, not to move authority.

Backup-only execution must not modify live laptop authority and must not mutate public routes.

## Artifacts to include in a future CT202 backup

A future guarded backup-only phase should include these CT202 candidate artifacts.

### CT202 candidate database

Backup target:

- `/srv/edge-controller/data/edge_queue.sqlite3`.

Requirements:

- backup as a file artifact only;
- verify source file exists before copy;
- verify copied artifact exists after copy;
- record file size;
- record SHA256 hash;
- do not print row content;
- do not run `.dump`;
- do not import into any DB;
- do not mutate either laptop or CT202 DB.

### CT202 application tree summary

Backup target:

- `/srv/edge-controller/app/current`.

Requirements:

- record symlink/realpath target if applicable;
- record git commit if the directory is a git repo;
- record a bounded file manifest or tarball only after explicit backup-only approval;
- avoid printing secrets;
- exclude runtime cache/temp files if safe;
- do not start the app.

### CT202 service/unit posture

Backup/record targets:

- `edge-queue-controller.service` unit state;
- unit enabled/active state;
- relevant systemd unit file path if present.

Requirements:

- record enabled state;
- record active state;
- verify expected disabled/inactive posture;
- do not run `systemctl start`;
- do not run `systemctl enable`;
- do not modify unit files during backup-only phase.

### CT202 environment/config posture

Backup/record targets:

- existence and permissions of expected env/config files;
- path names only unless separately approved.

Requirements:

- do not print secrets;
- do not cat env files;
- do not print tokens/passwords/keys;
- record file presence, owner, mode, and hash only if safe;
- prefer path/mode-only unless explicit secret-safe handling is defined.

### CT202 container config posture

Backup/record targets:

- CT202 Proxmox config;
- onboot value;
- resource settings;
- hostname;
- network attachment summary.

Requirements:

- sanitize raw private IPs and MAC addresses;
- verify onboot remains `0`;
- do not run `pct set`;
- do not start/stop/reboot CT202.

### Host-side backup directory

Recommended future backup root:

- host-local path on `pveso` under a dated CT202 backup directory.

Requirements:

- path must not include secrets;
- directory owner/mode should restrict access;
- write only in explicit future guarded backup-only phase;
- include manifest file with hashes and sizes;
- include a copy of the rollback checklist.

This HL phase does not create that directory.

## Artifacts not to include

Future backup-only execution should not include:

- laptop live DB copy;
- laptop live DB dump;
- laptop route/service mutation;
- public Cloudflare/DNS/tunnel state mutation;
- CT101 runtime artifacts;
- model/Ollama artifacts;
- secrets printed into logs;
- raw auth URLs;
- row content;
- SQL dumps.

## Backup verification plan

A future guarded backup-only phase should verify:

1. CT202 status before backup.
2. CT202 onboot is `0`.
3. CT202 controller service is disabled/inactive.
4. No checked CT202 listener is active.
5. CT202 candidate DB exists.
6. CT202 candidate DB backup file exists after copy.
7. CT202 candidate DB source size equals copied size.
8. CT202 candidate DB copied artifact has SHA256 recorded.
9. Backup manifest exists.
10. Backup manifest references every created artifact.
11. No secrets are printed.
12. Repo remains clean if the phase is not supposed to mutate repo files.
13. CT202 service remains disabled/inactive after backup.
14. CT202 onboot remains `0` after backup.
15. Laptop authority remains unchanged.

## Rollback plan objective

Rollback must be able to restore CT202 candidate state after a future rebuild rehearsal or failed schema apply.

Rollback is for CT202 candidate only.

Rollback does not mean laptop authority changes.

Rollback does not mean public route cutover.

## Rollback prerequisites

Before any future rebuild apply, rollback prerequisites must include:

- a verified CT202 candidate DB backup;
- recorded SHA256 hash of backup;
- recorded CT202 service disabled/inactive posture;
- recorded CT202 onboot `0` posture;
- a rollback command plan reviewed in docs;
- explicit restore approval phrase defined only in a later phase;
- confirmation that public routes remain unchanged;
- confirmation that laptop authority remains live.

## Rollback order for future design

A future rollback execution plan should follow this order:

1. Confirm rollback approval phrase.
2. Confirm CT202 remains private candidate and not public authority.
3. Confirm public routes still point to the existing live authority path.
4. Confirm CT202 controller service is stopped/inactive.
5. Confirm CT202 onboot remains off.
6. Preserve failed/rebuilt CT202 DB as a post-failure artifact if safe.
7. Restore the verified CT202 DB backup to the candidate DB path.
8. Verify restored file exists.
9. Verify restored file SHA256 matches backup manifest.
10. Run read-only SQLite quick_check only after explicit restore/verify approval.
11. Keep CT202 service disabled/inactive.
12. Keep CT202 cutover gate closed.
13. Record rollback result.

This phase does not execute any rollback.

## Guardrails for future backup-only phase

The next backup-only phase must use hard guards:

- expected repo HEAD guard;
- expected CT202 status guard;
- expected CT202 onboot `0` guard;
- expected service disabled/inactive guard;
- no listener guard;
- no CT101 call;
- no model/Ollama call;
- no worker start;
- no public route mutation;
- no Cloudflare/DNS/tunnel mutation;
- no laptop controller stop/pause;
- no DB import;
- no SQL dump;
- no row content output;
- no secrets printed;
- no destructive GitHub branch/repository deletion.

## Backup-only phase output requirements

Future backup-only output should be bounded and safe.

It should print:

- status PASS/FAIL lines;
- sanitized CT202 posture;
- backup artifact names;
- file sizes;
- SHA256 hashes;
- manifest path;
- confirmation no services were started/enabled;
- confirmation no cutover occurred.

It should not print:

- row content;
- SQL dumps;
- raw private IPs;
- MAC addresses;
- secrets;
- env file contents;
- auth URLs;
- raw database contents.

## Future backup-only approval phrase

The next phase may perform guarded CT202 backup only.

Suggested future approval phrase:

`APPROVE_PHASE_14J_HM_CT202_GUARDED_BACKUP_ONLY_NO_REBUILD`

Scope of that future approval:

- create CT202 candidate backup artifacts only;
- no CT202 rebuild;
- no schema apply;
- no data import;
- no route mutation;
- no service start/enable;
- no cutover.

## Required future phases before rebuild apply

Before any rebuild apply, required phases should include:

1. Phase 14J-HM - guarded CT202 backup only, no rebuild.
2. A post-backup verification record.
3. A no-apply CT202 rebuild script design.
4. A no-apply rollback command design.
5. A no-apply private rehearsal plan.
6. A separate explicit schema/rebuild apply approval gate defined later.

This phase intentionally does not define the rebuild-apply approval phrase.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize a CT202 rebuild.

This phase does not authorize a schema apply.

This phase does not authorize backup creation.

Do not run migration/import/copy/dump from this phase.
