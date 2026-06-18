# Phase 14J-LM — Post-LL final platform baseline

Date: 2026-06-18

## Scope

Read-only final baseline after Phase 14J-LL deployed the current PVEW public status model to CT203.

## Repo checkpoint

Repo HEAD:

- `81b3c57`

Required tags present:

- `controller-phase-14j-lj-current-pvew-status-model-no-live-apply-2026-06-18`
- `controller-phase-14j-ll-deploy-lj-current-pvew-status-model-to-ct203-2026-06-18`
- `controller-phase-14j-le-r2-deploy-lb-frontend-storage-status-card-to-vm200-2026-06-18`

## Public frontend baseline

Public root:

- HTTP `200`

Public app source:

- `/app.js?v=2026061814jlbr2`

Public app sha256:

- `dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`

Public app markers present:

- `privateStorageInfrastructureGroup`
- `Private backup storage policy:`

## Public `/system/status` baseline

Public `/system/status`:

- HTTP `200`
- `overall_state: online`
- `nodes: ct-203,pvew,vm-200,ct-204`
- `normalized.schema_version: 2`
- `private_storage_status` valid and public-safe

Private storage status remained:

- `policy: manual-unlock-only`
- `mount_state: unknown`
- `mountpoint: /srv/apc-private-data`
- `ct204.expected_state: stopped`
- `ct204.data_authority: false`

## PVEW / VM200 / CT203 / CT204 baseline

VM/CT status:

- VM200: running
- CT203: running
- CT204: stopped

CT203 active source sha256:

- `8a5733b18d2807be9aaa55403929a30cb85182ca34316d1bdb0901d4b07f61e1`

CT203 service state:

- `edge-queue-controller.service`: active
- `edge-queue-controller.service`: enabled

CT203 DB integrity:

- `ok`

CT203 loopback `/system/status`:

- HTTP `200`
- current status model OK

VM200 static app sha256:

- `dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`

## Current posture

The platform is publicly healthy under the current PVEW model:

- PVEW is the always-on platform host.
- VM200 serves the public wrapper frontend.
- CT203 is the controller/API/queue authority.
- CT204 remains stopped, backup-data-only, and not data authority.
- The public System page no longer degrades due to legacy PVESO/CT101/laptop assumptions.

## Explicitly not changed

- No source mutation during the baseline.
- No live infra mutation.
- No service restart/reload.
- No VM/CT mutation.
- No DB mutation.
- No storage mutation.
- No Cloudflare/DNS/tunnel mutation.
