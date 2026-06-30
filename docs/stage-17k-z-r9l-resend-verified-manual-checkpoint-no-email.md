# Stage 17K-Z-R9L — Resend Verified Manual Checkpoint, No Email

## Scope

This checkpoint records the manual Resend dashboard verification for `buddieswhostudy.com`.

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

## Current source checkpoint

- Previous HEAD: `1b0169a`
- Previous tag: `controller-stage-17k-z-r9k-r2-resend-cloudflare-auto-dns-note-no-email-2026-06-30`

## Operator verification

Operator manually checked the Resend dashboard and reported:

`buddieswhostudy.com` = `Verified`

This clears the manual Resend domain verification gate.

## Current expected live email env

From Stage 17K-Z-R8Q:

- `PUBLIC_BASE_URL=https://buddieswhostudy.com`
- `EMAIL_FROM=no-reply@buddieswhostudy.com`
- `EMAIL_FROM_NAME=Buddies Who Study`

## Closed-beta guard

This checkpoint rechecks that:

`POST https://buddieswhostudy.com/api/auth/register`

still returns HTTP 403 with:

`closed_beta_signup_disabled`

## Important decision

This checkpoint does not send email.

Even though the Resend domain is now verified, the next step must be a bounded email-readiness/config checkpoint before any actual test email, production email, or beta invite email is sent.

## Next safe action

Run a separate bounded readiness checkpoint that verifies:

- live email env values,
- public base URL,
- signup remains closed,
- existing sign-in remains allowed,
- email send path is understood,
- first send target is explicitly controlled.
