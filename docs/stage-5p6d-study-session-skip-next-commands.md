# Stage 5P-6D Study Session Skip / Next Commands

Adds card-advance commands to the durable Study session command endpoint.

Implemented through `POST /api/study/session/command`:

- `skip`
- `next_card`

Behavior:

- requires an active/current session
- refuses to advance while paused
- advances to the next card without writing a correct/incorrect review
- completes the session when no cards remain

This stage keeps skip/next separate from review grading.
