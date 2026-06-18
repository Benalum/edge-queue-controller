# Phase 14J-HO - CT202 rebuild script design, no apply

Date: 2026-06-17  
Type: no-apply rebuild script design / docs-smoke record  
Previous checkpoint: Phase 14J-HN at commit `500aec1`  
Approval phrase used: `APPROVE_PHASE_14J_HO_CT202_REBUILD_SCRIPT_DESIGN_NO_APPLY`

## Purpose

Record the no-apply design for a future CT202 candidate rebuild script.

This phase follows the Phase 14J-HN backup artifact verification record.

This phase designs the future script structure, prerequisites, guardrails, target schema handling, drift handling, and verification requirements only.

This phase does not create a rebuild script artifact.

This phase does not execute a rebuild.

This phase does not select a data authority path.

This phase does not authorize restore, schema apply, data migration, import, runtime activation, route mutation, or cutover.

## Mutation boundary

This phase is docs/smoke only.

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

## Required prerequisites from prior phases

A future rebuild-script artifact must require these completed prerequisites:

1. Phase 14J-HK target schema manifest exists.
2. Phase 14J-HL backup and rollback plan exists.
3. Phase 14J-HM guarded CT202 backup artifacts exist.
4. Phase 14J-HN backup artifact verification passed.
5. CT202 remains private candidate only.
6. CT202 service remains disabled/inactive.
7. CT202 onboot remains `0`.
8. CT202 cutover readiness gate remains CLOSED.
9. Laptop controller and laptop-local DB remain live authority.
10. Public routes remain unchanged.

## Verified HM/HN backup prerequisite

The future rebuild-script artifact must require this verified backup directory:

`/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z`

Verified backup artifacts include:

- `ct202-edge_queue.sqlite3`;
- `ct202-pct-config.txt`;
- `ct202-app-summary.txt`;
- `ct202-service-summary.txt`;
- `ct202-env-config-posture.txt`;
- `rollback-checklist.txt`;
- `manifest.txt`.

The verified CT202 DB backup hash is:

`43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`

## Future script goal

The future rebuild script should create or prepare a **CT202 candidate schema** that matches the Phase 14J-HK target manifest.

The future script must not promote CT202 to authority.

The future script must not start or enable the controller service.

The future script must not mutate Cloudflare, DNS, tunnels, public routes, CT101, workers, laptop controller, or laptop live DB.

## Future script mode

The recommended next artifact should be a **no-apply script artifact**, not an apply script.

The script should support a design or dry-run mode first.

Suggested initial behavior:

- verify prerequisites;
- verify CT202 posture;
- verify backup artifact presence;
- generate a target schema plan;
- produce bounded output;
- refuse to apply unless a later phase defines a separate apply approval phrase.

This phase intentionally does not define a rebuild-apply approval phrase.

## Future script guard sequence

A future rebuild script artifact should begin with hard guards.

### Guard 1 - explicit phase approval

Require a future no-apply artifact approval phrase, not an apply phrase.

Expected next approval phrase:

`APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY`

### Guard 2 - repo checkpoint

Require the expected repo HEAD from the phase that creates the artifact.

The script should fail if:

- repo HEAD is not the expected checkpoint;
- local `origin/main` is not expected;
- working tree is dirty.

### Guard 3 - host resolution

Resolve `pveso` using the existing SSH/Tailscale fallback pattern because direct hostname and MagicDNS lookup have been unreliable.

The script should avoid printing raw private IPs.

### Guard 4 - CT202 posture

Verify:

- CT202 status is `running`;
- CT202 hostname is `edge-controller`;
- CT202 onboot is `0`;
- `edge-queue-controller.service` is not enabled;
- `edge-queue-controller.service` is not active;
- no checked listener is active on `7070`, `8787`, or `8765`.

### Guard 5 - backup prerequisite

Verify the HM/HN backup directory exists.

Verify artifact size/hash values match the HN record.

Require the manifest guard flags:

- `no_sqlite_open=1`;
- `no_sql_dump=1`;
- `no_row_content=1`;
- `no_service_start=1`;
- `no_service_enable=1`;
- `no_onboot_mutation=1`;
- `no_rebuild=1`;
- `no_cutover=1`.

### Guard 6 - target manifest prerequisite

Verify Phase 14J-HK target manifest exists in repo docs.

Verify the manifest includes the `39` laptop continuity tables.

Verify the manifest omits or defers:

- `credit_ledger`;
- `user_credit_wallets`.

### Guard 7 - no authority/cutover

Fail closed if any approval phrase or command implies:

- cutover apply;
- runtime apply;
- route apply;
- Cloudflare apply;
- schema apply;
- data migration;
- restore apply.

## Target schema source design

The future script should use the Phase 14J-HK target table manifest as the table-level source of truth.

For schema shape, the future design should use:

1. current repository runtime bootstrap/schema code;
2. laptop continuity schema evidence from Phase 14J-HF;
3. code-path evidence from Phase 14J-HH;
4. explicit table group decisions from Phases 14J-HJ and 14J-HK.

Do not treat CT202 current DB as schema truth.

Do not treat CT202-only wallet tables as authoritative.

## Target include groups

The future script design must include the schema groups from HK:

- account and auth continuity group;
- credit and accounting continuity group;
- Study continuity group;
- Calendar continuity group;
- queue/runtime schema group;
- router/reference group;
- support/admin group;
- ad/reward group;
- GPU/session history group;
- power/platform group.

## Target include table list

The future rebuild script design must account for these `39` laptop continuity tables:

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

## Target omit/defer handling

The future rebuild script design must omit or defer these CT202-only drift tables unless a later credit redesign explicitly adopts them:

- `credit_ledger`;
- `user_credit_wallets`.

The future script must not silently map these tables into `user_credit_ledger`.

The future script must not let these CT202-only tables define authority.

## Critical mismatch handling

### workers

The future script design must target the current runtime-compatible laptop `workers` schema.

It must include lane/default-off metadata columns.

It must not use the current CT202 `workers` shape as authoritative because CT202 has `21` columns and laptop has `29`.

### credit_reservations

The future script design must choose the target `credit_reservations` shape from current runtime code and laptop continuity evidence.

It must not automatically preserve CT202's extra columns as authoritative because CT202 has `17` columns and laptop has `15`.

## Future script output requirements

A future no-apply rebuild script artifact should output:

- PASS/FAIL guard lines;
- expected backup directory;
- expected target table list;
- included table count;
- omitted/deferred table list;
- mismatch decisions for `workers` and `credit_reservations`;
- confirmation CT202 service remains disabled/inactive;
- confirmation CT202 onboot remains `0`;
- confirmation no route/cutover/service/model call occurred.

It should not output:

- row content;
- SQL dumps;
- raw DB contents;
- secrets;
- env file contents;
- raw private IPs;
- MAC addresses;
- auth URLs.

## Future script artifact location

Recommended future artifact location:

`ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh`

The artifact should be executable but safe by default.

The artifact should fail closed unless the exact no-apply artifact approval phrase is set.

The artifact should not contain any apply approval phrase.

## Future script sections

The future script artifact should have these sections:

1. approval and mutation-boundary banner;
2. repo guard;
3. pveso SSH/Tailscale resolver;
4. CT202 posture guard;
5. backup artifact verification guard;
6. target manifest verification guard;
7. schema-source decision summary;
8. table include/omit decision summary;
9. mismatch handling summary;
10. non-goals/forbidden operations summary;
11. final no-apply PASS result.

## Deferred apply design

Actual schema apply remains deferred.

Before any apply, future phases must still create:

1. no-apply rebuild script artifact;
2. no-apply rollback command design;
3. no-apply private rehearsal plan;
4. explicit apply-phase risk review;
5. separate schema/rebuild apply approval phrase.

This HO phase does not define the apply phrase.

## Recommended next safe phase

Recommended next phase:

`Phase 14J-HP - CT202 rebuild script artifact, no apply`

That phase should create the safe no-apply script artifact only.

It should not run rebuild.

It should not apply schema.

It should not open SQLite with `sqlite3`.

It should not dump SQL.

It should not start or enable services.

It should not select data authority.

It should not mutate public routes.

## Future approval phrase for HP

Suggested future approval phrase:

`APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY`

## Gate status

The CT202 controller cutover readiness gate remains CLOSED.

This phase does not open the cutover gate.

This phase does not select a data authority path.

This phase does not authorize Path C execution.

This phase does not authorize a CT202 rebuild.

This phase does not authorize a schema apply.

This phase does not authorize restore.

Do not run migration/import/copy/dump from this phase.
