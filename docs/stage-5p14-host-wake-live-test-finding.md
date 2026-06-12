# Stage 5P-14 Host Wake Live Test Finding

Stage 5P-14 tested whether logged-in web presence could wake the Proxmox host and recover CT101 after the host was intentionally powered off.

## Result

The test did not pass.

The timer continued running and `/power/auto/tick` continued returning successfully, but the host did not wake automatically during the test window.

## Key finding

When `pveso` is offline, Proxmox inventory is unavailable.

The tick result showed:

- `wake_plan_summary.eligible=true`
- `would_send=Wake-on-LAN magic packet to d8:bb:c1:03:fc:33 via UDP 192.168.0.255:9`
- `worker_start` action became `worker_start_blocked_by_plan`
- reason: `Inventory unavailable; worker start plan could not be safely evaluated.`

## Interpretation

The backend can compute that Wake-on-LAN is eligible, but the automatic action path currently blocks on inventory-backed worker start planning when the host is offline.

For full host recovery, wake must happen before inventory-dependent CT planning.

## Required follow-up

Create a host-first wake stage:

1. If web presence requires host/container and the host is unreachable, send WOL immediately.
2. Mark host as booting.
3. Skip CT start planning until host inventory becomes reachable.
4. On a later tick, once Proxmox is reachable, start CT101.
5. Keep shutdown blocked while web presence or boot grace is active.

## Current safe state

Stage 5P-12 remains valid:

- timer runs successfully
- service does not timeout
- current inventory is cleaned

Stage 5P-13 remains valid:

- CT101 auto-start works when Proxmox is already online

Stage 5P-14 identified the missing full host wake behavior.
