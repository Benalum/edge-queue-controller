# Stage 5P-10F Companion Queue Position UI

Adds queue visibility to the working canonical Companion page.

The Companion status rail now displays:

- Queue size
- User position
- Jobs ahead

After a Companion message creates a queued job, the frontend polls:

- GET /api/chat/queue/status?job_id=<job_id>

Existing behavior is preserved:

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}
- X-Queued-Chat-Session-Token
- Native session bridge from Stage 5P-10E
