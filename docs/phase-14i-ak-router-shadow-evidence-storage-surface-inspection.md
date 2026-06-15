# Phase 14I-AK - Router Shadow Evidence Storage Surface Inspection

Date: 2026-06-15

## Goal

Record the safe storage-surface inspection for future queued-chat router shadow evidence.

This phase is documentation and smoke-test only.

It does not add runtime evidence collection, database schema, route output, browser exposure, model routing, or persistence.

## Current Checkpoint

Previous phase:

- Phase 14I-AJ
- Router shadow contract validation and evidence plan
- Confirmed that `/api/chat/queued` has the post-AI shadow hook contract
- Confirmed evidence collection remains plan-only

## Inspection Result

The repository contains several existing storage or evidence-like surfaces, including:

- `power_events`
- `worker_events`
- `study_session_events`
- `job_results`
- `app_jobs.payload_json`
- generated docs/evidence artifacts
- authenticated shadow comparison artifacts under `docs/generated`
- database scripts under `ops/db`

None of these are approved yet for queued-chat router shadow evidence persistence.

## Current Decision

Do not persist queued-chat router shadow evidence yet.

The safest next step is to keep evidence collection plan-only until a later phase defines a narrow, redacted, default-off storage contract.

## Blocked for Now

The following are blocked in this phase:

- database schema changes
- runtime evidence writes
- route response changes
- browser-visible router shadow output
- storing raw prompt text
- storing raw message text
- storing raw context
- storing raw queue summaries
- storing auth headers
- storing session material
- storing secrets
- storing full user profile
- storing full job payload
- changing live model selection
- enabling router rollout
- enabling persistent lane workers
- enabling warmup execution
- mutating CT101

## Future Evidence Storage Requirements

A later gated phase may add evidence storage only after it defines:

- exact storage table or artifact location
- exact allowed fields
- exact blocked fields
- default-off environment flag
- redaction rules
- retention rules
- sampling rules
- delete/recovery procedure
- smoke tests proving no live model calls
- smoke tests proving no browser exposure
- smoke tests proving no prompt/context/session material is stored

## Allowed Future Evidence Shape

A future evidence record should be narrow and non-sensitive.

Candidate allowed fields:

- created timestamp
- route name
- feature flag enabled boolean
- shadow decision executed boolean
- deterministic route name or route bucket
- confidence bucket, not raw confidence internals if unnecessary
- reason code
- live model unchanged boolean
- model call allowed boolean
- job enqueue allowed boolean
- browser exposure allowed boolean
- persistence allowed boolean
- redaction version
- schema version

## Disallowed Future Evidence Shape

Future evidence must not include:

- raw prompt
- raw user message
- raw context
- raw request body
- raw queue summary
- cookies
- bearer tokens
- auth headers
- shared secrets
- full user profile
- full job payload
- full `payload_json`
- model output
- hidden router internals
- private chain-of-thought style reasoning

## Recommended Future Storage Surface

The recommended future direction is a dedicated, narrow table or artifact schema for router shadow evidence instead of reusing full `app_jobs.payload_json`.

Reason:

- `app_jobs.payload_json` may contain broad job payload fields.
- Shadow evidence should be intentionally narrow.
- A dedicated schema can enforce redaction and retention.
- A dedicated smoke can prove that blocked fields are absent.

## Phase 14I-AK Scope

This phase adds only:

- this inspection document
- a static/read-only smoke test

This phase does not patch runtime code.

## Validation

Required validation:

- Python compile passes.
- Phase 14I-AI smoke passes.
- Phase 14I-AJ smoke passes.
- Phase 14I-AK smoke passes.
- `/api/chat/queued` still has no shadow evidence persistence.
- No new DB schema or runtime evidence write markers are introduced.
- No live model endpoints are called by smoke tests.
