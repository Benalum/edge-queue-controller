# Phase 14I-AB - Browser Evidence and Routing Follow-up

Status: browser evidence recorded and routing follow-up identified

## Purpose

Phase 14I-AB records the first browser-observed evidence after disabling the Study UI legacy local Edge `/jobs` fallback in the browser session.

This phase also records that the Study UI queued-chat path still requests a fixed model directly.

## Starting Checkpoint

- HEAD: 3589efb
- Tag: controller-phase-14i-aa-controlled-browser-validation-readiness-preflight-2026-06-15

## Browser Evidence Summary

The browser test used the frontend override:

    window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED = false

Observed network behavior:

- `POST queued` returned HTTP 200
- repeated `GET status?job_id=...` requests returned HTTP 200
- no direct legacy `/jobs` submit request was visible
- no direct legacy `/jobs/{job_id}` poll request was visible
- no direct legacy `/job/{job_id}` poll request was visible

Decision:

- disabled frontend legacy `/jobs` fallback appears to work from browser-observed evidence
- queued-chat submit appears to be used
- queued-chat polling appears to be used
- backend direct `/jobs` routes should still remain enabled for now

## Slow Response Observation

The browser response took longer than expected for a small prompt.

Likely causes:

- queued job was accepted but model generation took time
- polling continued while the worker/model was still completing the job
- Study UI currently requests a heavier fixed model
- dynamic router or decision-maker selection is not proven active on this path

## Routing Inspection Result

The Study UI queued-chat submit path currently sends:

    body: { message: prompt, requested_model: "gemma4:e4b" }

The legacy fallback path also still contains:

    body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" }

Decision:

- Study UI currently requests `gemma4:e4b` directly
- this path does not yet prove dynamic router or decision-maker selection
- a later phase should inspect or plan router integration for Study UI companion queued-chat submissions

## Backend Queued Chat Route Observation

The backend `/api/chat/queued` route accepts `requested_model`.

The route mirrors trusted user/session/chat information and passes the requested model through existing queued-chat flow.

Decision:

- browser evidence validates queued-chat route usage
- browser evidence does not validate dynamic model selection
- router/decision-maker integration should be treated as a separate future phase

## Backend Route Decision

Do not gate backend direct `/jobs` yet.

Backend direct local jobs routes remain enabled:

- `POST /jobs`
- `GET /jobs`

Reason:

- browser evidence is promising but still early
- the Study UI code still retains guarded legacy fallback
- router behavior still needs separate inspection and planning

## Safety Notes

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

CT101 is not modified by this documentation phase.

No backend route gates are changed.

No global frontend fallback flag is changed.

No raw queue summary or prompt/context dump is recorded.

## Next Safe Step

Phase 14I-AC should inspect the model router and decision-maker surfaces for Study UI companion queued-chat traffic.

That phase should remain read-only and should answer:

- where the router currently exists
- whether `/api/chat/queued` can use it
- whether frontend should omit `requested_model`
- whether backend should choose a model based on intent
- how to avoid slowing simple prompts with a heavier model
