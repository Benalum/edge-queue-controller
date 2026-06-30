# Stage 17K-Z-R9D — VM200 Normal-User SSH Repair Record

## Scope

This checkpoint records the VM200 / website-edge SSH authentication repair after local VPN/Tailscale routing was fixed.

VM200 is the Proxmox VM ID for the Tailscale node named `website-edge`.

## Background

WireGuard `home` full-tunnel initially routed selected Tailscale peer IPs through `dev home table 51820`.

Local route exceptions were added and persisted under `[Interface]` in `/etc/wireguard/home.conf`, causing selected management IP routes to resolve through `dev tailscale0 table 51820`.

After routing was fixed:

- `ssh pvew 'hostname; whoami'` succeeded.
- `ssh website-edge 'hostname; whoami'` reached TCP/22 but failed with `Permission denied (publickey,password,keyboard-interactive)`.

## Root login finding

A controlled VM200 repair attempt refused to mutate root SSH authorization because VM200 sshd reported:

- `PermitRootLogin no`

This is the safer posture and was preserved.

## Repair

VM200 was repaired through PVEW using Proxmox `qm guest exec` without `--capture-output`, because this PVEW `qm` version does not support `--capture-output`.

The repair scope was limited to:

- Adding the laptop public key to the selected normal VM200 user's `authorized_keys`.
- Updating the local laptop `website-edge` / `vm200` SSH alias to use that normal user.

The repair explicitly did not change:

- `PermitRootLogin`
- root `authorized_keys`
- sshd service state
- nginx/cloudflared
- website files
- database state
- email state

## Expected final smoke

- `ssh pvew 'hostname; whoami'` returns `pvew` and `root`.
- `ssh website-edge 'hostname; whoami'` returns `website-edge` and the selected normal user.
- Routes to `100.127.73.75` and `100.105.133.69` from the laptop Tailscale IP resolve through `tailscale0`.
