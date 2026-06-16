# Phase 14I-AO Router Shadow Evidence Controller-Owned Migration Target Inspection

Phase 14I-AO records a static controller-owned migration target inspection for the future queued-chat router shadow evidence table.

This phase is documentation and static smoke validation only.

It does not apply a database migration.
It does not add a migration file.
It does not add SQL.
It does not add a writer.
It does not change runtime behavior.
It does not expose router shadow output to the browser.
It does not persist router shadow evidence.
It does not enable router model selection.
It does not mutate CT101.
It does not call live model endpoints.

## Current Verified Starting Point

Phase 14I-AN inspected migration mechanism surfaces and confirmed the project must not invent a second migration system.

The current runtime contract remains unchanged:

- `/api/chat/queued` calls `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`.
- `EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED` remains default-off.
- The shadow helper return value is discarded.
- Live `requested_model` pass-through remains unchanged.
- No router shadow output is returned to the browser.
- No router shadow evidence is persisted.
- No database migration exists for router shadow evidence.
- No writer exists for router shadow evidence.

## Static Target Surface Findings

The repo contains existing database-related surfaces that must be respected before any future schema-only migration is drafted:

- `ops/db/apply-laptop-app-schema.sh`
- `ops/db/laptop-app-schema-v1.sql`
- `ops/db/laptop-app-schema-v2-chat-source-job-id.sql`
- `ops/db/backup-laptop-postgres.sh`
- `ops/db/restore-laptop-postgres.sh`
- `ops/db/verify-laptop-postgres-restore-drill.sh`
- `edge_router_schema.py`

These surfaces show that the repository already has database ownership and schema-management history. A future router shadow evidence migration must fit the existing pattern instead of creating a second unrelated migration system.

## Controller-Owned Target Rule

The future `queued_chat_router_shadow_evidence` table should remain controller-owned.

For this project, controller-owned means the evidence surface belongs with the trusted backend/controller persistence boundary that owns queue behavior and router shadow integration decisions.

It must not be introduced into CT101.

It must not be owned by a browser-visible frontend.

It must not be owned by an external volunteer node.

It must not be owned by the router model itself.

It must not be implemented in the same phase as a writer or router rollout.

## Candidate Migration Target Direction

The safest future direction is a schema-only change in the existing controller-owned database migration surface.

Based on static repo surfaces, the candidate target family for future schema-only work is the existing `ops/db/laptop-app-schema*.sql` and `ops/db/apply-laptop-app-schema*.sh` pattern.

This is not an approval to apply a migration now.

This is not an approval to add writer code.

This is not an approval to enable router model selection.

This is only a target inspection result for a later gated schema-only phase.

## Explicit Non-Targets

The future router shadow evidence table should not be added to these surfaces in this phase:

- CT101 runtime.
- Browser/frontend state.
- Raw queue payload storage.
- Full `app_jobs.payload_json` reuse for evidence.
- External distributed node storage.
- Volunteer compute node storage.
- Any model-local cache.
- Any route response returned to the browser.

`edge_router_schema.py` may remain useful for router-specific fixtures or router dry-run support, but it is not selected in this phase as the target for queued-chat router shadow evidence persistence.

## Future Schema-Only Phase Boundary

A later schema-only phase may draft or apply a narrow table only after a separate explicit gate.

That later phase must still avoid:

- writer code,
- persistence calls from `/api/chat/queued`,
- model calls,
- scheduler changes,
- requested model selection changes,
- browser-visible output,
- backend direct `/jobs` gating,
- Study UI `requested_model` removal,
- legacy fallback removal,
- CT101 mutation,
- job 23 mutation.

## Backup and Recovery Requirement

Before any future schema migration is applied, the phase must verify backup and restore procedure readiness using existing repo-owned backup and restore scripts.

A future migration phase must document:

- backup command,
- rollback command or rollback procedure,
- restore drill expectations,
- failure isolation rule,
- how to confirm no job records were mutated.

## Evidence Privacy Requirements

Any future evidence surface must reject or omit:

- raw user messages,
- raw prompts,
- raw context,
- raw queue summaries,
- raw request bodies,
- cookies,
- auth headers,
- bearer tokens,
- session tokens,
- secrets,
- full payload blobs.

Only bounded allowlisted metadata should be considered.

## Phase 14I-AO Validation Scope

This phase validates only that:

- this controller-owned target inspection document exists,
- the scope remains docs/smoke only,
- runtime code still compiles,
- existing DB surface files are present,
- no runtime/schema implementation marker is introduced outside docs/smoke,
- no migration file is added,
- no SQL artifact is added,
- no writer marker is added,
- no router model selection is enabled,
- no browser exposure marker is introduced.

## Exit Criteria

Phase 14I-AO is complete when:

- this document exists,
- its static smoke exists,
- the smoke passes,
- `edge_controller.py` still compiles,
- git diff contains only this docs/smoke phase,
- the phase is committed, tagged, and pushed.

After Phase 14I-AO, the next safe follow-up can be a schema-only migration draft plan, still without applying a migration and still without adding a writer.
