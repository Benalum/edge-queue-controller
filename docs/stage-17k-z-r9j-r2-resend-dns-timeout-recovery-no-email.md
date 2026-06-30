# Stage 17K-Z-R9J-R2 — Resend DNS Timeout Recovery, No Email

## Scope

This checkpoint recovers from a PPB timeout during Stage 17K-Z-R9J.

Mutation scope:

- Repo docs/smoke only.
- No runtime mutation.
- No CT/VM/service restart.
- No backend/frontend deploy.
- No DB write.
- No email send.
- No Resend API call.
- No production or beta invite email.

## Recovery reason

The first R9J attempt timed out before final state could be confirmed. This R2 checkpoint uses shorter network timeouts and a smaller DNS/public smoke surface.

## Resend gate

Production and beta email remain blocked until this condition is manually confirmed:

`buddieswhostudy.com` is `Verified` in the Resend dashboard.

This checkpoint does not verify the dashboard and does not send email.

## Smoke coverage

R2 records:

- `https://buddieswhostudy.com/` HTTP status.
- `POST https://buddieswhostudy.com/api/auth/register` remains HTTP 403 with `closed_beta_signup_disabled`.
- Public DNS-over-HTTPS observations for:
  - `buddieswhostudy.com TXT`
  - `buddieswhostudy.com MX`
  - `resend._domainkey.buddieswhostudy.com CNAME`

## Decision

If R2 passes while Resend dashboard remains manually unknown:

- Keep signup closed.
- Keep production/beta email blocked.
- Continue product work that does not depend on outbound email.
