// STAGE_8I_ROUTER_SHADOW_READ_STUB_V1
//
// Disabled-by-default Universal Intent Router shadow-read helper.
//
// This file is intentionally NOT loaded by index.html yet.
// This file is intentionally NOT imported by app.js yet.
// This file performs no work unless a future stage explicitly wires it.
//
// Purpose:
// - Build a safe router dry-run payload.
// - Extract only safe decision_contract fields.
// - Refuse dispatch by default.
// - Keep Study and Companion behavior unchanged.

const ROUTER_SHADOW_READ_ENABLED = false;

// STAGE_8O_FEATURE_FLAG_BOUNDARY_V1
// Feature flag boundary for future shadow-read work.
// This remains off by default and does not introduce a router endpoint URL.
const ROUTER_SHADOW_READ_FEATURE_FLAG_NAME = "edge_router_shadow_read";
const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;

function isRouterShadowReadFeatureEnabled() {
  return ROUTER_SHADOW_READ_ENABLED === true && ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT === true;
}

function buildRouterShadowReadPayload({
  text = "",
  source = "unknown",
  surface = "unknown",
  activePage = "",
  profileLanguage = "en",
} = {}) {
  return {
    input: {
      text: String(text || ""),
      source: String(source || "unknown"),
      surface: String(surface || "unknown"),
    },
    context: {
      active_page: String(activePage || ""),
      profile_language: String(profileLanguage || "en"),
    },
    router_options: {
      dry_run: true,
      allow_dispatch: false,
      allow_model_call: false,
    },
  };
}

function extractRouterDecisionContract(routerResponse) {
  const decision = routerResponse && routerResponse.decision_contract
    ? routerResponse.decision_contract
    : {};

  const dispatchPlan = decision && decision.dispatch_plan
    ? decision.dispatch_plan
    : {};

  return {
    selected_path: decision.selected_path || null,
    intent_key: decision.intent_key || null,
    legacy_intent_name: decision.legacy_intent_name || null,
    confidence: typeof decision.confidence === "number" ? decision.confidence : null,
    needs_confirmation: decision.needs_confirmation === true,
    dispatch_performed: decision.dispatch_performed === true,
    allowed_to_dispatch: decision.allowed_to_dispatch === true,
    eligible_for_dispatch: decision.eligible_for_dispatch === true,
    model_call_required: decision.model_call_required === true,
    would_dispatch: dispatchPlan.would_dispatch === true,
  };
}

function isRouterDecisionShadowSafe(decision) {
  if (!decision || typeof decision !== "object") {
    return false;
  }

  return (
    decision.dispatch_performed === false &&
    decision.allowed_to_dispatch === false &&
    decision.would_dispatch === false
  );
}

async function routerShadowRead(_apiFn, _payload) {
  // Disabled by default. A future stage may wire this after a separate smoke.
  if (!isRouterShadowReadFeatureEnabled()) {
    return {
      ok: false,
      skipped: true,
      reason: "router_shadow_read_disabled",
      dispatch_performed: false,
      allowed_to_dispatch: false,
      would_dispatch: false,
    };
  }

  return {
    ok: false,
    skipped: true,
    reason: "router_shadow_read_not_wired",
    dispatch_performed: false,
    allowed_to_dispatch: false,
    would_dispatch: false,
  };
}

// STAGE_8K_BROWSER_NAMESPACE_EXPORT_V1
// Browser-safe namespace for future frontend wiring. Loading this file does not call the router.
if (typeof window !== "undefined") {
  window.EdgeRouterShadowRead = {
    ROUTER_SHADOW_READ_ENABLED,
    ROUTER_SHADOW_READ_FEATURE_FLAG_NAME,
    ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT,
    isRouterShadowReadFeatureEnabled,
    buildRouterShadowReadPayload,
    extractRouterDecisionContract,
    isRouterDecisionShadowSafe,
    routerShadowRead,
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    ROUTER_SHADOW_READ_ENABLED,
    ROUTER_SHADOW_READ_FEATURE_FLAG_NAME,
    ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT,
    isRouterShadowReadFeatureEnabled,
    buildRouterShadowReadPayload,
    extractRouterDecisionContract,
    isRouterDecisionShadowSafe,
    routerShadowRead,
  };
}
