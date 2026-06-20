# Stage 16-E2H — PVESO LAN Inventory Path Runtime-Firewall Checkpoint

Date: 2026-06-20

## Scope

This checkpoint records the working PVESO inventory path from CT203 to PVESO over LAN after the corrected Wake-on-LAN path was validated.

This phase intentionally does **not** activate workers, models, Ollama calls, scheduler dispatch, or job execution.

## Authority State

- PVEW remains the always-on platform host.
- VM200 remains the public website edge.
- CT203 remains the controller/API/queue authority.
- CT204 remains stopped, onboot disabled, backup-data-only, and not private-data authority.
- PVESO is the intended on-demand model/worker host but remains non-authoritative.

## What Changed Before This Checkpoint

The following runtime/config work was completed under explicit E2H approval:

1. CT203 generated a dedicated root SSH key for PVESO inventory access.
2. CT203 public key was installed on PVESO root authorized keys using a forced inventory-only command.
3. PVESO `/root/.ssh/authorized_keys` was confirmed to be a normal Proxmox symlink to `/etc/pve/priv/authorized_keys`; target mode was `600`.
4. PVESO runtime nft rule was inserted in `inet tslock input` before the existing LAN drop:
   - allow only CT203 LAN source to PVESO tcp/22.
5. PVESO runtime iptables rule was inserted in `PVEFW-HOST-IN` before `PVEFW-Drop`:
   - allow only CT203 LAN source to PVESO tcp/22.
6. CT203 controller env was updated:
   - `EDGE_PROXMOX_HOST_ID=pveso`
   - `EDGE_PROXMOX_SSH_TARGET=root@PVESO_LAN_IP`
   - `EDGE_POWER_EXECUTE_WAKE=false`
7. CT203 controller service was restarted once after env update.
8. `/power/proxmox/inventory` returned HTTP 200 and `ok=true`.

## Validated Result

The controller inventory endpoint now sees PVESO:

- host id: `pveso`
- hostname: `pveso`
- containers:
  - CT101 `llms`, stopped
  - CT201 `edge-data`, stopped
  - CT202 `edge-controller`, stopped
- VMs: none reported

## Data Safety

Before and after the inventory check, the following DB counts remained unchanged:

- `user_sessions:235`
- `jobs:23`
- `job_results:6`
- `router_logs:0`
- `router_resolution_steps:0`
- `router_feedback:0`
- `workers:2`
- `worker_events:3`

No DB writes, job creation, worker activation, scheduler activation, model endpoint calls, or Ollama calls were performed.

## Runtime-Only Warning

The PVESO firewall allow rules are currently **runtime-only**:

- nft runtime allow marker: `apc-stage16e2h-ct203-pveso-inventory`
- iptables runtime allow marker: `apc-stage16e2h-ct203-pveso-inventory-pvefw-host`

These may be lost if PVESO firewall reloads or PVESO reboots. A separate explicit approval boundary is required before making the firewall allow persistent in Proxmox firewall config.

## Safety Posture

- `EDGE_POWER_EXECUTE_WAKE=false`
- CT203 controller service active
- CT204 stopped
- private storage not mounted
- no worker/model/scheduler activation
- no model/Ollama endpoint calls
