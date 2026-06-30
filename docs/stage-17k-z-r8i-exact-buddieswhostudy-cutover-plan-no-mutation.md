# Stage 17K-Z-R8I — Exact Buddies Who Study Cutover Plan, No Mutation

Status: exact plan created; no infrastructure mutation  
Baseline: `cc3ad25`

## Purpose

Prepare the exact migration path from `alexhartel.com` to `buddieswhostudy.com` without changing DNS, Cloudflare, Google, email, VM200, CT203, nginx, or cloudflared.

## Current Safe Posture

From R8H/R8H-R2:

- `alexhartel.com` is serving the closed-beta frontend;
- existing login works from the header Login/Register flow;
- register/create-account is hidden/unavailable;
- backend `/api/auth/register` returns HTTP `403` with `closed_beta_signup_disabled`;
- `buddieswhostudy.com` resolves;
- `www.buddieswhostudy.com` resolves;
- DNS/Cloudflare cutover is still not changed;
- Google OAuth origins are still not changed;
- email domain setup is still not changed.

## Important Limitation

R8H recorded SSH timeouts to VM200 and PVEW. That means the next stage should not mutate Cloudflare or DNS until the active route authority is confirmed.

Route authority means confirming which layer currently maps public hostnames to the app:

- Cloudflare DNS records;
- Cloudflare Tunnel public hostnames;
- VM200 nginx `server_name` behavior;
- some combination of the above.

## Recommended Domain Behavior

Initial cutover should be conservative:

- `buddieswhostudy.com` serves the same closed-beta app;
- `www.buddieswhostudy.com` also serves the same closed-beta app;
- later, after stability, `www` can optionally redirect to apex;
- `alexhartel.com` remains in place until Buddies Who Study is stable;
- after stability, `alexhartel.com` can become the portfolio/projects site.

## Exact Mutation Sequence After Approval

### R8J — Route Authority Confirmation, No Mutation

Confirm current Cloudflare zone, DNS records, tunnel public hostnames, and VM200 nginx behavior.

No mutation.

### R8K — Cloudflare/DNS/Tunnel Cutover

After R8J confirms the route authority:

- add or adjust `buddieswhostudy.com`;
- add or adjust `www.buddieswhostudy.com`;
- route both to the same closed-beta app currently serving `alexhartel.com`;
- capture rollback records first.

### R8L — Public Smoke

Verify:

- `https://buddieswhostudy.com/` serves the closed-beta app;
- `https://www.buddieswhostudy.com/` serves the closed-beta app or redirects as intended;
- header Login/Register opens login;
- register/create-account remains unavailable;
- `/api/auth/register` returns `403 closed_beta_signup_disabled`;
- `/api/me` remains GET-capable;
- `/api/auth/login` remains POST-capable.

### R8M — Google OAuth Origin Update

Add authorized JavaScript origins:

- `https://buddieswhostudy.com`
- `https://www.buddieswhostudy.com`

Keep beta/test users configured until the OAuth app publishing decision is made.

### R8N — Email Domain Plan or Setup

Prepare sender/reply-to domain for `buddieswhostudy.com`.

Required records:

- SPF;
- DKIM;
- DMARC.

Do not send public beta invitations until email authentication is verified.

### R8O — Product-facing Source Domain Cleanup

Replace product-facing `alexhartel.com` links with `buddieswhostudy.com` where appropriate.

Do not blindly rewrite historical docs, admin notes, logs, or internal runbooks.

### R8P — AlexHartel.com Portfolio Split

After Buddies Who Study is stable, repurpose `alexhartel.com` as a portfolio/projects site.

## Go / No-Go

Go for R8J read-only route authority confirmation.

Do not proceed to R8K mutation until route authority is confirmed and rollback records are captured.

## Generated Plan

Machine-readable plan:

`docs/generated/stage-17k-z-r8i-exact-buddieswhostudy-cutover-plan-no-mutation.json`
