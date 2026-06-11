# Stage 5N-2 Companion Login and Queue Recovery — 2026-06-11

## Result

Companion login and queued message sending were recovered and verified in the live browser.

## Problem

The Companion page showed `Load failed` during login and message send testing.

The root issue was not the Companion UI conversion itself. The controller on port 7070 was wedged by long-running tick requests, which caused auth and queue routes to hang through the wrapper.

## Recovery

Stopped tick timers and tick services temporarily so they could not immediately re-wedge the controller:

- edge-queue-power-auto-tick.timer
- edge-queue-power-idle-tick.timer
- edge-queue-remediation-tick.timer
- edge-queue-scheduler-tick.timer
- matching one-shot tick services

Restarted the real controller service:

- edge-queue-controller.service

Confirmed controller auth recovered:

- Direct `/health` returned HTTP 200.
- Direct `/system/session/me` returned fast HTTP 401 without a bearer token.
- Public fake login returned fast HTTP 401 instead of hanging.

## Companion queue verification

Live browser Companion send succeeded.

Observed route flow:

- `POST /api/chat/queued` returned HTTP 200.
- `GET /api/chat/queued/s5f18-job-30ae339acb6a8ac1` returned HTTP 200.
- CT101 worker claimed and completed the job.
- Controller received `POST /internal/laptop-queue/jobs/s5f18-job-30ae339acb6a8ac1/complete` with HTTP 200.

Latest `app_jobs` confirmed:

- job id: `s5f18-job-30ae339acb6a8ac1`
- user id: `ct101:16`
- status: `complete`
- requested model: `gemma4:e4b`
- reply: `Hello!`
- worker: `ct101-stage5g21-managed-browser`

## UI note

The earlier `Load failed` message shown above the successful job was stale page conversation state from before recovery. Clearing the Companion conversation removes it.

## Boundary

This stage verifies the existing queued Companion path.

It does not yet fix the underlying tick-service wedging risk permanently.

A follow-up stage should make tick jobs bounded, lock-protected, and non-overlapping before the timers are re-enabled.
