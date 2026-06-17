# Phase 14J-EG - Proxmox LAN sshd Reachability Plan

PHASE_14J_EG_PROXMOX_LAN_SSHD_REACHABILITY_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_proxmox_lan_sshd_reachability_plan

This phase plans read-only controller-to-Proxmox LAN or VPN sshd reachability checks after EF found a candidate that differed from the Tailscale SSH endpoint but was not reachable on TCP 22 from the controller laptop.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox SSH command is run. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=30e743a
- START_TAG=controller-phase-14j-ef-direct-proxmox-sshd-candidate-read-only-diagnostics-second-retry-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## EF finding carried forward

- DIRECT_PROXMOX_SSHD_CANDIDATE_READ_ONLY_DIAGNOSTICS_SECOND_RETRY_RESULT=completed_candidate_differs_but_tcp22_unreachable
- EF_NARROWED_RESULT=direct_candidate_differs_but_tcp22_unreachable_from_controller
- DIRECT_PROXMOX_SSHD_CANDIDATE_DIFFERENT_FROM_TAILSCALE_ENDPOINT=yes
- CANDIDATE_TCP22_RESULT=connect_timeout
- CANDIDATE_STATUS=candidate_not_reachable_on_tcp22
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Reachability objective

PROXMOX_LAN_SSHD_REACHABILITY_PLAN=ready

The candidate route appears to be a native LAN or private-network Proxmox host path, but TCP 22 timed out from the controller laptop. The next approved diagnostic should determine whether the controller can route to the candidate network and whether TCP 22 is blocked, unreachable, or simply off-path.

## Local read-only checks allowed in next diagnostic

The next approved diagnostic may perform only local controller-side checks and sanitized target probes:

- CHECK_LOCAL_CONTROLLER_ROUTE_TO_CANDIDATE_HASH_ONLY=yes
- CHECK_LOCAL_INTERFACE_SUMMARY_REDACTED=yes
- CHECK_LOCAL_DEFAULT_ROUTE_SUMMARY_REDACTED=yes
- CHECK_WIREGUARD_HOME_INTERFACE_STATUS_REDACTED=yes
- CHECK_TAILSCALE_STATUS_REDACTED=yes
- CHECK_CANDIDATE_TCP22_BANNER_HASH_ONLY=yes
- CHECK_CANDIDATE_KEYSCAN_HASH_ONLY=yes
- CHECK_NO_REMOTE_COMMAND_EXECUTION=yes
- CHECK_NO_SERVICE_ENV_MUTATION=yes
- CHECK_NO_POWER_ENDPOINT_CALL=yes

## Candidate privacy rules

- DO_NOT_PASTE_RAW_CANDIDATE_IN_CHAT=yes
- SET_CANDIDATE_AS_LOCAL_SHELL_VARIABLE_ONLY=yes
- HASH_ONLY_CANDIDATE_OUTPUT=yes
- REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes
- REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_SANITIZED_OUTPUT=yes

## Likely causes to distinguish

- CONTROLLER_NOT_ON_HOME_LAN_OR_VPN=possible
- HOME_WIREGUARD_NOT_UP_OR_NOT_ROUTING=possible
- LAN_ROUTE_MISSING_FROM_CONTROLLER=possible
- HOST_FIREWALL_OR_NETWORK_FILTERING_TCP22=possible
- PROXMOX_SSHD_BOUND_TO_DIFFERENT_INTERFACE=possible
- WRONG_PRIVATE_NETWORK_PATH=possible
- TAILSCALE_SSH_ENDPOINT_STILL_SEPARATE_FROM_NATIVE_SSHD=confirmed_context

## Next phase

NEXT_PHASE_NAME=phase-14j-eh-proxmox-lan-sshd-reachability-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-EH Proxmox LAN sshd reachability read-only diagnostics with sanitized output and short timeouts, using only a one-time local shell variable I provide, with local controller-side route/interface/VPN status checks allowed, TCP 22 banner/keyscan probes allowed, no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no service environment mutation, no Proxmox remote command execution, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only target and host-key output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by EG

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

PROXMOX_LAN_SSHD_REACHABILITY_PLAN_RESULT=ready_for_read_only_diagnostics

NEXT_SAFE_PHASE=proxmox_lan_sshd_reachability_read_only_diagnostics_requires_approval
