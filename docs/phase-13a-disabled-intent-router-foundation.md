# Phase 13A Disabled Intent-Router Foundation

Phase 13A starts the decision-maker / intent-router work.

## Purpose

The platform needs a routing layer so users do not talk to models directly.

Future request flow:

Frontend -> Backend API -> Intent Router -> Job Queue -> Scheduler -> Worker -> Model or Tool

Phase 13A adds only a disabled, pure helper foundation.

It does not wire routing into live Study, Companion, Calendar, Profile, admin, or worker flows.

## What the helper can describe

The helper returns deterministic metadata for:

- study_review
- study_material
- companion_chat
- calendar
- profile
- admin_system
- unknown

It also returns:

- confidence
- recommended model tier
- deterministic action hints
- escalation reasons
- simple normalized features such as number word matches

Example: five can be normalized as a number-word match with value 5.

## Safety

This phase must not:

- Change live routing behavior.
- Enqueue jobs.
- Call any model.
- Call Ollama.
- Call /api/generate.
- Call /api/chat.
- Call external tools.
- Change CT101 worker runtime.
- Start persistent lane workers.
- Enable router rollout.
- Enable model warmup execution.
- Restart the controller.

## Future phases

Recommended next phases:

1. Phase 13B: static router contract and regression smoke.
2. Phase 13C: read-only route preview endpoint for admin/testing.
3. Phase 13D: Study answer-normalization helper for five equals 5.
4. Phase 13E: Study review route dry-run integration.
5. Phase 13F: Companion route dry-run integration.
6. Phase 13G: guarded rollout flag for live routing.

## Stop point

Phase 13A is safe to stop after adding the disabled helper and smoke.
