# Stage 16 R3S — Admin Users Online/Offline Only

## Goal

Replace the placeholder Admin console content with a narrow, useful admin MVP:

- show a read-only list of all non-deleted platform users,
- show each user as online or offline,
- keep the page admin-only,
- remove support inbox, credit tools, platform controls, and system overview content from the visible `/admin` page.

## Source changes

### Frontend

`frontend/wrapper-ui/app.js` now includes `APC_ADMIN_USERS_ONLY_PAGE_R3S`, a final `/admin` route owner that renders only:

- current admin email,
- online user count,
- total users returned,
- last refreshed state,
- a users table with status, user, role, last seen, and active session count.

The frontend loads users from `/api/admin/users`, with `/api/system/admin/users` as a compatibility fallback through the wrapper API base.

### Backend

`edge_controller.py` keeps `/system/admin/users` as the canonical endpoint and adds protected aliases:

- `/api/admin/users`
- `/admin/users`

The endpoint still requires admin auth through `_admin_support_require_admin()`. It now returns all non-deleted users instead of truncating the admin users list to 250 rows.

Online status remains conservative and read-only. A user is online when their last seen timestamp is inside `ADMIN_ONLINE_WINDOW_SECONDS` seconds, defaulting to 300 seconds.

### Gateway compatibility

`public_gateway.py`, `frontend/wrapper-ui/dev_server.py`, and `cloudflare/edge-public-proxy/src/index.js` now recognize `/api/admin/users` and forward it to the controller-owned `/system/admin/users` route while preserving bearer auth.

## Non-goals

This patch does not add user editing, deletion, role changes, account lockout, support-ticket controls, credit grants, system controls, or backend writes.

## Safety posture

- No database schema change.
- No database write path added.
- No service restart in source.
- No model/helper/worker invocation.
- No power/runtime action.
- Admin endpoint remains protected by backend permission checks.
