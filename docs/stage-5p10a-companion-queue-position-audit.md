# Stage 5P-10A Companion Queue Position Audit

Audit the existing queue schema, queue routes, and Companion frontend polling flow before adding queue size / user position display.

Feature goal:
- show queue size
- show user's position in queue
- show current job id/status
- keep existing /api/chat/queued behavior
- avoid changing worker behavior

This is an audit-only stage.
