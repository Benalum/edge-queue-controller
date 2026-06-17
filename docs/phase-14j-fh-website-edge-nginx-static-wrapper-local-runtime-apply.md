# Phase 14J-FH - Website-edge nginx static wrapper local runtime apply

Date: 2026-06-17

## Phase marker

PHASE_14J_FH_WEBSITE_EDGE_NGINX_STATIC_WRAPPER_LOCAL_RUNTIME_APPLY

## Purpose

Record the approved website-edge nginx static wrapper local runtime apply.

This phase configured nginx on website-edge VM 200 to serve the already-verified public wrapper static files locally only. No Cloudflare route, Cloudflare test route, or production cutover was performed.

## Previous checkpoint

Previous phase: Phase 14J-FG - Plan nginx static wrapper local runtime without Cloudflare cutover
Previous commit: cc74a88
Previous tag: controller-phase-14j-fg-plan-nginx-static-wrapper-local-runtime-without-cloudflare-cutover-2026-06-17

## Initial FH attempt

The first FH command stopped before mutation because sudo authentication was not cached.

Evidence:

- sudo: interactive authentication is required
- phase_exit_code=1
- nginx config mutation did not start
- no docroot mutation occurred
- no reload occurred
- no rollback was needed

## Successful FH retry

The retry began with sudo authentication and completed successfully.

Location and OS guard:

- hostname=website-edge
- os_id=ubuntu
- os_version=26.04
- os_pretty=Ubuntu 26.04 LTS
- PASS: location guard matched website-edge Ubuntu 26.04

Sudo and nginx guard:

- PASS: sudo authentication cached
- PASS: nginx service active before FH
- PASS: nginx command available

Checkout guard:

- head_now=03a6b4e
- tag_now=03a6b4e
- git_status_short=<clean>
- PASS: checkout remains at verified Phase 14J-FC checkpoint

Sparse checkout guard:

- /frontend/wrapper-ui/**
- /frontend/study-ui/**
- PASS: sparse checkout patterns match expected non-cone static paths
- actual_worktree_file_count=18
- PASS: actual filesystem worktree limited to frontend/wrapper-ui and frontend/study-ui

Forbidden command pre-check:

- PASS: command absent before fh: docker
- PASS: command absent before fh: cloudflared
- PASS: command absent before fh: node
- PASS: command absent before fh: npm

Nginx local port pre-check:

- PASS: selected nginx local port has no listener before FH

Source static file guard:

- PASS: source wrapper static file present: index.html
- PASS: source wrapper static file present: app.js
- PASS: source wrapper static file present: styles.css
- PASS: source wrapper static file present: queued_chat_config.js
- PASS: source wrapper static file present: queued_chat_status.js
- PASS: source wrapper static file present: router_shadow_read_stub.js
- PASS: source wrapper static file present: favicon.svg
- PASS: source wrapper static file present: robots.txt
- PASS: source wrapper static file present: sitemap.xml
- PASS: source wrapper static file present: _headers
- PASS: source wrapper static file present: _redirects
- PASS: dev_server.py exists in source checkout but will not be copied to nginx docroot

Backup evidence:

- backup_config_existing=no
- backup_enabled_existing=no
- backup_docroot_existing=no

Docroot staging and copy:

- PASS: staged docroot excludes Python/runtime files
- PASS: staged docroot has no obvious secret/key/env filenames
- PASS: nginx docroot populated with wrapper static files only
- PASS: nginx docroot excludes Python/runtime files
- PASS: nginx docroot has no obvious secret/key/env filenames

Copied file hash verification:

- PASS: copied file hash matches source: index.html
- PASS: copied file hash matches source: app.js
- PASS: copied file hash matches source: styles.css
- PASS: copied file hash matches source: queued_chat_config.js
- PASS: copied file hash matches source: queued_chat_status.js
- PASS: copied file hash matches source: router_shadow_read_stub.js
- PASS: copied file hash matches source: favicon.svg
- PASS: copied file hash matches source: robots.txt
- PASS: copied file hash matches source: sitemap.xml
- PASS: copied file hash matches source: _headers
- PASS: copied file hash matches source: _redirects

Nginx config and reload:

- PASS: nginx local static site config written and enabled
- PASS: nginx config test passed before reload
- PASS: nginx reload succeeded after config test
- PASS: nginx listener is bound to loopback on local port
- PASS: no wildcard/non-loopback nginx listener detected for local port

Local nginx curl checks:

- nginx_local_get_root_index_html_status=200
- PASS: nginx local GET / matches wrapper index.html
- nginx_local_get_app_js_status=200
- PASS: nginx local GET /app.js matches wrapper app.js
- nginx_local_get_styles_css_status=200
- PASS: nginx local GET /styles.css matches wrapper styles.css
- nginx_local_get_queued_chat_config_js_status=200
- PASS: nginx local GET /queued_chat_config.js matches wrapper queued_chat_config.js

Post-FH verification:

- git_status_after=<clean>
- PASS: source checkout remains clean after FH
- PASS: command absent after fh: docker
- PASS: command absent after fh: cloudflared
- PASS: command absent after fh: node
- PASS: command absent after fh: npm
- PASS: final nginx config test passed

Local FH report marker:

- PHASE_14J_FH_WEBSITE_EDGE_NGINX_STATIC_WRAPPER_LOCAL_RUNTIME_APPLY
- nginx_config_test_before_reload=passed
- nginx_reload_after_config_test=passed
- nginx_static_wrapper_local_runtime_apply=passed
- source_checkout_remained_clean=yes
- cloudflare_test_route_performed=no
- cloudflare_production_cutover_performed=no
- cloudflared_install_performed=no
- docker_install_performed=no
- node_npm_install_performed=no
- app_systemd_runtime_creation_performed=no
- controller_queue_migration_performed=no
- worker_start_performed=no
- runtime_activation_limited_to_nginx_static_wrapper_local=yes
- production_db_job_mutation_performed=no
- ct101_call_performed=no
- model_ollama_endpoint_call_performed=no
- tailscale_acl_grants_tag_mutation_performed=no
- tailscale_ssh_mode_enablement_performed=no
- phase_14j_ag_apply_wrapper_rerun_performed=no

Final VM-side result:

- PHASE_14J_FH_RESULT=passed
- nginx_static_wrapper_local_runtime_apply=passed
- rollback_performed=no
- phase_exit_code=0

## Current state after FH

- website-edge nginx serves the static wrapper locally on loopback port 18080.
- The nginx site config is local-only.
- The nginx listener is loopback-only.
- Nginx config test passed before reload.
- Nginx reload succeeded only after a passing config test.
- Local curl checks passed for /, /app.js, /styles.css, and /queued_chat_config.js.
- Copied file hashes matched the verified wrapper source files.
- The source checkout remained clean.
- Docker remains absent.
- cloudflared remains absent.
- Node/npm remain absent.
- No Cloudflare route or production cutover occurred.
- No app systemd runtime was created.
- No controller/queue migration occurred.
- No worker start occurred.
- No runtime activation occurred beyond nginx serving static wrapper files locally.
- No production DB/job mutation occurred.
- No CT101/model/Ollama call occurred.
- No Tailscale ACL/grants/tag mutation or Tailscale SSH mode enablement occurred.
- No rerun of Phase 14J-AG apply wrapper occurred.

## Result

PHASE_14J_FH_RESULT=website_edge_nginx_static_wrapper_local_runtime_apply_recorded

## Next safe phase

NEXT_SAFE_PHASE=plan_cloudflare_test_route_for_website_edge_nginx_local_runtime_without_production_cutover

The next phase should be docs/smoke-only planning for a Cloudflare test route to website-edge nginx local runtime, or a separately approved Cloudflare test route apply. It must not perform production cutover, expose Proxmox management, migrate controller/queue, start workers, mutate DB/jobs, call CT101/model endpoints, install Docker/Node/npm, or rerun the Phase 14J-AG apply wrapper.
