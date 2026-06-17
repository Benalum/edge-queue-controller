# Phase 14J-DU - SSH rc 255 Diagnostics Plan

PHASE_14J_DU_SSH_RC_255_DIAGNOSTICS_PLAN

## Scope

MUTATION_SCOPE=docs_smoke_only_ssh_rc_255_diagnostics_plan

This phase plans the next diagnostics for the SSH rc 255 result discovered in Phase 14J-DT.

No app source is mutated. No production DB rows are changed. No jobs are mutated. No service is restarted or reloaded. No controller power endpoint is called. No Proxmox SSH command is run. No worker is started. No runtime is activated. No GitHub branch or repository deletion occurred. No full systemd environment is printed.

## Starting checkpoint

- START_HEAD=f0c22fe
- START_TAG=controller-phase-14j-dt-proxmox-inventory-ssh-timeout-read-only-diagnostics-2026-06-16
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- worker_facts=2,1,1,1
- study_summary=lane,study,1,0,offline,offline
- jobs_summary=failed,1;forwarded,20;queued,1

## DT finding carried forward

- PROXMOX_INVENTORY_SSH_TIMEOUT_READ_ONLY_DIAGNOSTICS_RESULT=completed
- DT_NARROWED_ROOT_CAUSE_AREA=ssh_connection_or_auth_path_failure_before_inventory_output
- PROXMOX_INVENTORY_TIMEOUT_CAUSE_REFINED=ssh_rc_255_before_inventory_command_output
- SSH_HOST_RESOLUTION_RESULT=resolved
- TAILSCALE_BACKEND_STATE=Running
- SSH_REACHABILITY_TRUE_RC=255
- SSH_PVESH_PRESENT_RC=255
- SSH_PROXMOX_INVENTORY_RC=255
- GUARDED_WORKER_START_REMAINS_BLOCKED=yes

## Diagnosis objective

SSH_RC_255_DIAGNOSTICS_PLAN=ready_for_explicit_read_only_diagnostics

The next diagnostic phase should determine why SSH exits rc 255 before returning any Proxmox inventory output.

Possible causes to distinguish:

1. SSH target is reachable by name but the SSH daemon is unavailable.
2. Tailscale route exists but peer is offline or not accepting connections.
3. SSH authentication fails.
4. SSH host key handling fails.
5. The configured SSH target/user/key is wrong.
6. SSH errors were suppressed by LogLevel=ERROR, hiding the useful failure message.
7. The Proxmox host is online but root login or key auth is blocked.
8. A local known-hosts, identity, or permission issue is causing rc 255.

## Allowed diagnostics for next phase

The next phase may perform read-only diagnostics with short timeouts and sanitized output only:

- CHECK_REDACTED_SSH_TARGET_PRESENT=yes
- CHECK_REDACTED_TARGET_HOST_HASH=yes
- CHECK_TAILSCALE_PEER_MATCH_REDACTED=yes
- CHECK_TCP_PORT_22_REACHABILITY_SHORT_TIMEOUT=yes
- CHECK_SSH_BATCHMODE_VERBOSE_SANITIZED=yes
- CHECK_SSH_AUTH_FAILURE_CLASSIFICATION=yes
- CHECK_SSH_HOSTKEY_FAILURE_CLASSIFICATION=yes
- CHECK_SSH_TIMEOUT_FAILURE_CLASSIFICATION=yes
- CHECK_LOCAL_SSH_KEY_REFERENCED_REDACTED=yes
- CHECK_RECENT_SANITIZED_LOGS=yes

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
- REQUIRE_SANITIZED_OUTPUT=yes
- REQUIRE_NO_SECRET_PRINTING=yes
- REQUIRE_SHORT_TIMEOUTS=yes
- REQUIRE_NO_FULL_SYSTEMD_ENVIRONMENT_PRINT=yes
- REQUIRE_NO_RAW_SSH_TARGET_PRINTING=yes
- REQUIRE_NO_RAW_KEY_PATH_PRINTING=yes

## Decision

GUARDED_WORKER_START_REMAINS_BLOCKED=yes
SSH_RC_255_DIAGNOSIS_REQUIRED=yes

The guarded worker start endpoint remains blocked until SSH rc 255 is classified and a later dry-run can return a useful non-504 result.

## Next phase

NEXT_PHASE_NAME=phase-14j-dv-ssh-rc-255-read-only-diagnostics

Required approval text for the next phase:

I approve Phase 14J-DV SSH rc 255 read-only diagnostics with sanitized output and short timeouts, with no power endpoint call, no worker start, no production DB mutation, no production job mutation, no service restart/reload, no CT101 call, no model/Ollama endpoint call, no scheduler lane dispatch activation, no primary-worker filtering activation, no runtime activation, no app source mutation, no GitHub branch or repository deletion, no full systemd environment printing, no raw SSH target printing, no raw key path printing, and no rerun of the 14J-AG apply wrapper.

## Boundaries preserved by DU

- APP_SOURCE_MUTATION=not_performed
- PRODUCTION_DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- POWER_ENDPOINT_CALL=not_performed
- PROXMOX_SSH_CALL=not_performed
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

SSH_RC_255_DIAGNOSTICS_PLAN_RESULT=ready_for_explicit_read_only_diagnostics

NEXT_SAFE_PHASE=ssh_rc_255_read_only_diagnostics_requires_approval
