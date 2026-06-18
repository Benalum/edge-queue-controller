# Phase 14J-HI - No-apply reconciliation path recommendation

Date: 2026-06-17  
Type: recommendation-only / docs-smoke record  
Previous checkpoint: Phase 14J-HH at commit `8627f84`  
Approval phrase used: `APPROVE_PHASE_14J_HI_NO_APPLY_RECONCILIATION_PATH_RECOMMENDATION`

## Purpose

Record a no-apply reconciliation path recommendation using the evidence from Phases 14J-HC through 14J-HH.

This phase recommends a preferred future planning direction, but it does not select a data authority path and does not authorize any migration, import, schema change, runtime activation, route mutation, or cutover.

## Mutation boundary

This phase is docs/smoke only.

It does not perform:

- CT202 authority cutover;
- data authority path selection;
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

## Evidence base

### Phase 14J-HC

Read-only data-authority preflight found:

- laptop application table count: `39`;
- CT202 application table count: `25`;
- table-list hash match: `no`;
- schema hash match: `no`;
- CT202 cutover readiness gate remained CLOSED.

### Phase 14J-HF

Read-only safe schema-detail preflight narrowed the mismatch:

- shared tables: `23`;
- shared tables with matching detail hash: `21`;
- shared tables with mismatched detail hash: `2`;
- tables only on laptop: `16`;
- tables only on CT202: `2`;
- overall schema-detail hash match: `no`.

The two shared-table schema-detail mismatches were:

- `credit_reservations`: laptop columns=`15`, CT202 columns=`17`;
- `workers`: laptop columns=`29`, CT202 columns=`21`.

Critical CT202 missing tables included:

- `study_decks`;
- `study_cards`;
- `study_reviews`;
- `study_sessions`;
- `study_session_events`;
- `study_deck_totals`;
- `study_user_totals`;
- `calendar_events`;
- `job_results`;
- power/platform state tables.

CT202-only credit tables included:

- `credit_ledger`;
- `user_credit_wallets`.

### Phase 14J-HG

The no-apply decision plan identified the required decision areas:

- Study table continuity;
- Calendar table continuity;
- credit schema handling;
- `credit_reservations` mismatch;
- `workers` mismatch;
- runtime queue/session state;
- power/platform tables.

### Phase 14J-HH

Read-only code-path inspection found:

- `workers` appears in runtime code, so the `workers` schema mismatch is runtime-critical;
- `credit_reservations` appears in runtime code, so its schema mismatch is credit/accounting-critical;
- CT202-only `credit_ledger` and `user_credit_wallets` did not appear in app/runtime code scan;
- `user_credit_ledger` appears in runtime code and likely remains the current relevant ledger;
- Study tables appear in runtime code, so CT202 missing Study tables blocks Study continuity;
- `calendar_events` appears in runtime code, so CT202 missing `calendar_events` blocks local calendar continuity;
- `jobs` and `user_sessions` appear in runtime code, so a runtime cutover policy is required.

The HH scan included `.cleanup-archive` paths, so aggregate totals were noisy. However, the high-priority findings had active runtime evidence in current files such as `edge_controller.py` and `edge_modules/credits.py`.

## Candidate paths reviewed

### Path A - Fresh-start CT202

Summary:

Use CT202 as-is or close to as-is and accept reset/omission of laptop-only state.

Pros:

- simplest operationally;
- avoids complex data migration logic;
- avoids importing old runtime state.

Cons:

- loses or omits current Study continuity unless explicitly rebuilt;
- loses or omits local Calendar continuity unless explicitly rebuilt;
- ignores current laptop live user-facing state;
- still leaves `workers` and `credit_reservations` schema mismatches unresolved against current runtime code;
- requires explicit acceptance of continuity loss.

Recommendation:

Do not use Path A as the default. It is only acceptable if the project explicitly chooses a fresh-start/reset posture for Study, Calendar, sessions, jobs, and credit/accounting continuity.

### Path B - Forward-migrate CT202 schema

Summary:

Keep the CT202 candidate DB and add the missing laptop-continuity schema pieces and current runtime-required columns.

Pros:

- incremental;
- preserves CT202 candidate host/container setup;
- can add only the missing/mismatched pieces;
- may allow controlled future selective data migration.

Cons:

- requires careful migration scripts;
- requires resolving CT202-only wallet/ledger drift;
- risks layering migrations onto an already drifted candidate DB;
- may need multiple small guarded applies before CT202 is equivalent enough for rehearsal.

Recommendation:

Path B is viable if the project wants incremental CT202 repair. It should not be applied until a later explicit schema-apply plan exists.

### Path C - Rebuild CT202 candidate from laptop continuity schema, then layer intentional deltas

Summary:

Treat laptop schema as the current continuity baseline, rebuild or regenerate CT202 candidate schema to match that baseline, then deliberately decide whether any CT202-only/future tables should be added afterward.

Pros:

- best schema-continuity starting point;
- aligns with current runtime code evidence;
- avoids silently inheriting CT202 candidate drift;
- makes Study/Calendar continuity explicit;
- avoids letting unused CT202-only wallet tables drive authority decisions;
- gives the cleanest base for later selective data migration or rehearsal.

Cons:

- still requires explicit future approval before any rebuild or schema apply;
- still requires backup and rollback design;
- still requires runtime-state policy before any cutover;
- still requires careful treatment of CT202 service disabled/inactive posture.

Recommendation:

Path C is the preferred future planning direction, but it is not selected or authorized by this phase.

The recommended future approach is:

1. design a CT202 candidate schema-rebuild plan that starts from the laptop continuity schema;
2. preserve current user-facing schema groups such as Study and Calendar;
3. include current runtime-required `workers` lane metadata columns;
4. use current runtime `user_credit_ledger` as the relevant credit ledger unless code changes intentionally adopt wallet tables;
5. treat CT202-only `credit_ledger` and `user_credit_wallets` as candidate/future drift until proven otherwise;
6. design future data movement separately from schema reconciliation;
7. keep the CT202 cutover gate CLOSED until a complete backup, rollback, rehearsal, and cutover plan exists.

### Path D - Full laptop DB migration

Summary:

Move the laptop DB wholesale to CT202 after freeze/quiesce.

Pros:

- strongest data continuity;
- preserves current users, sessions, Study, Calendar, jobs, worker events, and platform state exactly as of freeze time.

Cons:

- highest operational risk;
- requires freeze/quiesce;
- may carry laptop-specific power/platform state into CT202;
- can create split-brain if the laptop continues writing;
- requires backups, rollback, service stop/start sequencing, and exact route/cutover controls.

Recommendation:

Do not use Path D as the immediate planning default. It may become useful later if a full freeze/copy cutover is explicitly chosen, but it should not be the next design target.

## Recommended path

The recommended future planning path is:

**Path C - Rebuild CT202 candidate from laptop continuity schema, then layer intentional deltas.**

This is only a recommendation. It is not a data authority path selection and not an apply approval.

## Why Path C is preferred

Path C best fits the current evidence because:

1. The laptop is the live controller/data authority.
2. Current runtime code aligns with laptop-style tables such as `user_credit_ledger`.
3. CT202 is missing active user-facing Study tables.
4. CT202 is missing active local Calendar state.
5. CT202 `workers` lacks current lane/default-off metadata columns.
6. CT202 `credit_reservations` differs from the current laptop/runtime shape.
7. CT202-only wallet tables did not appear in runtime code.
8. CT202 is private, disabled/inactive, and not authoritative, so it can be redesigned before any cutover.
9. Rebuilding the candidate schema is cleaner than layering unknown drift onto a private candidate DB.

## What Path C must still decide before any apply

Path C still requires future no-apply design work before any execution:

- exact source of schema truth;
- whether schema should be generated from current code bootstrap, SQL migration files, or a sanitized schema extract;
- which CT202-only tables should be omitted, archived, or reintroduced;
- whether wallet tables are future schema or discarded drift;
- whether `credit_reservations` should match laptop or a new intended target;
- whether all Study tables must be included as a consistency group;
- whether local `calendar_events` should be included or explicitly reset;
- which runtime tables are migrated, reset, drained, or regenerated;
- how laptop-specific power/platform rows are handled;
- backup and rollback design;
- rehearsal criteria;
- cutover gate criteria.

## Recommended next safe phase

Recommended next safe phase:

`Phase 14J-HJ - CT202 candidate rebuild plan, no apply`

That phase should remain docs/smoke-only and produce a detailed no-apply design for Path C.

It should define:

- schema source of truth;
- schema groups to preserve;
- schema groups to omit or reset;
- CT202-only drift handling;
- runtime-state policy outline;
- backup/rollback prerequisites;
- rehearsal prerequisites;
- explicit future approval gates.

## Future approval phrase for HJ

Suggested future approval phrase:

`APPROVE_PHASE_14J_HJ_CT202_CANDIDATE_REBUILD_PLAN_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

Do not run migration/import/copy/dump from this phase.
