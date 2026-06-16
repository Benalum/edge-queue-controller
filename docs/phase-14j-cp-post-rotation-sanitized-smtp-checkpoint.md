# Phase 14J-CP - Post-Rotation Sanitized SMTP Checkpoint

PHASE_14J_CP_POST_ROTATION_SANITIZED_SMTP_CHECKPOINT

## Scope

MUTATION_SCOPE=docs_smoke_only_post_rotation_sanitized_checkpoint

This phase records that the exposed SMTP credential was rotated outside PPB using an interactive local terminal flow, then verified without printing the secret.

No secret is printed. No secret value is recorded. PPB does not perform the rotation.

## Starting checkpoint

- START_HEAD=2ea2345
- START_TAG=controller-phase-14j-co-exposed-smtp-credential-rotation-plan-2026-06-16
- SERVICE=edge-queue-controller.service
- service_active=active
- service_enabled=enabled
- service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>
- sqlite_quick_check=ok
- lane_enabled_worker_count=0

## Rotation result

- SECRET_ROTATION=performed_interactively
- PPB_USED_FOR_SECRET_ENTRY=no
- SECRET_PRINTED=no
- SECRET_VALUE_RECORDED=no
- ACTIVE_SERVICE_LOADED_SMTP_PASSWORD=verified_by_local_terminal
- SMTP_PROVIDER_ACCEPTED_ACTIVE_CREDENTIAL=verified_by_local_terminal
- SMTP_HOST_VERIFIED=smtp.resend.com
- SMTP_USERNAME_VERIFIED=resend
- SERVICE_RESTART_RELOAD=performed_by_local_terminal_for_edge_queue_controller_only
- POST_ROTATION_SERVICE_ACTIVE=verified
- POST_ROTATION_DB_QUICK_CHECK=ok
- POST_ROTATION_LANE_FLAG_DEFAULT_OFF=verified

## Remaining manual security item

OLD_SMTP_CREDENTIAL_REVOCATION_REQUIRED=manual_provider_dashboard

The old exposed Resend SMTP/API credential should be revoked or deleted in the provider dashboard so the previously exposed value no longer works.

## Boundaries preserved by this checkpoint

- SECRET_ROTATION_PERFORMED_BY_THIS_PHASE=not_performed
- SOURCE_MUTATION=not_performed
- DB_MUTATION=not_performed
- JOB_MUTATION=not_performed
- SERVICE_RESTART_RELOAD=not_performed_by_this_phase
- CT101_CALL=not_performed
- MODEL_OLLAMA_CALL=not_performed
- SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed
- PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed
- PERSISTENT_LANE_WORKER_STARTUP=not_performed
- RUNTIME_ACTIVATION=not_performed
- NO_SECRETS_PRINTED=yes

## Result

SMTP_ROTATION_RESULT=rotated_loaded_and_provider_verified

NEXT_SAFE_PHASE=revoke_old_smtp_credential_or_gate_b1_worker_availability_metadata_plan
