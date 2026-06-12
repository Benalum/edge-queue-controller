# Stage 5P-10B Companion Queue Status Endpoint

Adds an authenticated Companion queue visibility endpoint.

Endpoint:

- GET /api/chat/queue/status
- GET /api/chat/queue/status?job_id=<job>

It returns:

- waiting_count
- running_count
- total_active
- optional job status
- optional queue position
- optional ahead_count

This stage does not change worker behavior and does not change POST /api/chat/queued.
