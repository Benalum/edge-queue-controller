# Stage 17K-Z-R9M — Forgot Password Readiness, No Email

## Scope

This checkpoint records the intended access-recovery path after Resend verification.

Mutation scope:

- Repo docs/smoke only.
- No runtime mutation.
- No CT/VM/service restart.
- No backend/frontend deploy.
- No DB write.
- No email send.
- No Resend API call.
- No Cloudflare API call.
- No DNS mutation.
- No password reset request.

## Current checkpoint

- Previous HEAD: `c42a73d`
- Previous tag: `controller-stage-17k-z-r9l-resend-verified-manual-checkpoint-no-email-2026-06-30`

## Product decision

Forgot Password is allowed for existing users so an existing account can regain access.

Public registration remains blocked.

This means:

- Existing users may use password reset.
- New users cannot create accounts while closed beta is active.
- `/api/auth/register` must remain blocked with `closed_beta_signup_disabled`.

## Resend state

Stage 17K-Z-R9L recorded the operator's manual Resend dashboard verification:

`buddieswhostudy.com` = `Verified`

This R9M checkpoint still does not send email.

## Smoke coverage

R9M records:

- public root is reachable,
- public register endpoint remains blocked,
- source contains password reset / forgot-password references,
- source contains registration / closed-beta gate references,
- likely reset-related public GET route probes are recorded without sending email.

## Next safe action

The next stage may perform one bounded Forgot Password request only for an explicitly controlled existing-user email address.

That stage must still:

- avoid opening registration,
- avoid sending beta invites,
- avoid production email blasts,
- record evidence,
- verify `/api/auth/register` remains blocked afterward.
