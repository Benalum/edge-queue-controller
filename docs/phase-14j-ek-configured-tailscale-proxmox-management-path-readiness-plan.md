# Phase 14J-EK - Configured Tailscale Proxmox Management Path Readiness Plan

PHASE_14J_EK_CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READINESS_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_configured_tailscale_proxmox_management_path_readiness_plan

This phase plans safe use of the already configured Tailscale Proxmox management path after the project accepted the Tailscale-only SSH security decision.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No controller service is restarted or reloaded. No Proxmox service is restarted or reloaded. No firewall is mutated. No ssh config is mutated. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=d25296f
- START_TAG=controller-phase-14j-ej-proxmox-ssh-tailscale-only-management-path-decision-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Carried-forward decision

- EJ_DECISION_RESULT=accepted
- SECURITY_DECISION=preserve_tailscale_only_proxmox_ssh_management
- USE_CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH=yes
- DIRECT_LAN_SSHD_CANDIDATE_USABLE=no
- DO_NOT_REQUIRE_DIRECT_LAN_SSHD=yes
- DO_NOT_OPEN_LAN_FIREWALL_TCP22=yes
- DO_NOT_WEAKEN_PROXMOX_FIREWALL_FOR_AUTOMATION=yes
- DO_NOT_PURSUE_DIRECT_LAN_SSHD_AS_REQUIRED_PATH=yes
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Readiness objective

CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READINESS_PLAN=ready

The next approved diagnostic should verify the configured Tailscale Proxmox SSH target is usable for **read-only** management checks without exposing raw target values or secrets.

## Next diagnostic boundaries

Allowed in the next approved diagnostic:

- CHECK_CONFIGURED_PROXMOX_SSH_TARGET_PRESENT_HASH_ONLY=yes
- CHECK_CONFIGURED_PROXMOX_SSH_TARGET_REACHABLE_READ_ONLY=yes
- CHECK_PROXMOX_IDENTITY_READ_ONLY_HASH_ONLY=yes
- CHECK_PROXMOX_NODE_STATUS_READ_ONLY_SANITIZED=yes
- CHECK_PROXMOX_VM_CT_INVENTORY_READ_ONLY_SANITIZED=yes
- CHECK_NO_PRODUCTION_DB_MUTATION=yes
- CHECK_NO_JOB_MUTATION=yes
- CHECK_NO_SERVICE_ENV_MUTATION=yes
- CHECK_NO_POWER_ENDPOINT_CALL=yes
- CHECK_NO_WORKER_START=yes
- CHECK_NO_RUNTIME_ACTIVATION=yes

Disallowed unless separately approved later:

- PROXMOX_SERVICE_RESTART_RELOAD=not_allowed
- FIREWALL_MUTATION=not_allowed
- SSH_CONFIG_MUTATION=not_allowed
- LAN_FIREWALL_TCP22_OPEN=not_allowed
- SERVICE_ENV_MUTATION=not_allowed
- POWER_ENDPOINT_CALL=not_allowed
- WORKER_START=not_allowed
- RUNTIME_ACTIVATION=not_allowed

## Privacy rules

- NO_RAW_CONFIGURED_SSH_TARGET_PRINTING=yes
- HASH_ONLY_CONFIGURED_TARGET_OUTPUT=yes
- REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_SANITIZED_OUTPUT=yes
- NO_SECRETS_PRINTED=yes

## Next phase

NEXT_PHASE_NAME=phase-14j-el-configured-tailscale-proxmox-management-path-read-only-readiness-diagnostics

Required approval text for the next phase:

I approve Phase 14J-EL configured Tailscale Proxmox management path read-only readiness diagnostics with sanitized output and short timeouts, using only the already configured Proxmox SSH target from the controller service environment, with configured target presence/hash checks allowed, Proxmox identity/node status/VM-CT inventory read-only checks allowed, no Proxmox service restart/reload, no firewall mutation, no ssh config mutation, no LAN firewall TCP22 opening, no power endpoint call, no worker start, no production DB mutation, no production job mutation, no controller service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no service environment mutation, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only target output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by EK

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- CONTROLLER_SERVICE_RESTART_RELOAD=not_performed
- PROXMOX_SERVICE_RESTART_RELOAD=not_performed
- FIREWALL_MUTATION=not_performed
- SSH_CONFIG_MUTATION=not_performed
- LAN_FIREWALL_TCP22_OPEN=not_performed
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
- HASH_ONLY_TARGET_OUTPUT=yes
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

CONFIGURED_TAILSCALE_PROXMOX_MANAGEMENT_PATH_READINESS_PLAN_RESULT=ready_for_read_only_diagnostics

NEXT_SAFE_PHASE=configured_tailscale_proxmox_management_path_read_only_readiness_diagnostics_requires_approval
