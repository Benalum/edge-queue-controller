# Stage 17K-Z-R8N-R2 — Correct SSH Reachability Summary, No Mutation

Status: generated R8N summary corrected  
Baseline: `9029d74`

## Purpose

R8N collected useful raw evidence, but the generated JSON summary incorrectly reported PVEW and VM200 SSH as working.

R8N-R2 corrects the summary from the raw evidence.

## Correct Raw Finding

Public route health is good:

- `buddieswhostudy.com` returns HTTP 200;
- `www.buddieswhostudy.com` returns HTTP 200;
- `alexhartel.com` redirects to `https://buddieswhostudy.com/`;
- `www.alexhartel.com` redirects to `https://buddieswhostudy.com/`.

Local management reachability is not good:

- `getent hosts pvew` returned no address;
- `getent hosts website-edge` returned no address;
- Tailscale status showed `pvew` and `website-edge` online;
- SSH to PVEW Tailscale IP timed out;
- SSH to VM200 Tailscale IP timed out.

## Corrected Conclusion

The public website migration is healthy, but laptop-to-management SSH is currently unavailable.

Do not patch live CT203 email sender configuration until PVEW/CT203 management reachability works.

## Recommended Next Stage

R8O should run a read-only Tailscale ping/netcheck and direct Tailscale-IP SSH debug to determine whether this is:

- stale MagicDNS/alias resolution;
- Tailscale connectivity;
- remote firewall;
- remote sshd;
- or local routing.

## Boundaries Held

R8N-R2 does not mutate network config, Tailscale config, SSH config, live env, DNS, Cloudflare, Resend, VM200, CT203, backend, DB, nginx/cloudflared, models, workers, or schedulers.
