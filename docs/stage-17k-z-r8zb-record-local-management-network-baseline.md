# Stage 17K-Z-R8ZB — Local Management Network Baseline

## Scope

This checkpoint records the local laptop management-network recovery baseline after the Buddies Who Study domain cutover and Resend sender migration.

Mutation scope for the diagnostic stage was local laptop networking/SSH configuration only.

This checkpoint does not deploy, restart services, write the production database, send email, or mutate remote hosts.

## Confirmed state

- WireGuard `home` full-tunnel initially routed selected Tailscale peer IPs through `dev home table 51820`.
- Runtime route exceptions were added for:
  - `100.127.73.75` — `pvew`
  - `100.105.133.69` — `website-edge`
  - `100.88.194.19` — `pveso`
  - `100.88.245.33` — `llms` / `ct101`
- Route resolution changed to `dev tailscale0 table 51820`.
- `/etc/wireguard/home.conf` now contains the APC `PostUp` / `PostDown` route exception block under `[Interface]`.
- `wg-quick strip /etc/wireguard/home.conf` passed.
- `ssh pvew 'hostname; whoami'` succeeds as `pvew` / `root`.
- `ssh website-edge 'hostname; whoami'` no longer times out, but fails authentication with `Permission denied (publickey,password,keyboard-interactive)`.

## Current interpretation

The VPN/Tailscale routing issue is fixed for the selected management IPs.

`website-edge` is now a separate SSH-auth problem. The laptop offered all loaded agent keys, including the key accepted by `pvew`, but VM200 rejected them.

## Next safe step

Keep remote mutation blocked until a controlled VM200 SSH credential repair stage is approved.

Likely repair choices:

1. Add the same laptop public key accepted by `pvew` to VM200 root `authorized_keys`.
2. Use a different `IdentityFile` for `website-edge` if VM200 expects a different key.
3. Use a controlled `ProxyJump pvew` path if VM200 is intentionally administered through PVEW.
