# Phase 14J-HP - CT202 rebuild script artifact, no apply

Date: 2026-06-17  
Type: no-apply script artifact / docs-smoke record  
Previous checkpoint: Phase 14J-HO at commit `d19e2b0`  
Approval phrase used: `APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY`

## Purpose

Create the safe no-apply CT202 rebuild script artifact designed in Phase 14J-HO.

This phase creates the artifact:

`ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh`

The artifact is executable but safe by default.

It verifies the no-apply approval phrase and prints prerequisite and target-plan summaries only.

This phase does not execute a rebuild.

This phase does not select a data authority path.

This phase does not authorize restore, schema apply, data migration, import, runtime activation, route mutation, or cutover.

## HP-R1 note

HP-R1 failed safely during local artifact smoke.

The no-apply artifact correctly refused a dirty repo, but the smoke ran before the newly created HP files were committed. The dirty tree was therefore expected for the artifact creation phase.

HP-R1 did not commit, tag, or push.

HP-R1 did not open a remote connection.

HP-R1 did not restore, rebuild, apply schema, import data, start services, enable services, mutate onboot, mutate routes, or cut over authority.

## HP-R2 repair note

HP-R2 keeps the same no-apply scope and adds explicit `APC_ALLOW_DIRTY=1` support for the pre-commit artifact smoke only.

The artifact still refuses dirty repositories unless that variable is explicitly set.

## Mutation boundary

This phase mutates the repository only by adding:

- this documentation file;
- the no-apply script artifact;
- the smoke check for this phase.

It does not perform:

- CT202 authority cutover;
- data authority path selection;
- Path C execution;
- CT202 rebuild execution;
- CT202 schema apply;
- CT202 data migration or import;
- SQLite open with `sqlite3`;
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

## Artifact behavior

The artifact requires:

`APC_HP_APPROVAL=APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY`

The artifact prints:

- no-apply mutation boundary;
- optional repo guard;
- pveso resolution design summary;
- HM/HN backup prerequisite summary;
- Phase 14J-HK target manifest summary;
- target include table list;
- target omit/defer list;
- critical mismatch decisions;
- forbidden operations summary;
- no-apply PASS result.

The artifact does not open a remote connection in HP.

Remote read-only verification can be added in a later phase if needed, but this HP artifact remains no-apply and local-summary-only.

## Required backup prerequisite recorded by the artifact

Expected HM/HN backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Expected CT202 DB backup:

- size: `262144`;
- sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`.

Required backup artifacts:

- `ct202-edge_queue.sqlite3`;
- `ct202-pct-config.txt`;
- `ct202-app-summary.txt`;
- `ct202-service-summary.txt`;
- `ct202-env-config-posture.txt`;
- `rollback-checklist.txt`;
- `manifest.txt`.

## Target manifest posture recorded by the artifact

Target schema source:

- Phase 14J-HK target manifest;
- current runtime/laptop continuity evidence.

Target include count:

- `39` laptop continuity tables.

Target omit/defer CT202-only drift tables:

- `credit_ledger`;
- `user_credit_wallets`.

## Target include table list

The artifact records these `39` target continuity tables:

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

## Critical mismatch decisions recorded by the artifact

### workers

Target current runtime-compatible laptop shape.

Include lane/default-off metadata columns.

Do not treat CT202 `21`-column shape as authority.

### credit_reservations

Target current runtime/laptop continuity shape.

Do not automatically preserve CT202 extra columns as authority.

### CT202-only wallet drift

Omit or defer:

- `credit_ledger`;
- `user_credit_wallets`.

Do not map them into `user_credit_ledger` without a later explicit credit redesign.

## Artifact safety properties

The artifact:

- contains no rebuild implementation;
- contains no schema apply implementation;
- contains no restore implementation;
- contains no data import implementation;
- contains no service start/enable implementation;
- contains no route mutation implementation;
- contains no model/Ollama call implementation;
- contains no CT101 call implementation;
- contains no SQL dump implementation;
- contains no row-content output implementation.

The artifact is a no-apply prerequisite and plan check only.

## Artifact smoke execution

The phase smoke runs the artifact with:

`APC_HP_APPROVAL=APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY`

and:

`APC_ALLOW_DIRTY=1`

The dirty allowance is restricted to this pre-commit artifact smoke context.

The artifact must return PASS while proving it performed no apply action.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HQ - CT202 rollback command design, no restore/no rebuild`

That phase should remain docs/smoke-only and should design future rollback commands without executing restore.

It should not restore.

It should not rebuild.

It should not apply schema.

It should not import data.

It should not start or enable services.

It should not select data authority.

It should not mutate public routes.

## Future approval phrase for HQ

Suggested future approval phrase:

`APPROVE_PHASE_14J_HQ_CT202_ROLLBACK_COMMAND_DESIGN_NO_RESTORE_NO_REBUILD`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize a CT202 rebuild.

This phase does not authorize a schema apply.

This phase does not authorize restore.

Do not run migration/import/copy/dump from this phase.
