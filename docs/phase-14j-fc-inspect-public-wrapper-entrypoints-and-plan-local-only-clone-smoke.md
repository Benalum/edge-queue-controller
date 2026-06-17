# Phase 14J-FC - Inspect public wrapper entrypoints and plan local-only clone smoke

Date: 2026-06-17

## Phase marker

PHASE_14J_FC_INSPECT_PUBLIC_WRAPPER_ENTRYPOINTS_AND_PLAN_LOCAL_ONLY_CLONE_SMOKE

## Purpose

Record a docs/smoke-only checkpoint after Phase 14J-FB.

This phase inspects the laptop repository for public wrapper/static edge entrypoint candidates and records the next safe website-edge clone/local-smoke plan.

## Previous checkpoint

- Previous phase: Phase 14J-FB - Install baseline packages on website-edge
- Previous commit: `66facfc`
- Previous tag: `controller-phase-14j-fb-install-baseline-packages-on-website-edge-2026-06-17`

## Mutation scope

MUTATION_SCOPE=docs_smoke_only_public_wrapper_entrypoint_inspection_plan

Allowed:

- read-only laptop repo inspection
- docs/smoke creation
- commit/tag/push

Not allowed and not performed:

- WEBSITE_EDGE_MUTATION_PERFORMED=no
- PROXMOX_MUTATION_PERFORMED=no
- APP_CLONE_PERFORMED=no
- APP_DEPLOYMENT_PERFORMED=no
- NGINX_CONFIG_MUTATION_PERFORMED=no
- CLOUDFLARE_TEST_ROUTE_PERFORMED=no
- CLOUDFLARE_PRODUCTION_CUTOVER_PERFORMED=no
- DOCKER_INSTALL_PERFORMED=no
- CLOUDFLARED_INSTALL_PERFORMED=no
- NODE_NPM_INSTALL_PERFORMED=no
- TAILSCALE_ACL_GRANTS_TAG_MUTATION_PERFORMED=no
- TAILSCALE_SSH_MODE_ENABLEMENT_PERFORMED=no
- CONTROLLER_QUEUE_MIGRATION_PERFORMED=no
- WORKER_START_PERFORMED=no
- RUNTIME_ACTIVATION_PERFORMED=no
- PRODUCTION_DB_JOB_MUTATION_PERFORMED=no
- CT101_CALL_PERFORMED=no
- MODEL_OLLAMA_ENDPOINT_CALL_PERFORMED=no
- PHASE_14J_AG_APPLY_WRAPPER_RERUN_PERFORMED=no

## FB baseline now available on website-edge

WEBSITE_EDGE_BASELINE_PACKAGES_INSTALLED=yes  
WEBSITE_EDGE_QEMU_GUEST_AGENT_ACTIVE=yes  
WEBSITE_EDGE_PYTHON3_VENV_INSTALLED=yes  
WEBSITE_EDGE_NGINX_ACTIVE=yes  
WEBSITE_EDGE_NGINX_LOCAL_HTTP_200=yes  

## Public wrapper/static edge target

WEBSITE_EDGE_RUNTIME_GOAL=public_wrapper_static_edge_first  
WEBSITE_EDGE_MUST_NOT_RUN_FULL_CONTROLLER=yes  
WEBSITE_EDGE_MUST_NOT_RUN_QUEUE=yes  
WEBSITE_EDGE_MUST_NOT_RUN_WORKERS=yes  
WEBSITE_EDGE_MUST_NOT_RUN_MODEL_ENDPOINTS=yes  
WEBSITE_EDGE_MUST_NOT_EXPOSE_PROXMOX_OR_POWER_CONTROLS=yes  

## Future clone/local-smoke plan

FUTURE_APPROVAL_REQUIRED_BEFORE_WEBSITE_EDGE_CLONE=yes

The next website-edge mutation phase should be separately approved before it runs. Its narrow scope should be limited to:

1. Create a non-secret source directory on `website-edge`.
2. Clone or copy only the repository source needed to inspect/run the public wrapper path.
3. Do not install Docker, cloudflared, Node/npm, or extra packages unless a later phase proves and approves the need.
4. Do not change nginx configuration yet.
5. Do not create a systemd runtime yet.
6. Do not expose anything through Cloudflare yet.
7. Run only local loopback smoke checks on `website-edge`.
8. Preserve rollback by leaving existing laptop/public path untouched.

## Future website-edge clone phase denied scope

FUTURE_CLONE_PHASE_DENY_CLOUDFLARE_CUTOVER=yes  
FUTURE_CLONE_PHASE_DENY_CLOUDFLARED_INSTALL=yes  
FUTURE_CLONE_PHASE_DENY_NGINX_CONFIG_MUTATION=yes  
FUTURE_CLONE_PHASE_DENY_CONTROLLER_QUEUE_MIGRATION=yes  
FUTURE_CLONE_PHASE_DENY_WORKER_START=yes  
FUTURE_CLONE_PHASE_DENY_RUNTIME_ACTIVATION=yes  
FUTURE_CLONE_PHASE_DENY_PRODUCTION_DB_JOB_MUTATION=yes  
FUTURE_CLONE_PHASE_DENY_CT101_MODEL_CALLS=yes  
FUTURE_CLONE_PHASE_DENY_TAILSCALE_POLICY_MUTATION=yes  

## Generated sanitized read-only inventory

The inventory below was generated from tracked files in the laptop repo only. It is used to identify candidate public wrapper/static files before any website-edge clone or deployment.

```text
=== tracked candidate web/runtime files ===
cloudflare/edge-public-proxy/package.json
cloudflare/edge-public-proxy/src/index.js
edge_controller.py
frontend/study-ui/app.js
frontend/study-ui/index.html
frontend/study-ui/study-content.partial.html
frontend/study-ui/study-dashboard.partial.html
frontend/study-ui/styles.css
frontend/wrapper-ui/app.js
frontend/wrapper-ui/index.html
frontend/wrapper-ui/queued_chat_config.js
frontend/wrapper-ui/queued_chat_status.js
frontend/wrapper-ui/router_shadow_read_stub.js
frontend/wrapper-ui/styles.css
ops/systemd/ct101-llm-stack-compose.service
ops/systemd/edge-queue-controller.service
ops/systemd/edge-queue-power-auto-tick.service
ops/systemd/edge-queue-power-idle-tick.service
ops/systemd/edge-queue-public-gateway.service
ops/systemd/edge-queue-remediation-tick.service
ops/systemd/edge-queue-scheduler-tick.service
requirements.txt

=== tracked public wrapper marker grep ===
.env.example:64:PUBLIC_BASE_URL=https://alexhartel.com
.env.example:72:EMAIL_FROM=no-reply@alexhartel.com
cloudflare/edge-public-proxy/src/index.js:1:// APC_PHASE_14J_CD_PUBLIC_GATEWAY_ROUTE_OWNERSHIP_CONTRACT: static route ownership marker only; no runtime behavior change.
cloudflare/edge-public-proxy/src/index.js:7:  { method: "POST", pattern: /^\/api\/auth\/login$/ },
cloudflare/edge-public-proxy/src/index.js:20:  { method: "POST", pattern: /^\/api\/study\/decks$/ },
cloudflare/edge-public-proxy/src/index.js:21:  { method: "GET",  pattern: /^\/api\/study\/decks$/ },
cloudflare/edge-public-proxy/src/index.js:22:  { method: "POST", pattern: /^\/api\/study\/decks\/[0-9]+\/cards$/ },
cloudflare/edge-public-proxy/src/index.js:23:  { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/cards$/ },
cloudflare/edge-public-proxy/src/index.js:24:  { method: "POST", pattern: /^\/api\/study\/cards\/[0-9]+\/reviews$/ },
cloudflare/edge-public-proxy/src/index.js:25:  { method: "GET",  pattern: /^\/api\/study\/progress$/ },
cloudflare/edge-public-proxy/src/index.js:26:  { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/card-stats$/ },
cloudflare/edge-public-proxy/src/index.js:27:  { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/review-queue$/ },
cloudflare/edge-public-proxy/src/index.js:29:  { method: "POST", pattern: /^\/api\/companion\/study\/grade$/ },
cloudflare/edge-public-proxy/src/index.js:30:  { method: "GET",  pattern: /^\/api\/companion\/context$/ },
cloudflare/edge-public-proxy/src/index.js:31:  { method: "POST", pattern: /^\/api\/companion\/chat$/ },
cloudflare/edge-public-proxy/src/index.js:99: * - CT101 remains the source of truth for study/companion/calendar private APIs and backend job execution.
cloudflare/edge-public-proxy/src/index.js:100: * - Study/companion routes are proxied as /public/study/* and /public/companion/* for public gateway compatibility.
cloudflare/edge-public-proxy/src/index.js:107: * - /api/study/* -> /public/study/* (public bridge; CT101 is source-of-truth)
cloudflare/edge-public-proxy/src/index.js:108: * - /api/companion/* -> /public/companion/* (public bridge; CT101 is source-of-truth)
cloudflare/edge-public-proxy/src/index.js:110: * - /api/system/* -> /system/* (controller-owned system status and power)
cloudflare/edge-public-proxy/src/index.js:129:  // CT101-owned study API, proxied as public bridge: /api/study/* -> /public/study/*
cloudflare/edge-public-proxy/src/index.js:131:  if (path.startsWith("/api/study/")) {
cloudflare/edge-public-proxy/src/index.js:132:    return path.replace("/api/study/", "/public/study/");
cloudflare/edge-public-proxy/src/index.js:135:  // CT101-owned companion API, proxied as public bridge: /api/companion/* -> /public/companion/*
cloudflare/edge-public-proxy/src/index.js:137:  if (path.startsWith("/api/companion/")) {
cloudflare/edge-public-proxy/src/index.js:138:    return path.replace("/api/companion/", "/public/companion/");
cloudflare/edge-public-proxy/src/index.js:146:  // Controller-owned system status and power: /api/system/* -> /system/*
cloudflare/edge-public-proxy/src/index.js:147:  if (path.startsWith("/api/system/")) {
cloudflare/edge-public-proxy/src/index.js:148:    return path.replace("/api/system/", "/system/");
cloudflare/edge-public-proxy/wrangler.jsonc:7:    "EDGE_API_BASE_URL": "https://edge-api.alexhartel.com"
cloudflare/edge-public-proxy/wrangler.jsonc:11:      "pattern": "alexhartel.com/api/auth/*",
cloudflare/edge-public-proxy/wrangler.jsonc:12:      "zone_name": "alexhartel.com"
create_stage5p_inspection_pack.sh:100:p = Path("frontend/wrapper-ui/app.js")
create_stage5p_inspection_pack.sh:102:    print("frontend/wrapper-ui/app.js missing")
docs/chat-assistant-message-idempotency-schema-plan.md:152:- obsolete wrapper compatibility routes
docs/chat-only-migration-inspection-notes.md:23:- frontend/wrapper-ui/app.js
docs/chat-only-migration-inspection-notes.md:24:- frontend/wrapper-ui/dev_server.py
docs/chat-only-migration-inspection-notes.md:25:- frontend/wrapper-ui/index.html
docs/chat-only-migration-inspection-notes.md:562:f0d381c Fix bounded poller static smoke marker
docs/chat-only-migration-inspection-notes.md:779:backend/app/routes/chat.py:768:    3. Central .env default for chat/companion mode.
docs/chat-only-migration-inspection-notes.md:1341:frontend/components/ChatPage.tsx:230:    const res = await authFetch("/api/backend/companion-profile");
docs/chat-only-migration-map.md:145:The wrapper chat page should show:
docs/chat-only-migration-map.md:191:- add static smoke only
docs/chat-only-migration-map.md:205:- obsolete wrapper compatibility routes
docs/cleanup/project-cleanup-audit-2026-06-10.md:5:- Study page loads without `/login?next=...` redirect.
docs/cleanup/project-cleanup-audit-2026-06-10.md:8:- Direct `/api/study/*` and `/api/companion/*` aliases exist in `edge_controller.py`.
docs/cleanup/project-cleanup-audit-2026-06-10.md:9:- Wrapper handles cookie-backed auth for Study API calls.
docs/cleanup/project-cleanup-audit-2026-06-10.md:15:3. Decide whether Study standalone header should remain temporarily or be migrated into the shared wrapper layout later.
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:8:controller-stage-5i-study-direct-wrapper-auth-cleanup-2026-06-10
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:10:## Wrapper map_api routes
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:15:60:        "/api/auth/login": "/system/session/login",
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:28:96:        "/api/auth/login": "/system/session/login",
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:34:131:    if path.startswith("/api/system/"):
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:35:132:        return CONTROLLER, path.replace("/api/system/", "/system/", 1)
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:38:137:    if path.startswith("/api/study/"):
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:40:140:    if path.startswith("/api/companion/"):
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:46:347:        # CT101 backend requests arrive at the wrapper as /api/backend/*, then
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:48:366:            or auth_source_path.startswith("/api/study/")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:49:367:            or auth_source_path.startswith("/api/companion/")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:51:376:            auth_source_path.startswith("/api/study/")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:52:377:            or auth_source_path.startswith("/api/companion/")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:63:6867:@app.post("/public/study/decks")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:64:6868:@app.post("/api/study/decks")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:65:6931:@app.get("/public/study/decks")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:66:6932:@app.get("/api/study/decks")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:67:6977:@app.delete("/public/study/decks/{deck_id}")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:68:6978:@app.delete("/api/study/decks/{deck_id}")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:69:7003:@app.post("/public/study/decks/{deck_id}/cards")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:70:7004:@app.post("/api/study/decks/{deck_id}/cards")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:71:7104:@app.get("/public/study/decks/{deck_id}/cards")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:72:7105:@app.get("/api/study/decks/{deck_id}/cards")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:73:7156:@app.delete("/public/study/cards/{card_id}")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:74:7157:@app.delete("/api/study/cards/{card_id}")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:75:7178:@app.post("/public/study/cards/{card_id}/reviews")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:76:7179:@app.post("/api/study/cards/{card_id}/reviews")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:77:7311:@app.get("/public/study/progress")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:78:7312:@app.get("/api/study/progress")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:79:7685:@app.get("/public/study/decks/{deck_id}/card-stats")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:80:7686:@app.get("/api/study/decks/{deck_id}/card-stats")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:81:7703:@app.get("/public/study/decks/{deck_id}/review-queue")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:82:7704:@app.get("/api/study/decks/{deck_id}/review-queue")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:83:7796:@app.post("/public/companion/study/grade")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:84:7797:@app.post("/api/companion/study/grade")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:85:8063:@app.get("/public/companion/context")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:86:8064:@app.get("/api/companion/context")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:87:8077:@app.post("/public/companion/chat")
docs/cleanup/stage-5j1-route-owner-snapshot-2026-06-10.md:88:8078:@app.post("/api/companion/chat")
docs/cleanup/stage-5j10-final-cleanup-rollup-2026-06-10.md:5:Record the final cleanup state after Study recovery, route ownership refresh, compatibility audits, and active wrapper stale-reference cleanup.
docs/cleanup/stage-5j10-final-cleanup-rollup-2026-06-10.md:9:- Stage 5I: Study direct wrapper auth cleanup
docs/cleanup/stage-5j10-final-cleanup-rollup-2026-06-10.md:15:- Stage 5J-7/8/9: active wrapper stale gateway reference cleanup
docs/cleanup/stage-5j10-final-cleanup-rollup-2026-06-10.md:19:- Study works through the laptop wrapper and laptop controller `/api/study/*` path.
docs/cleanup/stage-5j10-final-cleanup-rollup-2026-06-10.md:22:- Calendar is currently a wrapper/planning page; backend calendar API is not implemented yet.
docs/cleanup/stage-5j10-final-cleanup-rollup-2026-06-10.md:33:Move Study into the shared wrapper layout before adding new features such as PDF-to-flashcard import.
docs/cleanup/stage-5j2-current-route-ownership-summary-2026-06-10.md:17:- wrapper UI routing
docs/cleanup/stage-5j2-current-route-ownership-summary-2026-06-10.md:32:Browser -> laptop wrapper -> laptop controller /api/study/* -> laptop SQLite Study data
docs/cleanup/stage-5j2-current-route-ownership-summary-2026-06-10.md:37:- /public/study/* aliases
docs/cleanup/stage-5j2-current-route-ownership-summary-2026-06-10.md:38:- /public/companion/* aliases
docs/cleanup/stage-5j3-compatibility-code-audit-2026-06-10.md:17:- wrapper `/api/backend/*` bridge code
docs/cleanup/stage-5j3-compatibility-code-audit-2026-06-10.md:18:- controller `/public/study/*` aliases
docs/cleanup/stage-5j3-compatibility-code-audit-2026-06-10.md:19:- controller `/public/companion/*` aliases
docs/cleanup/stage-5j3-compatibility-code-audit-2026-06-10.md:29:Browser -> laptop wrapper -> laptop controller `/api/study/*` -> laptop Study data
docs/cleanup/stage-5j3-compatibility-code-audit-2026-06-10.md:33:1. Move Study into the shared wrapper layout.
docs/cleanup/stage-5j3-compatibility-code-audit-2026-06-10.md:37:5. Only then archive/remove inactive public gateway and Cloudflare Worker proxy source.
docs/cleanup/stage-5j4-chat-compatibility-bridge-audit-2026-06-10.md:15:- Does the wrapper CT101 compatibility bridge return a controlled 401/404/405, or a broken 502?
docs/cleanup/stage-5j4-chat-compatibility-bridge-audit-2026-06-10.md:35:Reason: the wrapper still contains active compatibility handling for CT101 ChatPage queued paths. Removal should wait until the browser Chat submit path is fully migrated and proven to use laptop-owned `/api/chat/queued` directly.
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:5:Audit whether Companion routes are using the laptop wrapper/controller path instead of the inactive public gateway.
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:13:- Does `/companion` load through the laptop wrapper?
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:14:- Do `/api/companion/context`, `/api/companion/chat`, and `/api/companion/study/grade` return controlled auth/validation responses instead of HTTP 502?
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:15:- Does the wrapper route `/api/companion/*` to the laptop controller?
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:16:- Are any active browser files still calling `/public/companion/*`, `7071`, or the public gateway?
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:20:Do not remove `/public/companion/*`, `public_gateway.py`, or Cloudflare Worker proxy source until Companion browser behavior is verified while logged in.
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:24:- `/companion` shell returned HTTP 200 from the laptop wrapper.
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:25:- `/api/companion/context` returned HTTP 401 Missing bearer token, not HTTP 502.
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:26:- `/api/companion/chat` returned HTTP 401 Missing bearer token, not HTTP 502.
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:27:- `/api/companion/study/grade` returned HTTP 401 Missing bearer token, not HTTP 502.
docs/cleanup/stage-5j5-companion-route-smoke-audit-2026-06-10.md:33:Keep `/public/companion/*`, `public_gateway.py`, and Cloudflare Worker proxy source for now.
docs/cleanup/stage-5j6-calendar-route-smoke-audit-2026-06-10.md:5:Audit whether Calendar routes are currently served by the laptop wrapper/controller and whether any old public-gateway or CT101 route ownership remains active.
docs/cleanup/stage-5j6-calendar-route-smoke-audit-2026-06-10.md:13:- Does `/calendar` load through the laptop wrapper?
docs/cleanup/stage-5j6-calendar-route-smoke-audit-2026-06-10.md:15:- Does the wrapper route `/api/calendar/*` to the laptop controller?
docs/cleanup/stage-5j6-calendar-route-smoke-audit-2026-06-10.md:24:- `/calendar` shell returned HTTP 200 from the laptop wrapper.
docs/cleanup/stage-5j6-calendar-route-smoke-audit-2026-06-10.md:33:Calendar is currently a wrapper/planning page, not a completed backend API.
docs/cleanup/stage-5j7-active-wrapper-gateway-reference-cleanup-2026-06-10.md:1:# Stage 5J-7 Active Wrapper Gateway Reference Cleanup — 2026-06-10
docs/cleanup/stage-5j7-active-wrapper-gateway-reference-cleanup-2026-06-10.md:5:Remove stale public-gateway references from the active laptop wrapper path after Stage 5I through Stage 5J route audits.
docs/cleanup/stage-5j7-active-wrapper-gateway-reference-cleanup-2026-06-10.md:9:- Removed unused `GATEWAY` / `EDGE_PUBLIC_GATEWAY_URL` reference from `frontend/wrapper-ui/dev_server.py` if no longer referenced.
docs/cleanup/stage-5j7-active-wrapper-gateway-reference-cleanup-2026-06-10.md:10:- Updated active wrapper comments to describe laptop-controller ownership.
docs/cleanup/stage-5j7-active-wrapper-gateway-reference-cleanup-2026-06-10.md:17:- `/study`, `/chat`, `/companion`, and `/calendar` still load through the wrapper.
docs/cleanup/stage-5j7-active-wrapper-gateway-reference-cleanup-2026-06-10.md:18:- `/api/system/status` still responds.
docs/cleanup/stage-5j8-finish-active-wrapper-stale-reference-cleanup-2026-06-10.md:1:# Stage 5J-8 Finish Active Wrapper Stale Reference Cleanup — 2026-06-10
docs/cleanup/stage-5j8-finish-active-wrapper-stale-reference-cleanup-2026-06-10.md:5:Finish the active wrapper cleanup after Stage 5J-7 left a stale unused `GATEWAY` env line and old public-gateway comments.
docs/cleanup/stage-5j8-finish-active-wrapper-stale-reference-cleanup-2026-06-10.md:9:- Removed the unused `GATEWAY = EDGE_PUBLIC_GATEWAY_URL -> 7071` line from `frontend/wrapper-ui/dev_server.py`.
docs/cleanup/stage-5j8-finish-active-wrapper-stale-reference-cleanup-2026-06-10.md:10:- Updated active wrapper comments away from public-gateway/source-of-truth wording.
docs/cleanup/stage-5j8-finish-active-wrapper-stale-reference-cleanup-2026-06-10.md:17:- `/study`, `/chat`, `/companion`, and `/calendar` still load.
docs/cleanup/stage-5j8-finish-active-wrapper-stale-reference-cleanup-2026-06-10.md:18:- `/api/system/status` still responds.
docs/cleanup/stage-5j9-final-active-wrapper-stale-comment-sweep-2026-06-10.md:1:# Stage 5J-9 Final Active Wrapper Stale Comment Sweep — 2026-06-10
docs/cleanup/stage-5j9-final-active-wrapper-stale-comment-sweep-2026-06-10.md:5:Remove the final stale active-wrapper comment mentioning the old public gateway/source-of-truth route model.
docs/cleanup/stage-5j9-final-active-wrapper-stale-comment-sweep-2026-06-10.md:9:- Cleaned remaining stale comment text in `frontend/wrapper-ui/app.js`.
docs/cleanup/stage-5j9-final-active-wrapper-stale-comment-sweep-2026-06-10.md:16:- `/study`, `/chat`, `/companion`, and `/calendar` still load.
docs/cleanup/stage-5j9-final-active-wrapper-stale-comment-sweep-2026-06-10.md:17:- `/api/system/status` still responds.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:1:# Stage 5K-1 Study Shared-Wrapper Layout Audit — 2026-06-10
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:5:Audit how to move the working Study dashboard into the shared wrapper layout without breaking Study data, auth, or review behavior.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:9:- Study currently works at `/study`.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:10:- Study still serves `frontend/study-ui/index.html`, which has its own standalone header/nav.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:11:- The wrapper shell works for `/`, `/chat`, `/companion`, `/calendar`, `/profile`, `/admin`, and `/system`.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:12:- Study API data is already laptop-controller owned through `/api/study/*`.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:16:Move Study content into the shared wrapper shell so `/study` uses the same header/nav/account/status layout as the rest of the site.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:26:3. Serve `/study` through wrapper shell with Study assets loaded only on Study route.
docs/cleanup/stage-5k1-study-shared-wrapper-layout-audit-2026-06-10.md:32:- No `/login?next=...` redirect.
docs/cleanup/stage-5k10-study-wrapper-preview-live-study-link-2026-06-10.md:1:# Stage 5K-10 Study Wrapper Preview Live Study Link — 2026-06-10
docs/cleanup/stage-5k10-study-wrapper-preview-live-study-link-2026-06-10.md:3:Added an Open Live Study action to /study-wrapper-preview.
docs/cleanup/stage-5k10-study-wrapper-preview-live-study-link-2026-06-10.md:5:The preview remains read-only and points users to /study for creating decks, adding cards, and reviewing.
docs/cleanup/stage-5k10-study-wrapper-preview-live-study-link-2026-06-10.md:9:Live /study remains unchanged and fully interactive.
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:1:# Stage 5K-11 Study Wrapper Action Endpoint Audit — 2026-06-10
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:5:Audit the existing standalone Study action payloads and backend routes before wiring create/review actions into /study-wrapper-preview.
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:9:/study-wrapper-preview is currently accurate and read-only. Before making it interactive, the wrapper route must match the existing Study API payloads exactly.
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:13:- /study-wrapper-preview uses shared wrapper layout.
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:14:- /study-wrapper-preview hydrates Study counts, deck summary, buckets, and card stats.
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:15:- /study-wrapper-preview is read-only.
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:16:- /study remains the live interactive Study page.
docs/cleanup/stage-5k11-study-wrapper-action-endpoint-audit-2026-06-10.md:25:6. Only after all smoke tests pass, decide whether /study-wrapper-preview can replace /study.
docs/cleanup/stage-5k12-study-wrapper-preview-deck-select-switching-2026-06-10.md:1:# Stage 5K-12 Study Wrapper Preview Deck Select Switching — 2026-06-10
docs/cleanup/stage-5k12-study-wrapper-preview-deck-select-switching-2026-06-10.md:3:Enabled safe preview-only deck selection on /study-wrapper-preview.
docs/cleanup/stage-5k12-study-wrapper-preview-deck-select-switching-2026-06-10.md:9:Live /study remains unchanged and fully interactive.
docs/cleanup/stage-5k13-study-wrapper-preview-create-deck-2026-06-10.md:1:# Stage 5K-13 Study Wrapper Preview Create Deck — 2026-06-10
docs/cleanup/stage-5k13-study-wrapper-preview-create-deck-2026-06-10.md:5:Enabled create-deck action on /study-wrapper-preview.
docs/cleanup/stage-5k13-study-wrapper-preview-create-deck-2026-06-10.md:7:The wrapper preview now POSTs to /api/study/decks with the existing Study payload shape:
docs/cleanup/stage-5k13-study-wrapper-preview-create-deck-2026-06-10.md:16:Created a test deck from the wrapper preview.
docs/cleanup/stage-5k13-study-wrapper-preview-create-deck-2026-06-10.md:27:Only create deck is wired in the wrapper preview.
docs/cleanup/stage-5k13-study-wrapper-preview-create-deck-2026-06-10.md:31:Live /study remains unchanged and fully interactive.
docs/cleanup/stage-5k14-study-wrapper-preview-add-card-2026-06-10.md:1:# Stage 5K-14 Study Wrapper Preview Add Card — 2026-06-10
docs/cleanup/stage-5k14-study-wrapper-preview-add-card-2026-06-10.md:5:Enabled add-card action on /study-wrapper-preview.
docs/cleanup/stage-5k14-study-wrapper-preview-add-card-2026-06-10.md:7:The wrapper preview now POSTs to /api/study/decks/{deck_id}/cards with the existing Study payload shape:
docs/cleanup/stage-5k14-study-wrapper-preview-add-card-2026-06-10.md:19:Added a test card to the wrapper-created test deck.
docs/cleanup/stage-5k14-study-wrapper-preview-add-card-2026-06-10.md:24:- question: wrapper
docs/cleanup/stage-5k14-study-wrapper-preview-add-card-2026-06-10.md:31:Create deck and add card are wired in the wrapper preview.
docs/cleanup/stage-5k14-study-wrapper-preview-add-card-2026-06-10.md:35:Live /study remains unchanged and fully interactive.
docs/cleanup/stage-5k15-study-wrapper-preview-review-queue-loader-2026-06-10.md:1:# Stage 5K-15 Study Wrapper Preview Review Queue Loader — 2026-06-10
docs/cleanup/stage-5k15-study-wrapper-preview-review-queue-loader-2026-06-10.md:5:Enabled review queue loading on /study-wrapper-preview.
docs/cleanup/stage-5k15-study-wrapper-preview-review-queue-loader-2026-06-10.md:7:The wrapper preview now fetches /api/study/decks/{deck_id}/review-queue?mode={mode}&limit=10.
docs/cleanup/stage-5k15-study-wrapper-preview-review-queue-loader-2026-06-10.md:19:Live /study remains unchanged and fully interactive.
docs/cleanup/stage-5k16-study-wrapper-preview-review-submit-2026-06-10.md:1:# Stage 5K-16 Study Wrapper Preview Review Submit — 2026-06-10
docs/cleanup/stage-5k16-study-wrapper-preview-review-submit-2026-06-10.md:5:Enabled Correct/Wrong review submit actions on /study-wrapper-preview.
docs/cleanup/stage-5k16-study-wrapper-preview-review-submit-2026-06-10.md:7:The wrapper preview now POSTs to /api/study/cards/{card_id}/reviews with:
docs/cleanup/stage-5k16-study-wrapper-preview-review-submit-2026-06-10.md:14:Submitted one review against the wrapper-created test deck.
docs/cleanup/stage-5k16-study-wrapper-preview-review-submit-2026-06-10.md:24:Live /study remains unchanged.
docs/cleanup/stage-5k17-study-wrapper-smoke-data-cleanup-2026-06-10.md:1:# Stage 5K-17 Study Wrapper Smoke Data Cleanup — 2026-06-10
docs/cleanup/stage-5k17-study-wrapper-smoke-data-cleanup-2026-06-10.md:5:Archived the temporary wrapper-preview smoke test deck created during Stage 5K-13 through Stage 5K-16.
docs/cleanup/stage-5k17-study-wrapper-smoke-data-cleanup-2026-06-10.md:11:- purpose: wrapper preview create/add/review smoke testing
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:1:# Stage 5K-18 Study Wrapper Migration Rollup Audit — 2026-06-10
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:5:/study-wrapper-preview is now functionally close to replacing the standalone /study route.
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:7:Wrapper preview supports:
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:9:- shared wrapper header/layout
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:29:- Keep /study as standalone for one more checkpoint.
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:30:- Keep /study-wrapper-preview as the shared-wrapper candidate route.
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:31:- Next stage can perform a controlled /study cutover if browser smoke passes.
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:35:- /study must keep loading the recovered deck.
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:36:- /study must not redirect to /login?next=...
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:37:- /study must use shared wrapper header after cutover.
docs/cleanup/stage-5k18-study-wrapper-migration-rollup-audit-2026-06-10.md:38:- Old standalone /study should remain available through a temporary fallback route until verified.
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:1:# Stage 5K-19 Study Shared Wrapper Controlled Cutover — 2026-06-10
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:5:Cut over exact /study to the shared wrapper Study implementation.
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:9:- /study serves the shared wrapper shell.
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:10:- /study-wrapper-preview remains available as the candidate/preview route.
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:11:- /study-standalone serves the old standalone Study page as a temporary fallback.
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:12:- /study/* still serves Study assets and partials such as /study/styles.css and /study/study-dashboard.partial.html.
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:14:## Study functionality now available through shared wrapper /study
docs/cleanup/stage-5k19-study-shared-wrapper-controlled-cutover-2026-06-10.md:37:Use /study-standalone#study to access the old standalone Study page during cutover verification.
docs/cleanup/stage-5k2-study-content-partial-extraction-2026-06-10.md:3:Extracted the working Study dashboard body into frontend/study-ui/study-content.partial.html.
docs/cleanup/stage-5k2-study-content-partial-extraction-2026-06-10.md:5:Runtime behavior did not change. /study still serves the standalone Study HTML.
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:1:# Stage 5K-20 Study Shared Wrapper Post-Cutover Smoke — 2026-06-10
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:5:Post-cutover route smoke confirmed /study now serves the shared wrapper shell.
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:9:- /study serves AlexHartel AI Platform wrapper shell.
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:10:- /study loads /app.js.
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:11:- /study-standalone serves the old standalone AI Study Dashboard shell.
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:12:- /study-standalone loads /study/app.js.
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:22:Keep /study-standalone temporarily.
docs/cleanup/stage-5k20-study-shared-wrapper-post-cutover-smoke-2026-06-10.md:24:Do not delete standalone Study files yet. Keep them as fallback until /study has passed repeated browser smoke tests after normal use.
docs/cleanup/stage-5k21-whole-project-checkpoint-after-study-cutover-2026-06-10.md:5:Recorded a whole-project checkpoint after cutting /study over to the shared wrapper implementation.
docs/cleanup/stage-5k21-whole-project-checkpoint-after-study-cutover-2026-06-10.md:9:- /study serves the shared wrapper Study page.
docs/cleanup/stage-5k21-whole-project-checkpoint-after-study-cutover-2026-06-10.md:10:- /study-standalone serves the old standalone Study fallback.
docs/cleanup/stage-5k21-whole-project-checkpoint-after-study-cutover-2026-06-10.md:11:- /study/* assets and partials remain available.
docs/cleanup/stage-5k21-whole-project-checkpoint-after-study-cutover-2026-06-10.md:23:Keep /study-standalone until /study has passed normal-use browser smoke over time.
docs/cleanup/stage-5k3-study-wrapper-preview-route-audit-2026-06-10.md:1:# Stage 5K-3 Study Wrapper Preview Route Audit — 2026-06-10
docs/cleanup/stage-5k3-study-wrapper-preview-route-audit-2026-06-10.md:3:Audit-only stage before adding a non-default /study-wrapper-preview route.
docs/cleanup/stage-5k3-study-wrapper-preview-route-audit-2026-06-10.md:5:Reason: Study app.js still contains standalone navigation/auth/hash routing code, so mounting it inside the wrapper should be done behind a preview route and in small reversible steps.
docs/cleanup/stage-5k3-study-wrapper-preview-route-audit-2026-06-10.md:7:Next safe step: add /study-wrapper-preview as a wrapper route that loads the Study partial with CSS only, without running Study app.js yet.
docs/cleanup/stage-5k4-study-wrapper-preview-route-2026-06-10.md:1:# Stage 5K-4 Study Wrapper Preview Route — 2026-06-10
docs/cleanup/stage-5k4-study-wrapper-preview-route-2026-06-10.md:3:Added non-default /study-wrapper-preview route.
docs/cleanup/stage-5k4-study-wrapper-preview-route-2026-06-10.md:5:The preview route uses the shared wrapper shell and loads the extracted Study content partial.
docs/cleanup/stage-5k4-study-wrapper-preview-route-2026-06-10.md:9:Live /study remains unchanged and still serves the standalone working Study dashboard.
docs/cleanup/stage-5k5-study-wrapper-dashboard-only-preview-2026-06-10.md:1:# Stage 5K-5 Study Wrapper Dashboard-Only Preview — 2026-06-10
docs/cleanup/stage-5k5-study-wrapper-dashboard-only-preview-2026-06-10.md:3:Updated /study-wrapper-preview to load a Study dashboard-only partial instead of the larger Study content partial.
docs/cleanup/stage-5k5-study-wrapper-dashboard-only-preview-2026-06-10.md:5:The preview now shows the shared wrapper header plus Study dashboard panels only.
docs/cleanup/stage-5k5-study-wrapper-dashboard-only-preview-2026-06-10.md:7:Study JavaScript is still intentionally not running in the preview, so counts remain static/default.
docs/cleanup/stage-5k5-study-wrapper-dashboard-only-preview-2026-06-10.md:9:Live /study remains unchanged and still serves the standalone working Study dashboard.
docs/cleanup/stage-5k6-study-wrapper-preview-hydrator-2026-06-10.md:1:# Stage 5K-6 Study Wrapper Preview Hydrator — 2026-06-10
docs/cleanup/stage-5k6-study-wrapper-preview-hydrator-2026-06-10.md:3:Added a safe preview-only hydrator for /study-wrapper-preview.
docs/cleanup/stage-5k6-study-wrapper-preview-hydrator-2026-06-10.md:5:The preview fetches /api/study/progress and /api/study/decks directly from the laptop controller.
docs/cleanup/stage-5k6-study-wrapper-preview-hydrator-2026-06-10.md:9:Live /study remains unchanged and continues to use the standalone Study page.
docs/cleanup/stage-5k7-study-wrapper-preview-card-stats-hydrator-2026-06-10.md:1:# Stage 5K-7 Study Wrapper Preview Card Stats Hydrator — 2026-06-10
docs/cleanup/stage-5k7-study-wrapper-preview-card-stats-hydrator-2026-06-10.md:3:Added preview-only hydration for selected deck card stats and difficulty buckets on /study-wrapper-preview.
docs/cleanup/stage-5k7-study-wrapper-preview-card-stats-hydrator-2026-06-10.md:5:The preview fetches /api/study/decks/{deck_id}/card-stats from the laptop controller.
docs/cleanup/stage-5k7-study-wrapper-preview-card-stats-hydrator-2026-06-10.md:11:Live /study remains unchanged and continues to use the standalone Study page.
docs/cleanup/stage-5k8-study-wrapper-preview-readonly-controls-2026-06-10.md:1:# Stage 5K-8 Study Wrapper Preview Read-Only Controls — 2026-06-10
docs/cleanup/stage-5k8-study-wrapper-preview-readonly-controls-2026-06-10.md:3:Made /study-wrapper-preview clearly read-only.
docs/cleanup/stage-5k8-study-wrapper-preview-readonly-controls-2026-06-10.md:5:Preview form controls are disabled and a notice points users to the live /study page for editing/review actions.
docs/cleanup/stage-5k8-study-wrapper-preview-readonly-controls-2026-06-10.md:9:Live /study remains unchanged and fully interactive.
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:1:# Stage 5K-9 Study Wrapper Preview Rollup — 2026-06-10
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:5:/study-wrapper-preview now uses the shared wrapper header and Study dashboard-only partial.
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:9:- Loads Study counts from /api/study/progress.
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:10:- Loads deck summary from /api/study/decks.
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:11:- Loads card stats and difficulty buckets from /api/study/decks/{deck_id}/card-stats.
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:14:- Is read-only and points users to the live /study page.
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:16:Live /study behavior:
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:19:- Still loads /study/app.js.
docs/cleanup/stage-5k9-study-wrapper-preview-rollup-2026-06-10.md:24:Do not replace live /study yet. The preview is readable and accurate, but create deck, add card, review queue, and answer grading actions are not wired in the shared wrapper route yet.
docs/cleanup/stage-5l1-chat-companion-queue-state-audit-2026-06-10.md:5:Audit current Chat and Companion queue state after completing the Study shared-wrapper cutover.
docs/cleanup/stage-5l1-chat-companion-queue-state-audit-2026-06-10.md:9:Study is now on the shared wrapper route at /study.
docs/cleanup/stage-5l1-chat-companion-queue-state-audit-2026-06-10.md:11:The old Study standalone fallback remains available at /study-standalone.
docs/cleanup/stage-5l2-queue-worker-service-lifecycle-audit-2026-06-10.md:9:- /chat and /companion routes return 200.
docs/cleanup/stage-5l2-queue-worker-service-lifecycle-audit-2026-06-10.md:11:- Wrapper still has /api/backend/* compatibility bridge for CT101 chat paths.
```

## Result

PHASE_14J_FC_RESULT=public_wrapper_entrypoint_inspection_and_local_clone_smoke_plan_recorded

## Next safe phase

NEXT_SAFE_PHASE=approve_website_edge_repo_clone_for_local_only_public_wrapper_smoke

The next phase should not deploy publicly. It should clone/copy to `website-edge` only after explicit approval, then perform local-only smoke validation.
