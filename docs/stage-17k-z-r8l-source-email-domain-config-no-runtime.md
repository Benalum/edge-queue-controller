# Stage 17K-Z-R8L-R2 — Source Email/Domain Config Update, No Runtime Mutation

Status: source defaults updated and finalized  
Baseline: `10862cf`

## Purpose

After the public product domain moved to `buddieswhostudy.com` and Resend was changed to use the new domain, update repo defaults so future deploys do not try to send email from the removed `alexhartel.com` Resend domain.

## Source Defaults Updated

`.env.example` now uses:

- `PUBLIC_BASE_URL=https://buddieswhostudy.com`
- `EMAIL_FROM=no-reply@buddieswhostudy.com`
- `EMAIL_FROM_NAME=Buddies Who Study`

`frontend/wrapper-ui/robots.txt` now points the sitemap to:

- `https://buddieswhostudy.com/sitemap.xml`

## Important Runtime Note

This stage does not update live CT203 environment variables.

If live CT203 currently has `EMAIL_FROM=no-reply@alexhartel.com`, email sending may fail because `alexhartel.com` was removed from Resend.

A later approved runtime stage should update live environment config to use the verified Resend sender:

- `no-reply@buddieswhostudy.com`

## Resend Status

User reported:

- `alexhartel.com` was removed from Resend;
- `buddieswhostudy.com` was added to Resend.

Before sending production or beta emails, verify the new Resend domain and its DNS records in Resend.

## Boundaries Held

R8L-R2 does not mutate live env, Resend, DNS, Cloudflare, VM200, CT203, backend, DB, nginx/cloudflared, models, workers, or schedulers.
