# Phase 14J-HE - Schema reconciliation plan, no migration/no apply

Date: 2026-06-17  
Type: no-apply planning / docs-smoke record  
Previous checkpoint: Phase 14J-HD at commit `eed02de`

## Purpose

Record a schema reconciliation plan after Phase 14J-HC proved the live laptop DB and CT202 candidate DB differ by table set and schema hashes.

This phase does not select a data authority path. It does not apply a schema migration. It only defines how to safely reconcile schema differences before any future data import, migration, or controller authority cutover.

## Mutation boundary

This phase is docs/smoke only.

It does not perform:

- CT202 authority cutover;
- data authority path selection;
- CT202 data migration or import;
- schema migration;
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

## Source evidence

Phase 14J-HC found:

- laptop application table count: `39`;
- CT202 application table count: `25`;
- tables on both: `23`;
- tables only on laptop: `16`;
- tables only on CT202: `2`;
- table-list hash match: `no`;
- schema hash match: `no`;
- comparison conclusion: `schemas_differ_or_table_sets_differ_by_safe_hashes`.

Phase 14J-HD recorded that:

- CT202 cannot be promoted as-is under the assumption that it has equivalent data;
- fresh-start, selective import, and full migration remain possible future paths;
- no path has been selected;
- schema reconciliation is required before any migration/import decision.

## Reconciliation objective

Before CT202 can become authoritative, the project must decide which schema should exist on CT202 at cutover time.

The future authoritative CT202 schema must either:

1. match the laptop schema closely enough for full migration;
2. support a strict selective-import allowlist; or
3. intentionally differ under a fresh-start plan with documented user-visible data loss/reset.

This phase does not choose among those outcomes.

## Table classification model

Future schema reconciliation should classify every table into one of these categories:

### Required user-facing state

Tables that likely affect user-visible continuity.

Candidate examples:

- `app_users`;
- `app_user_preferences`;
- `user_sessions`;
- `user_usage_limits`;
- `user_secondary_languages`;
- `study_decks`;
- `study_cards`;
- `study_reviews`;
- `study_sessions`;
- `study_session_events`;
- `study_deck_totals`;
- `study_user_totals`;
- `calendar_events`;
- `support_tickets`;
- `support_messages`.

### Required platform/accounting state

Tables that likely affect credits, limits, billing-like state, rewards, or durable platform accounting.

Candidate examples:

- `user_credit_ledger`;
- `credit_reservations`;
- `ad_reward_events`;
- CT202-only `credit_ledger`;
- CT202-only `user_credit_wallets`.

### Router/reference state

Tables that can often be recreated or reseeded, but may include user customization or audit records.

Candidate examples:

- `intent_definitions`;
- `intent_routes`;
- `global_phrase_bank`;
- `user_phrase_bank`;
- `user_language_preferences`;
- `router_logs`;
- `router_feedback`;
- `router_resolution_steps`.

### Runtime/queue state

Tables that may need special handling because they represent live or stale runtime state.

Candidate examples:

- `jobs`;
- `job_results`;
- `workers`;
- `worker_events`.

### Power/platform operational state

Tables that may be laptop-specific and risky to carry directly into CT202.

Candidate examples:

- `power_auto_state`;
- `power_events`;
- `power_idle_state`;
- `web_power_policy_events`;
- `web_presence`.

### GPU/session history

Tables that may be historical, runtime-specific, or future-feature-related.

Candidate examples:

- `gpu_sessions`;
- `gpu_session_quotes`.

## Laptop-only table handling plan

Phase 14J-HC found these laptop-only tables:

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

Future reconciliation must decide for each laptop-only table:

1. create equivalent table on CT202 before import;
2. transform into a new CT202 schema;
3. intentionally omit under a fresh-start or selective-reset plan;
4. archive only on laptop and do not make CT202 authoritative for that history.

No laptop-only table should be silently dropped without an explicit note.

## CT202-only table handling plan

Phase 14J-HC found these CT202-only tables:

- `credit_ledger`;
- `user_credit_wallets`.

Future reconciliation must determine whether these are:

1. intentional replacements for laptop credit tables;
2. newer schema artifacts that should also exist on laptop before cutover;
3. obsolete or experimental tables that should not become authoritative;
4. migration targets from laptop `user_credit_ledger` and related credit tables.

The credit schema naming drift is the highest-priority reconciliation question.

## Shared-table schema handling plan

For the 23 tables present on both laptop and CT202, table presence alone is not enough.

Future reconciliation should compare safe schema details without printing row content:

- column names;
- column types;
- primary-key definitions;
- NOT NULL constraints;
- default values;
- unique constraints;
- index definitions;
- foreign-key declarations if present;
- migration/version markers if present.

A future read-only schema-detail preflight may be needed before designing any migration.

## Credit schema reconciliation

Known issue:

- laptop has `user_credit_ledger`;
- CT202 has `user_credit_ledger`;
- CT202 also has `credit_ledger` and `user_credit_wallets`;
- laptop safe-table check reported `credit_ledger` and `user_credit_wallets` as missing.

Future reconciliation must answer:

1. Which credit tables are actually used by current laptop controller code?
2. Which credit tables are expected by CT202 code at the current repo checkpoint?
3. Are `credit_ledger` and `user_credit_wallets` newer intended tables or duplicate/legacy drift?
4. Should laptop receive those tables before any full migration?
5. Should CT202 drop or ignore those tables before import?
6. Is a deterministic transformation needed from `user_credit_ledger` to wallet/ledger tables?

No credit data migration should occur until this is decided.

## Study and calendar reconciliation

Laptop has study and calendar tables that CT202 does not.

Future reconciliation must decide:

- whether Study data is production/user-facing and must be preserved;
- whether `calendar_events` is still authoritative or should be provider-backed later;
- whether CT202 should create study/calendar schema before import;
- whether a future selective import should include all study tables as a consistent group.

Do not split study tables casually because totals, reviews, cards, decks, and sessions may depend on each other.

## Runtime queue reconciliation

Laptop has live runtime rows:

- `jobs`: `22`;
- `workers`: `2`;
- `user_sessions`: `233`.

Future reconciliation must decide:

- whether active jobs should be drained, cancelled, archived, or migrated;
- whether worker rows should be reset so workers do not register against both controllers;
- whether user sessions should be preserved or invalidated;
- whether `job_results` should be migrated for history;
- whether `worker_events` should be migrated for audit history.

Runtime tables are high split-brain risk and should not be blindly imported.

## Power/platform reconciliation

Laptop-only power tables are likely controller-host-specific.

Future reconciliation must decide whether CT202 should inherit, reset, or recreate:

- `power_auto_state`;
- `power_events`;
- `power_idle_state`;
- `web_power_policy_events`.

Because CT202 is not the same physical controller host as the laptop, power automation state should be treated as environment-specific unless proven otherwise.

## Recommended reconciliation sequence

Recommended no-apply sequence:

1. Read-only schema-detail preflight for shared tables and credit tables.
2. Code-path inspection to identify which tables the current controller code reads/writes.
3. Table classification document: required, optional, reset, archive-only, or deprecated.
4. Credit schema decision: laptop schema, CT202 schema, or explicit transform.
5. Study/calendar preservation decision.
6. Runtime queue/session policy decision.
7. Select either fresh-start, selective import, or full migration.
8. Only then design backup/import/migration commands.

## Future read-only schema-detail preflight

A future safe read-only preflight may collect:

- table column names;
- table column types;
- primary-key markers;
- NOT NULL flags;
- default value presence labels;
- index names and associated table names;
- foreign-key count by table;
- schema hashes by table.

It must not collect:

- row content;
- token/session values;
- password reset token values;
- auth URLs;
- API keys;
- bearer tokens;
- SQL dumps;
- full CREATE TABLE dumps if they might include sensitive defaults;
- database file copies.

Suggested future approval phrase:

`APPROVE_PHASE_14J_HF_READ_ONLY_SCHEMA_DETAIL_PREFLIGHT_NO_MIGRATION_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

No data authority path is selected by this phase.

## Recommended next safe step

Recommended next safe step:

- either perform the future read-only schema-detail preflight after explicit approval;
- or continue no-apply planning for runtime rehearsal, fallback, or route rollback;
- or perform a Source refresh if this is a stable handoff point.

Do not run migration/import/copy/dump from this phase.
