# Phase 14J-FJ - Read-only Cloudflare route and tunnel inventory

Date: 2026-06-17

## Phase marker

PHASE_14J_FJ_READ_ONLY_CLOUDFLARE_ROUTE_AND_TUNNEL_INVENTORY

## Purpose

Record the approved read-only Cloudflare route and tunnel inventory step before any Cloudflare test-route apply.

This phase inspected repo-local Cloudflare and public route artifacts and local Cloudflare tooling/config presence in sanitized read-only mode.

No Cloudflare remote API call was performed.

## Previous checkpoint

Previous phase: Phase 14J-FI - Plan Cloudflare test-route feasibility without production cutover
Previous commit: beb988d
Previous tag: controller-phase-14j-fi-plan-cloudflare-test-route-feasibility-without-production-cutover-2026-06-17

## Mutation scope

MUTATION_SCOPE=laptop_repo_read_only_cloudflare_public_route_inventory_docs_smoke_commit_tag_push

This phase performed:

- repo-local read-only inventory
- sanitized marker scan
- local tool presence check
- documentation
- smoke script creation
- commit, tag, and push

This phase did not perform:

- website-edge mutation
- Proxmox mutation
- nginx config mutation
- systemd runtime creation
- app deployment
- Cloudflare route creation/update/delete
- Cloudflare production cutover
- Cloudflare test route apply
- cloudflared install
- Docker/Node/npm install
- controller/queue migration
- worker start
- runtime activation
- production DB/job mutation
- CT101 call
- model/Ollama endpoint call
- Tailscale ACL/grants/tag mutation
- Tailscale SSH mode enablement
- subnet route
- exit node
- Phase 14J-AG apply wrapper rerun

## Sanitization policy

SANITIZED_OUTPUT_ONLY=yes
SECRETS_TOKENS_RAW_IPS_AUTH_URLS_REDACTED=yes
ACCOUNT_IDS_REDACTED_IF_PRESENT=yes
REMOTE_CLOUDFLARE_API_CALL_PERFORMED=no

The inventory intentionally avoided printing Cloudflare secrets, raw IPs, auth URLs, API tokens, or account IDs.

## Repo-local inventory summary

RELEVANT_CLOUDFLARE_PUBLIC_ROUTE_FILE_COUNT=2221
SANITIZED_MARKER_COUNT=240

CLOUDFLARE_EDGE_PUBLIC_PROXY_PRESENT=yes
CLOUDFLARE_WORKER_SRC_PRESENT=yes
CLOUDFLARE_WORKER_PACKAGE_PRESENT=yes
PUBLIC_GATEWAY_PRESENT=yes
PUBLIC_ROUTE_DOCS_PRESENT=yes
WRAPPER_STATIC_HEADERS_PRESENT=yes
WRAPPER_STATIC_REDIRECTS_PRESENT=yes

## Local tooling presence check

CLOUDFLARED_PRESENT=yes
CLOUDFLARED_VERSION_SANITIZED=cloudflared version 2026.5.2 (built 2026-05-27-10:38 UTC)
WRANGLER_PRESENT=no
WRANGLER_VERSION_SANITIZED=<absent>
LOCAL_CLOUDFLARED_CONFIG_DIR_PRESENT=yes
LOCAL_CLOUDFLARED_CONFIG_FILE_COUNT=4

LOCAL_CLOUDFLARED_CONFIG_CONTENT_READ=no
REMOTE_CLOUDFLARE_API_CALL_PERFORMED=no
CLOUDFLARE_ROUTE_MUTATION_PERFORMED=no
CLOUDFLARE_TEST_ROUTE_APPLY_PERFORMED=no
CLOUDFLARED_INSTALL_PERFORMED=no

## Repo-local relevant file inventory

- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104550/edge_controller.py.bak-remove-duplicate-companion-routes-2026-06-05-104508
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-104701/edge_controller.py.bak-remove-duplicate-companion-routes-actual-2026-06-05-104628
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-105000/public_gateway.py.bak-remove-duplicate-system-routes-2026-06-05-104918
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/index.js.bak-ad-status-route-2026-06-05-122025
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-122223/public_gateway.py.bak-ad-status-public-proxy-2026-06-05-122020
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-123508/public_gateway.py.bak-google-gpt-client-claim-2026-06-05-123359
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143139/public_gateway.py.bak-change-password-2026-06-05-142944
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/controller-refactor-2026-06-05-143543/public_gateway.py.bak-password-reset-2026-06-05-143339
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-pause-after-worker-start-2026-06-02-140247
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-pause-after-worker-start-2026-06-02-140247.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-start-workers-2026-06-02-173419
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-start-workers-2026-06-02-173419.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-start-workers-2026-06-02-173457
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-auto-start-workers-2026-06-02-173457.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-defensive-worker-row-to-dict-2026-06-03-112630
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-defensive-worker-row-to-dict-2026-06-03-112630.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-mark-worker-offline-on-stop-2026-06-02-220009
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-mark-worker-offline-on-stop-2026-06-02-220009.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-rewrite-worker-row-to-dict-2026-06-03-112448
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-rewrite-worker-row-to-dict-2026-06-03-112448.bak-gemma4-e4b-2026-06-03-180023
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-study-health-route-2026-06-04-073207
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-wake-and-start-worker-2026-06-02-165921
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-wake-and-start-worker-2026-06-02-165921.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-registry-2026-06-02-101325
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-registry-2026-06-02-101325.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-row-offline-health-rewrite-2026-06-02-225720
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-row-offline-health-rewrite-2026-06-02-225720.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-start-2026-06-02-001641
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-start-2026-06-02-001641.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-start-endpoints-2026-06-02-134830
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-start-endpoints-2026-06-02-134830.bak-gemma4-e4b-2026-06-03-180023
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-start-endpoints-2026-06-02-134836
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/edge_controller.py.bak-worker-start-endpoints-2026-06-02-134836.bak-gemma4-e4b-2026-06-03-180022
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-admin-me-endpoints-2026-06-04-120540
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-admin-system-session-me-2026-06-04-121615
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-auth-routes-2026-06-03-131536
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-block-public-ad-rewards-2026-06-04-145410
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-card-stats-review-queue-routes-2026-06-03-135734
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-companion-chat-routes-2026-06-03-162354
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-companion-study-grade-route-2026-06-03-160628
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-db-admin-no-env-required-2026-06-04-130846
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-db-admin-role-check-2026-06-04-124459
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-forward-auth-header-2026-06-03-131949
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-public-admin-status-2026-06-04-120115
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-study-routes-2026-06-03-134458
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-system-middleware-2026-06-04-075344
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-system-proxy-2026-06-04-074850
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-system-proxy-2026-06-04-075103
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-system-secret-names-2026-06-04-075548
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-system-status-public-read-2026-06-04-075716
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-system-status-public-read-2026-06-04-075726
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-system-status-public-read-2026-06-04-075823
- .cleanup-archive/2026-06-10-155808/bak-files/.cleanup-backups/root-bak-files-2026-06-05-095635/public_gateway.py.bak-user-job-list-route-2026-06-03-132820
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/src/index.js.bak-companion-chat-routes-2026-06-03-162423
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/src/index.js.bak-companion-study-grade-2026-06-03-160655
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/src/index.js.bak-dedup-system-routes-2026-06-04-074842
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/src/index.js.bak-email-verify-worker-route-2026-06-05-140818
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/src/index.js.bak-force-system-routes-2026-06-04-074511
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/src/index.js.bak-system-public-admin-routes-2026-06-04-120352
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/src/index.js.bak-system-routes-2026-06-04-074231
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/wrangler.jsonc.bak-api-auth-route-2026-06-05-140518
- .cleanup-archive/2026-06-10-155808/bak-files/cloudflare/edge-public-proxy/wrangler.jsonc.bak-remove-auth-worker-route-2026-06-10-145704
- .cleanup-archive/2026-06-10-155808/bak-files/docs/deploy.md.bak-bump-app-version-20260609200419
- .cleanup-archive/2026-06-10-155808/bak-files/edge_controller.py.bak-stage5g24-worker-status-2026-06-08-195059
- .cleanup-archive/2026-06-10-155808/bak-files/edge_controller.py.bak-stage5g24-worker-status-safe-2026-06-08-195231
- .cleanup-archive/2026-06-10-155808/bak-files/edge_controller.py.bak-stage5g26-normalized-worker-detail-2026-06-08-200659
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/study-ui/app.js.bak-default-study-route-2026-06-10-153948
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/study-ui/_headers.bak-csp-auth-status-2026-06-03-200727
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/study-ui/_headers.bak-path-based-2026-06-03-201452
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/app.js.bak-auth-cookie-for-route-proxy-2026-06-04-234605
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/app.js.bak-fix-admin-support-route-loading-2026-06-04-164329
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/app.js.bak-global-cloudflare-html-sanitizer-2026-06-07-113030
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/app.js.bak-hide-cloudflare-html-companion-2026-06-07-112701
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/app.js.bak-login-private-route-refresh-2026-06-05-081707
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/app.js.bak-stage5g25-worker-ui-detail-2026-06-08-200251
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-admin-support-routes-2026-06-04-162211
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-ad-reward-local-routes-2026-06-04-145428
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-apply-power-policy-route-2026-06-04-205439
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-auth-extra-routes-2026-06-07-105207
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-auth-me-route-2026-06-10-144831
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-auth-me-route-2026-06-10-144947
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-ensure-admin-support-routes-2026-06-04-164359
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-expand-cookie-bearer-routes-2026-06-10-152618
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-force-auth-me-route-2026-06-10-145055
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-force-spa-routes-2026-06-04-230523
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-presence-route-2026-06-04-165522
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-route-auth-to-ct101-2026-06-05-001011
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/dev_server.py.bak-web-presence-routes-2026-06-04-203338
- .cleanup-archive/2026-06-10-155808/bak-files/frontend/wrapper-ui/_headers.bak-remove-old-worker-2026-06-04-233350
- .cleanup-archive/2026-06-10-155808/bak-files/ops/scripts/rotate-cloudflare-edge-tunnel.sh.bak-safer-2026-06-03-112008
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-auth-me-target-fix-2026-06-10-145946
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-cookie-auth-fix-2026-06-10-140741
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-cookie-setcookie-forward-2026-06-10-143838
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-cookie-setcookie-forward-2026-06-10-144430
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-email-verification-public-api-proxy-2026-06-05-140027
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-inject-api-key-cookie-2026-06-10-143651
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-public-auth-me-bridge-2026-06-10-145840
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-remove-duplicate-system-proxy-helper-2026-06-07-103029
- .cleanup-archive/2026-06-10-155808/bak-files/public_gateway.py.bak-system-status-head-support-2026-06-07-105448
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/benchmark.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/browser-async.d.ts
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/browser-async.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/browser.d.ts
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/browser.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/changelog.md
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/disposable.d.ts
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/disposable.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/disposable.js.map
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/disposable.test.d.ts
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/disposable.test.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/disposable.test.js.map
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-fn.d.ts
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-fn.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-fn.js.map
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-instance.d.ts
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-instance.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-instance.js.map
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-reader.d.ts
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-reader.js
- .cleanup-archive/2026-06-10-155808/cloudflare-worker/cloudflare/edge-public-proxy/node_modules/blake3-wasm/dist/base/hash-reader.js.map

## Sanitized marker scan excerpt

- cloudflare/edge-public-proxy/package.json:7:    "deploy": "wrangler deploy",
- cloudflare/edge-public-proxy/package.json:8:    "dev": "wrangler dev"
- cloudflare/edge-public-proxy/package.json:11:    "wrangler": "^4.0.0"
- cloudflare/edge-public-proxy/wrangler.jsonc:2:  "$schema": "node_modules/wrangler/config-schema.json",
- cloudflare/edge-public-proxy/wrangler.jsonc:7:    "EDGE_API_BASE_URL": "<redacted-url>"
- cloudflare/edge-public-proxy/wrangler.jsonc:9:  "routes": [
- cloudflare/edge-public-proxy/wrangler.jsonc:11:      "pattern": "alexhartel.com/api/auth/*",
- cloudflare/edge-public-proxy/wrangler.jsonc:12:      "zone_name": "alexhartel.com"
- cloudflare/edge-public-proxy/src/index.js:1:// APC_PHASE_14J_CD_PUBLIC_GATEWAY_ROUTE_OWNERSHIP_CONTRACT: static route ownership marker only; no runtime behavior change.
- cloudflare/edge-public-proxy/src/index.js:2:// APC_PHASE_14J_CB_STATIC_ROUTE_CONTRACT: public gateway contract marker only; no runtime behavior change.
- cloudflare/edge-public-proxy/src/index.js:33:  // System status / power control routes
- cloudflare/edge-public-proxy/src/index.js:87:  return ALLOWED_ROUTES.some((route) => {
- cloudflare/edge-public-proxy/src/index.js:88:    return route.method === method.toUpperCase() && route.pattern.test(path);
- cloudflare/edge-public-proxy/src/index.js:95: * This function maps public API routes (/api/*) to controller backend routes.
- cloudflare/edge-public-proxy/src/index.js:98: * - Controller-owned public routes are translated to /public/* and /system/* on the edge controller.
- cloudflare/edge-public-proxy/src/index.js:100: * - Study/companion routes are proxied as /public/study/* and /public/companion/* for public gateway compatibility.
- cloudflare/edge-public-proxy/src/index.js:101: * - These public gateway routes are legacy bridges and must not become the authoritative data owner.
- cloudflare/edge-public-proxy/src/index.js:102: * - Do not add direct model routes here; model execution is CT101-owned backend logic.
- cloudflare/edge-public-proxy/src/index.js:113:  // Controller account authentication routes
- docs/chat-only-migration-map.md:68:No production chat route should require laptop queue unless LAPTOP_CHAT_QUEUE_ENABLED=1.
- docs/chat-only-migration-map.md:94:- route_source
- docs/chat-only-migration-map.md:101:The CT101 worker should return result_json with:
- docs/chat-only-migration-map.md:105:- worker
- docs/chat-only-migration-map.md:161:2. leave current chat route/path active
- docs/chat-only-migration-map.md:163:4. do not delete CT101 chat routes
- docs/chat-only-migration-map.md:201:- old CT101 queue routes
- docs/chat-only-migration-map.md:205:- obsolete wrapper compatibility routes
- docs/chat-only-migration-map.md:213:- add production queued chat route
- docs/chat-only-migration-map.md:217:- change CT101 worker loop
- docs/chat-only-migration-map.md:219:- start persistent workers
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:3:Phase 14I-AT drafts the future apply runbook for the router shadow evidence SQL artifact.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:15:It does not expose router shadow output to the browser.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:16:It does not persist router shadow evidence at runtime.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:17:It does not enable router model selection.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:27:`ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:31:- `/api/chat/queued` calls `_phase14iag_queued_chat_router_shadow_decision(guard_payload)`.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:35:- No router shadow output is returned to the browser.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:36:- No router shadow evidence is persisted by runtime code.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:37:- No writer exists for router shadow evidence.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:56:`ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:68:- apply only `ops/db/laptop-app-schema-v3-router-shadow-evidence.sql`,
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:80:`bash ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh`
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:112:- `queued_chat_router_shadow_evidence` table exists,
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:113:- `stage-14i-router-shadow-evidence` migration marker exists,
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:138:- router activation is included,
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:153:Applying the SQL artifact must not enable router model selection.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:155:Router activation remains parked until shadow evidence, lane-worker safety, and scheduler safety are proven separately.
- docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md:170:- no route behavior is changed,
- docs/phase-11v-lane-aware-worker-claim-source-map.md:3:Phase 11V maps the current worker claim path before adding lane-aware scheduling.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:14:Phase 11V is documentation/source-map only. It does not change worker claim behavior.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:19:Main helper: LaptopQueueClient.claim_next_job(worker_id, job_type=None)
- docs/phase-11v-lane-aware-worker-claim-source-map.md:29:7. Sets assigned_worker_id.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:30:8. Sets the worker row to busy and stores current_job_id.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:32:Current claim query does not filter by model_tier, model_lane, queue_lane, requested_model, worker lane capacity, or worker model availability.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:40:Current request fields: worker_id and job_type.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:44:## Current worker registry shape
- docs/phase-11v-lane-aware-worker-claim-source-map.md:46:Current app_workers fields include id, name, status, capabilities_json, current_job_id, worker_node_id, last_heartbeat_at, idle_shutdown_seconds, and timestamps.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:48:Current app_worker_nodes fields include id, name, node_type, host_machine, enabled, status, capabilities, last_seen_at, and timestamps.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:52:## Current CT101 managed worker runtime
- docs/phase-11v-lane-aware-worker-claim-source-map.md:54:Current CT101 service: ai-platform-laptop-queue-worker.service.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:55:Current service command: /opt/ai-platform/ops/runtime/laptop-queue-worker-loop.sh.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:58:Current CT101 worker env includes:
- docs/phase-11v-lane-aware-worker-claim-source-map.md:66:Current safety state: one job per bounded poller run, no parallel worker claim, no lane-aware worker selection, and no Ollama parallelism change.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:82:5. Add worker heartbeat capability metadata using existing capabilities_json.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:84:7. Only later raise worker or Ollama parallelism.
- docs/phase-11v-lane-aware-worker-claim-source-map.md:88:Future request shape should add queue_lane as an optional field alongside worker_id and job_type.
- docs/cleanup/stage-5o7-manual-browser-ui-checklist-2026-06-11.md:24:- Public and private routes load quickly.
- docs/cleanup/stage-5o7-manual-browser-ui-checklist-2026-06-11.md:39:- App route 404s
- docs/cleanup/stage-5o22-remove-study-extra-stylesheet-link-2026-06-11.md:20:- route-scoped Study logo/header normalization in the shared wrapper stylesheet
- docs/cleanup/stage-5l4i-queued-chat-real-user-smoke-fix-2026-06-10.md:13:- worker: ct101-stage5g21-managed-browser
- docs/cleanup/stage-5l4i-queued-chat-real-user-smoke-fix-2026-06-10.md:19:The wrapper now resolves the edgeStudyToken cookie server-side through the controller session endpoint and forwards trusted X-Edge-* headers for direct queued-chat routes.
- docs/cleanup/stage-5l4i-queued-chat-real-user-smoke-fix-2026-06-10.md:35:CT101 queue worker processed the real queued job successfully.
- docs/cleanup/stage-5l4i-queued-chat-real-user-smoke-fix-2026-06-10.md:37:The worker service is active from manual start but remains disabled for permanent boot enablement.
- docs/cleanup/stage-5l4i-queued-chat-real-user-smoke-fix-2026-06-10.md:43:- Decide whether to enable ai-platform-laptop-queue-worker.service permanently.
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:5:frontend/wrapper-ui/styles.css:1419:body:not([data-current-route="/credits"]) header a[href="/credits"]:not([aria-current="page"]),
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:6:frontend/wrapper-ui/styles.css:1421:body:not([data-current-route="/credits"]) .topbar a[href="/credits"]:not([aria-current="page"]),
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:7:frontend/wrapper-ui/styles.css:1423:body:not([data-current-route="/credits"]) .main-nav a[href="/credits"]:not([aria-current="page"]),
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:8:frontend/wrapper-ui/styles.css:1425:body:not([data-current-route="/credits"]) .route-nav a[href="/credits"]:not([aria-current="page"]),
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:11:frontend/wrapper-ui/index.html:12:    <a class="brand logo-only" href="/" data-route="/" aria-label="AlexHartel AI Platform home">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:12:frontend/wrapper-ui/index.html:24:      <a href="/study" data-route="/study">Study</a>
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:13:frontend/wrapper-ui/index.html:25:      <a href="/companion" data-route="/companion">Companion</a>
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:14:frontend/wrapper-ui/index.html:26:      <a href="/profile" data-route="/profile">Profile</a>
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:15:frontend/wrapper-ui/index.html:27:      <a href="/support" data-route="/support">Support</a>
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:16:frontend/wrapper-ui/index.html:28:      <a id="adminNavLink" class="hidden" href="/admin" data-route="/admin">Admin</a>
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:17:frontend/wrapper-ui/index.html:29:      <a href="/system" data-route="/system" id="systemNavLink">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:27:frontend/wrapper-ui/app.js:4555:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:28:frontend/wrapper-ui/app.js:4560:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:29:frontend/wrapper-ui/app.js:4565:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:30:frontend/wrapper-ui/app.js:4570:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:46:347:  document.querySelectorAll("[data-route]").forEach((link) => {
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:47:348:    link.classList.toggle("active", link.getAttribute("data-route") === path);
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:48:399:  const supportLink = document.querySelector('[data-route="/support"]');
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:95:4149:  const link = event.target.closest("[data-route]");
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:96:4152:  const path = link.getAttribute("data-route");
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:106:4235:  const supportLink = document.querySelector('[data-route="/support"]');
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:107:4555:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:108:4560:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:109:4565:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:110:4570:      <a class="feature-card" href="/support" data-route="/support">
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:121:5249:  const link = event.target.closest?.("[data-route]");
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:122:5257:  history.pushState({}, "", route);
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:140:6901:    const dataRoute = anchor.getAttribute("data-route");
- docs/cleanup/stage-5o11-deep-route-reload-inventory-2026-06-11.md:141:6942:      "header a, .topbar a, .main-nav a, .route-nav a, .nav a, .tabs a, .tabbar a, [data-route]"
- docs/cleanup/stage-5j8-finish-active-wrapper-stale-reference-cleanup-2026-06-10.md:12:- Kept `cloudflare/edge-public-proxy/*` in the repository.
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:4:12:    <a class="brand logo-only" href="/" data-route="/" aria-label="AlexHartel AI Platform home">
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:6:24:      <a href="/study" data-route="/study">Study</a>
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:7:25:      <a href="/companion" data-route="/companion">Companion</a>
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:8:26:      <a href="/profile" data-route="/profile">Profile</a>
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:9:27:      <a href="/support" data-route="/support">Support</a>
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:10:28:      <a id="adminNavLink" class="hidden" href="/admin" data-route="/admin">Admin</a>
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:11:29:      <a href="/system" data-route="/system" id="systemNavLink">
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:12:34:      <button id="creditsPill" class="credits-pill hidden" type="button" data-route="/credits" title="View credits and plans">
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:14:## App route/nav logic
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:29:1368:.topbar a[data-route],
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:30:1369:.main-nav a[data-route],
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:31:1370:.route-nav a[data-route],
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:34:1377:.route-nav a[href^="/"],
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:35:1387:header a[data-route][aria-current="page"],
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:36:1388:.topbar a[data-route].active,
- docs/cleanup/stage-5o13-header-nav-inventory-2026-06-11.md:37:1389:.topbar a[data-route].is-active,

## Inventory conclusion

The repo contains Cloudflare/public route related artifacts and wrapper static routing artifacts, but this phase did not mutate Cloudflare.

Because website-edge nginx is currently loopback-only on port 18080 and cloudflared is absent on website-edge, the next step should not be production cutover.

Before any test-route apply, the transport path must be explicitly approved and documented.

## Required gates before any test-route apply

FUTURE_TEST_ROUTE_GATE_TRANSPORT_PATH_EXPLICIT=yes
FUTURE_TEST_ROUTE_GATE_TEST_HOSTNAME_ONLY=yes
FUTURE_TEST_ROUTE_GATE_NO_APEX_CUTOVER=yes
FUTURE_TEST_ROUTE_GATE_NO_PRODUCTION_ROUTE_REPLACEMENT=yes
FUTURE_TEST_ROUTE_GATE_ROLLBACK_PLAN_REQUIRED=yes
FUTURE_TEST_ROUTE_GATE_SANITIZED_OUTPUT_ONLY=yes
FUTURE_TEST_ROUTE_GATE_NO_PROXMOX_PUBLIC_CONTROLS=yes

## Denied future scope unless separately approved

FUTURE_TEST_ROUTE_DENY_PRODUCTION_CUTOVER=yes
FUTURE_TEST_ROUTE_DENY_APEX_ROUTE_REPLACEMENT=yes
FUTURE_TEST_ROUTE_DENY_PRIMARY_PUBLIC_ROUTE_REPLACEMENT=yes
FUTURE_TEST_ROUTE_DENY_PROXMOX_PUBLIC_EXPOSURE=yes
FUTURE_TEST_ROUTE_DENY_CONTROLLER_QUEUE_MIGRATION=yes
FUTURE_TEST_ROUTE_DENY_WORKER_START=yes
FUTURE_TEST_ROUTE_DENY_RUNTIME_ACTIVATION=yes
FUTURE_TEST_ROUTE_DENY_PRODUCTION_DB_JOB_MUTATION=yes
FUTURE_TEST_ROUTE_DENY_CT101_CALL=yes
FUTURE_TEST_ROUTE_DENY_MODEL_OLLAMA_ENDPOINT_CALL=yes
FUTURE_TEST_ROUTE_DENY_DOCKER_INSTALL=yes
FUTURE_TEST_ROUTE_DENY_NODE_NPM_INSTALL=yes
FUTURE_TEST_ROUTE_DENY_TAILSCALE_ACL_GRANTS_TAG_MUTATION=yes
FUTURE_TEST_ROUTE_DENY_TAILSCALE_SSH_MODE_ENABLEMENT=yes
FUTURE_TEST_ROUTE_DENY_SUBNET_ROUTES=yes
FUTURE_TEST_ROUTE_DENY_EXIT_NODE=yes
FUTURE_TEST_ROUTE_DENY_SECRETS_RAW_IPS_AUTH_URLS=yes
FUTURE_TEST_ROUTE_DENY_14J_AG_APPLY_WRAPPER_RERUN=yes

## Result

PHASE_14J_FJ_RESULT=read_only_cloudflare_route_and_tunnel_inventory_recorded

## Next safe phase

NEXT_SAFE_PHASE=plan_explicit_cloudflare_test_route_transport_without_production_cutover

The next phase should remain docs/smoke-only planning unless the user separately approves a specific test hostname and transport path.
