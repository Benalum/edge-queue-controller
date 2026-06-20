# Stage 16-E2O — CT203 Temporary Secondary LAN IP Candidate Plan No-Apply

Date: 2026-06-20

## Purpose

Plan a low-blast-radius repair for the CT203 ↔ PVESO inventory path.

This checkpoint is **no-apply** and local-repo-only. It does not add an IP address, change CT203 networking, restart services, update controller environment, start CT101, write the database, activate workers, or call model endpoints.

## Known Safe Baseline from Prior Checks

Prior completed checks established:

- VM200 running
- CT203 running
- CT204 stopped
- CT101 stopped after rollback
- CT201 stopped
- CT202 stopped
- private storage not mounted
- CT203 controller service active
- CT203 `/health` HTTP 200
- CT203 `/system/status` HTTP 200
- CT203 DB counts unchanged
- `EDGE_POWER_EXECUTE_WAKE=false`

## Known Blocker

Stage 16-E2L/R5/R6S established:

- CT203 and PVESO are split across different LAN/subnet ranges.
- PVEW and PVESO overlap on one LAN.
- CT203 does not overlap with PVESO.
- CT203’s configured `EDGE_PROXMOX_SSH_TARGET` is stale.
- CT203 inventory endpoint returns HTTP 502 because SSH to the stale target fails with `No route to host`.

## Chosen First Repair Strategy

Use a **temporary secondary IP** on CT203 `eth0` in the PVEW/PVESO LAN.

This is preferred before primary network migration because it should:

- avoid replacing CT203’s current primary IP
- avoid changing CT203’s default gateway
- avoid changing VM200 nginx upstreams
- avoid restarting CT203
- avoid restarting CT203 networking
- provide a simple rollback path
- prove whether CT203 can reach PVESO tcp/22 before any persistent change

## Future E2P Approval Boundary

Future explicit approval phrase:

`APPROVE_STAGE_16_E2P_ADD_TEMP_CT203_SECONDARY_LAN_IP_FOR_PVESO_INVENTORY_TEST_NO_PUBLIC_ROUTE_CUTOVER_NO_DB_WRITE`

E2P should allow only:

- compute a candidate temporary secondary address at runtime
- add the temporary secondary address to CT203 `eth0`
- test CT203 → PVESO tcp/22
- test CT203 forced-command SSH to PVESO
- remove the temporary address immediately on failure

E2P must not:

- persist network config
- change CT203 primary IP
- change CT203 gateway
- restart CT203
- restart CT203 networking
- change VM200 nginx
- change Cloudflare/DNS/tunnels
- start CT101
- start CT204
- mount private storage
- write DB state
- activate workers
- activate scheduler lanes
- call Ollama/model endpoints

## Candidate Selection Requirements

The E2P apply block must:

1. Determine PVESO’s current LAN prefix at runtime.
2. Choose a candidate address in that prefix.
3. Exclude known addresses already used by PVEW and PVESO.
4. Probe for duplicate address risk before applying.
5. Avoid printing raw IP addresses in final output.
6. Keep rollback command ready before applying.
7. Fail closed if the candidate appears unsafe.

## Rollback Shape

The rollback command shape is:

```bash
pct exec 203 -- ip addr del <candidate>/<prefix> dev eth0Run with Project Pilot
Run with Project Pilot

E2P must run rollback automatically if connectivity checks fail.

Success Criteria for E2P

E2P is successful only if:

CT203 /health remains HTTP 200
CT203 /system/status remains HTTP 200
DB counts remain unchanged
VM200 remains running
CT204 remains stopped
private storage remains not mounted
CT101 remains stopped
CT203 can reach PVESO tcp/22 using the temporary secondary address path
CT203 forced-command SSH to PVESO works
no worker/model/scheduler activation occurs
Follow-Up if E2P Succeeds

A separate later stage should update:

EDGE_PROXMOX_SSH_TARGET
controller service reload/restart if required

That later stage must have its own explicit approval because it mutates controller environment and live controller service state.

Follow-Up if E2P Fails

If E2P fails:

remove the temporary address
keep CT203’s primary network unchanged
do not start CT101
do not update controller environment
reassess router/LAN design
Current Recommendation

Proceed to E2P only with explicit approval and keep it runtime-only, reversible, and narrowly scoped.
