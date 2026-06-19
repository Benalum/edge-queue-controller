# Phase 14J-MM — VM200 Webroot App Path Read-Only Diagnostic

Updated: 2026-06-18

## Purpose

This phase records the failed Phase 14J-ML deployment attempt and the recovered read-only VM200 path diagnostic evidence.

Phase 14J-ML passed SSH, QGA ping, and synchronous guest exec preflight, then stopped before any app.js write because no app.js target was found in the guessed paths.

A follow-up read-only cache retrieval recovered the decoded path diagnostic output from PVEW /tmp.

## Prior checkpoint

- Phase: 14J-MK — VM200 Guest Exec Output Shape Read-Only.
- Commit: `db2e2ca`.
- Tag: `controller-phase-14j-mk-vm200-guest-exec-output-shape-read-only-2026-06-18`.
- Result: `PASS_PHASE_14J_MK_VM200_GUEST_EXEC_OUTPUT_SHAPE_READ_ONLY_DONE`.

## Failed ML evidence

- `guest_locate_qm_exitcode=0`
- `guest_locate_exited=1`
- `guest_locate_exitcode=2`
- `guest_locate_stderr=FAIL: app.js target not found`

No VM200 app.js write occurred in ML.

## Public state after failed ML

- `public_root_http=200`
- `public_app_src=/app.js?v=2026061814jlbr2`
- `public_app_sha_after_failed_ml=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`
- `public_app_state_after_failed_ml=old_app_still_deployed_no_public_change`
- `public_status_http=200`
- `overall_state=online`
- `normalized_schema_version=2`
- `node_ids_sorted=ct-203,ct-204,pvew,vm-200`
- `storage_policy=manual-unlock-only`
- `storage_mount_state=unknown`
- `ct204_expected_state=stopped`
- `ct204_data_authority=false`

## Recovered VM200 path diagnostic evidence

- `pvew_cache_read_exitcode=0`
- `pvew_ssh_connect=pass`
- `pvew_remote_user=root`
- `pathdiag_exitcode=2`
- `pathdiag_stdout_bytes=488`
- `appjs_paths_count=3`
- `index_src_paths_count=1`
- `wrapper_source_path=/home/jkg76nid/apc-website-edge/source/edge-queue-controller/frontend/wrapper-ui/app.js`
- `study_source_path=/home/jkg76nid/apc-website-edge/source/edge-queue-controller/frontend/study-ui/app.js`
- `live_wrapper_path=/var/www/apc-wrapper-local/app.js`
- `live_index_path=/var/www/apc-wrapper-local/index.html`
- `next_target_strategy=deploy_to_live_wrapper_path`

The correct live VM200 wrapper target is:

`/var/www/apc-wrapper-local/app.js`

The index that references the deployed app asset is:

`/var/www/apc-wrapper-local/index.html`

## Mutation scope

No VM200 app.js write, no qemu guest-agent operation during recovery record, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Result marker

`PASS_PHASE_14J_MM_VM200_WEBROOT_APP_PATH_READ_ONLY_DIAGNOSTIC_DONE`
