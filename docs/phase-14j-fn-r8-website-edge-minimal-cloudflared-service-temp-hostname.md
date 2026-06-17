# Phase 14J-FN-R8 - Website-edge minimal cloudflared service temporary hostname

Date: 2026-06-17

## Phase marker

PHASE_14J_FN_R8_WEBSITE_EDGE_MINIMAL_CLOUDFLARED_SERVICE_TEMP_HOSTNAME

## Purpose

Record the successful website-edge Cloudflare Tunnel runtime setup for the temporary test hostname only.

This records the successful R8 path, after earlier failed/recovered attempts:

- FN initial attempt failed because the Cloudflare Linux install block was pasted instead of only the tunnel token or service-install token line.
- FN-R2 successfully installed and started cloudflared but failed overly strict public root exact-hash validation, then rolled back.
- FN-R3 inspected and showed cached assets plus root 530 after rollback.
- FN-R4 failed cloudflared service install after residual installer state.
- FN-R5 found residual cloudflared-update units.
- FN-R6 cleaned the residual cloudflared-update units.
- FN-R7 exposed a script bug where root-only env file verification used non-root file test and rolled back.
- FN-R8 fixed root-only file checks and passed.

## Previous repo checkpoint

Previous repo phase: Phase 14J-FM - token-safe website-edge tunnel setup plan
Previous commit: 4c781e6
Previous tag: controller-phase-14j-fm-plan-token-safe-website-edge-tunnel-setup-temporary-test-hostname-2026-06-17

## Runtime mutation scope actually performed on website-edge

MUTATION_SCOPE=website_edge_vm_200_minimal_cloudflared_service_setup_temp_hostname_only

Allowed and completed:

- hidden interactive tunnel token entry
- root-owned 0600 token env file
- minimal cloudflared systemd service
- no-autoupdate cloudflared run mode
- temporary public hostname smoke
- root marker validation
- exact asset hash validation
- nginx local health before and after

## Successful runtime result

PHASE_14J_FN_R8_RESULT=passed
minimal_cloudflared_service_setup_temp_hostname=passed
rollback_performed=no

temporary_test_hostname=website-edge-test.alexhartel.com
cloudflared_path=/usr/local/bin/cloudflared
cloudflared_version=cloudflared version 2026.6.0
cloudflared_service_file=/etc/systemd/system/cloudflared.service
cloudflared_service_file_mode=644
cloudflared_service_file_owner=root:root
cloudflared_service_file_content_printed=no
cloudflared_execstart_printed=no
cloudflared_service_uses_no_autoupdate=yes
cloudflared_service_uses_environment_file=yes

cloudflared_token_env_file=/etc/cloudflared/website-edge-tunnel.env
cloudflared_token_env_file_mode=600
cloudflared_token_env_file_owner=root:root
cloudflared_token_env_file_size_bytes_recorded=yes
cloudflared_token_env_file_content_printed=no

cloudflared_load_state=loaded
cloudflared_active_state=active
cloudflared_sub_state=running
cloudflared_unit_file_state=enabled
cloudflared_service_status_sanitized=yes

cloudflared_update_service_created=no
cloudflared_update_timer_created=no

token_printed=no
token_in_apc_last_output=no
token_in_chatgpt=no
token_committed=no
token_in_source_files=no

## Static runtime validation

nginx_config_test_before_fn_r8=passed
nginx_config_test_after_fn_r8=passed

pre_fn_r8_root_index_html_status=200
pre_fn_r8_app_js_status=200
pre_fn_r8_styles_css_status=200
pre_fn_r8_queued_chat_config_js_status=200

post_fn_r8_root_index_html_status=200
post_fn_r8_app_js_status=200
post_fn_r8_styles_css_status=200
post_fn_r8_queued_chat_config_js_status=200

public_fn_r8_root_index_html_status=200
public_fn_r8_root_marker_validation_passed=yes
public_fn_r8_app_js_status=200
public_fn_r8_styles_css_status=200
public_fn_r8_queued_chat_config_js_status=200

temporary_public_hostname_smoke_performed=yes
temporary_public_hostname_smoke_passed=yes
root_exact_hash_required=no
root_marker_validation_required=yes
asset_exact_hash_validation_required=yes

## Denied and not performed

cloudflare_route_mutation_by_terminal_performed=no
cloudflare_production_cutover_performed=no
apex_root_route_replacement_performed=no
primary_public_route_replacement_performed=no
proxmox_public_exposure_performed=no
nginx_config_mutation_performed=no
docker_install_performed=no
node_npm_install_performed=no
tailscale_acl_grants_tag_mutation_performed=no
tailscale_ssh_mode_enablement_performed=no
subnet_routes_created=no
exit_node_enabled=no
controller_queue_migration_performed=no
worker_start_performed=no
production_db_job_mutation_performed=no
ct101_call_performed=no
model_ollama_endpoint_call_performed=no
phase_14j_ag_apply_wrapper_rerun_performed=no

## Security notes

The tunnel token was not printed, not pasted into ChatGPT, not committed, not written into source files, and not included in APC_LAST_OUTPUT.

The token exists only in the root-owned env file on website-edge:

- path recorded
- permissions recorded
- owner recorded
- content not printed

## Production status

PRODUCTION_CUTOVER_STATUS=not_performed
APEX_ROOT_ROUTE_REPLACEMENT_STATUS=not_performed
PRIMARY_PUBLIC_ROUTE_REPLACEMENT_STATUS=not_performed
TEMPORARY_TEST_HOSTNAME_ONLY=yes

## Next safe phase

NEXT_SAFE_PHASE=record_and_verify_fn_r8_then_plan_production_cutover_only_without_applying_cutover

A future production cutover must be planned separately first. It must not be applied without explicit approval.
