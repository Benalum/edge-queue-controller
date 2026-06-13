# Stage 8H Frontend Router Shadow-Read Hook Audit

Stage 8H audits frontend Study and Companion input surfaces to identify where a future Universal Intent Router shadow-read could happen.

This is a docs/generated-report/smoke-only stage.

## Purpose

Stage 8G proved that downstream code can safely consume:

- `decision_contract.selected_path`
- `decision_contract.intent_key`
- `decision_contract.legacy_intent_name`
- `decision_contract.dispatch_plan.would_dispatch`

Stage 8H identifies where the frontend could eventually read that object without changing behavior.

## Safety

Stage 8H does not:

- modify frontend runtime code
- restart the live controller
- enable the live router endpoint
- dispatch Study commands
- call models
- change Study behavior
- change Companion behavior
- change Calendar behavior

The live router endpoint remains disabled.

## Expected Frontend Surfaces

The audit focuses on:

- Study session command calls
- Study input/action handlers
- Companion page/chat markers
- Shared API helper usage
- Candidate locations for future shadow-read-only router calls

## Shadow-Read Principle

A future frontend shadow-read must be passive:

1. User performs the existing action.
2. Existing Study or Companion behavior still runs exactly as it does now.
3. A separate router dry-run call may be made only for observation.
4. The UI must not dispatch based on router output.
5. The UI must not block or delay the original action.
6. Router output may be logged or compared only.

## Candidate Shadow-Read Hook Points

Future work should prefer hook points near:

- existing Study command API calls
- existing Companion message submit flow
- shared API helper wrapper

Future work should avoid:

- replacing Study command behavior
- replacing Companion chat behavior
- adding user-visible router UI too early
- enabling router dispatch

## Generated Report

The smoke writes:

- `docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json`

That report records line-numbered frontend markers and candidate hook points.

## Decision

Stage 8H only documents frontend hook candidates.

Stage 8I should add a source-only frontend helper plan or no-op shadow-read stub, but only if it can be proved disabled by default and behavior-preserving.
