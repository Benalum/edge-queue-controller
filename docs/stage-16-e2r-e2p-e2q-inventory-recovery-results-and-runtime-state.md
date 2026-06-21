# Stage 16-E2R — E2P/E2Q Inventory Recovery Results and Runtime State

Date: 2026-06-20

## Purpose

Record the successful recovery of CT203 → PVESO inventory after Stage 16-E2P-R3 and Stage 16-E2Q.

This is a repo documentation checkpoint only. It does not mutate live infrastructure.

## Result Summary

Stage 16-E2P-R3 succeeded.

It proved:

- temporary CT203 secondary LAN IP was added at runtime
- temporary PVESO firewall allow was added at runtime
- CT203 could reach PVESO tcp/22
- CT203 forced-command SSH to PVESO worked
- PVESO inventory returned:
  - CT101 stopped: `llms`
  - CT201 stopped: `edge-data`
  - CT202 stopped: `edge-controller`
- no persistent CT203 network config was changed
- no persistent PVESO firewall config was changed
- no controller env was changed during E2P-R3
- no service restart happened during E2P-R3
- no DB write happened
- no worker/model/scheduler activation happened

Stage 16-E2Q succeeded.

It changed only:

- CT203 `EDGE_PROXMOX_SSH_TARGET` to PVESO’s current reachable LAN address
- CT203 `edge-queue-controller.service` was restarted

E2Q verified:

- CT203 controller active after restart
- CT203 `/health`: HTTP 200
- CT203 `/system/status`: HTTP 200
- CT203 `/power/proxmox/inventory`: HTTP 200
- inventory `ok=true`
- inventory `host_id=pveso`
- inventory containers count: 3
- CT101 stopped: `llms`
- CT201 stopped: `edge-data`
- CT202 stopped: `edge-controller`
- DB counts unchanged
- private storage not mounted
- CT204 stopped
- no CT/VM start/stop/restart
- no DB write
- no worker/model/scheduler activation
- no Ollama/model endpoint calls

## Current Live Runtime Dependency

The inventory path is currently dependent on runtime-only network/firewall state:

1. temporary CT203 secondary IP on `eth0`
2. temporary PVESO firewall allow for that secondary source

Those runtime changes were intentionally not persisted.

If CT203 restarts, loses networking, or PVESO firewall reloads/reboots, CT203 → PVESO inventory may fail again unless the runtime path is made persistent or replaced by a cleaner persistent repair.

## Current Persistent State

Persistent state changed by E2Q:

- CT203 controller env now points `EDGE_PROXMOX_SSH_TARGET` to PVESO’s current reachable LAN address.

Persistent state not changed by E2P/E2Q:

- CT203 Proxmox/LXC network config
- PVESO firewall config files
- VM200 nginx
- Cloudflare/DNS/tunnel config
- CT101/CT201/CT202/CT204 state
- database contents
- worker registry activation
- scheduler activation
- model/Ollama endpoints

## Risk

The platform is functional after E2Q, but inventory recovery is only durable while the temporary runtime network/firewall bridge remains alive.

This should not be left undocumented or forgotten.

## Recommended Next Phase

Stage 16-E2S should create a no-apply persistence/cleanup decision plan.

Options:

### Option A — Persist the temporary bridge narrowly

Persist CT203 secondary LAN IP and PVESO firewall allow in minimal config.

Benefits:

- keeps inventory working across reboot/reload
- low change from proven working state

Risks:

- adds cross-LAN transitional config
- still needs careful cleanup later when network is fully realigned

### Option B — Clean up temporary bridge and defer PVESO inventory

Remove runtime CT203 secondary IP and PVESO firewall allow.

Benefits:

- avoids hidden runtime dependency

Risks:

- CT203 inventory will fail again because env now points to a currently unreachable LAN path
- would require reverting env target or accepting inventory outage

### Option C — Full network realignment

Move CT203 primary network to PVEW/PVESO LAN and update VM200/public upstreams if needed.

Benefits:

- long-term clean architecture

Risks:

- higher public-route/controller blast radius
- needs a separate maintenance plan

## Current Recommendation

Do not start CT101 yet.

Next safest step:

**Stage 16-E2S — runtime bridge persistence versus cleanup decision plan no-apply**

After that, choose one explicit approval boundary:

- persist the bridge narrowly, or
- clean it up and accept/revert inventory, or
- plan full CT203 network realignment.
