# Stage 5G-11 — CT101 bridge real-worker lifecycle readiness

## Goal

Prove the CT101 queued bridge is ready for runtime enablement by combining the two required lifecycle proofs.

## What this stage proves

1. CT101-shaped queued bridge compatibility still works:
   - POST /api/backend/chats/{chat_id}/messages/queued
   - GET /api/backend/chats/{chat_id}/messages/jobs/{job_id}
   - completed status returns CT101-compatible assistant_message
   - repeated completed poll is idempotent
   - wrapper does not create assistant DB rows

2. Real-user laptop queued jobs still complete through the CT101 bounded worker:
   - laptop real-user /api/chat/queued creates a job
   - CT101 bounded poller claims it
   - CT101 Ollama completes it
   - laptop route status reports completion
   - assistant persistence remains idempotent

## Why this is composed instead of persistent-worker based

The always-running CT101 worker polls CT101's backend, not the temporary laptop controller used by smoke tests.
The proven safe test path is the bounded CT101 poller pointed at the temporary laptop controller.

## Runtime enablement remains separate

This stage does not enable WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED in the live wrapper runtime.
That should happen only after this smoke passes.

## Rollback

If enabled later, rollback is:

- remove WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1 from the wrapper runtime environment
- restart the wrapper
