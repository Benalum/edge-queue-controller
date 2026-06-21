# Stage 16-E2V — Durable PVESO Inventory Bridge Results

Date: 2026-06-20

## Purpose

Record the completed Stage 16-E2T/E2U recovery work that made the CT203 → PVESO inventory path durable enough to survive a PVESO firewall reload.

This is a repo documentation checkpoint only. It does not mutate live infrastructure.

## Result Summary

The CT203 → PVESO inventory bridge is now persistent and reload-validated.

The path now depends on:

1. CT203 persistent secondary LAN IP service.
2. PVESO persistent firewall config for CT203 secondary source to tcp/22.
3. CT203 controller env pointing `EDGE_PROXMOX_SSH_TARGET` at PVESO’s reachable LAN address.

## E2T Result

Stage 16-E2T initially partially succeeded:

- CT203 secondary IP service was installed.
- CT203 secondary IP service was enabled.
- CT203 secondary IP service was active.
- CT203 persistent secondary IP was present.
- CT203 primary IP/gateway was not changed.
- PVESO nft persistent file rule was written.
- PVESO host.fw persistence initially failed because the host.fw rule shape was a two-line comment + rule pattern.

Stage 16-E2T-R1 inspected the partial state:

- CT203 secondary IP service enabled/active.
- CT203 secondary IP present.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 `/power/proxmox/inventory` HTTP 200.
- inventory `ok=true`.
- inventory `host_id=pveso`.
- CT101 stopped: `llms`.
- CT201 stopped: `edge-data`.
- CT202 stopped: `edge-controller`.
- DB counts unchanged.
- PVESO nft persistent file marker present.
- PVESO host.fw persistent file marker absent at that moment.
- runtime temporary nft marker still present at that moment.

Stage 16-E2T-R2 completed host.fw persistence:

- PVESO host.fw backup created.
- PVESO host.fw persistent marker written.
- PVESO host.fw persistent rule written.
- PVESO nft persistent marker confirmed.
- No firewall reload was performed during E2T-R2.
- CT203 inventory remained HTTP 200 and `ok=true`.
- CT101/CT201/CT202 remained stopped.
- DB counts remained unchanged.

## E2U Result

Stage 16-E2U performed controlled PVESO firewall reload validation.

E2U verified before reload:

- CT203 secondary IP service enabled/active.
- CT203 secondary IP present.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 `/power/proxmox/inventory` HTTP 200.
- DB counts unchanged.
- CT101 stopped.
- CT201 stopped.
- CT202 stopped.
- CT101 onboot=0.
- PVESO nft persistent file marker present.
- PVESO host.fw persistent file marker present.
- PVESO host.fw persistent file rule present.

E2U performed:

- PVESO firewall reload/restart only.
- activation of the persistent nft marker in runtime when reload did not materialize it automatically.
- cleanup of old runtime temporary firewall markers after persistent path validation.

E2U verified after reload:

- PVESO firewall status: enabled/running.
- runtime nft temporary marker: false.
- runtime nft persistent marker: true.
- runtime pvefw temporary marker: false.
- CT203 secondary IP service enabled/active.
- CT203 secondary IP present.
- CT203 bound tcp/22 to PVESO after reload: ok.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 `/power/proxmox/inventory` HTTP 200.
- inventory `ok=true`.
- inventory `host_id=pveso`.
- CT101 stopped: `llms`.
- CT201 stopped: `edge-data`.
- CT202 stopped: `edge-controller`.
- DB counts unchanged.

## Current Safety State

Current live posture after E2U:

- PVEW running.
- VM200 running.
- CT203 running.
- CT204 stopped.
- CT101 stopped.
- CT201 stopped.
- CT202 stopped.
- private storage not mounted.
- CT203 controller active.
- CT203 inventory to PVESO recovered.
- no CT/VM start/stop/restart occurred during E2U.
- no CT203 controller env mutation occurred during E2U.
- no CT203 controller service restart/reload occurred during E2U.
- no VM200 nginx mutation.
- no Cloudflare/DNS/tunnel mutation.
- no DB write.
- no worker/model/scheduler activation.
- no Ollama/model endpoint calls.

## Remaining Risk

The inventory bridge is now reload-proven for PVESO firewall reload, but CT101 itself still has legacy autostart/legacy-service risks from the earlier E2L start attempt.

The earlier CT101 start surfaced legacy active services including Docker/containerd, docker-proxy on 11434, Ollama serve, legacy worker agent, local queue controller, uvicorn services, and whisper-asr web service.

Therefore CT101 must not be started again until a separate legacy-autostart neutralization plan is prepared and explicitly approved.

## Recommended Next Phase

Proceed to:

**Stage 16-E2W — CT101 legacy-autostart neutralization plan no-apply**

E2W should be documentation/readiness only and should plan how to start CT101 safely without allowing legacy Docker/Ollama/worker/web services to register, call models, write DB rows, or expose unintended ports.

## Hard Rule

Do not start CT101 again until the CT101 legacy-autostart neutralization plan is complete and separately approved.
