# Phase 14J-HD - Data authority decision matrix and schema reconciliation options, no apply

Date: 2026-06-17  
Type: no-apply planning / docs-smoke record  
Previous checkpoint: Phase 14J-HC at commit `205e90f`

## Purpose

Record a decision matrix for the future CT202 data-authority path after the Phase 14J-HC read-only preflight proved that the laptop live DB and CT202 candidate DB are not equivalent.

This phase does not select a data authority path. It only documents options, risks, prerequisites, and safe next steps.

## Mutation boundary

This phase is docs/smoke only.

It does not perform:

- CT202 authority cutover;
- data authority path selection;
- CT202 data migration or import;
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

## Source evidence from Phase 14J-HC

Phase 14J-HC established:

- laptop DB quick_check: `ok`;
- CT202 DB quick_check: `ok`;
- laptop application table count: `39`;
- CT202 application table count: `25`;
- tables on both: `23`;
- tables only on laptop: `16`;
- tables only on CT202: `2`;
- table-list hash match: `no`;
- schema hash match: `no`;
- comparison conclusion: `schemas_differ_or_table_sets_differ_by_safe_hashes`.

Phase 14J-HC also confirmed:

- no DB import, migration, copy, or dump was performed;
- no row content was printed;
- no data authority path was selected;
- CT202 remained private and non-authoritative;
- the CT202 controller cutover readiness gate remained CLOSED.

## Current data-authority problem

CT202 cannot be promoted as-is under the assumption that it has equivalent data.

The laptop DB contains live platform and operational state that CT202 does not currently have, including current jobs, workers, user sessions, study tables, calendar table, power state tables, reward/ad table, GPU session tables, and job results.

CT202 also contains two tables that were missing from the laptop safe-table check:

- `credit_ledger`;
- `user_credit_wallets`.

Those may represent naming/schema drift compared with the laptop `user_credit_ledger` and related credit tables. This must be reconciled before selecting a migration/import path.

## Laptop-only tables from HC

Phase 14J-HC found these tables only on the laptop:

- `ad_reward_events`;
- `calendar_events`;
- `gpu_session_quotes`;
- `gpu_sessions`;
- `job_results`;
- `power_auto_state`;
- `power_events`;
- `power_idle_state`;
- `study_cards`;
- `study_deck_totals`;
- `study_decks`;
- `study_reviews`;
- `study_session_events`;
- `study_sessions`;
- `study_user_totals`;
- `web_power_policy_events`.

## CT202-only tables from HC

Phase 14J-HC found these tables only on CT202:

- `credit_ledger`;
- `user_credit_wallets`.

## Decision matrix

### Option A - Fresh-start CT202 authority

Summary:

CT202 becomes controller authority using its current candidate DB, accepting that laptop live platform state is not migrated.

Advantages:

- simplest technical cutover;
- avoids complex data transformation;
- avoids importing stale or experimental laptop operational history;
- lowers migration risk from incompatible schemas.

Major risks:

- active jobs would not carry over;
- worker registry state would reset;
- user sessions would reset;
- study data and calendar data would not carry over;
- reward/ad and credit-related state may be lost or inconsistent;
- operational power history and job results would not carry over;
- users may experience data loss or account/session discontinuity.

Minimum prerequisites before approval:

- explicitly accept state reset or limited data loss;
- list which user-facing features are safe to reset;
- confirm no active jobs must be preserved;
- confirm sessions may be invalidated;
- confirm study/calendar/credits impact is acceptable;
- define rollback behavior if laptop remains source of historical state;
- update public/admin copy if users are affected.

Recommended status:

Not recommended for production user continuity unless the project explicitly decides that current laptop data is disposable.

### Option B - Selective import

Summary:

Choose a strict allowlist of laptop tables to import into CT202 after schema compatibility is proven.

Advantages:

- can preserve important user-facing state without copying everything;
- avoids importing transient power/runtime history if not needed;
- allows deliberate handling of schema drift;
- can keep CT202 cleaner than a full clone.

Major risks:

- missing dependencies between tables could break features;
- foreign-key-like relationships may be implicit even if not enforced;
- schema drift must be reconciled first;
- imported rows may conflict with CT202 seed rows;
- selected tables may need ordered import and validation;
- rollback after CT202 accepts writes still requires reconciliation.

Candidate table groups to evaluate:

1. Identity and sessions:
   - `app_users`;
   - `app_user_preferences`;
   - `user_sessions`;
   - `password_reset_tokens`;
   - `pending_email_signups`;
   - `user_usage_limits`;
   - `user_secondary_languages`.

2. Credits and ads:
   - `user_credit_ledger`;
   - `credit_reservations`;
   - `ad_reward_events`;
   - CT202-only `credit_ledger`;
   - CT202-only `user_credit_wallets`.

3. Study:
   - `study_decks`;
   - `study_cards`;
   - `study_reviews`;
   - `study_sessions`;
   - `study_session_events`;
   - `study_deck_totals`;
   - `study_user_totals`.

4. Calendar:
   - `calendar_events`.

5. Router:
   - `intent_definitions`;
   - `intent_routes`;
   - `global_phrase_bank`;
   - `user_phrase_bank`;
   - `user_language_preferences`;
   - `router_logs`;
   - `router_feedback`;
   - `router_resolution_steps`.

6. Queue/runtime:
   - `jobs`;
   - `job_results`;
   - `workers`;
   - `worker_events`.

7. Power/platform:
   - `power_auto_state`;
   - `power_events`;
   - `power_idle_state`;
   - `web_power_policy_events`;
   - `web_presence`.

8. GPU/session history:
   - `gpu_sessions`;
   - `gpu_session_quotes`.

9. Support:
   - `support_tickets`;
   - `support_messages`.

Minimum prerequisites before approval:

- table allowlist;
- table dependency review;
- schema reconciliation plan;
- ordered import plan;
- conflict policy for existing CT202 rows;
- backup plan;
- post-import quick_check and row-count validation;
- rollback plan;
- split-brain prevention plan.

Recommended status:

Best candidate if the goal is to preserve user-facing state while avoiding unnecessary runtime/power history.

### Option C - Full migration

Summary:

Migrate the laptop DB into CT202 as the controller authority DB.

Advantages:

- preserves the most state;
- easiest user continuity story;
- avoids hand-picking table dependencies;
- keeps historical operational tables available for later inspection.

Major risks:

- imports laptop-specific runtime/power state that may not apply to CT202;
- may carry stale worker registrations or active jobs;
- requires write freeze or quiesce before final copy;
- requires careful backup and rollback;
- requires split-brain prevention;
- may need schema compatibility checks before final copy;
- rollback after CT202 accepts writes requires reconciliation.

Minimum prerequisites before approval:

- laptop controller write freeze or quiesce plan;
- active job drain/cancel/hold policy;
- worker registration policy;
- session policy;
- backup before migration;
- CT202 stop/no-listener guard before file replacement or import;
- post-migration quick_check;
- schema hash validation;
- row-count validation;
- route rollback plan;
- split-brain prevention proof.

Recommended status:

Most complete for continuity, but highest operational risk. It should only be considered with a strict freeze, backup, rollback, and reconciliation plan.

## Schema reconciliation needs

Before selecting selective import or full migration, the project needs a schema reconciliation plan.

Known reconciliation questions:

1. Why does CT202 have `credit_ledger` and `user_credit_wallets` while the laptop safe check reports those as missing?
2. Should CT202 use the laptop credit schema, the CT202 credit schema, or a migration from one naming model to the other?
3. Should laptop-only study tables be created on CT202 before import?
4. Should laptop-only calendar and power tables exist on CT202 before cutover?
5. Should runtime tables such as `jobs`, `workers`, `worker_events`, and `job_results` be migrated, reset, or transformed?
6. Should sessions be preserved or invalidated at cutover?
7. Should router seed tables be reseeded, imported, or merged?
8. Which tables are user-facing and which are disposable operational history?

## Recommended next no-apply path

The recommended next no-apply phase is a schema reconciliation plan focused on:

- table ownership groups;
- required vs optional tables;
- laptop-only table handling;
- CT202-only table handling;
- credit schema naming drift;
- user/session preservation policy;
- runtime queue table policy;
- study/calendar preservation policy;
- exact future approval phrases for any backup/import/migration phase.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

No data authority path is selected by this phase.

## Future approvals still required

Future phases still require explicit approval before any of these:

- read or compare more detailed schema information beyond safe metadata;
- backup creation;
- DB file copy;
- SQL export;
- SQL import;
- schema migration;
- row import;
- CT202 runtime start;
- CT202 persistent runtime enablement;
- CT202 onboot/autostart mutation;
- public route mutation;
- laptop controller stop or pause;
- controller authority cutover.

