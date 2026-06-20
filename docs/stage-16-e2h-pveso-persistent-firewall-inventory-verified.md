# Stage 16-E2H — PVESO Persistent Firewall Inventory Verified

Date: 2026-06-20

## Summary

PVESO inventory access from CT203 is now durable across firewall reloads.

This checkpoint completes the PVESO inventory path needed before worker/model re-entry planning:

- CT203 can SSH to PVESO over LAN for inventory.
- The SSH key on PVESO is constrained by a forced inventory-only command.
- PVESO persistent firewall config allows only CT203 LAN source to PVESO tcp/22.
- CT203 controller `/power/proxmox/inventory` returns HTTP 200 and `ok=true`.
- No workers, models, scheduler lanes, jobs, Ollama calls, CT starts, VM starts, or DB writes were performed.

## Persistent Firewall Sources

Two persistent firewall sources were updated on PVESO:

1. `/etc/nftables.d/tslock.nft`
   - Adds CT203 LAN source -> PVESO tcp/22 allow before the existing LAN drop for tcp/22 and tcp/8006.
   - Marker: `apc-stage16e2h-ct203-pveso-inventory`

2. `/etc/pve/nodes/pveso/host.fw`
   - Adds CT203 LAN source -> PVESO tcp/22 host firewall allow.
   - Marker: `apc-stage16e2h-ct203-pveso-inventory-pvefw-host`

CT203 was not added to the broad Proxmox `management` IPSet, because that would also open wider management ports such as 8006, console ports, and related management ranges.

## Reload Verification

After persistent config was written:

- `nft -c -f /etc/nftables.d/tslock.nft` passed.
- `pve-firewall compile` passed.
- `tslock.service` was restarted/reloaded.
- `pve-firewall restart` was executed.
- The nft allow rule loaded before the drop rule.
- The PVEFW host allow loaded before `PVEFW-Drop`.
- CT203 tcp/22 to PVESO LAN remained reachable.
- CT203 forced-command SSH to PVESO succeeded.
- CT203 `/power/proxmox/inventory` returned:
  - HTTP 200
  - `ok=true`
  - host id `pveso`
  - hostname `pveso`
  - CT101 `llms`, stopped
  - CT201 `edge-data`, stopped
  - CT202 `edge-controller`, stopped
  - VMs: 0

`tslock.service` may show inactive after restart; the authoritative validation is the loaded nft chain plus the working CT203 inventory path.

## Safety State

After reload:

- `EDGE_POWER_EXECUTE_WAKE=false`
- CT203 controller service active
- VM200 running
- CT203 running
- CT204 stopped
- private storage not mounted
- no DB count changes
- no worker/model/scheduler activation
- no Ollama/model endpoint calls
- no job/session writes

## DB Count Guard

Counts remained unchanged:

- `user_sessions:235`
- `jobs:23`
- `job_results:6`
- `router_logs:0`
- `router_resolution_steps:0`
- `router_feedback:0`
- `workers:2`
- `worker_events:3`

## Next Safe Step

Continue with read-only PVESO worker/model inventory:

- inspect CT101/llms state without starting it
- inspect PVESO storage/model paths without loading models
- inspect Ollama service/config presence without calling model endpoints
- identify the least-risk worker/model activation path
