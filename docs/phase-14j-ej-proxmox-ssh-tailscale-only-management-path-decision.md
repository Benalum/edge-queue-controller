# Phase 14J-EJ - Proxmox SSH Tailscale-Only Management Path Decision

PHASE_14J_EJ_PROXMOX_SSH_TAILSCALE_ONLY_MANAGEMENT_PATH_DECISION

## Scope

MUTATION_SCOPE=docs_smoke_only_proxmox_ssh_tailscale_only_management_path_decision

This phase records a safety/security decision after the Proxmox LAN sshd investigation path found that the LAN candidate differs from the configured Tailscale endpoint but TCP 22 is not reachable from the controller path.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No controller service is restarted or reloaded. No Proxmox service is restarted or reloaded. No firewall is mutated. No ssh config is mutated. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=e87586b
- START_TAG=controller-phase-14j-ei-proxmox-sshd-timeout-investigation-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Carried-forward finding

- EH_RESULT=completed_local_route_exists_but_tcp22_timeout
- EI_RESULT=ready_for_read_only_diagnostics
- LAN_CANDIDATE_DIFFERED_FROM_TAILSCALE_ENDPOINT=yes
- LAN_CANDIDATE_TCP22_TIMEOUT=yes
- DIRECT_LAN_SSHD_CANDIDATE_USABLE=no
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## User security intent

USER_REPORTED_LIKELY_FIREWALL_POLICY=tailscale_only_ssh_to_reduce_local_attack_surface
SECURITY_DECISION=preserve_tailscale_only_proxmox_ssh_management
DO_NOT_OPEN_LAN_SSH_FOR_AUTOMATION=yes
DO_NOT_WEAKEN_PROXMOX_FIREWALL_FOR_THIS_PHASE=yes
DO_NOT_PURSUE_DIRECT_LAN_SSHD_AS_REQUIRED_PATH=yes

## Decision

The project will not require direct LAN/native sshd reachability for this stage. The secure management path remains the configured Tailscale SSH path.

The direct LAN/private candidate path is parked because the likely firewall/security policy intentionally blocks LAN SSH to reduce local attack surface. This avoids weakening the host firewall only to satisfy automation.

## Updated path forward

NEXT_PHASE_NAME=phase-14j-ek-configured-tailscale-proxmox-management-path-readiness-plan

The next phase should plan how to use the existing configured Tailscale Proxmox management path safely for read-only checks and later guarded operations. It should keep strict boundaries:

- USE_CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH=yes
- DO_NOT_REQUIRE_DIRECT_LAN_SSHD=yes
- DO_NOT_OPEN_LAN_FIREWALL_TCP22=yes
- DO_NOT_MUTATE_FIREWALL=yes
- DO_NOT_MUTATE_SSH_CONFIG=yes
- DO_NOT_RESTART_PROXMOX_SSHD=yes
- DO_NOT_START_WORKERS=yes
- DO_NOT_ACTIVATE_RUNTIME=yes
- REQUIRE_EXPLICIT_APPROVAL_BEFORE_ANY_OPERATIONAL_CHANGE=yes

## Boundaries preserved by EJ

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- CONTROLLER_SERVICE_RESTART_RELOAD=not_performed
- PROXMOX_SERVICE_RESTART_RELOAD=not_performed
- FIREWALL_MUTATION=not_performed
- SSH_CONFIG_MUTATION=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- WORKER_START_PERFORMED=no
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- SERVICE_ENV_MUTATION=not_performed
- PROXMOX_SSH_CALL=not_performed
- PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- HASH_ONLY_TARGET_COMPARISON=yes
- HASH_ONLY_HOSTKEY_OUTPUT=yes
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

PROXMOX_SSH_TAILSCALE_ONLY_MANAGEMENT_PATH_DECISION_RESULT=accepted

NEXT_SAFE_PHASE=configured_tailscale_proxmox_management_path_readiness_plan
