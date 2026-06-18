# Phase 14J-HC - Read-only data-authority preflight, no import/no apply

Date: 2026-06-17  
Type: approved read-only live preflight / docs-smoke record  
Previous checkpoint: Phase 14J-HB at commit `aeff83c`  
Approval phrase used: `APPROVE_PHASE_14J_HC_READ_ONLY_DATA_AUTHORITY_PREFLIGHT_NO_IMPORT_NO_APPLY`

## Purpose

Record the approved read-only data-authority preflight comparing safe structure metadata for:

- laptop-local live controller DB: `edge_queue.sqlite3`;
- CT202 candidate DB: `/srv/edge-controller/data/edge_queue.sqlite3`.

This phase confirms the laptop DB and CT202 candidate DB are not equivalent and that no data-authority path has been selected.

## Mutation boundary

This phase was read-only.

It did not perform:

- CT202 authority cutover;
- CT202 data migration or import;
- SQLite copy;
- SQL dump;
- table data dump;
- row content output;
- live laptop DB mutation;
- CT202 DB mutation;
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

## Repo guard

The read-only preflight started from:

- HEAD: `aeff83c`;
- local `origin/main`: `aeff83c`;
- working tree: clean.

## Laptop DB read-only preflight result

Laptop DB safe metadata:

- DB exists: `True`;
- DB file size: `43220992` bytes;
- SQLite quick_check: `ok`;
- application table count: `39`;
- index count: `18`;
- trigger count: `0`;
- view count: `0`;
- schema hash SHA256: `43acb940270daee930879fa8d09c8491154a2dfa4f83ddbf3087dabbd61dafec`;
- table-list hash SHA256: `2c06687b7a7011a315c2287f35a7ae17478e7b1f75e71c425d224ec2b0d8d345`.

Laptop tables:

- `ad_reward_events`
- `app_user_preferences`
- `app_users`
- `calendar_events`
- `credit_reservations`
- `global_phrase_bank`
- `gpu_session_quotes`
- `gpu_sessions`
- `intent_definitions`
- `intent_routes`
- `job_results`
- `jobs`
- `password_reset_tokens`
- `pending_email_signups`
- `power_auto_state`
- `power_events`
- `power_idle_state`
- `router_feedback`
- `router_logs`
- `router_resolution_steps`
- `study_cards`
- `study_deck_totals`
- `study_decks`
- `study_reviews`
- `study_session_events`
- `study_sessions`
- `study_user_totals`
- `support_messages`
- `support_tickets`
- `user_credit_ledger`
- `user_language_preferences`
- `user_phrase_bank`
- `user_secondary_languages`
- `user_sessions`
- `user_usage_limits`
- `web_power_policy_events`
- `web_presence`
- `worker_events`
- `workers`

Laptop safe row counts:

- `credit_ledger`: `missing`;
- `global_phrase_bank`: `34`;
- `intent_definitions`: `14`;
- `intent_routes`: `14`;
- `jobs`: `22`;
- `router_logs`: `0`;
- `user_credit_wallets`: `missing`;
- `user_language_preferences`: `0`;
- `user_phrase_bank`: `0`;
- `user_sessions`: `233`;
- `workers`: `2`.

## CT202 safety posture before comparison

CT202 was checked before reading its DB:

- container status: running;
- hostname: `edge-controller`;
- onboot: `0`;
- service enabled state: `disabled`;
- service active state: `inactive`;
- no checked controller/smoke listener active.

CT202 remained private and non-authoritative throughout the preflight.

## CT202 DB read-only preflight result

CT202 DB safe metadata:

- DB exists: `True`;
- DB file size: `262144` bytes;
- SQLite quick_check: `ok`;
- application table count: `25`;
- index count: `16`;
- trigger count: `0`;
- view count: `0`;
- schema hash SHA256: `482fac6158f73033f56fe354b31719f80ee64dfdc3595d83a9a41868ff1da203`;
- table-list hash SHA256: `8782b953781558a81cfc0ac0473a5cfa1862763bb8e2f731258daf0c93cac817`.

CT202 tables:

- `app_user_preferences`
- `app_users`
- `credit_ledger`
- `credit_reservations`
- `global_phrase_bank`
- `intent_definitions`
- `intent_routes`
- `jobs`
- `password_reset_tokens`
- `pending_email_signups`
- `router_feedback`
- `router_logs`
- `router_resolution_steps`
- `support_messages`
- `support_tickets`
- `user_credit_ledger`
- `user_credit_wallets`
- `user_language_preferences`
- `user_phrase_bank`
- `user_secondary_languages`
- `user_sessions`
- `user_usage_limits`
- `web_presence`
- `worker_events`
- `workers`

CT202 safe row counts:

- `credit_ledger`: `0`;
- `global_phrase_bank`: `0`;
- `intent_definitions`: `0`;
- `intent_routes`: `0`;
- `jobs`: `0`;
- `router_logs`: `0`;
- `user_credit_wallets`: `0`;
- `user_language_preferences`: `0`;
- `user_phrase_bank`: `0`;
- `user_sessions`: `0`;
- `workers`: `0`.

## Safe comparison summary

Comparison results:

- laptop application table count: `39`;
- CT202 application table count: `25`;
- tables on both: `23`;
- tables only on laptop: `16`;
- tables only on CT202: `2`;
- table-list hash match: `no`;
- schema hash match: `no`;
- comparison conclusion: `schemas_differ_or_table_sets_differ_by_safe_hashes`.

Tables only on laptop:

- `ad_reward_events`
- `calendar_events`
- `gpu_session_quotes`
- `gpu_sessions`
- `job_results`
- `power_auto_state`
- `power_events`
- `power_idle_state`
- `study_cards`
- `study_deck_totals`
- `study_decks`
- `study_reviews`
- `study_session_events`
- `study_sessions`
- `study_user_totals`
- `web_power_policy_events`

Tables only on CT202:

- `credit_ledger`
- `user_credit_wallets`

Safe row-count comparison:

- `credit_ledger`: laptop=`missing`, CT202=`0`;
- `global_phrase_bank`: laptop=`34`, CT202=`0`;
- `intent_definitions`: laptop=`14`, CT202=`0`;
- `intent_routes`: laptop=`14`, CT202=`0`;
- `jobs`: laptop=`22`, CT202=`0`;
- `router_logs`: laptop=`0`, CT202=`0`;
- `user_credit_wallets`: laptop=`missing`, CT202=`0`;
- `user_language_preferences`: laptop=`0`, CT202=`0`;
- `user_phrase_bank`: laptop=`0`, CT202=`0`;
- `user_sessions`: laptop=`233`, CT202=`0`;
- `workers`: laptop=`2`, CT202=`0`.

## Data-authority conclusion

The live laptop DB and CT202 candidate DB are not equivalent.

The table sets differ. The schema hashes differ. Key live authority tables and operational rows exist on the laptop but not in CT202.

Therefore:

- CT202 must not be promoted as-is under the assumption that it has equivalent data;
- no data authority path was selected by this phase;
- no data migration/import/copy/dump was performed;
- the cutover readiness gate remains closed.

## Implications for future paths

The current comparison narrows the future decision:

### Fresh-start CT202 authority

Still possible only if the project explicitly accepts losing or resetting current laptop-local operational/application state during cutover.

This would need an explicit decision about active jobs, sessions, study data, calendar data, power state, rewards/ads, and historical operational tables.

### Selective import

Likely requires a clear table allowlist and schema reconciliation because laptop-only and CT202-only tables differ.

This path must define which laptop-only tables are required, whether CT202-only `credit_ledger` and `user_credit_wallets` should exist on laptop first, and whether any schema migration is needed before import.

### Full migration

Likely requires a guarded backup, write freeze/quiesce plan, schema compatibility plan, and rollback/reconciliation plan.

This path must avoid split-brain writes and must not dump data into ChatGPT, `APC_LAST_OUTPUT`, repo, or Source.

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

## Recommended next safe step

Recommended next safe step:

- record a no-apply decision matrix for choosing between fresh-start, selective import, and full migration; or
- prepare a no-apply schema reconciliation plan; or
- pause and perform a Source refresh if this is a stable handoff point.

Do not run migration/import/copy/dump from this phase.
