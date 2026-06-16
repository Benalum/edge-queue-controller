# Phase 14I-AT Router Shadow Evidence SQL Apply Runbook Draft

Phase 14I-AT drafts the future apply runbook for the router shadow evidence SQL artifact.

This phase is documentation and static smoke validation only.

It does not apply a database migration.
It does not call `psql`.
It does not source database environment files.
It does not read database secrets.
It does not touch the database.
It does not create an apply script.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence at runtime.
It does not enable router model selection.
It does not mutate CT101.
It does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AS completed the SQL artifact apply-readiness gate.

The schema-only SQL artifact exists:

`ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`

The current runtime contract remains unchanged:

- `/api/chat/queued` calls `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`.
- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED` remains default-off.
- The shadow helper return value is discarded.
- Live `requested_model` pass-through remains unchanged.
- No router shadow output is returned to the browser.
- No router shadow evidence is persisted by runtime code.
- No writer exists for router shadow evidence.
- The SQL artifact exists but has not been applied by this phase.

## Existing Apply Pattern

The repository already has controller-owned DB apply surfaces:

- `ops/db/apply-laptop-app-schema.sh`
- `ops/db/apply-laptop-app-schema-v2-chat-source-job-id.sh`
- `ops/db/backup-laptop-postgres.sh`
- `ops/db/restore-laptop-postgres.sh`
- `ops/db/verify-laptop-postgres-restore-drill.sh`

A future apply wrapper should follow the existing versioned apply-wrapper pattern instead of modifying runtime code or inventing a second migration system.

## Candidate Future Apply Wrapper

A later explicitly gated phase may create this file:

`ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`

This phase does not create that file.

The future wrapper should:

- require a clean repo baseline,
- verify the v3 SQL artifact exists,
- verify backup and restore scripts exist,
- source the DB env only inside the future apply wrapper,
- verify `DATABASE_URL` is set without printing it,
- run a pre-apply backup,
- apply only `ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`,
- verify the table exists without dumping row data,
- verify the migration marker exists without dumping secrets,
- avoid changing runtime behavior,
- avoid adding a writer.

## Candidate Future Apply Command Shape

A later apply phase should be explicit and operator-visible.

The candidate future command should be a dedicated script invocation rather than reusing a generic v1 script:

`bash ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`

This phase does not create or run that command.

## Future Apply Output Rules

A later apply phase must print only safe operational facts:

- backup path or backup status,
- SQL artifact path,
- table existence status,
- index existence status,
- migration marker existence status,
- final pass/fail result.

It must not print:

- `DATABASE_URL`,
- passwords,
- tokens,
- cookies,
- auth headers,
- raw prompt data,
- raw message data,
- raw request bodies,
- raw queue payloads,
- user secrets.

## Future Verification Queries

A later apply phase may verify, without dumping sensitive row data:

- `queued_chat_router_shadow_evidence` table exists,
- `stage-14i-router-shadow-evidence` migration marker exists,
- expected indexes exist,
- expected constraints exist,
- row count is zero or safe to report as count-only,
- `app_jobs` rows were not mutated.

This phase does not run those queries.

## Apply Stop Conditions

A later apply phase must stop before touching the database if:

- repo is dirty,
- HEAD/tag are unexpected,
- SQL artifact is missing,
- SQL artifact differs from the reviewed artifact,
- future apply wrapper differs from the reviewed wrapper,
- backup script is missing,
- restore script is missing,
- restore drill script is missing,
- DB env file is missing,
- `DATABASE_URL` is unset,
- CT101 mutation would be required,
- live model endpoint calls would be required,
- writer code is included,
- router activation is included,
- browser response changes are included,
- job 23 would be touched,
- secrets would be printed.

## Writer Separation Rule

The future SQL apply wrapper must not add or enable a writer.

A writer helper must remain a separate later default-off phase after schema application is proven.

The future writer must never block queued-chat job creation and must never return evidence to the browser.

## Router Activation Separation Rule

Applying the SQL artifact must not enable router model selection.

Router activation remains parked until shadow evidence, lane-worker safety, and scheduler safety are proven separately.

## Phase 14I-AT Validation Scope

This phase validates only that:

- this runbook draft exists,
- its smoke exists,
- the v3 SQL artifact exists,
- runtime code still compiles,
- existing DB apply/backup/restore surfaces exist,
- changed files are limited to this docs/smoke phase,
- no future apply wrapper is created,
- no database apply command is executed,
- no writer marker is introduced outside docs/smoke or the existing SQL artifact,
- no route behavior is changed,
- no browser exposure is introduced,
- no CT101 mutation path is introduced.

## Exit Criteria

Phase 14I-AT is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AT, the next safe follow-up can be a gated future apply-wrapper draft, still without running it and still without adding a writer.
