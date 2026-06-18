# Phase 14J-HK - CT202 target schema manifest, no apply

Date: 2026-06-17  
Type: no-apply target schema manifest / docs-smoke record  
Previous checkpoint: Phase 14J-HJ at commit `b428ceb`  
Approval phrase used: `APPROVE_PHASE_14J_HK_CT202_TARGET_SCHEMA_MANIFEST_NO_APPLY`

## Purpose

Record a no-apply target schema manifest for a future CT202 candidate rebuild design.

This phase follows the Phase 14J-HJ CT202 candidate rebuild plan.

This manifest describes the intended schema groups, include/omit/reset decisions, source-of-truth posture, and unresolved decisions before any future CT202 candidate rebuild.

This phase does not execute a rebuild.

This phase does not select a data authority path.

This phase does not authorize schema apply, backup, migration, import, runtime activation, route mutation, or cutover.

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

## Manifest principle

The target manifest uses laptop continuity schema as the planning baseline because the laptop remains live controller and laptop-local DB authority.

CT202 remains private candidate only.

CT202 current DB is not treated as schema truth.

CT202-only wallet tables are not treated as authoritative unless future code explicitly adopts them.

## Target manifest summary

Target manifest posture:

- include current laptop continuity schema groups;
- include active user-facing Study and Calendar schema;
- include queue/runtime schema support while deferring runtime row policy;
- include current runtime-relevant credit schema;
- treat CT202-only wallet tables as drift/future-candidate tables;
- include schema for laptop-only power/platform tables only with environment-specific row reset policy;
- do not import rows in this phase;
- do not apply schema in this phase.

## Target table list by group

### Account and auth continuity group

Decision: include schema.

Tables:

- `app_users`;
- `app_user_preferences`;
- `user_sessions`;
- `password_reset_tokens`;
- `pending_email_signups`;
- `user_usage_limits`.

Source of truth:

- current laptop continuity schema;
- current runtime bootstrap/code paths.

Row policy for future phase:

- preserve account rows only after explicit migration approval;
- decide separately whether to preserve or invalidate `user_sessions`.

Reason:

Account/auth schema is required for login, session validation, account preferences, and user limits.

### Credit and accounting continuity group

Decision: include current runtime-relevant schema.

Tables:

- `user_credit_ledger`;
- `credit_reservations`.

Also preserve account credit columns on:

- `app_users`.

Source of truth:

- current laptop continuity schema;
- runtime code evidence from Phase 14J-HH.

Mismatch handling:

- `credit_reservations` must be reconciled because laptop has `15` columns and CT202 has `17` columns.
- The target manifest should not assume CT202's extra columns are authoritative until code inspection or explicit design adopts them.

Row policy for future phase:

- preserve or transform rows only after explicit credit migration approval;
- never silently reset paid/free credit state.

Reason:

`user_credit_ledger` and `credit_reservations` appear in runtime code.

### CT202-only credit drift group

Decision: omit from target schema for initial continuity rebuild unless future code adoption is explicitly approved.

Tables:

- `credit_ledger`;
- `user_credit_wallets`.

Source of truth:

- none for current runtime.
- Phase 14J-HH found app/runtime refs=`0` for these tables.

Row policy for future phase:

- archive CT202 drift before any rebuild if needed;
- do not map or import these tables without a separate credit schema decision.

Reason:

These tables exist only on CT202 and did not appear in runtime code scan. They should not drive current authority.

### Study continuity group

Decision: include schema as a consistency group.

Tables:

- `study_decks`;
- `study_cards`;
- `study_reviews`;
- `study_sessions`;
- `study_session_events`;
- `study_deck_totals`;
- `study_user_totals`.

Source of truth:

- laptop continuity schema;
- runtime code evidence from Phase 14J-HH.

Row policy for future phase:

- preserve Study rows only after explicit data migration approval;
- do not split this group casually;
- if reset is chosen later, it must be explicit.

Reason:

Study tables appear in runtime code and CT202 is missing these tables.

### Calendar continuity group

Decision: include schema.

Tables:

- `calendar_events`.

Source of truth:

- laptop continuity schema;
- runtime code evidence from Phase 14J-HH.

Row policy for future phase:

- preserve local calendar rows only after explicit data migration approval;
- if future Google/Apple provider migration replaces local calendar, that reset must be explicit.

Reason:

`calendar_events` appears in runtime code and CT202 is missing it.

### Queue/runtime schema group

Decision: include schema, defer row policy.

Tables:

- `jobs`;
- `job_results`;
- `workers`;
- `worker_events`;
- `web_presence`.

Source of truth:

- laptop continuity schema;
- current runtime code;
- worker lane metadata phases.

Mismatch handling:

- `workers` must include current laptop lane/default-off metadata columns because laptop has `29` columns and CT202 has `21` columns.

Row policy for future phase:

- do not blindly import runtime rows;
- decide whether to drain, cancel, reset, or preserve jobs;
- reset worker registry unless an explicit worker-state preservation plan exists;
- decide whether sessions and web presence should be reset or preserved.

Reason:

Jobs, workers, worker events, sessions, and web presence are runtime-sensitive and can cause split-brain if moved without a cutover policy.

### Router/reference group

Decision: include schema.

Tables:

- `intent_definitions`;
- `intent_routes`;
- `global_phrase_bank`;
- `user_phrase_bank`;
- `user_language_preferences`;
- `user_secondary_languages`;
- `router_logs`;
- `router_feedback`;
- `router_resolution_steps`.

Source of truth:

- current laptop continuity schema;
- router foundation code and docs.

Row policy for future phase:

- reference/seed rows may be migrated or reseeded by explicit plan;
- user phrase/language preference rows need explicit user-data policy.

Reason:

These tables support router/reference planning and mostly matched across laptop/CT202.

### Support/admin group

Decision: include schema.

Tables:

- `support_tickets`;
- `support_messages`.

Source of truth:

- laptop continuity schema;
- runtime/admin code.

Row policy for future phase:

- preserve or reset support rows only after explicit decision.

Reason:

Support/admin functionality should not be silently dropped.

### Ad/reward group

Decision: include schema.

Tables:

- `ad_reward_events`.

Source of truth:

- laptop continuity schema;
- current controller credit/reward design.

Row policy for future phase:

- preserve or reset rewarded-ad history only after explicit decision;
- never use this table to mutate credit balances without credit policy.

Reason:

This is laptop-only and related to credit/reward accounting.

### GPU/session history group

Decision: include schema, likely reset rows unless explicit history preservation is chosen.

Tables:

- `gpu_sessions`;
- `gpu_session_quotes`.

Source of truth:

- laptop continuity schema.

Row policy for future phase:

- default to schema-only inclusion;
- preserve rows only after explicit history policy.

Reason:

These are laptop-only and historical/runtime-adjacent.

### Power/platform group

Decision: include schema if current controller expects it, but reset or regenerate rows for CT202.

Tables:

- `power_auto_state`;
- `power_events`;
- `power_idle_state`;
- `web_power_policy_events`.

Source of truth:

- laptop continuity schema for table structure only.

Row policy for future phase:

- do not import laptop-specific power/platform rows blindly;
- regenerate CT202-specific state during a later private rehearsal;
- keep CT202 service disabled/inactive until explicit runtime rehearsal approval.

Reason:

Power/platform rows are environment-specific and can cause incorrect host behavior if copied.

## Target include list

The target schema manifest includes these `39` laptop continuity tables:

- `ad_reward_events`;
- `app_user_preferences`;
- `app_users`;
- `calendar_events`;
- `credit_reservations`;
- `global_phrase_bank`;
- `gpu_session_quotes`;
- `gpu_sessions`;
- `intent_definitions`;
- `intent_routes`;
- `job_results`;
- `jobs`;
- `password_reset_tokens`;
- `pending_email_signups`;
- `power_auto_state`;
- `power_events`;
- `power_idle_state`;
- `router_feedback`;
- `router_logs`;
- `router_resolution_steps`;
- `study_cards`;
- `study_deck_totals`;
- `study_decks`;
- `study_reviews`;
- `study_session_events`;
- `study_sessions`;
- `study_user_totals`;
- `support_messages`;
- `support_tickets`;
- `user_credit_ledger`;
- `user_language_preferences`;
- `user_phrase_bank`;
- `user_secondary_languages`;
- `user_sessions`;
- `user_usage_limits`;
- `web_power_policy_events`;
- `web_presence`;
- `worker_events`;
- `workers`.

## Target omit/defer list

The target schema manifest omits or defers these CT202-only tables for initial continuity rebuild:

- `credit_ledger`;
- `user_credit_wallets`.

Reason:

They were CT202-only and did not appear in app/runtime code scan. They are not current continuity baseline.

They may be reconsidered in a later credit schema redesign.

## Target mismatch decisions

### workers

Target decision:

- target should match laptop/current runtime-compatible `workers` schema;
- include current lane/default-off metadata columns.

Reason:

The laptop has `29` columns, CT202 has `21`, and `workers` is runtime-critical.

### credit_reservations

Target decision:

- target should be explicitly designed from current runtime code and laptop continuity evidence;
- do not automatically use CT202's extra columns as authoritative;
- do not apply until a future manifest-to-code review confirms the intended target.

Reason:

`credit_reservations` appears in runtime credit/accounting code and differs between laptop and CT202.

## Reset/defer row policy

This manifest is schema-only.

Future data movement policy is still required for:

- account rows;
- sessions;
- credit rows;
- Study rows;
- Calendar rows;
- job rows;
- worker registry rows;
- web presence rows;
- power/platform rows;
- support rows;
- router/user preference rows;
- GPU/session history rows.

## Required future review before backup/apply

Before any future backup or apply, create a follow-up no-apply review that verifies:

1. target table list exactly matches the intended manifest;
2. omitted CT202-only wallet tables are intentionally handled;
3. `workers` target shape includes lane/default-off metadata;
4. `credit_reservations` target shape is explicitly chosen;
5. Study table group is complete;
6. Calendar table is included or explicitly reset;
7. runtime row policy is documented;
8. CT202 service remains disabled/inactive;
9. cutover gate remains closed.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HL - CT202 rebuild backup and rollback plan, no apply`

That phase should design:

- what to back up;
- where backup artifacts should live;
- how to verify backup integrity;
- rollback order;
- what must remain disabled;
- what must not be touched;
- what approvals are required before backup-only execution.

## Future approval phrase for HL

Suggested future approval phrase:

`APPROVE_PHASE_14J_HL_CT202_REBUILD_BACKUP_ROLLBACK_PLAN_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize a CT202 rebuild.

This phase does not authorize a schema apply.

Do not run migration/import/copy/dump from this phase.
