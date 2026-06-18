# Phase 14J-ME — Update Workstation PVEW Alias User Root Only

Updated: 2026-06-18

## Purpose

This phase updated only the local workstation managed `Host pvew` SSH alias so its `User` line is `root`.

This addresses the Phase 14J-MD blocker where PVEW was reachable by Tailscale IP, but SSH auth was denied for the default workstation user.

## Approval

`APPROVE_PHASE_14J_ME_UPDATE_WORKSTATION_PVEW_ALIAS_USER_ROOT_ONLY`

## Prior checkpoint

- Phase: 14J-MD — Retry Deploy Blocked: PVEW SSH Auth/User Denied.
- Commit: `017f1a9`.
- Tag: `controller-phase-14j-md-retry-deploy-blocked-pvew-ssh-auth-user-2026-06-18`.
- Result: `PASS_PHASE_14J_MD_RETRY_DEPLOY_BLOCKED_PVEW_SSH_AUTH_USER_DONE`.

## Mutation scope

Allowed mutation:

- local workstation `~/.ssh/config` managed `Host pvew` block `User` line only.

No SSH connection attempt, no qemu guest-agent operation, no VM200 write, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## SSH config preflight

- `managed_begin_count=1`
- `managed_end_count=1`
- `managed_block_has_host_pvew=yes`
- `managed_block_hostname_line_count=1`
- `managed_block_hostname_class=tailscale-ip-redacted`
- `managed_block_user_line_count_before=0`
- `managed_block_user_is_root_before=no`
- `managed_block_port_22_present=yes`

## SSH config mutation evidence

- `ssh_config_backup_path=/home/alex/.ssh/config.bak-phase-14j-me-20260618T224810Z`
- `ssh_config_managed_host_pvew_user_updated=root`
- `managed_block_hostname_class_after=tailscale-ip-redacted`
- `managed_block_user_line_count_after=1`
- `managed_block_user_root_count_after=1`
- `managed_block_user_is_root_after=yes`
- `managed_block_port_22_present_after=yes`

## Local config expansion validation

`ssh -G pvew` was used only for local config expansion. It does not connect to PVEW.

- `ssh_g_pvew_exitcode=0`
- `ssh_g_hostname_prefix_100=yes`
- `ssh_g_hostname_class=tailscale-ip-redacted`
- `ssh_g_user=root`
- `ssh_g_user_is_root=yes`
- `ssh_g_port=22`
- `ssh_g_proxyjump_present=no`
- `ssh_g_proxycommand_present=no`

## Next gate

The VM200 wrapper app asset deploy can be retried only with a separate explicit approval phrase:

`APPROVE_PHASE_14J_MF_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

## Result marker

`PASS_PHASE_14J_ME_UPDATE_WORKSTATION_PVEW_ALIAS_USER_ROOT_ONLY_DONE`
