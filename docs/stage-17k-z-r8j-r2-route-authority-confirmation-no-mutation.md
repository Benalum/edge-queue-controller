# Stage 17K-Z-R8J-R2 — Route Authority Confirmation, No Mutation

Status: read-only route authority inventory complete  
Baseline: `a4f80e8`

## Purpose

Confirm which layer should control the `buddieswhostudy.com` cutover before any DNS, tunnel, nginx, or app mutation.

R8J-R2 avoids provider API-token usage and relies on:

- public DNS;
- public HTTP;
- public registration-gate checks;
- optional VM200 SSH read-only config inspection;
- optional PVEW SSH read-only route hints.

## Boundaries

R8J-R2 is read-only. It does not:

- mutate DNS;
- mutate Cloudflare;
- mutate tunnel routes;
- mutate Google Cloud;
- mutate email provider settings;
- deploy frontend or backend code;
- write VM200 files;
- write CT203 files;
- restart backend;
- write DB rows;
- restart nginx/cloudflared;
- call models;
- activate workers or schedulers.

## Generated Inventory

Raw inventory:

`docs/generated/stage-17k-z-r8j-r2-route-authority-confirmation-no-mutation.txt`

Machine summary:

`docs/generated/stage-17k-z-r8j-r2-route-authority-confirmation-no-mutation.json`

## Decision Rule

If `buddieswhostudy.com` and `www.buddieswhostudy.com` already serve the closed-beta app and return `403 closed_beta_signup_disabled` for registration, then DNS mutation may already be unnecessary.

If they resolve but do not serve the closed-beta app, use the R8J-R2 inventory to choose between:

- adding tunnel public hostnames;
- changing DNS;
- adding VM200 nginx server names;
- or a combined change.

Do not mutate DNS or routing until the exact route authority and rollback records are confirmed.
