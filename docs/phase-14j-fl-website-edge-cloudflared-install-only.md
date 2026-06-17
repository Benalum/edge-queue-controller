# Phase 14J-FL - Website-edge cloudflared install-only

Date: 2026-06-17

## Phase marker

PHASE_14J_FL_WEBSITE_EDGE_CLOUDFLARED_INSTALL_ONLY

## Purpose

Record the approved website-edge cloudflared install-only phase.

This phase installed only the cloudflared binary on website-edge VM 200. It did not authenticate a tunnel, use a token, create a public hostname, mutate Cloudflare routes, create a service, or perform production cutover.

## Previous checkpoint

Previous phase: Phase 14J-FK - Plan explicit website-edge Cloudflare tunnel transport
Previous commit: 4c962c4
Previous tag: controller-phase-14j-fk-plan-explicit-website-edge-cloudflare-tunnel-transport-2026-06-17

## Mutation scope

MUTATION_SCOPE=website_edge_vm_200_cloudflared_install_only

Allowed in VM-side phase:

- official cloudflared binary download
- install to /usr/local/bin/cloudflared
- version verification
- nginx local health checks before and after install

Denied in VM-side phase:

- tunnel auth token
- Cloudflare route mutation
- test hostname apply
- production cutover
- nginx config mutation
- app systemd runtime creation
- Docker install
- Node/npm install
- Tailscale ACL/grants/tag mutation
- Tailscale SSH mode enablement
- subnet routes
- exit node
- Proxmox mutation
- controller/queue migration
- worker start
- production DB/job mutation
- CT101 call
- model/Ollama endpoint call
- secrets/raw IPs/auth URLs
- Phase 14J-AG apply wrapper rerun

## Website-edge guards

hostname=website-edge
os_id=ubuntu
os_version=26.04
os_pretty=Ubuntu 26.04 LTS
PASS: location guard matched website-edge Ubuntu 26.04
PASS: sudo authentication cached
PASS: nginx service active before FL
PASS: nginx command available before FL
PASS: nginx config test passed before FL

## Forbidden command pre-check

PASS: command absent before fl: docker
PASS: command absent before fl: node
PASS: command absent before fl: npm
PASS: cloudflared absent before FL

## Nginx local static runtime before install

pre_fl_root_index_html_status=200
PASS: nginx local static check matched for pre_fl_root_index_html
pre_fl_app_js_status=200
PASS: nginx local static check matched for pre_fl_app_js
pre_fl_styles_css_status=200
PASS: nginx local static check matched for pre_fl_styles_css
pre_fl_queued_chat_config_js_status=200
PASS: nginx local static check matched for pre_fl_queued_chat_config_js

## Cloudflared download and install

dpkg_arch=amd64
download_source=official_cloudflare_github_latest_release
download_kind=linux-amd64-binary
download_url_printed=no
download_size_bytes=39244160
download_sha256=08d27c4c5d3ed73ee3e98ef2ddceb4ad09fd4cfc28e243565a189538e8ccd706
PASS: downloaded cloudflared binary size is plausible
downloaded_cloudflared_version=cloudflared version 2026.6.0
PASS: downloaded cloudflared binary version check passed
existing_install_backup_created=no
PASS: cloudflared binary installed to expected path

## Post-install verification

installed_cloudflared_path=/usr/local/bin/cloudflared
PASS: cloudflared resolves to expected install path
installed_cloudflared_sha256=08d27c4c5d3ed73ee3e98ef2ddceb4ad09fd4cfc28e243565a189538e8ccd706
PASS: installed cloudflared hash matches downloaded binary
installed_cloudflared_version=cloudflared version 2026.6.0
PASS: installed cloudflared version check passed

## No tunnel auth, service, route, or hostname was created

PASS: no cloudflared systemd unit exists after install-only phase
PASS: no cloudflared process running after install-only phase
home_cloudflared_file_count=0
cloudflare_token_used=no
cloudflare_tunnel_authenticated=no
cloudflare_route_mutation_performed=no
cloudflare_test_hostname_created=no
cloudflare_production_cutover_performed=no

## Nginx local static runtime after install

PASS: nginx service active after FL
PASS: nginx config test passed after FL
post_fl_root_index_html_status=200
PASS: nginx local static check matched for post_fl_root_index_html
post_fl_app_js_status=200
PASS: nginx local static check matched for post_fl_app_js
post_fl_styles_css_status=200
PASS: nginx local static check matched for post_fl_styles_css
post_fl_queued_chat_config_js_status=200
PASS: nginx local static check matched for post_fl_queued_chat_config_js

## Post-checks

PASS: command absent after fl: docker
PASS: command absent after fl: node
PASS: command absent after fl: npm
website_edge_source_git_status_after=<clean>
PASS: website-edge source checkout remains clean after FL

## Local FL report marker

PHASE_14J_FL_WEBSITE_EDGE_CLOUDFLARED_INSTALL_ONLY
nginx_config_test_before_fl=passed
nginx_config_test_after_fl=passed
cloudflare_token_used=no
cloudflare_tunnel_authenticated=no
cloudflare_route_mutation_performed=no
cloudflare_test_hostname_created=no
cloudflare_production_cutover_performed=no
cloudflared_systemd_unit_created_or_enabled=no
cloudflared_process_running_after_install=no
nginx_config_mutation_performed=no
app_systemd_runtime_creation_performed=no
docker_install_performed=no
node_npm_install_performed=no
tailscale_acl_grants_tag_mutation_performed=no
tailscale_ssh_mode_enablement_performed=no
subnet_routes_created=no
exit_node_enabled=no
proxmox_mutation_performed=no
controller_queue_migration_performed=no
worker_start_performed=no
production_db_job_mutation_performed=no
ct101_call_performed=no
model_ollama_endpoint_call_performed=no
phase_14j_ag_apply_wrapper_rerun_performed=no

## Final VM-side result

PHASE_14J_FL_RESULT=passed
cloudflared_install_only=passed
rollback_performed=no
phase_exit_code=0

## Current state after FL

- cloudflared binary is installed on website-edge.
- cloudflared version verified as 2026.6.0.
- No Cloudflare token was used.
- No tunnel was authenticated.
- No Cloudflare route was created, updated, or deleted.
- No test hostname was created.
- No production cutover occurred.
- No cloudflared service was created or enabled.
- No cloudflared process is running.
- nginx local static runtime remained healthy before and after install.
- Docker, Node, and npm remain absent.
- website-edge source checkout remains clean.

## Result

PHASE_14J_FL_RESULT=website_edge_cloudflared_install_only_recorded

## Next safe phase

NEXT_SAFE_PHASE=plan_website_edge_cloudflared_tunnel_token_setup_for_temporary_test_hostname_without_production_cutover

The next phase should be docs/smoke-only planning for token-safe tunnel setup, or a separately approved token setup phase using a dedicated tunnel token entered interactively and never printed.
