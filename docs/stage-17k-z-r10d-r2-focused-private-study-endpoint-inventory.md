# Stage 17K-Z-R10D-R2 — Focused Private Study Endpoint Inventory

This checkpoint replaces the noisy uncommitted R10D scan with a focused source inventory.

## Purpose

Before disabling or removing backend endpoints, identify which frontend and backend paths touch private study content.

## Safety

This stage does not disable endpoints and does not change runtime behavior.

No deploy, DB write, schema change, service restart, endpoint removal, endpoint disable, backend storage change, Anki file mutation, Google OAuth, Google Drive API, email send, or signup opening occurred.

## Policy direction

Private study data should move to browser-local storage:

- private APC-native decks
- private APC-native cards
- notes
- note types
- templates
- private media
- Anki imported/read content
- private study sessions
- private progress/review history
- companion local memory where user-owned

Server should keep:

- auth/login/logout/me/session
- account shell
- billing/credits
- admin users
- AI jobs/queue/model routing
- system health/status
- public/shared features that are not private deck/card content

## Endpoint disable strategy

Do not hard-delete endpoints first.

Recommended sequence:

1. Patch frontend to use `window.APC_LOCAL_SAVE`.
2. Add backend guards to private study persistence endpoints.
3. Return clear local-only responses.
4. Later remove or archive dead backend route code after browser smoke passes.

Recommended guarded response code for still-mounted routes:

    403 private_study_data_local_only

Recommended removed legacy response code:

    410 private_study_server_storage_removed

## Focused inventory files

Generated files:

- docs/smoke/generated/stage-17k-z-r10d-r2-focused-private-study-endpoint-inventory/frontend-api-call-focused.txt
- docs/smoke/generated/stage-17k-z-r10d-r2-focused-private-study-endpoint-inventory/backend-route-focused.txt
- docs/smoke/generated/stage-17k-z-r10d-r2-focused-private-study-endpoint-inventory/backend-storage-focused.txt
- docs/smoke/generated/stage-17k-z-r10d-r2-focused-private-study-endpoint-inventory/focused-summary.json

## Next implementation recommendation

Patch one private content surface at a time.

Recommended next stage:

- R10E: move profile/preferences local storage to `APC_LOCAL_SAVE`, because it is lower-risk than deck/card migration.

Then:

- R10F: move APC-native decks/cards to `APC_LOCAL_SAVE`.
- R10G: move study sessions/progress to `APC_LOCAL_SAVE`.
- R10H: guard backend private study endpoints.
