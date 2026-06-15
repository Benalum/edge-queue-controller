# Phase 14I-AD - Study UI Queued-chat Router Integration Plan

Status: integration plan recorded, not implemented

## Purpose

Phase 14I-AD records the safe router integration plan for Study UI companion queued-chat traffic.

The goal is to eventually stop sending every Study UI companion message directly to the heavier fixed model `gemma4:e4b`.

This phase does not change runtime behavior.

## Starting Checkpoint

- HEAD: 331d704
- Tag: controller-phase-14i-ac-router-decision-maker-surface-inspection-2026-06-15

## Current Confirmed Behavior

The Study UI companion queued-chat submit path currently sends:

    body: { message: prompt, requested_model: "gemma4:e4b" }

The backend `/api/chat/queued` route accepts and passes through `requested_model`.

The queued-chat route does not currently show dynamic routing markers inside the route.

Decision:

- Study UI companion queued-chat traffic is not yet using the router for model selection.
- Simple prompts may be slower because they still request `gemma4:e4b`.
- Router integration must be introduced safely and disabled by default first.

## Desired Future Behavior

Future behavior should support:

1. Fast simple prompts using a small/fast model tier.
2. Normal companion messages using a medium model tier.
3. Complex prompts escalating to a stronger model tier.
4. Router decisions logged before they control live routing.
5. No direct model exposure to the browser.
6. Backend remains authoritative for final model choice.

## Proposed Router Integration Strategy

Use a staged rollout.

### Stage AD-1: Shadow-read only

Add a backend-only router shadow decision for queued-chat requests.

Behavior:

- frontend continues sending `requested_model: "gemma4:e4b"`
- backend computes a router decision in shadow mode
- backend does not use the router decision for live model choice
- backend logs or returns safe internal markers only when explicitly inspected
- no user-visible behavior changes

### Stage AD-2: Frontend omission flag

Add a disabled-by-default frontend flag that allows Study UI to omit `requested_model` for queued-chat submissions.

Proposed flag:

    window.STUDY_UI_QUEUED_CHAT_ROUTER_SELECTION_ENABLED = true

Default:

    false

Behavior when disabled:

- Study UI continues sending `requested_model: "gemma4:e4b"`

Behavior when enabled for testing:

- Study UI omits `requested_model`
- backend must decide the model
- backend direct `/jobs` fallback remains guarded separately

### Stage AD-3: Backend router selection flag

Add a disabled-by-default backend flag that allows `/api/chat/queued` to choose the model when `requested_model` is omitted.

Proposed environment flag:

    EDGE_QUEUED_CHAT_ROUTER_MODEL_SELECTION_ENABLED=0

Default:

    disabled

Behavior when disabled:

- current behavior remains unchanged

Behavior when enabled:

- if request omits `requested_model`, backend selects model using router decision
- if request includes `requested_model`, backend follows existing behavior unless a later safety policy overrides it

### Stage AD-4: Static and browser validation

Validation order:

1. Static smoke proves no behavior changed by default.
2. Browser test with frontend router flag disabled confirms current behavior.
3. Browser test with frontend router flag enabled confirms `requested_model` is omitted.
4. Backend dry-run confirms router decision without changing live model choice.
5. Backend router selection flag is tested only after shadow evidence is documented.

## Initial Model Tier Direction

Do not hard-code final model tier choices in this phase.

Initial intended routing direction:

- simple greeting or short answer: fast small tier
- study grading or answer comparison: study/light tutor tier
- normal companion conversation: medium companion tier
- complex reasoning or planning: deep reasoning tier only when needed

## Important Safety Boundaries

Do not remove `requested_model` from the frontend yet.

Do not enable backend router model selection yet.

Do not gate backend direct `/jobs` yet.

Do not remove legacy fallback yet.

Do not call live model endpoints in smoke tests.

Do not expose router internals or hidden prompt/context in browser responses.

Do not let the browser directly choose privileged model tiers.

## Recommended Next Step

Phase 14I-AE should perform a read-only inspection of the existing router dry-run and intent-router preview surfaces to identify the safest internal helper to reuse for queued-chat shadow decisions.

That next phase should answer:

- which existing function can classify intent without mutation
- whether dry-run can run without model execution
- what fields it returns
- whether it can recommend model tiers
- what fields are safe to log
- what fields must not be returned to the browser

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
