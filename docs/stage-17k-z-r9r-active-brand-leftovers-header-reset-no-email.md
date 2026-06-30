# Stage 17K-Z-R9R — Active Brand Leftovers: Header and Reset

## Scope

This checkpoint fixes active browser/user-facing brand leftovers found after R9Q.

Targeted active leftovers:

- `header/header.html`
- `auth/reset.js`

Allowed mutation:

- Source patch for active header/reset browser labels.
- Tiny VM200 package for `header/header.html` and `auth/reset.js`.
- Direct no-sudo VM200 update if writable, otherwise clean manual-sudo blocker.
- Repo docs/smoke commit/tag/push.

Explicitly not allowed:

- No backend deploy.
- No CT203 mutation.
- No DB write.
- No email send.
- No signup opening.
- No password reset request.
- No nginx/cloudflared config mutation.
- No service restart/reload/start/stop.
- No CT/VM restart.

## Current checkpoint

- Previous HEAD: `aa49247`
- Previous tag: `controller-stage-17k-z-r9q-verify-browser-brand-label-deploy-2026-06-30`

## Reason

R9Q verified the public root title as `Buddies Who Study`, but remote live static scan still found active leftovers:

- `header/header.html` aria labels
- `auth/reset.js` reset-password document title

Backups and `.bak` files are not targeted here.

## Desired result

Active header and reset password browser/user-facing labels should use:

`Buddies Who Study`

Registration must remain blocked with:

`closed_beta_signup_disabled`.
