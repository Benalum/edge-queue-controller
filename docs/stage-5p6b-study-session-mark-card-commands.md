# Stage 5P-6B Study Session Mark Card Commands

Adds card marking commands to the durable Study session command endpoint.

Implemented through `POST /api/study/session/command`:

- `mark_correct`
- `mark_incorrect`

Behavior:

- requires an active/current session
- refuses to mark while paused
- writes a row to `study_reviews`
- advances to the next card when one exists
- sets the session to `completed` when the queue is finished

Not implemented yet:

- skip
- next card
- answer grading
- model routing
- queue lanes
- UI wiring
