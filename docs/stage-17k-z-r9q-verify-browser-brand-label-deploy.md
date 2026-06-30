# Stage 17K-Z-R9Q — Verify Browser Brand Label Deploy

## Scope

This checkpoint verifies the public browser-label deploy after the manual interactive sudo update on website-edge.

Mutation scope:

- Verify-only public and remote static checks.
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

- Previous HEAD: `20d7a05`
- Previous tag: `controller-stage-17k-z-r9p-r2-website-edge-brand-deploy-recovery-2026-06-30`

## Acceptance criteria

Public root must show:

`Buddies Who Study`

Public root must not show:

`AlexHartel AI Platform`

Registration must remain blocked:

`POST /api/auth/register` returns HTTP 403 with `closed_beta_signup_disabled`.
