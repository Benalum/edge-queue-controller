# Stage 5P-11T Session Me Presence Touch

Uses `/system/session/me` as a reliable authenticated web presence heartbeat.

Reason:

- The browser already calls `/system/session/me` while logged in.
- Frontend presence can fail or be delayed by cache/auth timing.
- Power automation needs a fresh authenticated presence row to keep pveso and CT101 online for logged-in users.

Behavior:

- Every successful `/system/session/me` call refreshes a `web_presence` row named `session-me-user-<id>`.
- That row is authenticated and visible.
- Power policy then sees `active_authenticated > 0`.
- Power tick can treat logged-in presence as start demand even when no jobs are queued.
