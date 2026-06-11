# Stage 5J-2 Current Route Ownership Summary — 2026-06-10

## Current decision

The laptop is the platform owner.

The laptop owns:

- public page routing
- auth/session/account
- Study data and Study API routes
- Companion data/context/chat routes
- Calendar routes
- Profile/account data
- Chat queue state
- system/status/power routes
- wrapper UI routing

CT101 is an execution worker node only.

CT101 owns:

- Ollama runtime
- model execution
- queue worker process
- hardware/model capacity

CT101 must not own user pages, auth, Study data, Companion data, Calendar data, Profile data, or frontend routing.

## Current active Study path

Browser -> laptop wrapper -> laptop controller /api/study/* -> laptop SQLite Study data

## Compatibility still present intentionally

- /api/backend/* bridge for current Chat queued compatibility
- /public/study/* aliases
- /public/companion/* aliases
- public_gateway.py source retained but port 7071 is not required for current Study path
- cloudflare/edge-public-proxy source retained as historical/compatibility source

## Cleanup rule

Do not add new CT101-owned Study, Companion, Calendar, Profile, or Auth routes. New features should use the laptop controller as data owner and treat CT101 as execution capacity only.
