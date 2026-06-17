# Phase 14J-FD - Website-edge sparse static clone verification

Date: 2026-06-17

## Phase marker

PHASE_14J_FD_WEBSITE_EDGE_SPARSE_STATIC_CLONE_VERIFICATION

## Purpose

Record the approved website-edge repo clone/copy and local-only public wrapper/static file verification.

This phase copied only public wrapper/static source paths needed for local filesystem inspection on website-edge VM 200.

## Previous checkpoint

Previous phase: Phase 14J-FC - Inspect public wrapper entrypoints and plan local-only clone smoke
Previous commit: 03a6b4e
Previous tag: controller-phase-14j-fc-inspect-public-wrapper-entrypoints-and-plan-local-only-clone-smoke-2026-06-17

## Execution location

The website-edge mutation was run inside the existing website-edge SSH session.

The repo record in this file is created on the laptop repo after FD completed on the VM.

## Approved mutation scope

Allowed inside website-edge:

- create a non-secret source directory
- clone/copy repo content at the verified Phase 14J-FC checkpoint
- use sparse checkout for public wrapper/static files
- perform local filesystem/static-file verification only

Explicitly not included:

- app deployment
- nginx config mutation
- systemd runtime creation
- Cloudflare test route
- Cloudflare production cutover
- Docker install
- cloudflared install
- Node/npm install
- controller/queue migration
- worker start
- runtime activation
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

## Initial FD attempt result

The first FD attempt cloned the repo and reached the expected checkpoint, but the validation used git ls-files, which showed tracked paths from the index outside the sparse worktree. That caused a validation failure even though the checkout reached the expected commit.

Evidence:

- head_now=03a6b4e
- tag_now=03a6b4e
- git_status_short=<clean>
- failure reason: sparse checkout scope validation used index data instead of actual filesystem files

## First FD repair result

The first repair re-applied cone-mode sparse checkout and validated actual filesystem files. This showed that cone-mode still left root-level files in the worktree, including runtime/controller-adjacent files and .env.example.

Evidence:

- head_now=03a6b4e
- tag_now=03a6b4e
- git_status_short=<clean>
- actual_worktree_file_count=30
- sensitive_filename_count=1
- runtime_path_count=2
- PHASE_14J_FD_RESULT=failed

No deployment, nginx config, systemd runtime, Cloudflare route, controller/queue migration, worker start, runtime activation, DB/job mutation, CT101 call, model/Ollama call, Tailscale policy mutation, or package install occurred during this failed repair.

## Successful FD repair 2 result

The successful repair switched the repo checkout to non-cone sparse checkout with exact public static path patterns:

- /frontend/wrapper-ui/**
- /frontend/study-ui/**

Location and OS guard:

- hostname=website-edge
- os_id=ubuntu
- os_version=26.04
- os_pretty=Ubuntu 26.04 LTS
- PASS: location guard matched website-edge Ubuntu 26.04

Checkpoint verification:

- head_before=03a6b4e
- tag_before=03a6b4e
- git_status_before=<clean>
- head_now=03a6b4e
- tag_now=03a6b4e
- git_status_short=<clean>
- PASS: repo checkout remains at verified Phase 14J-FC checkpoint

Sparse checkout verification:

- sparse_mode=non-cone
- sparse_scope=frontend/wrapper-ui,frontend/study-ui
- actual_worktree_file_count=18
- PASS: actual filesystem worktree limited to frontend/wrapper-ui and frontend/study-ui

Actual worktree files:

- frontend/study-ui/app.js
- frontend/study-ui/_headers
- frontend/study-ui/index.html
- frontend/study-ui/study-content.partial.html
- frontend/study-ui/study-dashboard.partial.html
- frontend/study-ui/styles.css
- frontend/wrapper-ui/app.js
- frontend/wrapper-ui/dev_server.py
- frontend/wrapper-ui/favicon.svg
- frontend/wrapper-ui/_headers
- frontend/wrapper-ui/index.html
- frontend/wrapper-ui/queued_chat_config.js
- frontend/wrapper-ui/queued_chat_status.js
- frontend/wrapper-ui/_redirects
- frontend/wrapper-ui/robots.txt
- frontend/wrapper-ui/router_shadow_read_stub.js
- frontend/wrapper-ui/sitemap.xml
- frontend/wrapper-ui/styles.css

Required public wrapper/static file verification:

- PASS: required static file present: frontend/wrapper-ui/index.html bytes=4789
- PASS: required static file present: frontend/wrapper-ui/app.js bytes=343918
- PASS: required static file present: frontend/wrapper-ui/styles.css bytes=60815
- PASS: required static file present: frontend/wrapper-ui/queued_chat_config.js bytes=911
- PASS: required static file present: frontend/wrapper-ui/queued_chat_status.js bytes=3840
- PASS: required static file present: frontend/wrapper-ui/router_shadow_read_stub.js bytes=6830

Optional study static file verification:

- PASS: optional study static file present: frontend/study-ui/index.html bytes=10732
- PASS: optional study static file present: frontend/study-ui/app.js bytes=56400
- PASS: optional study static file present: frontend/study-ui/styles.css bytes=17296
- PASS: optional study static file present: frontend/study-ui/study-content.partial.html bytes=8812
- PASS: optional study static file present: frontend/study-ui/study-dashboard.partial.html bytes=4829

Static reference verification:

- PASS: wrapper index references app.js
- PASS: wrapper index references styles.css
- PASS: wrapper index references queued_chat_config.js

Sensitive/runtime absence verification:

- sensitive_filename_count=0
- PASS: no obvious secret/key/env filenames in actual sparse worktree
- runtime_path_count=0
- PASS: runtime/controller/cloudflare/systemd files are not present in actual worktree

Required wrapper static checksums:

- 40d625f9bbdfe2fe63586831958e3b449ca9bb472e2afea87c20fc5f13b9ff71  frontend/wrapper-ui/index.html
- 1658e5f03e754ae8fa563a5e7f3655ffbd6a3d368b230080a57c579670da203b  frontend/wrapper-ui/app.js
- c1e629398a7bb15ae9735fdb287cc0636cd36504031a93605783a45b12b55d19  frontend/wrapper-ui/styles.css
- 5ea0fc240fbe42ee263e29a730e119b11e29759500dd0764f7ae37adff77765b  frontend/wrapper-ui/queued_chat_config.js
- 078d359be4f17fd0261e7a1cb3ccf3ec6e691d531e1c450806fdc502ee8b227d  frontend/wrapper-ui/queued_chat_status.js
- fc0297e45a1a5eee42fbddb5cbc78b909506dfee010a3ad1b23423683ef73d29  frontend/wrapper-ui/router_shadow_read_stub.js

Forbidden command check:

- PASS: command absent after fd: docker
- PASS: command absent after fd: cloudflared
- PASS: command absent after fd: node
- PASS: command absent after fd: npm

Final result:

- PHASE_14J_FD_RESULT=passed
- phase_exit_code=0

## Local FD report written on website-edge

The successful VM-side command wrote:

- PHASE_14J_FD_WEBSITE_EDGE_REPO_CLONE_COPY_LOCAL_STATIC_VERIFICATION
- head_now=03a6b4e
- tag_now=03a6b4e
- git_status_short=<clean>
- sparse_mode=non-cone
- sparse_scope=frontend/wrapper-ui,frontend/study-ui
- actual_worktree_file_count=18
- actual_worktree_scope_verified=yes
- required_files_present=yes
- sensitive_filename_count=0
- runtime_path_count=0
- app_deployment_performed=no
- nginx_config_mutation_performed=no
- systemd_runtime_creation_performed=no
- cloudflare_test_route_performed=no
- cloudflare_production_cutover_performed=no
- docker_install_performed=no
- cloudflared_install_performed=no
- node_npm_install_performed=no
- controller_queue_migration_performed=no
- worker_start_performed=no
- runtime_activation_performed=no
- production_db_job_mutation_performed=no
- ct101_call_performed=no
- model_ollama_endpoint_call_performed=no
- tailscale_acl_grants_tag_mutation_performed=no
- tailscale_ssh_mode_enablement_performed=no
- phase_14j_ag_apply_wrapper_rerun_performed=no

## Current state after FD

- website-edge has a non-cone sparse checkout at the verified Phase 14J-FC checkpoint.
- Actual worktree is limited to frontend/wrapper-ui and frontend/study-ui.
- Required wrapper static files are present and checksummed.
- Optional Study static files are present.
- No obvious secret/key/env filenames are in the actual sparse worktree.
- Runtime/controller/cloudflare/systemd files are not present in the actual sparse worktree.
- Docker remains absent.
- cloudflared remains absent.
- Node/npm remain absent.
- No app deployment occurred.
- No nginx config mutation occurred.
- No systemd runtime creation occurred.
- No Cloudflare route/cutover occurred.
- No controller/queue migration occurred.
- No worker start/runtime activation occurred.
- No production DB/job mutation occurred.
- No CT101/model/Ollama call occurred.
- No Tailscale ACL/grants/tag mutation or Tailscale SSH mode enablement occurred.
- No rerun of Phase 14J-AG apply wrapper occurred.

## Result

PHASE_14J_FD_RESULT=website_edge_sparse_static_clone_verification_recorded

## Next safe phase

NEXT_SAFE_PHASE=plan_local_loopback_static_server_smoke_without_nginx_or_cloudflare

The next phase should be docs/smoke-only planning for a local loopback static server smoke, or a separately approved VM-only local loopback smoke. It should not mutate nginx configuration, create a systemd runtime, install Node/npm, install cloudflared, deploy publicly, or change Cloudflare.
