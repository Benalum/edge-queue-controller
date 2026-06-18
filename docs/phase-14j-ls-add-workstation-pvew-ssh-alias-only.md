# Phase 14J-LS — Add Workstation PVEW SSH Alias Only

Updated: 2026-06-18

## Purpose

This phase added a local workstation SSH alias for `Host pvew` so future approved PVEW/VM200 qemu guest-agent operations can address PVEW by a stable alias.

## Approval

`APPROVE_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY`

## Prior checkpoint

- Phase: 14J-MA — VM200 Wrapper App Deploy Blocked: PVEW Alias Missing.
- Commit: `9ab67c6`.
- Tag: `controller-phase-14j-ma-vm200-wrapper-app-deploy-blocked-pvew-alias-missing-2026-06-18`.
- Result: `PASS_PHASE_14J_MA_VM200_WRAPPER_APP_DEPLOY_BLOCKED_PVEW_ALIAS_MISSING_DONE`.

## Mutation scope

Allowed mutation:

- local workstation `~/.ssh/config` managed `Host pvew` block only.

No SSH connection attempt, no qemu guest-agent operation, no VM200 write, no frontend deploy, no index.html mutation, no nginx config mutation, no cloudflared config mutation, no Cloudflare/DNS/tunnel mutation, no service restart/reload/enable/start/stop, no controller deploy, no CT203 source deploy, no DB mutation, no DB backup creation, no DB restore/import/migration, no storage mutation, no storage unlock/mount/format/key/crypttab/fstab mutation, no CT204 start, no CT204 data authority change, no CT/VM config mutation, no Tailscale config/auth mutation, and no PVESO wake/start occurred.

## Discovery evidence

- `tailscale_backend_state=Running`
- `pvew_peer_match_count=1`
- `pvew_peer_target_class=dnsname-redacted`
- `pvew_peer_target_is_literal_pvew=no`
- `pvew_peer_target_has_dot=yes`

The raw PVEW Tailscale DNS/hostname was intentionally not printed or committed.

## SSH config evidence

- `existing_unmanaged_host_pvew=no`
- `ssh_config_backup_path=/home/alex/.ssh/config.bak-phase-14j-ls-20260618T222822Z`
- `ssh_config_managed_host_pvew=written`
- `pvew_alias_user_source=default-ssh-user`
- `pvew_alias_user_configured=no`

Managed marker names:

- `# APC_PHASE_14J_LS_BEGIN_HOST_PVEW`
- `# APC_PHASE_14J_LS_END_HOST_PVEW`

## Local config expansion validation

`ssh -G pvew` was used only for local config expansion. It does not connect to PVEW.

- `ssh_g_pvew_exitcode=0`
- `ssh_g_hostname_matches_target=yes`
- `ssh_g_hostname_literal_pvew=no`
- `ssh_g_hostname_class=configured-redacted`
- `ssh_g_user_present=yes`
- `ssh_g_port=22`
- `ssh_g_proxyjump_present=no`
- `ssh_g_proxycommand_present=no`

## Next gate

The original VM200 asset deploy was blocked before mutation. After this alias phase, the deploy can be retried only with a separate explicit approval phrase:

`APPROVE_PHASE_14J_MB_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY`

## Result marker

`PASS_PHASE_14J_LS_ADD_WORKSTATION_PVEW_SSH_ALIAS_ONLY_DONE`
