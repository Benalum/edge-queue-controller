# Phase 14J-LX — UI Legacy Copy Cleanup Plan, No Deploy

Updated: 2026-06-18

## Purpose

This phase records a no-deploy plan for cleaning stale UI/source references found during Phase 14J-LW.

Phase 14J-LW confirmed the public platform remains healthy, but the public app still contains legacy copy/code references to CT101, master-laptop, pveso/PVESO, and old CT101 heartbeat/worker wording.

This phase does not patch frontend source, deploy to VM200, run qemu guest-agent operations, restart services, change controller code, change Cloudflare/DNS/tunnels, mutate DBs, mutate storage, start CT204, or wake PVESO.

## Prior checkpoint

- Phase: 14J-LW — Status/UI Polish Read-Only Review.
- Commit: `2fd36f0`.
- Tag: `controller-phase-14j-lw-status-ui-polish-read-only-review-2026-06-18`.
- Result: `PASS_PHASE_14J_LW_STATUS_UI_POLISH_READ_ONLY_REVIEW_DONE`.

## Phase 14J-LW public app findings

Phase 14J-LW observed public status healthy:

- `public_root_http=200`
- `public_app_src=/app.js?v=2026061814jlbr2`
- `public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`
- `public_status_http=200`
- `overall_state=online`
- `normalized_schema_version=2`
- `node_ids_sorted=ct-203,ct-204,pvew,vm-200`
- `storage_policy=manual-unlock-only`
- `storage_mount_state=unknown`
- `ct204_expected_state=stopped`
- `ct204_data_authority=false`

Phase 14J-LW also observed these legacy public app hits:

- `CT101 /api/* compatibility endpoints`
- `ct101-laptop-queue-worker`
- `Managed CT101 worker processing queued chat jobs`
- `master-laptop`
- `pveso`
- `ct-101`
- `CT101 for logged-in users`

## Phase 14J-LX repo source inspection

Read-only source grep result:

- `legacy_source_hit_count=15518`
- `app_like_legacy_hits=present`

The full grep output was intentionally not committed because it may contain broad historical docs references. The cleanup should focus only on active public/frontend runtime source and user-visible copy.

## Cleanup target categories

### A. Active topology labels

Replace legacy UI logic that assumes:

- `master-laptop` as controller;
- `pveso` as server/compute host for public status;
- `ct-101` as CPU/model worker in the current always-on public model.

Current public status/UI should reflect:

- `ct-203`: controller/API/queue authority;
- `pvew`: always-on platform host;
- `vm-200`: website-edge public/static frontend;
- `ct-204`: stopped backup-data-only/non-authority.

### B. Legacy worker copy

Replace or remove:

- `ct101-laptop-queue-worker`;
- `Managed CT101 worker processing queued chat jobs with guarded one-at-a-time execution.`;
- comments that say logged-in users power CT101.

Current copy should not imply CT101 is active public status authority or required for the public website to be online.

### C. Compatibility comments

Review comments about CT101 `/api/*` compatibility endpoints.

If the compatibility statement is historical or false under current PVEW topology, update it to say that CT203 owns current controller/API/queue status while legacy compatibility paths are parked or historical.

### D. Status aggregation logic

Review code paths that group nodes by legacy role or fallback IDs:

- `n.role === "master" || n.id === "master-laptop"`
- `n.role === "compute-host" || n.id === "pveso"`
- direct `nodeById("master-laptop")`, `nodeById("pveso")`, `nodeById("ct-101")`

Patch should align fallback logic with current node IDs and roles without making PVESO/CT101 parked state degrade public status.

## Future patch constraints

A future source patch may be repo-only/no-deploy first.

Allowed in a future no-deploy source patch:

- edit frontend source in repo only;
- update stale comments/user-visible strings;
- update local smoke tests that check current node IDs and storage card markers;
- verify no active public source references stale IDs in deployed app source build target.

Not allowed without explicit approval:

- VM200 deployment;
- qemu guest-agent write;
- nginx/cloudflared reload/restart;
- CT203 deployment;
- controller service restart;
- Cloudflare/DNS/tunnel mutation;
- DB backup/restore/migration;
- storage unlock/mount;
- CT204 start or data authority change;
- PVESO wake/start;
- SSH config mutation or SSH connection.

## Future deployment boundary

If a later frontend deploy is needed, require a separate explicit approval boundary.

Future deploy must:

1. build or copy only the approved frontend asset;
2. parse qemu guest-agent JSON exitcode for VM200 operations;
3. verify deployed app sha256;
4. verify storage card markers;
5. verify public root and `/system/status`;
6. not change Cloudflare/DNS/tunnels;
7. not restart services unless separately approved.

## Recommended next phases

Safe next options:

1. Phase 14J-LY — repo-only UI legacy copy source patch, no deploy.
2. Phase 14J-LZ — finish-plan summary and Source refresh readiness.
3. Approved Phase 14J-LS — add workstation `Host pvew` alias only.
4. Approved frontend deploy boundary after a repo-only UI source patch is reviewed.

## Exact smoke guardrail strings

- legacy_ui_copy_hits=present
- CT101 /api/* compatibility endpoints
- ct101-laptop-queue-worker
- master-laptop
- pveso
- ct-101
- CT101 for logged-in users
- ct-203
- pvew
- vm-200
- ct-204
- no frontend deploy
- no VM200 write
- no qemu guest-agent operation
- no service restart/reload/enable/start/stop
- no CT204 start
- no PVESO wake/start
- no Cloudflare/DNS/tunnel mutation

## Result marker

`PASS_PHASE_14J_LX_UI_LEGACY_COPY_CLEANUP_PLAN_NO_DEPLOY_DONE`
