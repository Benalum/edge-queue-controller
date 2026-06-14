# Phase 13C Disabled Admin Intent-Router Preview Endpoint

Phase 13C adds a disabled admin/local preview endpoint for the Phase 13A intent-router helper.

## Purpose

The platform needs a way to inspect future routing decisions over HTTP before connecting the router to Study, Companion, Calendar, Profile, or worker flows.

This phase adds:

- POST /admin/intent-router-preview
- admin_intent_router_preview

The endpoint is admin-gated and non-executing.

## Behavior

The endpoint returns:

- route preview metadata
- primary intent
- confidence
- deterministic action hints
- normalized features
- recommended model tier
- safety flags

The endpoint does not:

- enqueue jobs
- call a model
- call Ollama
- call /api/generate
- call /api/chat
- change live Study behavior
- change live Companion behavior
- change Calendar behavior
- change Profile behavior
- change worker behavior

## Safety

This phase does not restart the controller.

The new endpoint will not be live until the controller is reloaded in a later guarded phase.

This phase must not:

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

## Relationship to Phase 13B

Phase 13B originally protected the helper as uncalled.

Phase 13C updates that contract so the only allowed helper caller is:

- admin_intent_router_preview

No live user-facing route may call the helper yet.
