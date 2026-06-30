# Stage 17K-Z-R9I — Resend Verification Gate and Closed-Beta Public Smoke

## Scope

This checkpoint records the next safe move after the Stage 17K-Z-R9H source refresh.

Mutation scope:

- Repo docs/smoke only.
- No runtime mutation.
- No CT/VM/service restart.
- No backend/frontend deploy.
- No DB write.
- No email send.
- No Resend API call.
- No production or beta invite email.

## Baseline

Current expected source checkpoint:

- HEAD: `dc17dff`
- Full commit: `dc17dff934d161167973a4ba6327119d5428061a`
- Prior tag: `controller-stage-17k-z-r9g-website-edge-jkg76nid-ssh-alias-fix-2026-06-30`

## Public routing expectations

Expected public posture:

- `https://buddieswhostudy.com/` returns HTTP 200.
- `https://www.buddieswhostudy.com/` returns HTTP 200.
- `http://alexhartel.com/` redirects/finalizes to `https://buddieswhostudy.com/`.
- `http://www.alexhartel.com/` redirects/finalizes to `https://buddieswhostudy.com/`.
- `POST https://buddieswhostudy.com/api/auth/register` remains blocked with HTTP 403 and closed-beta marker.

## Resend gate

`buddieswhostudy.com` is the active Resend domain target, but production/beta email remains blocked until the Resend dashboard explicitly shows:

`buddieswhostudy.com` = `Verified`

This checkpoint intentionally does not call the Resend API and does not send any email.

## Evidence

See generated smoke evidence under:

`docs/smoke/generated/stage-17k-z-r9i-resend-verification-gate-and-closed-beta-public-smoke/`

## Decision

If public smoke passes and Resend remains unverified or manually unknown:

- Keep signup closed.
- Keep email sending blocked.
- Continue product/UI work that does not depend on outbound email.

If Resend dashboard is verified later:

- Run a separate bounded email-readiness checkpoint before sending any beta invite or production email.
