# Route Ownership

## Canonical rule

Credits belong to the controller, not CT101.

Do not add credit wallets, credit ledgers, rewarded-ad sessions, or credit balance routes to CT101.

## Controller-owned systems

Repository:

- `~/Desktop/edge-queue-controller`

Primary files:

- `edge_controller.py`
- `public_gateway.py`
- `frontend/wrapper-ui/app.js`
- `cloudflare/edge-public-proxy/src/index.js`

Controller owns:

- public auth/session used by the wrapper
- account credit balances
- free/local credits
- paid credits
- rewarded ad status and claim flow
- GPU quote/reservation/commit/refund credit workflows
- system status and power controls
- public wrapper APIs

Important controller routes:

- `GET /system/account/credits`
- `POST /system/credits/reserve`
- `POST /system/credits/commit`
- `POST /system/credits/refund`
- `POST /system/credits/grant`
- `POST /system/credits/reserve-v2`
- `POST /system/credits/commit-v2`
- `POST /system/credits/refund-v2`
- `POST /system/credits/grant-free`
- `POST /system/credits/grant-paid`
- `GET /system/ads/reward/status`
- `POST /system/ads/reward/claim`

## CT101-owned systems

Repository/path:

- `/opt/ai-platform`

CT101 owns:

- study backend/frontend
- companion backend/frontend
- calendar backend/frontend
- private app UI
- worker node pages
- private internal app APIs

CT101 must not own:

- credit wallets
- credit ledgers
- rewarded ad sessions
- `/api/credits/*`
- `/credits` public credit page

## Deprecated/forbidden CT101 credit pieces

These should not exist in active CT101 code:

- `backend/app/routes/rewarded_credits.py`
- `user_credit_wallets`
- `credit_ledger`
- `rewarded_ad_sessions`
- `frontend/app/credits/page.tsx`
- `/api/credits/balance`
- `/api/credits/rewarded/status`
- `/api/credits/rewarded/start`
- `/api/credits/rewarded/claim`

## Public page ownership

`alexhartel.com/credits` is the public wrapper page.

Source:

- `frontend/wrapper-ui/app.js`
- `frontend/wrapper-ui/index.html`

It calls controller-backed APIs through the public proxy path.

## Rule for future changes

Before adding a new route, decide which owner it belongs to:

- controller: billing, credits, power, public wrapper, system state
- CT101: study, companion, calendar, private app

Do not duplicate a route or table across both systems.
