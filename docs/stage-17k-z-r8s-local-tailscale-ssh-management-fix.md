# Stage 17K-Z-R8S — Local Tailscale SSH Management Fix

Status: local laptop SSH config patched  
Baseline: a152875

## Purpose

Fix local management SSH so APC host aliases prefer Tailscale instead of being disrupted by the home VPN/WireGuard route.

## Local Files Patched

Local laptop files only:

- ~/.ssh/config
- ~/.ssh/config.d/apc-tailscale-management.conf

The APC include is added to ~/.ssh/config if missing:

Include ~/.ssh/config.d/*.conf

## Management Aliases

The generated SSH config maps management aliases to Tailscale IPs:

- pvew / pvew-ts -> 100.127.73.75
- website-edge / vm200 -> 100.105.133.69
- pveso -> 100.88.194.19
- llms / ct101 -> 100.88.245.33

The config uses BindInterface tailscale0 when supported by OpenSSH, otherwise it falls back to BindAddress using the local Tailscale IPv4.

## Expected Usage

Use these aliases:

- ssh pvew
- ssh website-edge
- ssh pveso
- ssh llms

For CT203 container work, continue using:

ssh pvew 'pct exec 203 -- bash -lc "...command..."'

## Boundaries Held

R8S does not mutate PVEW, CT203, VM200, PVESO, CT101, DNS, Cloudflare, Resend, live env, backend, DB, nginx/cloudflared, models, workers, or schedulers.
