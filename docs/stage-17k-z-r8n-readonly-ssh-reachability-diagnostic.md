# Stage 17K-Z-R8N — Read-only SSH Reachability Diagnostic

Status: read-only diagnostic recorded  
Baseline: `ba0e04e`

## Purpose

Diagnose why R8M could not inspect live CT203 email/domain environment: PVEW SSH timed out.

Live email sender config should not be patched until the live env path is reachable and confirmed.

## Scope

R8N checks:

- local hostname and routes;
- local name resolution for `pvew` and `website-edge`;
- Tailscale status if the command exists;
- TCP/SSH reachability to PVEW and VM200 aliases;
- public route health for `buddieswhostudy.com` and redirects from `alexhartel.com`.

## Boundaries Held

R8N does not mutate network config, Tailscale config, SSH config, live env, DNS, Cloudflare, Resend, VM200, CT203, backend, DB, nginx/cloudflared, models, workers, or schedulers.

## Generated Inventory

Raw inventory:

`docs/generated/stage-17k-z-r8n-readonly-ssh-reachability-diagnostic.txt`

Machine summary:

`docs/generated/stage-17k-z-r8n-readonly-ssh-reachability-diagnostic.json`

## Expected Next Step

If SSH remains unavailable, fix local Tailscale/LAN SSH reachability first.

If SSH works, rerun read-only live CT203 env inventory and then patch live sender config only after confirming the exact env file.
