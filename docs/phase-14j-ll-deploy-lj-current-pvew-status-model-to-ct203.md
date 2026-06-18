# Phase 14J-LL — Deploy LJ current PVEW status model to CT203

Date: 2026-06-18

## Scope

This checkpoint records the approved live deployment of the Phase 14J-LJ public status model update to CT203.

Live mutation performed:

- Replaced CT203 `/opt/edge-queue-controller/current/edge_controller.py`.
- Restarted only `edge-queue-controller.service` inside CT203.

## Approval

`APPROVE_PHASE_14J_LL_DEPLOY_LJ_CURRENT_PVEW_STATUS_MODEL_TO_CT203_AND_RESTART_CONTROLLER_NO_DB_MUTATION_NO_STORAGE_MUTATION_NO_CT_VM_CONFIG_NO_CLOUDFLARE`

## Repo source deployed

Repo HEAD:

- `f4201b4`

Repo `edge_controller.py` sha256:

- `8a5733b18d2807be9aaa55403929a30cb85182ca34316d1bdb0901d4b07f61e1`

## Previous CT203 source

Previous CT203 `edge_controller.py` sha256:

- `026a7dfe0fa7e04969f0bb5343e090e99c5454b03136fb753fc379cba148c24b`

Backup created before replacement:

- `/opt/edge-queue-controller/current/edge_controller.py.bak-phase-14j-ll-20260618T194849Z`

Backup sha256:

- `026a7dfe0fa7e04969f0bb5343e090e99c5454b03136fb753fc379cba148c24b`

## Deployment evidence

PVEW/VM/CT preflight:

- VM200 status: running
- CT203 status: running
- CT204 status: stopped

CT203 pre-deploy checks:

- `edge-queue-controller.service`: active
- `edge-queue-controller.service`: enabled
- DB integrity: `ok`

CT203 deployed source sha256:

- `8a5733b18d2807be9aaa55403929a30cb85182ca34316d1bdb0901d4b07f61e1`

CT203 post-restart checks:

- `edge-queue-controller.service`: active
- `edge-queue-controller.service`: enabled
- DB integrity: `ok`

## Loopback validation

CT203 loopback `/system/status` returned HTTP `200`.

Expected current PVEW model was present:

- `overall_state: online`
- `nodes: ct-203,pvew,vm-200,ct-204`
- `normalized.schema_version: 2`
- `private_storage_status` remained valid and public-safe

## Public validation

Public `/system/status` returned HTTP `200`.

Expected current PVEW model was present:

- `overall_state: online`
- `nodes: ct-203,pvew,vm-200,ct-204`
- `normalized.schema_version: 2`
- `private_storage_status` remained valid and public-safe

## Explicitly not changed

- No DB mutation.
- No storage mutation.
- No CT/VM config mutation.
- No VM200 deployment.
- No Cloudflare, DNS, or tunnel mutation.
- No nginx reload or restart.
- No cloudflared reload or restart.
- No CT204 start.
- No PVESO start.

## Current posture

The public System status model now matches current platform reality:

- PVEW is the always-on platform host.
- VM200 is the public website-edge VM.
- CT203 is the controller/API/queue authority.
- CT204 is backup-data-only, expected stopped, and not data authority.

The old legacy PVESO/CT101/laptop status assumptions no longer drive public `/system/status` degradation.
