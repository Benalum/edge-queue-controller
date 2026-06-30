# Stage 17K-Z-R9G — Website-Edge jkg76nid SSH Alias Fix Record

## Scope

This checkpoint records the final local management SSH recovery for website-edge / VM200 after the Buddies Who Study domain cutover.

Mutation scope for the final fix was local laptop SSH alias configuration only.

This checkpoint does not mutate remote hosts, restart VPN, restart services, deploy, write the database, or send email.

## Confirmed final state

pvew SSH alias:

    pvew
    root

website-edge / VM200 SSH alias:

    website-edge
    jkg76nid

## Important finding

VM200 is the Proxmox VM ID for the Tailscale node named website-edge.

VM200 has PermitRootLogin no, so the website-edge SSH alias must not use root.

The correct local SSH user for website-edge / vm200 is:

    jkg76nid

## Routing proof

The laptop is connected to the WireGuard VPN named home, but selected Tailscale management IPs are routed through tailscale0 using the WireGuard table exception.

Confirmed route decisions from laptop Tailscale IP 100.108.171.94:

    100.127.73.75 from 100.108.171.94 dev tailscale0 table 51820
    100.105.133.69 from 100.108.171.94 dev tailscale0 table 51820

This proves the SSH management path uses Tailscale routing, not the home VPN route.

## Current SSH alias posture

- pvew -> 100.127.73.75 as root
- website-edge / vm200 -> 100.105.133.69 as jkg76nid
- Both use BindAddress 100.108.171.94
- Both route through tailscale0 table 51820

## Safe next step

With PVEW and VM200 management SSH restored, future remote diagnostics can use normal aliases again.

Remote mutation should still remain stage-bounded and explicit.
