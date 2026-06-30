# Stage 17K-Z-R9N — One Bounded Forgot Password Request

## Scope

This checkpoint performs one bounded Forgot Password request for an explicitly controlled existing-user email address.

Mutation scope:

- One public forgot-password request.
- Repo docs/smoke commit/tag/push.
- No runtime mutation.
- No CT/VM/service restart.
- No backend/frontend deploy.
- No registration opening.
- No beta invite.
- No production email blast.

## Current checkpoint

- Previous HEAD: `c031b95`
- Previous tag: `controller-stage-17k-z-r9m-forgot-password-readiness-no-email-2026-06-30`

## Safety boundaries

This checkpoint is only for existing-user access recovery.

It must not:

- open public registration,
- create a new account,
- send beta invites,
- send production email blasts,
- mutate backend/frontend runtime.

## Precheck

Before the forgot-password request, `/api/auth/register` must return:

- HTTP 403
- `closed_beta_signup_disabled`

## Request

The request is sent to:

`POST https://buddieswhostudy.com/api/auth/forgot-password`

The target email is not stored in plaintext in evidence. Evidence stores only:

- email domain,
- SHA256 hash of full email.

## Postcheck

After the forgot-password request, `/api/auth/register` must still return:

- HTTP 403
- `closed_beta_signup_disabled`

## Next manual action

Check the target inbox for the reset email.

If the reset email arrives, use the reset link to reset the existing account password.

Registration should remain closed.
