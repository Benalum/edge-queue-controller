# Phase 14J-HH - Read-only code-path table usage inspection, no DB mutation/no apply

Date: 2026-06-17  
Type: approved read-only source/code inspection / docs-smoke record  
Previous checkpoint: Phase 14J-HG at commit `bd6fa14`  
Approval phrase used: `APPROVE_PHASE_14J_HH_READ_ONLY_CODE_PATH_TABLE_USAGE_INSPECTION_NO_DB_MUTATION_NO_APPLY`

## Purpose

Record the approved read-only repository source inspection for table usage evidence.

This phase was designed to answer whether the schema differences discovered in Phase 14J-HF are relevant to current controller code paths.

This phase did not open either SQLite database. It scanned repository source/code files only.

## Mutation boundary

This phase was read-only.

It did not perform:

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

## Repo guard

The live inspection started from:

- HEAD: `bd6fa14`;
- local `origin/main`: `bd6fa14`;
- working tree: clean.

## Scan scope

The inspection scanned:

- source/code files only;
- repository files excluding docs, virtualenv, git, binary DB files, and common binary artifacts.

Scan result:

- scanned file count: `930`;
- scanned line count: `295959`;
- DB files opened: `0`;
- row content output: `0`.

## Important caveat

The scan included `.cleanup-archive` paths. That makes some aggregate totals noisy, especially for broad names such as `workers` and `jobs`.

The useful conclusions should therefore prioritize current runtime files such as `edge_controller.py` and active module paths over archived frontend or cleanup snapshots.

This caveat does not invalidate the main findings because the high-priority tables also produced current-code evidence in active runtime files.

## High-priority table usage summary

### workers

Summary:

- total refs: `921`;
- file count: `226`;
- app/runtime refs: `122`;
- ops DB schema refs: `18`;
- verbs included: `alter`, `create`, `insert`, `select_from`, `update`, and mentions.

Conclusion:

`workers` appears in runtime scan output. Because Phase 14J-HF showed laptop `workers` has `29` columns while CT202 `workers` has `21`, the `workers` schema mismatch remains runtime-critical.

The scan is noisy due to `.cleanup-archive`, but the schema mismatch still blocks CT202 authority because current controller work has active worker registry and lane metadata expectations.

### credit_reservations

Summary:

- total refs: `31`;
- file count: `6`;
- app/runtime refs: `24`;
- active files include `edge_controller.py` and `edge_modules/credits.py`;
- verbs included: `create`, `insert`, `select_from`, `update`, and mentions.

Evidence examples included current runtime references in `edge_controller.py`, including:

- `CREATE TABLE IF NOT EXISTS credit_reservations`;
- `FROM credit_reservations`;
- `INSERT INTO credit_reservations`;
- `UPDATE credit_reservations`.

Conclusion:

`credit_reservations` appears in runtime code. Because Phase 14J-HF showed laptop `credit_reservations` has `15` columns while CT202 has `17`, this mismatch remains credit/accounting-critical.

### user_credit_ledger

Summary:

- total refs: `12`;
- app/runtime refs: `8`;
- active files include `edge_controller.py` and `edge_modules/credits.py`;
- verbs included: `create`, `insert`, `select_from`, and mentions.

Evidence examples included current runtime references in `edge_controller.py` and `edge_modules/credits.py`, including:

- `CREATE TABLE IF NOT EXISTS user_credit_ledger`;
- `INSERT INTO user_credit_ledger`;
- `FROM user_credit_ledger`.

Conclusion:

`user_credit_ledger` appears in runtime code. The laptop-style ledger likely remains relevant.

### credit_ledger

Summary:

- total refs: `10`;
- app/runtime refs: `0`;
- references appeared in smoke files only.

Conclusion:

CT202-only `credit_ledger` did not appear in app/runtime code scan. It may be schema drift or a future artifact unless used indirectly.

### user_credit_wallets

Summary:

- total refs: `10`;
- app/runtime refs: `0`;
- references appeared in smoke files only.

Conclusion:

CT202-only `user_credit_wallets` did not appear in app/runtime code scan. It may be schema drift or a future artifact unless used indirectly.

### Study tables

Study table app/runtime refs were present:

- `study_decks`: app/runtime refs=`21`;
- `study_cards`: app/runtime refs=`21`;
- `study_reviews`: app/runtime refs=`21`;
- `study_sessions`: app/runtime refs=`17`;
- `study_session_events`: app/runtime refs=`8`;
- `study_deck_totals`: app/runtime refs=`6`;
- `study_user_totals`: app/runtime refs=`5`.

Evidence examples included active runtime references in `edge_controller.py`, including CREATE, SELECT, INSERT, UPDATE, DELETE, and JOIN operations across the Study table group.

Conclusion:

Study tables appear in runtime code. CT202 missing Study tables blocks CT202 authority for Study continuity.

### calendar_events

Summary:

- total refs: `8`;
- app/runtime refs: `2`;
- active runtime references appeared in `edge_controller.py`.

Conclusion:

`calendar_events` appears in runtime scan output. CT202 missing `calendar_events` blocks local calendar continuity unless the project explicitly chooses a provider-backed reset/transition.

### jobs and job_results

Summary:

- `jobs`: total refs=`1137`, app/runtime refs=`451`;
- `job_results`: total refs=`8`, app/runtime refs=`5`.

Evidence examples included active runtime references in `edge_controller.py`, including job result creation, insert, select, and join paths.

Conclusion:

Job/runtime state remains relevant. A separate runtime cutover policy is required.

### worker_events

Summary:

- total refs=`13`;
- app/runtime refs=`6`;
- active runtime references appeared in `edge_controller.py`.

Conclusion:

Worker event history is active in runtime code and should be included in a deliberate runtime-state policy.

### user_sessions

Summary:

- total refs=`47`;
- app/runtime refs=`15`;
- active runtime references appeared in `edge_controller.py`, including create, insert, update, select, delete, and join paths.

Conclusion:

Session state remains relevant. A cutover must decide whether to preserve or invalidate sessions.

### web_presence

Summary:

- total refs=`13`;
- app/runtime refs=`9`;
- active runtime references appeared in `edge_controller.py`.

Conclusion:

`web_presence` remains active and should be considered in runtime/platform state policy.

## Preliminary code-path conclusions

The live HH inspection concluded:

- `workers` appears in app/runtime code; workers schema mismatch remains runtime-critical.
- `credit_reservations` appears in app/runtime code; its schema mismatch remains credit/accounting-critical.
- CT202-only `credit_ledger` and `user_credit_wallets` did not appear in app/runtime code scan; they may be schema drift or future artifacts unless used indirectly.
- `user_credit_ledger` appears in app/runtime code; current laptop-style ledger likely remains relevant.
- Study tables appear in app/runtime code; CT202 missing Study tables blocks authority for Study continuity.
- `calendar_events` appears in app/runtime code; CT202 missing `calendar_events` blocks local calendar continuity.
- `jobs` and `user_sessions` appear in app/runtime code; runtime cutover policy remains required.

## Data-authority conclusion

HH strengthens the prior gate decision:

CT202 should not become controller/data authority as-is.

The current blockers are not just table-count differences. They map to active or potentially active code paths:

1. `workers` schema mismatch affects runtime worker registry/lane behavior.
2. `credit_reservations` schema mismatch affects credit/accounting reservation behavior.
3. Missing Study tables affect user-facing Study continuity.
4. Missing `calendar_events` affects local calendar continuity.
5. Runtime state tables require a cutover policy.
6. CT202-only wallet/ledger tables appear unused by app/runtime code and should not drive authority without a deliberate decision.

No data authority path was selected by this phase.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HI - no-apply reconciliation path recommendation`

That phase should use HC/HF/HG/HH evidence to recommend a preferred no-apply path among:

- fresh-start CT202;
- forward-migrate CT202 schema;
- rebuild CT202 from laptop schema;
- full laptop DB migration.

Expected recommendation should likely favor **forward-migrating or rebuilding CT202 to match laptop continuity needs**, while continuing to block any actual migration/import/apply until a later explicit approval gate.

## Future approval phrase for HI

Suggested future approval phrase:

`APPROVE_PHASE_14J_HI_NO_APPLY_RECONCILIATION_PATH_RECOMMENDATION`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

No data authority path is selected by this phase.

Do not run migration/import/copy/dump from this phase.
