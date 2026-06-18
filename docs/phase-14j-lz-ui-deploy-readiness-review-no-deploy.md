# Phase 14J-LZ — UI Deploy Readiness Review, No Deploy

Updated: 2026-06-18

## Purpose

This phase records a no-deploy readiness review after the Phase 14J-LY repo-only UI source patch.

The goal is to prove the repo source is ready for a future VM200 frontend deployment while confirming that the public deployed asset has not changed yet.

## Prior checkpoint

- Phase: 14J-LY — UI Legacy Copy Source Patch, No Deploy.
- Commit: `9b1b167`.
- Tag: `controller-phase-14j-ly-ui-legacy-copy-source-patch-no-deploy-2026-06-18`.
- Result: `PASS_PHASE_14J_LY_UI_LEGACY_COPY_SOURCE_PATCH_NO_DEPLOY_DONE`.

## Mutation scope

Repo docs/smoke/commit/tag/push plus public read-only HTTP GETs only.

No frontend deploy, no VM200 write, no qemu guest-agent operation, no controller deploy, no CT203 source deploy, no service restart/reload/enable/start/stop, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no SSH connection attempt, no SSH config mutation, no Tailscale config/auth mutation, no PVESO wake/start, and no Cloudflare/DNS/tunnel mutation occurred.

## Repo source readiness

- `repo_app_source=frontend/wrapper-ui/app.js`
- `repo_app_sha=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- `expected_repo_app_sha=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`
- `repo_app_legacy_hits=absent`
- `repo_node_syntax_check=pass`
- `privateStorageInfrastructureGroup=present`
- `Private backup storage policy:=present`
- `ct-203=present`
- `pvew=present`
- `vm-200=present`

## Public deployed asset state

- `public_root_http=200`
- `public_app_src=/app.js?v=2026061814jlbr2`
- `public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`
- `expected_public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`
- `public_deployed_legacy_hit_count=10`
- `public_deployed_legacy_hits=present`

Interpretation:

- The repo source is patched.
- The public deployed VM200 asset is still the prior Phase 14J-LM asset.
- Therefore the UI cleanup has not been deployed yet and still needs a separate explicit deployment boundary.

## Public status state

- `public_status_http=200`
- `overall_state=online`
- `normalized_schema_version=2`
- `node_ids_sorted=ct-203,ct-204,pvew,vm-200`
- `storage_policy=manual-unlock-only`
- `storage_mount_state=unknown`
- `ct204_expected_state=stopped`
- `ct204_data_authority=false`

## Future deploy boundary

A future deployment requires explicit approval.

Suggested approval phrase:

`APPROVE_PHASE_14J_MA_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

Allowed scope after approval:

1. Deploy only the approved `frontend/wrapper-ui/app.js` asset to VM200.
2. Use qemu guest-agent only for VM200 file write/verification if needed.
3. Parse qemu guest-agent JSON exitcode; do not trust wrapper PASS alone.
4. Do not change Cloudflare, DNS, tunnels, nginx config, cloudflared config, CT203, CT204, DBs, storage, PVESO, SSH config, or Tailscale config.
5. Verify public root HTTP 200.
6. Verify public app source/hash changes as expected.
7. Verify public app legacy hits are absent after deploy.
8. Verify public `/system/status` remains online with nodes `ct-203,ct-204,pvew,vm-200`.
9. Verify private storage policy remains manual-unlock-only and mount_state remains unknown.

## Stop conditions for future deploy

Stop before deploy if:

- repo is dirty;
- source hash is not `8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751`;
- source syntax check fails;
- public status is not online;
- public status node IDs differ from `ct-203,ct-204,pvew,vm-200`;
- CT204 data_authority is not false;
- storage policy differs from manual-unlock-only;
- qemu guest-agent operation is needed but exitcode cannot be parsed;
- deployment would require service restart/reload, Cloudflare/DNS/tunnel mutation, storage mutation, DB mutation, CT204 start, PVESO wake, SSH config change, or Tailscale auth/config change.

## Exact smoke guardrail strings

- repo_app_sha=8c32e726f50b0255643ac46c5187feb2bd7722184cb7db188f054675bf513751
- repo_app_legacy_hits=absent
- public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812
- public_deployed_legacy_hits=present
- public_status_http=200
- overall_state=online
- normalized_schema_version=2
- node_ids_sorted=ct-203,ct-204,pvew,vm-200
- storage_policy=manual-unlock-only
- storage_mount_state=unknown
- ct204_expected_state=stopped
- ct204_data_authority=false
- APPROVE_PHASE_14J_MA_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY
- no frontend deploy
- no VM200 write
- no qemu guest-agent operation
- no service restart/reload/enable/start/stop
- no Cloudflare/DNS/tunnel mutation

## Result marker

`PASS_PHASE_14J_LZ_UI_DEPLOY_READINESS_REVIEW_NO_DEPLOY_DONE`
