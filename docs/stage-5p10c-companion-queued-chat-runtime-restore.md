# Stage 5P-10C Companion Queued Chat Runtime Restore

Restores Companion queued-chat runtime configuration.

Problem:

- Companion canonical UI loads.
- POST /api/chat/queued returns Stage 5F-9 feature_disabled.
- .env does not include the required laptop queued chat feature flags.

Runtime config restored:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1

This stage does not commit .env.
This stage does not change backend code.
This stage does not change worker behavior.
