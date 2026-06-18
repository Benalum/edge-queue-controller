# Phase 14J-MJ — MI Deploy Failure Guest Exec Read-Only Diagnostic

Updated: 2026-06-18

## Purpose

This phase records the failed Phase 14J-MI deploy attempt and performs a read-only compatibility diagnostic for VM200 qemu guest exec command forms.

Phase 14J-MI passed the corrected QGA preflight:

- `pvew_ssh_connect=pass`
- `pvew_remote_user=root`
- `pvew_qm_binary=present`
- `vm200_status=running`
- `qm_guest_cmd_ping_exitcode=0`
- `vm200_qga_cmd_ping=pass`
- `pvew_qemu_guest_agent_preflight=pass`

It failed immediately after entering the deploy-through-QGA section, before deployment evidence output was emitted.

## Prior checkpoint

- Phase: 14J-MH — VM200 QGA Command Compatibility Read-Only.
- Commit: `498baad`.
- Tag: `controller-phase-14j-mh-vm200-qga-command-compatibility-read-only-2026-06-18`.
- Result: `PASS_PHASE_14J_MH_VM200_QGA_COMMAND_COMPATIBILITY_READ_ONLY_DONE`.

## Public app state after failed MI attempt

- `public_root_http=200`
- `public_app_src=/app.js?v=2026061814jlbr2`
- `public_app_sha_after_failed_mi=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812`
- `public_app_state_after_failed_mi=old_app_still_deployed_no_public_change`
- `public_status_http=200`
- `overall_state=online`
- `normalized_schema_version=2`
- `node_ids_sorted=ct-203,ct-204,pvew,vm-200`
- `storage_policy=manual-unlock-only`
- `storage_mount_state=unknown`
- `ct204_expected_state=stopped`
- `ct204_data_authority=false`

## Read-only guest exec compatibility evidence

The guest exec checks executed only `/bin/true`.

- `pvew_guest_exec_diag_exitcode=0`
- `pvew_ssh_connect=pass`
- `pvew_remote_user=root`
- `pvew_qm_binary=present`
- `pvew_jq_binary=present`
- `vm200_status=running`
- `qm_guest_cmd_ping_exitcode=0`
- `vm200_qga_cmd_ping=pass`
- `guest_exec_dashdash_start_exitcode=0`
- `guest_exec_dashdash_pid_present=no`
- `guest_exec_dashdash_status_exitcode=skipped`
- `guest_exec_dashdash_guest_exitcode=missing`
- `guest_exec_nodash_start_exitcode=0`
- `guest_exec_nodash_pid_present=no`
- `guest_exec_nodash_status_exitcode=skipped`
- `guest_exec_nodash_guest_exitcode=missing`
- `guest_exec_supported_form=none_detected`
- `next_step_summary=inspect_before_retry`

## Mutation scope

No VM200 app.js write, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Result marker

`PASS_PHASE_14J_MJ_MI_DEPLOY_FAILURE_GUEST_EXEC_READ_ONLY_DIAGNOSTIC_DONE`
