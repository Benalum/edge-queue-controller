# Stage 16-E2B — PVESO Wake MAC Config Blocker, No Apply

Date: 2026-06-19
Base checkpoint: Stage 16-E1B / HEAD f339706

## Scope

Stage 16-E2B records the Stage 16-E2 wake readiness blocker.

This is a no-apply configuration discovery and blocker documentation phase.

It does not wake PVESO.

It does not call /power/execute-wake.

It does not send raw Wake-on-LAN.

It does not mutate configuration.

It does not deploy backend code.

It does not deploy frontend code.

It does not write the database.

It does not start, stop, restart, reload, enable, or disable services.

It does not start or stop CTs or VMs.

It does not activate workers.

It does not activate schedulers.

It does not call Ollama endpoints.

It does not call model endpoints.

It does not run ollama list, ollama pull, ollama run, or ollama show.

It does not start CT204.

It does not unlock or mount private storage.

## Observed blocker

Stage 16-E2A called only the dry-run wake-plan endpoint.

The wake plan returned:

- wake_plan_http=200
- wake_plan_ok=true
- wake_plan_eligible=false
- wake_plan_blocked_reason=EDGE_PROXMOX_WAKE_MAC is not configured.
- wake_plan_host_id=pveso
- wake_plan_has_mac=false
- wake_plan_has_broadcast=true
- wake_plan_port=9

Therefore PVESO wake execution is blocked until EDGE_PROXMOX_WAKE_MAC is configured.

## Required configuration

The controller needs the PVESO physical Wake-on-LAN NIC MAC address.

Required key:

EDGE_PROXMOX_WAKE_MAC

Already present enough for planning:

EDGE_PROXMOX_WAKE_BROADCAST

Wake execution also requires:

EDGE_POWER_EXECUTE_WAKE=1

But EDGE_POWER_EXECUTE_WAKE must not be enabled until the user explicitly approves the wake-config apply phase.

## Safe source for the MAC

The MAC must be the PVESO physical NIC that supports Wake-on-LAN on the LAN reachable by PVEW/CT203.

Safe ways to obtain it:

- router/gateway client list;
- PVESO BIOS/UEFI network device info;
- prior Proxmox network config backup;
- direct local console on PVESO;
- labeled NIC info if reliable.

Do not use the Tailscale virtual MAC for Wake-on-LAN.

Do not use a container MAC for host Wake-on-LAN.

Do not use VM/CT MACs for host Wake-on-LAN.

## Next phase

Stage 16-E2C should be an explicit wake-config apply phase only if the PVESO physical Wake-on-LAN MAC is known.

Suggested approval phrase:

APPROVE_STAGE_16_E2C_CONFIGURE_PVESO_WAKE_MAC_ONLY_NO_WAKE_NO_WORKER_NO_MODEL_JOB

Stage 16-E2C must:

- add EDGE_PROXMOX_WAKE_MAC only;
- optionally verify EDGE_PROXMOX_WAKE_BROADCAST and EDGE_PROXMOX_WAKE_PORT;
- not enable execute-wake unless separately approved;
- restart or reload only the controller service if required and explicitly included;
- not call /power/execute-wake;
- not start workers;
- not call Ollama;
- not create jobs;
- not start CT204;
- not unlock private storage.

After Stage 16-E2C, Stage 16-E2D can re-run /power/wake-plan.

Only if wake_plan_eligible=true should /power/execute-wake be considered.
