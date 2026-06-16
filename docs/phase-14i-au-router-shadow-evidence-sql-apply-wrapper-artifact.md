# Phase 14I-AU Router Shadow Evidence SQL Apply Wrapper Artifact

Phase 14I-AU adds the future apply wrapper artifact for the router shadow evidence SQL schema.

This phase adds:

- `ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`
- this docs record,
- a static smoke.

This phase does not run the apply wrapper.
This phase does not apply a database migration.
This phase does not call `psql`.
This phase does not source database environment files.
This phase does not read database secrets.
This phase does not touch the database.
This phase does not add a writer.
This phase does not change runtime behavior.
This phase does not expose router shadow output to the browser.
This phase does not persist router shadow evidence at runtime.
This phase does not enable router model selection.
This phase does not mutate CT101.
This phase does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AT completed the SQL apply runbook draft.

The schema-only SQL artifact exists:

`ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`

## Apply Wrapper Added

The future apply wrapper is:

`ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`

The wrapper is not run in this phase.

The wrapper requires this explicit confirmation phrase before it can apply anything in a later phase:

`APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA`

## Safety Boundary

The wrapper is an operator-run artifact for a later explicitly gated apply phase.

It is not wired into runtime.

It is not called by `edge_controller.py`.

It is not called by a route.

It is not called by a scheduler.

It is not called by a systemd timer or service.

It does not add a writer.

It does not enable router model selection.

## Future Apply Behavior

When a later phase explicitly approves running the wrapper, it should:

- verify required files exist,
- verify configured database environment exists,
- verify `DATABASE_URL` is set without printing it,
- run a pre-apply backup,
- apply only `ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`,
- verify the table exists,
- verify the migration marker exists,
- print only safe operational status,
- avoid dumping row contents,
- avoid printing secrets.

## Future Apply Stop Conditions

A later phase must not run the wrapper if:

- repo is dirty,
- HEAD/tag are unexpected,
- the SQL artifact is missing,
- the wrapper differs from the reviewed artifact,
- backup script is missing,
- restore script is missing,
- restore drill script is missing,
- DB target is uncertain,
- CT101 mutation would be required,
- live model endpoint calls would be required,
- writer code is included,
- router activation is included,
- browser response changes are included,
- job 23 would be touched,
- secrets would be printed.

## Writer Separation Rule

The apply wrapper does not add or enable a writer.

A writer helper must remain a separate later default-off phase after schema application is proven.

The future writer must never block queued-chat job creation and must never return evidence to the browser.

## Prior Smoke Note

Phase 14I-AT expected the future apply wrapper to be absent.

After Phase 14I-AU, that specific pre-wrapper assertion is superseded.

Use Phase 14I-AU and later smokes as the current authority for the apply-wrapper artifact state.

## Phase 14I-AU Validation Scope

This phase validates only that:

- this document exists,
- its smoke exists,
- the v3 SQL artifact exists,
- the apply wrapper exists,
- the apply wrapper requires explicit confirmation,
- the apply wrapper references the expected SQL artifact,
- runtime code still compiles,
- changed files are limited to this apply-wrapper/docs/smoke phase,
- the apply wrapper is not executed,
- no writer marker is introduced outside docs/smoke or the existing SQL artifact,
- no route behavior is changed,
- no browser exposure is introduced,
- no CT101 mutation path is introduced.

## Exit Criteria

Phase 14I-AU is complete when:

- the apply wrapper exists,
- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this apply-wrapper/docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AU, the next safe follow-up can be a final pre-apply audit, still without running the wrapper and still without adding a writer.
