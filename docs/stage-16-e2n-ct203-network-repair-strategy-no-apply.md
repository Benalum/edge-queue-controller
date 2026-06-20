# Stage 16-E2N — CT203 Network Repair Strategy No-Apply

Date: 2026-06-20

## Purpose

Define a safe repair strategy for the CT203 ↔ PVESO inventory path after Stage 16-E2L found a CT203/PVESO LAN split.

This phase is **no-apply**. It does not change CT203 networking, Proxmox config, firewall rules, controller environment, services, DNS, tunnels, database state, or worker/model state.

## Current Situation

Known stable state:

- PVEW: running
- VM200: running
- CT203: running and still the live controller/API/queue authority
- CT204: stopped
- CT101: stopped after rollback
- CT201: stopped
- CT202: stopped
- private storage: not mounted
- CT203 controller service: active
- CT203 `/health`: HTTP 200
- CT203 `/system/status`: HTTP 200
- CT203 DB counts: unchanged
- `EDGE_POWER_EXECUTE_WAKE=false`

Known blocker:

- CT203 `/power/proxmox/inventory` returns HTTP 502.
- The inventory body reports SSH return code 255 and `No route to host`.
- CT203’s configured `EDGE_PROXMOX_SSH_TARGET` points to a stale PVESO LAN address in CT203’s current subnet.
- PVESO’s current `vmbr0` address is in the PVEW/PVESO LAN, not CT203’s current LAN.
- R5 showed:
  - PVEW and PVESO overlap.
  - CT203 and PVESO do not overlap.
  - CT203 target is in CT203’s network but not PVESO’s current network.

## Constraints

CT203 is live authority. Network mutation has higher blast radius than earlier docs/smoke phases.

Until a separate approval is provided:

- do not change CT203 net0
- do not add/remove CT203 IP addresses
- do not restart CT203
- do not restart CT203 networking
- do not restart the controller service
- do not mutate VM200 nginx
- do not mutate Cloudflare/DNS/tunnels
- do not start CT101
- do not register workers
- do not activate scheduler lanes
- do not write database state

## Repair Options

### Option A — Temporary secondary CT203 LAN IP for PVESO inventory path

Add a temporary secondary IP on CT203 `eth0` in the PVEW/PVESO LAN, then test CT203 → PVESO tcp/22 and forced-command SSH.

Benefits:

- Lowest public-route blast radius.
- Does not replace CT203’s existing primary IP.
- Avoids immediate VM200 upstream changes.
- Easy rollback: remove temporary secondary IP.
- Allows proving CT203 can reach PVESO before persistent config changes.

Risks:

- Requires selecting an unused IP.
- Runtime-only unless later persisted.
- The controller inventory endpoint will not recover until `EDGE_PROXMOX_SSH_TARGET` is updated and the controller process is restarted or reloaded.
- Must avoid duplicate IPs.

Status: **recommended first mutation path**, after one more no-apply/approval boundary that selects a candidate address and rollback command.

### Option B — Full CT203 primary network realignment

Change CT203 `net0` primary address/gateway to the PVEW/PVESO LAN.

Benefits:

- Cleaner long-term LAN alignment.
- Makes CT203 match PVEW/PVESO.

Risks:

- Highest blast radius.
- Could break VM200 → CT203 proxy if VM200 points at CT203’s old IP.
- Could interrupt public `/system/status`.
- May require updating VM200 nginx upstreams and restarting/reloading nginx.
- May require CT203 restart or network restart.
- Requires console rollback path.

Status: not first choice.

### Option C — Move PVESO back to CT203’s stale subnet

Change PVESO to match CT203’s current LAN/subnet.

Benefits:

- Could restore CT203 inventory without touching CT203.

Risks:

- PVESO currently overlaps PVEW.
- Changing PVESO could break PVEW ↔ PVESO management and SSH path.
- Conflicts with current PVEW/PVESO network reality after router/gateway changes.

Status: not recommended.

### Option D — Use Tailscale SSH from CT203

Install/configure Tailscale inside CT203 or otherwise make CT203 reach PVESO over Tailscale.

Benefits:

- Avoids LAN split.

Risks:

- CT203 currently does not have Tailscale.
- Installing/configuring Tailscale inside live controller is a larger mutation.
- Adds identity/auth state to CT203.
- More moving parts than a LAN repair.

Status: fallback only.

## Recommended Next Step

Proceed with **Option A** as the next planned mutation, but only after a tiny pre-apply candidate selection step.

Next phase:

**Stage 16-E2O — CT203 temporary secondary LAN IP candidate plan no-apply**

E2O should:

- identify the PVEW/PVESO LAN prefix without printing raw IPs
- identify CT203’s existing LAN prefix without printing raw IPs
- propose a candidate temporary secondary IP on CT203 in the PVEW/PVESO LAN
- verify candidate is not already used using read-only/non-mutating probes
- write exact rollback command into the output and docs
- keep all live state unchanged

Then a later explicit approval could allow:

`APPROVE_STAGE_16_E2P_ADD_TEMP_CT203_SECONDARY_LAN_IP_FOR_PVESO_INVENTORY_TEST_NO_PUBLIC_ROUTE_CUTOVER_NO_DB_WRITE`

E2P should:

- add only a temporary secondary IP to CT203 `eth0`
- not change CT203 primary IP/gateway
- not change CT203 onboot/config
- not restart CT203
- not restart CT203 networking
- not change VM200 nginx
- not change Cloudflare/DNS/tunnels
- test CT203 → PVESO tcp/22
- test forced-command SSH
- if successful, separately approve controller env target update/restart
- if failed, remove secondary IP immediately

## Future Persistent Repair

Only after the temporary secondary IP proves safe should a persistent repair be considered.

Persistent options:

1. Persist CT203 secondary LAN address in Proxmox/LXC config while retaining old primary during transition.
2. Migrate VM200 upstreams and CT203 primary network together in a planned maintenance step.
3. Retire stale subnet after public route and inventory paths are verified.

## CT101 Follow-Up

Do not start CT101 again until the CT203/PVESO inventory path is repaired and a separate CT101 legacy-autostart neutralization plan exists.

CT101 blockers retained:

- legacy worker auto-start
- local queue controller auto-start
- Docker/containerd auto-start
- Ollama listener on tcp/11434
- app/API processes auto-starting without platform control

## Hard Stop Conditions for Any Future Apply

Immediately stop and roll back if any apply phase causes:

- CT203 `/health` not HTTP 200
- CT203 `/system/status` not HTTP 200
- DB counts change unexpectedly
- CT204 starts
- private storage mounts unexpectedly
- VM200 public routes regress
- CT203 cannot be reached from PVEW console/host
- duplicate IP is detected
- PVESO SSH path remains unreachable after temporary IP
