# Stage 5P-3B Study Session Lifecycle Endpoints

Adds backend-only durable Study session lifecycle endpoints:

- `POST /api/study/session/pause`
- `POST /api/study/session/resume`
- `POST /api/study/session/stop`
- `POST /public/study/session/pause`
- `POST /public/study/session/resume`
- `POST /public/study/session/stop`

This stage does not add command routing, model routing, queue lanes, or UI wiring.

Pause/resume/stop all operate on the current active durable session for the authenticated/current user.
