# Phase 14J-LE-R2 — Deploy LB frontend storage status card to VM200

Date: 2026-06-18

## Scope

This checkpoint records the live static-file deployment of the Phase 14J-LB frontend storage status card to VM200.

The deployment changed only VM200 static frontend files:

- `/var/www/apc-wrapper-local/app.js`
- `/var/www/apc-wrapper-local/index.html`

## Approval

APPROVE_PHASE_14J_LE_DEPLOY_LB_FRONTEND_STORAGE_STATUS_CARD_TO_VM200_STATIC_FILES_NO_NGINX_RELOAD_NO_CLOUDFLARE_NO_DB_NO_STORAGE_NO_CT_VM_CONFIG

## Repo source

Repo HEAD:

- `a4e6a74`

Repo `frontend/wrapper-ui/app.js` sha256:

- `dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`

## Failed first attempt and recovery

The first LE deploy attempt partially applied because the VM200 guest transfer path wrote an incomplete app payload. The index cache-buster changed to `2026061814jlb`, but the public `app.js` did not match the repo hash.

Recovery was immediately performed by restoring the static-file backups created during the failed attempt.

Failed-attempt backups restored:

- `/var/www/apc-wrapper-local/app.js.bak-phase-14j-le-20260618T192932Z`
- `/var/www/apc-wrapper-local/index.html.bak-phase-14j-le-20260618T192932Z`

Restored old app sha256:

- `1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b`

Restored old index sha256:

- `9fe028be28bc92d81d94d3307739f3d71a706cfa656cad728034649fc5656a99`

Post-recovery public state:

- Public app source returned to `/app.js?v=20260614214f`
- Public app sha256 returned to `1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b`
- Storage-card frontend marker was absent again, matching the old asset.

## Successful R2 deployment

LE-R2 used a safer `qm guest exec --pass-stdin` transfer and explicit guest JSON exit-code checking before continuing.

R2 backups created before deployment:

- `/var/www/apc-wrapper-local/app.js.bak-phase-14j-le-r2-20260618T193233Z`
- `/var/www/apc-wrapper-local/index.html.bak-phase-14j-le-r2-20260618T193233Z`

R2 pre-deploy old app sha256:

- `1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b`

R2 pre-deploy old index sha256:

- `9fe028be28bc92d81d94d3307739f3d71a706cfa656cad728034649fc5656a99`

R2 deployed app sha256:

- `dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`

R2 deployed index sha256:

- `93a140b7779da28b1ada42feb5555189f8b4224cceeb026bd0b24f049343d8b2`

R2 public app source:

- `/app.js?v=2026061814jlbr2`

## Verified public behavior

Public root returned HTTP `200`.

Public `app.js` returned HTTP `200`.

Public `app.js` sha256 matched the repo:

- `dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`

Frontend storage-card markers were present in the public JS:

- `privateStorageInfrastructureGroup`
- `Private backup storage policy:`

Public `/system/status` returned HTTP `200` and still exposed the expected static private storage status:

- `mount_state: unknown`
- `policy: manual-unlock-only`
- `mountpoint: /srv/apc-private-data`
- `ct204.expected_state: stopped`
- `ct204.data_authority: false`

## Explicitly not changed

- No nginx reload or restart.
- No cloudflared reload or restart.
- No Cloudflare, DNS, or tunnel mutation.
- No DB mutation.
- No storage mutation.
- No CT/VM config mutation.
- No CT/VM start or stop.

## Current posture

The VM200 public frontend now serves the Phase 14J-LB storage status card code. The backend API already exposes the static storage policy block from Phase 14J-KX/KZ.

The frontend displays storage status as a policy/status card only. It does not probe encrypted storage, does not imply live host mount visibility from CT203, and keeps the live mount state as `unknown`.
