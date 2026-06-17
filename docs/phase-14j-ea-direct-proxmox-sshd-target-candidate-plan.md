# Phase 14J-EA - Direct Proxmox sshd Target Candidate Plan

PHASE_14J_EA_DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_direct_proxmox_sshd_target_candidate_plan

This phase plans a safe way to identify a direct Proxmox OpenSSH daemon target for noninteractive controller automation.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run. No Proxmox remote command is executed. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment is printed. No raw SSH target or raw key path is printed.

## Starting checkpoint

- START_HEAD=0f33fc9
- START_TAG=controller-phase-14j-dz-tailscale-ssh-vs-proxmox-sshd-target-read-only-diagnostics-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DZ finding carried forward

- TAILSCALE_SSH_VS_PROXMOX_SSHD_TARGET_READ_ONLY_DIAGNOSTICS_RESULT=completed
- DZ_NARROWED_ROOT_CAUSE_AREA=configured_target_is_tailscale_ssh_endpoint_no_direct_proxmox_sshd_candidate_present
- CONFIGURED_TARGET_VENDOR=Tailscale
- EDGE_PROXMOX_HOST_SAME_AS_CONFIGURED_SSH_HOST=yes
- DIRECT_PROXMOX_SSHD_CANDIDATE_PRESENT=no
- TAILSCALE_SSH_BATCHMODE_NOT_SUITABLE_FOR_CONTROLLER_AUTOMATION=yes
- PREFERRED_TARGET_FOR_NONINTERACTIVE_CONTROLLER_AUTOMATION=direct_proxmox_sshd_if_available
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Planning objective

DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_PLAN=ready_for_explicit_candidate_selection

The configured target is currently a Tailscale SSH endpoint, and no separate direct Proxmox sshd candidate is present in the controller environment.

The next safe work should identify a candidate that is not the Tailscale SSH endpoint and verify only its TCP banner and host-key fingerprints before any environment change or power endpoint retry.

## Candidate requirements

A direct Proxmox sshd candidate must satisfy all of these before any runtime use:

- CANDIDATE_MUST_NOT_MATCH_CONFIGURED_TAILSCALE_SSH_TARGET_HASH=yes
- CANDIDATE_EXPECTED_BANNER_VENDOR=OpenSSH_or_other_non_Tailscale_sshd
- CANDIDATE_MUST_SUPPORT_SSH_KEYSCAN_HASH_ONLY=yes
- CANDIDATE_MUST_NOT_PRINT_RAW_HOST_OR_TARGET=yes
- CANDIDATE_MUST_NOT_PRINT_RAW_KEY_PATH=yes
- CANDIDATE_MUST_NOT_EXECUTE_REMOTE_COMMAND_IN_FIRST_CANDIDATE_CHECK=yes
- CANDIDATE_MUST_NOT_MUTATE_SERVICE_ENV_IN_FIRST_CANDIDATE_CHECK=yes
- CANDIDATE_MUST_NOT_CALL_POWER_ENDPOINT_IN_FIRST_CANDIDATE_CHECK=yes

## Allowed diagnostics for next phase

The next phase may perform read-only, sanitized, short-timeout diagnostics only:

- CHECK_ONE_TIME_DIRECT_PROXMOX_SSHD_CANDIDATE_IF_PROVIDED=yes
- CHECK_CONFIGURED_ENV_TARGET_HASH_ONLY=yes
- CHECK_CANDIDATE_TARGET_HASH_ONLY=yes
- CHECK_CANDIDATE_TCP_22_BANNER_VENDOR=yes
- CHECK_CANDIDATE_SSH_KEYSCAN_HASH_ONLY=yes
- CHECK_CANDIDATE_DIFFERS_FROM_TAILSCALE_SSH_ENDPOINT=yes
- CHECK_NO_RAW_SSH_TARGET_OR_KEY_PATH_OUTPUT=yes
- CHECK_NO_FULL_SYSTEMD_ENVIRONMENT_OUTPUT=yes

## Strict blocks for next phase

- ALLOW_POWER_ENDPOINT_CALL=no
- ALLOW_EXECUTE_POWER_ENDPOINT_CALL=no
- ALLOW_WORKER_START=no
- ALLOW_PRODUCTION_DB_MUTATION=no
- ALLOW_PRODUCTION_JOB_MUTATION=no
- ALLOW_SERVICE_RESTART_RELOAD=no
- ALLOW_CT101_CALL=no
- ALLOW_MODEL_OLLAMA_CALL=no
- ALLOW_SCHEDULER_LANE_DISPATCH_ACTIVATION=no
- ALLOW_PRIMARY_WORKER_FILTERING_ACTIVATION=no
- ALLOW_RUNTIME_ACTIVATION=no
- ALLOW_APP_SOURCE_MUTATION=no
- ALLOW_GITHUB_BRANCH_OR_REPO_DELETE=no
- ALLOW_PROXMOX_REMOTE_COMMAND_EXECUTION=no
- ALLOW_SERVICE_ENV_MUTATION=no
- ALLOW_RAW_SECRET_OR_TARGET_OUTPUT=no
- REQUIRE_SANITIZED_OUTPUT=yes
- REQUIRE_NO_SECRET_PRINTING=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
- REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes
- REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes
- REQUIRE_HASH_ONLY_HOSTKEY_OUTPUT=yes

## Decision

GUARDED_WORKER_START_REMAINS_BLOCKED=yes
DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_REQUIRED=yes

The guarded worker start path remains blocked until a direct Proxmox sshd candidate is identified, verified read-only, then later applied through a separately approved service environment change and dry-run.

## Next phase

NEXT_PHASE_NAME=phase-14j-eb-direct-proxmox-sshd-target-candidate-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-EB direct Proxmox sshd target candidate read-only diagnostics with sanitized output and short timeouts, using only a redacted candidate source already present or a one-time local shell variable I provide, with no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no service environment mutation, no Proxmox remote command execution, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, hash-only host-key output, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by EA

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- PROXMOX_SSH_CALL=not_performed
- PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
- WORKER_START_PERFORMED=no
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_PLAN_RESULT=ready_for_explicit_candidate_selection

NEXT_SAFE_PHASE=direct_proxmox_sshd_target_candidate_read_only_diagnostics_requires_approval
