# Phase 14J-HJ - CT202 candidate rebuild plan, no apply

Date: 2026-06-17  
Type: no-apply design / docs-smoke record  
Previous checkpoint: Phase 14J-HI at commit `c4e0b2a`  
Approval phrase used: `APPROVE_PHASE_14J_HJ_CT202_CANDIDATE_REBUILD_PLAN_NO_APPLY`

## Purpose

Record a detailed no-apply design for the preferred future planning direction from Phase 14J-HI:

**Path C - Rebuild CT202 candidate from laptop continuity schema, then layer intentional deltas.**

This phase does not execute Path C.

This phase does not select a data authority path.

This phase does not authorize a schema apply, data migration, import, service start, route mutation, or cutover.

## Mutation boundary

This phase is docs/smoke only.

It does not perform:

- CT202 authority cutover;
- data authority path selection;
- Path C execution;
- CT202 rebuild execution;
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

## Evidence summary

Phases 14J-HC through 14J-HI established:

- laptop remains live controller and laptop-local DB authority;
- CT202 remains private candidate only;
- CT202 controller service remains disabled/inactive;
- CT202 cutover readiness gate remains CLOSED;
- laptop app table count is `39`;
- CT202 app table count is `25`;
- shared safe schema-detail hash matches exist for `21` of `23` shared tables;
- shared mismatches remain for `workers` and `credit_reservations`;
- CT202 is missing active Study tables;
- CT202 is missing `calendar_events`;
- CT202-only `credit_ledger` and `user_credit_wallets` did not appear in app/runtime code scan;
- `user_credit_ledger`, `credit_reservations`, Study tables, jobs, user sessions, and worker-related paths appear in runtime code;
- Phase 14J-HI recommended Path C as a future planning direction only.

## Rebuild objective

The CT202 candidate rebuild objective is:

Build a private, non-authoritative CT202 candidate schema that matches current laptop continuity needs before any future data movement or runtime rehearsal.

The rebuilt candidate should be able to support current controller code expectations without becoming authority.

## Source of truth

The recommended schema source of truth for the future rebuild design is:

1. current repository runtime bootstrap code, especially `edge_controller.py` and active modules;
2. current laptop continuity schema evidence from Phase 14J-HF;
3. explicit project decisions from Phase 14J-HG and Phase 14J-HI;
4. only then any historical SQL migration artifacts.

Do not treat CT202 current DB as schema truth.

Do not treat CT202-only wallet tables as authoritative unless future code-path work deliberately adopts them.

## Schema groups to preserve in a future rebuild design

A future CT202 rebuild design should preserve these schema groups.

### Account and auth continuity group

Preserve:

- `app_users`;
- `app_user_preferences`;
- `user_sessions`;
- `password_reset_tokens`;
- `pending_email_signups`;
- `user_usage_limits`.

Rationale:

These tables affect login, sessions, accounts, and user limits.

Future runtime policy may still invalidate sessions, but the schema must exist.

### Credit and accounting continuity group

Preserve current runtime-relevant credit schema:

- `user_credit_ledger`;
- `credit_reservations`;
- account credit columns on `app_users`.

Treat as unresolved/future-drift unless explicitly adopted:

- `credit_ledger`;
- `user_credit_wallets`.

Rationale:

HH found `user_credit_ledger` and `credit_reservations` in runtime code. CT202-only wallet tables did not appear in runtime code.

### Study continuity group

Preserve as a consistency group:

- `study_decks`;
- `study_cards`;
- `study_reviews`;
- `study_sessions`;
- `study_session_events`;
- `study_deck_totals`;
- `study_user_totals`.

Rationale:

HH found Study tables in runtime code. CT202 missing these tables blocks Study continuity.

### Calendar continuity group

Preserve:

- `calendar_events`.

Rationale:

HH found `calendar_events` in runtime code. CT202 missing this table blocks local calendar continuity unless a future provider-backed reset is explicitly chosen.

### Queue/runtime schema group

Preserve schema support for:

- `jobs`;
- `job_results`;
- `workers`;
- `worker_events`;
- `web_presence`.

Rationale:

HH found jobs, sessions, worker events, and web presence in runtime code. Runtime rows may be reset later, but the schema must match controller expectations.

### Router/reference group

Preserve:

- `intent_definitions`;
- `intent_routes`;
- `global_phrase_bank`;
- `user_phrase_bank`;
- `user_language_preferences`;
- `router_logs`;
- `router_feedback`;
- `router_resolution_steps`;
- `user_secondary_languages`.

Rationale:

These are low-risk reference/router tables that already mostly matched and support current router foundation planning.

### Support/admin group

Preserve:

- `support_tickets`;
- `support_messages`.

Rationale:

Support/admin functionality should not be silently dropped.

### Optional GPU/session history group

Preserve schema only unless future migration policy says otherwise:

- `gpu_sessions`;
- `gpu_session_quotes`.

Rationale:

These are laptop-only and runtime-adjacent history tables. They can be included in schema while data migration remains a separate decision.

## Schema groups to reset or handle carefully

### Runtime rows

Rows in these tables should not be blindly imported:

- `jobs`;
- `job_results`;
- `workers`;
- `worker_events`;
- `user_sessions`;
- `web_presence`.

Future policy should decide whether to:

- drain jobs before cutover;
- cancel/expire queued jobs;
- reset worker registry;
- regenerate worker rows after CT202 runtime rehearsal;
- preserve or invalidate user sessions;
- reset web presence.

### Power/platform rows

Tables needing environment-specific policy:

- `power_auto_state`;
- `power_events`;
- `power_idle_state`;
- `web_power_policy_events`.

Recommended posture:

Include schema only if current controller code needs it, but do not blindly import laptop-specific power rows into CT202.

### CT202-only wallet drift

Tables:

- `credit_ledger`;
- `user_credit_wallets`.

Recommended posture:

Do not let these tables define authority. Treat them as candidate/future drift until a later code change intentionally uses them.

Options for future design:

- omit them from the rebuilt candidate;
- archive them before rebuild;
- reintroduce them later behind explicit code-path adoption;
- map them to current `user_credit_ledger` only after an explicit credit schema decision.

## Required future artifacts before any apply

Before any actual rebuild/apply, create no-apply artifacts for:

1. target schema manifest;
2. table group classification;
3. omitted-table decision list;
4. CT202-only drift decision list;
5. runtime row policy;
6. credit schema target decision;
7. Study/Calendar continuity policy;
8. backup plan;
9. rollback plan;
10. rehearsal plan;
11. cutover gate checklist.

## Future rebuild design sequence

Recommended sequence:

1. Create a target schema manifest from the selected source of truth.
2. Review the manifest against HF/HH evidence.
3. Decide CT202-only drift handling.
4. Decide runtime row handling.
5. Create a no-apply rebuild script design.
6. Create a backup and rollback plan.
7. Create a private rehearsal plan.
8. Only after explicit future approval, perform a guarded backup.
9. Only after separate explicit future approval, apply schema rebuild to CT202 candidate.
10. Keep CT202 service disabled/inactive until a separate runtime rehearsal gate.
11. Keep public routes unchanged until a separate cutover gate.

## Non-goals

This rebuild plan does not intend to:

- migrate live data now;
- apply schema now;
- start CT202 services;
- enable CT202 on boot;
- stop laptop controller;
- pause laptop controller;
- mutate Cloudflare or DNS;
- mutate public routes;
- call CT101;
- call a model/Ollama endpoint;
- start workers;
- choose production authority.

## Recommended future approval gates

Future gates should remain separate.

### Gate 1 - Target manifest only

Approval phrase:

`APPROVE_PHASE_14J_HK_CT202_TARGET_SCHEMA_MANIFEST_NO_APPLY`

Purpose:

Create a no-apply target schema manifest and table group checklist.

### Gate 2 - Backup plan only

Approval phrase:

`APPROVE_PHASE_14J_HL_CT202_REBUILD_BACKUP_ROLLBACK_PLAN_NO_APPLY`

Purpose:

Design backup/rollback steps without running them.

### Gate 3 - Guarded backup only

Approval phrase:

`APPROVE_PHASE_14J_HM_CT202_GUARDED_BACKUP_ONLY_NO_REBUILD`

Purpose:

Create a CT202 backup only, still no rebuild.

### Gate 4 - Rebuild apply

Approval phrase to be defined later.

Purpose:

Apply the CT202 candidate schema rebuild only after backups, rollback, and manifest review exist.

This phase does not define the rebuild-apply approval phrase to avoid accidental execution.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HK - CT202 target schema manifest, no apply`

That phase should remain docs/smoke-only or source-inspection-only and should produce:

- target table list;
- table group classification;
- intended source of truth for each group;
- include/omit/reset decision for each table;
- explicit drift handling for `credit_ledger` and `user_credit_wallets`;
- explicit mismatch handling for `workers` and `credit_reservations`.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize a CT202 rebuild.

Do not run migration/import/copy/dump from this phase.
