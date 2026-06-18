# Phase 14J-HG - Schema reconciliation decision plan, no apply

Date: 2026-06-17  
Type: no-apply planning / docs-smoke record  
Previous checkpoint: Phase 14J-HF at commit `9f70c5f`

## Purpose

Record a concrete schema reconciliation decision plan after Phase 14J-HF narrowed the CT202 data-authority blockers.

This phase does not select a data authority path and does not apply any schema or data changes.

It converts the HF findings into an ordered no-apply plan for deciding how CT202 should be reconciled before any future import, migration, runtime rehearsal, or controller cutover.

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

## Source evidence from Phase 14J-HF

Phase 14J-HF established:

- shared tables: `23`;
- shared tables with matching safe schema-detail hash: `21`;
- shared tables with mismatched safe schema-detail hash: `2`;
- tables only on laptop: `16`;
- tables only on CT202: `2`;
- overall schema-detail hash match: `no`.

The two shared-table mismatches are:

- `credit_reservations`: laptop columns=`15`, CT202 columns=`17`;
- `workers`: laptop columns=`29`, CT202 columns=`21`.

Critical missing CT202 user-facing tables include:

- `study_decks`;
- `study_cards`;
- `study_sessions`;
- `calendar_events`.

Critical CT202-only credit tables include:

- `credit_ledger`;
- `user_credit_wallets`.

## Reconciliation posture

The project should treat the laptop schema as the current continuity baseline because:

- laptop controller remains live controller/queue authority;
- laptop-local `edge_queue.sqlite3` remains live primary controller data authority;
- laptop has the currently live user/session/job/study/calendar/power state;
- CT202 remains a private candidate only.

This posture does not mean the laptop schema must be copied blindly.

It means CT202 should not become authoritative unless its schema is deliberately reconciled against the laptop continuity baseline or the project explicitly accepts a fresh-start reset.

## Required decision areas

Before any migration/import/cutover approval, the project needs decisions in these areas.

### Decision 1 - Study tables

CT202 is missing Study tables that exist on the laptop.

Decision needed:

- preserve Study data by adding/importing the Study table group;
- intentionally reset Study data under a fresh-start plan;
- or defer Study on CT202 and keep CT202 out of authority.

Recommended default:

Preserve Study data if the platform is intended to keep current user-facing functionality.

Do not split Study tables casually. Treat these as a consistency group:

- `study_decks`;
- `study_cards`;
- `study_reviews`;
- `study_sessions`;
- `study_session_events`;
- `study_deck_totals`;
- `study_user_totals`.

### Decision 2 - Calendar table

CT202 is missing `calendar_events`.

Decision needed:

- preserve current local calendar events;
- intentionally reset local calendar state;
- or declare calendar data non-authoritative because future Google/Apple providers will become source of truth.

Recommended default:

Do not silently drop `calendar_events`. If local calendar is not long-term authority, record a provider-backed transition decision before omission.

### Decision 3 - Credit schema

CT202 has `credit_ledger` and `user_credit_wallets`, while laptop does not.

Both laptop and CT202 have `user_credit_ledger`.

Decision needed:

- keep laptop-style `user_credit_ledger` only;
- migrate toward CT202 wallet/ledger tables;
- support both during transition;
- or rebuild CT202 from laptop schema and defer wallet tables.

Recommended default:

Treat credit schema as high priority. Do not migrate credits until code-path inspection proves which tables the current controller reads/writes.

### Decision 4 - `credit_reservations` mismatch

`credit_reservations` exists on both sides but differs:

- laptop columns: `15`;
- CT202 columns: `17`;
- laptop indexes: `1`;
- CT202 indexes: `3`;
- laptop foreign keys: `1`;
- CT202 foreign keys: `1`.

Decision needed:

- forward-migrate laptop schema to CT202 shape;
- backport CT202 columns/indexes to laptop first;
- or normalize both to one explicit desired schema.

Recommended default:

Inspect controller code paths and migration history before choosing. This table likely affects credit reservation correctness.

### Decision 5 - `workers` mismatch

`workers` exists on both sides but differs:

- laptop columns: `29`;
- CT202 columns: `21`.

The laptop `workers` table includes newer worker lane/default-off metadata columns from prior phases.

Decision needed:

- apply worker lane metadata schema to CT202 candidate DB later;
- rebuild CT202 from laptop schema later;
- or intentionally reset worker rows and create a new CT202 worker schema.

Recommended default:

CT202 should not run as controller authority until the `workers` schema supports the current controller code expectations.

### Decision 6 - Runtime queue state

Laptop has live runtime rows from prior checks:

- `jobs`: `22`;
- `workers`: `2`;
- `user_sessions`: `233`.

Decision needed:

- migrate runtime state;
- drain/cancel jobs before cutover;
- reset worker registry;
- preserve or invalidate sessions.

Recommended default:

Do not blindly import runtime queue state. Create a separate runtime cutover policy for jobs, workers, and sessions.

### Decision 7 - Power/platform tables

Laptop-only power/platform tables likely contain environment-specific controller-host state.

Decision needed:

- recreate CT202-specific state;
- omit laptop power history;
- archive laptop-only power history;
- or transform selected policy rows only.

Recommended default:

Do not import laptop-specific power state blindly into CT202.

## Recommended reconciliation strategy

Recommended no-apply strategy:

1. Treat laptop schema as current continuity baseline.
2. Treat CT202 schema as a candidate that needs reconciliation, not as authority.
3. Decide whether user-facing state should be preserved.
4. If preserving user-facing state, prioritize:
   - Study table group;
   - Calendar table;
   - user/session/account tables;
   - credit/accounting tables.
5. Reconcile `workers` schema before any CT202 runtime rehearsal.
6. Reconcile `credit_reservations` and wallet/ledger tables before any credit migration.
7. Decide runtime state handling separately from schema migration.
8. Only after these decisions, design a backup/import/migration phase.

## Candidate future paths

### Path A - Fresh-start CT202

Use CT202 current schema and accept reset or omission of laptop-only state.

Status:

- technically simplest;
- worst for user continuity;
- requires explicit acceptance of Study/Calendar/session/job/credit impacts.

### Path B - Forward-migrate CT202 schema

Apply missing laptop-compatible tables and required columns to CT202 before selective import.

Status:

- best candidate for preserving user-facing state;
- requires controlled schema migration;
- requires explicit future approval;
- requires backups before any apply.

### Path C - Rebuild CT202 from laptop schema

Recreate CT202 candidate DB from laptop schema and then handle CT202-only wallet/ledger additions deliberately.

Status:

- strongest schema continuity;
- may discard CT202 candidate-only schema drift;
- requires backup/rebuild plan;
- requires explicit future approval.

### Path D - Full laptop DB migration

Move laptop DB to CT202 after freeze/quiesce.

Status:

- strongest data continuity;
- highest operational/split-brain risk;
- requires freeze, backup, rollback, and reconciliation.

## Recommended next safe phase

The recommended next phase is no-apply code-path inspection:

`Phase 14J-HH - read-only code-path table usage inspection, no DB mutation/no apply`

That phase should inspect repository source only to identify which tables the current controller code reads/writes.

It should especially inspect usage of:

- `workers`;
- `credit_reservations`;
- `user_credit_ledger`;
- `credit_ledger`;
- `user_credit_wallets`;
- Study tables;
- Calendar table;
- runtime queue/session tables.

This helps decide whether CT202 should be forward-migrated, rebuilt from laptop schema, selectively imported, or fresh-started.

## Future approval phrase for HH

Suggested future approval phrase:

`APPROVE_PHASE_14J_HH_READ_ONLY_CODE_PATH_TABLE_USAGE_INSPECTION_NO_DB_MUTATION_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

No data authority path is selected by this phase.

Do not run migration/import/copy/dump from this phase.
