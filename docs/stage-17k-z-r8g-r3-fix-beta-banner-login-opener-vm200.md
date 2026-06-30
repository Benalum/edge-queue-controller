# Stage 17K-Z-R8G-R3 — Fix Beta Banner and Login Opener

Status: live VM200 frontend hotfix complete  
Baseline source: `0a191b5`

## Purpose

Fix two browser-visible issues after R8G-R2:

1. The public banner still included the old Anki/Companion/Google sync tail after the closed-beta sentence.
2. The browser-side signup guard blocked the combined Login/Register opener because it matched any clicked text containing `register`.

## Result

R8G-R3:

- changed the public banner to exactly:
  `Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`
- removed the Anki/Companion/Google sync tail from `index.html`;
- kept the browser-side signup guard loaded;
- narrowed the click blocker so Login/Register can open login while explicit registration controls remain blocked;
- preserved the backend registration gate returning `403 closed_beta_signup_disabled`;
- deployed only:
  - `index.html`
  - `privatepages/closed-beta-signup-guard.js`

Observed deploy marker:

`PASS_VM200_R8G_R3_BANNER_LOGIN_HOTFIX_INSTALL`

## Boundaries Held

R8G-R3 did not deploy backend code, write CT203 files, write DB rows, mutate DNS/Cloudflare, mutate Google Cloud, mutate email provider settings, restart nginx/cloudflared, call models, or activate workers/schedulers.
