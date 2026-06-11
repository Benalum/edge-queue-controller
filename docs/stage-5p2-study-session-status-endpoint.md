# Stage 5P-2 Study Session Status Endpoint

Adds the first durable Study Session backend foundation:

- `study_sessions` table
- `GET /api/study/session/status`
- `GET /public/study/session/status`

This stage is read-only. It does not start, pause, resume, stop, or modify a session.

Calendar remains provider-backed only. No local calendar database is added.
