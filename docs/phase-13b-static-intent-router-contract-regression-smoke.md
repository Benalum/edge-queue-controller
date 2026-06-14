# Phase 13B Static Intent-Router Contract and Regression Smoke

Phase 13B strengthens the disabled Phase 13A intent-router foundation with a reusable static and dynamic contract smoke.

## Purpose

Phase 13A added a pure disabled helper:

- _stage5p13a_disabled_intent_router_foundation

Phase 13B does not change routing behavior.

It only adds a stronger smoke that protects the helper contract before any preview endpoint or live route integration is added.

## Contract protected

The helper must remain:

- Disabled.
- Read-only.
- Not exposed as a FastAPI route.
- Not called by live routes.
- Not allowed to call a model.
- Not allowed to enqueue jobs.
- Not allowed to call Ollama.
- Not allowed to call /api/generate.
- Not allowed to call /api/chat.
- Not allowed to change runtime state.

## Regression examples protected

The smoke verifies deterministic examples for:

- next routes to study_review with study_card_advance.
- skip routes to study_review with study_card_advance.
- correct routes to study_review with study_mark_correct.
- incorrect routes to study_review with study_mark_incorrect.
- Answer is five routes to study_review and normalizes five to 5.
- How does my calendar look today routes to calendar.
- Open profile language settings routes to profile.
- Show system status routes to admin_system.
- Can we talk for a bit routes to companion_chat.
- Empty input routes to unknown.

## Safety

This phase must not:

- Patch live request flow.
- Add a new route.
- Restart the controller.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Call any model.
- Enqueue any job.
- Enable warmup execution.
- Call Ollama directly.
- Call /api/generate.
- Call /api/chat.

## Phase 13C compatibility note

Phase 13B originally protected the helper as uncalled.

After Phase 13C, the only allowed caller is the disabled admin/local preview route:

- POST /admin/intent-router-preview
- function admin_intent_router_preview

No Study, Companion, Calendar, Profile, worker, queue, or public route may call the helper directly.

## Future phases

Recommended next phases:

1. Phase 13C: disabled admin/local route-preview endpoint.
2. Phase 13D: study answer-normalization helper for flexible answer comparison.
3. Phase 13E: study review dry-run route preview.
4. Phase 13F: companion dry-run route preview.
5. Phase 13G: guarded rollout flag for live routing.
