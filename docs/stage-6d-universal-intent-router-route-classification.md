# Stage 6D Universal Intent Router Route Classification

Stage 6D classifies the Stage 6C route inventory into migration-safe groups for the future Universal Intent Router.

This stage does not change runtime behavior.

This stage does not modify Study, Companion, Chat, Calendar, Profile, Admin, auth, queue, worker, power automation, systemd, gateway, or frontend behavior.

## Goal

Turn the Stage 6C route inventory into a first-pass classification table.

The classification table helps decide which routes can safely become Universal Intent Router candidates later.

## Source

Stage 6D uses:

- `docs/generated/stage-6c-route-inventory.txt`

Stage 6D generates:

- `docs/generated/stage-6d-route-classification.tsv`

## Classification groups

### router_candidate

Routes where user natural language or flexible commands may eventually pass through the Universal Intent Router.

Examples:

- Study intent parsing.
- Study session command input.
- Companion chat.
- Legacy queued chat.

### direct_application

Routes that should remain normal application logic.

Examples:

- Study deck/card CRUD.
- Account/profile reads.
- Credits.
- Support tickets.
- Presence heartbeats.
- Status reads.
- Health checks.

### internal_service

Routes that must remain internal service APIs.

Examples:

- Worker registration.
- Worker heartbeat.
- Queue claim/complete.
- Internal laptop queue recovery.

### admin_system

Routes that must remain guarded, explicit, and permission-checked.

Examples:

- Power wake/start/stop/shutdown.
- System boot.
- Admin user/support views.
- GPU/session control.
- Retention/admin maintenance.

### auth_security

Routes that must remain direct security flows.

Examples:

- Login.
- Logout.
- Register.
- Password reset.
- Email verification.
- Change password.
- Bootstrap admin.

## Safety classes

The route classifier uses these initial safety classes:

- `read_only`
- `user_content_write`
- `user_preference_write`
- `provider_read`
- `provider_write_confirmed`
- `admin_read`
- `admin_write_confirmed`
- `infrastructure_read`
- `infrastructure_write_confirmed`
- `internal_worker_only`
- `auth_security`
- `static_asset`

## Router migration rules

The router may classify intent for safe user-facing text routes.

The router must not directly execute high-risk routes.

The router must not directly execute:

- host shutdown
- worker stop
- container stop
- machine boot
- account/security mutation
- password changes
- admin user changes
- queue worker internals
- support/admin moderation actions
- billing/credits mutation
- deletion of user data

Those actions require explicit existing handlers, permission checks, and confirmation gates.

## Stage 6D boundaries

This stage is a classification checkpoint only.

It does not add router code.

It does not add new endpoints.

It does not change frontend routing.

It does not modify existing behavior.

## Next stage

Stage 6E should define the minimal Universal Intent Router request/response contract.

Stage 6E should still avoid runtime behavior changes unless explicitly scoped as a disabled/dry-run route.
