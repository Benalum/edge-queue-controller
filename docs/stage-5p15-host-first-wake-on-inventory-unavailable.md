# Stage 5P-15 Host-First Wake on Inventory Unavailable

Stage 5P-15 fixes the full host wake path discovered by Stage 5P-14.

## Problem

When pveso is powered off, Proxmox inventory is unavailable.

The automatic power tick could compute that Wake-on-LAN was eligible, but the worker start branch still blocked because CT101 inventory could not be evaluated.

Observed action:

- `worker_start_blocked_by_plan`
- reason: `Inventory unavailable; worker start plan could not be safely evaluated.`

## Fix

When logged-in web presence requires the host/container and worker start planning fails because inventory is unavailable:

1. Send Wake-on-LAN first.
2. Mark pveso as booting through the existing `system_boot_pveso` path.
3. Defer CT101 start planning until a later tick after Proxmox inventory returns.
4. Keep stop/shutdown protection active while web presence or boot grace is active.

## Safety

The branch only executes when:

- start demand exists
- web presence requires host or container
- worker start plan has `inventory_error`
- wake plan is eligible
- `EDGE_POWER_EXECUTE_WAKE=1`

If boot grace is already active, the branch does not spam WOL. It defers worker start until the host returns.

## Online verification

With pveso already online and CT101 already running, the patched controller stayed healthy and the normal online auto tick path continued working.

Observed online action:

- `auto_recover_running_worker_executed`

The new host-first branch is reserved for the offline-host/inventory-unavailable case.
