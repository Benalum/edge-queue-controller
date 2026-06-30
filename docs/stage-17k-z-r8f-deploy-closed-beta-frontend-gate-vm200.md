# Stage 17K-Z-R8F — Deploy Closed Beta Frontend Gate to VM200

Status: live VM200 frontend deploy complete  
Baseline source: `29c6225`

## Purpose

Deploy the R8B closed-beta frontend banner and browser-side sign-up guard to VM200.

## Live target

- VM: `200`
- Live root: `/var/www/apc-wrapper-local`
- Deployed files:
  - `index.html`
  - `privatepages/closed-beta-signup-guard.js`

## Live result

Observed deploy marker:

`PASS_VM200_R8F_QGA_TARGETED_INSTALL`

Public HTTP smoke confirmed:

- root contains the closed-beta banner marker;
- root loads `/privatepages/closed-beta-signup-guard.js?v=20260629-stage17k-z-r8b-closed-beta`;
- root still loads the R7D GoogleSync runtime config script;
- closed-beta guard script is publicly reachable;
- existing GoogleSync runtime config remains publicly reachable;
- backend `/api/auth/register` still returns `403 closed_beta_signup_disabled`.

## User-facing copy

`Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`

## Boundaries Held

R8F did not:

- deploy backend code;
- write CT203 files;
- write DB rows;
- mutate DNS or Cloudflare;
- mutate Google Cloud;
- mutate email provider settings;
- call models;
- activate workers or schedulers;
- restart nginx/cloudflared.

## Next

Proceed to domain/DNS/Cloudflare preparation for `buddieswhostudy.com` only after confirming the closed-beta UI appears correctly in a browser.
