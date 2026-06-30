# Stage 17K-Z-R8O — Read-only Tailscale/Direct SSH Debug

Status: read-only diagnostic recorded  
Baseline: `dcad930`

## Purpose

Diagnose laptop-to-management reachability after R8N-R2 showed:

- public routes are healthy;
- `pvew` and `website-edge` aliases did not resolve through `getent`;
- Tailscale IPs were visible;
- SSH to those Tailscale IPs timed out.

## Scope

R8O checks:

- Tailscale status;
- Tailscale netcheck;
- Tailscale ping to PVEW and VM200 IPs;
- direct TCP port 22 checks;
- direct SSH checks;
- resolver/MagicDNS clues;
- public route health.

## Boundaries Held

R8O does not mutate network config, Tailscale config, SSH config, live env, DNS, Cloudflare, Resend, VM200, CT203, backend, DB, nginx/cloudflared, models, workers, or schedulers.

## Generated Inventory

Raw inventory:

`docs/generated/stage-17k-z-r8o-readonly-tailscale-direct-ssh-debug.txt`

Machine summary:

`docs/generated/stage-17k-z-r8o-readonly-tailscale-direct-ssh-debug.json`

## Expected Next Step

- If Tailscale ping fails: fix Tailscale connectivity on PVEW/VM200.
- If Tailscale ping works but port 22 times out: inspect remote firewall or sshd from console.
- If SSH succeeds: rerun live CT203 env inventory, then patch sender config if needed.
