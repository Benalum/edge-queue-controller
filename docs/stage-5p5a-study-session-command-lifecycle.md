# Stage 5P-5A Study Session Command Lifecycle Endpoint

Adds a backend command endpoint that uses the deterministic parser to execute lifecycle commands.

New endpoints:

- `POST /api/study/session/command`
- `POST /public/study/session/command`

Implemented commands in this stage:

- study session status
- study session start
- study session pause
- study session resume
- study session stop

Not implemented yet:

- read answer
- mark correct
- mark incorrect
- skip
- next card
- answer grading
- model routing
- queue lanes
- UI wiring

This stage intentionally keeps card-level behavior for the next stage.
