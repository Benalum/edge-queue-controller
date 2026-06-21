# Stage 16-E2S — Runtime Bridge Persistence vs Cleanup Decision Plan No-Apply

Date: 2026-06-20

## Purpose

Decide the next safe path after E2P-R3 and E2Q restored CT203 → PVESO inventory using a runtime-only bridge.

This is a **no-apply** documentation checkpoint. It does not mutate live infrastructure.

## Current Known State

From E2P-R3 and E2Q:

- CT203 → PVESO tcp/22 works.
- CT203 forced-command SSH to PVESO works.
- CT203 `/power/proxmox/inventory` returned HTTP 200.
- inventory `ok=true`.
- inventory `host_id=pveso`.
- CT101 stopped: `llms`.
- CT201 stopped: `edge-data`.
- CT202 stopped: `edge-controller`.
- CT203 controller service is active after E2Q restart.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 DB counts unchanged.
- CT204 stopped.
- private storage not mounted.
- no worker/model/scheduler activation occurred.
- no Ollama/model endpoint calls occurred.

## Current Runtime-Only Dependency

The recovered inventory path currently depends on two runtime-only changes:

1. CT203 has a temporary secondary IPv4 address on `eth0` in the PVEW/PVESO LAN.
2. PVESO has temporary runtime firewall allows for that CT203 secondary source to tcp/22.

E2Q changed persistent CT203 controller env so `EDGE_PROXMOX_SSH_TARGET` points to PVESO’s current reachable LAN address.

That means the controller env is now persistent, but the network/firewall path that makes it reachable is not yet persistent.

## Risk If We Pause Without Persisting or Cleaning Up

If CT203 networking resets, CT203 restarts, PVESO reboots, or PVESO firewall reloads:

- the temporary CT203 secondary IP may disappear;
- the temporary PVESO firewall allow may disappear;
- CT203 inventory may fail again;
- CT203 env may still point to the PVESO LAN address, producing a new `No route to host` or timeout state.

Therefore the current state should not be left as an undocumented long-term runtime dependency.

## Options

### Option A — Persist the proven bridge narrowly

Persist the exact architecture proven by E2P-R3/E2Q:

- add CT203 secondary LAN IP persistently while retaining the current primary IP/gateway;
- add PVESO firewall allow persistently for that CT203 secondary source to tcp/22;
- keep CT203 `EDGE_PROXMOX_SSH_TARGET` pointed at PVESO current LAN address;
- verify inventory remains HTTP 200;
- leave CT101 stopped.

Benefits:

- smallest change from a proven working runtime path;
- inventory remains durable across reboot/firewall reload;
- avoids changing CT203 primary IP;
- avoids changing VM200 nginx;
- avoids Cloudflare/DNS/tunnel changes;
- avoids full public-route cutover risk.

Risks:

- introduces transitional cross-subnet configuration;
- needs later cleanup when CT203 primary LAN is fully realigned;
- must ensure no duplicate IP and no overly broad firewall rule.

Status: **recommended next apply path**.

### Option B — Clean up runtime bridge and revert env target

Remove the temporary CT203 secondary IP, remove temporary PVESO firewall allows, and restore CT203 `EDGE_PROXMOX_SSH_TARGET` to the previous target or accept inventory outage.

Benefits:

- avoids hidden runtime dependency.

Risks:

- loses recovered PVESO inventory path;
- delays CT101 worker/model work;
- likely returns inventory to HTTP 502.

Status: safe only if pausing Stage 16 or abandoning PVESO inventory for now.

### Option C — Full CT203 primary network realignment

Move CT203 primary IP/gateway to the PVEW/PVESO LAN and update dependent upstreams.

Benefits:

- cleaner long-term topology.

Risks:

- highest blast radius;
- may disrupt VM200 → CT203 public/API route;
- likely requires VM200 nginx and route validation work;
- should be treated as a separate maintenance phase.

Status: not recommended as the immediate next step.

## Recommended Next Phase

Proceed with **Option A**.

Next phase:

**Stage 16-E2T — Persist CT203 secondary LAN IP and PVESO firewall allow**

Future approval phrase:

`APPROVE_STAGE_16_E2T_PERSIST_CT203_SECONDARY_LAN_IP_AND_PVESO_FIREWALL_ALLOW_FOR_INVENTORY_ONLY_NO_PUBLIC_ROUTE_CUTOVER_NO_DB_WRITE`

E2T should allow only:

- persist CT203 secondary LAN address while keeping existing CT203 primary IP/gateway;
- persist PVESO firewall allow for that CT203 secondary source to tcp/22;
- reload only what is required for those persistent network/firewall rules;
- verify CT203 health/status;
- verify CT203 `/power/proxmox/inventory` HTTP 200;
- verify DB counts unchanged;
- verify CT101/CT201/CT202 remain stopped;
- verify CT204 remains stopped;
- verify private storage remains not mounted.

E2T must forbid:

- CT101 start;
- CT201/CT202 start;
- CT204 start;
- CT203 primary IP/gateway change;
- VM200 nginx mutation;
- Cloudflare/DNS/tunnel mutation;
- DB writes;
- worker registration;
- scheduler activation;
- model jobs;
- Ollama/model endpoint calls;
- private-storage mount/unlock.

## Post-E2T Plan

If E2T succeeds:

1. document the durable inventory path;
2. run a read-only inventory verification;
3. proceed to CT101 legacy-autostart neutralization planning before starting CT101 again.

If E2T fails:

1. roll back the persistent CT203 secondary IP;
2. roll back persistent PVESO firewall allow;
3. leave CT101 stopped;
4. reassess full network realignment.

## Hard Rule

Do not start CT101 again until the CT203 → PVESO inventory path is durable and CT101 legacy-autostart behavior has a separate safety plan.
