# Phase 14I-AL - Router Shadow Evidence Schema Contract Design

Date: 2026-06-15

## Goal

Define the future schema contract for queued-chat router shadow evidence.

This phase is documentation and smoke-test only.

It does not add runtime persistence, database migration, writer code, browser output, model routing, or CT101 changes.

## Current Baseline

Previous phase:

- Phase 14I-AK
- Router shadow evidence storage surface inspection
- Confirmed that `/api/chat/queued` still has no router shadow evidence persistence
- Confirmed that future storage should use a dedicated narrow schema or artifact instead of full `app_jobs.payload_json`

## Schema Contract Decision

Future queued-chat router shadow evidence should use a dedicated, narrow, append-only evidence surface.

Do not reuse full `app_jobs.payload_json` as the evidence record.

Reason:

- `app_jobs.payload_json` can contain broad job payload fields.
- Router shadow evidence should be narrow and privacy-preserving.
- A dedicated schema allows exact allowlist validation.
- A dedicated schema can enforce redaction version, retention rules, and default-off writer behavior.
- A dedicated smoke can prove blocked fields are absent.

## Candidate Future Table Name

Recommended future table name:

`queued_chat_router_shadow_evidence`

This table name is reserved for a future gated migration phase.

Phase 14I-AL does not create this table.

## Candidate Future Columns

The future schema should be narrow.

Candidate allowed columns:

- `id`
- `created_at`
- `schema_version`
- `redaction_version`
- `route_name`
- `feature_flag_enabled`
- `shadow_decision_executed`
- `shadow_source`
- `primary_intent`
- `intent_bucket`
- `confidence_bucket`
- `reason_code`
- `fallback_reason_code`
- `live_model_selection_changed`
- `requested_model_present`
- `requested_model_bucket`
- `mode_bucket`
- `model_call_allowed`
- `job_enqueue_allowed`
- `browser_exposure_allowed`
- `persistence_allowed`
- `evidence_sampled`
- `retention_class`

Optional future foreign-key style references may be considered only if they do not expose sensitive payload content:

- `job_id`
- `chat_id_hash`
- `user_id_hash`

If hash fields are added later, the hash method and salt handling must be documented before implementation.

## Candidate Future JSON Field

Avoid a broad JSON blob by default.

If a JSON field is eventually needed, it must be narrow and allowlisted.

Candidate name:

`evidence_json`

Allowed content:

- versioned safety booleans
- versioned reason codes
- non-sensitive buckets
- validation metadata

Disallowed content:

- raw prompt
- raw user message
- raw context
- raw request body
- raw response body
- raw queue summary
- full job payload
- full `payload_json`
- full user profile
- cookies
- bearer tokens
- auth headers
- session tokens
- shared secrets
- model output
- hidden router internals
- chain-of-thought style reasoning

## Default-Off Future Writer Flag

Any future writer must be gated behind a separate default-off flag.

Recommended future flag:

`EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_ENABLED`

This flag must be separate from:

`EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED`

Reason:

- Shadow decision execution and evidence persistence are separate risks.
- Operators may want shadow execution without persistence.
- Persistence requires stricter privacy and retention controls.

## Future Writer Rules

A future evidence writer must:

- be disabled by default
- accept only an allowlisted evidence object
- reject blocked fields
- never receive raw prompt text
- never receive raw request bodies
- never receive auth/session material
- never write full `payload_json`
- avoid browser-visible output
- avoid live model calls
- preserve live model selection
- preserve queued-chat job creation behavior
- fail closed if validation fails

## Future Migration Rules

A future migration phase must:

- be separate from this phase
- add schema only, before runtime writer code
- include rollback instructions
- include smoke tests for schema presence
- include smoke tests proving no writer is active
- not mutate CT101 unless explicitly planned and gated
- not call model endpoints

## Phase 14I-AL Scope

This phase adds only:

- this schema contract document
- a static/read-only smoke test

This phase does not patch runtime code or database scripts.

## Validation

Required validation:

- Python compile passes.
- Phase 14I-AI smoke passes.
- Phase 14I-AJ smoke passes.
- Phase 14I-AK smoke passes.
- Phase 14I-AL smoke passes.
- The queued-chat route still has no evidence persistence.
- No runtime writer marker exists.
- No database migration marker exists for `queued_chat_router_shadow_evidence`.
- The schema contract includes allowed fields, blocked fields, future flag, and migration boundaries.
- No live model endpoints are called by smoke tests.
