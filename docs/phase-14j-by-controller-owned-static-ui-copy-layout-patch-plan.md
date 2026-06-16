# Phase 14J-BY - Controller-Owned Static UI Copy/Layout Patch Plan

PHASE_14J_BY_CONTROLLER_OWNED_STATIC_UI_COPY_LAYOUT_PATCH_PLAN

Date: 2026-06-16

## Scope

MUTATION_SCOPE=docs_smoke_only_targeted_source_shape

This document records the exact safety plan for the next bounded static UI copy/layout patch batch.

This phase is not runtime activation.

## Inspection result

TARGETED_ACTIVE_UI_SOURCE_SHAPE=completed

STATIC_UI_PATCH_TARGET_RECOMMENDATIONS=derived

PATCH_BATCH_DECISION=plan_only_until_exact_targets_confirmed

NEXT_PATCH_MODE=bounded_exact_string_patch

## Allowed next patch mode

ALLOWED_PATCH_MODE=exact_string_static_copy_layout_patch

The next patch phase should only edit active tracked source files where the source-shape inspection found exact UI strings or static structure markers.

Allowed changes:

ALLOWED_PATCH_TYPE=copy_text_polish  
ALLOWED_PATCH_TYPE=title_meta_polish  
ALLOWED_PATCH_TYPE=static_accessibility_label  
ALLOWED_PATCH_TYPE=static_layout_class_polish  
ALLOWED_PATCH_TYPE=non_runtime_ui_comment_marker  

## Still blocked

BLOCKED_PATCH_TYPE=runtime_activation  
BLOCKED_PATCH_TYPE=service_restart_reload  
BLOCKED_PATCH_TYPE=ct101_model_ollama_call  
BLOCKED_PATCH_TYPE=db_or_job_mutation  
BLOCKED_PATCH_TYPE=scheduler_worker_lane_activation  
BLOCKED_PATCH_TYPE=router_or_warmup_activation  

## Validation

REQUIRED_VALIDATION=ultra_concise_v2_static_baseline

## Non-activation confirmations

RUNTIME_ACTIVATION=not_performed  
SERVICE_RESTART_RELOAD=not_performed  
CT101_MODEL_OLLAMA_CALLS=forbidden  
CT101_MODEL_JOB_MUTATION=not_performed  
DB_MUTATION=not_performed  
JOB_MUTATION=not_performed  
LANE_WORKER_ENABLEMENT=not_performed  
SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed  
PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed  
ROUTER_MODEL_SELECTION_ACTIVATION=not_performed  
WARMUP_EXECUTION_ACTIVATION=not_performed  

DO_NOT_RERUN_14J_AG_APPLY_WRAPPER

## Runtime approval boundary

ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL

Runtime activation remains blocked unless explicitly approved in a future bounded phase.

## Source-shape inspection evidence

```text
TARGETED_ACTIVE_UI_SOURCE_SHAPE=completed
candidate_file_count=32

--- candidate file: cloudflare/edge-public-proxy/package.json ---
line_count=13
title_markers=<none>
ui_structure_markers=<none>

--- candidate file: cloudflare/edge-public-proxy/src/index.js ---
line_count=228
title_markers=<none>
ui_structure_markers:
  L5: { method: "POST", pattern: /^\/api\/auth\/login$/ },
  L18: { method: "POST", pattern: /^\/api\/study\/decks$/ },
  L19: { method: "GET",  pattern: /^\/api\/study\/decks$/ },
  L20: { method: "POST", pattern: /^\/api\/study\/decks\/[0-9]+\/cards$/ },
  L21: { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/cards$/ },
  L22: { method: "POST", pattern: /^\/api\/study\/cards\/[0-9]+\/reviews$/ },
  L23: { method: "GET",  pattern: /^\/api\/study\/progress$/ },
  L24: { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/card-stats$/ },
  L25: { method: "GET",  pattern: /^\/api\/study\/decks\/[0-9]+\/review-queue$/ },
  L27: { method: "POST", pattern: /^\/api\/companion\/study\/grade$/ },
  L28: { method: "GET",  pattern: /^\/api\/companion\/context$/ },
  L29: { method: "POST", pattern: /^\/api\/companion\/chat$/ },

--- candidate file: cloudflare/edge-public-proxy/wrangler.jsonc ---
line_count=15
title_markers=<none>
ui_structure_markers=<none>

--- candidate file: edge_controller.py ---
line_count=22708
title_markers:
  L48: title="Edge Queue Controller",
  L8618: title = payload.get("title") if isinstance(payload, dict) else None
  L8624: title = title.strip()[:200]
  L18528: title = "CT101 Companion" if clean_mode == "companion" else "CT101 Chat"
  L18555: title = EXCLUDED.title,
ui_structure_markers:
  L14: from fastapi import FastAPI, Header, HTTPException
  L337: headers={
  L863: if job_type in ("ollama_chat", "companion_chat", "tts", "stt"):
  L865: "required_capability": job_type if job_type != "companion_chat" else "ollama_chat",
  L936: x_heartbeat_token: str | None = Header(default=None, alias="X-Heartbeat-Token"),
  L2056: host_reason = "Proxmox inventory result was unavailable or malformed."
  L2249: # Skip header line:
  L2281: # Skip header line:
  L2622: "how_to_enable": "Set Environment=EDGE_POWER_EXECUTE_STOPS=1 in the controller systemd drop-in, then restart the controller.",
  L3193: "blocked_reason": "Inventory unavailable; worker start plan could not be safely evaluated.",
  L3217: "Inventory unavailable; host shutdown plan could not be safely evaluated."
  L3283: booting_marker = _system_read_booting_marker()

--- candidate file: edge_intent_router.py ---
line_count=821
title_markers=<none>
ui_structure_markers:
  L23: def _stage6af_lookup_context_domain(study_context, companion_context):
  L26: if study_context:
  L27: return "study"
  L28: if companion_context:
  L29: return "companion"
  L102: "calendar.write",
  L103: "profile.preference_update",
  L128: "system",
  L204: study_context = source_surface_policy["allowed"] and (source == "study" or surface.startswith("study") or active_page == "study")
  L205: companion_context = source_surface_policy["allowed"] and (source in {"companion", "chat"} or active_page in {"companion", "chat"})
  L226: "study_context": study_context,
  L227: "companion_context": companion_context,

--- candidate file: edge_inventory.example.json ---
line_count=55
title_markers=<none>
ui_structure_markers:
  L6: "companion_chat": "llms_ollama",

--- candidate file: edge_modules/chat_queue_creation.py ---
line_count=322
title_markers=<none>
ui_structure_markers:
  L317: chat_id=created_chat_id,
  L318: user_message_id=user_message_id,
  L319: job_id=parsed["job_id"],

--- candidate file: edge_modules/chat_queue_persistence.py ---
line_count=352
title_markers=<none>
ui_structure_markers:
  L185: id=parsed["id"],
  L186: chat_id=parsed["chat_id"],
  L189: source_job_id=parsed["source_job_id"],

--- candidate file: edge_modules/chat_queue_real_user_creation.py ---
line_count=325
title_markers=<none>
ui_structure_markers:
  L137: if mode_text == "companion":
  L151: "intent": "companion_chat" if mode_text == "companion" else "chat_message",
  L185: authenticated_user_id=authenticated_user_id,
  L216: {_sql_literal("Stage 5H-2 Queued Companion" if validated.mode == "companion" else "Stage 5F-18 Queued Chat")},
  L320: chat_id=chat_id,
  L321: user_message_id=user_message_id,
  L322: job_id=parsed["job_id"],

--- candidate file: edge_modules/chat_queue_real_user_guard.py ---
line_count=150
title_markers=<none>
ui_structure_markers:
  L73: # STAGE_5H2_COMPANION_MODE_OWNERSHIP_V1
  L77: if mode not in {"chat", "companion"}:
  L78: raise RealUserQueuedChatGuardError("mode must be chat or companion")
  L105: authenticated_user_id=authenticated_user_id,
  L106: chat_id=chat_id,

--- candidate file: edge_modules/chat_queue_session_auth.py ---
line_count=115
title_markers=<none>
ui_structure_markers:
  L104: user_id=parsed["user_id"],
  L105: session_id=parsed["session_id"],

--- candidate file: edge_modules/credit_helpers.py ---
line_count=85
title_markers=<none>
ui_structure_markers:
  L50: detail=f"Insufficient paid credits. External paid services require paid credits. Required {amount}, paid available {paid_available}.",
  L54: # Local jobs can use free credits first.
  L63: detail=f"Insufficient free/local credits. Required {amount}, free available {free_available}.",
  L69: detail=f"Insufficient credits. Required {amount}, free available {free_available}, paid available {paid_available}.",

--- candidate file: edge_modules/credits.py ---
line_count=292
title_markers=<none>
ui_structure_markers=<none>

--- candidate file: edge_modules/email_verification.py ---
line_count=268
title_markers=<none>
ui_structure_markers:
  L141: server.login(username, password)
  L145: server.login(username, password)
  L258: server.login(username, password)
  L262: server.login(username, password)

--- candidate file: edge_modules/laptop_queue.py ---
line_count=516
title_markers=<none>
ui_structure_markers=<none>

--- candidate file: edge_modules/rewarded_ads.py ---
line_count=375
title_markers=<none>
ui_structure_markers:
  L48: "reward_credits": int(os.getenv("AD_REWARD_FREE_CREDITS", "5")),
  L56: forwarded = request.headers.get("x-forwarded-for", "")
  L76: credits_granted INTEGER NOT NULL DEFAULT 0,
  L167: "reward_credits": settings["reward_credits"],
  L169: "credit_rule": "Ad rewards grant free/local credits only.",
  L258: credits = int(settings["reward_credits"])
  L283: "credits_granted": 0,
  L321: credits_granted,
  L334: credits,
  L336: ad_hash(request.headers.get("user-agent", "")),
  L344: user_id=user_id,
  L345: amount=credits,

--- candidate file: edge_router_lookup.py ---
line_count=163
title_markers=<none>
ui_structure_markers:
  L41: context_domain: str = "study",
  L154: context_domain: str = "study",

--- candidate file: edge_router_schema.py ---
line_count=215
title_markers=<none>
ui_structure_markers:
  L111: study_language TEXT,

--- candidate file: edge_router_seed.py ---
line_count=405
title_markers=<none>
ui_structure_markers:
  L22: # Study session intents
  L24: "intent_key": "study.session.start",
  L25: "domain": "study",
  L28: "description": "Start a study session.",
  L35: "intent_key": "study.session.end",
  L36: "domain": "study",
  L39: "description": "End the active study session.",
  L46: # Study card intents
  L48: "intent_key": "study.card.next",
  L49: "domain": "study",
  L52: "description": "Move to the next study card.",
  L59: "intent_key": "study.card.skip",

--- candidate file: frontend/study-ui/app.js ---
line_count=1932
title_markers:
  L266: const title = $("deckTitleInput").value.trim();
  L1305: const title = document.getElementById("calendarTitleInput")?.value?.trim();
  L1502: const title = authPanel.querySelector("h2");
ui_structure_markers:
  L18: console.warn(`[study-ui] Missing element #${id}; skipped ${eventName} listener.`);
  L25: function safeNavigate(url, reason = "study-ui navigation") {
  L29: target.includes("/login") ||
  L30: target.includes("login?next") ||
  L33: console.warn(`[study-ui] Blocked legacy login redirect from ${reason}: ${target}`);
  L50: function authHeaders(json = false) {
  L51: const headers = {};
  L52: if (json) headers["Content-Type"] = "application/json";
  L53: return headers;
  L59: headers: {
  L60: ...(options.headers || {})
  L97: $("studyGrid").classList.remove("hidden");

--- candidate file: frontend/study-ui/index.html ---
line_count=284
title_markers:
  L6: <title>AI Study Dashboard</title>
ui_structure_markers:
  L6: <title>AI Study Dashboard</title>
  L7: <link rel="stylesheet" href="/study/styles.css" />
  L10: <div class="app-shell">
  L11: <nav class="app-shell-nav" aria-label="Main navigation">
  L12: <a class="app-shell-brand" href="https://alexhartel.com">
  L13: <span class="app-shell-brand-mark">AI</span>
  L17: <div class="app-shell-links">
  L18: <a class="app-shell-link nav-link" href="https://alexhartel.com">Home</a>
  L19: <a class="app-shell-link nav-link" href="https://alexhartel.com/study">Study</a>
  L20: <a class="app-shell-link nav-link" href="https://alexhartel.com/companion">Companion</a>
  L21: <a class="app-shell-link nav-link" href="https://alexhartel.com/calendar">Calendar</a>
  L22: <a class="app-shell-link nav-link" href="https://alexhartel.com/profile">Profile</a>

--- candidate file: frontend/study-ui/study-content.partial.html ---
line_count=249
title_markers=<none>
ui_structure_markers:
  L1: <!-- Study dashboard content partial extracted from standalone Study HTML. Runtime is not using this file yet. -->
  L2: <header class="hero page-block" data-page="home">
  L4: <p class="eyebrow">AI Platform Control</p>
  L5: <h1>Study Dashboard</h1>
  L6: <p class="subtitle">
  L11: <div class="status-card">
  L12: <div class="status-dot" id="apiDot"></div>
  L14: <strong id="apiStatusText">Checking API...</strong>
  L15: <span id="workerStatusText">Worker proxy</span>
  L18: </header>
  L21: <section class="panel page-block" data-page="home" id="homePanel">
  L22: <div class="panel-header">

--- candidate file: frontend/study-ui/study-dashboard.partial.html ---
line_count=145
title_markers=<none>
ui_structure_markers:
  L1: <!-- Study dashboard-only partial for wrapper preview. Runtime /study does not use this file yet. -->
  L2: <section class="panel" data-page="study" data-preview-page="study" id="dashboardPanel">
  L3: <div class="panel-header">
  L5: <p class="eyebrow">Study</p>
  L6: <h2>Progress Overview</h2>
  L10: <div class="stats-grid">
  L11: <div class="stat">
  L13: <strong id="deckCount">0</strong>
  L15: <div class="stat">
  L17: <strong id="cardCount">0</strong>
  L19: <div class="stat">
  L21: <strong id="reviewCount">0</strong>

--- candidate file: frontend/study-ui/styles.css ---
line_count=1017
title_markers=<none>
ui_structure_markers:
  L28: font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  L32: button,
  L39: button {
  L139: .panel-header {
  L407: App navigation
  L410: .site-nav {
  L449: .nav-links,
  L450: .nav-auth {
  L456: .nav-link {
  L465: .nav-link:hover,
  L466: .nav-link.active {
  L490: .site-nav {

--- candidate file: frontend/wrapper-ui/app.js ---
line_count=11027
title_markers:
  L432: pill.title = "Log in to view credits.";
  L458: pill.title =
  L2685: el.title = "Preview-only deck switching. Editing and review actions are still disabled.";
  L2691: el.title = "Preview only. Use the live Study page for editing and review actions.";
  L2788: const title = String(titleInput?.value || "").trim();
  L2997: mode.title = "Choose preview review queue mode.";
ui_structure_markers:
  L2: // COMPANION_TRANSIENT_CONTROLLER_WRAPPER_V1
  L15: function cleanCompanionErrorMessage(value) {
  L29: let accountCredits = null;
  L36: let adminSystemStatus = null;
  L39: let profilePreferences = null;
  L40: let profilePreferencesLoading = false;
  L41: let profilePreferencesSaving = false;
  L42: let profilePreferencesError = "";
  L43: let profilePreferencesSaveMessage = "";
  L51: let authMode = "login";
  L55: token: localStorage.getItem("edgeStudyToken") || "",
  L61: // can decide whether /study, /chat, /companion, /calendar, and /profile should proxy

--- candidate file: frontend/wrapper-ui/dev_server.py ---
line_count=902
title_markers=<none>
ui_structure_markers:
  L15: "/login",
  L17: "/study",
  L18: "/study-wrapper-preview",
  L20: "/companion",
  L21: "/calendar",
  L22: "/profile",
  L23: "/credits",
  L26: "/system",
  L50: FULL_APP_ROUTES = {"/study", "/chat", "/companion", "/calendar", "/profile"}
  L51: WRAPPER_ROUTES = {"/", "/study-wrapper-preview", "/study-standalone", "/study", "/chat", "/companion", "/calendar", "/profile", "/system"}
  L56: # Wrapper login/admin/credits currently belong to the laptop controller.
  L59: "/api/me": "/system/session/me",

--- candidate file: frontend/wrapper-ui/index.html ---
line_count=143
title_markers:
  L6: <title>AlexHartel AI Platform</title>
  L14: <span class="brand-mark helper-logo" title="Study Companion Helper">
  L35: <button id="creditsPill" class="credits-pill hidden" type="button" data-credit-route="/credits" title="View credits and plans">
ui_structure_markers:
  L6: <title>AlexHartel AI Platform</title>
  L8: <link id="studyPreviewStyles" rel="stylesheet" href="/study/styles.css?v=20260612000409" disabled />
  L12: <header class="topbar">
  L13: <a class="brand logo-only" href="/" data-route="/" aria-label="AlexHartel AI Platform home">
  L14: <span class="brand-mark helper-logo" title="Study Companion Helper">
  L15: <svg viewBox="0 0 64 64" role="img" aria-label="Study Companion Helper logo">
  L24: <nav class="nav" aria-label="Main navigation">
  L25: <a href="/study" data-route="/study">Study</a>
  L26: <a href="/companion" data-route="/companion">Companion</a>
  L27: <a href="/profile" data-route="/profile">Profile</a>
  L29: <a id="adminNavLink" class="hidden" href="/admin" data-route="/admin">Admin</a>
  L30: <a href="/system" data-route="/system" id="systemNavLink">

--- candidate file: frontend/wrapper-ui/queued_chat_config.js ---
line_count=36
title_markers=<none>
ui_structure_markers=<none>

--- candidate file: frontend/wrapper-ui/queued_chat_status.js ---
line_count=147
title_markers=<none>
ui_structure_markers=<none>

--- candidate file: frontend/wrapper-ui/router_shadow_read_stub.js ---
line_count=230
title_markers=<none>
ui_structure_markers:
  L13: // - Keep Study and Companion behavior unchanged.
  L32: profileLanguage = "en",
  L42: profile_language: String(profileLanguage || "en"),
  L188: reason: "fetch_unavailable",
  L197: headers: {

--- candidate file: frontend/wrapper-ui/styles.css ---
line_count=2945
title_markers=<none>
ui_structure_markers:
  L24: font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  L68: .nav {
  L76: .nav a,
  L89: .nav a.active {
  L192: button.card {
  L200: .nav a:hover,
  L232: .system-drawer {
  L369: Auth/header additions
  L372: #systemNavLink {
  L378: .nav-auth-btn {
  L441: System grouping display
  L444: .system-section {

--- candidate file: public_gateway.py ---
line_count=756
title_markers:
  L12: app = FastAPI(title="Edge Queue Public Gateway")
ui_structure_markers:
  L32: "/public/auth/login",
  L43: if method in {"GET", "POST"} and path == "/public/study/decks":
  L46: if method in {"GET", "POST"} and re.fullmatch(r"/public/study/decks/[0-9]+/cards", path):
  L49: if method == "POST" and re.fullmatch(r"/public/study/cards/[0-9]+/reviews", path):
  L52: if method == "GET" and path == "/public/study/progress":
  L55: if method == "GET" and re.fullmatch(r"/public/study/decks/[0-9]+/card-stats", path):
  L58: if method == "GET" and re.fullmatch(r"/public/study/decks/[0-9]+/review-queue", path):
  L61: if method == "POST" and path == "/public/companion/study/grade":
  L64: if method == "GET" and path == "/public/companion/context":
  L67: if method == "POST" and path == "/public/companion/chat":
  L104: forwarded_headers = {}
  L106: for header_name in [

PASS: targeted active UI source-shape inspection completed
```

## Patch target recommendation evidence

```text
STATIC_UI_PATCH_TARGET_RECOMMENDATIONS=derived
candidate=frontend/study-ui/index.html exists=yes tracked=yes title_markers=1 ui_markers=241 runtime_risk_markers=3 recommended=yes
candidate=frontend/study-ui/app.js exists=yes tracked=yes title_markers=3 ui_markers=345 runtime_risk_markers=58 recommended=yes
candidate=cloudflare/edge-public-proxy/src/index.js exists=yes tracked=yes title_markers=0 ui_markers=44 runtime_risk_markers=29 recommended=yes
candidate=edge_controller.py exists=yes tracked=yes title_markers=5 ui_markers=565 runtime_risk_markers=2895 recommended=caution

PATCH_BATCH_DECISION=plan_only_until_exact_targets_confirmed
NEXT_PATCH_MODE=bounded_exact_string_patch
```
