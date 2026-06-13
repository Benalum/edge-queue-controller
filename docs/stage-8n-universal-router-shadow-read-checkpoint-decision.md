# Stage 8N Universal Router Shadow-Read Checkpoint Decision

Stage 8N records the checkpoint after Stage 8A through Stage 8M.

This is a docs/generated-report/smoke-only decision stage.

## Purpose

Stage 8A through Stage 8M built the Universal Intent Router shadow-read foundation without enabling router traffic or dispatch.

## Completed Work

Stage 8A through Stage 8M completed:

- router re-entry audit
- decision-maker contract
- response schema comparison
- decision contract adapter
- temporary enabled HTTP smoke
- nested `decision_contract` response
- consumer-readiness fixture
- frontend Study/Companion hook audit
- disabled frontend shadow-read stub
- stub consumer plan
- disabled stub browser load
- disabled Study observation call
- live frontend network audit

## Current Safety State

The platform should remain in this state:

- live router endpoint disabled
- live router dry-run environment flag not enabled
- frontend `app.js` contains no `/api/router/dry-run`
- frontend stub remains disabled with `ROUTER_SHADOW_READ_ENABLED = false`
- Study behavior unchanged
- Companion behavior unchanged
- dispatch disabled
- model calls disabled
- queue clean
- platform online

## Decision

Stage 8N decision:

**Do not enable real router traffic yet.**

Reason:

The disabled frontend observation path is now safely present and live-served, but the next stage should add a proper feature flag boundary before any real `/api/router/dry-run` request can be attempted from the browser.

## Recommended Next Stage

Stage 8O should add a source-level frontend feature flag boundary while keeping it off by default.

Stage 8O should still prove:

- no router requests happen while disabled
- no dispatch can occur
- no model calls can occur
- Study and Companion behavior remain unchanged

## Stop Condition

If there is any uncertainty, stop at Stage 8N. The current state is safe and functional.
