
// COMPANION_TRANSIENT_GATEWAY_WRAPPER_V1
function isGatewayHtmlErrorText(value) {
  const text = String(value || "").trim().toLowerCase();
  return (
    text.startsWith("<!doctype html") ||
    text.startsWith("<html") ||
    (text.includes("cloudflare") && text.includes("bad gateway")) ||
    text.includes("error code 502") ||
    text.includes("error code 503") ||
    text.includes("error code 504")
  );
}

function cleanCompanionErrorMessage(value) {
  const text = String(value || "");
  if (isGatewayHtmlErrorText(text)) {
    return "The companion is still working or the gateway timed out before the browser received the final response. I will not show the raw Cloudflare error page. Refresh in a moment or try again.";
  }
  return text;
}

const API_BASE = "/api";

const $ = (id) => document.getElementById(id);

let lastStatus = null;
let adminStatus = null;
let accountCredits = null;
let gpuCatalog = null;
let gpuQuote = null;
let gpuReserveResult = null;
let gpuSessions = null;
let adminUsers = null;
let adminTickets = null;
let adminSystemStatus = null;
let supportTickets = null;
let supportThread = null;
let adRewardStatus = null;
let googleRewardedSlot = null;
let googleRewardedReadyEvent = null;
let googleRewardedEventId = "";
let googleRewardedLoading = false;
let googleRewardedGranted = false;
let googleRewardedMessage = "";
let authMode = "login";
let pendingVerificationEmail = "";

const authState = {
  token: localStorage.getItem("edgeStudyToken") || "",
  user: null,
};

// AUTH_ROUTE_COOKIE_V1
// Mirror the token into a same-site cookie so the always-on Python wrapper
// can decide whether /study, /chat, /companion, /calendar, and /profile should proxy
// the full CT 101 app or serve public summaries.

// GLOBAL_HTML_ERROR_SANITIZER_V1
function sanitizeVisibleErrorText(value) {
  const text = String(value ?? "");
  if (typeof cleanCompanionErrorMessage === "function") {
    return cleanCompanionErrorMessage(text);
  }

  const lower = text.trim().toLowerCase();
  if (
    lower.startsWith("<!doctype html") ||
    lower.startsWith("<html") ||
    (lower.includes("cloudflare") && lower.includes("bad gateway")) ||
    lower.includes("error code 502") ||
    lower.includes("error code 503") ||
    lower.includes("error code 504")
  ) {
    return "The companion is still working or the gateway timed out before the browser received the final response. I will not show the raw Cloudflare error page. Refresh in a moment or try again.";
  }

  return text;
}

function installGlobalHtmlErrorSanitizer() {
  if (window.__globalHtmlErrorSanitizerInstalled) return;
  window.__globalHtmlErrorSanitizerInstalled = true;

  const textDescriptor = Object.getOwnPropertyDescriptor(Node.prototype, "textContent");
  if (textDescriptor && textDescriptor.set && textDescriptor.get) {
    Object.defineProperty(Node.prototype, "textContent", {
      get: textDescriptor.get,
      set(value) {
        return textDescriptor.set.call(this, sanitizeVisibleErrorText(value));
      },
      configurable: true,
      enumerable: textDescriptor.enumerable,
    });
  }

  const htmlDescriptor = Object.getOwnPropertyDescriptor(Element.prototype, "innerHTML");
  if (htmlDescriptor && htmlDescriptor.set && htmlDescriptor.get) {
    Object.defineProperty(Element.prototype, "innerHTML", {
      get: htmlDescriptor.get,
      set(value) {
        return htmlDescriptor.set.call(this, sanitizeVisibleErrorText(value));
      },
      configurable: true,
      enumerable: htmlDescriptor.enumerable,
    });
  }
}

installGlobalHtmlErrorSanitizer();


function syncAuthRouteCookie() {
  const secure = location.protocol === "https:" ? "; Secure" : "";

  if (authState.token) {
    document.cookie =
      `edgeStudyToken=${encodeURIComponent(authState.token)}; Path=/; Max-Age=2592000; SameSite=Lax${secure}`;
  } else {
    document.cookie =
      `edgeStudyToken=; Path=/; Max-Age=0; SameSite=Lax${secure}`;
  }
}


syncAuthRouteCookie();

// PRIVATE_ROUTE_REFRESH_AFTER_AUTH_V1
const PRIVATE_APP_ROUTE_SET = new Set(["/study", "/chat", "/companion", "/profile"]);

function refreshPrivateRouteAfterAuth(reason = "auth") {
  syncAuthRouteCookie();

  if (PRIVATE_APP_ROUTE_SET.has(location.pathname)) {
    const url = new URL(location.href);
    url.searchParams.set("fresh", String(Date.now()));
    url.searchParams.set("auth", reason);
    location.replace(url.toString());
    return true;
  }

  return false;
}

const pages = {
  "/": {
    eyebrow: "Welcome",
    title: "Welcome to your AI-powered learning space",
    subtitle:
      "Practice smarter with study tools, guided review, and an AI companion designed to help you focus on what matters most.",
    cards: [
      ["Study", "Create decks, review cards, track progress, and focus on cards that need more practice.", "/study"],
      ["Chat", "Use AI Chat or switch into Companion mode for study help, explanations, and supportive conversation.", "/chat"],
      ["Profile", "Manage preferences, permissions, account settings, and future companion personalization.", "/profile"],
      ["System", "View platform capacity, API health, and resource state.", "/system"],
    ],
    boxes: [
      ["Personalized practice", "The platform is designed around active recall, guided feedback, and focusing on weak areas."],
      ["AI support", "The companion can eventually use study history, profile settings, and calendar context to support learning."],
      ["Always available overview", "Public summaries stay available even when live backend services are asleep."],
      ["Efficient resources", "Compute services can wake only when needed and shut down when idle."],
    ],
  },

  "/study": {
    eyebrow: "Feature summary",
    title: "Study",
    subtitle:
      "Study helps users create decks, add cards, review material, track progress, and prioritize what needs more practice.",
    boxes: [
      ["Decks and cards", "Create study decks and add questions, answers, and explanations."],
      ["Review queue", "Practice new, hard, medium, and easy cards in a balanced review flow."],
      ["Progress tracking", "Track accuracy, card difficulty, and review history."],
      ["Future companion support", "The companion can help grade answers and explain difficult concepts."],
    ],
  },


  "/chat": {
    eyebrow: "Unified chat",
    title: "Chat",
    subtitle:
      "Chat is the single place for normal AI Chat and Companion mode. Use AI Chat for general local Ollama conversations, or switch to Companion mode for study-aware support.",
    boxes: [
      ["AI Chat", "General local-first AI chat with an experimental queued mode."],
      ["Companion mode", "Supportive companion conversation with study tools and safety boundaries."],
      ["One entry point", "The Chat tab replaces the separate Companion tab while keeping /companion compatible."],
      ["Safe migration", "Queued chat stays opt-in and Companion remains synchronous for now."],
    ],
  },

  "/companion": {
    eyebrow: "Feature summary",
    title: "Companion",
    subtitle:
      "Companion is the AI helper for conversation, studying, explanations, practice, and future personalized support.",
    boxes: [
      ["Study helper", "The companion can help users practice flashcards, explain concepts, and check understanding."],
      ["Answer checking", "When connected to study data, it can compare user answers against card answers."],
      ["Context aware", "Future versions can use profile, calendar, study, and file context with permission."],
      ["Helpful guidance", "The goal is a supportive helper that asks questions when unsure instead of guessing."],
    ],
  },


  "/calendar": {
    eyebrow: "External integrations",
    title: "Calendar Integrations",
    subtitle:
      "Instead of storing a permanent built-in calendar, the platform will connect with Apple Calendar and Google Calendar when users choose to authorize it.",
    boxes: [
      ["Apple Calendar", "Future option for users who want Apple Calendar-based scheduling and reminders."],
      ["Google Calendar", "Future option for users who want Google Calendar-based scheduling and reminders."],
      ["Temporary access", "Calendar data should be used only when needed for context, not permanently duplicated."],
      ["Less reinventing", "Apple and Google already provide reliable long-term calendar storage, sharing, and notifications."],
    ],
  },


  "/profile": {
    eyebrow: "Feature summary",
    title: "Profile",
    subtitle:
      "Profile will manage account settings, preferences, permissions, and personalization for the platform.",
    boxes: [
      ["Account settings", "Manage user identity, login state, and basic account preferences."],
      ["Permissions", "Control what data the companion and tools are allowed to use."],
      ["Personalization", "Store preferences that help the platform adapt to each user."],
      ["Security boundary", "Private server credentials and infrastructure controls stay out of the browser."],
    ],
  },

  "/credits": {
    eyebrow: "Account credits",
    title: "Credits and Plans",
    subtitle:
      "Credits control access to higher-cost features like AI jobs, companion usage, image generation, storage, and future premium tools.",
    boxes: [],
  },

  "/admin": {
    eyebrow: "Admin",
    title: "Admin Panel",
    subtitle:
      "Manage users, credits, support tickets, and infrastructure status from one admin-only dashboard.",
    boxes: [],
  },

  "/support": {
    eyebrow: "Support",
    title: "Customer Support",
    subtitle:
      "Send a message to support if something is not working, you need account help, or you have questions about credits and services.",
    boxes: [],
  },

  "/system": {
    eyebrow: "Platform status",
    title: "System",
    subtitle:
      "System summarizes platform infrastructure and API health without exposing private server details.",
    boxes: [],
  },
};

function isLocalDevHost() {
  return ["127.0.0.1", "localhost"].includes(location.hostname);
}

function titleCase(value) {
  if (!value) return "Unknown";
  return String(value).slice(0, 1).toUpperCase() + String(value).slice(1);
}

function routePath() {
  const path = window.location.pathname || "/";
  return pages[path] ? path : "/";
}

function authHeaders(extra = {}) {
  const headers = {
    "Content-Type": "application/json",
    ...extra,
  };

  if (authState.token) {
    headers.Authorization = `Bearer ${authState.token}`;
  }

  return headers;
}

/**
 * Central API wrapper for public wrapper frontend.
 *
 * ROUTE OWNERSHIP (Stage 1):
 * - /auth/* = controller-owned account authentication
 * - /me = controller-owned current user/session
 * - /system/* = controller-owned status, power, and account endpoints
 * - /api/study/* = public wrapper bridge/proxy; CT101 is source-of-truth downstream
 * - /api/companion/* = public wrapper bridge/proxy; CT101 is source-of-truth downstream
 * - /api/calendar/* = CT101 source-of-truth downstream
 * - /credits/* = controller-owned credit wallet and ledger
 * - /ads/reward/* = controller-owned rewarded ad claims
 * - /gpu/* = controller-owned GPU credit reservation and session management
 * - /support/* = controller-owned support tickets
 *
 * Note: The wrapper makes fetch calls to /api/* paths, which are translated
 * by the public gateway (index.js) to /public/* and /system/* controller routes,
 * or proxied to CT101 /api/* source-of-truth endpoints as appropriate.
 */
async function api(path, options = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: authHeaders(options.headers || {}),
  });

  const text = await response.text();
  let data = {};

  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { detail: text };
  }

  if (!response.ok) {
    throw new Error(data.detail || data.error || `HTTP ${response.status}`);
  }

  return data;
}

function setActiveNav(path) {
  document.querySelectorAll("[data-route]").forEach((link) => {
    link.classList.toggle("active", link.getAttribute("data-route") === path);
  });
}

function setSystemHeaderState() {
  const state = lastStatus?.overall_state || "unknown";
  const dot = $("systemNavDot");
  const text = $("systemNavText");

  if (dot) dot.className = `dot ${state}`;
  if (text) text.textContent = "System";
}

function normalizeCreditsPayload(payload) {
  const user = payload?.user || authState.user || {};
  const credits = payload?.credits || {};

  const available =
    credits.available ??
    credits.total_available ??
    user.credit_balance ??
    0;

  const free =
    credits.free_available ??
    credits.free ??
    available ??
    0;

  const paid =
    credits.paid_available ??
    credits.paid ??
    0;

  const reserved =
    credits.reserved ??
    credits.total_reserved ??
    0;

  return {
    available: Number(available || 0),
    free: Number(free || 0),
    paid: Number(paid || 0),
    reserved: Number(reserved || 0),
    plan: credits.plan || user.plan || "free",
    billing_status: credits.billing_status || user.billing_status || "none",
  };
}

function forceSyncAccountUi() {
  const adminLink = document.getElementById("adminNavLink");
  const supportLink = document.querySelector('[data-route="/support"]');
  const isAdmin = Boolean(authState?.user?.is_admin || authState?.user?.role === "admin");

  if (adminLink) adminLink.classList.toggle("hidden", !isAdmin);
  if (supportLink) supportLink.classList.toggle("hidden", isAdmin);

  renderCreditsPill?.();
}

function formatNumber(value) {
  const n = Number(value || 0);
  if (!Number.isFinite(n)) return "0";
  return n.toLocaleString();
}

function renderCreditsPill() {
  const pill = $("creditsPill");
  if (!pill) return;

  const loggedIn = Boolean(authState.token);
  const user = authState.user || {};
  const normalizedCredits = normalizeCreditsPayload(accountCredits);
  const pools = accountCredits?.credits || {};

  pill.classList.toggle("hidden", !loggedIn);

  if (!loggedIn) {
    pill.textContent = "Credits";
    pill.title = "Log in to view credits.";
    return;
  }

  const freeCredits =
    pools.free_available ??
    user.free_credit_balance ??
    0;

  const paidCredits =
    pools.paid_available ??
    user.paid_credit_balance ??
    0;

  const totalCredits =
    pools.total_available ??
    user.credit_balance ??
    Number(freeCredits || 0) + Number(paidCredits || 0);

  pill.innerHTML = `
    <span class="credits-total">Credits ${formatNumber(totalCredits)}</span>
    <span class="credits-breakdown">
      Free ${formatNumber(freeCredits)} · Paid ${formatNumber(paidCredits)}
    </span>
  `;

  pill.title =
    "Free credits are local-only. Paid credits can be used for external GPU/cloud services.";
}

function renderAuthButtons() {
  const loggedIn = Boolean(authState.token);

  $("authOpenBtn")?.classList.toggle("hidden", loggedIn);
  $("logoutBtn")?.classList.toggle("hidden", !loggedIn);
  renderCreditsPill();
}

function navigate(path) {
  if (!pages[path]) path = "/";
  history.pushState({}, "", path);

// ============================================================
// API_CACHE_LAYER_V1
// Small stale-while-refresh cache for GET requests.
// - GET routes can return cached data instantly.
// - Mutations invalidate related caches.
// - Important operations still force fresh data when needed.
// ============================================================

const AH_CACHE_TTL = {
  PUBLIC_STATUS: 15_000,
  CREDITS: 10_000,
  AD_REWARD: 5_000,
  GPU_CATALOG: 10 * 60_000,
  GPU_SESSIONS: 10_000,
  SUPPORT_TICKETS: 10_000,
  ADMIN_USERS: 10_000,
  ADMIN_SUPPORT: 10_000,
  ADMIN_SYSTEM: 15_000,
};

const ahApiCache = new Map();
const ahApiInflight = new Map();

function ahCacheUserKey() {
  // Include token fragment so cached private data is not shared between accounts.
  const token = authState?.token || "public";
  return token === "public" ? "public" : token.slice(-12);
}

function ahCacheKey(path, options = {}) {
  const method = String(options.method || "GET").toUpperCase();
  return `${ahCacheUserKey()}::${method}::${path}`;
}

function ahInvalidateCache(matchers = []) {
  const list = Array.isArray(matchers) ? matchers : [matchers];

  for (const key of [...ahApiCache.keys()]) {
    if (!list.length || list.some((m) => key.includes(m))) {
      ahApiCache.delete(key);
    }
  }

  for (const key of [...ahApiInflight.keys()]) {
    if (!list.length || list.some((m) => key.includes(m))) {
      ahApiInflight.delete(key);
    }
  }
}

function ahInvalidateForMutation(path) {
  const p = String(path || "");

  // Presence is a lightweight heartbeat. It should keep online status fresh,
  // but it should NOT wipe cached page data.
  if (p.includes("/session/presence")) {
    return;
  }

  if (p.includes("/support/")) {
    ahInvalidateCache([
      "/support/tickets",
      "/admin/support/tickets",
    ]);
  }

  if (
    p.includes("/credits/") ||
    p.includes("/gpu/") ||
    p.includes("/ads/")
  ) {
    ahInvalidateCache([
      "/account/credit-pools",
      "/ads/reward/status",
      "/gpu/sessions",
      "/admin/users",
    ]);
  }

  if (
    p.includes("/auth/") ||
    p.includes("/session/") ||
    p.includes("/account/")
  ) {
    ahInvalidateCache([]);
  }

  if (p.includes("/system/")) {
    ahInvalidateCache([
      "/system/public-status",
      "/system/admin-status",
      "/admin/users",
    ]);
  }
}

async function cachedApi(path, options = {}, ttlMs = 10_000, cacheOptions = {}) {
  const method = String(options.method || "GET").toUpperCase();

  if (method !== "GET") {
    const result = await api(path, options);
    ahInvalidateForMutation(path);
    return result;
  }

  const force = Boolean(cacheOptions.force);
  const allowStale = cacheOptions.allowStale !== false;
  const key = ahCacheKey(path, options);
  const now = Date.now();
  const cached = ahApiCache.get(key);

  if (!force && cached) {
    const age = now - cached.time;

    if (age < ttlMs) {
      return cached.data;
    }

    if (allowStale) {
      // Return old data instantly, then refresh in background.
      if (!ahApiInflight.has(key)) {
        const refresh = api(path, options)
          .then((data) => {
            ahApiCache.set(key, {
              time: Date.now(),
              data,
            });

            // Let the page update when fresh data arrives.
            setTimeout(() => {
              try {
                renderPage();
              } catch {
                // ignore render failures
              }
            }, 0);

            return data;
          })
          .finally(() => {
            ahApiInflight.delete(key);
          });

        ahApiInflight.set(key, refresh);
      }

      return cached.data;
    }
  }

  if (!force && ahApiInflight.has(key)) {
    return ahApiInflight.get(key);
  }

  const promise = api(path, options)
    .then((data) => {
      ahApiCache.set(key, {
        time: Date.now(),
        data,
      });
      return data;
    })
    .finally(() => {
      ahApiInflight.delete(key);
    });

  ahApiInflight.set(key, promise);
  return promise;
}

// Make existing POST/PUT/DELETE api() calls invalidate cache automatically.
// This only wraps if api is assignable in this script.
try {
  if (typeof api === "function" && !window.__ahApiMutationCacheWrapped) {
    window.__ahApiMutationCacheWrapped = true;
    window.__ahOriginalApiForCache = api;

    api = async function(path, options = {}) {
      const method = String(options.method || "GET").toUpperCase();
      const result = await window.__ahOriginalApiForCache(path, options);

      if (method !== "GET") {
        ahInvalidateForMutation(path);
      }

      return result;
    };
  }
} catch (err) {
  console.warn("API cache mutation wrapper could not be installed:", err);
}

renderPage();
}

function nodeById(id) {
  return (adminStatus?.nodes || []).find((node) => node.id === id);
}

function serviceById(id) {
  return (
    (lastStatus?.apis || lastStatus?.services || []).find((service) => service.id === id)
  );
}

const NORMALIZED_INFRASTRUCTURE_IDS = [
  "controller-node",
  "server-nodes",
  "cpu-nodes",
  "gpu-nodes",
  "storage-nodes",
];

const NORMALIZED_PLATFORM_IDS = [
  "backend-api",
  "frontend-wrapper",
  "queue",
  "workers",
  "power-automation",
];

const NORMALIZED_INFRASTRUCTURE_DETAILS = {
  "controller-node": "Always-on laptop/main controller.",
  "server-nodes": "Configured Proxmox server nodes.",
  "cpu-nodes": "CPU processing containers currently configured.",
  "gpu-nodes": "Future GPU processing containers for image/video jobs.",
  "storage-nodes": "Future NAS/storage stations.",
};

const NORMALIZED_PLATFORM_DETAILS = {
  "backend-api": "Backend API and controller services.",
  "frontend-wrapper": "Public wrapper and browser experience.",
  queue: "Job queue and scheduling surface.",
  workers: "Worker capacity and processing services.",
  "power-automation": "Power automation status.",
};

function getNormalizedStatus(source = lastStatus) {
  const normalized = source?.normalized;
  if (!normalized || typeof normalized !== "object" || Array.isArray(normalized)) return null;
  return normalized;
}

function normalizedItems(source, key, requiredIds) {
  const normalized = getNormalizedStatus(source);
  const items = normalized?.[key];

  if (!Array.isArray(items) || !items.length) return null;

  const valid = items.filter((item) => (
    item &&
    typeof item === "object" &&
    typeof item.id === "string" &&
    item.id
  ));

  if (!valid.length) return null;

  const ids = new Set(valid.map((item) => item.id));
  if (!requiredIds.every((id) => ids.has(id))) return null;

  return valid;
}

function normalizedInfrastructureGroups(source = lastStatus) {
  const items = normalizedItems(source, "infrastructure", NORMALIZED_INFRASTRUCTURE_IDS);
  if (!items) return null; // Fallback to infrastructureGroups() when normalized.infrastructure is unavailable.

  return items.map((item) => {
    const members = Array.isArray(item.members) ? item.members : [];
    const state = item.state || "unknown";

    return {
      id: item.id,
      name: item.name || item.id,
      state,
      counts: statusCounts(members.map(() => state)),
      detail: item.detail || NORMALIZED_INFRASTRUCTURE_DETAILS[item.id] || "",
      members,
    };
  });
}

function normalizedPlatformGroups(source = lastStatus) {
  const items = normalizedItems(source, "platform", NORMALIZED_PLATFORM_IDS);
  if (!items) return null; // Fallback to apiGroups() when normalized.platform is unavailable.

  return items.map((item) => ({
    id: item.id,
    name: item.name || item.id,
    state: item.state || "unknown",
    detail: item.detail || NORMALIZED_PLATFORM_DETAILS[item.id] || "",
  }));
}

function statusCounts(states) {
  const counts = {
    total: states.length,
    online: 0,
    offline: 0,
    booting: 0,
    error: 0,
    degraded: 0,
    planned: 0,
    unknown: 0,
  };

  for (const state of states) {
    const clean = state || "unknown";
    if (counts[clean] === undefined) counts.unknown += 1;
    else counts[clean] += 1;
  }

  return counts;
}

function groupState(counts) {
  if (counts.error > 0) return "error";
  if (counts.booting > 0) return "booting";
  if (counts.degraded > 0) return "degraded";
  if (counts.total > 0 && counts.online === counts.total) return "online";
  if (counts.online > 0 && counts.offline > 0) return "degraded";
  if (counts.offline > 0) return "offline";
  if (counts.planned > 0) return "planned";
  return "unknown";
}

function makeInfraGroup({ id, name, states, detail }) {
  const counts = statusCounts(states);
  return {
    id,
    name,
    state: groupState(counts),
    counts,
    detail,
  };
}

function infrastructureGroups() {
  const controller = nodeById("master-laptop");
  const pveso = nodeById("pveso");
  const cpuNode = nodeById("ct-101");

  return [
    makeInfraGroup({
      id: "controller-node",
      name: "Controller Node",
      states: [controller?.state || "unknown"],
      detail: "Always-on laptop/main controller.",
    }),
    makeInfraGroup({
      id: "server-nodes",
      name: "Server Nodes",
      states: [pveso?.state || "offline"],
      detail: "Configured Proxmox server nodes.",
    }),
    makeInfraGroup({
      id: "cpu-nodes",
      name: "CPU Nodes",
      states: [cpuNode?.state || "offline"],
      detail: "CPU processing containers currently configured.",
    }),
    makeInfraGroup({
      id: "gpu-nodes",
      name: "GPU Nodes",
      states: [],
      detail: "Future GPU processing containers for image/video jobs.",
    }),
    makeInfraGroup({
      id: "storage-nodes",
      name: "Storage Nodes",
      states: [],
      detail: "Future NAS/storage stations.",
    }),
  ];
}

function normalizeApiState(service, fallback = "planned") {
  if (!service) return fallback;

  const detail = String(service.detail || "").toLowerCase();

  if (detail.includes("401") || detail.includes("403") || detail.includes("unauthorized")) {
    return "online";
  }

  return service.state || fallback;
}

function normalizeApiDetail(service, fallback) {
  if (!service) return fallback;

  const detail = String(service.detail || "");

  if (detail.includes("401") || detail.toLowerCase().includes("unauthorized")) {
    return "Protected API route is responding.";
  }

  return service.detail || fallback;
}

function apiGroups() {
  const study = serviceById("study-api");

  return [
    {
      id: "study-api",
      name: "Study API",
      state: normalizeApiState(study, "online"),
      detail: normalizeApiDetail(study, "Decks, cards, reviews, stats, and study progress are active."),
    },
    {
      id: "companion-api",
      name: "Companion API",
      state: "online",
      detail: "Companion chat, study grading, and context support are active.",
    },
    {
      id: "profile-api",
      name: "Profile API",
      state: "online",
      detail: "Account profile, preferences, permissions, and user settings are active.",
    },
    {
      id: "calendar-integrations",
      name: "Calendar Integrations",
      state: "planned",
      detail: "Future Apple Calendar and Google Calendar connections. Calendar data will stay with the provider and only be used temporarily when authorized.",
    },
    {
      id: "images-api",
      name: "Images API",
      state: "planned",
      detail: "Future ComfyUI-backed image generation for companion images and user-requested visuals.",
    },
  ];
}

function renderCards(cards) {
  return `
    <div class="cards">
      ${cards.map(([title, text, path]) => `
        <button class="card" type="button" data-go="${path}">
          <strong>${title}</strong>
          <span>${text}</span>
        </button>
      `).join("")}
    </div>
  `;
}

function renderBoxes(boxes) {
  return `
    <div class="summary-grid">
      ${boxes.map(([title, text]) => `
        <div class="summary-box">
          <span>${title}</span>
          <strong>${text}</strong>
        </div>
      `).join("")}
    </div>
  `;
}

function renderInfraCards(items) {
  return `
    <div class="summary-grid">
      ${items.map((item) => `
        <div class="summary-box">
          <div class="group-head">
            <span>${item.name}</span>
            <strong class="badge ${item.state}">${item.state}</strong>
          </div>

          <div class="count-line">${item.counts.total}</div>

          <div class="mini-counts">
            <span>Online ${item.counts.online}</span>
            <span>Offline ${item.counts.offline}</span>
            <span>Booting ${item.counts.booting}</span>
            <span>Error ${item.counts.error}</span>
          </div>

          <p>${item.detail}</p>
        </div>
      `).join("")}
    </div>
  `;
}

function safeText(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function renderLedgerRows(items) {
  const rows = items || [];

  if (!rows.length) {
    return `<div class="empty-list">No credit history yet.</div>`;
  }

  return `
    <div class="activity-list">
      ${rows.slice(0, 12).map((item) => `
        <div class="activity-row">
          <div>
            <strong>${safeText(item.reason || "credit event")}</strong>
            <span>${safeText(item.created_at || "")}</span>
          </div>
          <b class="${Number(item.delta || 0) >= 0 ? "positive" : "negative"}">
            ${Number(item.delta || 0) >= 0 ? "+" : ""}${formatNumber(item.delta || 0)}
          </b>
        </div>
      `).join("")}
    </div>
  `;
}

function renderReservationRows(items) {
  const rows = items || [];

  if (!rows.length) {
    return `<div class="empty-list">No recent reservations.</div>`;
  }

  return `
    <div class="activity-list">
      ${rows.slice(0, 12).map((item) => {
        const isReserved = item.status === "reserved";
        const freeAmount = Number(item.free_amount || 0);
        const paidAmount = Number(item.paid_amount || 0);

        return `
          <div class="activity-row">
            <div>
              <strong>${safeText(item.reason || "reservation")}</strong>
              <span>
                ${safeText(item.status || "unknown")} ·
                free ${formatNumber(freeAmount)} ·
                paid ${formatNumber(paidAmount)} ·
                ${safeText(item.created_at || "")}
              </span>
            </div>

            <div class="row-actions">
              <b>${formatNumber(item.amount || 0)}</b>
              ${isReserved ? `
                <button
                  class="mini-danger-btn"
                  type="button"
                  data-refund-token="${safeText(item.reservation_token || "")}"
                >
                  Cancel
                </button>
              ` : ""}
            </div>
          </div>
        `;
      }).join("")}
    </div>
  `;
}

function renderApiCards(items) {
  return `
    <div class="summary-grid">
      ${items.map((item) => `
        <div class="summary-box">
          <div class="group-head">
            <span>${item.name}</span>
            <strong class="badge ${item.state}">${item.state}</strong>
          </div>
          <p>${item.detail}</p>
        </div>
      `).join("")}
    </div>
  `;
}


// ============================================================
// CREDITS_AND_GPU_WORKFLOWS
// Shared /credits page code.
// Includes admin credit grants, free/paid credit pools,
// mock ad rewards, mock external GPU quotes, reservations,
// sessions, start/stop/cleanup.
// Do NOT remove this section when cleaning legacy admin/support UI.
// ============================================================

async function loadGpuCatalog({ force = false } = {}) {
  if (!authState.token) {
    gpuCatalog = null;
    return;
  }

  // GPU catalog is static in the mock provider, so do not refetch it on every status tick.
  if (!force && gpuCatalog?.items?.length) {
    return;
  }

  try {
    gpuCatalog = await api("/gpu/catalog", {
      method: "GET",
    });
  } catch {
    gpuCatalog = null;
  }
}

function moneyFromCents(cents) {
  const amount = Number(cents || 0) / 100;
  return amount.toLocaleString(undefined, {
    style: "currency",
    currency: "USD",
  });
}

function renderGpuOptions() {
  const items = gpuCatalog?.items || [];

  if (!items.length) {
    return `<option value="">No GPU options loaded</option>`;
  }

  return items.map((item) => `
    <option value="${safeText(item.gpu_id)}">
      ${safeText(item.name)} · ${formatNumber(item.vram_gb)}GB VRAM · ${moneyFromCents(item.provider_cost_cents_per_hour)}/hr provider cost
    </option>
  `).join("");
}

function renderGpuQuoteBox() {
  if (!gpuQuote?.quote) {
    return "";
  }

  const q = gpuQuote.quote;

  return `
    <div class="quote-box">
      <h3>Quote ready</h3>
      <div class="summary-grid">
        <div class="summary-box">
          <span>GPU</span>
          <strong>${safeText(q.gpu_name)}</strong>
          <p>${safeText(q.provider)} · ${formatNumber(q.duration_minutes)} minutes</p>
        </div>

        <div class="summary-box">
          <span>Estimated total</span>
          <strong>${moneyFromCents(q.total_cents)}</strong>
          <p>Provider: ${moneyFromCents(q.provider_cost_cents)} · Fees: ${moneyFromCents(q.fees_cents)} · Margin: ${moneyFromCents(q.margin_cents)}</p>
        </div>

        <div class="summary-box">
          <span>Paid credits required</span>
          <strong>${formatNumber(q.credits_required)}</strong>
          <p>Free/local credits cannot be used for external paid GPUs.</p>
        </div>

        <div class="summary-box">
          <span>Expires</span>
          <strong>${safeText(q.expires_at)}</strong>
          <p>Quotes expire before any real provider session starts.</p>
        </div>
      </div>

      <div class="actions">
        <button id="gpuReserveQuoteBtn" class="primary-btn" type="button">
          Reserve paid credits
        </button>
      </div>

      <div class="notice">
        Mock mode: this reserves paid credits only. It does not start a real cloud GPU yet.
      </div>
    </div>
  `;
}

function renderGpuReserveResult() {
  if (!gpuReserveResult?.gpu_quote) {
    return "";
  }

  const result = gpuReserveResult.gpu_quote;

  return `
    <div class="notice">
      ${safeText(result.detail || "Quote reserved.")}
      Paid credits reserved: ${formatNumber(result.paid_credits_reserved || 0)}.
    </div>

    <div class="actions">
      <button
        id="gpuStartSessionBtn"
        class="primary-btn"
        type="button"
        data-gpu-quote-token="${safeText(result.quote_token || "")}"
        data-gpu-reservation-token="${safeText(result.reservation_token || "")}"
      >
        Start mock session
      </button>
    </div>
  `;
}

async function refundReservationToken(token) {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  if (!token) {
    alert("Missing reservation token.");
    return;
  }

  const ok = confirm("Cancel this reservation and refund the held credits?");
  if (!ok) return;

  try {
    const result = await api("/credits/refund-v2", {
      method: "POST",
      body: JSON.stringify({
        reservation_token: token,
        metadata: {
          reason: "user_cancelled_from_credits_page",
        },
      }),
    });

    accountCredits = result;

    if (result.user) {
      authState.user = result.user;
    }

    renderPage();
  } catch (err) {
    alert(err.message);
  }
}

async function quoteMockGpuSession() {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  const gpuId = $("gpuQuoteSelect")?.value || "";
  const duration = Number($("gpuQuoteDuration")?.value || 30);

  if (!gpuId) {
    alert("Choose a GPU first.");
    return;
  }

  const button = $("gpuQuoteBtn");
  if (button) {
    button.disabled = true;
    button.textContent = "Getting quote...";
  }

  try {
    gpuQuote = await api("/gpu/quote", {
      method: "POST",
      body: JSON.stringify({
        gpu_id: gpuId,
        duration_minutes: duration,
      }),
    });

    gpuReserveResult = null;
    renderPage();
  } catch (err) {
    alert(err.message);
  } finally {
    if (button) {
      button.disabled = false;
      button.textContent = "Get quote";
    }
  }
}

async function reserveMockGpuQuote() {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  const quoteToken = gpuQuote?.quote?.quote_token;

  if (!quoteToken) {
    alert("Get a quote first.");
    return;
  }

  const button = $("gpuReserveQuoteBtn");
  if (button) {
    button.disabled = true;
    button.textContent = "Reserving...";
  }

  try {
    gpuReserveResult = await api("/gpu/reserve-quote", {
      method: "POST",
      body: JSON.stringify({
        quote_token: quoteToken,
      }),
    });

    accountCredits = gpuReserveResult;
    gpuQuote = null;

    if (gpuReserveResult.user) {
      authState.user = gpuReserveResult.user;
    }

    renderPage();
  } catch (err) {
    alert(err.message);
  } finally {
    if (button) {
      button.disabled = false;
      button.textContent = "Reserve paid credits";
    }
  }
}

async function loadGpuSessions() {
  gpuSessions = null;

  if (!authState.token) {
    return;
  }

  try {
    gpuSessions = await api("/gpu/sessions", {
      method: "GET",
    });
  } catch {
    gpuSessions = null;
  }
}

function renderGpuSessionsList() {
  const sessions = gpuSessions?.sessions || [];

  if (!sessions.length) {
    return `<div class="empty-list">No GPU sessions yet.</div>`;
  }

  return `
    <div class="activity-list">
      ${sessions.slice(0, 8).map((session) => `
        <div class="activity-row">
          <div>
            <strong>${safeText(session.gpu_name || session.gpu_id || "GPU session")}</strong>
            <span>
              ${safeText(session.status)} ·
              reserved ${formatNumber(session.credits_reserved || 0)} paid credits ·
              charged ${formatNumber(session.final_credits_charged || 0)} ·
              billable ${formatNumber(session.billable_minutes || 0)} min
            </span>
          </div>

          <div class="row-actions">
            <b>${safeText(session.status)}</b>
            ${session.status === "running" ? `
              <button
                class="mini-danger-btn"
                type="button"
                data-stop-gpu-session="${safeText(session.session_token || "")}"
              >
                Stop
              </button>

              <button
                class="mini-danger-btn"
                type="button"
                data-cleanup-gpu-session="${safeText(session.session_token || "")}"
              >
                Cleanup
              </button>
            ` : ""}
          </div>
        </div>
      `).join("")}
    </div>
  `;
}

async function startMockGpuSession(quoteToken, reservationToken) {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  if (!quoteToken && !reservationToken) {
    alert("Missing quote or reservation token.");
    return;
  }

  try {
    const result = await api("/gpu/start-reserved", {
      method: "POST",
      body: JSON.stringify({
        quote_token: quoteToken || undefined,
        reservation_token: reservationToken || undefined,
      }),
    });

    gpuReserveResult = null;
    gpuQuote = null;

    await loadAccountCredits();
    await loadGpuSessions();

    alert(result.detail || "Mock GPU session started.");
    forceRefreshAfterOperation("gpu-session-started");
    renderPage();
  } catch (err) {
    alert(err.message);
  }
}

async function cleanupMockGpuSession(sessionToken) {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  if (!sessionToken) {
    alert("Missing session token.");
    return;
  }

  const ok = confirm("Force-clean this stuck mock GPU session? This is for development testing only.");
  if (!ok) return;

  try {
    const result = await api("/gpu/cleanup-mock-session", {
      method: "POST",
      body: JSON.stringify({
        session_token: sessionToken,
      }),
    });

    accountCredits = result;

    await loadGpuSessions();

    if (result.user) {
      authState.user = result.user;
    }

    alert(result.gpu_session_cleanup?.detail || "Mock GPU session cleaned up.");
    forceRefreshAfterOperation("gpu-session-cleaned");
    renderPage();
  } catch (err) {
    alert(err.message);
  }
}

async function stopMockGpuSession(sessionToken) {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  if (!sessionToken) {
    alert("Missing session token.");
    return;
  }

  const ok = confirm("Stop this mock GPU session and commit actual used credits?");
  if (!ok) return;

  try {
    const result = await api("/gpu/stop-session", {
      method: "POST",
      body: JSON.stringify({
        session_token: sessionToken,
      }),
    });

    accountCredits = result;

    await loadGpuSessions();

    if (result.user) {
      authState.user = result.user;
    }

    alert(result.gpu_session?.detail || "Mock GPU session stopped.");
    forceRefreshAfterOperation("gpu-session-stopped");
    renderPage();
  } catch (err) {
    alert(err.message);
  }
}

// Shared Credits/Admin tool.
// Used by /credits for admin credit grants.
// Do NOT remove with legacy support/admin page code.
function renderAdminCreditGrant() {
  const user = authState.user || {};

  if (!user.is_admin) {
    return "";
  }

  return `
    <section class="system-section admin-only-section">
      <h2>Admin credit tools</h2>
      <p class="section-copy">
        Grant free/local credits or paid credits to a user account. Free credits can only be used on local services.
        Paid credits can be used for external GPU/cloud services.
      </p>

      <div class="admin-credit-panel">
        <label>
          User email
          <input id="adminGrantEmail" type="email" placeholder="user@example.com" value="${safeText(user.email || "")}" />
        </label>

        <label>
          Amount
          <input id="adminGrantAmount" type="number" min="1" step="1" value="100" />
        </label>

        <label>
          Credit type
          <select id="adminGrantType">
            <option value="free">Free/local credits</option>
            <option value="paid">Paid credits</option>
          </select>
        </label>

        <label>
          Reason
          <input id="adminGrantReason" type="text" value="admin_manual_grant" />
        </label>

        <button id="adminGrantCreditsBtn" class="primary-btn" type="button">
          Grant credits
        </button>
      </div>

      <div class="notice">
        Admin-only. Use paid credits carefully because they represent credits that can fund external paid resources.
      </div>
    </section>
  `;
}

async function adminGrantCredits() {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  const user = authState.user || {};
  if (!user.is_admin) {
    alert("Admin access required.");
    return;
  }

  const email = $("adminGrantEmail")?.value?.trim();
  const amount = Number($("adminGrantAmount")?.value || 0);
  const type = $("adminGrantType")?.value || "free";
  const reason = $("adminGrantReason")?.value?.trim() || "admin_manual_grant";

  if (!email) {
    alert("Enter a user email.");
    return;
  }

  if (!Number.isFinite(amount) || amount < 1) {
    alert("Amount must be at least 1.");
    return;
  }

  const confirmText =
    type === "paid"
      ? `Grant ${formatNumber(amount)} PAID credits to ${email}?`
      : `Grant ${formatNumber(amount)} free/local credits to ${email}?`;

  if (!confirm(confirmText)) {
    return;
  }

  const endpoint = type === "paid" ? "/credits/grant-paid" : "/credits/grant-free";

  const button = $("adminGrantCreditsBtn");
  if (button) {
    button.disabled = true;
    button.textContent = "Granting...";
  }

  try {
    const result = await api(endpoint, {
      method: "POST",
      body: JSON.stringify({
        email,
        amount,
        reason,
        metadata: {
          source: "credits_page_admin_ui",
        },
      }),
    });

    accountCredits = result;

    if (result.user && result.user.email === authState.user?.email) {
      authState.user = result.user;
    }

    await loadAccountCredits();

    alert(`Granted ${formatNumber(amount)} ${type} credits to ${email}.`);
    renderPage();
  } catch (err) {
    alert(err.message);
  } finally {
    if (button) {
      button.disabled = false;
      button.textContent = "Grant credits";
    }
  }
}

async function loadAdminPanelData() {
  // Legacy admin loader disabled.
  // Active admin page uses cleanLoadAdminData().
  return;
}

async function loadSupportData() {
  // Legacy support loader disabled.
  // Active support page uses cleanLoadSupportTickets().
  return;
}

async function loadSupportThread(ticketId) {
  if (!authState.token || !ticketId) {
    return;
  }

  try {
    supportThread = await api(`/support/tickets/${ticketId}/messages`, {
      method: "GET",
    });
    renderPage();
  } catch (err) {
    alert(err.message);
  }
}

function renderAdminUsers() {
  const users = adminUsers?.users || [];

  if (!users.length) {
    return `<div class="empty-list">No users loaded yet.</div>`;
  }

  return `
    <div class="admin-table-wrap">
      <table class="admin-table">
        <thead>
          <tr>
            <th>User</th>
            <th>Online</th>
            <th>Role</th>
            <th>Plan</th>
            <th>Free</th>
            <th>Paid</th>
            <th>Last seen</th>
          </tr>
        </thead>
        <tbody>
          ${users.map((u) => `
            <tr>
              <td>${safeText(u.email || "")}</td>
              <td><span class="badge ${u.online ? "online" : "offline"}">${u.online ? "online" : "offline"}</span></td>
              <td>${safeText(u.role || "user")}</td>
              <td>${safeText(u.plan || "free")}</td>
              <td>${formatNumber(u.free_credit_balance || 0)}</td>
              <td>${formatNumber(u.paid_credit_balance || 0)}</td>
              <td>${safeText(u.last_seen_at || "")}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    </div>
  `;
}

function renderAdminSupportInbox() {
  const tickets = adminTickets?.tickets || [];

  if (!tickets.length) {
    return `<div class="empty-list">No support tickets yet.</div>`;
  }

  return `
    <div class="activity-list">
      ${tickets.map((ticket) => `
        <div class="activity-row">
          <div>
            <strong>#${ticket.id} · ${safeText(ticket.subject)}</strong>
            <span>
              ${safeText(ticket.email || "")} ·
              ${safeText(ticket.status)} ·
              ${formatNumber(ticket.message_count || 0)} messages ·
              ${safeText(ticket.last_message_at || ticket.updated_at || "")}
            </span>
          </div>
          <div class="row-actions">
            <button class="primary-btn mini-primary-btn" type="button" data-open-ticket="${ticket.id}">
              Open
            </button>
          </div>
        </div>
      `).join("")}
    </div>
  `;
}

function renderAdminSystemStatus() {
  const payload = adminSystemStatus || {};
  const nodes = payload.nodes || [];
  const services = payload.services || [];

  if (!authState.user?.is_admin) {
    return `<div class="notice">Admin access required.</div>`;
  }

  if (!payload.ok && !nodes.length && !services.length) {
    return `<div class="empty-list">Admin system status not loaded yet.</div>`;
  }

  return `
    <div class="summary-grid">
      <div class="summary-box">
        <span>Infrastructure visibility</span>
        <strong>Admin only</strong>
        <p>This detailed node view is hidden from normal users.</p>
      </div>
      <div class="summary-box">
        <span>Overall</span>
        <strong>${safeText(payload.overall_state || "unknown")}</strong>
        <p>${safeText(payload.admin_email || authState.user?.email || "")}</p>
      </div>
      <div class="summary-box">
        <span>Nodes</span>
        <strong>${formatNumber(nodes.length)}</strong>
        <p>Controller, server, CPU/GPU, and future storage nodes.</p>
      </div>
      <div class="summary-box">
        <span>APIs</span>
        <strong>${formatNumber(services.length)}</strong>
        <p>Study, Companion, Profile, Calendar, Images, and related APIs.</p>
      </div>
    </div>

    <h3>Nodes</h3>
    <div class="status-list">
      ${nodes.map((node) => `
        <div class="status-item">
          <div class="status-row">
            <div class="status-name">${safeText(node.name || node.id || "Node")}</div>
            <div class="badge ${safeText(node.state || "unknown")}">${safeText(node.state || "unknown")}</div>
          </div>
          <div class="status-detail">${safeText(node.detail || node.role || "")}</div>
        </div>
      `).join("")}
    </div>

    <h3>APIs / Services</h3>
    <div class="status-list">
      ${services.map((svc) => `
        <div class="status-item">
          <div class="status-row">
            <div class="status-name">${safeText(svc.name || svc.id || "Service")}</div>
            <div class="badge ${safeText(svc.state || "unknown")}">${safeText(svc.state || "unknown")}</div>
          </div>
          <div class="status-detail">${safeText(svc.detail || "")}</div>
        </div>
      `).join("")}
    </div>
  `;
}

function renderSupportTicketList(tickets) {
  const rows = tickets || [];

  if (!rows.length) {
    return `<div class="empty-list">No tickets yet.</div>`;
  }

  return `
    <div class="activity-list">
      ${rows.map((ticket) => `
        <div class="activity-row">
          <div>
            <strong>#${ticket.id} · ${safeText(ticket.subject)}</strong>
            <span>
              ${safeText(ticket.status)} ·
              ${formatNumber(ticket.message_count || 0)} messages ·
              ${safeText(ticket.last_message_at || ticket.updated_at || "")}
            </span>
          </div>
          <div class="row-actions">
            <button class="primary-btn mini-primary-btn" type="button" data-open-ticket="${ticket.id}">
              Open
            </button>
          </div>
        </div>
      `).join("")}
    </div>
  `;
}

function renderSupportThread() {
  if (!supportThread?.ticket) {
    return "";
  }

  return `
    <section class="system-section">
      <h2>Ticket #${supportThread.ticket.id}: ${safeText(supportThread.ticket.subject)}</h2>
      <p class="section-copy">
        Status: ${safeText(supportThread.ticket.status)} · Created: ${safeText(supportThread.ticket.created_at)}
      </p>

      <div class="message-thread">
        ${(supportThread.messages || []).map((message) => `
          <div class="message-bubble ${message.sender_role === "admin" ? "admin-message" : "user-message"}">
            <div class="message-meta">
              ${safeText(message.sender_role)} · ${safeText(message.sender_email || "")} · ${safeText(message.created_at)}
            </div>
            <div>${safeText(message.body)}</div>
          </div>
        `).join("")}
      </div>

      <div class="support-reply-box">
        <textarea id="supportReplyBody" rows="4" placeholder="Write a reply..."></textarea>
        <div class="actions">
          <button id="supportReplyBtn" class="primary-btn" type="button" data-ticket-id="${supportThread.ticket.id}">
            Send reply
          </button>
        </div>
      </div>
    </section>
  `;
}



async function createSupportTicket() {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  const subject = $("supportSubject")?.value?.trim() || "";
  const body = $("supportBody")?.value?.trim() || "";

  if (subject.length < 3) {
    alert("Subject must be at least 3 characters.");
    return;
  }

  if (body.length < 5) {
    alert("Message must be at least 5 characters.");
    return;
  }

  try {
    const result = await api("/support/tickets", {
      method: "POST",
      body: JSON.stringify({ subject, body }),
    });

    supportThread = null;
    await loadSupportData();

    alert(`Support ticket #${result.ticket?.id} created.`);
    renderPage();
  } catch (err) {
    alert(err.message);
  }
}

async function sendSupportReply(ticketId) {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  const body = $("supportReplyBody")?.value?.trim() || "";

  if (body.length < 2) {
    alert("Reply must be at least 2 characters.");
    return;
  }

  try {
    const selectedStatus = cleanIsAdmin()
      ? (document.getElementById("cleanSupportReplyStatus")?.value || "waiting_user")
      : "waiting_admin";

    await api(`/support/tickets/${ticketId}/messages`, {
      method: "POST",
      body: JSON.stringify({
        body,
        status: selectedStatus,
      }),
    });

    await loadSupportThread(ticketId);

    if (authState.user?.is_admin) {
      await loadAdminPanelData();
    } else {
      await loadSupportData();
    }

    renderPage();
  } catch (err) {
    alert(err.message);
  }
}


// ============================================================
// CREDITS_PAGE_RENDER
// Main /credits page renderer.
// Depends on CREDITS_AND_GPU_WORKFLOWS functions above.
// ============================================================


function formatRewardCooldown(seconds) {
  const value = Math.max(0, Number(seconds || 0));
  const mins = Math.floor(value / 60);
  const secs = value % 60;
  if (mins <= 0) return `${secs}s`;
  return `${mins}m ${secs}s`;
}


function adRewardProvider() {
  return adRewardStatus?.provider || {};
}

function googleRewardedConfig() {
  return adRewardProvider()?.google_gpt || {};
}

function canUseGoogleRewardedAds() {
  const provider = adRewardProvider();

  return Boolean(
    provider?.provider === "google_gpt" &&
    provider?.ready &&
    googleRewardedConfig()?.enabled &&
    googleRewardedConfig()?.ad_unit_path
  );
}

function setGoogleRewardedMessage(message) {
  googleRewardedMessage = message || "";
  renderPage();
}

function ensureGooglePublisherTag() {
  if (window.googletag?.apiReady || window.googletag?.cmd) {
    window.googletag = window.googletag || { cmd: [] };
    window.googletag.cmd = window.googletag.cmd || [];
    return Promise.resolve(window.googletag);
  }

  window.googletag = window.googletag || { cmd: [] };
  window.googletag.cmd = window.googletag.cmd || [];

  return new Promise((resolve, reject) => {
    const existing = document.querySelector('script[data-google-publisher-tag="true"]');

    if (existing) {
      existing.addEventListener("load", () => resolve(window.googletag), { once: true });
      existing.addEventListener("error", () => reject(new Error("Google Publisher Tag failed to load.")), { once: true });
      return;
    }

    const script = document.createElement("script");
    script.async = true;
    script.src = "https://securepubads.g.doubleclick.net/tag/js/gpt.js";
    script.dataset.googlePublisherTag = "true";
    script.onload = () => resolve(window.googletag);
    script.onerror = () => reject(new Error("Google Publisher Tag failed to load."));
    document.head.appendChild(script);
  });
}


function makeGoogleRewardedEventId() {
  if (window.crypto?.randomUUID) {
    return `google-gpt-${Date.now()}-${window.crypto.randomUUID()}`;
  }

  return `google-gpt-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function safeRewardPayload(payload) {
  try {
    return JSON.parse(JSON.stringify(payload || {}));
  } catch {
    return {
      value: String(payload || ""),
    };
  }
}

async function claimGoogleRewardedCredit(rewardPayload = {}) {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  if (!adRewardProvider()?.client_claim_enabled) {
    setGoogleRewardedMessage("Reward earned, but client credit claiming is disabled.");
    return;
  }

  if (!googleRewardedEventId) {
    googleRewardedEventId = makeGoogleRewardedEventId();
  }

  setGoogleRewardedMessage("Reward earned. Claiming free credits...");

  const result = await api("/ads/reward/claim", {
    method: "POST",
    body: JSON.stringify({
      provider: "google_gpt",
      reward_event_id: googleRewardedEventId,
      metadata: {
        placement: "credits_page",
        mode: "google_gpt_client",
        reward_payload: safeRewardPayload(rewardPayload),
      },
    }),
  });

  accountCredits = result;
  adRewardStatus = result.reward_status || null;

  if (result.user) {
    authState.user = result.user;
  }

  const granted = result?.ad_reward?.credits_granted ?? 0;
  const duplicate = Boolean(result?.ad_reward?.duplicate);

  setGoogleRewardedMessage(
    duplicate
      ? "Reward was already claimed. Your balance is up to date."
      : `Reward claimed. ${granted} free credits added.`
  );
}


async function loadGoogleRewardedAd() {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  if (!canUseGoogleRewardedAds()) {
    setGoogleRewardedMessage(adRewardProvider()?.detail || "Rewarded ads are not configured yet.");
    return;
  }

  if (!adRewardStatus?.can_claim) {
    setGoogleRewardedMessage(adRewardStatus?.blocked_reason || "Rewarded ads are not available right now.");
    return;
  }

  if (googleRewardedLoading) return;

  const button = $("showGoogleRewardedAdBtn");
  if (button) {
    button.disabled = true;
    button.textContent = "Loading ad...";
  }

  googleRewardedLoading = true;
  googleRewardedGranted = false;
  googleRewardedReadyEvent = null;
  googleRewardedEventId = makeGoogleRewardedEventId();
  googleRewardedMessage = "Loading rewarded ad...";

  try {
    const googletag = await ensureGooglePublisherTag();
    const adUnitPath = googleRewardedConfig().ad_unit_path;

    googletag.cmd.push(() => {
      try {
        if (googleRewardedSlot) {
          googletag.destroySlots([googleRewardedSlot]);
          googleRewardedSlot = null;
        }

        googleRewardedSlot = googletag.defineOutOfPageSlot(
          adUnitPath,
          googletag.enums.OutOfPageFormat.REWARDED
        );

        if (!googleRewardedSlot) {
          googleRewardedLoading = false;
          setGoogleRewardedMessage("Rewarded ad slot could not be created for this device/browser.");
          return;
        }

        googleRewardedSlot.addService(googletag.pubads());

        googletag.pubads().addEventListener("rewardedSlotReady", (event) => {
          if (event.slot !== googleRewardedSlot) return;

          googleRewardedReadyEvent = event;
          googleRewardedLoading = false;
          setGoogleRewardedMessage("Rewarded ad is ready. Opening ad...");
          event.makeRewardedVisible();
        });

        googletag.pubads().addEventListener("rewardedSlotGranted", async (event) => {
          if (event.slot !== googleRewardedSlot) return;

          googleRewardedGranted = true;

          if (adRewardProvider()?.client_claim_enabled) {
            try {
              await claimGoogleRewardedCredit(event?.payload || {});
            } catch (err) {
              setGoogleRewardedMessage(err.message || "Reward earned, but credit claim failed.");
            }
          } else {
            setGoogleRewardedMessage("Reward earned in browser test. Credit claiming is still disabled until final verification is enabled.");
          }
        });

        googletag.pubads().addEventListener("rewardedSlotClosed", (event) => {
          if (event.slot !== googleRewardedSlot) return;

          if (googleRewardedSlot) {
            googletag.destroySlots([googleRewardedSlot]);
            googleRewardedSlot = null;
          }

          googleRewardedLoading = false;

          if (!googleRewardedGranted) {
            setGoogleRewardedMessage("Rewarded ad closed before a reward was granted.");
          }
        });

        googletag.enableServices();
        googletag.display(googleRewardedSlot);
      } catch (err) {
        googleRewardedLoading = false;
        setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
      }
    });
  } catch (err) {
    googleRewardedLoading = false;
    setGoogleRewardedMessage(err.message || "Rewarded ad failed to load.");
  } finally {
    setTimeout(() => {
      const latestButton = $("showGoogleRewardedAdBtn");
      if (latestButton && !googleRewardedLoading) {
        latestButton.disabled = false;
        latestButton.textContent = "Load rewarded ad";
      }
    }, 0);
  }
}


function adRewardUiState(status) {
  const remaining = Number(status?.cooldown?.remaining_seconds || 0);
  const dailyUsed = Number(status?.daily?.used || 0);
  const dailyLimit = Number(status?.daily?.limit || 0);
  const monthlyUsed = Number(status?.monthly?.used || 0);
  const monthlyLimit = Number(status?.monthly?.limit || 0);

  if (!status) {
    return {
      label: "Loading",
      detail: "Checking rewarded-ad availability.",
      button: "Checking...",
      disabled: true,
    };
  }

  if (status.can_claim) {
    return {
      label: "Available",
      detail: status.blocked_reason || "Rewarded ad claim is available.",
      button: "Earn free credits",
      disabled: false,
    };
  }

  if (remaining > 0) {
    return {
      label: "Cooldown",
      detail: `Try again in ${formatRewardCooldown(remaining)}.`,
      button: `Cooldown ${formatRewardCooldown(remaining)}`,
      disabled: true,
    };
  }

  if (dailyLimit && dailyUsed >= dailyLimit) {
    return {
      label: "Daily limit reached",
      detail: "You have reached today's rewarded-ad limit.",
      button: "Daily limit reached",
      disabled: true,
    };
  }

  if (monthlyLimit && monthlyUsed >= monthlyLimit) {
    return {
      label: "Monthly limit reached",
      detail: "You have reached this month's rewarded-ad limit.",
      button: "Monthly limit reached",
      disabled: true,
    };
  }

  return {
    label: "Locked",
    detail: status.blocked_reason || "Rewarded ad claim is not available yet.",
    button: "Locked",
    disabled: true,
  };
}

function renderCreditsPage() {
  const loggedIn = Boolean(authState.token);
  const live = accountCredits || {};
  const user = live.user || authState.user || {};
  const credits = live.credits || {};

  const normalizedCredits = normalizeCreditsPayload(live);
  const freeAvailable = credits.free_available ?? normalizedCredits.free ?? 0;
  const paidAvailable = credits.paid_available ?? normalizedCredits.paid ?? 0;
  const totalAvailable = credits.total_available ?? credits.available ?? normalizedCredits.available ?? user.credit_balance ?? 0;

  const freeReserved = credits.free_reserved ?? 0;
  const paidReserved = credits.paid_reserved ?? 0;
  const totalReserved = credits.total_reserved ?? credits.reserved ?? 0;

  const monthlyFree = credits.monthly_free_allowance ?? credits.monthly_allowance ?? user.monthly_credit_allowance ?? 0;
  const monthlyPaid = credits.monthly_paid_allowance ?? 0;
  const storage = credits.storage_quota_mb ?? user.storage_quota_mb ?? 0;
  const plan = credits.plan || user.plan || (loggedIn ? "free" : "not logged in");
  const billing = credits.billing_status || user.billing_status || "none";
  const rewardProvider = adRewardProvider();
  const googleProvider = googleRewardedConfig();
  const showMockRewardButton = isLocalDevHost() || Boolean(adRewardStatus?.mock_enabled);
  const showGoogleRewardButton = !showMockRewardButton && canUseGoogleRewardedAds();
  const rewardUi = adRewardUiState(adRewardStatus);

  return `
    ${loggedIn ? `
      <section class="system-section">
        <h2>Your credits</h2>
        <p class="section-copy">
          Credits are the platform currency for companion usage, AI jobs, storage, RAG indexing,
          image generation, and future cloud GPU sessions.
        </p>

        <div class="summary-grid">
          <div class="summary-box">
            <span>Free/local credits</span>
            <strong>${formatNumber(freeAvailable)}</strong>
            <p>Can only be used on local platform services running on your hardware.</p>
          </div>

          <div class="summary-box">
            <span>Paid credits</span>
            <strong>${formatNumber(paidAvailable)}</strong>
            <p>Can be used for local services or external paid cloud resources.</p>
          </div>

          <div class="summary-box">
            <span>Total available</span>
            <strong>${formatNumber(totalAvailable)}</strong>
            <p>Combined free and paid credits.</p>
          </div>

          <div class="summary-box">
            <span>Reserved credits</span>
            <strong>${formatNumber(totalReserved)}</strong>
            <p>Free reserved: ${formatNumber(freeReserved)} · Paid reserved: ${formatNumber(paidReserved)}</p>
          </div>

          <div class="summary-box">
            <span>Monthly free allowance</span>
            <strong>${formatNumber(monthlyFree)}</strong>
            <p>Promotional/local monthly credits.</p>
          </div>

          <div class="summary-box">
            <span>Monthly paid allowance</span>
            <strong>${formatNumber(monthlyPaid)}</strong>
            <p>Paid monthly credits from future subscriptions.</p>
          </div>

          <div class="summary-box">
            <span>Storage quota</span>
            <strong>${formatNumber(storage)} MB</strong>
            <p>Used for uploaded files, future RAG data, generated assets, and companion memory.</p>
          </div>
        </div>

        <div class="summary-grid">
          <div class="summary-box">
            <span>Current plan</span>
            <strong>${safeText(plan)}</strong>
            <p>Billing status: ${safeText(billing)}</p>
          </div>

          <div class="summary-box">
            <span>Account</span>
            <strong>${safeText(user.email || "Logged in")}</strong>
            <p>${user.is_admin ? "Admin account" : "Standard account"}</p>
          </div>
        </div>
      </section>

      <section class="system-section">
        <h2>Earn free/local credits</h2>
        <p class="section-copy">
          Watch rewarded ads to earn free/local credits. These credits can only be used on local services;
          they cannot be used for external cloud GPUs, paid storage, or other services that cost real money.
        </p>

        <div class="summary-grid">
          <div class="summary-box">
            <span>Reward</span>
            <strong>${formatNumber(adRewardStatus?.reward_credits || 5)} free credits</strong>
            <p>Credit pool: free/local only.</p>
          </div>

          <div class="summary-box">
            <span>Daily rewarded ads</span>
            <strong>${formatNumber(adRewardStatus?.daily?.used || 0)} / ${formatNumber(adRewardStatus?.daily?.limit || 5)}</strong>
            <p>Monthly: ${formatNumber(adRewardStatus?.monthly?.used || 0)} / ${formatNumber(adRewardStatus?.monthly?.limit || 100)}</p>
          </div>

          <div class="summary-box">
            <span>Status</span>
            <strong>${safeText(rewardUi.label)}</strong>
            <p>${safeText(rewardUi.detail)}</p>
          </div>

          <div class="summary-box">
            <span>Provider</span>
            <strong>${safeText(rewardProvider?.provider || "none")}</strong>
            <p>${safeText(rewardProvider?.detail || "No rewarded-ad provider status loaded yet.")}</p>
          </div>

          <div class="summary-box">
            <span>Claim mode</span>
            <strong>${rewardProvider?.client_claim_enabled ? "Client claim enabled" : "Claim disabled"}</strong>
            <p>${rewardProvider?.provider_verification_enabled ? "Provider verification enabled." : "Provider verification is not enabled yet."}</p>
          </div>
        </div>

        ${showMockRewardButton ? `
          <div class="actions">
            <button
              id="claimAdRewardBtn"
              class="primary-btn"
              type="button"
              ${rewardUi.disabled ? "disabled" : ""}
            >
              ${safeText(rewardUi.button)}
            </button>
          </div>

          <div class="notice">
            Mock rewarded-ad testing is enabled. This grants free/local credits only and still obeys daily, monthly, and cooldown limits.
          </div>
        ` : showGoogleRewardButton ? `
          <div class="actions">
            <button
              id="showGoogleRewardedAdBtn"
              class="primary-btn"
              type="button"
              ${rewardUi.disabled || googleRewardedLoading ? "disabled" : ""}
            >
              ${googleRewardedLoading ? "Loading ad..." : "Load rewarded ad"}
            </button>
          </div>

          <div class="notice">
            Google rewarded ads are configured for ${safeText(googleProvider?.ad_unit_path || "this site")}.
            ${safeText(googleRewardedMessage || "Credit claiming remains disabled until final verification is enabled.")}
          </div>
        ` : `
          <div class="actions">
            <button class="primary-btn" type="button" disabled>
              Earn free credits coming soon
            </button>
          </div>

          <div class="notice">
            ${safeText(rewardProvider?.detail || "Rewarded ads will be enabled after a real provider is connected.")}
            Ad-earned credits will be free/local credits only.
          </div>
        `}
      </section>

      ${renderAdminCreditGrant()}

      <section class="system-section">
        <h2>Recent credit history</h2>
        <p class="section-copy">
          Every credit change should appear here so billing and usage are auditable.
        </p>
        ${renderLedgerRows(live.ledger || [])}
      </section>

      <section class="system-section">
        <h2>Recent reservations</h2>
        <p class="section-copy">
          Reservations hold credits before expensive jobs start, then commit or refund when done.
        </p>
        ${renderReservationRows(live.reservations || [])}
      </section>
    ` : `
      <div class="notice">
        Log in to see your current credits, plan, billing status, storage quota, and credit history.
      </div>
    `}

    <section class="system-section">
      <h2>External GPU sessions</h2>
      <p class="section-copy">
        Quote mock cloud GPU sessions and reserve paid credits. Free/local credits cannot be used here.
        This does not start a real cloud GPU yet.
      </p>

      ${loggedIn ? `
        <div class="gpu-quote-panel">
          <label>
            GPU
            <select id="gpuQuoteSelect">
              ${renderGpuOptions()}
            </select>
          </label>

          <label>
            Duration minutes
            <input id="gpuQuoteDuration" type="number" min="5" max="1440" step="5" value="30" />
          </label>

          <button id="gpuQuoteBtn" class="primary-btn" type="button">
            Get quote
          </button>
        </div>

        ${renderGpuQuoteBox()}
        ${renderGpuReserveResult()}
      ` : `
        <div class="notice">
          Log in to quote and reserve external GPU sessions.
        </div>
      `}
    </section>

    <section class="system-section">
      <h2>GPU session history</h2>
      <p class="section-copy">
        Mock GPU session history. Running sessions can be stopped to commit actual used credits and release unused paid credits.
      </p>
      ${loggedIn ? renderGpuSessionsList() : `<div class="notice">Log in to view GPU sessions.</div>`}
    </section>

    <section class="system-section">
      <h2>Monthly plans</h2>
      <p class="section-copy">
        Draft tiers for testing the business model. Checkout will be connected later.
      </p>

      <div class="pricing-grid">
        <div class="pricing-card">
          <span class="plan-label">Free</span>
          <strong>$0 / month</strong>
          <p>Good for trying the platform.</p>
          <ul>
            <li>100 monthly credits</li>
            <li>100 MB storage</li>
            <li>Study summaries</li>
            <li>Basic companion usage</li>
          </ul>
          <button class="ghost-btn" type="button" disabled>Free</button>
        </div>

        <div class="pricing-card featured">
          <span class="plan-label">Starter</span>
          <strong>$9 / month</strong>
          <p>For regular study and companion use.</p>
          <ul>
            <li>1,000 monthly credits</li>
            <li>1 GB storage</li>
            <li>More companion messages</li>
            <li>Standard queue priority</li>
          </ul>
          <button class="primary-btn" type="button" disabled>Coming soon</button>
        </div>

        <div class="pricing-card">
          <span class="plan-label">Pro</span>
          <strong>$25 / month</strong>
          <p>For heavy users and future image tools.</p>
          <ul>
            <li>5,000 monthly credits</li>
            <li>10 GB storage</li>
            <li>Priority queue</li>
            <li>Image generation access</li>
          </ul>
          <button class="primary-btn" type="button" disabled>Coming soon</button>
        </div>
      </div>
    </section>

    <section class="system-section">
      <h2>Credit packs</h2>
      <p class="section-copy">
        Credit packs are useful when users run out before their monthly refresh.
      </p>

      <div class="pricing-grid">
        <div class="pricing-card">
          <span class="plan-label">Small pack</span>
          <strong>500 credits</strong>
          <p>$5 draft price</p>
          <button class="primary-btn" type="button" disabled>Coming soon</button>
        </div>

        <div class="pricing-card featured">
          <span class="plan-label">Value pack</span>
          <strong>1,200 credits</strong>
          <p>$10 draft price</p>
          <button class="primary-btn" type="button" disabled>Coming soon</button>
        </div>

        <div class="pricing-card">
          <span class="plan-label">Power pack</span>
          <strong>3,500 credits</strong>
          <p>$25 draft price</p>
          <button class="primary-btn" type="button" disabled>Coming soon</button>
        </div>
      </div>
    </section>
  `;
}


function renderSystemPage() {
  const isAdmin = Boolean(adminStatus?.admin);
  const platformGroups = normalizedPlatformGroups() || apiGroups();
  const infraGroups = normalizedInfrastructureGroups() || infrastructureGroups();

  return `
    <section class="system-section">
      <h2>APIs</h2>
      <p class="section-copy">
        Public users can see whether platform API areas are online, degraded, offline, or planned.
      </p>
      ${renderApiCards(platformGroups)}
    </section>

    ${isAdmin ? `
      <section class="system-section">
        <h2>Infrastructure</h2>
        <p class="section-copy">
          Admin-only view of controller, server, CPU, GPU, and storage node capacity.
        </p>
        ${renderInfraCards(infraGroups)}
      </section>
    ` : ""}

    ${isAdmin ? `
      <div class="actions">
        <button class="primary-btn" type="button" id="openSystemBtn">Open Admin System Panel</button>
        <button class="primary-btn" type="button" id="wakeLoginBtn">${authState.token ? "Wake Services Soon" : "Login to Wake Services"}</button>
      </div>
    ` : ""}
  `;
}

function renderPage() {
  const path = routePath();
  const page = pages[path];

  document.title = `${page.title} | AlexHartel AI Platform`;
  setActiveNav(path);
  setSystemHeaderState();
  renderAuthButtons();

  $("adminNavLink")?.classList.toggle("hidden", !authState.user?.is_admin);

  const isHome = path === "/";
  const isSystem = path === "/system";
  const isCredits = path === "/credits";
  const isAdmin = path === "/admin";
  const isSupport = path === "/support";

  $("app").innerHTML = `
    <section class="${isHome ? "hero-card" : "page-card"}">
      <p class="eyebrow">${page.eyebrow}</p>
      <h1>${page.title}</h1>
      <p class="subtitle">${page.subtitle}</p>

      ${page.cards ? renderCards(page.cards) : ""}
      ${page.boxes?.length ? renderBoxes(page.boxes) : ""}
      ${isCredits ? renderCreditsPage() : ""}
      ${""}
      ${isSystem ? renderSystemPage() : ""}
    </section>
  `;

  document.querySelectorAll("[data-go]").forEach((btn) => {
    btn.addEventListener("click", () => navigate(btn.getAttribute("data-go")));
  });

  $("openSystemBtn")?.addEventListener("click", openSystemDrawer);
  $("wakeLoginBtn")?.addEventListener("click", () => {
    if (!authState.token) openAuthModal("login");
    else alert("Login-aware wake/session automation will be connected next.");
  });

  $("claimAdRewardBtn")?.addEventListener("click", claimMockAdReward);
  $("showGoogleRewardedAdBtn")?.addEventListener("click", loadGoogleRewardedAd);
  $("gpuQuoteBtn")?.addEventListener("click", quoteMockGpuSession);
  $("gpuReserveQuoteBtn")?.addEventListener("click", reserveMockGpuQuote);
  $("adminGrantCreditsBtn")?.addEventListener("click", adminGrantCredits);

  $("supportCreateTicketBtn")?.addEventListener("click", createSupportTicket);
  $("supportReplyBtn")?.addEventListener("click", (event) => {
    sendSupportReply(event.currentTarget.dataset.ticketId);
  });

  document.querySelectorAll("[data-open-ticket]").forEach((button) => {
    button.addEventListener("click", () => loadSupportThread(button.dataset.openTicket));
  });

  $("gpuStartSessionBtn")?.addEventListener("click", (buttonEvent) => {
    const button = buttonEvent.currentTarget;
    startMockGpuSession(button.dataset.gpuQuoteToken, button.dataset.gpuReservationToken);
  });

  document.querySelectorAll("[data-stop-gpu-session]").forEach((button) => {
    button.addEventListener("click", () => stopMockGpuSession(button.dataset.stopGpuSession));
  });
  document.querySelectorAll("[data-cleanup-gpu-session]").forEach((button) => {
    button.addEventListener("click", () => cleanupMockGpuSession(button.dataset.cleanupGpuSession));
  });
  document.querySelectorAll("[data-refund-token]").forEach((button) => {
    button.addEventListener("click", () => refundReservationToken(button.dataset.refundToken));
  });
}

function renderDrawerItems(targetId, items, type) {
  const target = $(targetId);
  if (!target) return;

  target.innerHTML = "";

  for (const item of items || []) {
    const state = item.state || "unknown";

    const row = document.createElement("div");
    row.className = "status-item";

    if (type === "infra") {
      row.innerHTML = `
        <div class="status-row">
          <div class="status-name"></div>
          <div class="badge ${state}"></div>
        </div>
        <div class="status-detail"></div>
      `;

      row.querySelector(".status-name").textContent = item.name || item.id || "Unknown";
      row.querySelector(".badge").textContent = state;
      row.querySelector(".status-detail").textContent =
        `Total ${item.counts.total}, Online ${item.counts.online}, Offline ${item.counts.offline}, Booting ${item.counts.booting}, Error ${item.counts.error}. ${item.detail}`;
    } else {
      row.innerHTML = `
        <div class="status-row">
          <div class="status-name"></div>
          <div class="badge ${state}"></div>
        </div>
        <div class="status-detail"></div>
      `;

      row.querySelector(".status-name").textContent = item.name || item.id || "Unknown";
      row.querySelector(".badge").textContent = state;
      row.querySelector(".status-detail").textContent = item.detail || "";
    }

    target.appendChild(row);
  }
}

function renderSystemDrawer() {
  const isAdmin = Boolean(adminStatus?.admin);
  const platformGroups = normalizedPlatformGroups() || apiGroups();
  const infraGroups = normalizedInfrastructureGroups() || infrastructureGroups();

  $("drawerSummary").textContent =
    `API state: ${titleCase(lastStatus?.overall_state || "unknown")}. Last checked: ${lastStatus?.checked_at || "unknown"}.`;

  if (isAdmin) {
    renderDrawerItems("drawerNodes", infraGroups, "infra");
  } else {
    renderDrawerItems("drawerNodes", [], "api");
  }

  renderDrawerItems("drawerServices", platformGroups, "api");
}

function openSystemDrawer() {
  $("systemDrawer").classList.remove("hidden");
  renderSystemDrawer();
}

function closeSystemDrawer() {
  $("systemDrawer").classList.add("hidden");
}

async function loadAdRewardStatus() {
  adRewardStatus = null;

  if (!authState.token) {
    return;
  }

  try {
    adRewardStatus = await api("/ads/reward/status", {
      method: "GET",
    });
  } catch {
    adRewardStatus = null;
  }
}

async function claimMockAdReward() {
  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  const button = $("claimAdRewardBtn");
  if (button) {
    button.disabled = true;
    button.textContent = "Checking reward...";
  }

  try {
    const result = await api("/ads/reward/claim", {
      method: "POST",
      body: JSON.stringify({
        provider: "mock_rewarded_ad",
        reward_event_id: `local-${Date.now()}-${Math.random().toString(16).slice(2)}`,
        metadata: {
          placement: "credits_page",
          mode: "local_mock",
        },
      }),
    });

    accountCredits = result;
    adRewardStatus = result.reward_status || null;

    if (result.user) {
      authState.user = result.user;
    }

    renderPage();
  } catch (err) {
    alert(err.message);
  } finally {
    if (button) {
      button.disabled = false;
      button.textContent = "Watch mock ad";
    }
  }
}

async function loadAccountCredits({ deep = false } = {}) {
  if (!authState.token) {
    accountCredits = null;
    gpuSessions = null;
    adRewardStatus = null;
    return;
  }

  const shouldLoadCreditPageData = deep || location.pathname === "/credits";

  try {
    const tasks = [
      api("/account/credit-pools", { method: "GET" }),
    ];

    if (shouldLoadCreditPageData) {
      tasks.push(loadAdRewardStatus().then(() => null));
      tasks.push(loadGpuCatalog().then(() => null));
      tasks.push(loadGpuSessions().then(() => null));
    }

    const [creditsResult] = await Promise.all(tasks);
    accountCredits = creditsResult;

    if (accountCredits?.user) {
      authState.user = accountCredits.user;
    }
  } catch {
    accountCredits = null;
  }
}

let systemStatusLoadInFlight = null;

async function loadSystemStatus() {
  if (!pageIsActive()) return;

  if (systemStatusLoadInFlight) {
    return systemStatusLoadInFlight;
  }

  systemStatusLoadInFlight = (async () => {
  try {
    const data = await api("/system/public-status", {
      method: "GET",
    });
    lastStatus = data;
  } catch (err) {
    lastStatus = {
      ok: false,
      overall_state: "unknown",
      checked_at: new Date().toISOString(),
      apis: [],
      services: [],
      error: err.message,
    };
  }

  // Keep system polling lightweight.
  // Credits/GPU/rewards load only on /credits, after login, or after credit-changing actions.
  // Admin infrastructure loads only inside the Admin page via cleanLoadAdminData().
  adminStatus = null;

  renderPage();
  renderSystemDrawer();
  })();

  try {
    return await systemStatusLoadInFlight;
  } finally {
    systemStatusLoadInFlight = null;
  }
}



function ensureResendVerificationButton() {
  const authForm = $("authForm");
  if (!authForm) return null;

  let btn = $("resendVerificationBtn");
  if (!btn) {
    btn = document.createElement("button");
    btn.id = "resendVerificationBtn";
    btn.className = "ghost-btn";
    btn.type = "button";
    btn.hidden = true;
    btn.textContent = "Resend verification email";
    btn.addEventListener("click", resendVerificationEmail);
    authForm.appendChild(btn);
  }

  return btn;
}

function emailVerificationMessageElement() {
  const authForm = $("authForm");
  if (!authForm) return null;

  ensureResendVerificationButton();

  let el = $("authVerificationMessage");
  if (!el) {
    el = document.createElement("div");
    el.id = "authVerificationMessage";
    el.className = "notice";
    el.style.marginTop = "12px";
    el.style.whiteSpace = "normal";

    const submitBtn = $("authSubmitBtn");
    if (submitBtn && submitBtn.parentNode) {
      submitBtn.parentNode.insertBefore(el, submitBtn.nextSibling);
    } else {
      authForm.appendChild(el);
    }
  }

  return el;
}

function setEmailVerificationMessage(message, isError = false) {
  const el = emailVerificationMessageElement();
  if (!el) return;

  el.textContent = message || "";
  el.classList.toggle("error", Boolean(isError));
  el.hidden = !message;
}

function clearEmailVerificationMessage() {
  const el = $("authVerificationMessage");
  if (el) {
    el.textContent = "";
    el.hidden = true;
  }
}

function rememberPendingVerificationEmail(email) {
  pendingVerificationEmail = String(email || "").trim().toLowerCase();

  if (pendingVerificationEmail) {
    try {
      sessionStorage.setItem("pendingVerificationEmail", pendingVerificationEmail);
    } catch {}
  }
}

function loadPendingVerificationEmail() {
  if (pendingVerificationEmail) return pendingVerificationEmail;

  try {
    pendingVerificationEmail = sessionStorage.getItem("pendingVerificationEmail") || "";
  } catch {
    pendingVerificationEmail = "";
  }

  return pendingVerificationEmail;
}

function isVerificationRequiredResponse(data) {
  return Boolean(data && data.verification_required);
}

async function handleVerificationRequiredResponse(data) {
  const email =
    data?.email ||
    (typeof authEmail !== "undefined" ? authEmail : "") ||
    $("authEmail")?.value ||
    "";

  rememberPendingVerificationEmail(email);

  setAuthMode("login");

  const authEmailInput = $("authEmail");
  if (authEmailInput && pendingVerificationEmail) {
    authEmailInput.value = pendingVerificationEmail;
  }

  setEmailVerificationMessage(
    data?.message || "Check your email to finish creating your account."
  );

  const resendBtn = $("resendVerificationBtn");
  if (resendBtn) {
    resendBtn.hidden = false;
  }
}

async function resendVerificationEmail() {
  const email = loadPendingVerificationEmail() || $("authEmail")?.value || "";

  if (!email || !email.includes("@")) {
    setEmailVerificationMessage("Enter your email address first.", true);
    return;
  }

  const btn = $("resendVerificationBtn");
  if (btn) {
    btn.disabled = true;
    btn.textContent = "Sending...";
  }

  try {
    const data = await api("/auth/resend-verification", {
      method: "POST",
      body: JSON.stringify({ email }),
    });

    rememberPendingVerificationEmail(data?.email || email);
    setEmailVerificationMessage(
      data?.message || "Verification email sent. Check your inbox."
    );
  } catch (err) {
    setEmailVerificationMessage(err.message || "Could not resend verification email.", true);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.textContent = "Resend verification email";
    }
  }
}

function showPageNotice(message, isError = false) {
  let el = $("pageNotice");

  if (!el) {
    el = document.createElement("div");
    el.id = "pageNotice";
    el.className = "notice";
    el.style.margin = "16px auto";
    el.style.maxWidth = "860px";

    const main = document.querySelector("main") || document.body;
    main.insertBefore(el, main.firstChild);
  }

  el.textContent = message || "";
  el.classList.toggle("error", Boolean(isError));
  el.hidden = !message;
}

async function handleVerifyEmailRoute() {
  const url = new URL(window.location.href);

  if (url.pathname !== "/verify-email") {
    return false;
  }

  const token = url.searchParams.get("token") || "";

  if (!token) {
    showPageNotice("Verification link is missing a token.", true);
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");
    return true;
  }

  showPageNotice("Verifying your email address...");

  try {
    const data = await api(`/auth/verify-email?token=${encodeURIComponent(token)}`);

    const session = data?.session || {};
    const accessToken = data?.access_token || session?.access_token || "";
    const user = data?.user || null;

    if (accessToken) {
      authState.token = accessToken;
      authState.user = user;
      saveAuthState();

      showPageNotice("Email verified. You are signed in.");
      window.history.replaceState({}, "", "/");

      setTimeout(() => {
        window.location.href = "/";
      }, 700);

      return true;
    }

    showPageNotice("Email verified. Please log in.");
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");

    const userEmail = user?.email || loadPendingVerificationEmail();
    if ($("authEmail") && userEmail) {
      $("authEmail").value = userEmail;
    }

    setEmailVerificationMessage("Email verified. Log in to continue.");

    setTimeout(() => {
      window.location.href = "/login";
    }, 900);
  } catch (err) {
    const message = err.message || "Email verification failed.";

    showPageNotice(message, true);
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");
    setEmailVerificationMessage(message, true);

    setTimeout(() => {
      window.location.href = "/login";
    }, 1200);
  }

  return true;
}


function setAuthMode(mode) {
  authMode = mode === "register" ? "register" : "login";

  $("authTitle").textContent = authMode === "register" ? "Register" : "Login";
  $("authSubtitle").textContent =
    authMode === "register"
      ? "Create an account to use platform services."
      : "Sign in to access your dashboard and future live services.";

  $("authSubmitBtn").textContent = authMode === "register" ? "Send verification email" : "Login";
  if (authMode === "register") {
    clearEmailVerificationMessage();
  }
  $("loginTabBtn").classList.toggle("active", authMode === "login");
  $("registerTabBtn").classList.toggle("active", authMode === "register");
}

function openAuthModal(mode = "login") {
  ensureResendVerificationButton();
  setAuthMode(mode);
  $("authMessage").classList.add("hidden");
  $("authModal").classList.remove("hidden");
  $("authEmail").focus();
}

function closeAuthModal() {
  $("authModal").classList.add("hidden");
}

async function handleAuthSubmit(event) {
  event.preventDefault();

  const email = $("authEmail").value.trim();
  const password = $("authPassword").value;

  $("authSubmitBtn").disabled = true;
  $("authSubmitBtn").textContent = authMode === "register" ? "Sending..." : "Logging in...";

  try {
    const data = await api(authMode === "register" ? "/auth/register" : "/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });

    if (authMode === "register" && isVerificationRequiredResponse(data)) {
      await handleVerificationRequiredResponse(data);
      return;
    }


    const token =
      data.token ||
      data.access_token ||
      data.jwt ||
      data.session?.access_token ||
      data.session?.token ||
      "";

    if (!token) {
      throw new Error("Login response did not include a token.");
    }

    authState.token = token;
    authState.user = data.user || { email };
    localStorage.setItem("edgeStudyToken", token);
    authState.token = token;
    syncAuthRouteCookie();
    if (refreshPrivateRouteAfterAuth("login")) return;
    authState.token = token;
    syncAuthRouteCookie();
    if (refreshPrivateRouteAfterAuth("login")) return;
    syncAuthRouteCookie();

    try {
      const me = await api("/me", { method: "GET" });
      authState.user = me.user || me;
    } catch {
      // Keep login successful even if account refresh fails.
    }

    closeAuthModal();
    await loadSystemStatus();
    renderPage();
  } catch (err) {
    $("authMessage").textContent = err.message;
    $("authMessage").classList.remove("hidden");
  } finally {
    $("authSubmitBtn").disabled = false;
    $("authSubmitBtn").textContent = authMode === "register" ? "Register" : "Login";
  }
}

async function logout() {
  try {
    if (authState.token) {
      await api("/auth/logout", {
        method: "POST",
        body: JSON.stringify({}),
      });
    }
  } catch {
    // Local logout should still happen even if remote logout fails.
  }

  authState.token = "";
  authState.user = null;
  localStorage.removeItem("edgeStudyToken");
  syncAuthRouteCookie();
  await loadSystemStatus();
  renderPage();
}

async function checkExistingLogin() {
  if (!authState.token) {
    renderAuthButtons();
    return;
  }

  try {
    const data = await api("/me", {
      method: "GET",
    });
    authState.user = data.user || data;
  } catch {
    authState.token = "";
    authState.user = null;
    localStorage.removeItem("edgeStudyToken");
  syncAuthRouteCookie();
  }

  renderAuthButtons();
  await loadSystemStatus();
  renderPage();
}

document.addEventListener("click", (event) => {
  const link = event.target.closest("[data-route]");
  if (!link) return;

  const path = link.getAttribute("data-route");
  if (!pages[path]) return;

  event.preventDefault();
  navigate(path);
});

window.addEventListener("popstate", renderPage);

$("drawerCloseBtn").addEventListener("click", closeSystemDrawer);
$("authOpenBtn").addEventListener("click", () => openAuthModal("login"));
$("logoutBtn").addEventListener("click", logout);
$("authCloseBtn").addEventListener("click", closeAuthModal);
$("loginTabBtn").addEventListener("click", () => setAuthMode("login"));
$("registerTabBtn").addEventListener("click", () => setAuthMode("register"));
$("resendVerificationBtn")?.addEventListener("click", resendVerificationEmail);
$("authForm")./*
 * Stage 5F-43: queued-chat submit insertion guard marker.
 *
 * Future queued-chat submit wiring may be inserted near this marker.
 *
 * Requirements for any future wiring:
 * - call AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH.shouldUseQueuedChatForSubmit at most once
 * - call only after the user submit payload is available
 * - call before the legacy non-queued assistant request
 * - preserve legacy submit behavior while the queued-chat flag is false
 * - do not render duplicate user messages
 * - do not render duplicate assistant placeholders
 * - do not create duplicate queued jobs
 * - do not start duplicate polling loops
 *
 * Stage 5F-43 is marker-only.
 * It does not call the decision helper.
 * It does not call the queued send helper.
 * It does not change submit behavior.
 */

/*
 * /*
 * Stage 5F-63: guarded live-submit gate marker.
 *
 * Future live queued-chat submit selection should pass through this gate.
 *
 * Safety:
 * - marker only near live submit path
 * - frontend queued-chat flag remains off by default
 * - live submit behavior remains unchanged
 * - no queued orchestration call
 * - no queued send call
 * - no queued polling
 * - no queued placeholder rendering
 */
/*
 * Stage 5F-60: guarded live-submit branch marker.
 *
 * Future live queued-chat submit selection may be inserted here after a
 * dedicated wired-stage smoke proves flag-off behavior remains unchanged.
 *
 * Safety:
 * - marker only
 * - feature flag remains off by default
 * - legacy submit remains active
 * - no queued orchestration call
 * - no queued send call
 * - no polling
 * - no placeholder rendering
 */
Stage 5F-57: guarded queued submit branch skeleton marker.
 *
 * Future guarded queued-chat submit wiring may be inserted here.
 *
 * Safety:
 * - skeleton marker only
 * - queued chat remains disabled by default
 * - legacy submit remains active
 * - does not call queued orchestration
 * - does not call queued send
 * - does not start queued polling
 * - does not render queued placeholders
 * - does not send client-provided identity fields
 */
addEventListener("submit", handleAuthSubmit);

renderPage();
checkExistingLogin();
loadSystemStatus();
setInterval(loadSystemStatus, 60000);


// ============================================================


// ============================================================


// ============================================================
// ACTIVE_SUPPORT_AND_ADMIN_UI
// Current active /support and /admin page implementation.
// This is the active layer. Do not replace with old legacy
// renderSupportPage()/renderAdminPage() functions.
// ============================================================

// CLEAN_ADMIN_SUPPORT_PAGES_V4
// Keeps old header. Adds working /admin and /support pages.
// Moves admin-only infrastructure from /system to /admin.
// ============================================================

let cleanAdminUsers = null;
let cleanAdminTickets = null;
let cleanAdminSystem = null;
let cleanPowerPolicy = null;
let cleanSupportTickets = null;
let cleanOpenThread = null;

function pageIsActive() {
  return document.visibilityState !== "hidden";
}

function cleanIsLoggedIn() {
  return Boolean(authState?.token);
}

function cleanIsAdmin() {
  return Boolean(authState?.user?.is_admin);
}

function cleanEsc(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function cleanNum(value) {
  return Number(value || 0).toLocaleString();
}

function cleanSyncNav() {
  const adminLink = document.getElementById("adminNavLink");
  if (adminLink) {
    adminLink.classList.toggle("hidden", !cleanIsAdmin());
  }

  const supportLink = document.querySelector('[data-route="/support"]');
  if (supportLink) {
    // Normal users use the Support page.
    // Admins use the Admin panel Support Inbox instead.
    supportLink.classList.toggle("hidden", cleanIsAdmin());
  }
}

async function cleanHeartbeat() {
  if (!cleanIsLoggedIn()) return;
  if (!pageIsActive()) return;

  try {
    // Session presence used to require a bearer token.
    // Web presence below is cookie-aware and handles anonymous/logged-in users.
    await sendWebPresence({ force: true });
  } catch {
    // ignore presence errors
  }
}

async function cleanLoadSupportTickets() {
  if (!cleanIsLoggedIn()) {
    cleanSupportTickets = null;
    return;
  }

  try {
    cleanSupportTickets = await cachedApi("/support/tickets", { method: "GET" }, AH_CACHE_TTL.SUPPORT_TICKETS);
  } catch (err) {
    cleanSupportTickets = { ok: false, tickets: [], detail: err.message };
  }
}

async function cleanLoadPowerPolicy() {
  if (!cleanIsAdmin()) {
    cleanPowerPolicy = null;
    return;
  }

  try {
    if (typeof cachedApi === "function") {
      cleanPowerPolicy = await cachedApi(
        "/presence/power-policy",
        { method: "GET" },
        10_000,
        { force: true }
      );
    } else {
      cleanPowerPolicy = await api("/presence/power-policy", {
        method: "GET",
      });
    }
  } catch (err) {
    cleanPowerPolicy = {
      ok: false,
      error: err.message,
    };
  }
}

async function cleanLoadAdminData() {
  if (!cleanIsLoggedIn() || !cleanIsAdmin()) {
    cleanAdminUsers = null;
    cleanAdminTickets = null;
    cleanAdminSystem = null;
    return;
  }

  await cleanHeartbeat();

  const [users, tickets, system] = await Promise.allSettled([
    api("/admin/users", { method: "GET" }),
    api("/admin/support/tickets", { method: "GET" }),
    api("/system/admin-status", { method: "GET" }),
  ]);

  cleanAdminUsers = users.status === "fulfilled"
    ? users.value
    : { ok: false, users: [], detail: users.reason?.message || "Failed to load users." };

  cleanAdminTickets = tickets.status === "fulfilled"
    ? tickets.value
    : { ok: false, tickets: [], detail: tickets.reason?.message || "Failed to load tickets." };

  cleanAdminSystem = system.status === "fulfilled"
    ? system.value
    : { ok: false, nodes: [], services: [], detail: system.reason?.message || "Failed to load system status." };
}

async function cleanLoadRouteData() {
  if (location.pathname === "/support") {
    await cleanLoadSupportTickets();
  }

  if (location.pathname === "/admin") {
    await cleanLoadAdminData();
  }
}

function cleanTicketRows(tickets, adminMode = false) {
  const rows = tickets || [];

  if (!rows.length) {
    return `<div class="empty-list">No support tickets yet.</div>`;
  }

  return `
    <div class="activity-list">
      ${rows.map((ticket) => `
        <div class="activity-row">
          <div>
            <strong>#${ticket.id} · ${cleanEsc(ticket.subject)}</strong>
            <span>
              ${adminMode ? `${cleanEsc(ticket.email || "")} · ` : ""}
              ${cleanEsc(ticket.status || "open")} ·
              ${cleanNum(ticket.message_count || 0)} messages ·
              ${cleanEsc(ticket.last_message_at || ticket.updated_at || "")}
            </span>
          </div>
          <div class="row-actions">
            <button class="primary-btn mini-primary-btn" type="button" data-clean-open-ticket="${ticket.id}">
              Open
            </button>
          </div>
        </div>
      `).join("")}
    </div>
  `;
}

async function cleanOpenTicket(ticketId) {
  if (!cleanIsLoggedIn()) return;

  try {
    cleanOpenThread = await api(`/support/tickets/${ticketId}/messages`, { method: "GET" });
    cleanRenderNow();
  } catch (err) {
    alert(err.message);
  }
}

function cleanRenderThread() {
  if (!cleanOpenThread?.ticket) return "";

  const ticket = cleanOpenThread.ticket;
  const messages = cleanOpenThread.messages || [];

  return `
    <section class="system-section">
      <h2>Ticket #${ticket.id}: ${cleanEsc(ticket.subject)}</h2>
      <p class="section-copy">
        Status: ${cleanEsc(ticket.status)} · Created: ${cleanEsc(ticket.created_at)}
      </p>

      <div class="message-thread">
        ${messages.map((m) => `
          <div class="message-bubble ${m.sender_role === "admin" ? "admin-message" : "user-message"}">
            <div class="message-meta">
              ${cleanEsc(m.sender_role)} · ${cleanEsc(m.sender_email || "")} · ${cleanEsc(m.created_at)}
            </div>
            <div>${cleanEsc(m.body)}</div>
          </div>
        `).join("")}
      </div>

      <div class="support-reply-box">
        <textarea id="cleanSupportReplyBody" rows="4" placeholder="Write a reply..."></textarea>

        ${cleanIsAdmin() ? `
          <label class="support-status-label">
            Ticket status after reply
            <select id="cleanSupportReplyStatus">
              <option value="waiting_user">Waiting on user</option>
              <option value="solved">Solved</option>
              <option value="waiting_admin">Waiting on admin</option>
            </select>
          </label>
        ` : ""}

        <div class="actions">
          <button class="primary-btn" type="button" data-clean-reply-ticket="${ticket.id}">
            Send reply
          </button>

          ${ticket.status !== "solved" ? `
            <button class="secondary-btn" type="button" data-clean-solve-ticket="${ticket.id}">
              Mark solved
            </button>
          ` : `
            <button class="secondary-btn" type="button" data-clean-reopen-ticket="${ticket.id}">
              Reopen ticket
            </button>
          `}
        </div>
      </div>
    </section>
  `;
}

async function cleanCreateSupportTicket() {
  if (!cleanIsLoggedIn()) {
    openAuthModal("login");
    return;
  }

  const subject = document.getElementById("cleanSupportSubject")?.value?.trim() || "";
  const body = document.getElementById("cleanSupportBody")?.value?.trim() || "";

  if (subject.length < 3) {
    alert("Subject must be at least 3 characters.");
    return;
  }

  if (body.length < 5) {
    alert("Message must be at least 5 characters.");
    return;
  }

  try {
    const result = await api("/support/tickets", {
      method: "POST",
      body: JSON.stringify({ subject, body }),
    });

    cleanOpenThread = null;
    await cleanLoadSupportTickets();

    alert(`Support ticket #${result.ticket?.id || ""} created.`);
    forceRefreshAfterOperation("support-ticket-created");
    cleanRenderNow();
  } catch (err) {
    alert(err.message);
  }
}

async function cleanSetTicketStatus(ticketId, status) {
  if (!cleanIsLoggedIn()) {
    openAuthModal("login");
    return;
  }

  if (!ticketId || !status) {
    alert("Missing ticket or status.");
    return;
  }

  let note = "";

  if (status === "solved") {
    const ok = confirm("Mark this support ticket as solved?");
    if (!ok) return;
    note = "Marked ticket as solved.";
  }

  if (status === "waiting_admin") {
    note = "Reopened ticket. Waiting on admin.";
  }

  try {
    await api(`/support/tickets/${ticketId}/status`, {
      method: "POST",
      body: JSON.stringify({
        status,
        note,
      }),
    });

    await cleanOpenTicket(ticketId);
    await cleanLoadSupportTickets();

    if (cleanIsAdmin()) {
      await cleanLoadAdminData();
    }

    cleanRenderNow();
  } catch (err) {
    alert(err.message);
  }
}

async function cleanSendReply(ticketId) {
  const body = document.getElementById("cleanSupportReplyBody")?.value?.trim() || "";

  if (body.length < 2) {
    alert("Reply must be at least 2 characters.");
    return;
  }

  try {
    await api(`/support/tickets/${ticketId}/messages`, {
      method: "POST",
      body: JSON.stringify({ body }),
    });

    await cleanOpenTicket(ticketId);
    await cleanLoadSupportTickets();

    if (cleanIsAdmin()) {
      await cleanLoadAdminData();
    }

    cleanRenderNow();
  } catch (err) {
    alert(err.message);
  }
}

function cleanRenderSupportSummary() {
  return `
    <section class="hero">
      <p class="eyebrow">Support</p>
      <h1>Help when something is not working</h1>
      <p>
        Support gives users a direct way to contact customer support, track open tickets,
        read admin replies, and mark issues solved once the problem is fixed.
      </p>
    </section>

    <section class="card-grid">
      <a class="feature-card" href="/support" data-route="/support">
        <h3>Send a message</h3>
        <p>Logged-in users can create a support ticket with a subject and message.</p>
      </a>

      <a class="feature-card" href="/support" data-route="/support">
        <h3>Track ticket status</h3>
        <p>Tickets move through waiting on admin, waiting on user, and solved states.</p>
      </a>

      <a class="feature-card" href="/support" data-route="/support">
        <h3>Keep replies organized</h3>
        <p>Each ticket keeps the full conversation in one place so users and admins have context.</p>
      </a>

      <a class="feature-card" href="/support" data-route="/support">
        <h3>Resolve issues clearly</h3>
        <p>Users or admins can mark a ticket solved when the issue is fixed.</p>
      </a>
    </section>

    <section class="system-section">
      <h2>What support helps with</h2>
      <div class="summary-grid">
        <div class="summary-box">
          <span>Account help</span>
          <strong>Login, profile, access</strong>
          <p>Get help when account tools, login, or profile settings are not working.</p>
        </div>

        <div class="summary-box">
          <span>Credits and billing</span>
          <strong>Balances and charges</strong>
          <p>Ask about free credits, paid credits, reservations, refunds, and future billing issues.</p>
        </div>

        <div class="summary-box">
          <span>Study and companion</span>
          <strong>Learning tools</strong>
          <p>Report issues with decks, reviews, companion replies, or learning workflows.</p>
        </div>

        <div class="summary-box">
          <span>Platform issues</span>
          <strong>System problems</strong>
          <p>Report slow pages, broken buttons, offline services, or unexpected errors.</p>
        </div>
      </div>
    </section>
  `;
}

function cleanRenderSupportPage() {
  if (!cleanIsLoggedIn()) {
    return `
      ${cleanRenderSupportSummary()}

      <section class="system-section">
        <h2>Need help?</h2>
        <p class="section-copy">
          Log in to send a message to customer support and view your ticket history.
        </p>
        <div class="actions">
          <button class="primary-btn" type="button" data-clean-login>Log in to contact support</button>
        </div>
      </section>
    `;
  }

  return `
    <section class="hero">
      <p class="eyebrow">Support</p>
      <h1>Customer Support</h1>
      <p>Send a message if you need account, credit, billing, study, companion, or platform help.</p>
    </section>

    <section class="system-section">
      <h2>Message customer support</h2>
      <div class="support-form">
        <label>
          Subject
          <input id="cleanSupportSubject" type="text" placeholder="Short description of the issue" />
        </label>

        <label>
          Message
          <textarea id="cleanSupportBody" rows="5" placeholder="Describe what happened and what you expected."></textarea>
        </label>

        <button id="cleanCreateSupportTicketBtn" class="primary-btn" type="button">
          Send message
        </button>
      </div>
    </section>

    <section class="system-section">
      <h2>Your support tickets</h2>
      ${cleanSupportTickets ? cleanTicketRows(cleanSupportTickets.tickets || []) : `<div class="empty-list">Loading support tickets...</div>`}
    </section>

    ${cleanRenderThread()}
  `;
}

function cleanGroupCounts(groupNodes) {
  const counts = {
    online: 0,
    offline: 0,
    booting: 0,
    error: 0,
  };

  for (const node of groupNodes) {
    const state = node.state || "unknown";
    if (state in counts) counts[state] += 1;
  }

  return counts;
}

function cleanGroupCard(title, state, nodes, description) {
  const counts = cleanGroupCounts(nodes);
  const total = nodes.length;

  return `
    <div class="summary-box infrastructure-card">
      <div class="group-head">
        <span>${cleanEsc(title)}</span>
        <div class="badge ${cleanEsc(state || "unknown")}">${cleanEsc(state || "unknown")}</div>
      </div>
      <div class="count-line">${cleanNum(total)}</div>
      <p>
        Online ${cleanNum(counts.online)}
        Offline ${cleanNum(counts.offline)}
        Booting ${cleanNum(counts.booting)}
        Error ${cleanNum(counts.error)}
      </p>
      <p>${cleanEsc(description)}</p>
    </div>
  `;
}

function cleanWorstState(nodes) {
  if (!nodes.length) return "unknown";
  if (nodes.some((n) => n.state === "error")) return "error";
  if (nodes.some((n) => n.state === "booting")) return "booting";
  if (nodes.some((n) => n.state === "offline")) return "offline";
  if (nodes.every((n) => n.state === "online")) return "online";
  return nodes[0].state || "unknown";
}

function cleanRenderInfrastructure() {
  const nodes = cleanAdminSystem?.nodes || [];
  const normalizedGroups = normalizedInfrastructureGroups(cleanAdminSystem);

  if (normalizedGroups) {
    return `
      <section class="system-section">
        <h2>Infrastructure</h2>
        <p class="section-copy">
          Admin-only view of controller, server, CPU, GPU, and storage node capacity.
        </p>

        <div class="summary-grid">
          ${normalizedGroups.map((group) => {
            const memberNodes = (group.members || []).map(() => ({ state: group.state }));
            return cleanGroupCard(group.name, group.state, memberNodes, group.detail);
          }).join("")}
        </div>

        <div class="actions">
          <button id="cleanToggleAdminSystemDetailsBtn" class="primary-btn" type="button">
            Open Admin System Panel
          </button>
        </div>

        <div id="cleanAdminSystemDetails" class="hidden">
          ${cleanRenderAdminSystemDetails()}
        </div>
      </section>
    `;
  }

  const controllerNodes = nodes.filter((n) => n.role === "master" || n.id === "master-laptop");
  const serverNodes = nodes.filter((n) => n.role === "compute-host" || n.id === "pveso");

  // Current design: only LLM/Ollama container counts as CPU node.
  // GPU and Storage nodes are future groups until explicitly registered.
  const cpuNodes = nodes.filter((n) =>
    n.role === "container" &&
    (
      String(n.id || "").includes("101") ||
      String(n.name || "").toLowerCase().includes("llm") ||
      JSON.stringify(n.services || []).toLowerCase().includes("ollama")
    )
  );

  const gpuNodes = [];
  const storageNodes = [];

  return `
    <section class="system-section">
      <h2>Infrastructure</h2>
      <p class="section-copy">
        Admin-only view of controller, server, CPU, GPU, and storage node capacity.
      </p>

      <div class="summary-grid">
        ${cleanGroupCard("Controller Node", cleanWorstState(controllerNodes), controllerNodes, "Always-on laptop/main controller.")}
        ${cleanGroupCard("Server Nodes", cleanWorstState(serverNodes), serverNodes, "Configured Proxmox server nodes.")}
        ${cleanGroupCard("CPU Nodes", cleanWorstState(cpuNodes), cpuNodes, "CPU processing containers currently configured.")}
        ${cleanGroupCard("GPU Nodes", cleanWorstState(gpuNodes), gpuNodes, "Future GPU processing containers for image/video jobs.")}
        ${cleanGroupCard("Storage Nodes", cleanWorstState(storageNodes), storageNodes, "Future NAS/storage stations.")}
      </div>

      <div class="actions">
        <button id="cleanToggleAdminSystemDetailsBtn" class="primary-btn" type="button">
          Open Admin System Panel
        </button>
      </div>

      <div id="cleanAdminSystemDetails" class="hidden">
        ${cleanRenderAdminSystemDetails()}
      </div>
    </section>
  `;
}

function cleanRenderAdminSystemDetails() {
  const nodes = cleanAdminSystem?.nodes || [];
  const services = cleanAdminSystem?.services || [];

  return `
    <section class="system-section">
      <h2>Admin system details</h2>

      <h3>Nodes</h3>
      <div class="status-list">
        ${nodes.map((n) => `
          <div class="status-item">
            <div class="status-row">
              <div class="status-name">${cleanEsc(n.name || n.id)}</div>
              <div class="badge ${cleanEsc(n.state || "unknown")}">${cleanEsc(n.state || "unknown")}</div>
            </div>
            <div class="status-detail">${cleanEsc(n.detail || n.role || "")}</div>
          </div>
        `).join("")}
      </div>

      <h3>APIs / Services</h3>
      <div class="status-list">
        ${services.map((svc) => `
          <div class="status-item">
            <div class="status-row">
              <div class="status-name">${cleanEsc(svc.name || svc.id)}</div>
              <div class="badge ${cleanEsc(svc.state || "unknown")}">${cleanEsc(svc.state || "unknown")}</div>
            </div>
            <div class="status-detail">${cleanEsc(svc.detail || "")}</div>
          </div>
        `).join("")}
      </div>
    </section>
  `;
}

function cleanAdminCreditToolHtml() {
  const email = authState?.user?.email || "";

  return `
    <section class="system-section admin-only-section">
      <h2>Admin credit tools</h2>
      <p class="section-copy">Grant free/local credits or paid credits to a user account.</p>

      <div class="admin-credit-panel">
        <label>
          User email
          <input id="cleanAdminGrantEmail" type="email" placeholder="user@example.com" value="${cleanEsc(email)}" />
        </label>

        <label>
          Amount
          <input id="cleanAdminGrantAmount" type="number" min="1" step="1" value="100" />
        </label>

        <label>
          Credit type
          <select id="cleanAdminGrantType">
            <option value="free">Free/local credits</option>
            <option value="paid">Paid credits</option>
          </select>
        </label>

        <label>
          Reason
          <input id="cleanAdminGrantReason" type="text" value="admin_manual_grant" />
        </label>

        <button id="cleanAdminGrantCreditsBtn" class="primary-btn" type="button">
          Grant credits
        </button>
      </div>
    </section>
  `;
}

async function cleanAdminGrantCredits() {
  if (!cleanIsAdmin()) {
    alert("Admin access required.");
    return;
  }

  const email = document.getElementById("cleanAdminGrantEmail")?.value?.trim() || "";
  const amount = Number(document.getElementById("cleanAdminGrantAmount")?.value || 0);
  const type = document.getElementById("cleanAdminGrantType")?.value || "free";
  const reason = document.getElementById("cleanAdminGrantReason")?.value?.trim() || "admin_manual_grant";

  if (!email) {
    alert("Enter an email.");
    return;
  }

  if (!Number.isFinite(amount) || amount < 1) {
    alert("Amount must be at least 1.");
    return;
  }

  const ok = confirm(`Grant ${cleanNum(amount)} ${type} credits to ${email}?`);
  if (!ok) return;

  const endpoint = type === "paid" ? "/credits/grant-paid" : "/credits/grant-free";

  try {
    await api(endpoint, {
      method: "POST",
      body: JSON.stringify({
        email,
        amount,
        reason,
        metadata: { source: "admin_panel" },
      }),
    });

    await loadAccountCredits?.();
    await cleanLoadAdminData();

    alert("Credits granted.");
    forceRefreshAfterOperation("credits-granted");
    cleanRenderNow();
  } catch (err) {
    alert(err.message);
  }
}

function cleanRenderUsers() {
  const users = cleanAdminUsers?.users || [];

  if (!users.length) {
    return `<div class="empty-list">No users loaded yet.</div>`;
  }

  return `
    <div class="admin-table-wrap">
      <table class="admin-table">
        <thead>
          <tr>
            <th>User</th>
            <th>Online</th>
            <th>Role</th>
            <th>Plan</th>
            <th>Free</th>
            <th>Paid</th>
            <th>Last seen</th>
          </tr>
        </thead>
        <tbody>
          ${users.map((u) => `
            <tr>
              <td>${cleanEsc(u.email)}</td>
              <td><span class="badge ${u.online ? "online" : "offline"}">${u.online ? "online" : "offline"}</span></td>
              <td>${cleanEsc(u.role)}</td>
              <td>${cleanEsc(u.plan)}</td>
              <td>${cleanNum(u.free_credit_balance)}</td>
              <td>${cleanNum(u.paid_credit_balance)}</td>
              <td>${cleanEsc(u.last_seen_at || "")}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    </div>
  `;
}

function cleanRenderAdminSupportInbox() {
  const tickets = cleanAdminTickets?.tickets || [];

  const waitingAdmin = tickets.filter((t) =>
    ["waiting_admin", "open"].includes(t.status)
  );

  const waitingUser = tickets.filter((t) =>
    t.status === "waiting_user"
  );

  const solved = tickets.filter((t) =>
    ["solved", "closed"].includes(t.status)
  );

  return `
    <section class="system-section">
      <h2>Support Inbox</h2>
      <p class="section-copy">
        Unsolved tickets are split by who needs to respond next.
      </p>

      <h3>Waiting on Admin</h3>
      ${cleanTicketRows(waitingAdmin, true)}

      <h3>Waiting on User</h3>
      ${cleanTicketRows(waitingUser, true)}
    </section>

    <section class="system-section">
      <h2>Solved Tickets</h2>
      <p class="section-copy">
        Resolved support conversations are kept here for history.
      </p>
      ${cleanTicketRows(solved, true)}
    </section>
  `;
}

function cleanRenderPowerPolicy() {
  const policy = cleanPowerPolicy;

  if (!policy) {
    return `
      <section class="system-section">
        <h2>Web Presence Power Policy</h2>
        <div class="notice">Power policy has not loaded yet.</div>
      </section>
    `;
  }

  if (!policy.ok) {
    return `
      <section class="system-section">
        <h2>Web Presence Power Policy</h2>
        <div class="notice error">Could not load power policy: ${cleanEsc(policy.error || "Unknown error")}</div>
      </section>
    `;
  }

  const presence = policy.presence || {};
  const actions = policy.actions || [];
  const reasons = policy.reasons || [];

  return `
    <section class="system-section">
      <h2>Web Presence Power Policy</h2>
      <p class="section-copy">
        Dry-run decision engine for waking the host, starting containers, stopping containers, and future host shutdown.
      </p>

      <div class="summary-grid">
        <div class="summary-box">
          <span>Dry run</span>
          <strong>${policy.dry_run ? "Yes" : "No"}</strong>
          <p>Execution is currently ${policy.execute ? "enabled" : "disabled"}.</p>
        </div>

        <div class="summary-box">
          <span>Active visitors</span>
          <strong>${cleanNum(presence.active_visible || 0)}</strong>
          <p>Total visible active browser sessions.</p>
        </div>

        <div class="summary-box">
          <span>Logged-in users</span>
          <strong>${cleanNum(presence.active_authenticated || 0)}</strong>
          <p>Users currently signed in and active.</p>
        </div>

        <div class="summary-box">
          <span>Wake intent</span>
          <strong>${cleanNum(presence.anonymous_wake_intent || 0)}</strong>
          <p>Anonymous visitors active long enough to wake the host.</p>
        </div>

        <div class="summary-box">
          <span>Host required</span>
          <strong>${desired.host_required ? "Yes" : "No"}</strong>
          <p>${cleanEsc(desired.desired_host_state || "not_required")}</p>
        </div>

        <div class="summary-box">
          <span>Containers required</span>
          <strong>${desired.container_required ? "Yes" : "No"}</strong>
          <p>${cleanEsc(desired.desired_container_state || "not_required")}</p>
        </div>

        <div class="summary-box">
          <span>Shutdown blocked</span>
          <strong>${desired.shutdown_blocked ? "Yes" : "No"}</strong>
          <p>${cleanEsc(desired.shutdown_block_reason || "none")}</p>
        </div>
      </div>

      <div class="summary-box system-section">
        <span>Recommended actions</span>
        <strong>${actions.map(cleanEsc).join(", ") || "none"}</strong>
        <p>${reasons.map(cleanEsc).join(" ") || "No reason provided."}</p>
      </div>

      <div class="summary-box">
        <span>Policy</span>
        <p>
          Anonymous wake after ${cleanNum(policy.policy?.anonymous_wake_after_seconds || 15)}s.
          Container idle ${cleanNum(policy.policy?.container_idle_seconds || 600)}s.
          Host idle ${cleanNum(policy.policy?.host_idle_seconds || 1500)}s.
          Minimum host-on ${cleanNum(policy.policy?.min_host_on_seconds || 1200)}s.
        </p>
      </div>
    </section>
  `;
}

function cleanRenderAdminPage() {
  if (!cleanIsLoggedIn()) {
    return `
      <section class="hero">
        <p class="eyebrow">Admin</p>
        <h1>Admin Panel</h1>
        <p>Log in with an admin account to view this page.</p>
        <button class="primary-btn" type="button" data-clean-login>Log in</button>
      </section>
    `;
  }

  if (!cleanIsAdmin()) {
    return `
      <section class="hero">
        <p class="eyebrow">Admin</p>
        <h1>Admin access required</h1>
        <p>This page is only available to admin users.</p>
      </section>
    `;
  }

  return `
    <section class="hero">
      <p class="eyebrow">Admin</p>
      <h1>Admin Panel</h1>
      <p>Manage users, credits, support tickets, and infrastructure status.</p>
    </section>

    ${cleanAdminCreditToolHtml()}

    <section class="system-section">
      <h2>Online Users</h2>
      <div class="summary-grid">
        <div class="summary-box">
          <span>Online users</span>
          <strong>${cleanNum(cleanAdminUsers?.online_count || 0)}</strong>
          <p>Users active within the online window.</p>
        </div>

        <div class="summary-box">
          <span>Users returned</span>
          <strong>${cleanNum(cleanAdminUsers?.user_count_returned || 0)}</strong>
          <p>Latest users by activity.</p>
        </div>
      </div>

      ${cleanAdminUsers ? cleanRenderUsers() : `<div class="empty-list">Loading users...</div>`}
    </section>

    ${cleanAdminTickets ? cleanRenderAdminSupportInbox() : `
      <section class="system-section">
        <h2>Support Inbox</h2>
        <div class="empty-list">Loading support tickets...</div>
      </section>
    `}

    ${cleanRenderThread()}

    ${cleanRenderInfrastructure()}
  `;
}

function cleanRemoveAdminInfrastructureFromSystemPage() {
  if (location.pathname !== "/system") return;

  const headings = [...document.querySelectorAll("h2, h3")];

  for (const heading of headings) {
    const text = heading.textContent.trim().toLowerCase();

    if (text === "infrastructure" || text.includes("admin system")) {
      const section = heading.closest("section") || heading.closest(".system-section");
      if (section) section.remove();
    }
  }

  [...document.querySelectorAll("button, a")].forEach((el) => {
    const text = el.textContent.trim().toLowerCase();

    if (text.includes("wake service soon")) {
      el.remove();
    }

    if (text.includes("open admin system panel")) {
      el.remove();
    }
  });
}

function cleanAttachHandlers() {
  document.getElementById("cleanCreateSupportTicketBtn")?.addEventListener("click", cleanCreateSupportTicket);
  document.getElementById("cleanAdminGrantCreditsBtn")?.addEventListener("click", cleanAdminGrantCredits);

  document.querySelectorAll("[data-clean-open-ticket]").forEach((btn) => {
    if (btn.dataset.bound === "1") return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", () => cleanOpenTicket(btn.dataset.cleanOpenTicket));
  });

  document.querySelectorAll("[data-clean-reply-ticket]").forEach((btn) => {
    if (btn.dataset.bound === "1") return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", () => cleanSendReply(btn.dataset.cleanReplyTicket));
  });

  document.querySelectorAll("[data-clean-solve-ticket]").forEach((btn) => {
    if (btn.dataset.bound === "1") return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", () => cleanSetTicketStatus(btn.dataset.cleanSolveTicket, "solved"));
  });

  document.querySelectorAll("[data-clean-reopen-ticket]").forEach((btn) => {
    if (btn.dataset.bound === "1") return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", () => cleanSetTicketStatus(btn.dataset.cleanReopenTicket, "waiting_admin"));
  });

  document.querySelectorAll("[data-clean-login]").forEach((btn) => {
    if (btn.dataset.bound === "1") return;
    btn.dataset.bound = "1";
    btn.addEventListener("click", () => openAuthModal("login"));
  });

  document.getElementById("cleanToggleAdminSystemDetailsBtn")?.addEventListener("click", () => {
    const panel = document.getElementById("cleanAdminSystemDetails");
    if (panel) panel.classList.toggle("hidden");
  });
}

let cleanOriginalRenderPage = null;

try {
  cleanOriginalRenderPage = renderPage;

  renderPage = function(...args) {
    cleanSyncNav();

    const app = document.getElementById("app");

    if (location.pathname === "/support") {
      if (app) app.innerHTML = cleanRenderSupportPage();
      cleanAttachHandlers();
      return;
    }

    if (location.pathname === "/admin") {
      if (app) app.innerHTML = cleanRenderAdminPage();
      cleanAttachHandlers();
      return;
    }

    const result = cleanOriginalRenderPage.apply(this, args);
    cleanSyncNav();
    cleanRemoveAdminInfrastructureFromSystemPage();
    cleanAttachHandlers();
    return result;
  };
} catch (err) {
  console.warn("Clean admin/support render wrapper failed:", err);
}

async function cleanRenderNow() {
  await cleanLoadRouteData();
  renderPage();
}

document.addEventListener("click", async (event) => {
  const link = event.target.closest?.("[data-route]");

  if (!link) return;

  const route = link.dataset.route;
  if (!route) return;

  event.preventDefault();
  history.pushState({}, "", route);

  await cleanLoadRouteData();
  renderPage();
}, true);

window.addEventListener("popstate", cleanRenderNow);

setInterval(cleanHeartbeat, 60000);

setTimeout(async () => {
  cleanSyncNav();
  await cleanHeartbeat();
  await cleanLoadRouteData();
  renderPage();
}, 300);



function forceRefreshAfterOperation(reason = "") {
  ahInvalidateCache([]);

  console.log("[cache] force refresh after operation", reason);

  return Promise.resolve()
    .then(async () => {
      const path = location.pathname;

      if (typeof loadSystemStatus === "function") {
        await loadSystemStatus();
      }

      if (typeof refreshHeaderCredits === "function") {
        await refreshHeaderCredits("force-operation");
      } else if (typeof loadAccountCredits === "function") {
        await loadAccountCredits({
          deep: path === "/credits",
        });
      }

      if (path === "/support" && typeof cleanLoadSupportTickets === "function") {
        await cleanLoadSupportTickets();
      }

      if (path === "/admin" && typeof cleanLoadAdminData === "function") {
        await cleanLoadAdminData();
      }

      renderPage();
    })
    .catch((err) => {
      console.warn("[cache] force refresh failed", err);
    });
}



// ============================================================
// HEADER_CREDIT_REFRESH_V1
// Keeps header credits fresh without tying credits to system polling.
// ============================================================

let headerCreditRefreshInFlight = null;

async function refreshHeaderCredits(reason = "") {
  if (!authState?.token) return;

  if (headerCreditRefreshInFlight) {
    return headerCreditRefreshInFlight;
  }

  headerCreditRefreshInFlight = Promise.resolve()
    .then(async () => {
      if (typeof loadAccountCredits === "function") {
        await loadAccountCredits({
          deep: location.pathname === "/credits",
        });
      }
    })
    .catch((err) => {
      console.warn("[credits] header refresh failed", reason, err);
    })
    .finally(() => {
      headerCreditRefreshInFlight = null;
    });

  return headerCreditRefreshInFlight;
}

setTimeout(() => {
  refreshHeaderCredits("startup");
}, 800);


// ============================================================

// ============================================================
// FAST_AUTH_AND_SESSION_UI
// Current login/logout UI path.
// Login renders immediately after auth + /me.
// Logout clears local state immediately and revokes server session
// in the background via /auth/logout -> /system/session/logout-safe.
// ============================================================

// FAST_AUTH_PATCH_V1
// Makes login/logout feel instant.
// Login: auth -> /me -> render now -> refresh page data in background.
// Logout: clear local state now -> revoke backend session in background.
// ============================================================

let fastAuthBusy = false;

function fastSetAuthMessage(message, isError = false) {
  const box = document.getElementById("authMessage");
  if (!box) {
    if (message && isError) alert(message);
    return;
  }

  box.textContent = message || "";
  box.classList.toggle("hidden", !message);
  box.classList.toggle("error", Boolean(isError));
}

async function fastRefreshAfterAuth(reason = "") {
  const path = location.pathname;

  const jobs = [];

  if (typeof cleanHeartbeat === "function" && authState?.token) {
    jobs.push(cleanHeartbeat());
  }

  if (typeof refreshHeaderCredits === "function" && authState?.token) {
    jobs.push(refreshHeaderCredits(reason));
  }

  if (typeof sendWebPresence === "function" && authState?.token) {
    jobs.push(sendWebPresence("force"));
  }

  if (typeof loadSystemStatus === "function") {
    jobs.push(loadSystemStatus());
  }

  if (path === "/support" && typeof cleanLoadSupportTickets === "function") {
    jobs.push(cleanLoadSupportTickets());
  }

  if (path === "/admin" && typeof cleanLoadAdminData === "function" && authState?.user?.is_admin) {
    jobs.push(cleanLoadAdminData());
  }

  if (path === "/credits" && typeof loadAccountCredits === "function") {
    jobs.push(loadAccountCredits({ deep: true }));
  }

  await Promise.allSettled(jobs);

  try {
    renderPage();
  } catch {
    // ignore render errors
  }
}

async function fastHandleAuthSubmit(event) {
  const form = event.target;

  if (!form || form.id !== "authForm") {
    return;
  }

  event.preventDefault();
  event.stopPropagation();
  event.stopImmediatePropagation();

  if (fastAuthBusy) return;
  fastAuthBusy = true;

  const submitBtn = document.getElementById("authSubmitBtn");
  const email = document.getElementById("authEmail")?.value?.trim() || "";
  const password = document.getElementById("authPassword")?.value || "";
  const mode = typeof authMode !== "undefined" && authMode === "register" ? "register" : "login";

  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = mode === "register" ? "Sending..." : "Logging in...";
  }

  fastSetAuthMessage("");

  try {
    const result = await api(`/auth/${mode}`, {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });

    const token = result?.session?.access_token;

    if (!token) {
      throw new Error("Login response did not include a token.");
    }

    authState.token = token;
    localStorage.setItem("edgeStudyToken", token);
    syncAuthRouteCookie();

    // Fetch enriched user once so admin/is_admin/credits state is correct.
    try {
      const me = await api("/me", { method: "GET" });
      authState.user = me?.user || result.user || null;
    } catch {
      authState.user = result.user || null;
    }

    if (typeof ahInvalidateCache === "function") {
      ahInvalidateCache([]);
    }

    if (typeof closeAuthModal === "function") {
      closeAuthModal();
    }

    // Render immediately so login feels fast.
    renderPage();

    // Then refresh related data in the background.
    fastRefreshAfterAuth("login");
  } catch (err) {
    fastSetAuthMessage(err.message || "Login failed.", true);
  } finally {
    fastAuthBusy = false;

    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.textContent = mode === "register" ? "Send verification email" : "Login";
    }
  }
}

function fastHandleLogoutClick(event) {
  const button = event.target?.closest?.("#logoutBtn, [data-logout], [data-auth-logout]");

  if (!button) {
    return;
  }

  event.preventDefault();
  event.stopPropagation();
  event.stopImmediatePropagation();

  const oldToken = authState?.token || localStorage.getItem("edgeStudyToken") || "";

  // UI changes immediately.
  authState.token = "";
  authState.user = null;
  localStorage.removeItem("edgeStudyToken");
  syncAuthRouteCookie();

  if (typeof ahInvalidateCache === "function") {
    ahInvalidateCache([]);
  }

  try {
    renderPage();
  } catch {
    // ignore render errors
  }

  // Revoke backend session in background without making the user wait.
  if (oldToken && typeof API_BASE !== "undefined") {
    fetch(`${API_BASE}/auth/logout`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${oldToken}`,
      },
      keepalive: true,
    }).catch((err) => {
      console.warn("[auth] background logout revoke failed", err);
    });
  }
}

document.addEventListener("submit", fastHandleAuthSubmit, true);
document.addEventListener("click", fastHandleLogoutClick, true);


// ============================================================
// WEB_PRESENCE_CLIENT_V1
// Sends anonymous/logged-in web presence for power policy.
// Anonymous visitors can request host wake after 15s active.
// Logged-in users indicate core containers should be online.
// ============================================================

const WEB_PRESENCE_VISITOR_KEY = "ahVisitorId";
const WEB_PRESENCE_STARTED_AT = Date.now();
let webPresenceLastSentAt = 0;
let webPresenceInFlight = null;

function getWebPresenceVisitorId() {
  let id = localStorage.getItem(WEB_PRESENCE_VISITOR_KEY);

  if (!id) {
    const randomPart =
      crypto?.randomUUID?.() ||
      `${Date.now()}-${Math.random().toString(36).slice(2)}`;

    id = "v-" + randomPart;
    localStorage.setItem(WEB_PRESENCE_VISITOR_KEY, id);
  }

  return id;
}

function getWebPresenceActiveSeconds() {
  return Math.max(0, Math.floor((Date.now() - WEB_PRESENCE_STARTED_AT) / 1000));
}

async function sendWebPresence(reason = "") {
  if (!pageIsActive()) return;

  const activeSeconds = getWebPresenceActiveSeconds();

  // Anonymous visitors only signal wake intent after 15 seconds.
  // Logged-in users can signal immediately.
  if (!authState?.token && activeSeconds < 15) {
    return;
  }

  if (webPresenceInFlight) {
    return webPresenceInFlight;
  }

  const now = Date.now();

  // Debounce normal presence sends.
  if (reason !== "force" && now - webPresenceLastSentAt < 55_000) {
    return;
  }

  webPresenceLastSentAt = now;

  webPresenceInFlight = api("/presence/web", {
    method: "POST",
    body: JSON.stringify({
      visitor_id: getWebPresenceVisitorId(),
      route: location.pathname,
      active_seconds: activeSeconds,
      visibility: document.visibilityState,
      metadata: {
        reason,
        logged_in: Boolean(authState?.token),
      },
    }),
  })
    .catch((err) => {
      console.warn("[presence] web presence failed", err);
    })
    .finally(() => {
      webPresenceInFlight = null;
    });

  return webPresenceInFlight;
}

// Logged-in users signal immediately; anonymous visitors signal wake intent after 15s.
setTimeout(() => {
  sendWebPresence(authState?.token ? "startup-logged-in" : "startup-anonymous-check");
}, 1_500);

setTimeout(() => {
  sendWebPresence("15-second-intent");
}, 15_000);

setInterval(() => {
  sendWebPresence("interval");
}, 60_000);

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState !== "hidden") {
    sendWebPresence("force");
  }
});

// Strong signal when user opens auth modal or clicks login/register.
document.addEventListener("click", (event) => {
  const target = event.target?.closest?.("button, a");
  const text = target?.textContent?.toLowerCase?.() || "";

  if (text.includes("login") || text.includes("log in") || text.includes("register")) {
    sendWebPresence("force");
  }
}, true);





// ============================================================



// ============================================================
// WEB_PRESENCE_APPLY_POLICY_V1
// After web presence is sent, ask backend to apply policy.
// Backend currently executes only wake_host_if_needed when enabled.
// ============================================================

let webPresencePolicyApplyInFlight = null;
let webPresencePolicyLastApplyAt = 0;

async function applyWebPresencePowerPolicy(reason = "") {
  if (!pageIsActive()) return;

  const now = Date.now();

  // Prevent rapid duplicate applies from login/startup/visibility events.
  if (now - webPresencePolicyLastApplyAt < 55_000) {
    return;
  }

  if (webPresencePolicyApplyInFlight) {
    return webPresencePolicyApplyInFlight;
  }

  webPresencePolicyLastApplyAt = now;

  webPresencePolicyApplyInFlight = api("/presence/apply-power-policy", {
    method: "POST",
    body: JSON.stringify({
      reason,
      route: location.pathname,
    }),
  })
    .then((result) => {
      console.log("[presence] apply power policy", result);
      return result;
    })
    .catch((err) => {
      console.warn("[presence] apply power policy failed", err);
    })
    .finally(() => {
      webPresencePolicyApplyInFlight = null;
    });

  return webPresencePolicyApplyInFlight;
}

try {
  if (typeof sendWebPresence === "function" && !window.__ahWebPresenceApplyWrapped) {
    window.__ahWebPresenceApplyWrapped = true;
    window.__ahOriginalSendWebPresence = sendWebPresence;

    sendWebPresence = async function(reason = "") {
      const result = await window.__ahOriginalSendWebPresence(reason);

      if (result !== undefined) {
        await applyWebPresencePowerPolicy(reason);
      }

      return result;
    };
  }
} catch (err) {
  console.warn("[presence] apply policy wrapper failed", err);
}



// WRAPPER_STARTUP_AUTH_REFRESH_V1
async function wrapperStartupAuthRefresh() {
  if (!authState.token) {
    renderCreditsPill();
    cleanSyncNav?.();
    forceSyncAccountUi();
    return;
  }

  try {
    const me = await api("/me", { method: "GET" });
    authState.user = me.user || me;

    try {
      accountCredits = await api("/account/credits", { method: "GET" });
      if (accountCredits?.user) {
        authState.user = accountCredits.user;
      }
    } catch (creditErr) {
      console.warn("Startup credits refresh failed:", creditErr);
    }

    renderCreditsPill();
    cleanSyncNav?.();
    forceSyncAccountUi();
    renderPage();
    sendWebPresence?.("force");
  } catch (err) {
    console.warn("Startup auth refresh failed:", err);
    authState.token = "";
    authState.user = null;
    localStorage.removeItem("edgeStudyToken");
  syncAuthRouteCookie();
    renderCreditsPill();
    cleanSyncNav?.();
    forceSyncAccountUi();
    renderPage();
  }
}

function runWrapperStartupAuthRefreshNow() {
  setTimeout(() => {
    wrapperStartupAuthRefresh();
  }, 0);
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", runWrapperStartupAuthRefreshNow, { once: true });
} else {
  runWrapperStartupAuthRefreshNow();
}


// PROTECTED_NAV_PRIVATE_RELOAD_V1
document.addEventListener("click", (event) => {
  const link = event.target?.closest?.("a[href]");
  if (!link) return;

  const href = link.getAttribute("href");
  if (!href) return;

  let target;
  try {
    target = new URL(href, location.origin);
  } catch {
    return;
  }

  if (target.origin !== location.origin) return;
  if (!PRIVATE_APP_ROUTE_SET.has(target.pathname)) return;

  const token = localStorage.getItem("edgeStudyToken") || authState?.token || "";
  if (!token) return;

  document.cookie =
    `edgeStudyToken=${encodeURIComponent(token)}; Path=/; Max-Age=2592000; SameSite=Lax${location.protocol === "https:" ? "; Secure" : ""}`;

  target.searchParams.set("fresh", String(Date.now()));
  event.preventDefault();
  location.href = target.toString();
}, true);

(async function bootEmailVerificationRoute() {
  try {
    await handleVerifyEmailRoute();
  } catch (err) {
    console.warn("Email verification route handling failed", err);
  }
})();


function ensureForgotPasswordButton() {
  const authForm = $("authForm");
  if (!authForm) return null;

  let btn = $("forgotPasswordBtn");
  if (!btn) {
    btn = document.createElement("button");
    btn.id = "forgotPasswordBtn";
    btn.className = "ghost-btn";
    btn.type = "button";
    btn.textContent = "Forgot password?";
    btn.style.marginTop = "10px";
    btn.addEventListener("click", requestPasswordResetFromLogin);

    const resendBtn = $("resendVerificationBtn");
    const submitBtn = $("authSubmitBtn");

    if (resendBtn && resendBtn.parentNode) {
      resendBtn.parentNode.insertBefore(btn, resendBtn.nextSibling);
    } else if (submitBtn && submitBtn.parentNode) {
      submitBtn.parentNode.insertBefore(btn, submitBtn.nextSibling);
    } else {
      authForm.appendChild(btn);
    }
  }

  btn.hidden = authMode !== "login";
  return btn;
}

function updateForgotPasswordVisibility() {
  const btn = $("forgotPasswordBtn");
  if (btn) {
    btn.hidden = authMode !== "login";
  }
}

async function requestPasswordResetFromLogin() {
  const email = ($("authEmail")?.value || "").trim().toLowerCase();

  if (!email || !email.includes("@")) {
    setEmailVerificationMessage("Enter your email address first, then click Forgot password.", true);
    return;
  }

  const btn = $("forgotPasswordBtn");
  if (btn) {
    btn.disabled = true;
    btn.textContent = "Sending reset email...";
  }

  try {
    const data = await api("/auth/forgot-password", {
      method: "POST",
      body: JSON.stringify({ email }),
    });

    setEmailVerificationMessage(
      data?.message || "If that email exists, a password reset link has been sent."
    );
  } catch (err) {
    setEmailVerificationMessage(err.message || "Could not request password reset.", true);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.textContent = "Forgot password?";
    }
  }
}

async function handleResetPasswordRoute() {
  const url = new URL(window.location.href);

  if (url.pathname !== "/reset-password") {
    return false;
  }

  const token = url.searchParams.get("token") || "";

  if (!token) {
    showPageNotice("Reset link is missing a token.", true);
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");
    return true;
  }

  showPageNotice("Password reset link ready.");

  const newPassword = window.prompt("Enter your new password. It must be at least 8 characters.");

  if (!newPassword) {
    showPageNotice("Password reset cancelled.", true);
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");
    return true;
  }

  const confirmPassword = window.prompt("Confirm your new password.");

  if (newPassword !== confirmPassword) {
    showPageNotice("Passwords did not match.", true);
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");
    return true;
  }

  try {
    const data = await api("/auth/reset-password", {
      method: "POST",
      body: JSON.stringify({
        token,
        new_password: newPassword,
      }),
    });

    showPageNotice(data?.message || "Password reset. You can now log in.");
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");
    setEmailVerificationMessage("Password reset. Log in with your new password.");

    setTimeout(() => {
      window.location.href = "/login";
    }, 900);
  } catch (err) {
    const message = err.message || "Password reset failed.";
    showPageNotice(message, true);
    window.history.replaceState({}, "", "/login");
    openAuthModal("login");
    setEmailVerificationMessage(message, true);
  }

  return true;
}

(function installPasswordRecoveryUiHooks() {
  const originalSetAuthMode = setAuthMode;

  setAuthMode = function patchedSetAuthMode(mode) {
    const result = originalSetAuthMode(mode);
    ensureForgotPasswordButton();
    updateForgotPasswordVisibility();
    return result;
  };

  document.addEventListener("DOMContentLoaded", () => {
    ensureForgotPasswordButton();
    updateForgotPasswordVisibility();
  });
})();

(async function bootPasswordResetRoute() {
  try {
    await handleResetPasswordRoute();
  } catch (err) {
    console.warn("Password reset route handling failed", err);
  }
})();

/*
 * Stage 5F-31: queued-chat frontend flag detection.
 *
 * This block intentionally does not wire queued chat send behavior.
 * It only records whether the disabled-by-default queued-chat frontend flag is enabled.
 *
 * Safety:
 * - queued chat remains disabled by default
 * - legacy/current chat path remains active while flag is false
 * - does not call the queued chat API route
 * - does not use the queued chat status helper yet
 * - does not send client-provided user identity fields
 * - does not send synthetic-user headers
 */
(function stage5f31QueuedChatFlagDetection(root) {
  "use strict";

  const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;

  root.AI_PLATFORM_QUEUED_CHAT_UI_STATE = Object.freeze({
    stage: "5f31",
    source: "app_js_queued_chat_flag_detection",
    enabled,
    legacyChatPathActive: enabled !== true,
    queuedSendWired: false,
  });
})(typeof window !== "undefined" ? window : globalThis);

/*
 * Stage 5F-32: disabled queued-chat send branch.
 *
 * This block defines a future queued-chat send helper, but intentionally does not
 * wire it into the current chat submit flow.
 *
 * Safety:
 * - branch is gated by the disabled-by-default queued-chat frontend flag
 * - branch is not wired to submit
 * - legacy/current chat path remains active while flag is false
 * - does not send client-provided user identity fields
 * - does not send synthetic-user headers
 */
(function stage5f32QueuedChatSendBranch(root) {
  "use strict";

  async function stage5f32SendQueuedChat(payload) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;

    if (!enabled) {
      return {
        ok: false,
        skipped: true,
        reason: "queued_chat_disabled_stage_5f32",
        legacyChatPathActive: true,
      };
    }

    const cleanPayload = {
      message: String((payload && payload.message) || ""),
    };

    if (payload && payload.chat_id) {
      cleanPayload.chat_id = String(payload.chat_id);
    }

    if (payload && payload.requested_model) {
      cleanPayload.requested_model = String(payload.requested_model);
    }

    const response = await fetch("/api/chat/queued", {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(cleanPayload),
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      return {
        ok: false,
        status: response.status,
        error: data,
      };
    }

    return data;
  }

  root.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH = Object.freeze({
    stage: "5f32",
    source: "app_js_disabled_queued_send_branch",
    wiredToSubmit: false,
    sendQueuedChat: stage5f32SendQueuedChat,
  });
})(typeof window !== "undefined" ? window : globalThis);

/*
 * Stage 5F-35: disabled queued-chat status polling branch.
 *
 * This block defines a future queued-chat status polling helper, but intentionally
 * does not wire it into the current chat submit flow or any runtime polling loop.
 *
 * Safety:
 * - branch is gated by the disabled-by-default queued-chat frontend flag
 * - branch is not wired to submit
 * - branch is not wired to automatic polling
 * - legacy/current chat path remains active while flag is false
 * - does not send client-provided identity fields
 * - does not send synthetic-user headers
 */
(function stage5f35QueuedChatStatusPollBranch(root) {
  "use strict";

  async function stage5f35PollQueuedChatStatus(jobId, options) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;

    if (!enabled) {
      return {
        ok: false,
        skipped: true,
        reason: "queued_status_poll_disabled_stage_5f35",
        legacyChatPathActive: true,
      };
    }

    const helper = root.QueuedChatStatusHelper;

    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
      return {
        ok: false,
        error: "queued_status_helper_missing_stage_5f35",
      };
    }

    const cleanJobId = String(jobId || "").trim();

    if (!cleanJobId) {
      return {
        ok: false,
        error: "missing_job_id_stage_5f35",
      };
    }

    const response = await fetch(`/api/chat/queued/${encodeURIComponent(cleanJobId)}`, {
      method: "GET",
      credentials: "include",
      headers: {
        "Accept": "application/json",
      },
    });

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      return {
        ok: false,
        status: response.status,
        error: data,
      };
    }

    const job = data.job || data;
    const elapsedMs = Number((options && options.elapsedMs) || 0);
    const view = helper.queuedChatBuildStatusView(job, elapsedMs);

    return {
      ok: true,
      stage: "5f35",
      job,
      view,
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH = Object.freeze({
    stage: "5f35",
    source: "app_js_disabled_queued_status_poll_branch",
    pollerWired: false,
    pollQueuedChatStatus: stage5f35PollQueuedChatStatus,
  });
})(typeof window !== "undefined" ? window : globalThis);

/*
 * Stage 5F-37: disabled queued-chat assistant placeholder branch.
 *
 * This block defines a future queued-chat assistant placeholder helper, but
 * intentionally does not wire it into the current chat rendering flow.
 *
 * Safety:
 * - branch is gated by the disabled-by-default queued-chat frontend flag
 * - branch is not wired to submit
 * - branch is not wired to message rendering
 * - legacy/current chat path remains active while flag is false
 * - does not send client-provided identity fields
 * - does not send synthetic-user headers
 */
(function stage5f37QueuedChatAssistantPlaceholderBranch(root) {
  "use strict";

  function stage5f37BuildQueuedAssistantPlaceholder(job, options) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;

    if (!enabled) {
      return {
        ok: false,
        skipped: true,
        reason: "queued_placeholder_disabled_stage_5f37",
        legacyChatPathActive: true,
      };
    }

    const helper = root.QueuedChatStatusHelper;

    if (!helper || typeof helper.queuedChatBuildStatusView !== "function") {
      return {
        ok: false,
        error: "queued_placeholder_helper_missing_stage_5f37",
      };
    }

    const elapsedMs = Number((options && options.elapsedMs) || 0);
    const view = helper.queuedChatBuildStatusView(job || {}, elapsedMs);

    return {
      ok: true,
      stage: "5f37",
      view,
      placeholderText: view.placeholder || "Waiting for queued response status.",
      canRenderAssistant: view.canRenderAssistant === true,
      assistantReply: view.assistantReply || "",
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH = Object.freeze({
    stage: "5f37",
    source: "app_js_disabled_queued_assistant_placeholder_branch",
    placeholderWired: false,
    buildQueuedAssistantPlaceholder: stage5f37BuildQueuedAssistantPlaceholder,
  });
})(typeof window !== "undefined" ? window : globalThis);

/*
 * Stage 5F-40: disabled queued-chat submit decision branch.
 *
 * This block defines a future decision helper for selecting the queued-chat
 * submit path, but intentionally does not wire it into the current submit flow.
 *
 * Safety:
 * - decision is gated by the disabled-by-default queued-chat frontend flag
 * - decision remains false while this branch is not wired
 * - legacy/current chat path remains active
 * - does not submit jobs
 * - does not start polling
 * - does not send client-provided identity fields
 * - does not send synthetic-user headers
 */
(function stage5f40QueuedChatSubmitDecisionBranch(root) {
  "use strict";

  function stage5f40ShouldUseQueuedChatForSubmit(context) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;
    const sendBranch = root.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH;
    const decisionWired = false;

    if (!enabled) {
      return {
        ok: true,
        stage: "5f40",
        shouldUseQueuedChat: false,
        reason: "queued_chat_flag_disabled_stage_5f40",
        legacyChatPathActive: true,
        decisionWired,
      };
    }

    /*
     * Stage 5F-41: decisionWired remains the authoritative guard.
     * Even if a mocked send branch reports wiredToSubmit=true, queued submit
     * must not be selected until a later stage explicitly wires this decision.
     */
    if (!decisionWired) {
      return {
        ok: true,
        stage: "5f41",
        shouldUseQueuedChat: false,
        reason: "queued_chat_decision_not_wired_stage_5f41",
        legacyChatPathActive: true,
        decisionWired,
      };
    }

    if (!sendBranch || sendBranch.wiredToSubmit !== true) {
      return {
        ok: true,
        stage: "5f40",
        shouldUseQueuedChat: false,
        reason: "queued_chat_submit_not_wired_stage_5f40",
        legacyChatPathActive: true,
        decisionWired,
      };
    }

    return {
      ok: true,
      stage: "5f40",
      shouldUseQueuedChat: true,
      reason: "queued_chat_submit_selected_stage_5f40",
      legacyChatPathActive: false,
      decisionWired,
      context: {
        hasMessage: Boolean(context && String(context.message || "").trim()),
        hasChat: Boolean(context && context.chat_id),
        hasModel: Boolean(context && context.requested_model),
      },
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH = Object.freeze({
    stage: "5f40",
    source: "app_js_disabled_queued_submit_decision_branch",
    decisionWired: false,
    shouldUseQueuedChatForSubmit: stage5f40ShouldUseQueuedChatForSubmit,
  });
})(typeof window !== "undefined" ? window : globalThis);

/*
 * Stage 5F-45: disabled queued-chat submit dry-run branch.
 *
 * This block defines a future dry-run helper for checking whether a submit
 * could use the queued-chat path, but intentionally does not wire it into
 * the current submit flow.
 *
 * Safety:
 * - dry-run is gated by the disabled-by-default queued-chat frontend flag
 * - dry-run remains unwired
 * - legacy/current chat path remains active
 * - does not submit jobs
 * - does not call fetch
 * - does not start polling
 * - does not render placeholders
 * - does not send client-provided identity fields
 * - does not send synthetic-user headers
 */
(function stage5f45QueuedChatSubmitDryRunBranch(root) {
  "use strict";

  function stage5f45BuildQueuedChatSubmitDryRun(context) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;
    const decisionBranch = root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH;
    const sendBranch = root.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH;
    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;
    const placeholderBranch = root.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH;

    const payload = {
      message: String((context && context.message) || ""),
    };

    if (context && context.chat_id) {
      payload.chat_id = String(context.chat_id);
    }

    if (context && context.requested_model) {
      payload.requested_model = String(context.requested_model);
    }

    return {
      ok: true,
      stage: "5f45",
      source: "app_js_disabled_queued_submit_dry_run_branch",
      dryRunWired: false,
      enabled,
      wouldUseQueuedChat: false,
      reason: enabled ? "queued_submit_dry_run_unwired_stage_5f45" : "queued_submit_dry_run_flag_disabled_stage_5f45",
      legacyChatPathActive: true,
      decisionBranchPresent: Boolean(decisionBranch),
      sendBranchPresent: Boolean(sendBranch),
      pollBranchPresent: Boolean(pollBranch),
      placeholderBranchPresent: Boolean(placeholderBranch),
      decisionWired: Boolean(decisionBranch && decisionBranch.decisionWired === true),
      sendWired: Boolean(sendBranch && sendBranch.wiredToSubmit === true),
      pollerWired: Boolean(pollBranch && pollBranch.pollerWired === true),
      placeholderWired: Boolean(placeholderBranch && placeholderBranch.placeholderWired === true),
      payload,
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DRY_RUN_BRANCH = Object.freeze({
    stage: "5f45",
    source: "app_js_disabled_queued_submit_dry_run_branch",
    dryRunWired: false,
    buildQueuedChatSubmitDryRun: stage5f45BuildQueuedChatSubmitDryRun,
  });
})(typeof window !== "undefined" ? window : globalThis);

/*
 * Stage 5F-48: disabled queued-chat submit payload builder branch.
 *
 * This block defines a future queued-chat submit payload builder, but
 * intentionally does not wire it into the current submit flow.
 *
 * Safety:
 * - payload builder remains unwired
 * - legacy/current chat path remains active
 * - builds only message, chat_id, and requested_model
 * - does not submit jobs
 * - does not call fetch
 * - does not start polling
 * - does not render placeholders
 * - does not send client-provided identity fields
 * - does not send synthetic-user headers
 */
(function stage5f48QueuedChatSubmitPayloadBranch(root) {
  "use strict";

  function stage5f48BuildQueuedChatSubmitPayload(context) {
    const message = String((context && context.message) || "").trim();

    if (!message) {
      return {
        ok: false,
        stage: "5f48",
        error: "missing_message_stage_5f48",
        payloadWired: false,
      };
    }

    const payload = {
      message,
    };

    if (context && context.chat_id) {
      payload.chat_id = String(context.chat_id);
    }

    if (context && context.requested_model) {
      payload.requested_model = String(context.requested_model);
    }

    return {
      ok: true,
      stage: "5f48",
      source: "app_js_disabled_queued_submit_payload_builder_branch",
      payloadWired: false,
      payload,
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH = Object.freeze({
    stage: "5f48",
    source: "app_js_disabled_queued_submit_payload_builder_branch",
    payloadWired: false,
    buildQueuedChatSubmitPayload: stage5f48BuildQueuedChatSubmitPayload,
  });
})(typeof window !== "undefined" ? window : globalThis);

/*
 * Stage 5F-51: disabled queued-chat submit orchestration branch.
 *
 * This block defines a future queued-chat submit orchestration helper, but
 * intentionally does not wire it into the current submit flow.
 *
 * Safety:
 * - orchestration remains unwired
 * - legacy/current chat path remains active
 * - only runs when directly called by a future/mock test
 * - does not change live submit behavior
 * - does not send client-provided identity fields
 * - does not send synthetic-user headers
 */
(function stage5f51QueuedChatSubmitOrchestrationBranch(root) {
  "use strict";

  async function stage5f51RunQueuedChatSubmitOrchestration(context, options) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;

    if (!enabled) {
      return {
        ok: false,
        skipped: true,
        stage: "5f51",
        reason: "queued_orchestration_flag_disabled_stage_5f51",
        orchestrationWired: false,
        legacyChatPathActive: true,
      };
    }

    const payloadBranch = root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH;
    const decisionBranch = root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH;
    const sendBranch = root.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH;
    const placeholderBranch = root.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH;
    const pollBranch = root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH;

    const calls = [];

    if (!payloadBranch || typeof payloadBranch.buildQueuedChatSubmitPayload !== "function") {
      return {
        ok: false,
        stage: "5f51",
        error: "queued_orchestration_payload_helper_missing_stage_5f51",
        orchestrationWired: false,
        calls,
      };
    }

    calls.push("payload");
    const payloadResult = payloadBranch.buildQueuedChatSubmitPayload(context || {});

    if (!payloadResult || payloadResult.ok !== true || !payloadResult.payload) {
      return {
        ok: false,
        stage: "5f51",
        error: "queued_orchestration_payload_failed_stage_5f51",
        orchestrationWired: false,
        calls,
        payloadResult,
      };
    }

    if (!decisionBranch || typeof decisionBranch.shouldUseQueuedChatForSubmit !== "function") {
      return {
        ok: false,
        stage: "5f51",
        error: "queued_orchestration_decision_helper_missing_stage_5f51",
        orchestrationWired: false,
        calls,
      };
    }

    calls.push("decision");
    const decisionResult = decisionBranch.shouldUseQueuedChatForSubmit(payloadResult.payload);

    if (!decisionResult || decisionResult.shouldUseQueuedChat !== true) {
      return {
        ok: false,
        stage: "5f51",
        error: "queued_orchestration_decision_refused_stage_5f51",
        orchestrationWired: false,
        calls,
        payload: payloadResult.payload,
        decisionResult,
        legacyChatPathActive: true,
      };
    }

    if (!sendBranch || typeof sendBranch.sendQueuedChat !== "function") {
      return {
        ok: false,
        stage: "5f51",
        error: "queued_orchestration_send_helper_missing_stage_5f51",
        orchestrationWired: false,
        calls,
      };
    }

    calls.push("send");
    const sendResult = await sendBranch.sendQueuedChat(payloadResult.payload);

    if (!sendResult || sendResult.ok !== true || !sendResult.job_id) {
      return {
        ok: false,
        stage: "5f51",
        error: "queued_orchestration_send_failed_stage_5f51",
        orchestrationWired: false,
        calls,
        sendResult,
      };
    }

    let placeholderResult = null;

    if (placeholderBranch && typeof placeholderBranch.buildQueuedAssistantPlaceholder === "function") {
      calls.push("placeholder");
      placeholderResult = placeholderBranch.buildQueuedAssistantPlaceholder(
        {
          id: sendResult.job_id,
          job_id: sendResult.job_id,
          status: "queued",
        },
        options || {}
      );
    }

    let statusResult = null;

    if (pollBranch && typeof pollBranch.pollQueuedChatStatus === "function") {
      calls.push("poll");
      statusResult = await pollBranch.pollQueuedChatStatus(sendResult.job_id, options || {});
    }

    return {
      ok: true,
      stage: "5f51",
      source: "app_js_disabled_queued_submit_orchestration_branch",
      orchestrationWired: false,
      calls,
      payload: payloadResult.payload,
      decisionResult,
      sendResult,
      placeholderResult,
      statusResult,
      job_id: sendResult.job_id,
      chat_id: sendResult.chat_id || payloadResult.payload.chat_id || "",
      user_message_id: sendResult.user_message_id || "",
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH = Object.freeze({
    stage: "5f51",
    source: "app_js_disabled_queued_submit_orchestration_branch",
    orchestrationWired: false,
    runQueuedChatSubmitOrchestration: stage5f51RunQueuedChatSubmitOrchestration,
  });
})(typeof window !== "undefined" ? window : globalThis);


/*
 * Stage 5F-57: disabled guarded queued submit skeleton branch.
 *
 * This block exposes a future guarded-submit skeleton for tests/planning.
 * It intentionally does not wire itself into the current submit flow.
 *
 * Safety:
 * - guarded submit remains unwired
 * - legacy/current chat path remains active
 * - does not call queued orchestration
 * - does not call queued send
 * - does not call queued status polling
 * - does not render queued placeholders
 * - does not send client-provided identity fields
 */
(function stage5f57GuardedQueuedSubmitSkeletonBranch(root) {
  "use strict";

  function stage5f57BuildGuardedQueuedSubmitSkeleton(context) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;

    return {
      ok: true,
      stage: "5f57",
      source: "app_js_disabled_guarded_queued_submit_skeleton_branch",
      guardedSubmitWired: false,
      enabled,
      legacyChatPathActive: enabled !== true,
      queuedSubmitSelected: false,
      reason: enabled
        ? "guarded_queued_submit_skeleton_unwired_stage_5f57"
        : "guarded_queued_submit_skeleton_flag_disabled_stage_5f57",
      plannedOrder: [
        "build_safe_payload",
        "make_submit_decision",
        "run_orchestration_once",
        "render_placeholder_once",
        "poll_status_once",
        "render_final_once"
      ],
      helperPresence: {
        payload: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH),
        decision: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH),
        orchestration: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH),
        send: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH),
        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
        placeholder: Boolean(root.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH)
      }
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH = Object.freeze({
    stage: "5f57",
    source: "app_js_disabled_guarded_queued_submit_skeleton_branch",
    guardedSubmitWired: false,
    buildGuardedQueuedSubmitSkeleton: stage5f57BuildGuardedQueuedSubmitSkeleton
  });
})(typeof window !== "undefined" ? window : globalThis);


/*
 * Stage 5F-60: disabled guarded live-submit readiness branch.
 *
 * This block exposes a future live-submit readiness helper for tests/planning.
 * It intentionally does not wire itself into the current submit flow.
 *
 * Safety:
 * - guarded live submit remains unwired
 * - legacy/current chat path remains active
 * - does not call queued orchestration
 * - does not call queued send
 * - does not call queued status polling
 * - does not render queued placeholders
 */
(function stage5f60GuardedLiveSubmitReadinessBranch(root) {
  "use strict";

  function stage5f60BuildGuardedLiveSubmitReadiness(context) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;

    return {
      ok: true,
      stage: "5f60",
      source: "app_js_disabled_guarded_live_submit_readiness_branch",
      guardedLiveSubmitWired: false,
      enabled,
      liveSubmitSelected: false,
      legacyChatPathActive: true,
      reason: enabled
        ? "guarded_live_submit_unwired_stage_5f60"
        : "guarded_live_submit_flag_disabled_stage_5f60",
      requiredBeforeEnable: [
        "flag_off_legacy_submit_unchanged",
        "single_orchestration_call",
        "single_queued_send",
        "single_placeholder",
        "single_poll_loop",
        "single_final_render",
        "rollback_flag_off"
      ],
      helperPresence: {
        guardedSkeleton: Boolean(root.AI_PLATFORM_QUEUED_CHAT_GUARDED_SUBMIT_SKELETON_BRANCH),
        orchestration: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_ORCHESTRATION_BRANCH),
        payload: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_PAYLOAD_BRANCH),
        decision: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SUBMIT_DECISION_BRANCH),
        send: Boolean(root.AI_PLATFORM_QUEUED_CHAT_SEND_BRANCH),
        poll: Boolean(root.AI_PLATFORM_QUEUED_CHAT_STATUS_POLL_BRANCH),
        placeholder: Boolean(root.AI_PLATFORM_QUEUED_CHAT_ASSISTANT_PLACEHOLDER_BRANCH)
      }
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH = Object.freeze({
    stage: "5f60",
    source: "app_js_disabled_guarded_live_submit_readiness_branch",
    guardedLiveSubmitWired: false,
    buildGuardedLiveSubmitReadiness: stage5f60BuildGuardedLiveSubmitReadiness
  });
})(typeof window !== "undefined" ? window : globalThis);


/*
 * Stage 5F-63: disabled guarded live-submit gate branch.
 *
 * This block exposes a future live-submit gate helper for tests/planning.
 * It intentionally does not wire itself into the current submit flow.
 *
 * Safety:
 * - guarded live-submit gate remains unwired
 * - legacy/current chat path remains active
 * - does not call queued orchestration
 * - does not call queued send
 * - does not call queued status polling
 * - does not render queued placeholders
 */
(function stage5f63GuardedLiveSubmitGateBranch(root) {
  "use strict";

  function stage5f63EvaluateGuardedLiveSubmitGate(context) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;
    const readiness = root.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH;

    return {
      ok: true,
      stage: "5f63",
      source: "app_js_disabled_guarded_live_submit_gate_branch",
      guardedLiveSubmitGateWired: false,
      enabled,
      readinessPresent: Boolean(readiness),
      liveSubmitSelected: false,
      legacyChatPathActive: true,
      queuedSubmitAllowed: false,
      reason: enabled
        ? "guarded_live_submit_gate_unwired_stage_5f63"
        : "guarded_live_submit_gate_flag_disabled_stage_5f63",
      blockedActions: [
        "queued_orchestration",
        "queued_send",
        "queued_polling",
        "queued_placeholder",
        "queued_final_render"
      ],
      requiredBeforeWire: [
        "flag_off_regression_passes",
        "gate_mock_test_passes",
        "single_orchestration_call_proven",
        "single_send_call_proven",
        "single_poll_loop_proven",
        "single_final_render_proven",
        "rollback_flag_off_proven"
      ]
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH = Object.freeze({
    stage: "5f63",
    source: "app_js_disabled_guarded_live_submit_gate_branch",
    guardedLiveSubmitGateWired: false,
    evaluateGuardedLiveSubmitGate: stage5f63EvaluateGuardedLiveSubmitGate
  });
})(typeof window !== "undefined" ? window : globalThis);
