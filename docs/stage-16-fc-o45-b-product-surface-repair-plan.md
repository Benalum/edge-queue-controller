# Stage 16 FC-O45-B — Product Surface Repair Plan

Date: 2026-06-24  
Scope: product-surface planning only. No live deployment, no DB write, no worker/model runtime, no scheduler/timer activation.

## Decision

Pause queue/concurrency runtime work after FC-O43-F-R8-R2 and move to a visible product repair track before trying to onboard testers.

The queue work is still important, but the current bottleneck for real testing is that signed-in Study/Admin/Companion surfaces are not product-coherent yet. The platform should first show useful signed-in pages, route to working backend data, and expose the Study/Companion features users can actually test.

## Current evidence

From FC-O45-A read-only audit and visual browser review:

- Public root and wrapper are live.
- Public `/api/system/status` returns HTTP 200.
- Public `/api/me` returns HTTP 401 when signed out, which is expected.
- Public Admin data endpoints currently return HTTP 404:
  - `/api/account/users`
  - `/api/account/online-users`
  - `/api/credits/admin`
  - `/api/support/admin`
  - `/api/jobs`
- Signed-in Study currently shows a durable Study session panel, but also repeats an older Study page block:
  - “Study session”
  - “Deck selector”
  - then another “Study / Study / Create decks, add cards, review by difficulty...”
- Signed-in Study is missing the complete product tools expected from the earlier Study surface:
  - Deck list/management
  - Card list/add/edit
  - Stats/progress
  - Review controls
- Admin currently shows empty user/activity/support/infrastructure data despite the platform having account/auth/status concepts.
- Companion still needs backend text wiring before speech/listen work should be added.
- Speech/listen should be added only after text Companion is working and behind feature flags.

## Product-first repair order

### FC-O45-C — Signed-in Study dedupe and restore tools

Goal: make Study usable for a signed-in tester.

Allowed target behavior:

- Keep the durable Study session panel.
- Remove duplicate/embedded repeated Study page block.
- Restore visible signed-in Study modules:
  - Decks
  - Cards
  - Stats/progress
  - Review controls
- Signed-out Study should remain public-safe and should not leak private deck/card/user data.
- If an API route is not ready, show an honest disabled/empty state instead of duplicating layout.

Suggested verification:

- Public `/` loads.
- Signed-out Study remains safe.
- Signed-in Study contains one Study heading/layout.
- Signed-in Study includes durable session plus Decks/Cards/Stats/Review areas.
- No DB mutation required for the UI patch itself.

### FC-O45-D — Admin route/data binding repair

Goal: make Admin reflect real backend data or explicit unavailable states.

Observed problem:

- Public Admin frontend is likely calling `/api/account/users`, `/api/account/online-users`, `/api/credits/admin`, `/api/support/admin`, and `/api/jobs`, but these return 404 from the public compatibility layer.

Repair direction:

- Decide whether VM200 nginx should map these paths to CT203 backend routes, or whether frontend should call existing mapped paths.
- Do not invent fake users.
- Do not expose sensitive user fields publicly.
- Admin must remain signed-in/admin-only.
- If an endpoint is unavailable, show “Unavailable” with diagnostic status rather than “0 users” as if authoritative.

Suggested verification:

- Admin no longer reports misleading zero users when the endpoint is 404.
- Admin shows endpoint health/status per module.
- User list uses redacted/safe fields.
- Support inbox and credits tools bind to real backend routes or show explicit unavailable status.

### FC-O45-E — Companion backend text path

Goal: connect Companion tab to a backend text endpoint without depending on the broken queue/concurrency path.

Repair direction:

- Implement a simple text backend path first.
- Prefer a durable job enqueue/status path only if it can gracefully show queued/running/failed.
- Otherwise add a temporary non-model echo/status path for UI wiring, clearly labeled as under construction.
- Do not block Companion UI on CT101 worker readiness.
- Do not start scheduler/persistent workers.

Suggested verification:

- Signed-in Companion accepts a message.
- Backend returns either a real response, queued job status, or explicit unavailable state.
- No internal prompt/queue/worker details appear in user-visible text.

### FC-O45-F — Companion speak/listen feature flags

Goal: add browser speech/listen controls only after text Companion works.

Repair direction:

- Listening: browser microphone capture to a signed-in STT endpoint.
- Speaking: TTS endpoint response playable in browser.
- Feature flag both controls.
- Provide graceful unsupported-browser/error states.
- Do not require queue concurrency to be complete before basic UI wiring.

Suggested verification:

- Microphone controls only show when enabled.
- TTS controls only show when enabled.
- User sees clear permission/error messages.
- No raw internal endpoint failures leak into the UI.

### FC-O45-G — Return to queue/concurrency

Only after Study/Admin/Companion text surfaces are usable:

- Resume FC-O43-F job117 exact runtime path.
- Complete CT101 worker config postflight.
- Prove job117 exact runtime.
- Then prove limited concurrency.
- Then enable tester-ready Companion model path.

## Guardrails

- Keep VM200 as public/static wrapper authority unless separately approved.
- Keep CT203 as controller/API/queue authority.
- Do not activate scheduler/timers/persistent workers during product UI repairs.
- Do not start/stop/restart CTs or VMs unless separately approved.
- Do not perform DB writes for UI-only patches.
- Do not fake Admin user data.
- Do not leak private user info, private IPs, tokens, or internal worker details.
- Do not expose queue/model errors directly to signed-in users except as product-safe unavailable states.

## Recommended next action

Proceed with FC-O45-C as the first product-visible repair:

1. Read-only inspect the exact VM200 wrapper `app.js` Study rendering functions.
2. Patch repo/source wrapper if tracked.
3. If VM200 public file is the active source of truth, patch only the public wrapper file with a backup and no service restart.
4. Smoke:
   - root HTTP 200
   - app.js HTTP 200
   - signed-out Study safe
   - signed-in Study static markers include Decks/Cards/Stats/Review
   - duplicate Study layout marker count reduced
5. Record doc/smoke/commit/tag after verification.
