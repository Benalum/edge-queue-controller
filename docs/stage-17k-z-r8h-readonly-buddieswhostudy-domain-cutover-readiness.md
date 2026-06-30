# Stage 17K-Z-R8H — Read-only Buddies Who Study Domain Cutover Readiness

Status: read-only inventory completed and finalized  
Baseline: `e94c3cf`

## Purpose

Inventory readiness for moving the public AI Platform Control product surface from `alexhartel.com` toward `buddieswhostudy.com`.

## Boundaries

R8H was read-only. It did not:

- mutate DNS;
- mutate Cloudflare;
- mutate Google Cloud;
- mutate email provider settings;
- deploy frontend or backend code;
- write VM200 files;
- write CT203 files;
- restart backend;
- write DB rows;
- restart nginx/cloudflared;
- call models;
- activate workers or schedulers.

## Current Closed-beta Posture

Closed-beta gating is live on the current domain:

- public banner says account creation is temporarily closed;
- header Login/Register opens login and forgot-password only;
- register/create-account is hidden/unavailable;
- backend `/api/auth/register` returns HTTP `403` with `closed_beta_signup_disabled`.

## Read-only Inventory Findings

Generated summary reported:

- `buddieswhostudy.com` resolves;
- `www.buddieswhostudy.com` resolves;
- current `alexhartel.com` closed-beta frontend marker is live;
- current `alexhartel.com` backend closed-beta registration gate is live;
- DNS/Cloudflare cutover work is still needed;
- Google OAuth origin update is still needed;
- email domain planning is still needed.

## Inventory Limitations

The read-only SSH inventory portions for VM200 and PVEW timed out during this run:

- VM200 SSH timeout;
- PVEW SSH timeout.

Those timeouts do not invalidate the public HTTP/DNS findings, but R8I should either restore SSH reachability or use the last-known VM200/PVEW configuration before producing a mutation plan.

## Generated Inventory

Raw inventory:

`docs/generated/stage-17k-z-r8h-readonly-buddieswhostudy-domain-cutover-readiness.txt`

Machine summary:

`docs/generated/stage-17k-z-r8h-readonly-buddieswhostudy-domain-cutover-readiness.json`

## Expected Next Stage

R8I should prepare an exact no-mutation change plan for:

1. Cloudflare/DNS route for `buddieswhostudy.com`;
2. `www.buddieswhostudy.com` redirect or CNAME behavior;
3. Google OAuth JavaScript origin updates;
4. email sending domain and SPF/DKIM/DMARC plan;
5. later `alexhartel.com` portfolio separation.

R8I should remain no-mutation unless explicitly approved.
