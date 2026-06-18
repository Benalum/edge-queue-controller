# Phase 14J-MH — VM200 QGA Command Compatibility Read-Only

Updated: 2026-06-18

## Purpose

This phase verifies the supported Proxmox qemu guest-agent ping command shape for VM200.

Phase 14J-MG showed that this PVEW `qm` does not support:

`qm guest ping 200`

The supported command family listed by `qm` is:

`qm guest cmd <vmid> <command>`

This phase therefore tested the read-only compatibility command:

`qm guest cmd 200 ping`

## Prior checkpoint

- Phase: 14J-MG — VM200 QGA Preflight Blocker Read-Only Diagnostic.
- Commit: `4eff0e6`.
- Tag: `controller-phase-14j-mg-vm200-qga-preflight-blocker-read-only-diagnostic-2026-06-18`.
- Result: `PASS_PHASE_14J_MG_VM200_QGA_PREFLIGHT_BLOCKER_READ_ONLY_DIAGNOSTIC_DONE`.

## Read-only public validation

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

## Read-only PVEW/VM200 QGA compatibility evidence

- `pvew_diag_exitcode=0`
- `pvew_ssh_connect=pass`
- `pvew_remote_user=root`
- `pvew_qm_binary=present`
- `qm_status_exitcode=0`
- `vm200_status=running`
- `qm_config_exitcode=0`
- `vm200_config_agent_line_present=yes`
- `vm200_config_agent_enabled_hint=yes`
- `qm_guest_cmd_ping_exitcode=0`
- `vm200_qga_cmd_ping=pass`
- `blocker_summary=old_preflight_command_shape_wrong_qga_available_retry_deploy_possible`

## Interpretation

If `blocker_summary=old_preflight_command_shape_wrong_qga_available_retry_deploy_possible`, the VM200 app asset deploy should be retried with the corrected preflight command:

`qm guest cmd 200 ping`

## Mutation scope

No VM200 write, no guest exec, no qemu guest-agent mutation, no SSH config mutation, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Next gate

If QGA compatibility passes, retry deployment with a separate explicit approval phrase:

`APPROVE_PHASE_14J_MI_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_CORRECTED_QGA_CMD`

## Result marker

`PASS_PHASE_14J_MH_VM200_QGA_COMMAND_COMPATIBILITY_READ_ONLY_DONE`
