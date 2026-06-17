# Phase 14J-DV - SSH rc 255 Read-Only Diagnostics

PHASE_14J_DV_SSH_RC_255_READ_ONLY_DIAGNOSTICS

## Scope

MUTATION_SCOPE=docs_smoke_only_ssh_rc_255_read_only_diagnostics_result

This phase records the approved read-only SSH rc 255 diagnostics.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run by this checkpoint phase. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment was printed. No raw SSH target or raw key path is recorded.

## Approval

APPROVAL_CONFIRMED=yes

## Starting checkpoint

- START_HEAD=96dbf10
- START_TAG=controller-phase-14j-du-ssh-rc-255-diagnostics-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Diagnostic results carried forward

- DV_DIAGNOSTICS_RESULT=completed_read_only
- DV_MUTATION_RESULT=none
- EDGE_PROXMOX_SSH_TARGET_PRESENT=yes
- EDGE_PROXMOX_SSH_TARGET_REDACTED_HASH=7d65a629e9ce
- EDGE_PROXMOX_SSH_USER_REDACTED_HASH=4813494d137e
- EDGE_PROXMOX_SSH_HOST_REDACTED_HASH=9960b990ae47
- EDGE_POWER_TARGET_MAP_PRESENT=yes
- EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes

## Network and Tailscale diagnostics

- SSH_HOST_RESOLUTION_RC=0
- SSH_HOST_RESOLUTION_RESULT=resolved
- SSH_HOST_RESOLUTION_LINE_COUNT=3
- TAILSCALE_STATUS_RC=0
- SSH_HOST_HASH=9960b990ae47
- TAILSCALE_BACKEND_STATE=Running
- TAILSCALE_PEER_COUNT=3
- TAILSCALE_PEER_MATCH=yes
- TAILSCALE_PEER_ONLINE=true
- TCP_22_RESULT=open
- TCP_22_RC=0
- TCP_22_DURATION_MS=28

## SSH rc 255 diagnostics

- SSH_VERBOSE_TRUE_RC=255
- SSH_VERBOSE_TRUE_STDOUT_SIZE=0
- SSH_VERBOSE_TRUE_STDERR_SIZE=7284
- SSH_VERBOSE_ERROR_CLASSIFICATIONS=timeout,host_key
- SSH_ACCEPTNEW_TRUE_RC=255
- SSH_ACCEPTNEW_TRUE_STDOUT_SIZE=0
- SSH_ACCEPTNEW_TRUE_STDERR_SIZE=6588
- SSH_ACCEPTNEW_ERROR_CLASSIFICATIONS=timeout,host_key
- SSH_G_RC=0
- SSH_G_USER_PRESENT=yes
- SSH_G_HOSTNAME_PRESENT=yes
- SSH_G_IDENTITYFILE_COUNT=7
- SSH_G_IDENTITYFILE_EXISTING_COUNT=1
- SSH_G_PROXYJUMP_PRESENT=no
- SSH_G_PROXYCOMMAND_PRESENT=no

## Interpretation

The SSH target is present without exposing it, DNS resolution succeeds, Tailscale is running, the matching Tailscale peer is online, and TCP port 22 is open. SSH still exits rc 255 during verbose read-only connection attempts.

DV_NARROWED_ROOT_CAUSE_AREA=ssh_handshake_or_host_key_or_auth_timeout_after_tcp_connect
TCP_22_REACHABLE_BUT_SSH_TRUE_FAILS=yes
TAILSCALE_PEER_ONLINE_BUT_SSH_TRUE_FAILS=yes
SSH_IDENTITY_AVAILABLE_BUT_TRUE_FAILS=yes
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

This means the previous "Proxmox inventory over SSH timeout" is now narrowed to the SSH connection path after TCP connection succeeds and before a remote command can run. The next work should classify whether this is host-key handling, SSH server behavior, authentication/key mismatch, root login policy, or SSH handshake timeout.

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

NEXT_PHASE_NAME=phase-14j-dw-ssh-handshake-or-hostkey-timeout-diagnostics-plan

The next phase should be docs/smoke-only planning for SSH handshake / host-key / auth timeout diagnostics. It should not call controller power endpoints, start workers, mutate DB/jobs, call CT101, call model/Ollama, restart services, or activate scheduler/primary filtering.

## Boundaries preserved by DV

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
- GITHUB_BRANCH_OR_REPO_DELETE=not_performed
- FULL_SYSTEMD_ENVIRONMENT_PRINTING=not_performed
- RAW_SSH_TARGET_PRINTING=not_performed
- RAW_KEY_PATH_PRINTING=not_performed
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

SSH_RC_255_READ_ONLY_DIAGNOSTICS_RESULT=completed

NEXT_SAFE_PHASE=ssh_handshake_or_hostkey_timeout_diagnostics_plan
