# Phase 14I-AC - Router and Decision-maker Surface Inspection

Status: read-only inspection recorded

## Purpose

Phase 14I-AC records the read-only inspection of router and decision-maker surfaces after browser evidence showed Study UI queued-chat working with legacy local Edge `/jobs` fallback disabled.

This phase answers whether the Study UI companion queued-chat path is currently using dynamic model routing.

## Starting Checkpoint

- HEAD: 48547cb
- Tag: controller-phase-14i-ab-browser-evidence-and-routing-follow-up-2026-06-15

## Finding

The Study UI companion queued-chat path is not currently proving dynamic router or decision-maker behavior.

The frontend currently sends a fixed model:

    body: { message: prompt, requested_model: "gemma4:e4b" }

The legacy local jobs fallback also still sends the same fixed model:

    body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" }

Decision:

- Study UI currently requests `gemma4:e4b` directly.
- The frontend is not delegating model choice yet.
- Simple prompts may be slow because they are still routed to a heavier fixed model.

## Backend Queued-chat Route Finding

The queued-chat request model includes:

- `message`
- `chat_id`
- `requested_model`
- `mode`
- `user_id`
- `authenticated_user_id`

The backend `/api/chat/queued` route accepts `requested_model`.

The queued-chat route inspection found:

- `uses_requested_model=True`
- `mentions_router=False`
- `mentions_decision=False`
- `mentions_intent=False`
- `mentions_tier=False`
- `mentions_select=False`
- `mentions_classifier=False`
- `uses_guard_payload_requested_model=True`

Decision:

- `/api/chat/queued` appears to pass `requested_model` through.
- `/api/chat/queued` does not appear to run dynamic routing inside that route.
- Browser evidence proves queued-chat path usage, not dynamic model selection.

## Existing Router and Decision-maker Surfaces

Read-only inspection found existing router-related surfaces, including:

- `stage6f_universal_intent_router_dry_run`
- `_stage5p13a_disabled_intent_router_foundation`
- `admin_intent_router_preview`
- `public_study_intent_parse`
- `_study_parse_deterministic_intent`
- `select_best_worker_for_job`

Route decorators found include:

- `POST /api/router/dry-run`
- `POST /system/router/dry-run`
- `POST /admin/intent-router-preview`
- `POST /api/study/intent/parse`
- `POST /public/study/intent/parse`
- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

Decision:

- router and intent surfaces exist
- they are separate from the Study UI companion queued-chat submit path
- integration should be planned as a separate phase

## Speed Concern

A small prompt took longer than expected.

Likely reason:

- the Study UI submitted to queued-chat successfully
- polling continued while the worker/model completed
- the selected model was fixed to `gemma4:e4b`
- no fast-router tier was proven active on this path

## Recommended Next Design Direction

A later phase should plan router integration for Study UI companion queued-chat traffic.

Open questions:

1. Should the frontend omit `requested_model` for Study UI companion queued-chat submissions?
2. Should the backend choose the model based on intent when `requested_model` is omitted?
3. Should simple prompts use a faster model tier by default?
4. Should user-facing Study UI companion messages include a `mode` hint?
5. Should router decisions be logged before being trusted for live routing?
6. Should router use shadow-read first before controlling model choice?

## Safety Notes

No code behavior changes are made in this phase.

No jobs are created.

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

CT101 is not modified.

No backend route gates are changed.

No global frontend fallback flag is changed.

No model calls are made by this documentation phase.

No raw queue summary or prompt/context dump is recorded.

## Next Safe Step

Phase 14I-AD should create a router integration plan for Study UI companion queued-chat traffic.

That plan should remain disabled by default and should prefer shadow-read/router preview before changing live model selection.
