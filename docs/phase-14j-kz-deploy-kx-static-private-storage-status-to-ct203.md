# Phase 14J-KZ — Deploy KX static private storage status to CT203

Date: 2026-06-18

## Scope

This checkpoint records the approved deployment of the already-committed KX static private storage status API contract to CT203.

## Approval

APPROVE_PHASE_14J_KZ_DEPLOY_KX_STATIC_PRIVATE_STORAGE_STATUS_TO_CT203_AND_RESTART_CONTROLLER_NO_DB_MUTATION_NO_STORAGE_MUTATION_NO_CT_VM_MUTATION_NO_CLOUDFLARE

## Applied mutation

Only CT203 controller source deployment and controller service restart were performed.

## Deployed source

Repo HEAD:

- `49f881b`

Repo `edge_controller.py` sha256:

- `026a7dfe0fa7e04969f0bb5343e090e99c5454b03136fb753fc379cba148c24b`

CT203 deployed `edge_controller.py` sha256:

- `026a7dfe0fa7e04969f0bb5343e090e99c5454b03136fb753fc379cba148c24b`

Previous CT203 source backup:

- `/opt/edge-queue-controller/current/edge_controller.py.bak-phase-14j-kz-20260618T191857Z`

Previous CT203 source backup sha256:

- `ce6a46c4fed2b6f92fc2a1854102a8696af170605eaf79f38d8bfea5fec322e8`

## Verified post-deploy state

- VM200 remained running.
- CT203 remained running.
- CT204 remained stopped.
- `edge-queue-controller.service` remained enabled.
- `edge-queue-controller.service` restarted successfully and returned active.
- CT203 SQLite DB integrity remained ok.

## Verified API behavior

Loopback CT203 `/system/status` returned the expected static storage status block:

- `mount_state: unknown`
- `policy: manual-unlock-only`
- `mountpoint: /srv/apc-private-data`
- `ct204.expected_state: stopped`
- `ct204.data_authority: false`

Public `/system/status` returned HTTP `200` and the same expected static storage status block.

## Explicitly not changed

- No DB mutation.
- No storage mutation.
- No crypttab/fstab/systemd storage mutation.
- No CT/VM start, stop, or config mutation.
- No Cloudflare, DNS, or tunnel mutation.
- No nginx mutation.

## Current posture

The public system status API now exposes a safe static private storage policy block. It does not inspect the live PVEW host mount from CT203 and intentionally reports live mount state as unknown until a separately approved host-visible signal exists.
