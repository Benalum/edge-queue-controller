# Stage 5P-10E Native Companion Queue Session Bridge

Fixes real logged-in Companion queued-chat creation.

Problem:

- The wrapper login stores active tokens in native SQLite user_sessions.
- The queued-chat real-user resolver checks app_sessions through chat_queue_persistence.
- Browser Companion requests therefore failed with:
  queued_chat_session_auth_failed_stage_5f17

Fix:

- Mirror a valid native wrapper session token into the queued-chat app_users/app_sessions tables.
- Resolve queued-chat auth from the mirrored session.
- Keep server-side identity ownership.
- Keep client-provided user_id refused.
- Remove client-generated chat_id from Companion job creation so the server creates an owned chat.

This stage keeps:

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}
- X-Queued-Chat-Session-Token
- existing worker behavior
