# Stage 17K-Z-R8G-R4 — Remove Login Click Blocker, Keep Signup Closed

Status: live VM200 frontend hotfix complete  
Baseline source: `76623f0`

## Purpose

The R8G-R3 browser-side guard still interfered with the header Login/Register opener. R8G-R4 removes document-level click interception entirely.

## Result

R8G-R4:

- removed the document-level click blocker from `closed-beta-signup-guard.js`;
- kept the register tab disabled/hidden when the auth modal is present;
- kept the browser fetch guard blocking `/auth/register`, `/register`, and `/signup`;
- kept the backend `/api/auth/register` gate returning `403 closed_beta_signup_disabled`;
- deployed only `privatepages/closed-beta-signup-guard.js` to VM200.

Observed deploy marker:

`PASS_VM200_R8G_R4_REMOVE_LOGIN_CLICK_BLOCKER_INSTALL`

## Boundaries Held

R8G-R4 did not deploy backend code, write CT203 files, write DB rows, mutate DNS/Cloudflare, mutate Google Cloud, mutate email provider settings, restart nginx/cloudflared, call models, or activate workers/schedulers.
