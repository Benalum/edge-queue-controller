# Phase 14J-DT - Proxmox Inventory SSH Timeout Read-Only Diagnostics

PHASE_14J_DT_PROXMOX_INVENTORY_SSH_TIMEOUT_READ_ONLY_DIAGNOSTICS

## Scope

MUTATION_SCOPE=docs_smoke_only_proxmox_inventory_ssh_timeout_read_only_diagnostics_result

This phase records the approved read-only diagnostics for the Proxmox inventory SSH timeout that caused the Phase 14J-DN dry-run HTTP 504.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment was printed.

## Approval

APPROVAL_CONFIRMED=yes

## Starting checkpoint

- START_HEAD=b1a82b6
- START_TAG=controller-phase-14j-ds-proxmox-inventory-ssh-timeout-diagnostics-plan-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## Diagnostic results

- DT_DIAGNOSTICS_RESULT=completed_read_only
- DT_MUTATION_RESULT=none
- EDGE_PROXMOX_SSH_TARGET_PRESENT=yes
- EDGE_PROXMOX_SSH_TARGET_REDACTED_HASH=7d65a629e9ce
- EDGE_POWER_TARGET_MAP_PRESENT=yes
- EDGE_POWER_TARGET_MAP_MENTIONS_LLMS_OLLAMA=yes
- EDGE_POWER_TARGET_MAP_REDACTED_HASH=9bb81488e90b
- SSH_HOST_RESOLUTION_RC=0
- SSH_HOST_RESOLUTION_RESULT=resolved
- SSH_HOST_RESOLUTION_LINE_COUNT=3
- TAILSCALE_STATUS_RC=0
- TAILSCALE_BACKEND_STATE=Running
- TAILSCALE_PEER_COUNT=3
- SSH_REACHABILITY_TRUE_RC=255
- SSH_REACHABILITY_TRUE_DURATION_MS=2991
- SSH_REACHABILITY_TRUE_STDOUT_SIZE=0
- SSH_REACHABILITY_TRUE_STDERR_SIZE=0
- SSH_PVESH_PRESENT_RC=255
- SSH_PVESH_PRESENT_DURATION_MS=2196
- SSH_PVESH_PRESENT_STDOUT_SIZE=0
- SSH_PVESH_PRESENT_STDERR_SIZE=0
- SSH_PROXMOX_INVENTORY_RC=255
- SSH_PROXMOX_INVENTORY_DURATION_MS=2214
- SSH_PROXMOX_INVENTORY_STDOUT_SIZE=0
- SSH_PROXMOX_INVENTORY_STDERR_SIZE=0
- INVENTORY_OUTPUT_JSON_ATTEMPTED=yes
- INVENTORY_OUTPUT_SIZE=0
- INVENTORY_JSON_PARSE_RESULT=failed
- INVENTORY_JSON_PARSE_ERROR=JSONDecodeError
- TARGET_MAP_LLMS_OLLAMA_MAPPING_PRESENT=yes
- TARGET_MAP_LLMS_OLLAMA_KIND=ct
- TARGET_MAP_LLMS_OLLAMA_VMID_PRESENT=yes

## Source path result

- POWER_START_WORKER_PLAN_FOUND=yes
- POWER_START_WORKER_PLAN_USES_EDGE_PROXMOX_SSH_TARGET=yes
- POWER_START_WORKER_PLAN_USES_PVESH_INVENTORY=no
- POWER_START_WORKER_PLAN_HAS_HTTP_EXCEPTION_TIMEOUT_TEXT=no
- POWER_START_WORKER_PLAN_HAS_INTERNAL_TIMEOUT_12=no
- POWER_START_WORKER_PLAN_DECLARES_DRY_RUN_NO_START=yes

## Interpretation

The target configuration is present, the host name resolves, and Tailscale is running. However, short-timeout SSH checks fail with rc 255 and no output before any Proxmox inventory JSON is returned.

DT_NARROWED_ROOT_CAUSE_AREA=ssh_connection_or_auth_path_failure_before_inventory_output
PROXMOX_INVENTORY_TIMEOUT_CAUSE_REFINED=ssh_rc_255_before_inventory_command_output
GUARDED_WORKER_START_REMAINS_BLOCKED=yes

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

NEXT_PHASE_NAME=phase-14j-du-ssh-rc-255-diagnostics-plan

The next phase should be docs/smoke-only planning for SSH rc 255 diagnostics. It should determine whether the failure is SSH auth, host key handling, wrong Tailscale target, inactive Proxmox SSH, unreachable target, or suppressed SSH error output. It should not call power endpoints, start workers, mutate DB/jobs, call CT101, call model/Ollama, restart services, or activate scheduler/primary filtering.

## Boundaries preserved by DT

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
- DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved
- NO_SECRETS_PRINTED=yes

## Result

PROXMOX_INVENTORY_SSH_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed

NEXT_SAFE_PHASE=ssh_rc_255_diagnostics_plan
