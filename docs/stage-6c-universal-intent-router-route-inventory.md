# Stage 6C Universal Intent Router Route Inventory

Stage 6C inventories current routes and frontend input surfaces before adding the Universal Intent Router.

This stage does not change runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, power automation, or frontend behavior.

## Goal

Create a route-level map of where user input enters the platform today.

The Universal Intent Router should not be inserted blindly.

Every candidate route must be classified before migration.

## Route classes

### Router candidate routes

Routes that eventually may pass through the Universal Intent Router:

- Study answer/input routes.
- Study command-like inputs such as next, skip, hint, or explain.
- Companion message routes.
- Legacy Chat message routes if still used.
- Future Calendar natural-language request routes.
- Profile preference natural-language update routes.

### Direct application routes

Routes that should remain direct app logic:

- Login/logout/session.
- Account/profile reads.
- Static page serving.
- Presence heartbeats.
- Health checks.
- System status reads.
- File/static assets.

### Internal service routes

Routes that must not go through a natural-language router:

- Queue worker registration.
- Queue worker heartbeat.
- Job claim/complete/fail endpoints.
- Internal smoke/test endpoints.
- Worker registry endpoints.
- Laptop queue internal endpoints.

### Admin/system routes

Routes that must remain guarded and explicit:

- Power wake/start/stop/shutdown.
- Admin user management.
- System configuration.
- Infrastructure actions.
- Any route that can mutate machines, queues, users, billing, security, or provider connections.

The router may help explain these actions in the future, but it must not execute them from casual natural language without explicit confirmation and permission checks.

## Classification fields

Every route inventory row should eventually include:

- route path
- HTTP method
- backend function name
- surface/page
- current payload shape
- current handler
- future router category
- migration priority
- safety class
- confirmation required
- notes

## Initial safety classes

- `read_only`
- `user_content_write`
- `user_preference_write`
- `provider_read`
- `provider_write_confirmed`
- `admin_read`
- `admin_write_confirmed`
- `infrastructure_read`
- `infrastructure_write_confirmed`
- `internal_worker_only`
- `auth_security`
- `static_asset`

## Migration priority

### Priority 1

Low-risk text interpretation routes.

Examples:

- Study card command normalization.
- Companion chat dispatch.
- General help/explanation requests.

### Priority 2

Routes that need user context and permissions but are still safe.

Examples:

- Profile preference suggestions.
- Calendar read requests.
- Study material creation drafts.

### Priority 3

Confirmed writes.

Examples:

- Calendar write after explicit confirmation.
- Profile preference update after explicit confirmation.
- Study material save after preview.

### Never direct-router-execute

Examples:

- Shutdown host.
- Stop containers.
- Delete user data.
- Change account security.
- Send external messages.
- Worker internal queue mutation.
- Admin-only infrastructure commands.

## Expected route inventory sources

Stage 6C should inspect:

- `edge_controller.py`
- `public_gateway.py` if present
- frontend JavaScript
- frontend HTML
- wrapper UI files
- docs from Stage 6A and 6B

## Stage 6C deliverable

This stage creates:

1. A route inventory planning document.
2. A readonly smoke test that extracts route names for inspection.
3. A generated route inventory text file from current source code.

The generated inventory is not a final migration plan.

It is a baseline snapshot for Stage 6D.
