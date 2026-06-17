# Phase 14J-FF - Website-edge temporary loopback static server smoke

Date: 2026-06-17

## Phase marker

PHASE_14J_FF_WEBSITE_EDGE_TEMPORARY_LOOPBACK_STATIC_SERVER_SMOKE

## Purpose

Record the approved website-edge temporary local loopback static server smoke.

This phase verified that the already-cloned public wrapper static files can be served locally from website-edge using a temporary Python HTTP server bound only to 127.0.0.1.

## Previous checkpoint

Previous phase: Phase 14J-FE - Plan website-edge local loopback static server smoke
Previous commit: 5de0f65
Previous tag: controller-phase-14j-fe-plan-website-edge-local-loopback-static-server-smoke-2026-06-17

## Execution location

The VM-side smoke was run inside the existing website-edge SSH session.

This repo record is created on the laptop repo after the VM-side FF smoke completed.

## Approved mutation scope

Allowed inside website-edge:

- use existing verified sparse checkout
- serve only frontend/wrapper-ui
- start a temporary Python HTTP server
- bind only to 127.0.0.1
- use a high unprivileged local port
- perform local curl checks only
- verify static file content hashes
- stop the temporary server before exit

Explicitly not included:

- nginx config mutation
- systemd runtime creation
- app deployment
- Cloudflare test route
- Cloudflare production cutover
- Docker install
- cloudflared install
- Node/npm install
- controller/queue migration
- worker start
- runtime activation beyond temporary loopback-only static smoke
- production DB/job mutation
- CT101 call
- model/Ollama endpoint call
- Tailscale ACL/grants/tag mutation
- Tailscale SSH mode enablement
- subnet routes
- exit node
- Proxmox management exposure to public users
- secrets/raw IP/auth URL output
- rerun of Phase 14J-AG apply wrapper

## VM-side observed evidence

Location and OS guard:

- hostname=website-edge
- os_id=ubuntu
- os_version=26.04
- os_pretty=Ubuntu 26.04 LTS
- PASS: location guard matched website-edge Ubuntu 26.04

Existing checkout guard:

- head_now=03a6b4e
- tag_now=03a6b4e
- git_status_short=<clean>
- PASS: checkout remains at verified Phase 14J-FC checkpoint

Sparse worktree guard:

- /frontend/wrapper-ui/**
- /frontend/study-ui/**
- PASS: sparse checkout patterns match expected non-cone static paths
- actual_worktree_file_count=18
- PASS: actual filesystem worktree limited to frontend/wrapper-ui and frontend/study-ui

Forbidden command pre-check:

- PASS: command absent before ff: docker
- PASS: command absent before ff: cloudflared
- PASS: command absent before ff: node
- PASS: command absent before ff: npm

Required static file guard:

- PASS: required static file present: frontend/wrapper-ui/index.html bytes=4789
- PASS: required static file present: frontend/wrapper-ui/app.js bytes=343918
- PASS: required static file present: frontend/wrapper-ui/styles.css bytes=60815
- PASS: required static file present: frontend/wrapper-ui/queued_chat_config.js bytes=911

Loopback server evidence:

- temporary loopback server responded locally
- PASS: listener is bound to loopback on selected port
- PASS: no wildcard/non-loopback listener detected for selected port

Local curl checks:

- local_get_root_index_html_status=200
- local_get_root_index_html_expected_sha256=40d625f9bbdfe2fe63586831958e3b449ca9bb472e2afea87c20fc5f13b9ff71
- local_get_root_index_html_actual_sha256=40d625f9bbdfe2fe63586831958e3b449ca9bb472e2afea87c20fc5f13b9ff71
- PASS: local GET / matches frontend/wrapper-ui/index.html

- local_get_app_js_status=200
- local_get_app_js_expected_sha256=1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b
- local_get_app_js_actual_sha256=1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b
- PASS: local GET /app.js matches frontend/wrapper-ui/app.js

- local_get_styles_css_status=200
- local_get_styles_css_expected_sha256=c1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19
- local_get_styles_css_actual_sha256=c1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19
- PASS: local GET /styles.css matches frontend/wrapper-ui/styles.css

- local_get_queued_chat_config_js_status=200
- local_get_queued_chat_config_js_expected_sha256=5ea0fc240fbe42ee263e29a730e119b11e29759500dd0764f7ae37adff77765b
- local_get_queued_chat_config_js_actual_sha256=5ea0fc240fbe42ee263e29a730e119b11e29759500dd0764f7ae37adff77765b
- PASS: local GET /queued_chat_config.js matches frontend/wrapper-ui/queued_chat_config.js

Stop verification:

- PASS: no listener remains on temporary loopback port
- PASS: temporary server stopped before exit

Post-smoke verification:

- git_status_after=<clean>
- PASS: checkout remains clean after loopback smoke
- PASS: command absent after ff: docker
- PASS: command absent after ff: cloudflared
- PASS: command absent after ff: node
- PASS: command absent after ff: npm

Final VM-side result:

- PHASE_14J_FF_RESULT=passed
- temporary_loopback_static_server_smoke=passed
- temporary_server_stopped_before_exit=yes
- nginx_config_mutation_performed=no
- systemd_runtime_creation_performed=no
- app_deployment_performed=no
- cloudflare_test_route_performed=no
- cloudflare_production_cutover_performed=no
- docker_install_performed=no
- cloudflared_install_performed=no
- node_npm_install_performed=no
- controller_queue_migration_performed=no
- worker_start_performed=no
- runtime_activation_limited_to_temporary_loopback_static_smoke=yes
- production_db_job_mutation_performed=no
- ct101_call_performed=no
- model_ollama_endpoint_call_performed=no
- tailscale_acl_grants_tag_mutation_performed=no
- tailscale_ssh_mode_enablement_performed=no
- phase_14j_ag_apply_wrapper_rerun_performed=no
- phase_exit_code=0

## Current state after FF

- website-edge can locally serve the public wrapper static files through a temporary Python HTTP server.
- The temporary server was stopped before exit.
- The sparse checkout remained clean.
- No nginx config was changed.
- No systemd runtime was created.
- No app deployment occurred.
- No Cloudflare route or cutover occurred.
- No Docker, cloudflared, Node, or npm was installed.
- No controller/queue migration occurred.
- No worker start occurred.
- No runtime activation occurred beyond the temporary loopback static smoke.
- No production DB/job mutation occurred.
- No CT101/model/Ollama call occurred.
- No Tailscale ACL/grants/tag mutation or Tailscale SSH mode enablement occurred.
- No rerun of Phase 14J-AG apply wrapper occurred.

## Result

PHASE_14J_FF_RESULT=website_edge_temporary_loopback_static_server_smoke_recorded

## Next safe phase

NEXT_SAFE_PHASE=plan_nginx_static_wrapper_local_runtime_without_cloudflare_cutover

The next phase should be docs/smoke-only planning for nginx serving the static wrapper locally on website-edge, or a separately approved VM-only nginx local runtime apply. It must not perform Cloudflare route changes, production cutover, controller/queue migration, worker start, CT101/model calls, DB/job mutation, Docker/cloudflared install, or Tailscale policy mutation.
