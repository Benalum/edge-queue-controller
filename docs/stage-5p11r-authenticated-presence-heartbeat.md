# Stage 5P-11R Authenticated Presence Heartbeat

Fixes logged-in web presence for power automation.

The power tick already treats authenticated web presence as start demand. This stage makes the frontend reliably send authenticated presence:

- Adds Authorization header to `/presence/web` when `authState.token` exists.
- Bypasses debounce when auth state changes.
- Sends a logged-in heartbeat after 15 seconds.
- Keeps logged-in private-app heartbeats fresh every minute.
- Adds `private_app` metadata for debugging.

Expected behavior:

- Logged-in active user => `active_authenticated > 0`.
- Power policy => `host_required: true`, `container_required: true`.
- Power tick can wake pveso and start CT101 even without queued jobs.
