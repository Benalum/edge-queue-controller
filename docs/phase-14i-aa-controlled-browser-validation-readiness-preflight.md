# Phase 14I-AA - Controlled Browser Validation Readiness Preflight

Status: read-only readiness preflight prepared

## Purpose

Phase 14I-AA prepares the exact browser validation checklist for testing Study UI with legacy local Edge `/jobs` fallback disabled.

This phase does not perform the browser validation.

This phase does not create jobs.

This phase does not call models.

This phase does not flip the fallback flag globally.

This phase does not change backend route gates.

## Starting Checkpoint

- HEAD: 4fe84a5
- Tag: controller-phase-14i-z-controlled-disabled-legacy-jobs-fallback-browser-validation-plan-2026-06-15

## Browser Validation Setup

Open the Study UI in the browser.

Open DevTools.

Open the Console tab.

Before submitting a Study UI companion message, run:

    window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED = false

Then open the Network tab and clear existing requests.

## Manual Test Message

Use a small harmless message, for example:

    Say hello in one short sentence.

## Expected Network Behavior

Expected submit behavior:

- first submit should go to queued chat
- expected queued submit path contains `/chat/queued`
- frontend should not submit this request to direct `/jobs`

Expected poll behavior:

- polling should use queued chat
- expected queued poll path contains `/chat/queued/`
- frontend should not poll direct `/jobs/{job_id}` for this request
- frontend should not poll direct `/job/{job_id}` for this request

## Stop Conditions

Stop immediately if any of the following occur:

- browser submits directly to `/jobs`
- browser polls directly to `/jobs/{job_id}`
- browser polls directly to `/job/{job_id}`
- queued chat returns an unexpected error
- UI gets stuck without a clear status
- any backend or model error appears

Capture the exact browser-visible error and stop.

## Evidence To Paste Back

Paste only this evidence:

- whether Console accepted the flag
- the first submit URL path
- the poll URL path or paths
- whether any `/jobs` request appeared
- whether the UI response completed or failed
- any visible browser error text

Do not paste auth tokens.

Do not paste cookies.

Do not paste full request headers.

Do not paste full prompt/context dumps.

## Backend Decision Boundary

Even if browser validation passes, backend direct `/jobs` should not be gated in the same step.

A later phase should record the evidence first, then decide whether backend direct `/jobs` can move closer to disabled-by-default testing.

## Safety Notes

No jobs are created by this preflight.

No jobs are deleted.

No jobs are archived.

No jobs are forwarded.

Job 23 is not mutated.

CT101 is not modified.

No model calls are made by this preflight.

No runtime service mutation is performed.

No raw queue summary or prompt/context dump is performed.

## Next Safe Step

Perform the manual browser-observed validation using this checklist.

After the browser evidence is pasted back, record the result in a new documentation phase before changing any backend route gates.
