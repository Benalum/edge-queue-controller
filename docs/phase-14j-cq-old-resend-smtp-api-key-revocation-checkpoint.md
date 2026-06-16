# Phase 14J-CQ - Old Resend SMTP/API Key Revocation Checkpoint

PHASE_14J_CQ_OLD_RESEND_SMTP_API_KEY_REVOCATION_CHECKPOINT

## Scope

MUTATION_SCOPE=docs_smoke_only_manual_provider_key_revocation_checkpoint

This phase records the user's manual provider-side deletion/revocation of the old exposed Resend SMTP/API key.

No secret is printed. No secret value is recorded. No provider API call is made by this phase.

## Starting checkpoint

- START_HEAD=99c4e64
- START_TAG=controller-phase-14j-cp-post-rotation-sanitized-smtp-checkpoint-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- lane_enabled_worker_count=0

## Carried-forward CP result

- SMTP_ROTATION_RESULT=rotated_loaded_and_provider_verified
- SECRET_ROTATION=performed_interactively
- PPB_USED_FOR_SECRET_ENTRY=no
- SECRET_PRINTED=no
- SECRET_VALUE_RECORDED=no
- ACTIVE_SERVICE_LOADED_SMTP_PASSWORD=verified_by_local_terminal
- SMTP_PROVIDER_ACCEPTED_ACTIVE_CREDENTIAL=verified_by_local_terminal
- SMTP_HOST_VERIFIED=smtp.resend.com
- SMTP_USERNAME_VERIFIED=resend

## Manual revocation result

- OLD_SMTP_CREDENTIAL_REVOCATION=reported_deleted_by_user
- RESEND_OLD_API_KEY_DELETED=reported_by_user
- PROVIDER_DASHBOARD_MUTATION=performed_manually_outside_repo
- PROVIDER_API_CALL_BY_THIS_PHASE=not_performed
- OLD_EXPOSED_KEY_SHOULD_NO_LONGER_WORK=yes

## Boundaries preserved by this checkpoint

- SECRET_ROTATION_PERFORMED_BY_THIS_PHASE=not_performed
- SECRET_VALUE_RECORDED=no
- SOURCE_MUTATION=not_performed
- DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- NO_SECRETS_PRINTED=yes

## Result

SECURITY_FOLLOWUP_RESULT=smtp_credential_rotated_and_old_key_revoked

NEXT_SAFE_PHASE=gate_b1_worker_availability_metadata_plan
