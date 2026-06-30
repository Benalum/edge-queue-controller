# Stage 17K-Z-R9S — Record and Verify Active Header/Reset Brand Fix

## Scope

This checkpoint verifies the manual live patch for the two active VM200 browser-brand leftovers and records those active split files back into source.

Mutation scope:

- Verify-only public and remote static checks.
- Pull fixed active VM200 static files into source mirror.
- Repo docs/smoke commit/tag/push.
- No runtime mutation.
- No deploy.
- No CT/VM/service restart.
- No backend deploy.
- No DB write.
- No email send.
- No signup opening.
- No password reset request.

## Current checkpoint

- Previous HEAD: `552f192`
- Previous tag: `controller-stage-17k-z-r9r-active-brand-leftovers-header-reset-no-email-2026-06-30`

## Files recorded into source

- `frontend/wrapper-ui/apc-wrapper-local/header/header.html`
- `frontend/wrapper-ui/apc-wrapper-local/auth/reset.js`

## Acceptance criteria

- Remote active header/reset files contain no old Alex/Hartel brand labels.
- Source mirror files contain no old Alex/Hartel brand labels.
- Public root title remains `Buddies Who Study`.
- Public reset route contains no old Alex/Hartel brand labels.
- Registration remains HTTP 403 with `closed_beta_signup_disabled`.
