# Phase 14I-AW Router Shadow Evidence Controlled DB Apply

Phase 14I-AW records the controlled database apply of the router shadow evidence schema artifact.

## Scope

This phase applied only the controller-owned router shadow evidence schema artifact:

- `ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`

The apply used the existing guarded wrapper artifact:

- `ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`

## Approval Boundary

This phase was explicitly approved as the DB-touching apply phase after a clean read-only baseline and pre-apply wrapper inspection.

The apply phase did not add:

- writer code,
- route changes,
- browser output,
- router activation,
- live model calls,
- CT101 mutation,
- scheduler changes,
- job mutation,
- job 23 mutation.

## Backup and Apply Result

The guarded apply wrapper ran its pre-apply backup step before applying the schema.

The apply output verified:

- backup created successfully,
- schema applied inside a transaction,
- `queued_chat_router_shadow_evidence` table exists,
- migration marker exists,
- safe count-only row state was `0`.

## Current Router Shadow Evidence State After 14I-AW

- SQL artifact exists.
- Apply wrapper exists.
- Controller-owned schema has been applied.
- No runtime writer exists.
- No runtime persistence exists.
- No browser exposure exists.
- Router model selection remains disabled.
- Live requested_model pass-through remains unchanged.
- Shadow helper return value remains discarded.

## Next Gate

Writer creation remains a separate future gate.

A future writer phase must be default-off, fail-closed/no-block, privacy-filtered, and must only write allowlisted evidence fields. It must not expose raw prompts, raw messages, raw request bodies, queue payloads, secrets, auth headers, cookies, or full job payloads.
