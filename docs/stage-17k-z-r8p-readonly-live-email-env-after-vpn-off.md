# Stage 17K-Z-R8P — Read-only Live Email Env After VPN Off

Status: read-only live env inventory recorded  
Baseline: `d6dc4e9`

## Purpose

After the VPN was turned off, retry live CT203 email/domain env inventory.

## Expected Runtime Values

Live runtime should use:

- `PUBLIC_BASE_URL=https://buddieswhostudy.com`
- `EMAIL_FROM=no-reply@buddieswhostudy.com`
- `EMAIL_FROM_NAME=Buddies Who Study`

## Secret Handling

R8P records only non-secret sender/domain keys:

- `PUBLIC_BASE_URL`
- `EMAIL_FROM`
- `EMAIL_FROM_NAME`
- `REPLY_TO`
- `SUPPORT_EMAIL`

It does not print provider keys, API secrets, tokens, database URLs, cookies, or credentials.

## Generated Inventory

Raw inventory:

`docs/generated/stage-17k-z-r8p-readonly-live-email-env-after-vpn-off.txt`

Machine summary:

`docs/generated/stage-17k-z-r8p-readonly-live-email-env-after-vpn-off.json`

## Boundaries Held

R8P does not mutate live env, Resend, DNS, Cloudflare, VM200, CT203, backend, DB, nginx/cloudflared, models, workers, or schedulers.
