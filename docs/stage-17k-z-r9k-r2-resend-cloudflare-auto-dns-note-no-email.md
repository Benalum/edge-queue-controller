# Stage 17K-Z-R9K-R2 — Resend Cloudflare Auto-DNS Note, No Email

## Scope

This checkpoint recovers from the failed R9K attempt and records the operator update about Resend/Cloudflare DNS automation.

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

## Recovery

The first R9K script created its own smoke directory before checking for clean repo state, then blocked because that new untracked directory made the repo dirty.

R9K-R2 removes only the failed partial R9K artifacts and records a clean docs/smoke checkpoint.

## Operator update

Operator reported:

- The Resend API key stayed the same.
- The active Resend domain was changed to `buddieswhostudy.com`.
- Resend hooked up Cloudflare DNS automatically.

## Current expected email env

From the prior live env patch:

- `PUBLIC_BASE_URL=https://buddieswhostudy.com`
- `EMAIL_FROM=no-reply@buddieswhostudy.com`
- `EMAIL_FROM_NAME=Buddies Who Study`

## DNS interpretation

Stage 17K-Z-R9J-R2 queried selected public DNS names and saw successful DNS responses with zero answers for those guessed names.

Because Resend/Cloudflare automation may create exact records under names shown by the dashboard, and because DNS propagation can lag, this checkpoint does not guess DNS records and does not treat guessed-query zero answers as the final source of truth.

## Hard email gate

Do not send production or beta email until:

`buddieswhostudy.com` is shown as `Verified` in the Resend dashboard.

The Resend dashboard remains the source of truth.

## Next safe action

1. Open the Resend dashboard.
2. Open the `buddieswhostudy.com` domain.
3. Confirm whether the domain status is `Verified`.
4. If verified, run a separate bounded email-readiness checkpoint before sending any email.
5. If not verified, inspect the exact DNS records shown by Resend/Cloudflare and wait for propagation or repair only those exact records.
