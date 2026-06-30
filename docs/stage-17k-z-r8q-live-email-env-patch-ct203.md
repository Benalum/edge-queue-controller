# Stage 17K-Z-R8Q — Live CT203 Email Env Patch

Status: live CT203 env patched and controller restarted  
Baseline: `ea16ec0`

## Purpose

Update live CT203 runtime sender/domain configuration after the Resend sender domain moved from `alexhartel.com` to `buddieswhostudy.com`.

## Live Env File

Patched file:

`/etc/edge-queue-controller/edge-queue-controller.env`

Expected live values:

- `PUBLIC_BASE_URL=https://buddieswhostudy.com`
- `EMAIL_FROM=no-reply@buddieswhostudy.com`
- `EMAIL_FROM_NAME=Buddies Who Study`

## Runtime Action

R8Q backs up the live env file, patches only public base URL and sender identity keys, restarts only `edge-queue-controller.service`, and verifies active process env.

## Public Smoke

R8Q verifies:

- `buddieswhostudy.com` remains HTTP 200;
- `www.buddieswhostudy.com` remains HTTP 200;
- `alexhartel.com` redirects to `https://buddieswhostudy.com/`;
- closed-beta registration remains blocked with HTTP `403 closed_beta_signup_disabled`.

## Boundaries Held

R8Q does not mutate Resend, DNS, Cloudflare, VM200, DB, nginx/cloudflared, models, workers, or schedulers.
