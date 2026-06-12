# Stage 5P-11S Presence Send Fallback

Fixes browser web presence delivery after Stage 5P-11R.

The Stage 5P-11R app.js was served, but no fresh browser web_presence rows were created. This stage makes the sender more robust:

- Tries the wrapper `api("/presence/web")` helper first.
- Falls back to `/system/presence/web`.
- Falls back to `/api/presence/web`.
- Falls back to `${API_BASE}/presence/web`.
- Adds backend route aliases for `/api/presence/web` and `/presence/web`.
- Bumps the app.js cache version in index.html.

Expected result after hard refresh while logged in:

- A fresh web_presence row appears.
- If authenticated, `active_authenticated > 0`.
- Power policy sets `container_required: true`.
