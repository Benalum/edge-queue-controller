# Phase 14J-MK — VM200 Guest Exec Output Shape Read-Only

Updated: 2026-06-18

## Purpose

This phase inspects the output shape of VM200 qemu guest exec using only `/bin/true`.

The previous Phase 14J-MJ evidence showed both guest exec forms returned start exitcode 0, but the parser did not find a PID. This phase captures the exact stdout/stderr shape and tests whether a synchronous flag is supported.

## Prior checkpoint

- Phase: 14J-MJ — MI Deploy Failure Guest Exec Read-Only Diagnostic.
- Commit: `8b1f250`.
- Tag: `controller-phase-14j-mj-mi-deploy-failure-guest-exec-read-only-diagnostic-2026-06-18`.
- Result: `PASS_PHASE_14J_MJ_MI_DEPLOY_FAILURE_GUEST_EXEC_READ_ONLY_DIAGNOSTIC_DONE`.

## Public state

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

## Read-only guest exec output-shape evidence

- `pvew_guest_exec_shape_diag_exitcode=0`
- `pvew_ssh_connect=pass`
- `pvew_remote_user=root`
- `vm200_status=running`
- `vm200_qga_cmd_ping=pass`
- `qm_guest_exec_help_mentions_synchronous=no`
- `guest_exec_dashdash_start_exitcode=0`
- `guest_exec_dashdash_pid_present=no`
- `guest_exec_dashdash_status_exitcode=skipped`
- `guest_exec_dashdash_guest_exitcode=missing`
- `guest_exec_nodash_start_exitcode=0`
- `guest_exec_nodash_pid_present=no`
- `guest_exec_nodash_status_exitcode=skipped`
- `guest_exec_nodash_guest_exitcode=missing`
- `guest_exec_sync_probe_start_exitcode=0`
- `guest_exec_sync_probe_stdout_bytes=39`
- `guest_exec_sync_probe_stderr_bytes=0`
- `guest_exec_strategy=synchronous_flag_no_pid`
- `next_step_summary=retry_deploy_using_synchronous_flag_no_pid`

## Mutation scope

No VM200 app.js write, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Result marker

`PASS_PHASE_14J_MK_VM200_GUEST_EXEC_OUTPUT_SHAPE_READ_ONLY_DONE`
