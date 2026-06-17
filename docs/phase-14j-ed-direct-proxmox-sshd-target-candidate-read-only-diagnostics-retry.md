# Phase 14J-ED - Direct Proxmox sshd Target Candidate Read-Only Diagnostics Retry

PHASE_14J_ED_DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_READ_ONLY_DIAGNOSTICS_RETRY

## Scope

MUTATION_SCOPE=docs_smoke_only_direct_proxmox_sshd_target_candidate_retry_result

This phase records the approved retry of direct Proxmox sshd target candidate read-only diagnostics.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated. No service environment is mutated. No Proxmox remote command is executed. No GitHub branch or repository deletion occurred. No full systemd environment was printed. No raw SSH target or raw key path is recorded. Target comparison is hash-only.

## Approval

APPROVAL_CONFIRMED=yes

## Starting checkpoint

- START_HEAD=5d00e47
- START_TAG=controller-phase-14j-ec-direct-proxmox-sshd-candidate-selection-guidance-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Diagnostic result carried forward

- ED_DIAGNOSTICS_RESULT=completed_read_only
- ED_MUTATION_RESULT=none
- CANDIDATE_SOURCE=one_time_local_shell_variable
- CANDIDATE_PRESENT=yes
- CONFIGURED_SSH_TARGET_HASH=7d65a629e9ce
- CONFIGURED_SSH_HOST_HASH=9960b990ae47
- CANDIDATE_TARGET_HASH=9960b990ae47
- CANDIDATE_HOST_HASH=9960b990ae47
- CANDIDATE_DIFFERS_FROM_CONFIGURED_TAILSCALE_ENDPOINT=no
- CANDIDATE_STATUS=invalid_same_as_configured_tailscale_ssh_endpoint

## Interpretation

The retry candidate again resolved to the same redacted host hash as the already configured Tailscale SSH endpoint.

ED_NARROWED_RESULT=retry_candidate_is_same_configured_tailscale_ssh_endpoint
DIRECT_PROXMOX_SSHD_CANDIDATE_VALID=no
DIRECT_PROXMOX_SSHD_CANDIDATE_FOUND=no
CANDIDATE_BANNER_PROBE_PERFORMED=no
CANDIDATE_KEYSCAN_PROBE_PERFORMED=no
CANDIDATE_REJECTED_BEFORE_NETWORK_PROBE=yes
PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
SERVICE_ENV_MUTATION=not_performed
POWER_ENDPOINT_CALL=not_performed
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

A different candidate is still required. The next candidate should be a route to native Proxmox OpenSSH daemon, such as the Proxmox LAN management IP, a WireGuard/VPN management IP, or another known non-Tailscale-SSH path. The raw candidate must stay local and must not be pasted into chat.

## Safety state after diagnostics

- GIT_STATUS_AFTER=clean
- SERVICE_ACTIVE_AFTER=active
- SERVICE_ENABLED_AFTER=enabled
- SERVICE_FLAG_REMAINED_UNSET=verified
- SQLITE_QUICK_CHECK_AFTER=ok
- WORKER_FACTS_UNCHANGED=verified
- STUDY_ROW_REMAINED_ENABLED_OFFLINE=verified
- JOB_SUMMARY_UNCHANGED=verified
- PRODUCTION_STATE_UNCHANGED_AFTER_DIAGNOSTICS=verified

## Next phase

NEXT_PHASE_NAME=phase-14j-ee-direct-proxmox-sshd-candidate-discovery-plan

The next phase should be docs/smoke-only planning for discovering a valid direct Proxmox sshd candidate locally without exposing raw hosts in chat. It should not call controller power endpoints, start workers, mutate DB/jobs, call CT101, call model/Ollama, restart services, mutate service environment, execute Proxmox remote commands, or activate scheduler/primary filtering.

## Boundaries preserved by ED

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
- PROXMOX_REMOTE_COMMAND_EXECUTION=not_performed
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- HASH_ONLY_TARGET_COMPARISON=yes
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

DIRECT_PROXMOX_SSHD_TARGET_CANDIDATE_READ_ONLY_DIAGNOSTICS_RETRY_RESULT=completed_invalid_same_candidate

NEXT_SAFE_PHASE=direct_proxmox_sshd_candidate_discovery_plan
