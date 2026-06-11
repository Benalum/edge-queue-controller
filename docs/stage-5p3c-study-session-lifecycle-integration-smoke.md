# Stage 5P-3C Study Session Lifecycle Integration Smoke

Adds a test-only lifecycle smoke for the durable Study session endpoints.

The smoke verifies:

- create deck
- create card
- start session
- status active
- pause session
- status paused
- resume session
- status active
- stop session
- status no longer active

This stage does not add runtime behavior.
