# Phase 14I-AV Router Shadow Evidence Final Pre-Apply Audit

Phase 14I-AV records the final pre-apply audit for the router shadow evidence SQL artifact and apply wrapper.

This phase is documentation and static smoke validation only.

It does not run the apply wrapper.
It does not apply a database migration.
It does not call `psql`.
It does not source database environment files.
It does not read database secrets.
It does not touch the database.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence at runtime.
It does not enable router model selection.
It does not mutate CT101.
It does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AU added the future apply wrapper artifact:

`ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`

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
- The apply wrapper exists but is not run by this phase.

## Final Pre-Apply Audit Result

The pre-apply artifact chain is now present:

- schema-only SQL artifact exists,
- apply wrapper artifact exists,
- apply wrapper requires explicit confirmation,
- backup script exists,
- restore script exists,
- restore drill script exists,
- current smokes validate static safety boundaries,
- no runtime writer has been introduced,
- no route behavior has changed,
- no browser exposure has been introduced.

## Apply Wrapper Confirmation

The future apply wrapper requires this explicit confirmation phrase:

`APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA`

This phase does not provide that confirmation and does not run the wrapper.

## Apply Is Still a Separate Decision

This phase is not approval to apply the database schema.

A later apply phase must be explicitly requested and must still verify:

- clean repo,
- expected HEAD and tag,
- reviewed SQL artifact,
- reviewed apply wrapper,
- backup readiness,
- restore readiness,
- correct controller-owned database target,
- no CT101 mutation,
- no writer,
- no router activation,
- no browser output change,
- no job 23 mutation,
- no secret printing.

## Future Apply Command

A later explicitly gated phase may run:

`bash ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA`

This phase does not run that command.

## Stop Conditions Before Future Apply

Stop before applying if:

- repo is dirty,
- HEAD/tag are unexpected,
- SQL artifact changed unexpectedly,
- apply wrapper changed unexpectedly,
- database target is uncertain,
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

The future apply phase must not add or enable a writer.

A writer helper must remain a separate later default-off phase after schema application is proven.

The future writer must never block queued-chat job creation and must never return evidence to the browser.

## Router Activation Separation Rule

Applying the SQL artifact must not enable router model selection.

Router activation remains parked until shadow evidence, lane-worker safety, and scheduler safety are proven separately.

## Phase 14I-AV Validation Scope

This phase validates only that:

- this final pre-apply audit document exists,
- its smoke exists,
- the v3 SQL artifact exists,
- the apply wrapper exists,
- the apply wrapper requires explicit confirmation,
- the apply wrapper references the expected SQL artifact,
- runtime code still compiles,
- changed files are limited to this docs/smoke phase,
- no database apply command is executed,
- no writer marker is introduced outside docs/smoke or existing artifacts,
- no route behavior is changed,
- no browser exposure is introduced,
- no CT101 mutation path is introduced.

## Exit Criteria

Phase 14I-AV is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AV, pause for an explicit decision before any real database apply.
