# Phase 14J-EI - Proxmox sshd Timeout Investigation Plan

PHASE_14J_EI_PROXMOX_SSHD_TIMEOUT_INVESTIGATION_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_proxmox_sshd_timeout_investigation_plan

This phase plans a guarded investigation after EH confirmed that a non-Tailscale LAN/private candidate has a local route from the controller laptop but TCP 22 times out.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=88334ea
- START_TAG=controller-phase-14j-eh-proxmox-lan-sshd-reachability-read-only-diagnostics-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## EH finding carried forward

- PROXMOX_LAN_SSHD_REACHABILITY_READ_ONLY_DIAGNOSTICS_RESULT=completed_local_route_exists_but_tcp22_timeout
- EH_NARROWED_RESULT=local_route_exists_but_tcp22_timeout
- LOCAL_ROUTE_TO_CANDIDATE_PRESENT=yes
- WIREGUARD_HOME_LINK_PRESENT_OBSERVED=yes
- TCP22_TIMEOUT_CONFIRMED=yes
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Investigation objective

PROXMOX_SSHD_TIMEOUT_INVESTIGATION_PLAN=ready

The next approved diagnostic should distinguish between these likely causes:

- PROXMOX_SSHD_SERVICE_INACTIVE_OR_BOUND_UNEXPECTEDLY=possible
- PROXMOX_HOST_FIREWALL_OR_PVE_FIREWALL_BLOCKING_TCP22=possible
- LAN_OR_VPN_ROUTE_EXISTS_BUT_RETURN_PATH_BLOCKED=possible
- CONTROLLER_WIREGUARD_HOME_INTERFACE_PRESENT_BUT_NOT_ACTIVE_FOR_ROUTE=possible
- SSHD_LISTENING_ONLY_ON_TAILSCALE_OR_DIFFERENT_INTERFACE=possible
- CANDIDATE_LAN_PATH_VALID_BUT_TCP22_FILTERED=possible

## Next diagnostic boundaries

The next diagnostic may inspect only read-only status. Any Proxmox-side inspection must be explicitly approved before execution.

Allowed in the next approved diagnostic:

- CHECK_PROXMOX_SSHD_SERVICE_STATUS_READ_ONLY=yes
- CHECK_PROXMOX_SSHD_LISTEN_SOCKETS_READ_ONLY=yes
- CHECK_PROXMOX_FIREWALL_STATUS_READ_ONLY=yes
- CHECK_PROXMOX_HOST_ROUTE_INTERFACE_SUMMARY_REDACTED=yes
- CHECK_CONTROLLER_TO_CANDIDATE_TCP22_RETEST=yes
- CHECK_NO_PRODUCTION_DB_MUTATION=yes
- CHECK_NO_JOB_MUTATION=yes
- CHECK_NO_SERVICE_ENV_MUTATION=yes
- CHECK_NO_POWER_ENDPOINT_CALL=yes
- CHECK_NO_WORKER_START=yes
- CHECK_NO_RUNTIME_ACTIVATION=yes

Disallowed unless separately approved later:

- PROXMOX_SSHD_RESTART=not_allowed
- FIREWALL_MUTATION=not_allowed
- SSH_CONFIG_MUTATION=not_allowed
- SERVICE_ENV_MUTATION=not_allowed
- POWER_ENDPOINT_CALL=not_allowed
- WORKER_START=not_allowed
- RUNTIME_ACTIVATION=not_allowed

## Privacy rules

- DO_NOT_PASTE_RAW_CANDIDATE_IN_CHAT=yes
- SET_CANDIDATE_AS_LOCAL_SHELL_VARIABLE_ONLY=yes
- HASH_ONLY_CANDIDATE_OUTPUT=yes
- REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes
- REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_SANITIZED_OUTPUT=yes

## Next phase

NEXT_PHASE_NAME=phase-14j-ej-proxmox-sshd-timeout-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-EJ Proxmox sshd timeout read-only diagnostics with sanitized output and short timeouts, using only a one-time local shell variable I provide, with Proxmox-side read-only sshd service/listener/firewall/interface checks allowed, local controller TCP 22 retest allowed, no Proxmox service restart/reload, no firewall mutation, no ssh config mutation, no power endpoint call, no worker start, no production DB mutation, no production job mutation, no controller service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no service environment mutation, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only target and host-key output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by EI

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
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

PROXMOX_SSHD_TIMEOUT_INVESTIGATION_PLAN_RESULT=ready_for_read_only_diagnostics

NEXT_SAFE_PHASE=proxmox_sshd_timeout_read_only_diagnostics_requires_approval
