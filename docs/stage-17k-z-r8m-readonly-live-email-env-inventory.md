# Stage 17K-Z-R8M-R2 — Read-only Live Email/Domain Env Inventory

Status: read-only inventory finalized  
Baseline: `d06a33f`

## Purpose

Check whether live CT203 runtime configuration still references the removed Resend sender domain `alexhartel.com`.

## Result

Repo defaults are updated:

- `PUBLIC_BASE_URL=https://buddieswhostudy.com`
- `EMAIL_FROM=no-reply@buddieswhostudy.com`
- `EMAIL_FROM_NAME=Buddies Who Study`

Public route posture is good:

- `https://buddieswhostudy.com/` returns HTTP 200;
- `https://www.buddieswhostudy.com/` returns HTTP 200;
- `https://alexhartel.com/` redirects to `https://buddieswhostudy.com/`;
- `https://www.alexhartel.com/` redirects to `https://buddieswhostudy.com/`.

Live CT203 env inventory did not complete because PVEW SSH timed out.

Because live inventory was unavailable, R8M-R2 does not claim whether live CT203 currently uses the old or new sender. It only confirms repo defaults and public route posture.

## Expected Runtime Values

Future live runtime should use:

- `PUBLIC_BASE_URL=https://buddieswhostudy.com`
- `EMAIL_FROM=no-reply@buddieswhostudy.com`
- `EMAIL_FROM_NAME=Buddies Who Study`

## Secret Handling

R8M-R2 only records non-secret domain/email sender variables and public HTTP posture.

It does not print provider keys, API secrets, tokens, database URLs, cookies, or credentials.

## Generated Inventory

Raw inventory:

`docs/generated/stage-17k-z-r8m-readonly-live-email-env-inventory.txt`

Machine summary:

`docs/generated/stage-17k-z-r8m-readonly-live-email-env-inventory.json`

## Recommended Next Stage

R8N should restore or confirm PVEW/CT203 reachability, then perform either:

1. read-only live env confirmation if reachable; or
2. a small approved live CT203 env patch and backend restart only after the exact live env path is confirmed.

## Boundaries Held

R8M-R2 does not mutate live env, Resend, DNS, Cloudflare, VM200, CT203, backend, DB, nginx/cloudflared, models, workers, or schedulers.
