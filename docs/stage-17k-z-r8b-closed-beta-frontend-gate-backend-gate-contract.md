# Stage 17K-Z-R8B — Closed Beta Frontend Gate + Backend Gate Contract

Status: source-only closed beta frontend gate  
Baseline: `0079d27`

## User-facing Copy

`Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`

## Source Changes

Active public wrapper source:

- `frontend/wrapper-ui/apc-wrapper-local/index.html`

New browser-side guard:

- `frontend/wrapper-ui/apc-wrapper-local/privatepages/closed-beta-signup-guard.js`

The frontend gate:

- shows the closed-beta banner;
- hides/disables the Register tab button;
- blocks visible create-account/register clicks;
- intercepts browser-side `/auth/register`, `/register`, and `/signup` fetch calls with a 403 closed-beta response.

## Backend Boundary

The frontend/browser-side gate is not the final security boundary.

R8B source mapping did not find the backend registration route. Therefore:

- DNS/Cloudflare cutover to `buddieswhostudy.com` remains blocked.
- Google Cloud domain cutover remains blocked.
- Public launch remains blocked.
- Backend account creation must be located and gated before external beta traffic is allowed.

Required backend behavior:

- Existing/test user sign-in continues.
- Public registration/create-account returns a closed-beta refusal.
- Admin/invite-only creation may be added later.

## Not Performed

R8B does not deploy to VM200, mutate DNS/Cloudflare, mutate Google Cloud, mutate email provider settings, restart backend, write DB rows, restart nginx/cloudflared, or activate workers/schedulers/models.
