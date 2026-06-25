/* APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2: disable early duplicate Study tools before route code runs. */
window.__apcStudySingleOwnerDisableEarlyToolsFcO45CL = true;
window.__apcStudyCanonicalFullWorkspaceFcO45CNR2 = true;

/*
 * APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G
 *
 * Runs before the older wrapper code so Study cleanup is registered even if later
 * modules fail. Public-safe: API data is requested only from authenticated Study
 * endpoints, which return 401 when signed out.
 */
(() => {
  const MARKER = "APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G";
  const PANEL_ID = "apc-study-early-tools-fc-o45-c-g";
  const LEGACY_PHRASE = "Create decks, add cards, review by difficulty, and track progress from the shared wrapper layout.";
  let timer = null;
  let lastDeckId = null;

  function esc(value) {
    return String(value ?? "").replace(/[&<>"']/g, (ch) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      "\"": "&quot;",
      "'": "&#39;",
    }[ch]));
  }

  function textOf(el) {
    return (el && el.textContent ? el.textContent : "").replace(/\s+/g, " ").trim();
  }

  function looksLikeStudy() {
    const t = textOf(document.body);
    return t.includes("Study session") || t.includes("Deck selector") || t.includes(LEGACY_PHRASE);
  }

  function deckIdFromPage() {
    const t = textOf(document.body);
    const selected = t.match(/Selected:\s*[^#]+#(\d+)/i);
    if (selected) return selected[1];
    const hash = t.match(/deck\s*#(\d+)/i);
    return hash ? hash[1] : null;
  }

  async function apiJson(path) {
    /* APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K: prefer wrapper api() so signed-in Study calls carry auth headers. */
    if (typeof api === "function" && typeof path === "string" && path.startsWith("/api/")) {
      try {
        const apiPath = path.slice(4);
        const data = await api(apiPath, { method: "GET" });
        const status = Number(data?.status || data?.status_code || 200) || 200;
        const ok = !(data && data.ok === false) && status < 400;
        return { ok, status, data };
      } catch (error) {
        const status = Number(error?.status || error?.response?.status || error?.data?.status || 0) || 0;
        return {
          ok: false,
          status,
          data: { detail: error?.message || "Study API unavailable" },
        };
      }
    }
    const response = await fetch(path, {
      credentials: "include",
      headers: { "Accept": "application/json" },
    });
    const body = await response.text();
    let data = null;
    try {
      data = body ? JSON.parse(body) : null;
    } catch (_) {
      data = { raw: body };
    }
    return { ok: response.ok, status: response.status, data };
  }

  function hideLegacyDuplicate() {
    const all = Array.from(document.querySelectorAll("section, article, main, main > div, .card, .panel, div"));
    const candidates = all
      .filter((el) => el.id !== PANEL_ID && textOf(el).includes(LEGACY_PHRASE))
      .map((el) => ({ el, text: textOf(el) }))
      .sort((a, b) => a.text.length - b.text.length);

    for (const item of candidates) {
      const t = item.text;
      const isWholeShell = t.includes("Study session") && t.includes("Deck selector") && t.includes(LEGACY_PHRASE);
      const isLegacyChunk = t.includes(LEGACY_PHRASE)
        && (t.length < 3500 || (t.includes("Support") && t.includes("Loading")));
      if (isLegacyChunk && !isWholeShell) {
        item.el.setAttribute("data-apc-study-legacy-hidden", MARKER);
        item.el.hidden = true;
        item.el.style.display = "none";
      }
    }

    // Fallback for the nested legacy mini-app: hide the smallest parent containing the
    // legacy phrase plus its own second nav/loading markers, but not the durable shell.
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const textNodes = [];
    while (walker.nextNode()) {
      if ((walker.currentNode.nodeValue || "").includes(LEGACY_PHRASE)) {
        textNodes.push(walker.currentNode);
      }
    }
    for (const node of textNodes) {
      let el = node.parentElement;
      for (let depth = 0; el && depth < 8; depth += 1, el = el.parentElement) {
        const t = textOf(el);
        if (!t.includes(LEGACY_PHRASE)) continue;
        if (t.includes("Study session") && t.includes("Deck selector")) break;
        if (t.length < 3500 || (t.includes("Support") && t.includes("Loading"))) {
          el.setAttribute("data-apc-study-legacy-hidden", MARKER);
          el.hidden = true;
          el.style.display = "none";
          break;
        }
      }
    }
  }

  function mountPanel() {
    if (window.__apcStudySingleOwnerDisableEarlyToolsFcO45CL) {
      let scratch = document.getElementById("apcStudyEarlyToolsScratchFcO45CL");
      if (!scratch) {
        scratch = document.createElement("section");
        scratch.id = "apcStudyEarlyToolsScratchFcO45CL";
        scratch.hidden = true;
        scratch.setAttribute("aria-hidden", "true");
        scratch.setAttribute("data-apc-study-single-owner", "APC_STUDY_SINGLE_OWNER_FC_O45_C_L");
        (document.body || document.documentElement).appendChild(scratch);
      }
      return scratch;
    }
    let panel = document.getElementById(PANEL_ID);
    if (panel) return panel;

    const anchors = Array.from(document.querySelectorAll("section, article, .card, .panel, div, h1, h2, h3, strong"));
    let anchor = anchors.find((el) => textOf(el).includes("Deck selector"))
      || anchors.find((el) => textOf(el).includes("Study session"));

    let container = anchor;
    for (let i = 0; i < 6 && container && container.parentElement; i += 1) {
      const t = textOf(container);
      if (t.includes("Deck selector") && t.length < 2600) break;
      if (t.includes("Study session") && t.length < 2600) break;
      container = container.parentElement;
    }

    panel = document.createElement("section");
    panel.id = PANEL_ID;
    panel.className = "card apc-study-tools";
    panel.setAttribute("data-apc-marker", MARKER);
    panel.innerHTML = `
      <h2>Study tools</h2>
      <p class="muted">Decks, cards, stats, and review queue are loaded from your signed-in Study account.</p>
      <div class="grid two">
        <section class="mini-summary" id="apcStudyEarlyDecks"><strong>Decks</strong><p class="muted">Loading decks…</p></section>
        <section class="mini-summary" id="apcStudyEarlyStats"><strong>Stats</strong><p class="muted">Loading progress…</p></section>
      </div>
      <div class="grid two">
        <section class="mini-summary" id="apcStudyEarlyCards"><strong>Cards</strong><p class="muted">Choose a deck to load cards.</p></section>
        <section class="mini-summary" id="apcStudyEarlyReview"><strong>Review queue</strong><p class="muted">Choose a deck to load the review queue.</p></section>
      </div>
    `;

    if (container && container.parentNode) {
      container.insertAdjacentElement("afterend", panel);
    } else {
      document.body.appendChild(panel);
    }
    return panel;
  }

  function renderDecks(payload) {
    const panel = document.getElementById("apcStudyEarlyDecks");
    if (!panel) return null;
    const decks = Array.isArray(payload?.decks) ? payload.decks : [];
    if (!decks.length) {
      panel.innerHTML = `<strong>Decks</strong><p class="muted">No decks were returned for this account yet.</p>`;
      return null;
    }
    const selected = lastDeckId || deckIdFromPage() || String(decks[0].id);
    lastDeckId = selected;
    const list = decks.slice(0, 8).map((deck) => {
      const id = String(deck.id ?? "");
      const title = esc(deck.title || deck.name || `Deck #${id}`);
      const count = deck.card_count ?? deck.cards_count ?? deck.total_cards ?? "—";
      return `<li><button type="button" class="secondary" data-apc-early-deck-id="${esc(id)}">${title}</button> <span class="muted">${esc(count)} cards</span></li>`;
    }).join("");
    panel.innerHTML = `<strong>Decks</strong><p class="muted">${esc(payload.count ?? decks.length)} deck(s) available. Selected deck #${esc(selected)}.</p><ul>${list}</ul>`;
    panel.querySelectorAll("[data-apc-early-deck-id]").forEach((btn) => {
      btn.addEventListener("click", () => {
        lastDeckId = btn.getAttribute("data-apc-early-deck-id");
        loadTools(lastDeckId);
      });
    });
    return selected;
  }

  function renderStats(payload) {
    const panel = document.getElementById("apcStudyEarlyStats");
    if (!panel) return;
    const totals = payload?.totals || payload?.summary || payload || {};
    const accuracy = totals.accuracy === null || totals.accuracy === undefined ? "—" : `${Math.round(Number(totals.accuracy) * 100)}%`;
    panel.innerHTML = `
      <strong>Stats</strong>
      <dl>
        <dt>Decks</dt><dd>${esc(totals.total_decks ?? payload?.deck_count ?? "—")}</dd>
        <dt>Cards</dt><dd>${esc(totals.total_cards ?? payload?.card_count ?? "—")}</dd>
        <dt>Reviews</dt><dd>${esc(totals.total_reviews ?? payload?.review_count ?? "—")}</dd>
        <dt>Accuracy</dt><dd>${esc(accuracy)}</dd>
      </dl>
    `;
  }

  function renderCards(payload, deckId) {
    const panel = document.getElementById("apcStudyEarlyCards");
    if (!panel) return;
    const cards = Array.isArray(payload?.cards) ? payload.cards : [];
    if (!cards.length) {
      panel.innerHTML = `<strong>Cards</strong><p class="muted">No cards returned for deck #${esc(deckId)}.</p>`;
      return;
    }
    const list = cards.slice(0, 6).map((card) => {
      const q = esc(card.question || card.front || card.prompt || `Card #${card.id}`);
      const a = esc(card.answer || card.back || "");
      return `<li><strong>${q}</strong>${a ? `<br><span class="muted">${a}</span>` : ""}</li>`;
    }).join("");
    panel.innerHTML = `<strong>Cards</strong><p class="muted">${esc(payload.count ?? cards.length)} card(s) in deck #${esc(deckId)}.</p><ul>${list}</ul>`;
  }

  function renderReview(payload, deckId) {
    const panel = document.getElementById("apcStudyEarlyReview");
    if (!panel) return;
    const queue = Array.isArray(payload?.queue) ? payload.queue : Array.isArray(payload?.cards) ? payload.cards : [];
    if (!queue.length) {
      panel.innerHTML = `<strong>Review queue</strong><p class="muted">No review cards returned for deck #${esc(deckId)}.</p>`;
      return;
    }
    const card = queue[0];
    const q = esc(card.question || card.front || card.prompt || `Card #${card.id}`);
    const bucket = esc(card.performance_bucket || card.bucket || "balanced");
    panel.innerHTML = `
      <strong>Review queue</strong>
      <p class="muted">${esc(queue.length)} card(s) queued. First bucket: ${bucket}.</p>
      <p><strong>${q}</strong></p>
      <div class="actions">
        <button type="button" disabled>Read answer</button>
        <button type="button" disabled>Correct</button>
        <button type="button" disabled>Wrong</button>
        <button type="button" disabled>Skip</button>
      </div>
      <p class="muted">Durable session controls remain the active review controls.</p>
    `;
  }

  async function loadTools(deckIdOverride) {
    const panel = mountPanel();
    if (!panel) return;
    const decksResult = await apiJson("/api/study/decks");
    if (!decksResult.ok) {
      panel.setAttribute("data-apc-study-tools-auth-cleanup", "APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K");
      panel.remove();
      return;
    }
    const selectedDeckId = renderDecks(decksResult.data) || deckIdOverride || deckIdFromPage();
    const progress = await apiJson("/api/study/progress");
    if (progress.ok) renderStats(progress.data);
    else {
      const stats = document.getElementById("apcStudyEarlyStats");
      if (stats) stats.innerHTML = `<strong>Stats</strong><p class="muted">Progress endpoint unavailable (${progress.status}).</p>`;
    }
    const deckId = deckIdOverride || selectedDeckId;
    if (!deckId) return;
    const cards = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/cards`);
    if (cards.ok) renderCards(cards.data, deckId);
    else {
      const p = document.getElementById("apcStudyEarlyCards");
      if (p) p.innerHTML = `<strong>Cards</strong><p class="muted">Cards endpoint unavailable (${cards.status}).</p>`;
    }
    const review = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue`);
    if (review.ok) renderReview(review.data, deckId);
    else {
      const p = document.getElementById("apcStudyEarlyReview");
      if (p) p.innerHTML = `<strong>Review queue</strong><p class="muted">Review queue endpoint unavailable (${review.status}).</p>`;
    }
  }

  function runRepair() {
    if (!document.body || !looksLikeStudy()) return;
    hideLegacyDuplicate();
    mountPanel();
    loadTools(deckIdFromPage()).catch((error) => {
      const panel = document.getElementById(PANEL_ID);
      if (panel) panel.innerHTML = `<h2>Study tools</h2><p class="muted">Study tools could not load yet.</p>`;
      console.warn(`[${MARKER}] Study tools load skipped`, error);
    });
  }

  function schedule() {
    clearTimeout(timer);
    timer = setTimeout(runRepair, 40);
  }

  window.apcStudyEarlyRepairFcO45CG = { marker: MARKER, repair: runRepair };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", schedule, { once: true });
  } else {
    schedule();
  }

  window.addEventListener("hashchange", schedule);
  window.addEventListener("popstate", schedule);
  document.addEventListener("click", () => setTimeout(schedule, 80), true);

  try {
    const observer = new MutationObserver(() => {
      if (document.body && looksLikeStudy()) schedule();
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
  } catch (_) {}
})();


// COMPANION_TRANSIENT_CONTROLLER_WRAPPER_V1
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
    return "The platform gateway timed out before the browser received a final response. I will not show the raw Cloudflare error page. Refresh in a moment or try again.";
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
let profilePreferences = null;
let profilePreferencesLoading = false;
let profilePreferencesSaving = false;
let profilePreferencesError = "";
let profilePreferencesSaveMessage = "";
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
    return "The platform gateway timed out before the browser received a final response. I will not show the raw Cloudflare error page. Refresh in a moment or try again.";
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
const PRIVATE_APP_ROUTE_SET = new Set(["/study-wrapper-preview", "/study", "/chat", "/companion", "/calendar", "/profile"]);

function refreshPrivateRouteAfterAuth(reason = "auth") {
  // STAGE_5O10_REMOVE_FRESH_ROUTE_CACHE_BUSTING_V1
  // Keep private app routes clean. Data freshness is handled by the API cache
  // invalidation/refresh layer, not by adding ?fresh= timestamps to URLs.
  try {
    const cleanPath = String(window.location.pathname || "/").split("?")[0].split("#")[0] || "/";
    if (PRIVATE_APP_ROUTE_SET && PRIVATE_APP_ROUTE_SET.has(cleanPath)) {
      window.history.replaceState({}, "", cleanPath);
      if (typeof renderRoute === "function") {
        renderRoute(cleanPath);
      }
      return true;
    }
  } catch (err) {
    console.warn("Private route clean refresh failed:", err);
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
      ["Companion", "Use Companion for general conversation, study help, explanations, and supportive conversation.", "/companion"],
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

  "/study-wrapper-preview": {
    eyebrow: "Preview",
    title: "Study Wrapper Preview",
    subtitle: "Preview of the Study dashboard inside the shared wrapper layout. Study behavior is not wired here yet.",
    boxes: [],
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
    eyebrow: "Compatibility route",
    title: "Companion",
    subtitle:
      "Chat remains a compatibility alias while Companion becomes the main AI surface for conversation, study help, explanations, and supportive support.",
    boxes: [
      ["Companion", "General local-first AI conversation through the existing queued worker path."],
      ["Study-aware direction", "Future stages will add study session controls, deck/card tools, and answer checking."],
      ["Compatibility", "/chat stays available for old links while /companion is the primary route."],
      ["Safe migration", "No backend queue or controller behavior changes in this visible route stage."],
    ],
  },

  "/companion": {
    eyebrow: "Main AI surface",
    title: "Companion",
    subtitle:
      "Companion is the main AI surface for conversation, studying, explanations, practice, and future personalized support.",
    boxes: [
      ["General conversation", "Use Companion for normal local-first AI conversation."],
      ["Study helper", "Future stages will let Companion start study sessions, select decks, read questions, and grade answers."],
      ["Context aware", "Future versions can use profile, calendar, study, and file context with permission."],
      ["Helpful boundaries", "Companion should stay supportive, ask when unsure, and use safety-aware boundaries."],
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
    title: "Help when something is not working",
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
 * - /api/study/* = CT203/controller-owned Study API
 * - /api/companion/* = CT203/controller-owned Companion API
 * - /api/calendar/* = CT203/controller-owned Calendar API
 * - /credits/* = controller-owned credit wallet and ledger
 * - /ads/reward/* = controller-owned rewarded ad claims
 * - /gpu/* = controller-owned GPU credit reservation and session management
 * - /support/* = controller-owned support tickets
 *
 * Note: The wrapper makes fetch calls to /api/* paths, which are translated
 * by the laptop wrapper to laptop controller routes,
 * or proxied to current CT203 controller/API/queue endpoints as appropriate.
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
      "/system/status",
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
  "ct203-controller-queue",
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
  "ct203-controller-queue": "CT203 controller/API/queue authority for the current PVEW-hosted platform.",
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

function privateStorageInfrastructureDetail(storage) {
  const ct204 = storage?.ct204 || {};
  const policy = storage?.policy || "unknown";
  const mountState = storage?.mount_state || storage?.state || "unknown";
  const mountpoint = storage?.mountpoint || "unknown";
  const expectedState = ct204.expected_state || "unknown";
  const authority = ct204.data_authority === true
    ? "true"
    : ct204.data_authority === false
      ? "false"
      : "unknown";

  return `Private backup storage policy: ${policy}; mount: ${mountState}; path: ${mountpoint}; CT204 expected: ${expectedState}; authority: ${authority}.`;
}

function privateStorageInfrastructureGroup(source = lastStatus) {
  const storage = source?.private_storage_status;
  if (!storage || typeof storage !== "object") return null;

  const state = storage.state || storage.mount_state || "unknown";
  const detail = privateStorageInfrastructureDetail(storage);

  return {
    id: "storage-nodes",
    name: "Storage Nodes",
    state,
    counts: statusCounts([state]),
    detail,
    members: [
      {
        id: storage.id || "apc-private-storage",
        name: storage.name || "Encrypted Private Backup Storage",
        state,
        detail,
      },
    ],
  };
}

function normalizedInfrastructureGroups(source = lastStatus) {
  const items = normalizedItems(source, "infrastructure", NORMALIZED_INFRASTRUCTURE_IDS);
  if (!items) return null; // Fallback to infrastructureGroups() when normalized.infrastructure is unavailable.

  const groups = items.map((item) => {
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

  const storageGroup = privateStorageInfrastructureGroup(source);
  if (storageGroup) {
    const existingIndex = groups.findIndex((group) => group.id === "storage-nodes");
    if (existingIndex >= 0) groups[existingIndex] = storageGroup;
    else groups.push(storageGroup);
  }

  return groups;
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
  const controller = nodeById("ct-203");
  const platformHost = nodeById("pvew");
  const websiteEdge = nodeById("vm-200");

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
      states: [platformHost?.state || "offline"],
      detail: "Configured Proxmox server nodes.",
    }),
    makeInfraGroup({
      id: "cpu-nodes",
      name: "CPU Nodes",
      states: [websiteEdge?.state || "offline"],
      detail: "CPU processing containers currently configured.",
    }),
    makeInfraGroup({
      id: "gpu-nodes",
      name: "GPU Nodes",
      states: [],
      detail: "Future GPU processing containers for image/video jobs.",
    }),
    privateStorageInfrastructureGroup(lastStatus) || makeInfraGroup({
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


function phase11eRenderSystemPageOriginal() {
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

// PHASE_11E_SYSTEM_STABLE_RENDER_BEGIN
// Keep /system from flashing the older static API catalog before live status loads.
// The original renderer is preserved above and used once adminStatus has the live payload.
function renderSystemPage() {
  const phase11eStatus = lastStatus || {}; // PHASE_11G_SYSTEM_READINESS_VARIABLE_REPAIR
  const phase11eHasLiveStatus = Boolean(
    lastStatus &&
    (
      Array.isArray(phase11eStatus.services) ||
      Array.isArray(phase11eStatus.nodes) ||
      Array.isArray(phase11eStatus.groups) ||
      Object.prototype.hasOwnProperty.call(phase11eStatus, "ok") ||
      Object.prototype.hasOwnProperty.call(phase11eStatus, "admin")
    )
  );

  if (!phase11eHasLiveStatus) {
    return `
      <section class="system-section" id="phase11fSystemStatusLoading">
        <h2>APIs</h2>
        <div class="notice">
          <strong>Loading live platform status...</strong>
          <p>Checking backend, frontend, queue, worker, and power automation status.</p>
        </div>
      </section>
    `;
  }

  return phase11eRenderSystemPageOriginal();
}

// PHASE_11F_SYSTEM_LOADING_COMPLETION_REPAIR_BEGIN
// Replace the stable loading placeholder with the live System render once loadSystemStatus()
// has populated adminStatus. This avoids a full route rerender and keeps the repair
// frontend-only.
function phase11fRefreshSystemPageIfReady() {
  try {
    if (location.pathname !== "/system") return;
    if (!lastStatus) return;

    const loadingSection = document.getElementById("phase11fSystemStatusLoading");
    if (!loadingSection) return;

    const html = phase11eRenderSystemPageOriginal();
    const template = document.createElement("template");
    template.innerHTML = html.trim();

    if (!template.content.childNodes.length) return;

    loadingSection.replaceWith(template.content);

    const openButton = document.getElementById("openSystemBtn");
    if (openButton && typeof openSystemDrawer === "function" && !openButton.dataset.phase11fBound) {
      openButton.dataset.phase11fBound = "1";
      openButton.addEventListener("click", openSystemDrawer);
    }

    if (typeof cleanRemoveAdminInfrastructureFromSystemPage === "function") {
      cleanRemoveAdminInfrastructureFromSystemPage();
    }
  } catch (error) {
    console.warn("[phase11f] System page refresh after status load failed", error);
  }
}
// PHASE_11F_SYSTEM_LOADING_COMPLETION_REPAIR_END

// PHASE_11E_SYSTEM_STABLE_RENDER_END




function setStudyWrapperPreviewReadOnly() {
  const root = document.querySelector(".study-wrapper-preview");
  if (!root) return;

  root.querySelectorAll("input, textarea, select, button").forEach((el) => {
    const isSafePreviewSelect = el.id === "deckSelect";
    const isCreateDeckControl =
      el.id === "deckTitleInput" ||
      el.id === "deckDescriptionInput" ||
      el.closest?.("#deckForm");

    const isCreateCardControl =
      el.id === "questionInput" ||
      el.id === "answerInput" ||
      el.id === "explanationInput" ||
      el.id === "difficultyInput" ||
      el.id === "tagsInput" ||
      el.closest?.("#cardForm");

    const isReviewQueueControl =
      el.id === "reviewMode" ||
      el.id === "loadQueueBtn";

    if (isSafePreviewSelect || isCreateDeckControl || isCreateCardControl || isReviewQueueControl) {
      el.disabled = false;
      el.removeAttribute("aria-disabled");
      el.title = "Preview-only deck switching. Editing and review actions are still disabled.";
      return;
    }

    el.disabled = true;
    el.setAttribute("aria-disabled", "true");
    el.title = "Preview only. Use the live Study page for editing and review actions.";
  });

  const firstPanel = root.querySelector(".panel");
  if (firstPanel && !root.querySelector("[data-study-preview-notice]")) {
    const notice = document.createElement("div");
    notice.className = "mini-summary";
    notice.setAttribute("data-study-preview-notice", "true");
    notice.innerHTML = `
      <strong>Preview only</strong>
      <p>This shared-layout preview is read-only. Use <a href="/study">the live Study page</a> to create decks, add cards, or review cards.</p>
    `;
    firstPanel.prepend(notice);
  }
}


function studyPreviewSetText(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = value;
}

function studyPreviewEscape(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}


function studyPreviewNormalizeDifficulty(card) {
  const explicit = String(
    card?.difficulty ||
    card?.difficulty_bucket ||
    card?.bucket ||
    card?.level ||
    ""
  ).toLowerCase();

  if (["new", "hard", "medium", "easy"].includes(explicit)) {
    return explicit;
  }

  const reviews = Number(card?.review_count ?? card?.total_reviews ?? card?.reviews ?? 0);
  const wrongStreak = Number(card?.wrong_streak ?? card?.wrongStreak ?? 0);
  const accuracy = typeof card?.accuracy === "number" ? card.accuracy : null;

  if (reviews <= 0) return "new";
  if (wrongStreak >= 2) return "hard";
  if (accuracy !== null && accuracy <= 0.34) return "hard";
  if (accuracy !== null && reviews >= 5 && accuracy >= 0.85) return "easy";
  return "medium";
}

function studyPreviewPercent(value) {
  return typeof value === "number" ? `${Math.round(value * 100)}%` : "—";
}

function studyPreviewCardArray(data) {
  if (Array.isArray(data?.cards)) return data.cards;
  if (Array.isArray(data?.card_stats)) return data.card_stats;
  if (Array.isArray(data?.stats)) return data.stats;
  if (Array.isArray(data)) return data;
  return [];
}


function renderStudyWrapperPreviewDeckSummary(deck) {
  const deckSummary = document.getElementById("deckSummary");
  if (!deckSummary) return;

  if (!deck) {
    deckSummary.textContent = "No deck selected.";
    return;
  }

  const deckAccuracy = typeof deck.accuracy === "number"
    ? `${Math.round(deck.accuracy * 100)}% accuracy`
    : "— accuracy";

  deckSummary.innerHTML = `
    <strong>${studyPreviewEscape(deck.title)}</strong>
    <p>${studyPreviewEscape(deck.description || "")}</p>
    <small>${Number(deck.card_count || 0)} cards · ${Number(deck.total_reviews || 0)} reviews · ${deckAccuracy}</small>
  `;
}


async function createStudyWrapperPreviewDeck(event) {
  event.preventDefault();

  const titleInput = document.getElementById("deckTitleInput");
  const descriptionInput = document.getElementById("deckDescriptionInput");
  const statusText = document.getElementById("workerStatusText");

  const title = String(titleInput?.value || "").trim();
  const description = String(descriptionInput?.value || "").trim();

  if (!title) {
    alert("Enter a deck title first.");
    return;
  }

  try {
    if (statusText) statusText.textContent = "Creating deck...";

    const res = await fetch("/api/study/decks", {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, description })
    });

    const text = await res.text();
    if (!res.ok) throw new Error(`/api/study/decks HTTP ${res.status}: ${text.slice(0, 160)}`);

    const data = JSON.parse(text);
    const newDeckId = data?.deck?.id;

    if (titleInput) titleInput.value = "";
    if (descriptionInput) descriptionInput.value = "";

    await hydrateStudyWrapperPreview(newDeckId);

    if (statusText) statusText.textContent = "Deck created";
  } catch (error) {
    console.error("[study-wrapper-preview] create deck failed", error);
    if (statusText) statusText.textContent = "Could not create deck";
    alert(`Could not create deck: ${error.message || error}`);
  }
}



const studyPreviewReviewState = {
  queue: [],
  currentIndex: 0,
  showingAnswer: false
};


async function submitStudyWrapperPreviewReview(cardId, wasCorrect) {
  const statusText = document.getElementById("workerStatusText");
  const deckSelect = document.getElementById("deckSelect");
  const deckId = String(deckSelect?.value || "").trim();

  try {
    if (statusText) statusText.textContent = "Submitting review...";

    const res = await fetch(`/api/study/cards/${encodeURIComponent(cardId)}/reviews`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        was_correct: Boolean(wasCorrect),
        confidence: wasCorrect ? 4 : 2
      })
    });

    const text = await res.text();
    if (!res.ok) {
      throw new Error(`/api/study/cards/${cardId}/reviews HTTP ${res.status}: ${text.slice(0, 160)}`);
    }

    studyPreviewReviewState.currentIndex += 1;
    studyPreviewReviewState.showingAnswer = false;

    if (deckId) {
      await hydrateStudyWrapperPreview(deckId);
    }

    renderStudyWrapperPreviewReviewCard();

    if (statusText) statusText.textContent = "Review submitted";
  } catch (error) {
    console.error("[study-wrapper-preview] review submit failed", error);
    if (statusText) statusText.textContent = "Could not submit review";
    alert(`Could not submit review: ${error.message || error}`);
  }
}


function renderStudyWrapperPreviewReviewCard() {
  const el = document.getElementById("reviewCard");
  if (!el) return;

  const card = studyPreviewReviewState.queue[studyPreviewReviewState.currentIndex];

  if (!card) {
    el.innerHTML = `<p class="muted">No cards in the current preview queue.</p>`;
    return;
  }

  const accuracy = card.accuracy === null || card.accuracy === undefined
    ? "—"
    : `${Math.round(card.accuracy * 100)}%`;

  const answerBlock = studyPreviewReviewState.showingAnswer
    ? `
      <div class="mini-summary">
        <strong>Answer</strong>
        <p>${studyPreviewEscape(card.answer || "No answer saved.")}</p>
        ${card.explanation ? `<p class="muted">${studyPreviewEscape(card.explanation)}</p>` : ""}
      </div>
    `
    : "";

  el.innerHTML = `
    <div class="card-row">
      <strong>${studyPreviewEscape(card.question || "Untitled card")}</strong>
      <span class="card-meta">
        ${studyPreviewEscape(card.performance_bucket || card.difficulty || "new")}
        · ${Number(card.total_reviews || 0)} reviews
        · ${accuracy} accuracy
      </span>
    </div>

    ${answerBlock}

    <div class="actions">
      ${studyPreviewReviewState.showingAnswer ? `
        <button class="secondary" type="button" id="studyPreviewWrongBtn">Wrong</button>
        <button class="primary-btn" type="button" id="studyPreviewCorrectBtn">Correct</button>
      ` : `
        <button class="primary-btn" type="button" id="studyPreviewShowAnswerBtn">Show Answer</button>
      `}
      <button class="secondary" type="button" id="studyPreviewSkipCardBtn">Skip</button>
    </div>
  `;

  document.getElementById("studyPreviewShowAnswerBtn")?.addEventListener("click", () => {
    studyPreviewReviewState.showingAnswer = true;
    renderStudyWrapperPreviewReviewCard();
  });

  document.getElementById("studyPreviewSkipCardBtn")?.addEventListener("click", () => {
    studyPreviewReviewState.currentIndex += 1;
    studyPreviewReviewState.showingAnswer = false;
    renderStudyWrapperPreviewReviewCard();
  });

  document.getElementById("studyPreviewWrongBtn")?.addEventListener("click", () => {
    submitStudyWrapperPreviewReview(card.id, false);
  });

  document.getElementById("studyPreviewCorrectBtn")?.addEventListener("click", () => {
    submitStudyWrapperPreviewReview(card.id, true);
  });
}

async function loadStudyWrapperPreviewReviewQueue() {
  const deckSelect = document.getElementById("deckSelect");
  const reviewMode = document.getElementById("reviewMode");
  const statusText = document.getElementById("workerStatusText");

  const deckId = String(deckSelect?.value || "").trim();
  if (!deckId) {
    alert("Select or create a deck first.");
    return;
  }

  const mode = String(reviewMode?.value || "balanced");

  try {
    if (statusText) statusText.textContent = "Loading review queue...";

    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
      credentials: "include",
      cache: "no-store"
    });

    const text = await res.text();
    if (!res.ok) {
      throw new Error(`/api/study/decks/${deckId}/review-queue HTTP ${res.status}: ${text.slice(0, 160)}`);
    }

    const data = JSON.parse(text);
    studyPreviewReviewState.queue = Array.isArray(data.cards) ? data.cards : [];
    studyPreviewReviewState.currentIndex = 0;
    studyPreviewReviewState.showingAnswer = false;

    const buckets = data.bucket_counts || {};
    studyPreviewSetText("bucketNew", String(buckets.new || 0));
    studyPreviewSetText("bucketHard", String(buckets.hard || 0));
    studyPreviewSetText("bucketMedium", String(buckets.medium || 0));
    studyPreviewSetText("bucketEasy", String(buckets.easy || 0));

    renderStudyWrapperPreviewReviewCard();

    if (statusText) statusText.textContent = "Review queue loaded";
  } catch (error) {
    console.error("[study-wrapper-preview] review queue failed", error);
    if (statusText) statusText.textContent = "Could not load review queue";
    alert(`Could not load review queue: ${error.message || error}`);
  }
}

function bindStudyWrapperPreviewReviewQueue() {
  const mode = document.getElementById("reviewMode");
  const button = document.getElementById("loadQueueBtn");

  if (mode) {
    mode.disabled = false;
    mode.removeAttribute("aria-disabled");
    mode.title = "Choose preview review queue mode.";
  }

  if (button) {
    button.disabled = false;
    button.removeAttribute("aria-disabled");
    button.title = "Load preview review queue.";
    button.onclick = loadStudyWrapperPreviewReviewQueue;
  }
}


async function createStudyWrapperPreviewCard(event) {
  event.preventDefault();

  const deckSelect = document.getElementById("deckSelect");
  const statusText = document.getElementById("workerStatusText");

  const deckId = String(deckSelect?.value || "").trim();
  if (!deckId) {
    alert("Select or create a deck first.");
    return;
  }

  const payload = {
    question: String(document.getElementById("questionInput")?.value || "").trim(),
    answer: String(document.getElementById("answerInput")?.value || "").trim(),
    explanation: String(document.getElementById("explanationInput")?.value || "").trim(),
    difficulty: String(document.getElementById("difficultyInput")?.value || ""),
    tags: String(document.getElementById("tagsInput")?.value || "")
  };

  if (!payload.question || !payload.answer) {
    alert("Enter both a question and an answer.");
    return;
  }

  try {
    if (statusText) statusText.textContent = "Adding card...";

    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/cards`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    const text = await res.text();
    if (!res.ok) {
      throw new Error(`/api/study/decks/${deckId}/cards HTTP ${res.status}: ${text.slice(0, 160)}`);
    }

    ["questionInput", "answerInput", "explanationInput", "difficultyInput", "tagsInput"].forEach((id) => {
      const el = document.getElementById(id);
      if (el) el.value = "";
    });

    await hydrateStudyWrapperPreview(deckId);

    if (statusText) statusText.textContent = "Card added";
  } catch (error) {
    console.error("[study-wrapper-preview] add card failed", error);
    if (statusText) statusText.textContent = "Could not add card";
    alert(`Could not add card: ${error.message || error}`);
  }
}

function bindStudyWrapperPreviewCreateCard() {
  const form = document.getElementById("cardForm");
  if (!form) return;

  ["questionInput", "answerInput", "explanationInput", "difficultyInput", "tagsInput"].forEach((id) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.disabled = false;
    el.removeAttribute("aria-disabled");
    el.title = "Add a card to the selected deck.";
  });

  const submitButton = form.querySelector("button[type='submit'], button:not([type])");
  if (submitButton) {
    submitButton.disabled = false;
    submitButton.removeAttribute("aria-disabled");
    submitButton.title = "Add card";
  }

  form.onsubmit = createStudyWrapperPreviewCard;
}


function bindStudyWrapperPreviewCreateDeck() {
  const form = document.getElementById("deckForm");
  const titleInput = document.getElementById("deckTitleInput");
  const descriptionInput = document.getElementById("deckDescriptionInput");

  if (!form) return;

  [titleInput, descriptionInput].forEach((el) => {
    if (!el) return;
    el.disabled = false;
    el.removeAttribute("aria-disabled");
    el.title = "Create a deck in the wrapper preview.";
  });

  const submitButton = form.querySelector("button[type='submit'], button:not([type])");
  if (submitButton) {
    submitButton.disabled = false;
    submitButton.removeAttribute("aria-disabled");
    submitButton.title = "Create deck";
  }

  form.onsubmit = createStudyWrapperPreviewDeck;
}


function bindStudyWrapperPreviewDeckSwitch(decks) {
  const deckSelect = document.getElementById("deckSelect");
  if (!deckSelect) return;

  deckSelect.disabled = false;
  deckSelect.removeAttribute("aria-disabled");
  deckSelect.title = "Preview-only deck switching. Editing and review actions are still disabled.";

  deckSelect.onchange = () => {
    const selected = decks.find((deck) => String(deck.id) === String(deckSelect.value));
    renderStudyWrapperPreviewDeckSummary(selected);
    hydrateStudyWrapperPreviewDeck(deckSelect.value);
  };
}


async function hydrateStudyWrapperPreviewDeck(deckId) {
  if (!deckId) return;

  const cardsList = document.getElementById("cardsList");

  try {
    const res = await fetch(`/api/study/decks/${encodeURIComponent(deckId)}/card-stats`, {
      credentials: "include",
      cache: "no-store"
    });

    const text = await res.text();
    if (!res.ok) throw new Error(`/api/study/decks/${deckId}/card-stats HTTP ${res.status}: ${text.slice(0, 120)}`);

    const data = JSON.parse(text);
    const cards = studyPreviewCardArray(data);

    const buckets = { new: 0, hard: 0, medium: 0, easy: 0 };

    for (const card of cards) {
      const difficulty = studyPreviewNormalizeDifficulty(card);
      if (difficulty in buckets) buckets[difficulty] += 1;
      else buckets.new += 1;
    }

    studyPreviewSetText("bucketNew", String(buckets.new));
    studyPreviewSetText("bucketHard", String(buckets.hard));
    studyPreviewSetText("bucketMedium", String(buckets.medium));
    studyPreviewSetText("bucketEasy", String(buckets.easy));

    if (cardsList) {
      if (!cards.length) {
        cardsList.innerHTML = `<p class="muted">No card stats found for this deck.</p>`;
      } else {
        cardsList.innerHTML = cards.map((card) => {
          const difficulty = studyPreviewNormalizeDifficulty(card);
          const reviews = card.review_count ?? card.total_reviews ?? card.reviews ?? 0;
          const accuracy = studyPreviewPercent(card.accuracy);
          const wrongStreak = card.wrong_streak ?? card.wrongStreak ?? 0;
          const confidence = card.confidence ?? card.avg_confidence ?? "—";
          const question = card.question ?? card.front ?? card.prompt ?? "Untitled card";

          return `
            <div class="card-row">
              <strong>${studyPreviewEscape(question)}</strong>
              <span class="card-meta">
                ${studyPreviewEscape(difficulty)} · ${Number(reviews || 0)} reviews · ${accuracy} accuracy
                · Wrong streak: ${studyPreviewEscape(wrongStreak)}
                · Confidence: ${studyPreviewEscape(confidence)}
              </span>
            </div>
          `;
        }).join("");
      }
    }
  } catch (error) {
    console.error("[study-wrapper-preview] card stats hydrate failed", error);
    if (cardsList) {
      cardsList.innerHTML = `<p class="muted">Could not load card stats.</p>`;
    }
  }
}


async function hydrateStudyWrapperPreview(preferredDeckId = null) {
  const statusText = document.getElementById("workerStatusText");
  const apiDot = document.getElementById("apiDot");

  try {
    if (statusText) statusText.textContent = "Loading Study data...";
    if (apiDot) apiDot.className = "status-dot";

    const [progressRes, decksRes] = await Promise.all([
      fetch("/api/study/progress", { credentials: "include", cache: "no-store" }),
      fetch("/api/study/decks", { credentials: "include", cache: "no-store" })
    ]);

    const progressText = await progressRes.text();
    const decksText = await decksRes.text();

    if (!progressRes.ok) throw new Error(`/api/study/progress HTTP ${progressRes.status}: ${progressText.slice(0, 120)}`);
    if (!decksRes.ok) throw new Error(`/api/study/decks HTTP ${decksRes.status}: ${decksText.slice(0, 120)}`);

    const progress = JSON.parse(progressText);
    const decksData = JSON.parse(decksText);

    const overall = progress.overall || {};
    const decks = Array.isArray(decksData.decks) ? decksData.decks : [];

    studyPreviewSetText("deckCount", String(overall.deck_count ?? decks.length ?? 0));
    studyPreviewSetText("cardCount", String(overall.card_count ?? 0));
    studyPreviewSetText("reviewCount", String(overall.review_count ?? 0));

    const accuracy = overall.accuracy;
    studyPreviewSetText(
      "accuracyValue",
      typeof accuracy === "number" ? `${Math.round(accuracy * 100)}%` : "—"
    );

    const deckSelect = document.getElementById("deckSelect");
    if (deckSelect) {
      deckSelect.innerHTML = `<option value="">Select a deck</option>` + decks.map((deck) => (
        `<option value="${studyPreviewEscape(deck.id)}">${studyPreviewEscape(deck.title)}</option>`
      )).join("");
      const selectedDeck = decks.find((deck) => String(deck.id) === String(preferredDeckId)) || decks[0];
      if (selectedDeck) deckSelect.value = String(selectedDeck.id);
    }

    const selectedDeck = decks.find((deck) => String(deck.id) === String(preferredDeckId)) || decks[0] || null;
    renderStudyWrapperPreviewDeckSummary(selectedDeck);
    bindStudyWrapperPreviewDeckSwitch(decks);
    bindStudyWrapperPreviewCreateDeck();
    bindStudyWrapperPreviewCreateCard();
    bindStudyWrapperPreviewReviewQueue();

    const cardsList = document.getElementById("cardsList");
    if (cardsList && Array.isArray(progress.by_deck) && progress.by_deck[0]) {
      cardsList.innerHTML = progress.by_deck.map((deck) => {
        const deckAccuracy = typeof deck.accuracy === "number" ? `${Math.round(deck.accuracy * 100)}% accuracy` : "— accuracy";
        return `
          <div class="card-row">
            <strong>${studyPreviewEscape(deck.title)}</strong>
            <span>${Number(deck.card_count || 0)} cards · ${Number(deck.review_count || 0)} reviews · ${deckAccuracy}</span>
          </div>
        `;
      }).join("");
    }

    if (selectedDeck) {
      hydrateStudyWrapperPreviewDeck(selectedDeck.id);
    }

    if (statusText) statusText.textContent = "Study data loaded";
    if (apiDot) apiDot.classList.add("ok");
  } catch (error) {
    console.error("[study-wrapper-preview] hydrate failed", error);
    if (statusText) statusText.textContent = "Could not load Study data";
    if (apiDot) apiDot.classList.add("bad");
  }
}


async function loadStudyWrapperPreview() {
  const app = $("app");
  const style = document.getElementById("studyPreviewStyles");
  const isLiveStudyRoute = window.location.pathname === "/study";

  if (style) style.disabled = false;
  if (!app) return;

  try {
    const res = await fetch("/study/study-dashboard.partial.html", {
      credentials: "include",
      cache: "no-store"
    });

    const html = await res.text();

    if (!res.ok) {
      throw new Error(`HTTP ${res.status}: ${html.slice(0, 120)}`);
    }

    app.innerHTML = `
      <section class="page-card">
        <p class="eyebrow">${isLiveStudyRoute ? "Study" : "Candidate route"}</p>
        <h1>${isLiveStudyRoute ? "Study" : "Study Wrapper Preview"}</h1>
        <p class="subtitle">
          ${isLiveStudyRoute
            ? "Create decks, add cards, review by difficulty, and track progress from the shared wrapper layout."
            : "Shared-wrapper candidate route for Study. Use this to verify behavior before removing the standalone fallback."}
        </p>
        ${isLiveStudyRoute ? "" : `
          <div class="actions">
            <a class="primary-btn" href="/study">Open Live Study</a>
            <a class="secondary" href="/study-standalone">Open Standalone Fallback</a>
          </div>
        `}
        <div class="study-wrapper-preview">
          ${html}
        </div>
      </section>
    `;

    hydrateStudyWrapperPreview();
  } catch (error) {
    app.innerHTML = `
      <section class="page-card">
        <p class="eyebrow">Preview error</p>
        <h1>Study Wrapper Preview</h1>
        <p class="subtitle">Could not load the Study partial.</p>
        <pre>${String(error.message || error)}</pre>
      </section>
    `;
  }
}


// STAGE_5L8_MINIMAL_QUEUED_CHAT_UI_V1
// Minimal wrapper-native Chat UI wired to the already working /api/chat/queued API.
// This replaces the static /chat summary with a real send/poll/render loop.
const queuedChatUiState = {
  messages: [],
  busy: false,
  lastJobId: "",
};

function queuedChatEscape(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function queuedChatSetStatus(text) {
  const el = document.getElementById("queuedChatStatus");
  if (el) el.textContent = text || "";
}

function queuedChatRenderMessages() {
  const el = document.getElementById("queuedChatMessages");
  if (!el) return;

  if (!queuedChatUiState.messages.length) {
    el.innerHTML = `<p class="muted">Send a message to start a queued local AI chat.</p>`;
    return;
  }

  el.innerHTML = queuedChatUiState.messages.map((msg) => `
    <div class="summary-box">
      <span>${queuedChatEscape(msg.role)}</span>
      <strong>${queuedChatEscape(msg.content)}</strong>
      ${msg.detail ? `<p>${queuedChatEscape(msg.detail)}</p>` : ""}
    </div>
  `).join("");
}

function renderQueuedChatPage() {
  /* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source.
   * Signed-in Companion renders the minimal chat DOM directly.
   * Existing queued-chat IDs/classes are preserved so current submit, polling,
   * result, and clear handlers keep working.
   */
  if (!authState || !authState.token) {
    return `
      <section class="page-card stage5p8h-companion-page stage5p8h-companion-public" data-stage5p8h-canonical-companion="true">
        <p class="eyebrow">Companion</p>
        <h1>A queued local AI companion for study and support.</h1>
        <p class="subtitle">
          Sign in to use the local queued Companion surface. Logged-out users stay on the public summary path.
        </p>
      </section>
    `;
  }

  return `
    <section class="stage5p8h-companion-page stage16-fc-o45-e-bj-companion-minimal" data-stage5p8h-canonical-companion="true" data-stage16-fc-o45-e-bj="structural-minimal" aria-label="Companion workspace">
      <section class="stage5p8h-conversation-card" aria-label="Companion conversation">
        <section class="stage5p8h-message-stream">
          <h2>Conversation</h2>
          <p class="stage16-fc-o45-e-bj-helper">Type a message and press Enter to send.</p>
          <div id="queuedChatMessages" class="stage5p8h-message-list"></div>
        </section>

        <form id="queuedChatForm" class="stage5p8h-message-form">
          <label for="queuedChatInput">Message</label>
          <textarea id="queuedChatInput" rows="5" placeholder="Message Companion..."></textarea>

          <div class="stage5p8h-actions">
            <button class="stage5p8h-send-button" type="submit" id="queuedChatSendBtn">Send message</button>
            <button class="stage5p8h-clear-button" type="button" id="queuedChatClearBtn">Clear</button>
          </div>
        </form>
      </section>
    </section>
  `;
}




// STAGE_5P10D_COMPANION_QUEUE_AUTH_HEADERS_BEGIN
function queuedChatSessionToken() {
  try {
    return String(
      authState?.token
      || window.localStorage.getItem("edgeStudyToken")
      || ""
    ).trim();
  } catch (err) {
    return String(authState?.token || "").trim();
  }
}

function queuedChatAuthHeaders() {
  const headers = { "Content-Type": "application/json" };
  const token = queuedChatSessionToken();

  if (token) {
    headers.Authorization = "Bearer " + token;
    headers["X-Queued-Chat-Session-Token"] = token;
  }

  return headers;
}
// STAGE_5P10D_COMPANION_QUEUE_AUTH_HEADERS_END



// STAGE_5P10F_COMPANION_QUEUE_POSITION_LOGIC_BEGIN
let stage5p10fQueuePollTimer = null;
let stage5p10fLastJobId = "";

function stage5p10fSetText(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = value || "—";
}

function stage5p10fUpdateQueueDisplay(data) {
  const queue = data && data.queue ? data.queue : {};
  // STAGE_15_F_MOCK_QUEUE_STATUS_POLISH_BEGIN
  const job = data && data.job ? data.job : (data && data.job_id ? data : null);
  // STAGE_15_F_MOCK_QUEUE_STATUS_POLISH_END

  const waiting = Number(queue.waiting_count || 0);
  const running = Number(queue.running_count || 0);
  const total = Number(queue.total_active || 0);

  // STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_LOGIC_BEGIN
  // Show one compact Queue value:
  // - queued job: "position / total"
  // - running job: "running"
  // - completed job: "complete"
  // - no active queue: "0 / 0"
  if (job && job.status && job.status !== "not_found") {
    const status = String(job.status || "").toLowerCase();

    // STAGE_15_F_MOCK_QUEUE_SUMMARY_QUEUED_STATE_BEGIN
    if (["queued", "pending", "waiting", "created"].includes(status)) {
      stage5p10fSetText("queuedChatQueueSummary", "Queued");
      return;
    }
    // STAGE_15_F_MOCK_QUEUE_SUMMARY_QUEUED_STATE_END

    if (job.position !== null && job.position !== undefined) {
      const denominator = total > 0 ? total : waiting;
      stage5p10fSetText("queuedChatQueueSummary", `${job.position} / ${Math.max(denominator, job.position)}`);
      return;
    }

    // STAGE_5P10H_COMPANION_QUEUE_DISPLAY_POLISH_BEGIN
    if (["running", "claimed", "processing", "in_progress"].includes(status)) {
      stage5p10fSetText("queuedChatQueueSummary", "Running");
      return;
    }

    if (["complete", "completed"].includes(status)) {
      stage5p10fSetText("queuedChatQueueSummary", "Done");
      return;
    }

    if (["failed", "error"].includes(status)) {
      stage5p10fSetText("queuedChatQueueSummary", "Failed");
      return;
    }

    if (["cancelled", "canceled"].includes(status)) {
      stage5p10fSetText("queuedChatQueueSummary", "Cancelled");
      return;
    }
    // STAGE_5P10H_COMPANION_QUEUE_DISPLAY_POLISH_END
  }

  if (total > 0) {
    stage5p10fSetText("queuedChatQueueSummary", `— / ${total}`);
  } else {
    stage5p10fSetText("queuedChatQueueSummary", "0 / 0");
  }
  // STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_LOGIC_END
}
async function stage5p10fFetchQueueStatus(jobId) {
  const cleanJobId = String(jobId || stage5p10fLastJobId || "").trim();
  const url = cleanJobId
    ? `/api/chat/queue/status?job_id=${encodeURIComponent(cleanJobId)}`
    : "/api/chat/queue/status";

  try {
    const res = await fetch(url, {
      method: "GET",
      credentials: "include",
      cache: "no-store",
      headers: queuedChatAuthHeaders()
    });

    const data = await res.json().catch(function () { return {}; });
    if (!res.ok || data.ok === false) return null;

    stage5p10fUpdateQueueDisplay(data);
    return data;
  } catch (err) {
    return null;
  }
}

function stage5p10fStopQueueStatusPolling() {
  if (stage5p10fQueuePollTimer) {
    window.clearInterval(stage5p10fQueuePollTimer);
    stage5p10fQueuePollTimer = null;
  }
}

function stage5p10fStartQueueStatusPolling(jobId) {
  stage5p10fLastJobId = String(jobId || "").trim();
  if (!stage5p10fLastJobId) return;

  stage5p10fStopQueueStatusPolling();
  stage5p10fFetchQueueStatus(stage5p10fLastJobId);

  stage5p10fQueuePollTimer = window.setInterval(async function () {
    const data = await stage5p10fFetchQueueStatus(stage5p10fLastJobId);
    const status = String(data && data.job && data.job.status || "").toLowerCase();

    if (["complete", "completed", "failed", "error", "cancelled", "not_found"].includes(status)) {
      stage5p10fStopQueueStatusPolling();
    }
  }, 3000);
}

window.stage5p10fStartQueueStatusPolling = stage5p10fStartQueueStatusPolling;
window.stage5p10fFetchQueueStatus = stage5p10fFetchQueueStatus;
window.stage5p10fStopQueueStatusPolling = stage5p10fStopQueueStatusPolling;
// STAGE_5P10F_COMPANION_QUEUE_POSITION_LOGIC_END

async function queuedChatPollJob(jobId) {
  for (let i = 0; i < 80; i++) {
    queuedChatSetStatus(`Waiting for worker... poll ${i + 1}`);

    const res = await fetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
      credentials: "include",
      cache: "no-store",
      headers: queuedChatAuthHeaders()
    });

    const text = await res.text();
    if (!res.ok) {
      throw new Error(`Status poll HTTP ${res.status}: ${text.slice(0, 180)}`);
    }

    const data = JSON.parse(text);
    const job = data?.job || data;
    const status = String(job?.status || "").toLowerCase();

    // STAGE_15_F_MOCK_QUEUE_STATUS_POLISH_BEGIN
    const requestedModel = String(job?.requested_model || data?.requested_model || "").toLowerCase();
    const modelCallState = String(job?.model_call || data?.model_call || "").toLowerCase();
    const isMockNoModel = requestedModel === "mock/no-model" || modelCallState === "not_started";
    if (isMockNoModel && ["queued", "pending", "waiting", "created"].includes(status)) {
      return {
        reply: "Your message is queued safely. The model worker is not active yet, so no assistant reply has been generated.",
        detail: `job ${jobId} - mock/no-model - waiting for model worker`
      };
    }
    // STAGE_15_F_MOCK_QUEUE_STATUS_POLISH_END

    if (status === "complete" || status === "completed") {
      const result = job?.result_json || job?.result || {};
      const reply = result.reply || result.response || result.text || "Completed, but no reply text was returned.";
      return {
        reply,
        detail: `job ${jobId} · ${result.model || job.requested_model || "model unknown"}`
      };
    }

    if (status === "failed" || status === "error") {
      throw new Error(job?.error_text || `Queued job failed with status ${status}`);
    }

    await new Promise((resolve) => setTimeout(resolve, 3000));
  }

  throw new Error("Queued job did not finish before polling timed out.");
}


// STAGE_5P11I_COMPANION_STUDY_COMMAND_ROUTING_BEGIN
function stage5p11iNormalizeStudyPhrase(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[“”]/g, '"')
    .replace(/[’]/g, "'")
    .replace(/[^a-z0-9+#.\s'-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function stage5p11iLooksLikeStudyCommand(message) {
  const text = stage5p11iNormalizeStudyPhrase(message);
  if (!text) return false;

  // STAGE_5P11Q_COMPANION_REVIEW_STYLE_LOOKS_LIKE_BEGIN
  if (/^(balanced|new|hard|medium|easy)$/.test(text)) return true;
  if (/\b(balanced|new|hard|medium|easy)\b/.test(text) && /\b(mode|style|review|cards?)\b/.test(text)) return true;
  // STAGE_5P11Q_COMPANION_REVIEW_STYLE_LOOKS_LIKE_END

  const exact = new Set([
    "study session start",
    "start study session",
    "start a study session",
    "study session pause",
    "pause study session",
    "study session resume",
    "resume study session",
    "study session stop",
    "stop study session",
    "end study session",
    "end the study session",
    "read answer",
    "read the answer",
    "show answer",
    "show the answer",
    "correct",
    "right",
    "wrong",
    "incorrect",
    "skip",
    "pass",
    "next",
    "next card",
    "next question",
    "continue",
    "continue card",
    "continue cards",
    "go on",
    "move on",
    "list decks",
    "list my decks",
    "show decks",
    "show my decks",
    "what decks do i have",
    "select deck",
    "choose deck",
    "use deck"
  ]);

  if (exact.has(text)) return true;

  const hasStudy = /\bstudy\b/.test(text);
  const hasSession = /\bsession\b/.test(text);
  const hasLifecycle = /\b(start|pause|resume|stop|end|status)\b/.test(text);

  // STAGE_5P11P_COMPANION_DECK_SELECTION_LOOKS_LIKE_BEGIN
  if (/\b(list|show)\b/.test(text) && /\bdecks?\b/.test(text)) return true;
  if (/\b(what|which)\b/.test(text) && /\bdecks?\b/.test(text)) return true;
  if (/\b(select|choose|use|switch to|change to)\b/.test(text) && /\bdecks?\b/.test(text)) return true;
  if (/\bstart\b/.test(text) && /\bdecks?\b/.test(text)) return true;
  if (/\bstart\b/.test(text) && /\b(my\s+)?[a-z0-9+#.'-]+\s+deck\b/.test(text)) return true;
  // STAGE_5P11P_COMPANION_DECK_SELECTION_LOOKS_LIKE_END

  if (hasStudy && hasSession && hasLifecycle) return true;
  if (/\bread\b/.test(text) && /\banswer\b/.test(text)) return true;
  if (/\bshow\b/.test(text) && /\banswer\b/.test(text)) return true;
  if (/\b(mark|answer|that was|it was|i was)\b/.test(text) && /\b(correct|right|wrong|incorrect)\b/.test(text)) return true;

  return false;
}

function stage5p11iSelectedDeckId() {
  try {
    return String(window.localStorage.getItem("stage5p9aSelectedStudyDeckId") || "").trim();
  } catch (err) {
    return "";
  }
}

// STAGE_5P11Q_COMPANION_REVIEW_STYLE_BEGIN
function stage5p11qReviewStyleKey() {
  return "stage5p11qSelectedStudyReviewStyle";
}

function stage5p11qAllowedReviewStyles() {
  return ["balanced", "new", "hard", "medium", "easy"];
}

function stage5p11qReviewStyleLabel(mode) {
  const labels = {
    balanced: "Balanced",
    new: "New",
    hard: "Hard",
    medium: "Medium",
    easy: "Easy"
  };
  return labels[String(mode || "").trim().toLowerCase()] || "";
}

function stage5p11qSelectedReviewStyle() {
  try {
    const value = String(window.localStorage.getItem(stage5p11qReviewStyleKey()) || "").trim().toLowerCase();
    return stage5p11qAllowedReviewStyles().includes(value) ? value : "";
  } catch (err) {
    return "";
  }
}

function stage5p11qSetSelectedReviewStyle(mode) {
  const clean = String(mode || "").trim().toLowerCase();
  if (!stage5p11qAllowedReviewStyles().includes(clean)) return false;
  try {
    window.localStorage.setItem(stage5p11qReviewStyleKey(), clean);
    return true;
  } catch (err) {
    return false;
  }
}

function stage5p11qReviewStyleFromMessage(message) {
  const text = stage5p11iNormalizeStudyPhrase(message);
  if (/\bbalanced\b/.test(text) || /\bmixed\b/.test(text) || /\bnormal\b/.test(text)) return "balanced";
  if (/\bnew\b/.test(text)) return "new";
  if (/\bhard\b/.test(text)) return "hard";
  if (/\bmedium\b/.test(text)) return "medium";
  if (/\beasy\b/.test(text)) return "easy";
  return "";
}

function stage5p11qReviewStylePrompt(deckLabel) {
  const prefix = deckLabel ? "Selected Study deck: " + deckLabel + ".\n\n" : "";
  return prefix
    + "Which review style do you want?\n\n"
    + "Balanced — mix hard/new, medium, and easy cards\n"
    + "New — cards you have not reviewed yet\n"
    + "Hard — cards you are struggling with\n"
    + "Medium — reinforcement cards\n"
    + "Easy — confidence practice\n\n"
    + "Reply with Balanced, New, Hard, Medium, or Easy.";
}

function stage5p11qLooksLikeReviewStyleCommand(message) {
  const text = stage5p11iNormalizeStudyPhrase(message);
  if (/^(balanced|new|hard|medium|easy)$/.test(text)) return true;
  if (/\b(balanced|new|hard|medium|easy)\b/.test(text) && /\b(mode|style|review|cards?)\b/.test(text)) return true;
  if (/\b(use|select|choose|start|review)\b/.test(text) && /\b(balanced|new|hard|medium|easy)\b/.test(text)) return true;
  return false;
}

function stage5p11qRouteCompanionReviewStyleCommand(message) {
  if (!stage5p11qLooksLikeReviewStyleCommand(message)) return { handled: false };

  const mode = stage5p11qReviewStyleFromMessage(message);
  if (!mode) {
    return { handled: true, reply: stage5p11qReviewStylePrompt("") };
  }

  stage5p11qSetSelectedReviewStyle(mode);

  const deckId = stage5p11iSelectedDeckId();
  const label = stage5p11qReviewStyleLabel(mode);

  if (!deckId) {
    return {
      handled: true,
      reply: "Review style selected: " + label + ".\n\nNow choose a Study deck. Say “List my decks” or “Select my math deck.”"
    };
  }

  return {
    handled: true,
    reply: "Review style selected: " + label + ".\n\nSay “Study session start” when you are ready."
  };
}
// STAGE_5P11Q_COMPANION_REVIEW_STYLE_END

// STAGE_5P11P_COMPANION_DECK_SELECTION_BEGIN
function stage5p11pSetSelectedDeckId(deckId) {
  const clean = String(deckId || "").trim();
  if (!clean) return false;

  try {
    window.localStorage.setItem("stage5p9aSelectedStudyDeckId", clean);
    return true;
  } catch (err) {
    return false;
  }
}

function stage5p11pDeckTitle(deck) {
  return String((deck && (deck.title || deck.name || deck.deck_title)) || "").trim();
}

function stage5p11pDeckId(deck) {
  return String((deck && (deck.id || deck.deck_id)) || "").trim();
}

function stage5p11pDeckSearchText(deck) {
  return stage5p11iNormalizeStudyPhrase(stage5p11pDeckTitle(deck));
}

function stage5p11pDecksFromPayload(data) {
  if (!data || typeof data !== "object") return [];

  const candidates = [
    data.decks,
    data.items,
    data.results,
    data.by_deck,
    data.deck_totals
  ];

  for (const value of candidates) {
    if (Array.isArray(value)) return value;
  }

  if (data.totals && Array.isArray(data.totals.deck_totals)) {
    return data.totals.deck_totals;
  }

  return [];
}

async function stage5p11pFetchDecks() {
  const response = await fetch("/api/study/decks", {
    method: "GET",
    credentials: "include",
    cache: "no-store",
    headers: queuedChatAuthHeaders()
  });

  const data = await response.json().catch(function () { return {}; });

  if (!response.ok || data.ok === false) {
    const detail = data.detail || data.message || "Could not list Study decks.";
    throw new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
  }

  return stage5p11pDecksFromPayload(data)
    .filter(function (deck) {
      return stage5p11pDeckId(deck) && stage5p11pDeckTitle(deck);
    });
}

function stage5p11pFormatDeckList(decks) {
  if (!decks.length) {
    return "You do not have any Study decks yet. Create a deck in Study first.";
  }

  const selectedId = stage5p11iSelectedDeckId();

  const lines = decks.slice(0, 12).map(function (deck, index) {
    const id = stage5p11pDeckId(deck);
    const title = stage5p11pDeckTitle(deck);
    const cardCount = Number(deck.card_count || deck.cards_count || deck.total_cards || 0);
    const selected = selectedId && selectedId === id ? " selected" : "";
    return String(index + 1) + ". " + title + " — deck " + id + " · " + cardCount + " cards" + selected;
  });

  let reply = "Your Study decks:\n" + lines.join("\n");
  reply += "\n\nSay “Select deck 2” or “Select my math deck.”";

  return reply;
}

function stage5p11pDeckQueryFromMessage(message) {
  let text = stage5p11iNormalizeStudyPhrase(message);

  text = text
    .replace(/\bplease\b/g, " ")
    .replace(/\bcan you\b/g, " ")
    .replace(/\bcould you\b/g, " ")
    .replace(/\bselect\b/g, " ")
    .replace(/\bchoose\b/g, " ")
    .replace(/\buse\b/g, " ")
    .replace(/\bswitch to\b/g, " ")
    .replace(/\bchange to\b/g, " ")
    .replace(/\bstart\b/g, " ")
    .replace(/\bstudy\b/g, " ")
    .replace(/\bsession\b/g, " ")
    .replace(/\bmy\b/g, " ")
    .replace(/\bthe\b/g, " ")
    .replace(/\bdeck\b/g, " ")
    .replace(/\bdecks\b/g, " ")
    .replace(/\bgo over\b/g, " ")
    .replace(/\bsome\b/g, " ")
    .replace(/\bcards\b/g, " ")
    .replace(/\blets\b/g, " ")
    .replace(/\blet s\b/g, " ")
    .replace(/\bwith\b/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  return text;
}

function stage5p11pFindDeckForMessage(message, decks) {
  const normalized = stage5p11iNormalizeStudyPhrase(message);
  const query = stage5p11pDeckQueryFromMessage(message);

  const byDeckNumber = normalized.match(/\bdeck\s+(\d+)\b/);
  if (byDeckNumber) {
    const raw = byDeckNumber[1];
    const byId = decks.find(function (deck) {
      return stage5p11pDeckId(deck) === raw;
    });

    if (byId) return byId;

    const index = Number(raw) - 1;
    if (Number.isInteger(index) && index >= 0 && index < decks.length) {
      return decks[index];
    }
  }

  const plainNumber = normalized.match(/^(?:select|choose|use)\s+(\d+)$/);
  if (plainNumber) {
    const index = Number(plainNumber[1]) - 1;
    if (Number.isInteger(index) && index >= 0 && index < decks.length) {
      return decks[index];
    }
  }

  if (!query) return null;

  const exact = decks.find(function (deck) {
    return stage5p11pDeckSearchText(deck) === query;
  });
  if (exact) return exact;

  const contains = decks.find(function (deck) {
    const title = stage5p11pDeckSearchText(deck);
    return title && (title.includes(query) || query.includes(title));
  });
  if (contains) return contains;

  const tokens = query.split(/\s+/).filter(Boolean);
  if (tokens.length) {
    return decks.find(function (deck) {
      const title = stage5p11pDeckSearchText(deck);
      return tokens.every(function (token) {
        return title.includes(token);
      });
    }) || null;
  }

  return null;
}

function stage5p11pIsListDecksMessage(message) {
  const text = stage5p11iNormalizeStudyPhrase(message);
  return (/\b(list|show)\b/.test(text) && /\bdecks?\b/.test(text))
    || (/\b(what|which)\b/.test(text) && /\bdecks?\b/.test(text));
}

function stage5p11pIsDeckSelectOrStartMessage(message) {
  const text = stage5p11iNormalizeStudyPhrase(message);
  return (/\b(select|choose|use|switch to|change to)\b/.test(text) && /\bdecks?\b/.test(text))
    || (/\bstart\b/.test(text) && /\bdecks?\b/.test(text))
    || (/\bstart\b/.test(text) && /\b(my\s+)?[a-z0-9+#.'-]+\s+deck\b/.test(text));
}

async function stage5p11pRouteCompanionDeckCommand(message) {
  const decks = await stage5p11pFetchDecks();

  if (stage5p11pIsListDecksMessage(message)) {
    return {
      handled: true,
      reply: stage5p11pFormatDeckList(decks)
    };
  }

  if (!stage5p11pIsDeckSelectOrStartMessage(message)) {
    return {
      handled: false
    };
  }

  const deck = stage5p11pFindDeckForMessage(message, decks);

  if (!deck) {
    return {
      handled: true,
      reply: "I could not find that deck.\n\n" + stage5p11pFormatDeckList(decks)
    };
  }

  const deckId = stage5p11pDeckId(deck);
  const title = stage5p11pDeckTitle(deck);
  stage5p11pSetSelectedDeckId(deckId);

  const normalized = stage5p11iNormalizeStudyPhrase(message);
  const shouldStart = /\bstart\b/.test(normalized) || (/\bgo over\b/.test(normalized) && /\bcards?\b/.test(normalized));

  const explicitReviewMode = stage5p11qReviewStyleFromMessage(message);
  const reviewMode = explicitReviewMode || stage5p11qSelectedReviewStyle();

  if (explicitReviewMode) {
    stage5p11qSetSelectedReviewStyle(explicitReviewMode);
  }

  if (!shouldStart) {
    return {
      handled: true,
      reply: reviewMode
        ? "Selected Study deck: " + title + " — deck " + deckId + ".\n\nReview style selected: " + stage5p11qReviewStyleLabel(reviewMode) + ".\n\nSay “Study session start” when you are ready."
        : stage5p11qReviewStylePrompt(title + " — deck " + deckId)
    };
  }

  if (!reviewMode) {
    return {
      handled: true,
      reply: stage5p11qReviewStylePrompt(title + " — deck " + deckId)
    };
  }

  // STAGE_8L_DISABLED_STUDY_SHADOW_READ_OBSERVATION_CALL_V1
  stage8lObserveRouterShadowReadDisabled({
    text: "study_command_shadow_observation",
    source: "study",
    surface: "study_session",
    activePage: "study",
    profileLanguage: "en",
  });
  const response = await fetch("/api/study/session/command", {
    method: "POST",
    credentials: "include",
    headers: queuedChatAuthHeaders(),
    body: JSON.stringify({
      message: "Study session start",
      deck_id: deckId,
      review_mode: reviewMode
    })
  });

  const data = await response.json().catch(function () { return {}; });

  if (!response.ok || data.ok === false) {
    const detail = data.detail || data.message || "Could not start Study session.";
    throw new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
  }

  return {
    handled: true,
    reply: "Selected Study deck: " + title + " — deck " + deckId + ".\nReview style: " + stage5p11qReviewStyleLabel(reviewMode) + ".\n\n" + stage5p11iAssistantSummary(data)
  };
}
// STAGE_5P11P_COMPANION_DECK_SELECTION_END

function stage5p11iAssistantSummary(data) {
  const session = data && data.session ? data.session : {};
  const status = String(session.status || "").toLowerCase();
  const command = String((data && (data.command || data.intent)) || "").toLowerCase();
  const current = session.current_card || {};
  const question = String(current.question || "").trim();

  if (status === "reviewing_answer" || status === "waiting_for_mark") {
    const answer = String(current.answer || "").trim();
    const explanation = String(current.explanation || "").trim();
    if (answer && explanation) return "Answer revealed: " + answer + "\n\nExplanation: " + explanation + "\n\nMark it Correct, Wrong, or Skip.";
    if (answer) return "Answer revealed: " + answer + "\n\nMark it Correct, Wrong, or Skip.";
    return "Answer revealed. Mark it Correct, Wrong, or Skip.";
  }

  if (status === "active") {
    if (question) return "Study session is active. Current question: " + question;
    return "Study session is active. Continue with Read answer, Correct, Wrong, or Skip.";
  }

  if (status === "completed") return "Study session completed. Nice work.";
  if (status === "paused") return "Study session paused. Say “Study session resume” when you are ready.";
  if (status === "stopped") return "Study session stopped.";

  if (command.includes("skip")) return "Skipped. Moving to the next card.";
  if (command.includes("correct")) return "Marked correct.";
  if (command.includes("incorrect") || command.includes("wrong")) return "Marked wrong.";

  return "Study command handled.";
}

async function stage5p11iRouteCompanionStudyCommand(message) {
  // STAGE_5P11Q_COMPANION_REVIEW_STYLE_ROUTE_HOOK_BEGIN
  const styleRoute = stage5p11qRouteCompanionReviewStyleCommand(message);
  if (styleRoute && styleRoute.handled) {
    return {
      ok: true,
      data: {},
      reply: styleRoute.reply
    };
  }
  // STAGE_5P11Q_COMPANION_REVIEW_STYLE_ROUTE_HOOK_END

  // STAGE_5P11P_COMPANION_DECK_SELECTION_ROUTE_HOOK_BEGIN
  const deckRoute = await stage5p11pRouteCompanionDeckCommand(message);
  if (deckRoute && deckRoute.handled) {
    return {
      ok: true,
      data: {},
      reply: deckRoute.reply
    };
  }
  // STAGE_5P11P_COMPANION_DECK_SELECTION_ROUTE_HOOK_END

  const payload = { message: message };
  const normalized = stage5p11iNormalizeStudyPhrase(message);
  const deckId = stage5p11iSelectedDeckId();

  if (/\bstart\b/.test(normalized) && /\bstudy\b/.test(normalized) && deckId) {
    const reviewMode = stage5p11qSelectedReviewStyle();

    if (!reviewMode) {
      return {
        ok: true,
        data: {},
        reply: stage5p11qReviewStylePrompt("")
      };
    }

    payload.deck_id = deckId;
    payload.review_mode = reviewMode;
  }

  const response = await fetch("/api/study/session/command", {
    method: "POST",
    credentials: "include",
    headers: queuedChatAuthHeaders(),
    body: JSON.stringify(payload)
  });

  const data = await response.json().catch(function () { return {}; });

  if (!response.ok || data.ok === false) {
    const detail = data.detail || data.message || "Study command failed.";
    throw new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
  }

  return {
    ok: true,
    data: data,
    reply: stage5p11iAssistantSummary(data)
  };
}
// STAGE_5P11I_COMPANION_STUDY_COMMAND_ROUTING_END


// STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_BEGIN
function stage5p11jNormalizeAnswer(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[“”]/g, '"')
    .replace(/[’]/g, "'")
    .replace(/\s+/g, " ")
    .replace(/[.。]+$/g, "")
    .trim();
}

function stage5p11jCompactAnswer(value) {
  return stage5p11jNormalizeAnswer(value)
    .replace(/[^a-z0-9+\-*/=().]/g, "");
}

// STAGE_5P11K_DETERMINISTIC_NUMBER_WORD_NORMALIZER_BEGIN
function stage5p11kParseIntegerNumberWords(tokens) {
  const small = {
    zero: 0,
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
    ten: 10,
    eleven: 11,
    twelve: 12,
    thirteen: 13,
    fourteen: 14,
    fifteen: 15,
    sixteen: 16,
    seventeen: 17,
    eighteen: 18,
    nineteen: 19
  };

  const tens = {
    twenty: 20,
    thirty: 30,
    forty: 40,
    fourty: 40,
    fifty: 50,
    sixty: 60,
    seventy: 70,
    eighty: 80,
    ninety: 90
  };

  const scales = {
    thousand: 1000,
    million: 1000000
  };

  let total = 0;
  let current = 0;
  let seen = false;

  for (let i = 0; i < tokens.length; i += 1) {
    const token = tokens[i];

    if (token === "and") {
      continue;
    }

    if (token === "a" || token === "an") {
      const next = tokens[i + 1] || "";
      if (next === "hundred" || Object.prototype.hasOwnProperty.call(scales, next)) {
        current += 1;
        seen = true;
        continue;
      }
      return null;
    }

    if (Object.prototype.hasOwnProperty.call(small, token)) {
      current += small[token];
      seen = true;
      continue;
    }

    if (Object.prototype.hasOwnProperty.call(tens, token)) {
      current += tens[token];
      seen = true;
      continue;
    }

    if (token === "hundred") {
      if (!seen && current === 0) current = 1;
      current *= 100;
      seen = true;
      continue;
    }

    if (Object.prototype.hasOwnProperty.call(scales, token)) {
      if (!seen && current === 0) current = 1;
      total += current * scales[token];
      current = 0;
      seen = true;
      continue;
    }

    return null;
  }

  if (!seen) return null;
  return total + current;
}

function stage5p11kParseNumberWords(value) {
  const digitWords = {
    zero: "0",
    oh: "0",
    one: "1",
    two: "2",
    three: "3",
    four: "4",
    five: "5",
    six: "6",
    seven: "7",
    eight: "8",
    nine: "9"
  };

  let raw = String(value || "")
    .toLowerCase()
    .replace(/[−–—]/g, "-")
    .replace(/-/g, " ")
    .replace(/[^a-z\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (!raw) return null;

  let tokens = raw.split(/\s+/).filter(Boolean);
  let sign = 1;

  if (tokens[0] === "minus" || tokens[0] === "negative") {
    sign = -1;
    tokens = tokens.slice(1);
  }

  if (!tokens.length) return null;

  const pointIndex = tokens.indexOf("point");

  if (pointIndex !== -1) {
    if (tokens.indexOf("point", pointIndex + 1) !== -1) return null;

    const wholeTokens = tokens.slice(0, pointIndex);
    const decimalTokens = tokens.slice(pointIndex + 1);

    if (!decimalTokens.length) return null;

    const whole = wholeTokens.length ? stage5p11kParseIntegerNumberWords(wholeTokens) : 0;
    if (whole === null) return null;

    const digits = [];
    for (const token of decimalTokens) {
      if (!Object.prototype.hasOwnProperty.call(digitWords, token)) return null;
      digits.push(digitWords[token]);
    }

    const parsed = Number(String(whole) + "." + digits.join(""));
    return Number.isFinite(parsed) ? sign * parsed : null;
  }

  const parsedInteger = stage5p11kParseIntegerNumberWords(tokens);
  return parsedInteger === null ? null : sign * parsedInteger;
}

function stage5p11jParseNumericAnswer(value) {
  const raw = stage5p11jNormalizeAnswer(value)
    .replace(/,/g, "")
    .replace(/−/g, "-");

  const wordNumber = stage5p11kParseNumberWords(raw);
  if (wordNumber !== null && Number.isFinite(wordNumber)) return wordNumber;

  if (/^[+-]?\d+(?:\.\d+)?\s*\/\s*[+-]?\d+(?:\.\d+)?$/.test(raw)) {
    const parts = raw.split("/");
    const a = Number(parts[0].trim());
    const b = Number(parts[1].trim());
    if (Number.isFinite(a) && Number.isFinite(b) && b !== 0) return a / b;
  }

  if (/^[+-]?\d+(?:\.\d+)?$/.test(raw)) {
    const n = Number(raw);
    if (Number.isFinite(n)) return n;
  }

  return null;
}
// STAGE_5P11K_DETERMINISTIC_NUMBER_WORD_NORMALIZER_END


function stage5p11jCompareAnswer(userAnswer, correctAnswer) {
  const user = stage5p11jNormalizeAnswer(userAnswer);
  const expected = stage5p11jNormalizeAnswer(correctAnswer);

  if (!user || !expected) return "uncertain";

  if (user === expected) return "correct";
  if (stage5p11jCompactAnswer(user) === stage5p11jCompactAnswer(expected)) return "correct";

  const userNumber = stage5p11jParseNumericAnswer(user);
  const expectedNumber = stage5p11jParseNumericAnswer(expected);

  if (userNumber !== null && expectedNumber !== null) {
    return Math.abs(userNumber - expectedNumber) < 1e-9 ? "correct" : "wrong";
  }

  return "uncertain";
}

function stage5p11jLooksLikeAnswerAttempt(message) {
  const text = String(message || "").trim();
  const normalized = stage5p11iNormalizeStudyPhrase(text);

  if (!normalized) return false;
  if (normalized.length > 240) return false;
  if (/[?？]\s*$/.test(text)) return false;

  if (/^(what|why|how|explain|tell me|can you|could you|please explain)\b/.test(normalized)) {
    return false;
  }

  return true;
}

async function stage5p11jFetchStudyStatus() {
  const response = await fetch("/api/study/session/status", {
    method: "GET",
    credentials: "include",
    cache: "no-store",
    headers: queuedChatAuthHeaders()
  });

  const data = await response.json().catch(function () { return {}; });

  if (!response.ok || data.ok === false) {
    return null;
  }

  return data.session || null;
}

async function stage5p11jSendStudyCommand(message) {
  const response = await fetch("/api/study/session/command", {
    method: "POST",
    credentials: "include",
    headers: queuedChatAuthHeaders(),
    body: JSON.stringify({ message: message })
  });

  const data = await response.json().catch(function () { return {}; });

  if (!response.ok || data.ok === false) {
    const detail = data.detail || data.message || "Study command failed.";
    throw new Error(typeof detail === "string" ? detail : JSON.stringify(detail));
  }

  return data;
}

function stage5p11jNextQuestionSummary(data, prefix) {
  const session = data && data.session ? data.session : {};
  const status = String(session.status || "").toLowerCase();
  const current = session.current_card || {};
  const question = String(current.question || "").trim();

  if (status === "completed") {
    return prefix + " Session complete. Nice work.";
  }

  if (question) {
    return prefix + " Next question: " + question;
  }

  return prefix;
}

async function stage5p11jRouteCompanionStudyAnswer(message) {
  if (!stage5p11jLooksLikeAnswerAttempt(message)) {
    return { handled: false };
  }

  const session = await stage5p11jFetchStudyStatus();
  if (!session) return { handled: false };

  const status = String(session.status || "").toLowerCase();
  if (status !== "active") return { handled: false };

  const current = session.current_card || {};
  const expectedAnswer = String(current.answer || "").trim();

  if (!expectedAnswer) return { handled: false };

  const verdict = stage5p11jCompareAnswer(message, expectedAnswer);

  if (verdict === "correct") {
    const data = await stage5p11jSendStudyCommand("Correct");
    return {
      handled: true,
      reply: stage5p11jNextQuestionSummary(data, "Correct.")
    };
  }

  if (verdict === "wrong") {
    const data = await stage5p11jSendStudyCommand("Wrong");
    return {
      handled: true,
      reply: stage5p11jNextQuestionSummary(data, "Marked wrong. Correct answer was: " + expectedAnswer + ".")
    };
  }

  return {
    handled: true,
    reply: "I am not certain whether that matches the answer. Your answer was: " + String(message || "").trim() + ". Expected answer: " + expectedAnswer + ". Say Correct, Wrong, or Skip."
  };
}
// STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_END

async function queuedChatSubmit(event) {
  event.preventDefault();

  if (queuedChatUiState.busy) return;

  const input = document.getElementById("queuedChatInput");
  const button = document.getElementById("queuedChatSendBtn");
  const message = String(input?.value || "").trim();

  if (!message) {
    queuedChatSetStatus("Enter a message first.");
    return;
  }

  // STAGE_5P11I_COMPANION_STUDY_COMMAND_ROUTING_SUBMIT_HOOK_BEGIN
  if (stage5p11iLooksLikeStudyCommand(message)) {
    queuedChatUiState.messages.push({ role: "You", content: message });
    queuedChatRenderMessages();

    if (input) input.value = "";
    queuedChatUiState.busy = true;
    if (button) button.disabled = true;
    queuedChatSetStatus("Handling Study command...");

    try {
      const routed = await stage5p11iRouteCompanionStudyCommand(message);
      queuedChatUiState.messages.push({
        role: "Assistant",
        content: routed.reply,
        detail: "Study session command"
      });
      queuedChatSetStatus("Study command complete");
    } catch (err) {
      queuedChatUiState.messages.push({
        role: "Error",
        content: "I could not complete that Study command.",
        detail: err && err.message ? err.message : String(err)
      });
      queuedChatSetStatus("Study command failed");
    } finally {
      queuedChatUiState.busy = false;
      if (button) button.disabled = false;
      queuedChatRenderMessages();
    }

    return;
  }
  // STAGE_5P11I_COMPANION_STUDY_COMMAND_ROUTING_SUBMIT_HOOK_END


  // STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_SUBMIT_HOOK_BEGIN
  if (stage5p11jLooksLikeAnswerAttempt(message)) {
    queuedChatSetStatus("Checking Study answer...");

    try {
      const answerAttempt = await stage5p11jRouteCompanionStudyAnswer(message);

      if (answerAttempt && answerAttempt.handled) {
        queuedChatUiState.messages.push({ role: "You", content: message });
        queuedChatRenderMessages();

        if (input) input.value = "";
        queuedChatUiState.busy = true;
        if (button) button.disabled = true;

        queuedChatUiState.messages.push({
          role: "Assistant",
          content: answerAttempt.reply,
          detail: "Study answer check"
        });

        queuedChatSetStatus("Study answer checked");
        queuedChatUiState.busy = false;
        if (button) button.disabled = false;
        queuedChatRenderMessages();
        return;
      }
    } catch (err) {
      queuedChatUiState.messages.push({ role: "You", content: message });
      queuedChatUiState.messages.push({
        role: "Error",
        content: "I could not check that Study answer.",
        detail: err && err.message ? err.message : String(err)
      });
      if (input) input.value = "";
      queuedChatSetStatus("Study answer check failed");
      queuedChatRenderMessages();
      return;
    }

    queuedChatSetStatus("Ready");
  }
  // STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_SUBMIT_HOOK_END

  queuedChatUiState.busy = true;
  if (button) button.disabled = true;

  queuedChatUiState.messages.push({ role: "You", content: message });
  queuedChatRenderMessages();

  if (input) input.value = "";

  try {
    queuedChatSetStatus("Creating queued job...");

    const res = await fetch("/api/chat/queued", {
      method: "POST",
      credentials: "include",
      headers: queuedChatAuthHeaders(),
      body: JSON.stringify({
        message,
        requested_model: "gemma4:e4b",
        // STAGE_5P10E_COMPANION_OMIT_CLIENT_CHAT_ID_BEGIN
        // Let the server create an owned chat for the authenticated user.
        // Sending a new client chat_id fails ownership validation.
        // STAGE_5P10E_COMPANION_OMIT_CLIENT_CHAT_ID_END
        mode: "chat"
      })
    });

    const text = await res.text();
    if (!res.ok) {
      throw new Error(`Create job HTTP ${res.status}: ${text.slice(0, 180)}`);
    }

    const data = JSON.parse(text);
    const jobId = data.job_id || data?.job?.job_id;

    if (!jobId) {
      throw new Error("Queued job response did not include a job_id.");
    }

    queuedChatUiState.lastJobId = jobId;
    // APC_COMPANION_SUBMIT_RESULT_READER_BRIDGE_FC_O45_E_AD_E_R2 BEGIN
    if (typeof window.apcCompanionResultReaderSetJobId === "function") {
      window.apcCompanionResultReaderSetJobId(jobId, {
        source: "queuedChatSubmit",
        autoRead: false
      });
    }
    // APC_COMPANION_SUBMIT_RESULT_READER_BRIDGE_FC_O45_E_AD_E_R2 END
    queuedChatUiState.messages.push({
      role: "Queue",
      content: "Job created",
      detail: jobId
    });
    queuedChatRenderMessages();

    // STAGE_5P10F_COMPANION_QUEUE_POSITION_SUBMIT_HOOK_BEGIN
    if (typeof stage5p10fStartQueueStatusPolling === "function") {
      stage5p10fStartQueueStatusPolling(jobId);
    }
    // STAGE_5P10F_COMPANION_QUEUE_POSITION_SUBMIT_HOOK_END

    const final = await queuedChatPollJob(jobId);

    queuedChatUiState.messages.push({
      role: "Assistant",
      content: final.reply,
      detail: final.detail
    });
    queuedChatSetStatus("Complete");
    if (typeof stage5p10fFetchQueueStatus === "function") {
      stage5p10fFetchQueueStatus(jobId);
    }
    queuedChatRenderMessages();
  } catch (err) {
    queuedChatUiState.messages.push({
      role: "Error",
      content: err.message || String(err)
    });
    queuedChatSetStatus("Error");
    queuedChatRenderMessages();
  } finally {
    queuedChatUiState.busy = false;
    if (button) button.disabled = false;
  }
}

function bindQueuedChatPage() {
  queuedChatRenderMessages();

  const form = document.getElementById("queuedChatForm");
  if (form) {
    form.onsubmit = queuedChatSubmit;
  }

  const clearBtn = document.getElementById("queuedChatClearBtn");
  if (clearBtn) {
    clearBtn.onclick = () => {
      queuedChatUiState.messages = [];
      queuedChatSetStatus("Ready");
      queuedChatRenderMessages();
    };
  }
}



// ============================================================
// STAGE_5O25_PUBLIC_FEATURE_GATE_V1
// Logged-out users see a public feature summary first.
// Logged-in users see the usable application surface.
// ============================================================


// ============================================================
// STAGE_5O32_AUTH_READY_HELPERS_V1
// Profile and other gated pages must re-render after /me confirms
// the session. Avoid trapping logged-in users on public summaries.
// ============================================================

function normalizeWrapperAuthRoute(path) {
  const raw = String(path || "/").split("?")[0].split("#")[0] || "/";
  const cleaned = raw.replace(/\/+/g, "/").replace(/\/$/, "") || "/";
  return cleaned === "" ? "/" : cleaned;
}

function isWrapperAuthReady() {
  try {
    return Boolean(authState && authState.token && authState.user);
  } catch {
    return false;
  }
}

function rerenderCurrentRouteAfterAuthReady() {
  try {
    if (!isWrapperAuthReady()) return;
    const path = normalizeWrapperAuthRoute(window.location.pathname || "/");
    if (
      path === "/study" ||
      path === "/chat" ||
      path === "/companion" ||
      path === "/profile" ||
      path === "/support" ||
      path === "/calendar" ||
      path === "/credits"
    ) {
      renderPage();
    }
  } catch (err) {
    console.warn("auth-ready rerender skipped", err);
  }
}

function hasActiveWrapperSession() {
  // STAGE_5O32_PROFILE_AFTER_LOGIN_GATE_V1
  // Logged-in means /me has confirmed the user for this page session.
  return isWrapperAuthReady();
}

const PUBLIC_FEATURE_SUMMARIES = {
  "/study": {
    eyebrow: "Study",
    title: "Study smarter with decks, cards, and adaptive review.",
    body: "Build decks, add cards, review by difficulty, and track progress over time. Once signed in, this page becomes your personal study dashboard.",
    points: [
      ["Decks", "Organize topics into reusable decks."],
      ["Cards", "Add questions, answers, explanations, difficulty, and tags."],
      ["Progress", "Track reviews, accuracy, confidence, and weak spots."]
    ]
  },
  "/companion": {
    eyebrow: "Companion",
    title: "A queued local AI companion for study and support.",
    body: "Send messages through the local queued AI path so the website stays responsive while your worker processes the response.",
    points: [
      ["Queued responses", "Messages are submitted as jobs and polled until complete."],
      ["Study context", "Future companion features can use allowed study context."],
      ["Local-first", "Designed around your local server and worker queue."]
    ]
  },
  "/profile": {
    eyebrow: "Profile",
    title: "Manage your account, preferences, and permissions.",
    body: "Profile explains how account settings, privacy controls, permissions, and personalization will work after you sign in.",
    points: [
      ["Account", "View identity, plan, and login state."],
      ["Permissions", "Control what tools and companion features can access."],
      ["Personalization", "Store preferences that improve the experience."]
    ]
  },
  "/credits": {
    eyebrow: "Credits",
    title: "Credits power higher-cost AI features.",
    body: "Credits track usage for higher-cost features such as local AI jobs, image generation, storage, and future paid resources.",
    points: [
      ["Free/local credits", "For local services running on your hardware."],
      ["Paid credits", "For future paid resources such as external GPUs or cloud services."],
      ["History", "Credit changes and reservations stay auditable."]
    ]
  },
  "/calendar": {
    eyebrow: "Calendar",
    title: "Google Calendar and Apple Calendar integrations.",
    body: "The platform will not store its own separate calendar. Future calendar features should connect to Google Calendar or Apple Calendar with permission.",
    points: [
      ["Google Calendar", "Future provider-backed scheduling and event context."],
      ["Apple Calendar", "Future provider-backed scheduling and reminders."],
      ["No local calendar store", "Calendar data should stay with the provider."]
    ]
  }
};

function renderPublicFeatureGate(route) {
  // STAGE_5O33_PUBLIC_GATE_BROWSER_ROUTE_FIX_V1
  try {
    const browserRoute = normalizeWrapperAuthRoute(window.location.pathname || route || "/");
    if (PUBLIC_FEATURE_SUMMARIES[browserRoute]) {
      route = browserRoute;
    }
  } catch {
    // Keep provided route.
  }

  // STAGE_5O27B_NONBLANK_PUBLIC_GATE_RENDERER_V1
  // Self-contained renderer: do not depend on helper functions that might not
  // be initialized yet. Public logged-out pages must never render blank.
  const app = document.getElementById("app");
  if (!app) return;

  const safe = (value) => String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

  const summary = PUBLIC_FEATURE_SUMMARIES[route] || {
    eyebrow: "Platform",
    title: "Sign in to use this feature.",
    body: "This page is available after login.",
    points: []
  };

  const pointsHtml = (summary.points || []).map((point) => {
    const label = Array.isArray(point) ? point[0] : "";
    const text = Array.isArray(point) ? point[1] : "";
    return `
      <div class="summary-card public-feature-card">
        <span>${safe(label)}</span>
        <p>${safe(text)}</p>
      </div>
    `;
  }).join("");

  app.innerHTML = `
    <section class="system-section public-feature-gate">
      <div class="summary-box">
        <span>${safe(summary.eyebrow)}</span>
        <strong>${safe(summary.title)}</strong>
        <p>${safe(summary.body)}</p>
        <p class="public-feature-note">Sign in from the header when you are ready to use this feature.</p>
      </div>
      <div class="summary-grid">
        ${pointsHtml}
      </div>
    </section>
  `;
}


// ============================================================
// STAGE_5O33_LOGGED_IN_PROFILE_PAGE_V1
// Real logged-in Profile surface instead of generic feature summary.
// ============================================================

// PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1
// Read-only display of backend-owned profile preferences.
// This phase does not save preferences and does not activate browser voice,
// calendar provider auth, tools, model calls, jobs, or workers.
function normalizeProfilePreferenceValue(value) {
  if (value === true) return "Enabled";
  if (value === false) return "Disabled";
  if (value === null || value === undefined || value === "") return "—";
  return String(value)
    .replaceAll("_", " ")
    .replace(/\b\w/g, (match) => match.toUpperCase());
}

function renderProfilePreferenceRows(preferences) {
  const safe = (value) => String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

  const prefs = preferences || {};
  const rows = [
    ["Preferred language", prefs.preferred_language],
    ["Study language", prefs.study_language],
    ["Learning style", prefs.learning_style],
    ["Explanation depth", prefs.study_explanation_depth],
    ["Answer strictness", prefs.study_answer_strictness],
    ["Companion behavior", prefs.companion_behavior],
    ["Companion tone", prefs.companion_tone],
    ["Voice", prefs.voice_enabled],
    ["Listen", prefs.listen_enabled],
    ["Speak", prefs.speak_enabled],
    ["Calendar provider", prefs.calendar_provider_preference],
    ["Notifications", prefs.notification_preference],
  ];

  return `
    <div class="profile-preference-list" data-phase14a-profile-preferences-list="true">
      ${rows.map(([label, value]) => `
        <div class="profile-preference-row">
          <span>${safe(label)}</span>
          <strong>${safe(normalizeProfilePreferenceValue(value))}</strong>
        </div>
      `).join("")}
    </div>
  `;
}

function renderProfilePreferencesCard() {
  const safe = (value) => String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

  if (profilePreferencesLoading) {
    return `
      <div class="summary-card profile-preferences-card" data-phase14a-profile-preferences-card="loading">
        <span>Preferences</span>
        <strong>Loading preferences</strong>
        <p>Reading your backend-owned profile preferences.</p>
      </div>
    `;
  }

  if (profilePreferencesError) {
    return `
      <div class="summary-card profile-preferences-card" data-phase14a-profile-preferences-card="error">
        <span>Preferences</span>
        <strong>Unavailable</strong>
        <p>${safe(profilePreferencesError)}</p>
        <p>Typed input remains available. No voice, calendar, model, job, or worker action was triggered.</p>
      </div>
    `;
  }

  const prefs = profilePreferences?.preferences || null;

  if (!prefs) {
    return `
      <div class="summary-card profile-preferences-card" data-phase14a-profile-preferences-card="empty">
        <span>Preferences</span>
        <strong>Not loaded yet</strong>
        <p>Profile preferences will appear here after the backend route is available.</p>
      </div>
    `;
  }

  return `
    <div class="summary-card profile-preferences-card" data-phase14a-profile-preferences-card="ready">
      <span>Preferences</span>
      <strong>Editable preferences</strong>
      <p>These values are read from /api/profile/preferences. Save only updates backend-owned profile preferences.</p>
      ${renderProfilePreferenceRows(prefs)}
      ${renderProfilePreferencesForm(prefs)}
    </div>
  `;
}

async function loadProfilePreferencesForProfilePage({ force = false } = {}) {
  if (!authState.token) {
    profilePreferences = null;
    profilePreferencesError = "";
    profilePreferencesLoading = false;
    return null;
  }

  if (profilePreferences && !force) return profilePreferences;
  if (profilePreferencesError && !force) return null;
  if (profilePreferencesLoading) return profilePreferences;

  profilePreferencesLoading = true;
  profilePreferencesError = "";

  try {
    const result = await api("/profile/preferences", { method: "GET" });
    profilePreferences = result;
    profilePreferencesError = "";
    return result;
  } catch (err) {
    profilePreferencesError = sanitizeVisibleErrorText(err?.message || "Profile preferences are not available yet.");
    return null;
  } finally {
    profilePreferencesLoading = false;
    if (normalizeWrapperAuthRoute(window.location.pathname || "/") === "/profile") {
      renderPage();
    }
  }
}

// PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1
// Editable profile preference controls. This phase only writes allowed
// profile preference fields through the backend-owned PATCH endpoint.
// It does not activate microphone capture, speech output, calendar auth,
// model calls, jobs, workers, or tools.
function profilePreferenceSafe(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function renderProfilePreferenceSelect(name, label, value, options) {
  const safeName = profilePreferenceSafe(name);
  const safeLabel = profilePreferenceSafe(label);
  const current = String(value ?? "");

  return `
    <label class="profile-preference-control">
      <span>${safeLabel}</span>
      <select name="${safeName}" data-profile-preference-field="${safeName}">
        ${options.map((option) => {
          const optionValue = String(option[0] ?? "");
          const optionLabel = String(option[1] ?? optionValue);
          const selected = optionValue === current ? " selected" : "";
          return `<option value="${profilePreferenceSafe(optionValue)}"${selected}>${profilePreferenceSafe(optionLabel)}</option>`;
        }).join("")}
      </select>
    </label>
  `;
}

function renderProfilePreferenceToggle(name, label, value, detail) {
  const safeName = profilePreferenceSafe(name);
  const checked = Boolean(value) ? " checked" : "";

  return `
    <label class="profile-preference-toggle">
      <input type="checkbox" name="${safeName}" data-profile-preference-field="${safeName}"${checked} />
      <span>
        <strong>${profilePreferenceSafe(label)}</strong>
        <small>${profilePreferenceSafe(detail)}</small>
      </span>
    </label>
  `;
}

function renderProfilePreferencesForm(preferences) {
  const prefs = preferences || {};
  const message = profilePreferencesSaveMessage
    ? `<p class="profile-preference-save-message">${profilePreferenceSafe(profilePreferencesSaveMessage)}</p>`
    : "";

  return `
    <form class="profile-preference-form" data-phase14f-profile-preferences-form="true">
      <div class="profile-preference-control-grid">
        ${renderProfilePreferenceSelect("preferred_language", "Preferred language", prefs.preferred_language, [
          ["en", "English"],
          ["es", "Spanish"],
          ["fr", "French"],
          ["de", "German"],
          ["it", "Italian"],
          ["pt", "Portuguese"],
          ["ja", "Japanese"],
          ["ko", "Korean"],
          ["zh", "Chinese"],
        ])}

        ${renderProfilePreferenceSelect("study_language", "Study language", prefs.study_language, [
          ["en", "English"],
          ["es", "Spanish"],
          ["fr", "French"],
          ["de", "German"],
          ["it", "Italian"],
          ["pt", "Portuguese"],
          ["ja", "Japanese"],
          ["ko", "Korean"],
          ["zh", "Chinese"],
        ])}

        ${renderProfilePreferenceSelect("learning_style", "Learning style", prefs.learning_style, [
          ["balanced", "Balanced"],
          ["visual", "Visual"],
          ["step_by_step", "Step by step"],
          ["concise", "Concise"],
          ["detailed", "Detailed"],
        ])}

        ${renderProfilePreferenceSelect("study_explanation_depth", "Explanation depth", prefs.study_explanation_depth, [
          ["brief", "Brief"],
          ["normal", "Normal"],
          ["deep", "Deep"],
        ])}

        ${renderProfilePreferenceSelect("study_answer_strictness", "Answer strictness", prefs.study_answer_strictness, [
          ["lenient", "Lenient"],
          ["balanced", "Balanced"],
          ["strict", "Strict"],
        ])}

        ${renderProfilePreferenceSelect("study_session_default_mode", "Study mode", prefs.study_session_default_mode, [
          ["standard_review", "Standard review"],
          ["immersive_review", "Immersive review"],
        ])}

        ${renderProfilePreferenceSelect("companion_behavior", "Companion behavior", prefs.companion_behavior, [
          ["supportive_tutor", "Supportive tutor"],
          ["direct_helper", "Direct helper"],
          ["study_coach", "Study coach"],
        ])}

        ${renderProfilePreferenceSelect("companion_tone", "Companion tone", prefs.companion_tone, [
          ["calm_clear", "Calm and clear"],
          ["encouraging", "Encouraging"],
          ["concise", "Concise"],
        ])}

        ${renderProfilePreferenceSelect("companion_memory_scope", "Companion memory scope", prefs.companion_memory_scope, [
          ["session_only", "Session only"],
          ["session_and_profile_approved", "Session and profile approved"],
        ])}

        ${renderProfilePreferenceSelect("calendar_provider_preference", "Calendar provider", prefs.calendar_provider_preference, [
          ["none", "None"],
          ["google_calendar", "Google Calendar"],
          ["apple_calendar", "Apple Calendar"],
        ])}

        ${renderProfilePreferenceSelect("notification_preference", "Notifications", prefs.notification_preference, [
          ["none", "None"],
          ["email", "Email"],
          ["in_app", "In app"],
        ])}
      </div>

      <div class="profile-preference-toggle-grid">
        ${renderProfilePreferenceToggle("voice_enabled", "Voice preference", prefs.voice_enabled, "Stores preference only. Does not activate microphone or speakers.")}
        ${renderProfilePreferenceToggle("listen_enabled", "Listen preference", prefs.listen_enabled, "Stores preference only. Listening still requires an explicit future action.")}
        ${renderProfilePreferenceToggle("speak_enabled", "Speak preference", prefs.speak_enabled, "Stores preference only. Speaking still requires an explicit future action.")}
        ${renderProfilePreferenceToggle("auto_listen_enabled", "Auto-listen preference", prefs.auto_listen_enabled, "Stored as off by default. No background listening is activated.")}
        ${renderProfilePreferenceToggle("auto_speak_enabled", "Auto-speak preference", prefs.auto_speak_enabled, "Stored as off by default. No automatic speech is activated.")}
        ${renderProfilePreferenceToggle("accessibility_large_text", "Large text", prefs.accessibility_large_text, "Stores a future display preference.")}
        ${renderProfilePreferenceToggle("accessibility_reduce_motion", "Reduce motion", prefs.accessibility_reduce_motion, "Stores a future accessibility preference.")}
      </div>

      <div class="profile-preference-actions">
        <button class="primary-btn" type="submit" data-profile-preferences-save="true"${profilePreferencesSaving ? " disabled" : ""}>
          ${profilePreferencesSaving ? "Saving..." : "Save preferences"}
        </button>
        <button class="ghost-btn" type="button" data-profile-preferences-refresh="true"${profilePreferencesSaving ? " disabled" : ""}>
          Refresh
        </button>
      </div>

      ${message}
    </form>
  `;
}

function collectProfilePreferencesFormPatch() {
  const form = document.querySelector('[data-phase14f-profile-preferences-form="true"]');
  if (!form) return {};

  const current = profilePreferences?.preferences || {};
  const fields = [
    "preferred_language",
    "study_language",
    "learning_style",
    "study_explanation_depth",
    "study_answer_strictness",
    "study_session_default_mode",
    "companion_behavior",
    "companion_tone",
    "companion_memory_scope",
    "calendar_provider_preference",
    "notification_preference",
    "voice_enabled",
    "listen_enabled",
    "speak_enabled",
    "auto_listen_enabled",
    "auto_speak_enabled",
    "accessibility_large_text",
    "accessibility_reduce_motion",
  ];

  const patch = {};

  fields.forEach((field) => {
    const input = form.querySelector(`[name="${field}"]`);
    if (!input) return;

    const nextValue = input.type === "checkbox" ? Boolean(input.checked) : String(input.value || "");
    const currentValue = input.type === "checkbox" ? Boolean(current[field]) : String(current[field] ?? "");

    if (nextValue !== currentValue) {
      patch[field] = nextValue;
    }
  });

  return patch;
}

async function saveProfilePreferencesFromProfilePage(event) {
  if (event) event.preventDefault();

  if (!authState.token) {
    openAuthModal("login");
    return;
  }

  const patch = collectProfilePreferencesFormPatch();

  if (!Object.keys(patch).length) {
    profilePreferencesSaveMessage = "No preference changes to save.";
    renderPage();
    return;
  }

  profilePreferencesSaving = true;
  profilePreferencesSaveMessage = "Saving preferences...";
  renderPage();

  try {
    const result = await api("/profile/preferences", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(patch),
    });

    profilePreferences = result;
    profilePreferencesError = "";
    profilePreferencesSaveMessage = "Preferences saved.";
  } catch (err) {
    profilePreferencesSaveMessage = sanitizeVisibleErrorText(err?.message || "Could not save preferences.");
  } finally {
    profilePreferencesSaving = false;
    if (normalizeWrapperAuthRoute(window.location.pathname || "/") === "/profile") {
      renderPage();
    }
  }
}

function bindProfilePreferencesControls() {
  const form = document.querySelector('[data-phase14f-profile-preferences-form="true"]');
  if (form) {
    form.addEventListener("submit", saveProfilePreferencesFromProfilePage);
  }

  const refreshBtn = document.querySelector('[data-profile-preferences-refresh="true"]');
  if (refreshBtn) {
    refreshBtn.addEventListener("click", () => {
      profilePreferencesError = "";
      profilePreferencesSaveMessage = "";
      loadProfilePreferencesForProfilePage({ force: true });
    });
  }
}

function renderLoggedInProfilePage() {
  const safe = (value) => String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

  const user = authState?.user || {};
  const email = user.email || "Signed-in user";
  const role = user.role || (user.is_admin ? "admin" : "user");
  const plan = user.plan || "free";
  const status = user.status || "active";
  const billing = user.billing_status || "not configured";

  const freeCredits = user.free_credit_balance ?? user.free_credits ?? user.credit_balance ?? accountCredits?.free_balance ?? "—";
  const paidCredits = user.paid_credit_balance ?? user.paid_credits ?? accountCredits?.paid_balance ?? "—";
  const storageQuota = user.storage_quota_mb ?? accountCredits?.storage_quota_mb ?? "—";

  return `
    <section class="system-section profile-page">
      <div class="summary-box profile-hero">
        <span>Profile</span>
        <strong>Account and personalization</strong>
        <p>
          Manage identity, plan details, permissions, preferences, and future
          personalization settings for the platform.
        </p>
      </div>

      <div class="summary-grid profile-grid">
        <div class="summary-card">
          <span>Account</span>
          <strong>${safe(email)}</strong>
          <p>Status: ${safe(status)}</p>
          <p>Role: ${safe(role)}</p>
        </div>

        <div class="summary-card">
          <span>Plan</span>
          <strong>${safe(plan)}</strong>
          <p>Billing status: ${safe(billing)}</p>
          <p>Storage quota: ${safe(storageQuota)} MB</p>
        </div>

        <div class="summary-card">
          <span>Credits</span>
          <strong>${safe(user.credit_balance ?? accountCredits?.total_available ?? "—")}</strong>
          <p>Free/local: ${safe(freeCredits)}</p>
          <p>Paid: ${safe(paidCredits)}</p>
        </div>

        <div class="summary-card">
          <span>Security boundary</span>
          <strong>Private by design</strong>
          <p>Server credentials, infrastructure secrets, and internal keys stay out of the browser.</p>
        </div>
      </div>

      <div class="summary-grid profile-grid">
        <div class="summary-card">
          <span>Permissions</span>
          <strong>Coming next</strong>
          <p>Choose what Study, Companion, Calendar providers, and future tools may use as context.</p>
        </div>

        ${renderProfilePreferencesCard()}

        <div class="summary-card">
          <span>Connected providers</span>
          <strong>Google / Apple later</strong>
          <p>Calendar connections will be provider-backed only. No local calendar database is planned.</p>
        </div>
      </div>
    </section>
  `;
}


/*
 * APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J
 *
 * Real /study must not mount the old Study wrapper preview mini-app. That
 * legacy preview includes its own banner/nav shell, causing two Study pages on
 * one page. Keep the old preview available only at /study-wrapper-preview.
 */

/*
 * APC_STUDY_SINGLE_OWNER_FC_O45_C_L
 *
 * /study is a single-owner surface:
 * - signed-out users get exactly one public Study page;
 * - signed-in users get the durable Study session/deck selector plus one Study tools panel;
 * - the early emergency tools injector is kept from rendering visible duplicate tools.
 */
window.__apcStudySingleOwnerDisableEarlyToolsFcO45CL = true;

function apcStudySingleOwnerIsStudyRouteFcO45CL() {
  try {
    const path = window.location.pathname || "/";
    const hash = window.location.hash || "";
    return path === "/study" || path.endsWith("/study") || hash.includes("study");
  } catch (_) {
    return false;
  }
}

function apcStudySingleOwnerHasSessionFcO45CL() {
  try {
    if (typeof hasActiveWrapperSession === "function" && hasActiveWrapperSession()) return true;
  } catch (_) {}
  try {
    if (window.authState && (window.authState.token || window.authState.user)) return true;
  } catch (_) {}
  try {
    if (window.localStorage && (localStorage.getItem("edgeStudyToken") || localStorage.getItem("edgeAuthToken"))) return true;
  } catch (_) {}
  return false;
}

function apcStudySingleOwnerStudyToolPanelsFcO45CL() {
  const panels = new Set();

  [
    "#apcStudyEarlyToolsPanel",
    "#apcStudyToolsPanel",
    "#apcStudyEarlyToolsScratchFcO45CL",
    "[data-apc-study-tools-panel]",
    "[data-apc-study-tools-auth-cleanup]"
  ].forEach((selector) => {
    try {
      document.querySelectorAll(selector).forEach((node) => panels.add(node));
    } catch (_) {}
  });

  try {
    document.querySelectorAll("h2").forEach((heading) => {
      if ((heading.textContent || "").trim() !== "Study tools") return;
      const panel = heading.closest("section, article, .card, div") || heading.parentElement;
      if (panel) panels.add(panel);
    });
  } catch (_) {}

  return Array.from(panels).filter((panel) => panel && panel.isConnected);
}

function apcStudySingleOwnerCleanupFcO45CL() {
  if (!apcStudySingleOwnerIsStudyRouteFcO45CL()) return;

  const panels = apcStudySingleOwnerStudyToolPanelsFcO45CL();
  const signedIn = apcStudySingleOwnerHasSessionFcO45CL();

  if (!signedIn) {
    panels.forEach((panel) => panel.remove());
  } else if (panels.length > 1) {
    const visiblePanels = panels.filter((panel) => panel.id !== "apcStudyEarlyToolsScratchFcO45CL");
    const keep = visiblePanels.find((panel) => panel.id === "apcStudyFullWorkspacePanelFcO45CNR2")
      || visiblePanels[visiblePanels.length - 1]
      || panels[panels.length - 1];
    panels.forEach((panel) => {
      if (panel !== keep) panel.remove();
    });
    if (keep) {
      keep.setAttribute("data-apc-study-single-owner", "APC_STUDY_SINGLE_OWNER_FC_O45_C_L");
    }
  } else if (panels.length === 1) {
    panels[0].setAttribute("data-apc-study-single-owner", "APC_STUDY_SINGLE_OWNER_FC_O45_C_L");
  }

  try {
    document.querySelectorAll("#apcStudyEarlyToolsScratchFcO45CL").forEach((node) => node.remove());
  } catch (_) {}
}

function apcStudySingleOwnerScheduleCleanupFcO45CL() {
  [0, 50, 200, 750, 1500].forEach((delay) => {
    window.setTimeout(() => {
      try {
        apcStudySingleOwnerCleanupFcO45CL();
      } catch (error) {
        console.warn("[APC_STUDY_SINGLE_OWNER_FC_O45_C_L] cleanup skipped", error);
      }
    }, delay);
  });
}

function apcStudySingleOwnerArmObserverFcO45CL() {
  if (window.__apcStudySingleOwnerObserverFcO45CL) return;
  try {
    const observer = new MutationObserver(() => {
      if (!apcStudySingleOwnerIsStudyRouteFcO45CL()) return;
      if (window.__apcStudySingleOwnerCleanupQueuedFcO45CL) return;
      window.__apcStudySingleOwnerCleanupQueuedFcO45CL = true;
      window.setTimeout(() => {
        window.__apcStudySingleOwnerCleanupQueuedFcO45CL = false;
        apcStudySingleOwnerCleanupFcO45CL();
      }, 25);
    });
    observer.observe(document.documentElement || document.body, {
      childList: true,
      subtree: true,
    });
    window.__apcStudySingleOwnerObserverFcO45CL = observer;
  } catch (_) {}
}

apcStudySingleOwnerArmObserverFcO45CL();


/*
 * APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2
 *
 * Canonical signed-in Study workspace. This restores deck/card CRUD controls,
 * overall progress, weekly progress, deck/card statistics, and review queue in
 * one Study tools panel without reintroducing duplicate Study renderers.
 */
window.apcStudyFullWorkspaceFcO45CNR2 = (function () {
  const MARKER = "APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2";
  const PANEL_ID = "apcStudyFullWorkspacePanelFcO45CNR2";

  function esc(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function displayValue(value) {
    if (Array.isArray(value)) return value.length;
    if (value && typeof value === "object") {
      if (Array.isArray(value.cards)) return value.cards.length;
      if (Array.isArray(value.items)) return value.items.length;
      if (Array.isArray(value.results)) return value.results.length;
      if (Array.isArray(value.queue)) return value.queue.length;
      if (value.count !== undefined) return value.count;
      if (value.total !== undefined) return value.total;
      if (value.card_count !== undefined) return value.card_count;
      return "—";
    }
    if (value === undefined || value === null || value === "") return "—";
    return value;
  }

  function firstValue() {
    for (let i = 0; i < arguments.length; i += 1) {
      const value = arguments[i];
      if (value === undefined || value === null || value === "") continue;
      if (Array.isArray(value)) return value.length;
      if (value && typeof value === "object") return displayValue(value);
      return value;
    }
    return "—";
  }

  function ensureWorkspaceStyles() {
    const styleId = "apc-study-workspace-polish-fc-o45-c-o";
    if (document.getElementById(styleId)) return;
    const style = document.createElement("style");
    style.id = styleId;
    style.setAttribute("data-apc-study-workspace-polish", "APC_STUDY_WORKSPACE_POLISH_FC_O45_C_O");
    style.textContent = [
      ".study-workspace-card{display:grid;gap:1rem;margin-top:1.25rem;}",
      ".study-workspace-card h2{margin:0;font-size:1.35rem;}",
      ".study-workspace-card>.muted{margin-top:-.5rem;}",
      ".study-workspace-actions{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:1rem;align-items:start;}",
      ".study-workspace-actions .inline-form{display:grid;gap:.65rem;padding:1rem;border:1px solid rgba(148,163,184,.28);border-radius:14px;background:rgba(15,23,42,.28);}",
      ".study-workspace-actions label{display:grid;gap:.35rem;font-weight:700;}",
      ".study-workspace-actions input{width:100%;box-sizing:border-box;border-radius:10px;border:1px solid rgba(148,163,184,.35);padding:.7rem .8rem;background:rgba(15,23,42,.32);color:inherit;}",
      ".study-workspace-actions button,.study-workspace-card .inline-actions button{border:1px solid rgba(148,163,184,.35);border-radius:999px;padding:.55rem .85rem;font-weight:700;cursor:pointer;background:rgba(59,130,246,.16);color:inherit;}",
      ".study-workspace-card .mini-summary{display:grid;gap:.7rem;padding:1rem;border:1px solid rgba(148,163,184,.22);border-radius:14px;background:rgba(15,23,42,.18);}",
      ".study-workspace-card .mini-summary>strong{font-size:1rem;letter-spacing:.01em;}",
      ".study-workspace-card .metric-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:.75rem;margin:0;}",
      ".study-workspace-card .metric-grid dt{font-size:.78rem;text-transform:uppercase;letter-spacing:.06em;opacity:.75;}",
      ".study-workspace-card .metric-grid dd{margin:0;font-size:1.25rem;font-weight:800;}",
      ".study-workspace-card .compact-list{display:grid;gap:.65rem;list-style:none;padding:0;margin:0;}",
      ".study-workspace-card .compact-list li{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:.75rem;align-items:center;padding:.8rem;border:1px solid rgba(148,163,184,.18);border-radius:12px;background:rgba(2,6,23,.16);}",
      ".study-workspace-card .compact-list strong{display:block;line-height:1.25;}",
      ".study-workspace-card .compact-list span{display:block;margin-top:.2rem;opacity:.78;line-height:1.35;}",
      ".study-workspace-card .inline-actions{display:flex;flex-wrap:wrap;gap:.4rem;justify-content:flex-end;}",
      "#apcStudyWorkspaceStatusFcO45CNR2{padding:.7rem .9rem;border-radius:12px;background:rgba(34,197,94,.12);border:1px solid rgba(34,197,94,.22);}",
      "@media (max-width:720px){.study-workspace-card .compact-list li{grid-template-columns:1fr;}.study-workspace-card .inline-actions{justify-content:flex-start;}}"
    ].join("\n");
    (document.head || document.documentElement).appendChild(style);
  }

  function arr(value) {
    if (Array.isArray(value)) return value;
    if (Array.isArray(value && value.decks)) return value.decks;
    if (Array.isArray(value && value.cards)) return value.cards;
    if (Array.isArray(value && value.items)) return value.items;
    if (Array.isArray(value && value.results)) return value.results;
    if (Array.isArray(value && value.queue)) return value.queue;
    if (Array.isArray(value && value.by_deck)) return value.by_deck;
    if (Array.isArray(value && value.weekly)) return value.weekly;
    if (Array.isArray(value && value.weeks)) return value.weeks;
    return [];
  }

  function pct(value) {
    if (value === undefined || value === null || value === "") return "—";
    const n = Number(value);
    if (!Number.isFinite(n)) return esc(value);
    return String(Math.round(n <= 1 ? n * 100 : n)) + "%";
  }

  function signedIn() {
    try { if (typeof apcStudySingleOwnerHasSessionFcO45CL === "function" && apcStudySingleOwnerHasSessionFcO45CL()) return true; } catch (_) {}
    try { if (typeof hasActiveWrapperSession === "function" && hasActiveWrapperSession()) return true; } catch (_) {}
    try { if (window.authState && (window.authState.user || window.authState.token)) return true; } catch (_) {}
    return false;
  }

  function isStudyRoute() {
    try {
      return window.location.pathname === "/study" || String(window.location.hash || "").includes("study");
    } catch (_) {
      return false;
    }
  }

  async function request(path, options) {
    options = options || {};
    const method = String(options.method || "GET").toUpperCase();
    const body = options.body;

    try {
      if (typeof api === "function" && path.indexOf("/api/") === 0) {
        const payload = { method: method };
        if (body !== undefined) payload.body = body;
        const data = await api(path.slice(4), payload);
        const status = Number((data && (data.status || data.status_code)) || 200) || 200;
        const ok = !(data && data.ok === false) && status < 400;
        return { ok: ok, status: status, data: data };
      }
    } catch (error) {
      return { ok: false, status: Number(error && error.status) || 0, data: { detail: (error && error.message) || "Study API unavailable" } };
    }

    try {
      const headers = { Accept: "application/json" };
      const fetchOptions = { method: method, credentials: "include", cache: "no-store", headers: headers };
      if (body !== undefined) {
        headers["Content-Type"] = "application/json";
        fetchOptions.body = JSON.stringify(body);
      }
      const response = await fetch(path, fetchOptions);
      let data = null;
      try { data = await response.json(); } catch (_) { data = { detail: await response.text().catch(function () { return ""; }) }; }
      return { ok: response.ok, status: response.status, data: data };
    } catch (error) {
      return { ok: false, status: 0, data: { detail: (error && error.message) || "Study API unavailable" } };
    }
  }

  function selectedDeckIdFromPage() {
    try {
      if (typeof deckIdFromPage === "function") {
        const id = deckIdFromPage();
        if (id) return String(id);
      }
    } catch (_) {}

    try {
      const text = (document.body && document.body.innerText) || "";
      const selected = text.match(/Selected:[\s\S]*?#(\d+)/i);
      if (selected) return selected[1];
      const deck = text.match(/deck\s*#\s*(\d+)/i);
      if (deck) return deck[1];
    } catch (_) {}
    return "";
  }

  function removeOtherStudyTools() {
    const nodes = new Set();
    ["#apcStudyEarlyToolsPanel", "#apcStudyToolsPanel", "#apcStudyEarlyToolsScratchFcO45CL", "[data-apc-study-tools-panel]", "[data-apc-study-tools-auth-cleanup]"].forEach(function (selector) {
      try { document.querySelectorAll(selector).forEach(function (node) { nodes.add(node); }); } catch (_) {}
    });
    try {
      document.querySelectorAll("h2").forEach(function (heading) {
        if ((heading.textContent || "").trim() !== "Study tools") return;
        const panel = heading.closest("section, article, .card, div") || heading.parentElement;
        if (panel) nodes.add(panel);
      });
    } catch (_) {}
    nodes.forEach(function (node) {
      if (!node || node.id === PANEL_ID) return;
      node.remove();
    });
  }

  function insertTarget() {
    const headings = Array.from(document.querySelectorAll("h1,h2,h3,strong"));
    const deckHeading = headings.find(function (node) { return (node.textContent || "").trim() === "Deck selector"; });
    if (deckHeading) return deckHeading.closest("section, article, .card, div") || deckHeading.parentElement;
    const sessionHeading = headings.find(function (node) { return (node.textContent || "").trim() === "Study session"; });
    if (sessionHeading) return sessionHeading.closest("section, article, .card, div") || sessionHeading.parentElement;
    return document.querySelector("main:not([hidden])") || document.getElementById("app") || document.body;
  }

  function ensurePanel() {
    ensureWorkspaceStyles();
    removeOtherStudyTools();
    let panel = document.getElementById(PANEL_ID);
    if (!panel) {
      panel = document.createElement("section");
      panel.id = PANEL_ID;
      panel.className = "card study-tools-card study-workspace-card";
      panel.setAttribute("data-apc-study-single-owner", MARKER);
      panel.setAttribute("data-apc-study-tools-panel", "canonical-full-workspace");
      const target = insertTarget();
      if (target && target.parentElement && target !== document.body) target.insertAdjacentElement("afterend", panel);
      else (document.querySelector("main:not([hidden])") || document.body).appendChild(panel);
    }
    return panel;
  }

  function metric(label, value) {
    return "<dt>" + esc(label) + "</dt><dd>" + esc(displayValue(value)) + "</dd>";
  }

  function compactItem(title, subtitle, actions) {
    return "<li><div><strong>" + esc(title) + "</strong><span>" + esc(subtitle) + "</span></div><div class=\"inline-actions\">" + (actions || "") + "</div></li>";
  }

  function renderShell(panel) {
    panel.innerHTML = [
      "<h2>Study tools</h2>",
      "<p class=\"muted\">Decks, cards, stats, progress, and review queue are loaded from your signed-in Study account.</p>",
      "<div class=\"study-workspace-actions\">",
      "<form id=\"apcStudyCreateDeckFormFcO45CNR2\" class=\"inline-form\"><label>New deck name <input id=\"apcStudyCreateDeckNameFcO45CNR2\" name=\"name\" placeholder=\"Example: Math 316 Review\" autocomplete=\"off\" /></label><button type=\"submit\">Create deck</button></form>",
      "<form id=\"apcStudyCreateCardFormFcO45CNR2\" class=\"inline-form\"><label>Card front <input id=\"apcStudyCreateCardFrontFcO45CNR2\" name=\"front\" placeholder=\"Question or prompt\" autocomplete=\"off\" /></label><label>Card back <input id=\"apcStudyCreateCardBackFcO45CNR2\" name=\"back\" placeholder=\"Answer\" autocomplete=\"off\" /></label><button type=\"submit\">Add card</button></form>",
      "</div>",
      "<section class=\"mini-summary\" id=\"apcStudyOverallProgressFcO45CNR2\"><strong>Overall progress</strong><p class=\"muted\">Loading overall progress...</p></section>",
      "<section class=\"mini-summary\" id=\"apcStudyWeeklyProgressFcO45CNR2\"><strong>Weekly progress</strong><p class=\"muted\">Loading weekly progress...</p></section>",
      "<section class=\"mini-summary\" id=\"apcStudyDecksPanelFcO45CNR2\"><strong>Decks</strong><p class=\"muted\">Loading decks...</p></section>",
      "<section class=\"mini-summary\" id=\"apcStudyDeckStatsPanelFcO45CNR2\"><strong>Deck/card statistics</strong><p class=\"muted\">Loading deck and card statistics...</p></section>",
      "<section class=\"mini-summary\" id=\"apcStudyCardsPanelFcO45CNR2\"><strong>Cards</strong><p class=\"muted\">Loading cards...</p></section>",
      "<section class=\"mini-summary\" id=\"apcStudyQueuePanelFcO45CNR2\"><strong>Review queue</strong><p class=\"muted\">Loading review queue...</p></section>",
      "<p class=\"muted\" id=\"apcStudyWorkspaceStatusFcO45CNR2\">Ready.</p>"
    ].join("");
  }

  function setStatus(message) {
    const node = document.getElementById("apcStudyWorkspaceStatusFcO45CNR2");
    if (node) node.textContent = message;
  }

  function renderOverall(progress, decks, cards) {
    const node = document.getElementById("apcStudyOverallProgressFcO45CNR2");
    if (!node) return;
    const overall = (progress && (progress.overall || progress.summary)) || progress || {};
    const deckCount = firstValue(overall.deck_count, overall.total_decks, overall.decks, decks.length, 0);
    const cardCount = firstValue(overall.card_count, overall.total_cards, overall.cards, cards.length, 0);
    const reviewCount = firstValue(overall.review_count, overall.total_reviews, overall.reviews);
    const accuracy = pct(overall.accuracy || overall.correct_rate || overall.success_rate);
    node.innerHTML = "<strong>Overall progress</strong><dl class=\"metric-grid\">" + metric("Decks", deckCount) + metric("Cards", cardCount) + metric("Reviews", reviewCount) + metric("Accuracy", accuracy) + "</dl>";
  }

  function renderWeekly(progress) {
    const node = document.getElementById("apcStudyWeeklyProgressFcO45CNR2");
    if (!node) return;
    const weekly = arr(progress && (progress.weekly || progress.weekly_progress || progress.by_week || progress.weeks || progress.review_weeks));
    if (!weekly.length) {
      node.innerHTML = "<strong>Weekly progress</strong><p class=\"muted\">No weekly progress data yet.</p>";
      return;
    }
    const items = weekly.slice(0, 8).map(function (week) {
      const label = week.week || week.label || week.date || week.start || "Week";
      const reviews = week.reviews || week.review_count || week.total_reviews || "—";
      const correct = week.correct || week.correct_count || "";
      const accuracy = week.accuracy !== undefined ? " · " + pct(week.accuracy) : "";
      return "<li><strong>" + esc(label) + "</strong><span>" + esc(reviews) + " reviews" + (correct !== "" ? " · " + esc(correct) + " correct" : "") + accuracy + "</span></li>";
    }).join("");
    node.innerHTML = "<strong>Weekly progress</strong><ul class=\"compact-list\">" + items + "</ul>";
  }

  function renderDecks(decks, selectedDeckId) {
    const node = document.getElementById("apcStudyDecksPanelFcO45CNR2");
    if (!node) return;
    if (!decks.length) {
      node.innerHTML = "<strong>Decks</strong><p class=\"muted\">No decks yet. Create one above.</p>";
      return;
    }
    const items = decks.map(function (deck) {
      const id = deck.id || deck.deck_id || deck.deckId || "";
      const name = deck.name || deck.title || ("Deck #" + id);
      const cards = firstValue(deck.card_count, deck.total_cards, deck.cards);
      const reviews = firstValue(deck.review_count, deck.total_reviews, deck.reviews);
      const subtitle = String(cards) + " cards · " + String(reviews) + " reviews · " + pct(deck.accuracy || deck.correct_rate);
      const actions = "<button type=\"button\" data-study-action=\"select-deck\" data-deck-id=\"" + esc(id) + "\">Select</button><button type=\"button\" data-study-action=\"edit-deck\" data-deck-id=\"" + esc(id) + "\" data-deck-name=\"" + esc(name) + "\">Edit</button><button type=\"button\" data-study-action=\"delete-deck\" data-deck-id=\"" + esc(id) + "\">Delete</button>";
      return compactItem(name, subtitle, actions);
    }).join("");
    node.innerHTML = "<strong>Decks</strong><p class=\"muted\">" + esc(decks.length) + " deck(s) available. Selected deck #" + esc(selectedDeckId || "—") + ".</p><ul class=\"compact-list\">" + items + "</ul>";
  }

  function renderDeckStats(stats, selectedDeckId) {
    const node = document.getElementById("apcStudyDeckStatsPanelFcO45CNR2");
    if (!node) return;
    stats = stats || {};
    const cardMetric = firstValue(stats.card_count, stats.total_cards, stats.cards, stats.items, stats.results);
    const reviewMetric = firstValue(stats.review_count, stats.total_reviews, stats.reviews);
    const hardMetric = firstValue(stats.hard, stats.hard_count, stats.buckets && stats.buckets.hard);
    const dueMetric = firstValue(stats.due, stats.due_count, stats.review_queue_count, stats.queue);
    node.innerHTML = "<strong>Deck/card statistics</strong><p class=\"muted\">Selected deck #" + esc(selectedDeckId || "—") + ".</p><dl class=\"metric-grid\">"
      + metric("Cards", cardMetric)
      + metric("Reviews", reviewMetric)
      + metric("Hard bucket", hardMetric)
      + metric("Due / queued", dueMetric)
      + metric("Accuracy", pct(firstValue(stats.accuracy, stats.correct_rate, stats.success_rate)))
      + "</dl>";
  }

  function renderCards(cards, selectedDeckId) {
    const node = document.getElementById("apcStudyCardsPanelFcO45CNR2");
    if (!node) return;
    if (!selectedDeckId) {
      node.innerHTML = "<strong>Cards</strong><p class=\"muted\">Select or create a deck to manage cards.</p>";
      return;
    }
    if (!cards.length) {
      node.innerHTML = "<strong>Cards</strong><p class=\"muted\">No cards in deck #" + esc(selectedDeckId) + " yet. Add one above.</p>";
      return;
    }
    const items = cards.map(function (card) {
      const id = card.id || card.card_id || card.cardId || "";
      const front = card.front || card.question || card.prompt || "";
      const back = card.back || card.answer || card.response || "";
      const actions = "<button type=\"button\" data-study-action=\"edit-card\" data-card-id=\"" + esc(id) + "\" data-front=\"" + esc(front) + "\" data-back=\"" + esc(back) + "\">Edit</button><button type=\"button\" data-study-action=\"delete-card\" data-card-id=\"" + esc(id) + "\">Delete</button>";
      return compactItem(front, back, actions);
    }).join("");
    node.innerHTML = "<strong>Cards</strong><p class=\"muted\">" + esc(cards.length) + " card(s) in deck #" + esc(selectedDeckId) + ".</p><ul class=\"compact-list\">" + items + "</ul>";
  }

  function renderQueue(queue, selectedDeckId) {
    const node = document.getElementById("apcStudyQueuePanelFcO45CNR2");
    if (!node) return;
    if (!selectedDeckId) {
      node.innerHTML = "<strong>Review queue</strong><p class=\"muted\">Select a deck to load the review queue.</p>";
      return;
    }
    if (!queue.length) {
      node.innerHTML = "<strong>Review queue</strong><p class=\"muted\">No cards currently queued for deck #" + esc(selectedDeckId) + ".</p>";
      return;
    }
    const first = queue[0] || {};
    const front = first.front || first.question || first.prompt || "";
    const bucket = first.bucket || first.difficulty || first.status || "queued";
    node.innerHTML = "<strong>Review queue</strong><p class=\"muted\">" + esc(queue.length) + " card(s) queued. First bucket: " + esc(bucket) + ".</p><p><strong>" + esc(front) + "</strong></p><p class=\"muted\">Durable session controls above remain the active review controls.</p>";
  }

  async function loadWorkspace(deckIdOverride) {
    if (!isStudyRoute() || !signedIn()) return;
    const panel = ensurePanel();
    renderShell(panel);
    setStatus("Loading Study workspace...");

    const decksResult = await request("/api/study/decks");
    if (!decksResult.ok) {
      panel.innerHTML = "<h2>Study tools</h2><p class=\"muted\">Study workspace could not load (" + esc(decksResult.status) + "). Try refreshing after sign-in.</p>";
      return;
    }

    const decks = arr(decksResult.data);
    const selectedDeckId = String(deckIdOverride || selectedDeckIdFromPage() || ((decks[0] && (decks[0].id || decks[0].deck_id)) || "") || "");
    const progressResult = await request("/api/study/progress");
    const cardsResult = selectedDeckId ? await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/cards") : { ok: true, data: [] };
    const statsResult = selectedDeckId ? await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/card-stats") : { ok: true, data: {} };
    const queueResult = selectedDeckId ? await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/review-queue") : { ok: true, data: [] };

    const cards = cardsResult.ok ? arr(cardsResult.data) : [];
    const progress = progressResult.ok ? progressResult.data : {};
    const stats = statsResult.ok ? statsResult.data : {};
    const queue = queueResult.ok ? arr(queueResult.data) : [];

    renderOverall(progress, decks, cards);
    renderWeekly(progress);
    renderDecks(decks, selectedDeckId);
    renderDeckStats(stats, selectedDeckId);
    renderCards(cards, selectedDeckId);
    renderQueue(queue, selectedDeckId);
    attachHandlers(panel, selectedDeckId);
    setStatus("Study workspace loaded.");
    try { if (typeof apcStudySingleOwnerScheduleCleanupFcO45CL === "function") apcStudySingleOwnerScheduleCleanupFcO45CL(); } catch (_) {}
  }

  function attachHandlers(panel, selectedDeckId) {
    const deckForm = document.getElementById("apcStudyCreateDeckFormFcO45CNR2");
    if (deckForm && !deckForm.dataset.boundFcO45CNR2) {
      deckForm.dataset.boundFcO45CNR2 = "1";
      deckForm.addEventListener("submit", async function (event) {
        event.preventDefault();
        const name = (document.getElementById("apcStudyCreateDeckNameFcO45CNR2").value || "").trim();
        if (!name) return;
        setStatus("Creating deck...");
        const result = await request("/api/study/decks", { method: "POST", body: { name: name } });
        setStatus(result.ok ? "Deck created." : "Deck create failed (" + result.status + ").");
        if (result.ok) loadWorkspace();
      });
    }

    const cardForm = document.getElementById("apcStudyCreateCardFormFcO45CNR2");
    if (cardForm && !cardForm.dataset.boundFcO45CNR2) {
      cardForm.dataset.boundFcO45CNR2 = "1";
      cardForm.addEventListener("submit", async function (event) {
        event.preventDefault();
        if (!selectedDeckId) { setStatus("Select or create a deck before adding a card."); return; }
        const front = (document.getElementById("apcStudyCreateCardFrontFcO45CNR2").value || "").trim();
        const back = (document.getElementById("apcStudyCreateCardBackFcO45CNR2").value || "").trim();
        if (!front || !back) return;
        setStatus("Adding card...");
        const result = await request("/api/study/decks/" + encodeURIComponent(selectedDeckId) + "/cards", { method: "POST", body: { front: front, back: back } });
        setStatus(result.ok ? "Card added." : "Card add failed (" + result.status + ").");
        if (result.ok) loadWorkspace(selectedDeckId);
      });
    }

    if (!panel.dataset.boundActionsFcO45CNR2) {
      panel.dataset.boundActionsFcO45CNR2 = "1";
      panel.addEventListener("click", async function (event) {
        const button = event.target.closest("button[data-study-action]");
        if (!button) return;
        const action = button.dataset.studyAction;

        if (action === "select-deck") { loadWorkspace(button.dataset.deckId || ""); return; }

        if (action === "edit-deck") {
          const deckId = button.dataset.deckId || "";
          const oldName = button.dataset.deckName || "";
          const name = window.prompt("Deck name", oldName);
          if (!deckId || !name || name === oldName) return;
          setStatus("Updating deck...");
          let result = await request("/api/study/decks/" + encodeURIComponent(deckId), { method: "PUT", body: { name: name } });
          if (!result.ok) result = await request("/api/study/decks/" + encodeURIComponent(deckId), { method: "PATCH", body: { name: name } });
          setStatus(result.ok ? "Deck updated." : "Deck update failed (" + result.status + ").");
          if (result.ok) loadWorkspace(deckId);
          return;
        }

        if (action === "delete-deck") {
          const deckId = button.dataset.deckId || "";
          if (!deckId || !window.confirm("Delete deck #" + deckId + "?")) return;
          setStatus("Deleting deck...");
          const result = await request("/api/study/decks/" + encodeURIComponent(deckId), { method: "DELETE" });
          setStatus(result.ok ? "Deck deleted." : "Deck delete failed (" + result.status + ").");
          if (result.ok) loadWorkspace();
          return;
        }

        if (action === "edit-card") {
          const cardId = button.dataset.cardId || "";
          const oldFront = button.dataset.front || "";
          const oldBack = button.dataset.back || "";
          const front = window.prompt("Card front", oldFront);
          if (front === null) return;
          const back = window.prompt("Card back", oldBack);
          if (back === null) return;
          if (!cardId || (!front.trim() && !back.trim())) return;
          setStatus("Updating card...");
          let result = await request("/api/study/cards/" + encodeURIComponent(cardId), { method: "PUT", body: { front: front.trim(), back: back.trim() } });
          if (!result.ok) result = await request("/api/study/cards/" + encodeURIComponent(cardId), { method: "PATCH", body: { front: front.trim(), back: back.trim() } });
          setStatus(result.ok ? "Card updated." : "Card update failed (" + result.status + ").");
          if (result.ok) loadWorkspace(selectedDeckId);
          return;
        }

        if (action === "delete-card") {
          const cardId = button.dataset.cardId || "";
          if (!cardId || !window.confirm("Delete card #" + cardId + "?")) return;
          setStatus("Deleting card...");
          const result = await request("/api/study/cards/" + encodeURIComponent(cardId), { method: "DELETE" });
          setStatus(result.ok ? "Card deleted." : "Card delete failed (" + result.status + ").");
          if (result.ok) loadWorkspace(selectedDeckId);
        }
      });
    }
  }

  function mount() {
    if (!isStudyRoute()) return;
    if (!signedIn()) {
      removeOtherStudyTools();
      return;
    }
    loadWorkspace();
  }

  return { mount: mount, loadWorkspace: loadWorkspace, request: request };
})();

function renderCleanStudyRouteFcO45CJ() {
  const app = document.getElementById("app");
  if (!app) return;

  if (!apcStudySingleOwnerHasSessionFcO45CL()) {
    if (typeof renderPublicFeatureGate === "function") {
      renderPublicFeatureGate("/study");
    } else {
      app.innerHTML = `
        <main class="page" data-apc-study-single-owner="APC_STUDY_SINGLE_OWNER_FC_O45_C_L">
          <section class="hero-card">
            <p class="eyebrow">Study</p>
            <h1>Study</h1>
            <p>Sign in to load your Study deck, durable session, cards, stats, and review queue.</p>
          </section>
        </main>
      `;
    }
    apcStudySingleOwnerScheduleCleanupFcO45CL();
    return;
  }

  app.innerHTML = `
    <main
      class="page clean-study-route"
      data-apc-study-route-cleanup="APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J"
      data-apc-study-tools-auth-cleanup="APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K"
      hidden
      aria-hidden="true"
    ></main>
  `;

  window.setTimeout(() => {
    try {
      if (window.apcStudyFullWorkspaceFcO45CNR2 && typeof window.apcStudyFullWorkspaceFcO45CNR2.mount === "function") {
        window.apcStudyFullWorkspaceFcO45CNR2.mount();
      }
      apcStudySingleOwnerScheduleCleanupFcO45CL();
    } catch (error) {
      console.warn("[APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2] Study workspace mount skipped", error);
      apcStudySingleOwnerScheduleCleanupFcO45CL();
    }
  }, 0);
}


function renderPage() {
  const path = routePath();
  const page = pages[path];

  // STAGE_5O27B_PUBLIC_ROUTE_EARLY_GATE_V1
  // Public pages should render summaries before any private loaders/preloads.
  if (!hasActiveWrapperSession()) {
    if (
      path === "/study" ||
      path === "/chat" ||
      path === "/companion" ||
      path === "/support" ||
      path === "/profile" ||
      path === "/calendar" ||
      path === "/credits"
    ) {
      renderPublicFeatureGate(path === "/chat" ? "/chat" : path);
      return;
    }
  }

  // STAGE_5O27_GENERIC_PUBLIC_PAGE_GATES_V1
  // These pages are rendered through the generic `pages[path]` branch,
  // not direct path-specific branches. Logged-out users should see the
  // public summary wrapper instead of loading usable/private UI surfaces.
  if (!hasActiveWrapperSession()) {
    if (path === "/profile" || path === "/calendar" || path === "/credits") {
      renderPublicFeatureGate(path);
      return;
    }
  }

  document.title = `${page.title} | AlexHartel AI Platform`;
  setActiveNav(path);
  setSystemHeaderState();
  renderAuthButtons();

  $("adminNavLink")?.classList.toggle("hidden", !authState.user?.is_admin);

  const isStudyWrapperRoute = path === "/study-wrapper-preview";



  const studyPreviewStyle = document.getElementById("studyPreviewStyles");
  if (studyPreviewStyle) {
    // STAGE_5O23_STUDY_LAYOUT_SHARED_HEADER_V1
    // Study content may use its own content stylesheet, but the shared
    // wrapper stylesheet loads after it and owns header/logo/nav styling.
    studyPreviewStyle.disabled = !isStudyWrapperRoute;
  }

  if (path === "/study") {
    renderCleanStudyRouteFcO45CJ();
    return;
  }

  if (isStudyWrapperRoute) {
    if (!hasActiveWrapperSession()) {
      renderPublicFeatureGate("/study");
      return;
    }
    loadStudyWrapperPreview();
    return;
  }

  if (path === "/chat" || path === "/companion") {
    if (!hasActiveWrapperSession()) {
      renderPublicFeatureGate(path === "/chat" ? "/chat" : "/companion");
      return;
    }

    $("app").innerHTML = renderQueuedChatPage();
    bindQueuedChatPage();
    return;
  }

  const isHome = path === "/";
  const isSystem = path === "/system";
  if (path === "/profile") {
    // STAGE_5O33_PROFILE_DIRECT_RENDER_BRANCH_V1
    if (!hasActiveWrapperSession()) {
      renderPublicFeatureGate("/profile");
      return;
    }

    $("app").innerHTML = renderLoggedInProfilePage();
    bindProfilePreferencesControls();
    loadProfilePreferencesForProfilePage();
    return;
  }

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
    const data = await api("/system/status", {
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
      phase11fRefreshSystemPageIfReady();
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
    window.history.replaceState({}, "", "/");
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
    window.history.replaceState({}, "", "/");
    openAuthModal("login");

    const userEmail = user?.email || loadPendingVerificationEmail();
    if ($("authEmail") && userEmail) {
      $("authEmail").value = userEmail;
    }

    setEmailVerificationMessage("Email verified. Log in to continue.");

    setTimeout(() => {
      console.warn("[wrapper-ui] Suppressed old /login redirect; staying on wrapper auth.");
    }, 900);
  } catch (err) {
    const message = err.message || "Email verification failed.";

    showPageNotice(message, true);
    window.history.replaceState({}, "", "/");
    openAuthModal("login");
    setEmailVerificationMessage(message, true);

    setTimeout(() => {
      console.warn("[wrapper-ui] Suppressed old /login redirect; staying on wrapper auth.");
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
    // STAGE_5O32_PROFILE_POST_LOGIN_REFRESH_V1
    rerenderCurrentRouteAfterAuthReady();
    authState.token = token;
    syncAuthRouteCookie();
    if (refreshPrivateRouteAfterAuth("login")) return;
    syncAuthRouteCookie();

    try {
      const me = await api("/me", { method: "GET" });
      authState.user = me.user || me;
      rerenderCurrentRouteAfterAuthReady();
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
/*
 * Stage 5G-1: repaired malformed guarded-submit comment splice.
 * Queued chat remains disabled by default.
 * Legacy auth submit listener remains active.
 */
$("authForm").addEventListener("submit", handleAuthSubmit);

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
    // STAGE_5O21_ADMIN_FAST_STATUS_FIRST_V1
    // Admin page should not block initial rendering on deep Proxmox/SSH checks.
    // Use fast public status here; deep infrastructure status can be added behind
    // an explicit refresh/deep-check button later.
    api("/system/public-status", { method: "GET" }),
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
  if (location.pathname === "/support" && hasActiveWrapperSession()) {
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
  if (!hasActiveWrapperSession()) {
    // STAGE_5O31_FORCE_SUPPORT_PUBLIC_SUMMARY_V1
    // Logged-out Support uses the same public summary pattern as the other pages.
    // Header owns login/create-account actions.
    return `
      <section class="system-section public-feature-gate">
        <div class="summary-box">
          <span>Support</span>
          <strong>Help when something is not working</strong>
          <p>
            Support explains how logged-in users can create tickets, track replies,
            and keep platform issues organized.
          </p>
          <p class="public-feature-note">Sign in from the header when you are ready to contact support.</p>
        </div>

        <div class="summary-grid">
          <div class="summary-card public-feature-card">
            <span>Send a message</span>
            <p>Logged-in users can create a support ticket with a subject and message.</p>
          </div>
          <div class="summary-card public-feature-card">
            <span>Track ticket status</span>
            <p>Tickets move through waiting on admin, waiting on user, and solved states.</p>
          </div>
          <div class="summary-card public-feature-card">
            <span>Keep replies organized</span>
            <p>Each ticket keeps the conversation in one place so users and admins have context.</p>
          </div>
          <div class="summary-card public-feature-card">
            <span>Resolve issues clearly</span>
            <p>Users or admins can mark a ticket solved when the issue is fixed.</p>
          </div>
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

  const controllerNodes = nodes.filter((n) => n.id === "ct-203" || n.role === "controller" || n.role === "controller-api-queue");
  const serverNodes = nodes.filter((n) => n.id === "pvew" || n.id === "vm-200" || n.role === "platform-host" || n.role === "website-edge");

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
  const storageGroup = privateStorageInfrastructureGroup(cleanAdminSystem);
  const storageNodes = storageGroup
    ? (storageGroup.members || []).map(() => ({ state: storageGroup.state || "unknown" }))
    : [];
  const storageDescription = storageGroup?.detail || "Future NAS/storage stations.";

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
        ${cleanGroupCard("Storage Nodes", cleanWorstState(storageNodes), storageNodes, storageDescription)}
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
      // STAGE_5O31_SUPPORT_WRAPPER_PUBLIC_SAFE_V1
      if (app) app.innerHTML = cleanRenderSupportPage();
      if (hasActiveWrapperSession()) {
        cleanAttachHandlers();
      } else {
        cleanSyncNav();
      }
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

      if (
        path === "/support" &&
        typeof cleanLoadSupportTickets === "function" &&
        hasActiveWrapperSession()
      ) {
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

// STAGE_5M0A_AUTH_BACKGROUND_FAILURE_GUARD_V1
// Auth success should not be reversed just because non-critical background
// requests such as presence, public-status, credits, or study previews fail.
function safeBackgroundAuthTask(label, fn) {
  try {
    const result = fn?.();
    if (result && typeof result.catch === "function") {
      result.catch((err) => console.warn(`[auth-background] ${label} failed`, err));
    }
    return result;
  } catch (err) {
    console.warn(`[auth-background] ${label} failed`, err);
    return null;
  }
}

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

  if (
    path === "/support" &&
    typeof cleanLoadSupportTickets === "function" &&
    hasActiveWrapperSession()
  ) {
    jobs.push(cleanLoadSupportTickets());
  }

  if (
    path === "/admin" &&
    typeof cleanLoadAdminData === "function" &&
    authState?.token &&
    authState?.user?.is_admin
  ) {
    jobs.push(cleanLoadAdminData());
  }

  if (
    path === "/credits" &&
    typeof loadAccountCredits === "function" &&
    hasActiveWrapperSession()
  ) {
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
      rerenderCurrentRouteAfterAuthReady();
    } catch {
      authState.user = result.user || null;
      rerenderCurrentRouteAfterAuthReady();
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

// STAGE_5P11R_AUTH_PRESENCE_FORCE_BEGIN
let webPresenceLastAuthState = null;

function webPresenceIsLoggedIn() {
  return Boolean(authState && authState.token);
}

function webPresenceAuthHeaders() {
  const headers = { "Content-Type": "application/json" };

  if (webPresenceIsLoggedIn()) {
    headers.Authorization = "Bearer " + authState.token;
  }

  return headers;
}

function webPresenceShouldBypassDebounce(reason) {
  const loggedIn = webPresenceIsLoggedIn();
  const authStateKey = loggedIn ? "auth" : "anon";

  if (webPresenceLastAuthState !== authStateKey) {
    webPresenceLastAuthState = authStateKey;
    return true;
  }

  return reason === "force"
    || reason === "startup-logged-in"
    || reason === "auth-login-success"
    || reason === "private-app-heartbeat"
    || reason === "15-second-logged-in-heartbeat";
}
// STAGE_5P11R_AUTH_PRESENCE_FORCE_END

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

  // Debounce normal presence sends, but never debounce the first logged-in
  // heartbeat after auth state changes. This keeps authenticated CT203 controller status fresh for logged-in users.
  if (!webPresenceShouldBypassDebounce(reason) && now - webPresenceLastSentAt < 55_000) {
    return;
  }

  webPresenceLastSentAt = now;

  const presencePayload = {
    visitor_id: getWebPresenceVisitorId(),
    route: location.pathname,
    active_seconds: activeSeconds,
    visibility: document.visibilityState,
    logged_in: webPresenceIsLoggedIn(),
    metadata: {
      reason,
      logged_in: webPresenceIsLoggedIn(),
      private_app: PRIVATE_APP_ROUTE_SET.has(location.pathname),
    },
  };

  // STAGE_5P11S_PRESENCE_SEND_FALLBACK_BEGIN
  // Use the wrapper api helper first because it knows the deployed route prefix.
  // If that fails, fall back to direct backend routes for local/dev deployments.
  webPresenceInFlight = (async () => {
    const errors = [];

    try {
      return await api("/presence/web", {
        method: "POST",
        headers: webPresenceAuthHeaders(),
        body: JSON.stringify(presencePayload),
      });
    } catch (err) {
      errors.push("api:/presence/web: " + (err?.message || String(err)));
    }

    const directUrls = [
      "/system/presence/web",
      "/api/presence/web",
      `${API_BASE}/presence/web`,
    ];

    for (const url of directUrls) {
      try {
        const response = await fetch(url, {
          method: "POST",
          credentials: "include",
          headers: webPresenceAuthHeaders(),
          body: JSON.stringify(presencePayload),
        });

        const data = await response.json().catch(() => ({}));

        if (!response.ok || data.ok === false) {
          throw new Error(data.detail || data.error || `presence HTTP ${response.status}`);
        }

        return data;
      } catch (err) {
        errors.push(url + ": " + (err?.message || String(err)));
      }
    }

    throw new Error("presence send failed: " + errors.join(" | "));
  })()
  // STAGE_5P11S_PRESENCE_SEND_FALLBACK_END
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

// STAGE_5P11R_LOGGED_IN_15_SECOND_HEARTBEAT_BEGIN
setTimeout(() => {
  if (webPresenceIsLoggedIn()) {
    sendWebPresence("15-second-logged-in-heartbeat");
  }
}, 15_000);

setInterval(() => {
  if (webPresenceIsLoggedIn()) {
    sendWebPresence("private-app-heartbeat");
  } else {
    sendWebPresence("interval");
  }
}, 60_000);
// STAGE_5P11R_LOGGED_IN_15_SECOND_HEARTBEAT_END

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
      rerenderCurrentRouteAfterAuthReady();

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
  // STAGE_5O11_INTERNAL_ROUTE_NO_DOCUMENT_RELOAD_V1
  // Do not use location.href for wrapper-owned routes. That reloads the whole
  // document and re-runs startup/auth/background fetches. Internal app routes
  // must use the SPA router so the header/nav state changes without refresh.
  event.preventDefault();

  const cleanRoute =
    target.pathname ||
    link.getAttribute("data-route") ||
    link.getAttribute("href") ||
    "/";

  const sameOrigin = !target.origin || target.origin === window.location.origin;
  const routeIsInternal =
    sameOrigin &&
    typeof pages !== "undefined" &&
    Object.prototype.hasOwnProperty.call(pages, cleanRoute);

  if (routeIsInternal && typeof navigate === "function") {
    navigate(cleanRoute);
  } else if (sameOrigin && link?.dataset?.route && typeof navigate === "function") {
    navigate(link.dataset.route);
  } else {
    window.location.href = target.toString();
  }
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
    window.history.replaceState({}, "", "/");
    openAuthModal("login");
    return true;
  }

  showPageNotice("Password reset link ready.");

  const newPassword = window.prompt("Enter your new password. It must be at least 8 characters.");

  if (!newPassword) {
    showPageNotice("Password reset cancelled.", true);
    window.history.replaceState({}, "", "/");
    openAuthModal("login");
    return true;
  }

  const confirmPassword = window.prompt("Confirm your new password.");

  if (newPassword !== confirmPassword) {
    showPageNotice("Passwords did not match.", true);
    window.history.replaceState({}, "", "/");
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
    window.history.replaceState({}, "", "/");
    openAuthModal("login");
    setEmailVerificationMessage("Password reset. Log in with your new password.");

    setTimeout(() => {
      console.warn("[wrapper-ui] Suppressed old /login redirect; staying on wrapper auth.");
    }, 900);
  } catch (err) {
    const message = err.message || "Password reset failed.";
    showPageNotice(message, true);
    window.history.replaceState({}, "", "/");
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


/*
 * Stage 5F-69: disabled guarded live-submit branch skeleton.
 *
 * This block exposes a future live-submit branch skeleton for tests/planning.
 * It intentionally does not wire itself into the current submit flow.
 *
 * Safety:
 * - guarded live-submit branch remains unwired
 * - legacy/current chat path remains active
 * - does not call queued orchestration
 * - does not call queued send
 * - does not call queued status polling
 * - does not render queued placeholders
 */
(function stage5f69GuardedLiveSubmitBranchSkeleton(root) {
  "use strict";

  function stage5f69EvaluateGuardedLiveSubmitBranch(context) {
    const enabled = root.AI_PLATFORM_QUEUED_CHAT_ENABLED === true;
    const gate = root.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_GATE_BRANCH;
    const readiness = root.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH;

    return {
      ok: true,
      stage: "5f69",
      source: "app_js_disabled_guarded_live_submit_branch_skeleton",
      guardedLiveSubmitBranchWired: false,
      enabled,
      gatePresent: Boolean(gate),
      readinessPresent: Boolean(readiness),
      liveSubmitSelected: false,
      legacyChatPathActive: true,
      queuedSubmitAllowed: false,
      reason: enabled
        ? "guarded_live_submit_branch_unwired_stage_5f69"
        : "guarded_live_submit_branch_flag_disabled_stage_5f69",
      blockedActions: [
        "build_payload",
        "submit_decision",
        "queued_orchestration",
        "queued_send",
        "queued_placeholder",
        "queued_polling",
        "queued_final_render"
      ],
      requiredBeforeWire: [
        "flag_off_submit_regression_passes",
        "branch_skeleton_mock_test_passes",
        "gate_wire_explicitly_enabled",
        "live_wire_explicitly_enabled",
        "single_payload_build_proven",
        "single_decision_call_proven",
        "single_orchestration_call_proven",
        "single_send_call_proven",
        "single_placeholder_proven",
        "single_poll_loop_proven",
        "single_final_render_proven",
        "rollback_flag_off_proven"
      ]
    };
  }

  root.AI_PLATFORM_QUEUED_CHAT_GUARDED_LIVE_SUBMIT_BRANCH_SKELETON = Object.freeze({
    stage: "5f69",
    source: "app_js_disabled_guarded_live_submit_branch_skeleton",
    guardedLiveSubmitBranchWired: false,
    evaluateGuardedLiveSubmitBranch: stage5f69EvaluateGuardedLiveSubmitBranch
  });
})(typeof window !== "undefined" ? window : globalThis);


// ============================================================
// STAGE_5O8_HEADER_ACTIVE_STATE_NORMALIZER_V1
//
// Keeps shared header/nav active state consistent across SPA routes.
// Fixes:
// - Study route using different active coloring.
// - Admin not turning active when selected.
// - Credits staying active when current route is not Credits.
// ============================================================
(function stage5o8HeaderActiveStateNormalizer() {
  const APP_ROUTES = new Set([
    "/",
    "/chat",
    "/study",
    "/companion",
    "/calendar",
    "/profile",
    "/admin",
    "/system",
    "/credits",
    "/account/credits"
  ]);

  function normalizeRoute(path) {
    let route = String(path || "/").split("?")[0].split("#")[0] || "/";
    if (route.length > 1 && route.endsWith("/")) route = route.slice(0, -1);

    if (route === "/study-wrapper-preview") return "/study";
    if (route === "/account/credits") return "/credits";

    return route;
  }

  function getCurrentRoute() {
    return normalizeRoute(window.location.pathname || "/");
  }

  function getAnchorRoute(anchor) {
    if (!anchor) return "";

    const dataRoute = anchor.getAttribute("data-route");
    if (dataRoute) return normalizeRoute(dataRoute);

    const href = anchor.getAttribute("href") || "";
    if (!href || href.startsWith("#")) return "";

    try {
      const url = new URL(href, window.location.origin);
      if (url.origin !== window.location.origin) return "";
      return normalizeRoute(url.pathname || "/");
    } catch {
      return "";
    }
  }

  function shouldManageLink(anchor, route) {
    if (!anchor || !route) return false;

    if (!APP_ROUTES.has(route)) return false;

    const scope = anchor.closest("header, .topbar, .main-nav, .route-nav, .nav, .tabs, .tabbar");
    if (!scope) return false;

    return true;
  }

  function isActiveRoute(linkRoute, currentRoute) {
    const link = normalizeRoute(linkRoute);
    const current = normalizeRoute(currentRoute);

    if (link === "/") return current === "/";
    if (link === "/credits") return current === "/credits" || current === "/account/credits";

    return current === link || current.startsWith(link + "/");
  }

  function normalizeHeaderActiveState() {
    const current = getCurrentRoute();
    document.body.setAttribute("data-current-route", current);

    const anchors = Array.from(document.querySelectorAll(
      "header a, .topbar a, .main-nav a, .route-nav a, .nav a, .tabs a, .tabbar a, [data-route]"
    ));

    for (const anchor of anchors) {
      const route = getAnchorRoute(anchor);
      if (!shouldManageLink(anchor, route)) continue;

      const active = isActiveRoute(route, current);

      anchor.classList.toggle("active", active);
      anchor.classList.toggle("is-active", active);
      anchor.classList.toggle("selected", active);

      if (active) {
        anchor.setAttribute("aria-current", "page");
      } else if (anchor.getAttribute("aria-current") === "page") {
        anchor.removeAttribute("aria-current");
      }
    }
  }

  function scheduleNormalizeHeaderActiveState() {
    window.requestAnimationFrame(normalizeHeaderActiveState);
    window.setTimeout(normalizeHeaderActiveState, 50);
    window.setTimeout(normalizeHeaderActiveState, 250);
  }

  const originalPushState = history.pushState;
  history.pushState = function patchedPushState() {
    const result = originalPushState.apply(this, arguments);
    scheduleNormalizeHeaderActiveState();
    return result;
  };

  const originalReplaceState = history.replaceState;
  history.replaceState = function patchedReplaceState() {
    const result = originalReplaceState.apply(this, arguments);
    scheduleNormalizeHeaderActiveState();
    return result;
  };

  window.addEventListener("popstate", scheduleNormalizeHeaderActiveState);
  window.addEventListener("hashchange", scheduleNormalizeHeaderActiveState);
  document.addEventListener("DOMContentLoaded", scheduleNormalizeHeaderActiveState);
  document.addEventListener("click", function onPossibleRouteClick(event) {
    const anchor = event.target && event.target.closest ? event.target.closest("a") : null;
    if (anchor && getAnchorRoute(anchor)) {
      scheduleNormalizeHeaderActiveState();
    }
  }, true);

  window.stage5o8NormalizeHeaderActiveState = normalizeHeaderActiveState;
  scheduleNormalizeHeaderActiveState();
  window.setInterval(normalizeHeaderActiveState, 1500);
})();


// ============================================================
// STAGE_5O9_CREDITS_PILL_ROUTE_STATE_V1
//
// Credits in the header is an account balance pill, not a permanent
// selected nav tab. It should only receive route-active styling on /credits.
// Also keeps route URLs clean; no ?fresh cache busters are needed.
// ============================================================
(function stage5o9CreditsPillRouteState() {
  function cleanRoute(path) {
    let route = String(path || "/").split("?")[0].split("#")[0] || "/";
    if (route.length > 1 && route.endsWith("/")) route = route.slice(0, -1);
    if (route === "/account/credits") return "/credits";
    return route;
  }

  function updateCreditsPillRouteState() {
    const current = cleanRoute(window.location.pathname || "/");
    const active = current === "/credits";

    document.body.setAttribute("data-current-route", current);

    const pill = document.getElementById("creditsPill");
    if (!pill) return;

    pill.classList.toggle("route-active", active);
    pill.classList.toggle("active", active);
    pill.classList.toggle("is-active", active);
    pill.classList.toggle("selected", active);

    if (active) {
      pill.setAttribute("aria-current", "page");
    } else {
      pill.removeAttribute("aria-current");
    }
  }

  function scheduleCreditsPillRouteState() {
    window.requestAnimationFrame(updateCreditsPillRouteState);
    window.setTimeout(updateCreditsPillRouteState, 50);
    window.setTimeout(updateCreditsPillRouteState, 250);
  }

  window.addEventListener("popstate", scheduleCreditsPillRouteState);
  window.addEventListener("hashchange", scheduleCreditsPillRouteState);
  document.addEventListener("DOMContentLoaded", scheduleCreditsPillRouteState);
  document.addEventListener("click", scheduleCreditsPillRouteState, true);

  window.stage5o9UpdateCreditsPillRouteState = updateCreditsPillRouteState;
  scheduleCreditsPillRouteState();
  window.setInterval(updateCreditsPillRouteState, 1500);
})();




// ============================================================
// STAGE_5O13_HEADER_NAV_ACTIVE_STATE_V1
// Single source of truth for wrapper header active-tab state.
// This runs after older route handlers so duplicate/legacy handlers cannot
// leave Credits or another tab stuck highlighted.
// ============================================================
(function stage5o13HeaderNavActiveState() {
  function normalizeHeaderRoute(value) {
    let route = String(value || "/").trim() || "/";
    try {
      const url = new URL(route, window.location.origin);
      if (url.origin === window.location.origin) {
        route = url.pathname || "/";
      }
    } catch (_) {
      route = route.split("?")[0].split("#")[0] || "/";
    }

    route = route.split("?")[0].split("#")[0] || "/";
    if (route.length > 1) route = route.replace(/\/+$/, "");
    return route || "/";
  }

  function currentHeaderRoute() {
    return normalizeHeaderRoute(window.location.pathname || "/");
  }

  function syncHeaderNavActiveState() {
    const route = currentHeaderRoute();
    document.body.dataset.currentRoute = route;

    const navLinks = document.querySelectorAll(
      'header a[data-route], .topbar a[data-route], .main-nav a[data-route], .route-nav a[data-route], nav a[data-route]'
    );

    navLinks.forEach((link) => {
      const linkRoute = normalizeHeaderRoute(link.getAttribute("data-route") || link.getAttribute("href") || "");
      const isActive = linkRoute === route;

      link.classList.toggle("active", isActive);

      if (isActive) {
        link.setAttribute("aria-current", "page");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  window.stage5o13SyncHeaderNavActiveState = syncHeaderNavActiveState;

  const scheduleSync = () => {
    syncHeaderNavActiveState();
    window.setTimeout(syncHeaderNavActiveState, 0);
    window.setTimeout(syncHeaderNavActiveState, 50);
  };

  const originalPushState = history.pushState;
  history.pushState = function stage5o13PushState(...args) {
    const result = originalPushState.apply(this, args);
    scheduleSync();
    return result;
  };

  const originalReplaceState = history.replaceState;
  history.replaceState = function stage5o13ReplaceState(...args) {
    const result = originalReplaceState.apply(this, args);
    scheduleSync();
    return result;
  };

  window.addEventListener("popstate", scheduleSync);
  window.addEventListener("hashchange", scheduleSync);
  document.addEventListener("click", (event) => {
    const link = event.target.closest?.("a[data-route]");
    if (link) scheduleSync();
  }, true);

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", scheduleSync);
  } else {
    scheduleSync();
  }

  window.setTimeout(scheduleSync, 250);
})();


// ============================================================
// STAGE_5O16_CREDITS_PILL_NOT_NAV_TAB_V1
// Credits is an account balance button, not a normal nav tab.
// Only real header nav anchors get active-page styling.
// ============================================================
(function stage5o16CreditsPillNotNavTab() {
  function cleanRoute(value) {
    let route = String(value || "/").trim() || "/";
    try {
      const url = new URL(route, window.location.origin);
      route = url.pathname || "/";
    } catch {
      route = route.split("?")[0].split("#")[0] || "/";
    }
    route = route.split("?")[0].split("#")[0] || "/";
    if (route.length > 1) route = route.replace(/\/+$/, "");
    if (route === "/study-wrapper-preview") return "/study";
    if (route === "/account/credits") return "/credits";
    return route || "/";
  }

  function syncNavActive() {
    const current = cleanRoute(window.location.pathname || "/");
    document.body.setAttribute("data-current-route", current);
    document.body.dataset.currentRoute = current;

    document
      .querySelectorAll('header nav a[data-route], .topbar nav a[data-route], nav.nav a[data-route]')
      .forEach((link) => {
        const route = cleanRoute(link.getAttribute("data-route") || link.getAttribute("href") || "");
        const active = route === current;
        link.classList.toggle("active", active);
        link.classList.toggle("is-active", active);
        link.classList.toggle("selected", active);
        if (active) {
          link.setAttribute("aria-current", "page");
        } else {
          link.removeAttribute("aria-current");
        }
      });

    const pill = document.getElementById("creditsPill");
    if (pill) {
      const active = current === "/credits";
      pill.classList.toggle("active", active);
      pill.classList.toggle("is-active", active);
      pill.classList.toggle("selected", active);
      pill.classList.toggle("route-active", active);
      if (active) {
        pill.setAttribute("aria-current", "page");
      } else {
        pill.removeAttribute("aria-current");
      }
    }
  }

  function goCredits(event) {
    const pill = event.target.closest?.("#creditsPill");
    if (!pill) return;
    event.preventDefault();
    event.stopPropagation();

    if (typeof navigate === "function") {
      navigate("/credits");
    } else {
      history.pushState({}, "", "/credits");
      if (typeof renderPage === "function") renderPage();
    }

    syncNavActive();
    window.setTimeout(syncNavActive, 0);
    window.setTimeout(syncNavActive, 50);
  }

  document.addEventListener("click", goCredits, true);
  window.addEventListener("popstate", syncNavActive);
  window.addEventListener("hashchange", syncNavActive);

  const oldPush = history.pushState;
  history.pushState = function stage5o16PushState(...args) {
    const result = oldPush.apply(this, args);
    window.setTimeout(syncNavActive, 0);
    return result;
  };

  const oldReplace = history.replaceState;
  history.replaceState = function stage5o16ReplaceState(...args) {
    const result = oldReplace.apply(this, args);
    window.setTimeout(syncNavActive, 0);
    return result;
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", syncNavActive);
  } else {
    syncNavActive();
  }

  window.setTimeout(syncNavActive, 50);
  window.setTimeout(syncNavActive, 250);
})();

// STAGE_5O35_COMPANION_UX_BEGIN
(function () {
  const stageClass = "stage5o35";
  const snapshotKey = "stage5o35CompanionQueueSnapshot";
  let stageScheduled = false;

  // STAGE_5P8G_COMPANION_REFRESH_LOOP_GUARD_BEGIN
  let stageLastEnhanceAt = 0;
  let stageLastCardUpdateAt = 0;
  // STAGE_5P8G_COMPANION_REFRESH_LOOP_GUARD_END

  function stageRouteLooksCompanion() {
    const path = String(window.location.pathname || "").replace(/\/+$/, "");
    const hash = String(window.location.hash || "").toLowerCase();
    return path === "/companion" || path.endsWith("/companion") || hash.includes("companion");
  }

  function stageFindRoot() {
    return document.querySelector("#app")
      || document.querySelector("#root")
      || document.querySelector("main")
      || document.querySelector(".app-main")
      || document.querySelector(".page-root");
  }

  function stageNodeMentionsCompanion(root) {
    if (!root) return false;
    const text = String(root.innerText || "");
    if (/companion|queued chat|message|assistant|worker|model/i.test(text)) return true;
    return Array.from(root.querySelectorAll("[id], [class], [data-page], [data-route]")).some(function (el) {
      const blob = [
        el.id || "",
        el.className || "",
        el.getAttribute("data-page") || "",
        el.getAttribute("data-route") || ""
      ].join(" ");
      return /companion|queued|chat/i.test(blob);
    });
  }

  function stageHasInteractiveCompanion(root) {
    if (!root) return false;
    const hasMessageControl = !!root.querySelector("textarea, input[type='text'], input:not([type]), form");
    const hasButton = Array.from(root.querySelectorAll("button, input[type='submit']")).some(function (btn) {
      return /send|submit|message|chat|start|retry/i.test(String(btn.textContent || btn.value || ""));
    });
    return stageNodeMentionsCompanion(root) && (hasMessageControl || hasButton);
  }

  function stageReadSnapshot() {
    try {
      return JSON.parse(window.localStorage.getItem(snapshotKey) || "{}") || {};
    } catch (err) {
      return {};
    }
  }

  function stageWriteSnapshot(next) {
    const previous = stageReadSnapshot();
    const merged = Object.assign({}, previous, next, {
      updatedAt: new Date().toLocaleString()
    });
    try {
      window.localStorage.setItem(snapshotKey, JSON.stringify(merged));
    } catch (err) {
      /* storage may be unavailable */
    }
    stageUpdateCards();
  }

  function stagePickValue(data, keys) {
    if (!data || typeof data !== "object") return "";
    for (const key of keys) {
      if (data[key] !== undefined && data[key] !== null && String(data[key]).trim() !== "") {
        return String(data[key]);
      }
    }
    for (const value of Object.values(data)) {
      if (value && typeof value === "object") {
        const nested = stagePickValue(value, keys);
        if (nested) return nested;
      }
    }
    return "";
  }

  function stageCaptureQueueResponse(url, response) {
    if (!url || !String(url).includes("/api/chat/queued") || !response || !response.clone) return;
    response.clone().json().then(function (data) {
      const jobId = stagePickValue(data, ["job_id", "jobId", "id"]);
      const status = stagePickValue(data, ["status", "state", "job_status", "jobStatus"]);
      const model = stagePickValue(data, ["model", "current_model", "worker_model", "model_name"]);
      const worker = stagePickValue(data, ["worker", "worker_id", "worker_name"]);
      stageWriteSnapshot({
        lastJobId: jobId || stageReadSnapshot().lastJobId || "",
        status: status || stageReadSnapshot().status || "updated",
        model: model || stageReadSnapshot().model || "",
        worker: worker || stageReadSnapshot().worker || ""
      });
    }).catch(function () {
      stageWriteSnapshot({
        status: stageReadSnapshot().status || "waiting for response"
      });
    });
  }

  function stageInstallFetchObserver() {
    if (window.__stage5o35CompanionFetchObserver || typeof window.fetch !== "function") return;
    const nativeFetch = window.fetch.bind(window);
    window.fetch = function (input, init) {
      const url = typeof input === "string" ? input : (input && input.url ? input.url : "");
      return nativeFetch(input, init).then(function (response) {
        stageCaptureQueueResponse(url, response);
        return response;
      });
    };
    window.__stage5o35CompanionFetchObserver = true;
  }

  function stageField(name) {
    const shell = document.querySelector(".stage5o35-companion-shell");
    return shell ? shell.querySelector("[data-stage5o35-field='" + name + "']") : null;
  }

  function stageFindStatusFromText() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    const text = shell ? String(shell.innerText || "") : "";
    const statusMatch = text.match(/\b(queued|pending|running|processing|complete|completed|done|failed|error|cancelled)\b/i);
    return statusMatch ? statusMatch[1].toLowerCase() : "";
  }

  function stageFindModelFromText() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    const text = shell ? String(shell.innerText || "") : "";
    const modelMatch = text.match(/\bmodel\s*[:\-]\s*([^\n\r]+)/i);
    return modelMatch ? modelMatch[1].trim().slice(0, 80) : "";
  }

  function stageFindJobFromText() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    const text = shell ? String(shell.innerText || "") : "";
    const jobMatch = text.match(/\b(?:job[_\s-]*id|job)\s*[:#\-]?\s*([A-Za-z0-9_-]{8,})/i);
    return jobMatch ? jobMatch[1] : "";
  }

  function stageSetField(name, value) {
    const el = stageField(name);
    if (el) el.textContent = value || "—";
  }

  function stageUpdateCards() {
    const shell = document.querySelector(".stage5o35-companion-shell");
    if (!shell) return;

    // STAGE_5P8G_COMPANION_CARD_UPDATE_THROTTLE_BEGIN
    // Prevent Companion card text mutations from retriggering the enhancer in a rapid loop.
    const now = Date.now();
    if (now - stageLastCardUpdateAt < 750) return;
    stageLastCardUpdateAt = now;
    // STAGE_5P8G_COMPANION_CARD_UPDATE_THROTTLE_END

    const snapshot = stageReadSnapshot();
    const status = snapshot.status || stageFindStatusFromText() || "ready";
    const model = snapshot.model || stageFindModelFromText() || "backend default";
    const jobId = snapshot.lastJobId || stageFindJobFromText() || "";
    const worker = snapshot.worker || "local worker pool";
    const updatedAt = snapshot.updatedAt || "not started this session";

    stageSetField("queueStatus", status);
    stageSetField("model", model);
    stageSetField("jobId", jobId ? jobId : "no recent job");
    stageSetField("worker", worker);
    stageSetField("updatedAt", updatedAt);

    shell.dataset.queueStatus = String(status).toLowerCase();

    const empty = shell.querySelector(".stage5o35-empty-state");
    if (empty) {
      const hasMessages = !!shell.querySelector(".message, .chat-message, .assistant-message, .user-message, [data-role='assistant'], [data-role='user']")
        || /\bassistant\s*·|\buser\s*·/i.test(String(shell.innerText || ""));
      empty.hidden = hasMessages;
    }
  }

  function stageUpgradeControls(shell) {
    shell.querySelectorAll("textarea, input[type='text'], input:not([type])").forEach(function (input) {
      input.classList.add("stage5o35-message-input");
      if (!input.getAttribute("placeholder")) {
        input.setAttribute("placeholder", "Message Companion...");
      }
    });

    shell.querySelectorAll("button, input[type='submit']").forEach(function (button) {
      const label = String(button.textContent || button.value || "");
      if (/send|submit|message|chat/i.test(label)) {
        button.classList.add("stage5o35-send-button");
      }
    });

    shell.querySelectorAll(".message, .chat-message, [data-role='assistant'], [data-role='user']").forEach(function (msg) {
      const role = String(msg.getAttribute("data-role") || msg.className || msg.textContent || "").toLowerCase();
      msg.classList.add("stage5o35-message-bubble");
      if (role.includes("user")) msg.classList.add("stage5o35-user-bubble");
      if (role.includes("assistant")) msg.classList.add("stage5o35-assistant-bubble");
    });
  }

  function stageEnhanceCompanion() {
    if (!stageRouteLooksCompanion()) return;

    // STAGE_5P8H_COMPANION_CANONICAL_RENDERER_GUARD_BEGIN
    // The Companion page now renders the polished layout directly in renderQueuedChatPage.
    // Do not wrap/enhance it again.
    const canonical = document.querySelector("[data-stage5p8h-canonical-companion='true']");
    if (canonical) {
      stageUpdateCards();
      return;
    }
    // STAGE_5P8H_COMPANION_CANONICAL_RENDERER_GUARD_END

    // STAGE_5P8G_COMPANION_ENHANCE_THROTTLE_BEGIN
    // DOM updates from message/status rendering can trigger MutationObserver again.
    // Throttle enhancement so Companion does not appear to constantly refresh.
    const enhanceNow = Date.now();
    if (enhanceNow - stageLastEnhanceAt < 1000) return;
    stageLastEnhanceAt = enhanceNow;
    // STAGE_5P8G_COMPANION_ENHANCE_THROTTLE_END

    const root = stageFindRoot();
    if (!stageHasInteractiveCompanion(root)) return;

    const existingShell = root.querySelector(".stage5o35-companion-shell");
    if (existingShell) {
      stageUpgradeControls(existingShell);
      stageUpdateCards();
      return;
    }

    const originalChildren = Array.from(root.children).filter(function (child) {
      return !child.classList.contains("stage5o35-companion-shell");
    });
    if (!originalChildren.length) return;

    const shell = document.createElement("section");
    shell.className = "stage5o35-companion-shell";
    shell.setAttribute("aria-label", "Companion workspace");

    const hero = document.createElement("div");
    hero.className = "stage5o35-companion-hero";
    hero.innerHTML = [
      '<div class="stage5o35-companion-hero-copy">',
      '<p class="stage5o35-eyebrow">Companion</p>',
      '<h1>Supportive chat workspace</h1>',
      '<p>Talk with your local Companion while the queue handles work safely behind the scenes.</p>',
      '</div>',
      '<div class="stage5o35-companion-hero-badge">Queue-aware UI</div>'
    ].join("");

    const grid = document.createElement("div");
    grid.className = "stage5o35-companion-grid";

    const main = document.createElement("div");
    main.className = "stage5o35-companion-main";

    const conversation = document.createElement("div");
    conversation.className = "stage5o35-conversation-card";

    const empty = document.createElement("div");
    empty.className = "stage5o35-empty-state";
    empty.innerHTML = [
      '',
      '<div>',
      '',
      '',
      '</div>'
    ].join("");

    const legacy = document.createElement("div");
    legacy.className = "stage5o35-existing-companion-ui";
    originalChildren.forEach(function (child) {
      legacy.appendChild(child);
    });

    conversation.appendChild(empty);
    conversation.appendChild(legacy);
    main.appendChild(conversation);

    const aside = document.createElement("aside");
    aside.className = "stage5o35-companion-aside";
    aside.innerHTML = [
      '<section class="stage5o35-status-card">',
      '<div class="stage5o35-card-title-row"><h2>Companion status</h2><span class="stage5o35-live-dot"></span></div>',
      '<dl>',
      '<div><dt>Queue</dt><dd data-stage5o35-field="queueStatus">ready</dd></div>',
      '<div><dt>Worker</dt><dd data-stage5o35-field="worker">local worker pool</dd></div>',
      '<div><dt>Model</dt><dd data-stage5o35-field="model">backend default</dd></div>',
      '</dl>',
      '</section>',
      '<section class="stage5o35-status-card">',
      '<h2>Last job</h2>',
      '<dl>',
      '<div><dt>Job id</dt><dd data-stage5o35-field="jobId">no recent job</dd></div>',
      '<div><dt>Updated</dt><dd data-stage5o35-field="updatedAt">not started this session</dd></div>',
      '</dl>',
      '</section>',
      '<section class="stage5o35-status-card stage5o35-how-card">',
      '<h2>How this works</h2>',
      '<p>Messages continue through <code>/api/chat/queued</code>. The page watches the same polling flow and displays queue state without changing backend behavior.</p>',
      '</section>',
      '<section class="stage5o35-status-card stage5o35-toggle-card">',
      '<div>',
      '<h2>Study context</h2>',
      '<p>Use the Study phrases above to control sessions through Companion.</p>',
      '</div>',
      '<button type="button" class="stage5o35-toggle" disabled aria-disabled="true">Coming next</button>',
      '</section>'
    ].join("");

    grid.appendChild(main);
    grid.appendChild(aside);
    shell.appendChild(hero);
    shell.appendChild(grid);
    root.appendChild(shell);

    stageUpgradeControls(shell);
    stageUpdateCards();
  }

  function stageSchedule() {
    if (stageScheduled) return;
    stageScheduled = true;
    window.setTimeout(function () {
      stageScheduled = false;
      stageInstallFetchObserver();
      stageEnhanceCompanion();
    }, 60);
  }

  document.addEventListener("DOMContentLoaded", stageSchedule);
  window.addEventListener("hashchange", stageSchedule);
  window.addEventListener("popstate", stageSchedule);
  document.addEventListener("click", function (event) {
    const link = event.target && event.target.closest ? event.target.closest("a[href]") : null;
    if (link && String(link.getAttribute("href") || "").includes("companion")) {
      window.setTimeout(stageSchedule, 100);
    }
  });

  const observer = new MutationObserver(stageSchedule);
  observer.observe(document.documentElement, { childList: true, subtree: true });

  stageSchedule();
})();
// STAGE_5O35_COMPANION_UX_END



// STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN
(function () {
  const cardId = "stage5p8a-study-session-status-card";
  let observerInstalled = false;
  let refreshTimer = null;

  function isStudyRoute() {
    const path = String(window.location.pathname || "").replace(/\/+$/, "");
    const hash = String(window.location.hash || "").toLowerCase();
    return path === "/study" || path.endsWith("/study") || hash.includes("study");
  }

  function findRoot() {
    return document.querySelector("#app")
      || document.querySelector("#root")
      || document.querySelector("main")
      || document.querySelector(".app-main")
      || document.body;
  }

  function pageLooksPublicSummary(root) {
    const text = String(root && root.innerText || "").toLowerCase();
    return text.includes("log in")
      && text.includes("create account")
      && !text.includes("deck")
      && !text.includes("card");
  }

  function readTokenCandidate(value) {
    if (!value) return "";
    const raw = String(value).trim();
    if (!raw) return "";

    if (raw.startsWith("eyJ") || raw.length > 40) {
      return raw.replace(/^Bearer\s+/i, "");
    }

    try {
      const data = JSON.parse(raw);
      const direct = data.access_token
        || data.accessToken
        || data.token
        || data.auth_token
        || data.authToken
        || (data.session && (data.session.access_token || data.session.accessToken || data.session.token))
        || "";
      if (direct) return String(direct).replace(/^Bearer\s+/i, "");
    } catch (err) {
      /* not JSON */
    }

    return "";
  }

  function findBearerToken() {
    const preferredKeys = [
      "access_token",
      "accessToken",
      "auth_token",
      "authToken",
      "token",
      "session",
      "auth",
      "aiPlatformSession",
      "ai_platform_session",
      "aiPlatformAuth",
      "ai_platform_auth",
      "edgeSession",
      "edgeAuthSession"
    ];

    try {
      for (const key of preferredKeys) {
        const token = readTokenCandidate(window.localStorage.getItem(key));
        if (token) return token;
      }

      for (let i = 0; i < window.localStorage.length; i += 1) {
        const key = window.localStorage.key(i);
        if (!key || !/token|auth|session/i.test(key)) continue;
        const token = readTokenCandidate(window.localStorage.getItem(key));
        if (token) return token;
      }
    } catch (err) {
      /* localStorage may be unavailable */
    }

    return "";
  }

  function authHeaders() {
    const headers = {
      "Content-Type": "application/json"
    };
    const token = findBearerToken();
    if (token) headers.Authorization = "Bearer " + token;
    return headers;
  }

  function setField(card, name, value) {
    const el = card.querySelector("[data-stage5p8a-field='" + name + "']");
    if (el) el.textContent = value || "—";
  }

  function setState(card, state, message) {
    card.dataset.sessionState = String(state || "unknown").toLowerCase();
    setField(card, "state", state || "unknown");
    setField(card, "message", message || "");
  }

  // STAGE_5P11G_STUDY_ANSWER_REVEAL_HELPER_BEGIN
  function updateAnswerPanel(card, session) {
    if (!card) return;

    const panel = card.querySelector("[data-stage5p11g-answer-panel]");
    const answerEl = card.querySelector("[data-stage5p11g-answer]");
    const explanationWrap = card.querySelector("[data-stage5p11g-explanation-wrap]");
    const explanationEl = card.querySelector("[data-stage5p11g-explanation]");

    if (!panel) return;

    const status = String((session && session.status) || "").toLowerCase();
    const currentCard = (session && session.current_card) || {};
    const answer = String(currentCard.answer || "").trim();
    const explanation = String(currentCard.explanation || "").trim();
    const shouldReveal = ["reviewing_answer", "waiting_for_mark"].includes(status) && !!answer;

    panel.hidden = !shouldReveal;

    if (answerEl) answerEl.textContent = shouldReveal ? answer : "—";

    if (explanationWrap) explanationWrap.hidden = !shouldReveal || !explanation;
    if (explanationEl) explanationEl.textContent = shouldReveal && explanation ? explanation : "—";
  }
  // STAGE_5P11G_STUDY_ANSWER_REVEAL_HELPER_END

  function renderCard(root) {
    if (!root || root.querySelector("#" + cardId)) return root && root.querySelector("#" + cardId);

    const card = document.createElement("section");
    card.id = cardId;
    card.className = "stage5p8a-study-session-card";
    card.setAttribute("aria-label", "Study session status");
    card.innerHTML = [
      '<div class="stage5p8a-study-session-head">',
      '  <div>',
      '    <p class="stage5p8a-eyebrow">Study session</p>',
      '    <h2>Session status</h2>',
      '    <p data-stage5p8a-field="message">Checking current session...</p>',
      '  </div>',
      '  <button type="button" class="stage5p8a-refresh" data-stage5p8a-refresh>Refresh</button>',
      '</div>',
      '<div class="stage5p8a-study-session-grid">',
      '  <div><span>Status</span><strong data-stage5p8a-field="state">checking</strong></div>',
      '  <div><span>Deck</span><strong data-stage5p8a-field="deck">—</strong></div>',
      '  <div class="stage5p11f-current-card"><span>Current question</span><strong data-stage5p8a-field="card">—</strong></div>',
      '  <div><span>Queue</span><strong data-stage5p8a-field="queue">—</strong></div>',
      '  <div><span>Last action</span><strong data-stage5p8a-field="lastAction">—</strong></div>',
      '  <div><span>Updated</span><strong data-stage5p8a-field="updated">—</strong></div>',
      '</div>',
      // STAGE_5P11G_STUDY_ANSWER_REVEAL_ACTIONS_BEGIN
      '<div class="stage5p11g-answer-panel" data-stage5p11g-answer-panel hidden>',
      '  <div><span>Answer</span><strong data-stage5p11g-answer>—</strong></div>',
      '  <div data-stage5p11g-explanation-wrap hidden><span>Explanation</span><p data-stage5p11g-explanation>—</p></div>',
      '</div>',
      // STAGE_5P11G_STUDY_ANSWER_REVEAL_ACTIONS_END
      '<p class="stage5p8a-study-session-note">Use the session actions below, or use natural Study phrases in Companion.</p>'
    ].join("");

    const first = root.firstElementChild;
    if (first) {
      root.insertBefore(card, first);
    } else {
      root.appendChild(card);
    }

    const refresh = card.querySelector("[data-stage5p8a-refresh]");
    if (refresh) {
      refresh.addEventListener("click", function () {
        loadStatus(card);
      });
    }

    return card;
  }

  async function loadStatus(card) {
    if (!card) return;

    setState(card, "checking", "Checking current session...");
    const refresh = card.querySelector("[data-stage5p8a-refresh]");
    if (refresh) refresh.disabled = true;

    try {
      const response = await fetch("/api/study/session/status", {
        method: "GET",
        headers: authHeaders(),
        credentials: "include"
      });

      const text = await response.text();
      let data = {};
      try {
        data = text ? JSON.parse(text) : {};
      } catch (err) {
        data = { raw: text };
      }

      if (response.status === 401 || response.status === 403) {
        setState(card, "signed out", "Log in to view durable Study session status.");
        setField(card, "deck", "—");
        setField(card, "card", "—");
        setField(card, "queue", "—");
        setField(card, "lastAction", "—");
        setField(card, "updated", "—");
        updateAnswerPanel(card, {});
        return;
      }

      if (!response.ok || data.ok === false) {
        setState(card, "error", data.detail || data.message || "Could not load Study session status.");
        return;
      }

      const session = data.session || {};
      const status = session.status || "none";
      const queuePosition = Number(session.queue_position || 0);
      const queueCount = Number(session.queue_count || 0);
      const queueLabel = queueCount ? String(queuePosition + 1) + " / " + String(queueCount) : "—";

      setState(card, status, status === "none" ? "No active durable Study session." : "Durable Study session is available.");
      setField(card, "deck", session.deck_id ? String(session.deck_id) : "—");
      // STAGE_5P11F_STUDY_CURRENT_CARD_QUESTION_FRONTEND_BEGIN
      const currentCard = session.current_card || {};
      const currentQuestion = String(currentCard.question || "").trim();
      setField(card, "card", currentQuestion || (session.current_card_id ? String(session.current_card_id) : "—"));
      // STAGE_5P11F_STUDY_CURRENT_CARD_QUESTION_FRONTEND_END
      setField(card, "queue", queueLabel);
      setField(card, "lastAction", session.last_action || session.last_intent || "—");
      setField(card, "updated", session.updated_at ? new Date(session.updated_at).toLocaleString() : "—");
      updateAnswerPanel(card, session);
    } catch (err) {
      setState(card, "offline", "Could not reach Study session status endpoint.");
      updateAnswerPanel(card, {});
    } finally {
      if (refresh) refresh.disabled = false;
    }
  }

  function enhanceStudyPage() {
    if (!isStudyRoute()) return;

    const root = findRoot();
    if (!root) return;

    if (pageLooksPublicSummary(root)) {
      const existing = root.querySelector("#" + cardId);
      if (existing) existing.remove();
      return;
    }

    const card = renderCard(root);
    if (!card) return;

    // STAGE_5P8F_REFRESH_LOOP_GUARD_BEGIN
    // Prevent status text mutations from causing MutationObserver -> enhance -> loadStatus loops.
    // Manual Refresh and command buttons still update the card when clicked.
    if (card.dataset.stage5p8aStatusLoaded === "true") return;
    card.dataset.stage5p8aStatusLoaded = "true";
    // STAGE_5P8F_REFRESH_LOOP_GUARD_END

    window.clearTimeout(refreshTimer);
    refreshTimer = window.setTimeout(function () {
      loadStatus(card);
    }, 150);
  }

  function installObserver() {
    if (observerInstalled) return;
    observerInstalled = true;

    const root = findRoot();
    if (!root || !window.MutationObserver) return;

    const observer = new MutationObserver(function () {
      if (isStudyRoute()) enhanceStudyPage();
    });

    observer.observe(root, {
      childList: true,
      subtree: true
    });
  }

  window.addEventListener("popstate", enhanceStudyPage);
  window.addEventListener("hashchange", enhanceStudyPage);
  document.addEventListener("DOMContentLoaded", function () {
    installObserver();
    enhanceStudyPage();
  });

  window.setTimeout(function () {
    installObserver();
    enhanceStudyPage();
  }, 300);
})();
 // STAGE_5P8A_STUDY_SESSION_STATUS_CARD_END


// STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN
(function () {
  const cardId = "stage5p8a-study-session-status-card";
  const controlsClass = "stage5p8c-study-session-controls";
  // STAGE_5P11B_STUDY_START_BUTTON_BEGIN
  const selectedDeckKey = "stage5p9aSelectedStudyDeckId";
  // STAGE_5P11B_STUDY_START_BUTTON_END
  let installing = false;

  function isStudyRoute() {
    const path = String(window.location.pathname || "").replace(/\/+$/, "");
    const hash = String(window.location.hash || "").toLowerCase();
    return path === "/study" || path.endsWith("/study") || hash.includes("study");
  }

  function findCard() {
    return document.getElementById(cardId);
  }

  function readTokenCandidate(value) {
    if (!value) return "";
    const raw = String(value).trim();
    if (!raw) return "";

    if (raw.startsWith("eyJ") || raw.length > 40) {
      return raw.replace(/^Bearer\s+/i, "");
    }

    try {
      const data = JSON.parse(raw);
      return String(
        data.access_token
        || data.accessToken
        || data.token
        || data.auth_token
        || data.authToken
        || (data.session && (data.session.access_token || data.session.accessToken || data.session.token))
        || ""
      ).replace(/^Bearer\s+/i, "");
    } catch (err) {
      return "";
    }
  }

  function findBearerToken() {
    const keys = [
      "access_token",
      "accessToken",
      "auth_token",
      "authToken",
      "token",
      "session",
      "auth",
      "aiPlatformSession",
      "ai_platform_session",
      "aiPlatformAuth",
      "ai_platform_auth",
      "edgeSession",
      "edgeAuthSession"
    ];

    try {
      for (const key of keys) {
        const token = readTokenCandidate(window.localStorage.getItem(key));
        if (token) return token;
      }

      for (let i = 0; i < window.localStorage.length; i += 1) {
        const key = window.localStorage.key(i);
        if (!key || !/token|auth|session/i.test(key)) continue;
        const token = readTokenCandidate(window.localStorage.getItem(key));
        if (token) return token;
      }
    } catch (err) {
      /* localStorage may be unavailable */
    }

    return "";
  }

  function authHeaders() {
    const headers = { "Content-Type": "application/json" };
    const token = findBearerToken();
    if (token) headers.Authorization = "Bearer " + token;
    return headers;
  }

  function setMessage(card, message) {
    const field = card && card.querySelector("[data-stage5p8a-field='message']");
    if (field) field.textContent = message || "";
  }

  function getState(card) {
    return String(card && card.dataset && card.dataset.sessionState || "unknown").toLowerCase();
  }

  function setBusy(card, busy) {
    if (!card) return;
    card.dataset.stage5p8cBusy = busy ? "true" : "false";
    card.querySelectorAll("[data-stage5p8c-command]").forEach(function (button) {
      button.disabled = !!busy || !button.dataset.stage5p8cEnabled;
    });
  }

  function updateButtonState(card) {
    // STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_BEGIN
    // Stopped/completed sessions must not lock the Study controls.
    // After Stop, the user should still be able to Start a new session. The top status-card Refresh remains available.
    if (!card) return;

    const state = String(card.dataset.sessionState || "none").toLowerCase();
    const busy = card.dataset.stage5p8cBusy === "true";

    const start = card.querySelector("[data-stage5p8c-command='start']");
    const readAnswer = card.querySelector("[data-stage5p8c-command='read-answer']");
    const correct = card.querySelector("[data-stage5p8c-command='correct']");
    const wrong = card.querySelector("[data-stage5p8c-command='wrong']");
    const skip = card.querySelector("[data-stage5p8c-command='skip']");
    const pause = card.querySelector("[data-stage5p8c-command='pause']");
    const resume = card.querySelector("[data-stage5p8c-command='resume']");
    const stop = card.querySelector("[data-stage5p8c-command='stop']");

    const activeStates = ["active", "reviewing_answer", "waiting_for_mark"];
    const answerStates = ["reviewing_answer", "waiting_for_mark"];
    const canPause = activeStates.includes(state);
    const canResume = state === "paused";
    const canStop = activeStates.includes(state) || state === "paused";
    const canStart = ["none", "stopped", "completed", "signed out", "error", "offline", "unknown"].includes(state);
    const canReadAnswer = state === "active";
    const canMark = answerStates.includes(state);
    const canSkip = activeStates.includes(state);

    if (start) start.disabled = busy || !canStart;
    if (readAnswer) readAnswer.disabled = busy || !canReadAnswer;
    if (correct) correct.disabled = busy || !canMark;
    if (wrong) wrong.disabled = busy || !canMark;
    if (skip) skip.disabled = busy || !canSkip;
    if (pause) pause.disabled = busy || !canPause;
    if (resume) resume.disabled = busy || !canResume;
    if (stop) stop.disabled = busy || !canStop;
    // STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_END
  }

  async function refreshStatus(card) {
    if (!card) return;
    const refresh = card.querySelector("[data-stage5p8c-command='refresh']");
    if (refresh) refresh.disabled = true;

    try {
      const response = await fetch("/api/study/session/status", {
        method: "GET",
        headers: authHeaders(),
        credentials: "include"
      });
      const data = await response.json().catch(function () { return {}; });

      if (response.status === 401 || response.status === 403) {
        card.dataset.sessionState = "signed out";
        setMessage(card, "Log in to view durable Study session status.");
        updateButtonState(card);
        return;
      }

      if (!response.ok || data.ok === false) {
        card.dataset.sessionState = "error";
        setMessage(card, data.detail || data.message || "Could not refresh Study session status.");
        updateButtonState(card);
        return;
      }

      const session = data.session || {};
      card.dataset.sessionState = String(session.status || "none").toLowerCase();

      const stateField = card.querySelector("[data-stage5p8a-field='state']");
      const deckField = card.querySelector("[data-stage5p8a-field='deck']");
      const cardField = card.querySelector("[data-stage5p8a-field='card']");
      const queueField = card.querySelector("[data-stage5p8a-field='queue']");
      const actionField = card.querySelector("[data-stage5p8a-field='lastAction']");
      const updatedField = card.querySelector("[data-stage5p8a-field='updated']");

      const queuePosition = Number(session.queue_position || 0);
      const queueCount = Number(session.queue_count || 0);

      if (stateField) stateField.textContent = session.status || "none";
      if (deckField) deckField.textContent = session.deck_id ? String(session.deck_id) : "—";
      // STAGE_5P11F_STUDY_CURRENT_CARD_QUESTION_REFRESH_BEGIN
      const currentCard = session.current_card || {};
      const currentQuestion = String(currentCard.question || "").trim();
      if (cardField) cardField.textContent = currentQuestion || (session.current_card_id ? String(session.current_card_id) : "—");
      // STAGE_5P11F_STUDY_CURRENT_CARD_QUESTION_REFRESH_END
      if (queueField) queueField.textContent = queueCount ? String(queuePosition + 1) + " / " + String(queueCount) : "—";
      if (actionField) actionField.textContent = session.last_action || session.last_intent || "—";
      if (updatedField) updatedField.textContent = session.updated_at ? new Date(session.updated_at).toLocaleString() : "—";

      if (typeof updateAnswerPanel === "function") updateAnswerPanel(card, session);

      setMessage(card, session.status === "none" ? "No active durable Study session." : "Durable Study session is available.");
      updateButtonState(card);
    } catch (err) {
      card.dataset.sessionState = "offline";
      setMessage(card, "Could not reach Study session status endpoint.");
      updateButtonState(card);
    } finally {
      if (refresh) refresh.disabled = false;
    }
  }

  // STAGE_5P11B_STUDY_START_BUTTON_LOGIC_BEGIN
  function selectedDeckId() {
    try {
      return String(window.localStorage.getItem(selectedDeckKey) || "").trim();
    } catch (err) {
      return "";
    }
  }

  async function startSession(card) {
    if (!card) return;

    const deckId = selectedDeckId();
    if (!deckId) {
      setMessage(card, "Choose a Study deck before starting a session.");
      return;
    }

    setBusy(card, true);
    setMessage(card, "Starting Study session...");

    try {
      const response = await fetch("/api/study/session/start", {
        method: "POST",
        headers: authHeaders(),
        credentials: "include",
        body: JSON.stringify({ deck_id: deckId })
      });

      const data = await response.json().catch(function () { return {}; });

      if (!response.ok || data.ok === false) {
        setMessage(card, data.detail || data.message || "Could not start Study session.");
        return;
      }

      const session = data.session || {};
      card.dataset.sessionState = String(session.status || "active").toLowerCase();
      setMessage(card, "Study session started.");
      await refreshStatus(card);
    } catch (err) {
      setMessage(card, "Could not reach Study session start endpoint.");
    } finally {
      setBusy(card, false);
      updateButtonState(card);
    }
  }
  // STAGE_5P11B_STUDY_START_BUTTON_LOGIC_END

  async function sendCommand(card, command, message) {
    if (!card) return;
    setBusy(card, true);
    setMessage(card, "Sending " + command + " command...");

    try {
      const response = await fetch("/api/study/session/command", {
        method: "POST",
        headers: authHeaders(),
        credentials: "include",
        body: JSON.stringify({ message: message })
      });

      const data = await response.json().catch(function () { return {}; });

      if (!response.ok || data.ok === false) {
        setMessage(card, data.detail || data.message || "Command failed.");
        return;
      }

      const session = data.session || {};
      card.dataset.sessionState = String(session.status || "none").toLowerCase();
      setMessage(card, "Command complete: " + command + ".");
      await refreshStatus(card);
    } catch (err) {
      setMessage(card, "Could not send Study session command.");
    } finally {
      setBusy(card, false);
      updateButtonState(card);
    }
  }

  function ensureControls(card) {
    if (!card || card.querySelector("." + controlsClass)) return;

    const controls = document.createElement("div");
    controls.className = controlsClass;
    controls.innerHTML = [
      '<button type="button" data-stage5p8c-command="start">Start</button>',
      // STAGE_5P11E_REMOVE_DUPLICATE_STUDY_REFRESH_BEGIN
      // The status card already has a top Refresh button, so the lower command row stays focused on session actions.
      // STAGE_5P11E_REMOVE_DUPLICATE_STUDY_REFRESH_END
      '<button type="button" data-stage5p8c-command="read-answer">Read answer</button>',
      '<button type="button" data-stage5p8c-command="correct">Correct</button>',
      '<button type="button" data-stage5p8c-command="wrong">Wrong</button>',
      '<button type="button" data-stage5p8c-command="skip">Skip</button>',
      '<button type="button" data-stage5p8c-command="pause">Pause</button>',
      '<button type="button" data-stage5p8c-command="resume">Resume</button>',
      '<button type="button" data-stage5p8c-command="stop">Stop</button>',
      '<p data-stage5p11b-start-note>Choose a deck below, then press Start. Use Read answer, Correct, Wrong, or Skip while reviewing.</p>'
    ].join("");

    const note = card.querySelector(".stage5p8a-study-session-note");
    if (note) {
      card.insertBefore(controls, note);
    } else {
      card.appendChild(controls);
    }

    const start = controls.querySelector("[data-stage5p8c-command='start']");
    const readAnswer = controls.querySelector("[data-stage5p8c-command='read-answer']");
    const correct = controls.querySelector("[data-stage5p8c-command='correct']");
    const wrong = controls.querySelector("[data-stage5p8c-command='wrong']");
    const skip = controls.querySelector("[data-stage5p8c-command='skip']");
    const pause = controls.querySelector("[data-stage5p8c-command='pause']");
    const resume = controls.querySelector("[data-stage5p8c-command='resume']");
    const stop = controls.querySelector("[data-stage5p8c-command='stop']");

    if (start) start.addEventListener("click", function () { startSession(card); });
    if (readAnswer) readAnswer.addEventListener("click", function () { sendCommand(card, "read answer", "Read the answer"); });
    if (correct) correct.addEventListener("click", function () { sendCommand(card, "correct", "Correct"); });
    if (wrong) wrong.addEventListener("click", function () { sendCommand(card, "wrong", "Wrong"); });
    if (skip) skip.addEventListener("click", function () { sendCommand(card, "skip", "Skip"); });
    if (pause) pause.addEventListener("click", function () { sendCommand(card, "pause", "Study Session Pause"); });
    if (resume) resume.addEventListener("click", function () { sendCommand(card, "resume", "Study Session Resume"); });
    if (stop) stop.addEventListener("click", function () { sendCommand(card, "stop", "Study Session Stop"); });

    updateButtonState(card);
  }

  function enhance() {
    if (!isStudyRoute()) return;
    const card = findCard();
    if (!card) return;
    ensureControls(card);
    updateButtonState(card);
  }

  function install() {
    if (installing) return;
    installing = true;

    enhance();

    if (window.MutationObserver) {
      const observer = new MutationObserver(function () {
        enhance();
      });
      observer.observe(document.body, { childList: true, subtree: true });
    }

    window.addEventListener("popstate", enhance);
    window.addEventListener("hashchange", enhance);
    // STAGE_5P8F_CONTROL_INTERVAL_GUARD_BEGIN
    // Keep button state updated, but avoid unnecessary rapid background UI churn.
    window.setInterval(function () {
      const card = findCard();
      if (isStudyRoute() && card) updateButtonState(card);
    }, 10000);
    // STAGE_5P8F_CONTROL_INTERVAL_GUARD_END
  }

  document.addEventListener("DOMContentLoaded", install);
  window.setTimeout(install, 500);
})();
 // STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_END


// STAGE_5P9A_STUDY_DECK_SELECTOR_BEGIN
(function () {
  const statusCardId = "stage5p8a-study-session-status-card";
  const selectorClass = "stage5p9a-study-deck-selector";
  const selectedDeckKey = "stage5p9aSelectedStudyDeckId";
  let installed = false;

  function isStudyRoute() {
    const path = String(window.location.pathname || "").replace(/\/+$/, "");
    const hash = String(window.location.hash || "").toLowerCase();
    return path === "/study" || path.endsWith("/study") || hash.includes("study");
  }

  function findStatusCard() {
    return document.getElementById(statusCardId);
  }

  function readTokenCandidate(value) {
    if (!value) return "";
    const raw = String(value).trim();
    if (!raw) return "";
    if (raw.startsWith("eyJ") || raw.length > 40) return raw.replace(/^Bearer\s+/i, "");

    try {
      const data = JSON.parse(raw);
      return String(
        data.access_token
        || data.accessToken
        || data.token
        || data.auth_token
        || data.authToken
        || (data.session && (data.session.access_token || data.session.accessToken || data.session.token))
        || ""
      ).replace(/^Bearer\s+/i, "");
    } catch (err) {
      return "";
    }
  }

  function findBearerToken() {
    // STAGE_5P11C_STUDY_DECK_SELECTOR_AUTH_REPAIR_BEGIN
    // Prefer the wrapper's canonical logged-in token first. The deck selector
    // was using an older generic token scan, which could miss the active
    // edgeStudyToken session used by the rest of the wrapper.
    try {
      const directAuthStateToken = (
        typeof authState !== "undefined"
        && authState
        && authState.token
      ) ? String(authState.token || "").trim() : "";
      if (directAuthStateToken) return directAuthStateToken.replace(/^Bearer\s+/i, "");

      const edgeStudyToken = readTokenCandidate(window.localStorage.getItem("edgeStudyToken"));
      if (edgeStudyToken) return edgeStudyToken;
    } catch (err) {
      /* authState/localStorage may be unavailable */
    }
    // STAGE_5P11C_STUDY_DECK_SELECTOR_AUTH_REPAIR_END

    const keys = [
      "edgeStudyToken",
      "access_token",
      "accessToken",
      "auth_token",
      "authToken",
      "token",
      "session",
      "auth",
      "aiPlatformSession",
      "ai_platform_session",
      "aiPlatformAuth",
      "ai_platform_auth",
      "edgeSession",
      "edgeAuthSession"
    ];

    try {
      for (const key of keys) {
        const token = readTokenCandidate(window.localStorage.getItem(key));
        if (token) return token;
      }

      for (let i = 0; i < window.localStorage.length; i += 1) {
        const key = window.localStorage.key(i);
        if (!key || !/token|auth|session|edgeStudy/i.test(key)) continue;
        const token = readTokenCandidate(window.localStorage.getItem(key));
        if (token) return token;
      }
    } catch (err) {
      /* localStorage may be unavailable */
    }

    return "";
  }

  function authHeaders() {
    const headers = { "Content-Type": "application/json" };
    const token = findBearerToken();
    if (token) headers.Authorization = "Bearer " + token;
    return headers;
  }

  function normalizeDecks(data) {
    if (!data || typeof data !== "object") return [];
    const candidates = [
      data.decks,
      data.items,
      data.results,
      data.data,
      data.study_decks,
      data.studyDecks
    ];

    for (const candidate of candidates) {
      if (Array.isArray(candidate)) return candidate;
      if (candidate && Array.isArray(candidate.decks)) return candidate.decks;
      if (candidate && Array.isArray(candidate.items)) return candidate.items;
    }

    return [];
  }

  function deckId(deck) {
    return deck && (deck.id || deck.deck_id || deck.deckId || "");
  }

  function deckTitle(deck) {
    return String(
      (deck && (deck.title || deck.name || deck.deck_name || deck.deckName))
      || ("Deck " + deckId(deck))
    );
  }

  function selectedDeckId() {
    try {
      return window.localStorage.getItem(selectedDeckKey) || "";
    } catch (err) {
      return "";
    }
  }

  function setSelectedDeckId(id) {
    try {
      if (id) window.localStorage.setItem(selectedDeckKey, String(id));
      else window.localStorage.removeItem(selectedDeckKey);
    } catch (err) {
      /* storage may be unavailable */
    }
  }

  function setSelectorMessage(shell, message) {
    const el = shell && shell.querySelector("[data-stage5p9a-message]");
    if (el) el.textContent = message || "";
  }

  function setSelectedLabel(shell, deck) {
    const el = shell && shell.querySelector("[data-stage5p9a-selected]");
    if (!el) return;

    if (!deck) {
      const id = selectedDeckId();
      el.textContent = id ? ("Selected deck id: " + id) : "No deck selected.";
      return;
    }

    el.textContent = "Selected: " + deckTitle(deck) + " (#" + deckId(deck) + ")";
  }

  function renderDeckOptions(shell, decks) {
    const list = shell.querySelector("[data-stage5p9a-list]");
    if (!list) return;

    list.innerHTML = "";

    if (!decks.length) {
      const empty = document.createElement("p");
      empty.className = "stage5p9a-empty";
      empty.textContent = "No decks found yet. Create or import a Study deck first.";
      list.appendChild(empty);
      setSelectedLabel(shell, null);
      return;
    }

    const current = selectedDeckId();
    let selectedDeck = null;

    decks.forEach(function (deck) {
      const id = String(deckId(deck));
      if (!id) return;

      if (String(current) === id) selectedDeck = deck;

      const button = document.createElement("button");
      button.type = "button";
      button.className = "stage5p9a-deck-option";
      button.dataset.stage5p9aDeckId = id;
      button.textContent = deckTitle(deck) + " (#" + id + ")";
      button.setAttribute("aria-pressed", String(String(current) === id));

      button.addEventListener("click", function () {
        setSelectedDeckId(id);
        shell.querySelectorAll(".stage5p9a-deck-option").forEach(function (other) {
          other.setAttribute("aria-pressed", String(other.dataset.stage5p9aDeckId === id));
        });
        setSelectedLabel(shell, deck);
        setSelectorMessage(shell, "Deck selected. Press Start to begin.");
      });

      list.appendChild(button);
    });

    setSelectedLabel(shell, selectedDeck);
  }

  async function loadDecks(shell) {
    if (!shell) return;

    const refresh = shell.querySelector("[data-stage5p9a-refresh]");
    if (refresh) refresh.disabled = true;
    setSelectorMessage(shell, "Loading decks...");

    try {
      const response = await fetch("/api/study/decks", {
        method: "GET",
        headers: authHeaders(),
        credentials: "include"
      });

      const data = await response.json().catch(function () { return {}; });

      if (response.status === 401 || response.status === 403) {
        setSelectorMessage(shell, "Log in to load your Study decks.");
        renderDeckOptions(shell, []);
        return;
      }

      if (!response.ok || data.ok === false) {
        setSelectorMessage(shell, data.detail || data.message || "Could not load decks.");
        renderDeckOptions(shell, []);
        return;
      }

      const decks = normalizeDecks(data);
      renderDeckOptions(shell, decks);
      setSelectorMessage(shell, decks.length ? ("Loaded " + decks.length + " deck" + (decks.length === 1 ? "" : "s") + ". Choose one, then press Start.") : "No decks found.");
    } catch (err) {
      setSelectorMessage(shell, "Could not reach Study deck endpoint.");
      renderDeckOptions(shell, []);
    } finally {
      if (refresh) refresh.disabled = false;
    }
  }

  function ensureSelector() {
    if (!isStudyRoute()) return;

    const card = findStatusCard();
    if (!card || card.querySelector("." + selectorClass)) return;

    const shell = document.createElement("section");
    shell.className = selectorClass;
    shell.innerHTML = [
      '<div class="stage5p9a-head">',
      '  <div>',
      '    <p class="stage5p9a-eyebrow">Deck selector</p>',
      '    <h3>Choose a deck for Start</h3>',
      '    <p data-stage5p9a-message>Choose a deck, then press Start.</p>',
      '  </div>',
      '  <button type="button" data-stage5p9a-refresh>Load decks</button>',
      '</div>',
      '<div class="stage5p9a-selected" data-stage5p9a-selected>No deck selected.</div>',
      '<div class="stage5p9a-list" data-stage5p9a-list></div>',
      '<p class="stage5p9a-note">Start uses the selected deck id to create a durable Study session.</p>'
    ].join("");

    card.appendChild(shell);

    const refresh = shell.querySelector("[data-stage5p9a-refresh]");
    if (refresh) refresh.addEventListener("click", function () { loadDecks(shell); });

    window.setTimeout(function () {
      loadDecks(shell);
    }, 250);
  }

  function install() {
    if (installed) return;
    installed = true;

    ensureSelector();

    if (window.MutationObserver) {
      const observer = new MutationObserver(function () {
        if (isStudyRoute()) ensureSelector();
      });
      observer.observe(document.body, { childList: true, subtree: true });
    }

    window.addEventListener("popstate", ensureSelector);
    window.addEventListener("hashchange", ensureSelector);
  }

  document.addEventListener("DOMContentLoaded", install);
  window.setTimeout(install, 700);
})();
 // STAGE_5P9A_STUDY_DECK_SELECTOR_END

// STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1
// Passive, disabled-by-default observer. This must never call the router while
// EdgeRouterShadowRead.ROUTER_SHADOW_READ_ENABLED is false.
function stage8lObserveRouterShadowReadDisabled(payload) {
  try {
    const shadow = window && window.EdgeRouterShadowRead ? window.EdgeRouterShadowRead : null;

    if (!shadow || shadow.ROUTER_SHADOW_READ_ENABLED !== true) {
      return {
        ok: false,
        skipped: true,
        reason: "router_shadow_read_disabled",
        dispatch_performed: false,
        allowed_to_dispatch: false,
        would_dispatch: false,
      };
    }

    const routerPayload = shadow.buildRouterShadowReadPayload(payload);

    return shadow.routerShadowRead(
      function stage8lDisabledRouterApiGuard() {
        throw new Error("Stage 8L router API guard: router calls are not allowed while disabled");
      },
      routerPayload
    ).catch(function stage8lRouterShadowReadCatch(error) {
      return {
        ok: false,
        skipped: true,
        reason: "router_shadow_read_error",
        error: error && error.message ? error.message : "unknown",
        dispatch_performed: false,
        allowed_to_dispatch: false,
        would_dispatch: false,
      };
    });
  } catch (error) {
    return {
      ok: false,
      skipped: true,
      reason: "router_shadow_read_unavailable",
      error: error && error.message ? error.message : "unknown",
      dispatch_performed: false,
      allowed_to_dispatch: false,
      would_dispatch: false,
    };
  }
}

// Stage 9D disabled narrow browser-surface router shadow-read wiring.
// This bridge intentionally stays disabled by default. It never stores the
// backend endpoint in app.js; endpoint ownership remains in router_shadow_read_stub.js.
(function () {
  "use strict";

  const ROUTER_SHADOW_READ_SURFACE_ALLOWLIST = Object.freeze([
    "manual-diagnostic",
    "study-card-action"
  ]);

  const ROUTER_SHADOW_READ_DEFAULT_REASON = "router_shadow_read_surface_disabled";

  function getRouterShadowReadNamespace() {
    if (typeof window === "undefined") {
      return null;
    }

    return window.EdgeRouterShadowRead || null;
  }

  function browserSurfaceShadowReadEnabled(surface) {
    const shadow = getRouterShadowReadNamespace();

    if (!shadow) {
      return false;
    }

    if (shadow.ROUTER_SHADOW_READ_ENABLED !== true) {
      return false;
    }

    if (shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT !== true) {
      return false;
    }

    if (!ROUTER_SHADOW_READ_SURFACE_ALLOWLIST.includes(String(surface || ""))) {
      return false;
    }

    if (typeof shadow.sendRouterDryRunShadowRead !== "function") {
      return false;
    }

    return true;
  }

  function buildBrowserSurfaceShadowReadInput(surface, input) {
    const value = input && typeof input === "object" ? input : {};

    return {
      text: String(value.text || ""),
      source: String(value.source || "browser-surface-shadow-read"),
      surface: String(surface || value.surface || "unknown-surface"),
      route_hint: value.route_hint || null,
      dry_run: true,
      dispatch_requested: false,
      dispatch_performed: false
    };
  }

  async function requestBrowserSurfaceRouterShadowRead(surface, input, options) {
    const normalizedSurface = String(surface || "");
    const shadow = getRouterShadowReadNamespace();

    if (!browserSurfaceShadowReadEnabled(normalizedSurface)) {
      return {
        ok: true,
        skipped: true,
        reason: ROUTER_SHADOW_READ_DEFAULT_REASON,
        surface: normalizedSurface,
        dispatch_requested: false,
        dispatch_performed: false
      };
    }

    const opts = options && typeof options === "object" ? options : {};
    const request = buildBrowserSurfaceShadowReadInput(normalizedSurface, input);

    if (request.dry_run !== true ||
        request.dispatch_requested !== false ||
        request.dispatch_performed !== false) {
      return {
        ok: false,
        skipped: true,
        reason: "router_shadow_read_invalid_non_dispatch_contract",
        surface: normalizedSurface,
        dispatch_requested: false,
        dispatch_performed: false
      };
    }

    return shadow.sendRouterDryRunShadowRead(request, opts);
  }

  if (typeof window !== "undefined") {
    window.EdgeRouterShadowReadSurface = Object.assign(
      {},
      window.EdgeRouterShadowReadSurface || {},
      {
        ROUTER_SHADOW_READ_SURFACE_ALLOWLIST,
        ROUTER_SHADOW_READ_DEFAULT_REASON,
        browserSurfaceShadowReadEnabled,
        buildBrowserSurfaceShadowReadInput,
        requestBrowserSurfaceRouterShadowRead
      }
    );
  }
})();
// End Stage 9D disabled narrow browser-surface router shadow-read wiring.

// Stage 9K disabled operator-gated browser shadow-read activation boundary.
// This wraps the Stage 9D browser-surface bridge with an operator gate that
// remains false by default. It does not store the backend endpoint in app.js.
(function () {
  "use strict";

  const OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false;
  const OPERATOR_BROWSER_SHADOW_READ_DEFAULT_REASON = "operator_browser_shadow_read_activation_disabled";

  function getOperatorGateNamespace() {
    if (typeof window === "undefined") {
      return null;
    }

    return window.EdgeRouterShadowReadOperatorGate || null;
  }

  function getBrowserSurfaceNamespace() {
    if (typeof window === "undefined") {
      return null;
    }

    return window.EdgeRouterShadowReadSurface || null;
  }

  function operatorBrowserShadowReadActivationEnabled() {
    const gate = getOperatorGateNamespace();

    return !!(
      gate &&
      gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED === true
    );
  }

  function buildOperatorGateSkip(surface) {
    return {
      ok: true,
      skipped: true,
      reason: OPERATOR_BROWSER_SHADOW_READ_DEFAULT_REASON,
      surface: String(surface || ""),
      dry_run: true,
      dispatch_requested: false,
      dispatch_performed: false
    };
  }

  if (typeof window !== "undefined") {
    window.EdgeRouterShadowReadOperatorGate = Object.assign(
      {},
      window.EdgeRouterShadowReadOperatorGate || {},
      {
        OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED,
        OPERATOR_BROWSER_SHADOW_READ_DEFAULT_REASON,
        operatorBrowserShadowReadActivationEnabled
      }
    );

    const surface = getBrowserSurfaceNamespace();

    if (surface &&
        typeof surface.requestBrowserSurfaceRouterShadowRead === "function" &&
        surface.__stage9kOperatorGateWrapped !== true) {
      const originalRequestBrowserSurfaceRouterShadowRead =
        surface.requestBrowserSurfaceRouterShadowRead;

      surface.requestBrowserSurfaceRouterShadowRead =
        async function requestOperatorGatedBrowserSurfaceRouterShadowRead(surfaceName, input, options) {
          if (!operatorBrowserShadowReadActivationEnabled()) {
            return buildOperatorGateSkip(surfaceName);
          }

          return originalRequestBrowserSurfaceRouterShadowRead.call(
            this,
            surfaceName,
            input,
            options
          );
        };

      surface.__stage9kOperatorGateWrapped = true;
    }
  }
})();
// End Stage 9K disabled operator-gated browser shadow-read activation boundary.

// Stage 9R disabled persistent operator-gated rollout boundary.
// This boundary reserves the persistent rollout layer while keeping all
// persistent activation state false by default. It does not store the backend
// router dry-run endpoint in app.js.
(function () {
  "use strict";

  const PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false;
  const PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS = "disabled";
  const PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON =
    "persistent_operator_gated_rollout_disabled";
  const PERSISTENT_OPERATOR_GATED_ROLLOUT_ALLOWED_SURFACES = [
    "manual-diagnostic"
  ];

  function getPersistentRolloutNamespace() {
    if (typeof window === "undefined") {
      return null;
    }

    return window.EdgeRouterShadowReadPersistentRollout || null;
  }

  function getOperatorGateNamespace() {
    if (typeof window === "undefined") {
      return null;
    }

    return window.EdgeRouterShadowReadOperatorGate || null;
  }

  function persistentOperatorGatedRolloutEnabled(surface) {
    const rollout = getPersistentRolloutNamespace();
    const gate = getOperatorGateNamespace();
    const surfaceName = String(surface || "");

    return !!(
      rollout &&
      rollout.PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED === true &&
      rollout.PERSISTENT_OPERATOR_GATED_ROLLOUT_ALLOWED_SURFACES.indexOf(surfaceName) !== -1 &&
      gate &&
      gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED === true
    );
  }

  function buildPersistentRolloutSkip(surface) {
    return {
      ok: true,
      skipped: true,
      reason: PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON,
      status: PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS,
      surface: String(surface || ""),
      dry_run: true,
      dispatch_requested: false,
      dispatch_performed: false
    };
  }

  if (typeof window !== "undefined") {
    window.EdgeRouterShadowReadPersistentRollout = Object.assign(
      {},
      window.EdgeRouterShadowReadPersistentRollout || {},
      {
        PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED,
        PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS,
        PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON,
        PERSISTENT_OPERATOR_GATED_ROLLOUT_ALLOWED_SURFACES,
        persistentOperatorGatedRolloutEnabled,
        buildPersistentRolloutSkip
      }
    );
  }
})();
// End Stage 9R disabled persistent operator-gated rollout boundary.


/* APC_PUBLIC_STUDY_SIGNED_OUT_GUARD_FC_O44_D
 * Public signed-out Study safety guard.
 *
 * Signed-out visitors should see only the public Study overview and sign-in prompt.
 * Durable Study session state, selected deck identifiers, deck selector state, queue
 * fields, and review controls are authenticated UI only.
 */
(function apcPublicStudySignedOutGuardFcO44D() {
  "use strict";

  const publicBannerText = "Under Construction: Some features do not work yet.";
  const signedOutNeedles = [
    "Sign in from the header",
    "Log in to view durable Study session status.",
    "Log in to load your Study decks.",
    "Statussigned out",
    "Status signed out"
  ];
  const privateStudyNeedles = [
    "Study session",
    "Session status",
    "Selected deck id:",
    "No decks found",
    "No decks found yet.",
    "Deck selector",
    "Start uses the selected deck id",
    "Current question",
    "Last action",
    "Read answer",
    "Correct",
    "Wrong",
    "Skip"
  ];

  function isSignedOutStudySurface() {
    const text = (document.body && document.body.innerText) || "";
    if (!/Study/i.test(text)) return false;
    return signedOutNeedles.some((needle) => text.indexOf(needle) !== -1);
  }

  function closestSafePanel(node) {
    let cur = node;
    for (let i = 0; cur && i < 8; i += 1, cur = cur.parentElement) {
      if (!cur || cur === document.body || cur === document.documentElement) continue;
      const text = (cur.innerText || cur.textContent || "").trim();
      if (!text) continue;
      if (text.length < 2600 && /Study session|Session status|Deck selector|Selected deck id|No decks found|Start uses the selected deck id|Current question|Last action/.test(text)) {
        return cur;
      }
    }
    return null;
  }

  function hidePrivateStudyPanels() {
    if (!isSignedOutStudySurface()) return;

    const candidates = Array.from(document.querySelectorAll("section, article, div, aside, form, ul, p, h1, h2, h3, h4, button, label, span"));
    for (const el of candidates) {
      const text = (el.innerText || el.textContent || "").trim();
      if (!text) continue;
      if (!privateStudyNeedles.some((needle) => text.indexOf(needle) !== -1)) continue;
      const panel = closestSafePanel(el);
      if (panel) {
        panel.setAttribute("data-apc-public-study-hidden", "true");
        panel.style.display = "none";
        panel.setAttribute("aria-hidden", "true");
      }
    }

    const selectedDeckNodes = Array.from(document.querySelectorAll("[id], [class], [aria-label]"));
    for (const el of selectedDeckNodes) {
      const text = (el.innerText || el.textContent || "").trim();
      if (/Selected deck id:|No deck selected|No decks found|Start uses the selected deck id/.test(text)) {
        const panel = closestSafePanel(el) || el;
        panel.setAttribute("data-apc-public-study-hidden", "true");
        panel.style.display = "none";
        panel.setAttribute("aria-hidden", "true");
      }
    }
  }

  function patchBannerCopy() {
    const banner = document.getElementById("apc-under-construction-banner");
    if (banner && banner.textContent !== publicBannerText) {
      banner.textContent = publicBannerText;
    }
  }

  function runGuard() {
    patchBannerCopy();
    hidePrivateStudyPanels();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", runGuard);
  } else {
    runGuard();
  }

  const observer = new MutationObserver(runGuard);
  observer.observe(document.documentElement || document.body, { childList: true, subtree: true, characterData: true });
  window.addEventListener("hashchange", () => setTimeout(runGuard, 0));
  window.addEventListener("popstate", () => setTimeout(runGuard, 0));
})();


/*
 * APC_STUDY_SIGNED_IN_REPAIR_FC_O45_C_C
 *
 * Product-surface repair only:
 * - Keeps durable Study session/deck selector UI.
 * - Removes the duplicated legacy Study block when it is embedded under signed-in Study.
 * - Restores signed-in Decks, Cards, Stats, and Review Queue panels from existing Study APIs.
 * - Skips signed-out users so public Study remains private-data safe.
 */
(() => {
  const MARKER = "APC_STUDY_SIGNED_IN_REPAIR_FC_O45_C_C";
  const PANEL_ID = "apc-study-signed-in-tools-fc-o45-c-c";
  let repairTimer = null;
  let lastDeckId = null;

  function esc(value) {
    return String(value ?? "").replace(/[&<>"']/g, (ch) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      "\"": "&quot;",
      "'": "&#39;",
    }[ch]));
  }

  function textOf(el) {
    return (el && el.textContent ? el.textContent : "").replace(/\s+/g, " ").trim();
  }

  function isProbablyStudyPage() {
    const bodyText = textOf(document.body);
    return bodyText.includes("Study session")
      || bodyText.includes("Deck selector")
      || bodyText.includes("No active durable Study session")
      || bodyText.includes("Create decks, add cards, review by difficulty");
  }

  async function apiJson(path) {
    /* APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K: prefer wrapper api() so signed-in Study calls carry auth headers. */
    if (typeof api === "function" && typeof path === "string" && path.startsWith("/api/")) {
      try {
        const apiPath = path.slice(4);
        const data = await api(apiPath, { method: "GET" });
        const status = Number(data?.status || data?.status_code || 200) || 200;
        const ok = !(data && data.ok === false) && status < 400;
        return { ok, status, data };
      } catch (error) {
        const status = Number(error?.status || error?.response?.status || error?.data?.status || 0) || 0;
        return {
          ok: false,
          status,
          data: { detail: error?.message || "Study API unavailable" },
        };
      }
    }
    const response = await fetch(path, {
      credentials: "include",
      headers: { "Accept": "application/json" },
    });
    const text = await response.text();
    let data = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch (_) {
      data = { raw: text };
    }
    return { ok: response.ok, status: response.status, data };
  }

  async function currentUserIsSignedIn() {
    try {
      const me = await apiJson("/api/me");
      return me.ok && !!me.data && (me.data.id || me.data.email || me.data.user);
    } catch (_) {
      return false;
    }
  }

  function removeDuplicatedLegacyStudyBlock() {
    const candidates = Array.from(document.querySelectorAll("section, article, main > div, .card, .panel, div"));
    for (const el of candidates) {
      if (el.id === PANEL_ID) continue;
      const t = textOf(el);
      const hasLegacyIntro = t.includes("Create decks, add cards, review by difficulty")
        || t.includes("track progress from the shared wrapper layout");
      const hasDurablePanel = t.includes("Study session") || t.includes("Deck selector") || t.includes("No active durable Study session");
      const isLargePageShell = t.includes("Companion") && t.includes("Profile") && t.includes("System") && t.length > 600;

      if (hasLegacyIntro && !hasDurablePanel && !isLargePageShell) {
        el.setAttribute("data-apc-study-legacy-hidden", MARKER);
        el.hidden = true;
        el.style.display = "none";
      }
    }
  }

  function findStudyMount() {
    const existing = document.getElementById(PANEL_ID);
    if (existing) return existing;

    const headings = Array.from(document.querySelectorAll("h1, h2, h3, strong, div, section"));
    let anchor = headings.find((el) => textOf(el).includes("Deck selector"))
      || headings.find((el) => textOf(el).includes("Study session"))
      || headings.find((el) => textOf(el).includes("No active durable Study session"));

    let container = anchor;
    for (let i = 0; i < 4 && container && container.parentElement; i += 1) {
      const t = textOf(container);
      if (t.includes("Study session") || t.includes("Deck selector")) break;
      container = container.parentElement;
    }

    const panel = document.createElement("section");
    panel.id = PANEL_ID;
    panel.className = "card apc-study-tools";
    panel.setAttribute("data-apc-marker", MARKER);
    panel.innerHTML = `
      <h2>Study tools</h2>
      <p class="muted">Decks, cards, stats, and review queue are loaded from your signed-in Study account.</p>
      <div class="grid two">
        <section class="mini-summary" id="apcStudyDecksPanel"><strong>Decks</strong><p class="muted">Loading decks…</p></section>
        <section class="mini-summary" id="apcStudyStatsPanel"><strong>Stats</strong><p class="muted">Loading progress…</p></section>
      </div>
      <div class="grid two">
        <section class="mini-summary" id="apcStudyCardsPanel"><strong>Cards</strong><p class="muted">Choose a deck to load cards.</p></section>
        <section class="mini-summary" id="apcStudyReviewPanel"><strong>Review queue</strong><p class="muted">Choose a deck to load the review queue.</p></section>
      </div>
    `;

    if (container && container.parentNode) {
      container.insertAdjacentElement("afterend", panel);
    } else {
      document.body.appendChild(panel);
    }
    return panel;
  }

  function deckIdFromExistingUi() {
    const bodyText = textOf(document.body);
    const selected = bodyText.match(/Selected:\s*[^#]+#(\d+)/i);
    if (selected) return selected[1];
    const hash = bodyText.match(/deck\s*#(\d+)/i);
    if (hash) return hash[1];
    return null;
  }

  function renderDecks(payload) {
    const panel = document.getElementById("apcStudyDecksPanel");
    if (!panel) return null;

    const decks = Array.isArray(payload?.decks) ? payload.decks : [];
    if (!decks.length) {
      panel.innerHTML = `<strong>Decks</strong><p class="muted">No decks were returned for this account yet.</p>`;
      return null;
    }

    const selectedId = lastDeckId || deckIdFromExistingUi() || String(decks[0].id);
    lastDeckId = selectedId;

    const items = decks.slice(0, 8).map((deck) => {
      const active = String(deck.id) === String(selectedId) ? " selected" : "";
      const title = esc(deck.title || deck.name || `Deck #${deck.id}`);
      const count = deck.card_count ?? deck.cards_count ?? deck.total_cards ?? "—";
      return `<li><button type="button" class="secondary apc-study-deck-choice${active}" data-apc-study-deck-id="${esc(deck.id)}">${title}</button> <span class="muted">${esc(count)} cards</span></li>`;
    }).join("");

    panel.innerHTML = `
      <strong>Decks</strong>
      <p class="muted">${esc(payload.count ?? decks.length)} deck(s) available. Selected deck #${esc(selectedId)}.</p>
      <ul>${items}</ul>
    `;

    panel.querySelectorAll("[data-apc-study-deck-id]").forEach((btn) => {
      btn.addEventListener("click", () => {
        lastDeckId = btn.getAttribute("data-apc-study-deck-id");
        loadStudyTools(lastDeckId);
      });
    });

    return selectedId;
  }

  function renderStats(payload) {
    const panel = document.getElementById("apcStudyStatsPanel");
    if (!panel) return;

    const totals = payload?.totals || payload?.summary || payload || {};
    const totalDecks = totals.total_decks ?? payload?.deck_count ?? "—";
    const totalCards = totals.total_cards ?? payload?.card_count ?? "—";
    const totalReviews = totals.total_reviews ?? payload?.review_count ?? "—";
    const accuracy = totals.accuracy === null || totals.accuracy === undefined
      ? "—"
      : `${Math.round(Number(totals.accuracy) * 100)}%`;

    panel.innerHTML = `
      <strong>Stats</strong>
      <dl>
        <dt>Decks</dt><dd>${esc(totalDecks)}</dd>
        <dt>Cards</dt><dd>${esc(totalCards)}</dd>
        <dt>Reviews</dt><dd>${esc(totalReviews)}</dd>
        <dt>Accuracy</dt><dd>${esc(accuracy)}</dd>
      </dl>
    `;
  }

  function renderCards(payload, deckId) {
    const panel = document.getElementById("apcStudyCardsPanel");
    if (!panel) return;

    const cards = Array.isArray(payload?.cards) ? payload.cards : [];
    if (!cards.length) {
      panel.innerHTML = `<strong>Cards</strong><p class="muted">No cards returned for deck #${esc(deckId)}.</p>`;
      return;
    }

    const items = cards.slice(0, 6).map((card) => {
      const question = esc(card.question || card.front || card.prompt || `Card #${card.id}`);
      const answer = esc(card.answer || card.back || "");
      return `<li><strong>${question}</strong>${answer ? `<br><span class="muted">${answer}</span>` : ""}</li>`;
    }).join("");

    panel.innerHTML = `
      <strong>Cards</strong>
      <p class="muted">${esc(payload.count ?? cards.length)} card(s) in deck #${esc(deckId)}.</p>
      <ul>${items}</ul>
    `;
  }

  function renderReview(payload, deckId) {
    const panel = document.getElementById("apcStudyReviewPanel");
    if (!panel) return;

    const queue = Array.isArray(payload?.queue) ? payload.queue
      : Array.isArray(payload?.cards) ? payload.cards
      : [];
    if (!queue.length) {
      panel.innerHTML = `<strong>Review queue</strong><p class="muted">No review cards returned for deck #${esc(deckId)}.</p>`;
      return;
    }

    const card = queue[0];
    const q = esc(card.question || card.front || card.prompt || `Card #${card.id}`);
    const bucket = esc(card.performance_bucket || card.bucket || "balanced");

    panel.innerHTML = `
      <strong>Review queue</strong>
      <p class="muted">${esc(queue.length)} card(s) queued. First bucket: ${bucket}.</p>
      <p><strong>${q}</strong></p>
      <div class="actions">
        <button type="button" disabled>Read answer</button>
        <button type="button" disabled>Correct</button>
        <button type="button" disabled>Wrong</button>
        <button type="button" disabled>Skip</button>
      </div>
      <p class="muted">Review action buttons are visible here; durable session actions above remain the active controls.</p>
    `;
  }

  async function loadStudyTools(deckIdOverride) {
    const panel = findStudyMount();
    if (!panel) return;

    const decksResult = await apiJson("/api/study/decks");
    if (!decksResult.ok) {
      panel.innerHTML = `
        <h2>Study tools</h2>
        <p class="muted">Study tools are available after signing in. Deck/card data was not loaded.</p>
      `;
      return;
    }

    const selectedDeckId = renderDecks(decksResult.data) || deckIdOverride;
    const progress = await apiJson("/api/study/progress");
    if (progress.ok) {
      renderStats(progress.data);
    } else {
      const statsPanel = document.getElementById("apcStudyStatsPanel");
      if (statsPanel) statsPanel.innerHTML = `<strong>Stats</strong><p class="muted">Progress endpoint unavailable (${progress.status}).</p>`;
    }

    const deckId = deckIdOverride || selectedDeckId;
    if (!deckId) return;

    const cards = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/cards`);
    if (cards.ok) renderCards(cards.data, deckId);
    else {
      const cardsPanel = document.getElementById("apcStudyCardsPanel");
      if (cardsPanel) cardsPanel.innerHTML = `<strong>Cards</strong><p class="muted">Cards endpoint unavailable (${cards.status}).</p>`;
    }

    const review = await apiJson(`/api/study/decks/${encodeURIComponent(deckId)}/review-queue`);
    if (review.ok) renderReview(review.data, deckId);
    else {
      const reviewPanel = document.getElementById("apcStudyReviewPanel");
      if (reviewPanel) reviewPanel.innerHTML = `<strong>Review queue</strong><p class="muted">Review queue endpoint unavailable (${review.status}).</p>`;
    }
  }

  async function repairStudySurface() {
    if (!isProbablyStudyPage()) return;
    removeDuplicatedLegacyStudyBlock();

    const signedIn = await currentUserIsSignedIn();
    if (!signedIn) return;

    findStudyMount();
    await loadStudyTools(deckIdFromExistingUi());
  }

  function scheduleRepair() {
    clearTimeout(repairTimer);
    repairTimer = setTimeout(() => {
      repairStudySurface().catch((error) => {
        console.warn(`[${MARKER}] Study repair skipped`, error);
      });
    }, 80);
  }

  window.apcStudySignedInRepairFcO45CC = {
    marker: MARKER,
    repair: repairStudySurface,
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", scheduleRepair, { once: true });
  } else {
    scheduleRepair();
  }

  window.addEventListener("hashchange", scheduleRepair);
  window.addEventListener("popstate", scheduleRepair);
  document.addEventListener("click", () => setTimeout(scheduleRepair, 120), true);

  const observer = new MutationObserver(() => {
    if (!document.getElementById(PANEL_ID) && isProbablyStudyPage()) scheduleRepair();
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();


/*
 * APC_ADMIN_USERS_ROUTE_REPAIR_FC_O45_D_C_R2
 *
 * Admin users frontend route repair.
 * Uses CT203's existing /system/admin/users route and clearly marks
 * /system/admin/online-users as a backend route still pending.
 */
(function () {
  const MARKER = "APC_ADMIN_USERS_ROUTE_REPAIR_FC_O45_D_C_R2";
  const PANEL_ID = "apcAdminUsersRouteRepairFcO45DCR2";
  const STYLE_ID = "apc-admin-users-route-repair-fc-o45-d-c-r2";

  function esc(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function isAdminRoute() {
    try {
      const path = window.location.pathname || "";
      const hash = window.location.hash || "";
      return path === "/admin" || path.startsWith("/admin/") || hash.toLowerCase().includes("admin");
    } catch (_) {
      return false;
    }
  }

  function isAdminUserReady() {
    try { if (typeof cleanIsAdmin === "function") return !!cleanIsAdmin(); } catch (_) {}
    try { if (window.authState && window.authState.user && window.authState.user.is_admin) return true; } catch (_) {}
    try { if (window.currentUser && window.currentUser.is_admin) return true; } catch (_) {}
    return false;
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.setAttribute("data-apc-admin-users-route-repair", MARKER);
    style.textContent = [
      ".admin-users-route-repair{display:grid;gap:1rem;margin-top:1rem;}",
      ".admin-users-route-repair .admin-repair-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:1rem;}",
      ".admin-users-route-repair .admin-repair-card{border:1px solid rgba(148,163,184,.22);border-radius:14px;padding:1rem;background:rgba(15,23,42,.18);}",
      ".admin-users-route-repair .admin-repair-table{width:100%;border-collapse:collapse;font-size:.92rem;}",
      ".admin-users-route-repair .admin-repair-table th,.admin-users-route-repair .admin-repair-table td{padding:.55rem;border-bottom:1px solid rgba(148,163,184,.18);text-align:left;vertical-align:top;}",
      ".admin-users-route-repair .admin-repair-table th{font-size:.75rem;text-transform:uppercase;letter-spacing:.06em;opacity:.75;}",
      ".admin-users-route-repair .admin-repair-pill{display:inline-flex;align-items:center;border-radius:999px;padding:.25rem .55rem;border:1px solid rgba(148,163,184,.25);font-size:.8rem;}",
      ".admin-users-route-repair .admin-repair-ok{background:rgba(34,197,94,.12);}",
      ".admin-users-route-repair .admin-repair-warn{background:rgba(234,179,8,.12);}",
      ".admin-users-route-repair .admin-repair-error{background:rgba(239,68,68,.12);}",
      ".admin-users-route-repair .muted{opacity:.78;}",
      "@media (max-width:720px){.admin-users-route-repair .admin-repair-table{display:block;overflow-x:auto;}}"
    ].join("\n");
    (document.head || document.documentElement).appendChild(style);
  }

  function candidatesFromStorageValue(value, out) {
    if (!value || typeof value !== "string") return;
    if (/^eyJ[A-Za-z0-9_-]+\./.test(value) || (value.length > 40 && /^[A-Za-z0-9._-]+$/.test(value))) out.push(value);
    try {
      const parsed = JSON.parse(value);
      if (parsed && typeof parsed === "object") {
        ["token", "access_token", "authToken", "jwt", "bearer", "session_token"].forEach(function (key) {
          if (typeof parsed[key] === "string") candidatesFromStorageValue(parsed[key], out);
        });
        if (parsed.user && typeof parsed.user === "object") {
          ["token", "access_token", "authToken", "jwt"].forEach(function (key) {
            if (typeof parsed.user[key] === "string") candidatesFromStorageValue(parsed.user[key], out);
          });
        }
      }
    } catch (_) {}
  }

  function findBearerToken() {
    const values = [];
    try {
      [window.localStorage, window.sessionStorage].forEach(function (store) {
        if (!store) return;
        for (let i = 0; i < store.length; i += 1) {
          const key = store.key(i) || "";
          if (!/(token|auth|jwt|session)/i.test(key)) continue;
          candidatesFromStorageValue(store.getItem(key), values);
        }
      });
    } catch (_) {}
    return values[0] || "";
  }

  async function jsonFetch(path) {
    const headers = { Accept: "application/json" };
    const token = findBearerToken();
    if (token) headers.Authorization = "Bearer " + token;

    try {
      const response = await fetch(path, {
        method: "GET",
        credentials: "include",
        cache: "no-store",
        headers: headers
      });
      let data = null;
      try { data = await response.json(); } catch (_) { data = { detail: await response.text().catch(function () { return ""; }) }; }
      return { ok: response.ok, status: response.status, data: data };
    } catch (error) {
      return { ok: false, status: 0, data: { detail: error && error.message ? error.message : "request failed" } };
    }
  }

  async function adminUsersRequest() {
    if (typeof api === "function") {
      const candidates = ["/system/admin/users", "/admin/users"];
      for (const candidate of candidates) {
        try {
          const data = await api(candidate);
          if (data) return { ok: !(data.ok === false), status: Number(data.status || 200) || 200, data: data };
        } catch (_) {}
      }
    }
    return jsonFetch("/system/admin/users");
  }

  function usersArray(data) {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data && data.users)) return data.users;
    if (Array.isArray(data && data.items)) return data.items;
    if (Array.isArray(data && data.results)) return data.results;
    if (Array.isArray(data && data.accounts)) return data.accounts;
    return [];
  }

  function ensurePanel() {
    ensureStyle();
    let panel = document.getElementById(PANEL_ID);
    if (!panel) {
      panel = document.createElement("section");
      panel.id = PANEL_ID;
      panel.className = "card admin-users-route-repair";
      panel.setAttribute("data-apc-admin-users-route-repair", MARKER);
      const target = document.querySelector("main:not([hidden])") || document.getElementById("app") || document.body;
      target.appendChild(panel);
    }
    return panel;
  }

  function renderUsersTable(result) {
    if (!result.ok) {
      return "<div class=\"admin-repair-card\"><h3>Users</h3><p class=\"admin-repair-pill admin-repair-error\">/system/admin/users returned HTTP " + esc(result.status) + "</p><p class=\"muted\">The backend users route exists. If this fails while signed in as admin, the remaining issue is the frontend auth token source.</p></div>";
    }

    const users = usersArray(result.data);
    if (!users.length) {
      return "<div class=\"admin-repair-card\"><h3>Users</h3><p class=\"admin-repair-pill admin-repair-warn\">No users returned</p><p class=\"muted\">The route loaded but did not return a user list.</p></div>";
    }

    const rows = users.slice(0, 80).map(function (user) {
      const id = user.id ?? user.user_id ?? user.account_id ?? "—";
      const email = user.email ?? user.username ?? user.user_email ?? "—";
      const role = user.role ?? (user.is_admin ? "admin" : "user");
      const created = user.created_at ?? user.registered_at ?? user.created ?? "—";
      const last = user.last_login_at ?? user.last_seen_at ?? user.updated_at ?? "—";
      const online = user.online === true || user.is_online === true || user.active === true;
      return "<tr>"
        + "<td>" + esc(id) + "</td>"
        + "<td>" + esc(email) + "</td>"
        + "<td>" + esc(role) + "</td>"
        + "<td>" + (online ? "<span class=\"admin-repair-pill admin-repair-ok\">online</span>" : "<span class=\"admin-repair-pill\">offline/unknown</span>") + "</td>"
        + "<td>" + esc(created) + "</td>"
        + "<td>" + esc(last) + "</td>"
        + "</tr>";
    }).join("");

    return "<div class=\"admin-repair-card\"><h3>Users</h3><p class=\"admin-repair-pill admin-repair-ok\">Loaded from /system/admin/users</p><table class=\"admin-repair-table\"><thead><tr><th>ID</th><th>User</th><th>Role</th><th>Status</th><th>Created</th><th>Last seen/login</th></tr></thead><tbody>" + rows + "</tbody></table></div>";
  }

  function renderOnlineStatus(usersResult, onlineResult) {
    const users = usersArray(usersResult && usersResult.data);
    const derivedOnline = users.filter(function (user) {
      return user.online === true || user.is_online === true || user.active === true;
    });

    if (onlineResult && onlineResult.status === 404) {
      return "<div class=\"admin-repair-card\"><h3>Online Users</h3><p class=\"admin-repair-pill admin-repair-warn\">Backend endpoint not available yet</p><p class=\"muted\">/system/admin/online-users is not implemented yet. This will be activated in the next backend step.</p>"
        + (derivedOnline.length ? "<ul>" + derivedOnline.map(function (user) { return "<li>" + esc(user.email || user.username || user.id || "user") + "</li>"; }).join("") + "</ul>" : "<p class=\"muted\">No online status fields are available from /system/admin/users yet.</p>")
        + "</div>";
    }

    return "<div class=\"admin-repair-card\"><h3>Online Users</h3><p class=\"admin-repair-pill admin-repair-warn\">Waiting for backend online-users route</p><p class=\"muted\">The users table can load independently. Online tracking needs the planned /system/admin/online-users endpoint.</p></div>";
  }

  async function mount() {
    if (!isAdminRoute()) return;
    if (!isAdminUserReady()) return;

    const panel = ensurePanel();
    panel.innerHTML = "<h2>Admin users</h2><p class=\"muted\">Loading users from <code>/system/admin/users</code>...</p>";

    const usersResult = await adminUsersRequest();
    const onlineResult = await jsonFetch("/system/admin/online-users");

    panel.innerHTML = "<h2>Admin users</h2><p class=\"muted\">Frontend route repair active. Users route: <code>/system/admin/users</code>.</p><div class=\"admin-repair-grid\">"
      + renderUsersTable(usersResult)
      + renderOnlineStatus(usersResult, onlineResult)
      + "</div>";
  }

  function schedule() {
    if (!isAdminRoute()) return;
    window.setTimeout(mount, 250);
    window.setTimeout(mount, 1200);
    window.setTimeout(mount, 3000);
  }

  window.apcAdminUsersRouteRepairFcO45DCR2 = { mount: mount, requestUsers: adminUsersRequest };
  window.addEventListener("DOMContentLoaded", schedule);
  window.addEventListener("popstate", schedule);
  window.addEventListener("hashchange", schedule);
  schedule();
})();


/*
 * APC_NATIVE_ADMIN_USERS_INTEGRATION_FC_O45_D_E
 *
 * Native Admin users integration.
 * - Feeds /system/admin/users into the existing Admin Online Users and Latest Users sections.
 * - Derives online users from the users route until /system/admin/online-users exists.
 * - Removes the temporary FC-O45-D-C repair panel from the rendered page.
 * - Frontend-only: no backend, DB, service, nginx, CT/VM, job, worker, runtime, or model mutation.
 */
(function () {
  const MARKER = "APC_NATIVE_ADMIN_USERS_INTEGRATION_FC_O45_D_E";
  const OLD_PANEL_ID = "apcAdminUsersRouteRepairFcO45DCR2";
  const STYLE_ID = "apc-native-admin-users-integration-fc-o45-d-e";
  const USER_PATH = "/system/admin/users";

  let lastSignature = "";
  let lastUsers = [];
  let inFlight = false;

  function esc(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function isAdminRoute() {
    try {
      const path = window.location.pathname || "";
      const hash = window.location.hash || "";
      return path === "/admin" || path.startsWith("/admin/") || hash.toLowerCase().includes("admin");
    } catch (_) {
      return false;
    }
  }

  function isAdminReady() {
    try { if (typeof cleanIsAdmin === "function") return !!cleanIsAdmin(); } catch (_) {}
    try { if (window.authState && window.authState.user && window.authState.user.is_admin) return true; } catch (_) {}
    try { if (window.currentUser && window.currentUser.is_admin) return true; } catch (_) {}
    return false;
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.setAttribute("data-apc-native-admin-users-integration", MARKER);
    style.textContent = [
      ".apc-native-admin-users{display:grid;gap:.75rem;margin-top:.75rem;}",
      ".apc-native-admin-users .apc-admin-user-summary{display:flex;flex-wrap:wrap;gap:.5rem;align-items:center;}",
      ".apc-native-admin-users .apc-admin-pill{display:inline-flex;align-items:center;border-radius:999px;padding:.25rem .55rem;border:1px solid rgba(148,163,184,.28);font-size:.8rem;}",
      ".apc-native-admin-users .apc-admin-pill.ok{background:rgba(34,197,94,.12);}",
      ".apc-native-admin-users .apc-admin-pill.warn{background:rgba(234,179,8,.12);}",
      ".apc-native-admin-users table{width:100%;border-collapse:collapse;font-size:.92rem;}",
      ".apc-native-admin-users th,.apc-native-admin-users td{padding:.55rem;border-bottom:1px solid rgba(148,163,184,.18);text-align:left;vertical-align:top;}",
      ".apc-native-admin-users th{font-size:.75rem;text-transform:uppercase;letter-spacing:.06em;opacity:.75;}",
      ".apc-native-admin-users ul{margin:.25rem 0 0 1.2rem;padding:0;}",
      ".apc-native-admin-users .muted{opacity:.78;}",
      "@media (max-width:720px){.apc-native-admin-users table{display:block;overflow-x:auto;}}"
    ].join("\n");
    (document.head || document.documentElement).appendChild(style);
  }

  function removeTemporaryRepairPanel() {
    try {
      const old = document.getElementById(OLD_PANEL_ID);
      if (old) old.remove();
      document.querySelectorAll("[data-apc-admin-users-route-repair]").forEach(function (node) {
        const parent = node.closest("section, article, .card") || node;
        if (parent && parent.id === OLD_PANEL_ID) parent.remove();
      });
    } catch (_) {}
  }

  function storageTokenCandidates(value, out) {
    if (!value || typeof value !== "string") return;
    if (/^eyJ[A-Za-z0-9_-]+\./.test(value) || (value.length > 40 && /^[A-Za-z0-9._-]+$/.test(value))) out.push(value);
    try {
      const parsed = JSON.parse(value);
      if (parsed && typeof parsed === "object") {
        ["token", "access_token", "authToken", "jwt", "bearer", "session_token"].forEach(function (key) {
          if (typeof parsed[key] === "string") storageTokenCandidates(parsed[key], out);
        });
        if (parsed.user && typeof parsed.user === "object") {
          ["token", "access_token", "authToken", "jwt"].forEach(function (key) {
            if (typeof parsed.user[key] === "string") storageTokenCandidates(parsed.user[key], out);
          });
        }
      }
    } catch (_) {}
  }

  function findBearerToken() {
    const values = [];
    try {
      [window.localStorage, window.sessionStorage].forEach(function (store) {
        if (!store) return;
        for (let i = 0; i < store.length; i += 1) {
          const key = store.key(i) || "";
          if (!/(token|auth|jwt|session)/i.test(key)) continue;
          storageTokenCandidates(store.getItem(key), values);
        }
      });
    } catch (_) {}
    return values[0] || "";
  }

  async function requestAdminUsers() {
    if (typeof window.apcAdminUsersRouteRepairFcO45DCR2 === "object" && typeof window.apcAdminUsersRouteRepairFcO45DCR2.requestUsers === "function") {
      try {
        const result = await window.apcAdminUsersRouteRepairFcO45DCR2.requestUsers();
        if (result && result.ok) return result;
      } catch (_) {}
    }

    if (typeof api === "function") {
      try {
        const data = await api(USER_PATH);
        if (data) return { ok: !(data.ok === false), status: Number(data.status || 200) || 200, data: data };
      } catch (_) {}
    }

    const headers = { Accept: "application/json" };
    const token = findBearerToken();
    if (token) headers.Authorization = "Bearer " + token;

    try {
      const response = await fetch(USER_PATH, {
        method: "GET",
        credentials: "include",
        cache: "no-store",
        headers: headers
      });
      let data = null;
      try { data = await response.json(); } catch (_) { data = { detail: await response.text().catch(function () { return ""; }) }; }
      return { ok: response.ok, status: response.status, data: data };
    } catch (error) {
      return { ok: false, status: 0, data: { detail: error && error.message ? error.message : "request failed" } };
    }
  }

  function usersArray(data) {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data && data.users)) return data.users;
    if (Array.isArray(data && data.items)) return data.items;
    if (Array.isArray(data && data.results)) return data.results;
    if (Array.isArray(data && data.accounts)) return data.accounts;
    return [];
  }

  function onlineUsers(users) {
    return users.filter(function (user) {
      return user.online === true || user.is_online === true || user.active === true;
    });
  }

  function userLabel(user) {
    return user.email || user.username || user.user_email || user.name || ("User #" + (user.id || user.user_id || "—"));
  }

  function userId(user) {
    return user.id ?? user.user_id ?? user.account_id ?? "—";
  }

  function userRole(user) {
    return user.role ?? (user.is_admin ? "admin" : "user");
  }

  function userLastSeen(user) {
    return user.last_seen_at ?? user.last_login_at ?? user.updated_at ?? user.created_at ?? "—";
  }

  function userCreated(user) {
    return user.created_at ?? user.registered_at ?? user.created ?? "—";
  }

  function sectionByHeading(patterns) {
    const headings = Array.from(document.querySelectorAll("h1,h2,h3,h4"));
    for (const heading of headings) {
      const text = (heading.textContent || "").replace(/\s+/g, " ").trim().toLowerCase();
      if (!patterns.some(function (pattern) { return pattern.test(text); })) continue;
      const container = heading.closest("section, article, .card, .admin-card, .panel, div");
      if (container) return container;
    }
    return null;
  }

  function childMount(container, id) {
    if (!container) return null;
    let node = container.querySelector("#" + id);
    if (!node) {
      node = document.createElement("div");
      node.id = id;
      node.className = "apc-native-admin-users";
      node.setAttribute("data-apc-native-admin-users-integration", MARKER);
      container.appendChild(node);
    }
    return node;
  }

  function clearOldNativeEmptyText(container) {
    if (!container) return;
    try {
      Array.from(container.querySelectorAll("p,div,span")).forEach(function (node) {
        const text = (node.textContent || "").replace(/\s+/g, " ").trim().toLowerCase();
        if (
          text === "no users loaded yet." ||
          text === "users returned 0" ||
          text === "online users 0" ||
          text === "online users 0 users active within the online window." ||
          text === "users returned 0 latest users by activity."
        ) {
          node.style.display = "none";
          node.setAttribute("data-apc-native-admin-hidden-empty", MARKER);
        }
      });
    } catch (_) {}
  }

  function renderOnline(container, users) {
    if (!container) return false;
    clearOldNativeEmptyText(container);
    const online = onlineUsers(users);
    const node = childMount(container, "apcNativeAdminOnlineUsersFcO45DE");
    if (!node) return false;

    const list = online.length
      ? "<ul>" + online.map(function (user) {
          return "<li><strong>" + esc(userLabel(user)) + "</strong> <span class=\"apc-admin-pill ok\">online</span><br><span class=\"muted\">Last activity: " + esc(userLastSeen(user)) + "</span></li>";
        }).join("") + "</ul>"
      : "<p class=\"muted\">No users are currently marked online by <code>/system/admin/users</code>.</p>";

    node.innerHTML = [
      "<div class=\"apc-admin-user-summary\">",
      "<span class=\"apc-admin-pill ok\">Online users " + esc(online.length) + "</span>",
      "<span class=\"apc-admin-pill\">Derived from /system/admin/users</span>",
      "</div>",
      list
    ].join("");
    return true;
  }

  function renderLatest(container, users) {
    if (!container) return false;
    clearOldNativeEmptyText(container);
    const node = childMount(container, "apcNativeAdminLatestUsersFcO45DE");
    if (!node) return false;

    if (!users.length) {
      node.innerHTML = "<p class=\"apc-admin-pill warn\">Users route loaded, but no users were returned.</p>";
      return true;
    }

    const rows = users.slice(0, 40).map(function (user) {
      const isOnline = onlineUsers([user]).length > 0;
      return "<tr>"
        + "<td>" + esc(userId(user)) + "</td>"
        + "<td>" + esc(userLabel(user)) + "</td>"
        + "<td>" + esc(userRole(user)) + "</td>"
        + "<td>" + (isOnline ? "<span class=\"apc-admin-pill ok\">online</span>" : "<span class=\"apc-admin-pill\">offline/unknown</span>") + "</td>"
        + "<td>" + esc(userCreated(user)) + "</td>"
        + "<td>" + esc(userLastSeen(user)) + "</td>"
        + "</tr>";
    }).join("");

    node.innerHTML = [
      "<div class=\"apc-admin-user-summary\">",
      "<span class=\"apc-admin-pill ok\">Users returned " + esc(users.length) + "</span>",
      "<span class=\"apc-admin-pill\">Loaded from /system/admin/users</span>",
      "</div>",
      "<table>",
      "<thead><tr><th>ID</th><th>User</th><th>Role</th><th>Status</th><th>Created</th><th>Last seen/login</th></tr></thead>",
      "<tbody>" + rows + "</tbody>",
      "</table>"
    ].join("");
    return true;
  }

  function renderFallback(users) {
    let node = document.getElementById("apcNativeAdminUsersFallbackFcO45DE");
    if (!node) {
      node = document.createElement("section");
      node.id = "apcNativeAdminUsersFallbackFcO45DE";
      node.className = "card apc-native-admin-users";
      node.setAttribute("data-apc-native-admin-users-integration", MARKER);
      const target = document.querySelector("main:not([hidden])") || document.getElementById("app") || document.body;
      target.appendChild(node);
    }

    node.innerHTML = [
      "<h2>Admin users</h2>",
      "<p class=\"muted\">Native Admin users integration is active. Could not locate the original user cards, so this fallback is shown.</p>",
      "<div id=\"apcNativeAdminOnlineUsersFcO45DE\"></div>",
      "<div id=\"apcNativeAdminLatestUsersFcO45DE\"></div>"
    ].join("");

    renderOnline(node, users);
    renderLatest(node, users);
  }

  function signature(users) {
    try {
      return JSON.stringify(users.slice(0, 80).map(function (user) {
        return [userId(user), userLabel(user), userRole(user), user.online, user.is_online, user.active, userLastSeen(user)];
      }));
    } catch (_) {
      return String(Date.now());
    }
  }

  async function integrate() {
    if (!isAdminRoute()) return;
    if (!isAdminReady()) return;
    if (inFlight) return;

    inFlight = true;
    try {
      ensureStyle();
      removeTemporaryRepairPanel();

      const result = await requestAdminUsers();
      if (!result || !result.ok) {
        return;
      }

      const users = usersArray(result.data);
      const sig = signature(users);
      const force = sig !== lastSignature;
      lastSignature = sig;
      lastUsers = users;

      const onlineContainer = sectionByHeading([/^online users$/, /online users/]);
      const latestContainer = sectionByHeading([/latest users/, /users returned/, /^users$/]);

      const onlineOk = renderOnline(onlineContainer, users);
      const latestOk = renderLatest(latestContainer, users);

      if (!onlineOk || !latestOk) {
        renderFallback(users);
      } else {
        const fallback = document.getElementById("apcNativeAdminUsersFallbackFcO45DE");
        if (fallback) fallback.remove();
      }

      if (force) {
        document.documentElement.setAttribute("data-apc-native-admin-users-integrated", MARKER);
      }
    } finally {
      inFlight = false;
    }
  }

  function schedule() {
    if (!isAdminRoute()) return;
    removeTemporaryRepairPanel();
    [150, 700, 1600, 3200].forEach(function (delay) {
      window.setTimeout(integrate, delay);
    });
  }

  let observer = null;
  function observe() {
    if (observer || !document.documentElement) return;
    observer = new MutationObserver(function () {
      if (!isAdminRoute()) return;
      removeTemporaryRepairPanel();
      if (lastUsers.length) {
        window.clearTimeout(observe._timer);
        observe._timer = window.setTimeout(function () {
          const onlineContainer = sectionByHeading([/^online users$/, /online users/]);
          const latestContainer = sectionByHeading([/latest users/, /users returned/, /^users$/]);
          renderOnline(onlineContainer, lastUsers);
          renderLatest(latestContainer, lastUsers);
        }, 120);
      } else {
        window.clearTimeout(observe._timer);
        observe._timer = window.setTimeout(integrate, 300);
      }
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
  }

  window.apcNativeAdminUsersIntegrationFcO45DE = { integrate, requestAdminUsers, onlineUsers };
  window.addEventListener("DOMContentLoaded", function () { observe(); schedule(); });
  window.addEventListener("popstate", schedule);
  window.addEventListener("hashchange", schedule);
  observe();
  schedule();
})();


/*
 * APC_RECENT_USERS_TOP50_CREDITS_FC_O45_D_F
 *
 * Recent Users Admin card.
 * - Adds a top-50 scroll window for recent users.
 * - Includes free/local credits and paid credits columns when the backend user payload provides them.
 * - Hides the earlier fallback block so Online Users is not duplicated.
 * - Frontend-only: no backend, DB, service, nginx, CT/VM, job, worker, runtime, or model mutation.
 */
(function () {
  const MARKER = "APC_RECENT_USERS_TOP50_CREDITS_FC_O45_D_F";
  const CARD_ID = "apcRecentUsersTop50CreditsFcO45DF";
  const STYLE_ID = "apc-recent-users-top50-credits-fc-o45-d-f";
  const USER_PATH = "/system/admin/users";
  const HIDDEN_FALLBACK_ID = "apcNativeAdminUsersFallbackFcO45DE";

  let inFlight = false;
  let lastSignature = "";

  function esc(value) {
    return String(value === undefined || value === null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function isAdminRoute() {
    try {
      const path = window.location.pathname || "";
      const hash = window.location.hash || "";
      return path === "/admin" || path.startsWith("/admin/") || hash.toLowerCase().includes("admin");
    } catch (_) {
      return false;
    }
  }

  function isAdminReady() {
    try { if (typeof cleanIsAdmin === "function") return !!cleanIsAdmin(); } catch (_) {}
    try { if (window.authState && window.authState.user && window.authState.user.is_admin) return true; } catch (_) {}
    try { if (window.currentUser && window.currentUser.is_admin) return true; } catch (_) {}
    return false;
  }

  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.setAttribute("data-apc-recent-users-top50-credits", MARKER);
    style.textContent = [
      "#" + HIDDEN_FALLBACK_ID + "{display:none!important;}",
      ".apc-recent-users-card{display:grid;gap:1rem;margin-top:1rem;}",
      ".apc-recent-users-card .apc-recent-users-summary{display:flex;flex-wrap:wrap;gap:.5rem;align-items:center;}",
      ".apc-recent-users-card .apc-admin-pill{display:inline-flex;align-items:center;border-radius:999px;padding:.25rem .55rem;border:1px solid rgba(148,163,184,.28);font-size:.8rem;}",
      ".apc-recent-users-card .apc-admin-pill.ok{background:rgba(34,197,94,.12);}",
      ".apc-recent-users-card .apc-admin-pill.warn{background:rgba(234,179,8,.12);}",
      ".apc-recent-users-card .apc-recent-users-scroll{max-height:34rem;overflow:auto;border:1px solid rgba(148,163,184,.18);border-radius:14px;}",
      ".apc-recent-users-card table{width:100%;border-collapse:separate;border-spacing:0;font-size:.9rem;min-width:980px;}",
      ".apc-recent-users-card th,.apc-recent-users-card td{padding:.55rem;border-bottom:1px solid rgba(148,163,184,.16);text-align:left;vertical-align:top;}",
      ".apc-recent-users-card th{position:sticky;top:0;z-index:1;background:rgba(15,23,42,.96);font-size:.75rem;text-transform:uppercase;letter-spacing:.06em;opacity:.92;}",
      ".apc-recent-users-card tr:last-child td{border-bottom:0;}",
      ".apc-recent-users-card .muted{opacity:.78;}",
      ".apc-recent-users-card .credit-pending{opacity:.7;font-style:italic;}",
      "@media (max-width:720px){.apc-recent-users-card .apc-recent-users-scroll{max-height:28rem;}}"
    ].join("\n");
    (document.head || document.documentElement).appendChild(style);
  }

  function hideDuplicateFallback() {
    try {
      const fallback = document.getElementById(HIDDEN_FALLBACK_ID);
      if (fallback) {
        fallback.style.display = "none";
        fallback.setAttribute("hidden", "hidden");
        fallback.setAttribute("aria-hidden", "true");
        fallback.setAttribute("data-apc-recent-users-hidden-fallback", MARKER);
      }
    } catch (_) {}
  }

  function storageTokenCandidates(value, out) {
    if (!value || typeof value !== "string") return;
    if (/^eyJ[A-Za-z0-9_-]+\./.test(value) || (value.length > 40 && /^[A-Za-z0-9._-]+$/.test(value))) out.push(value);
    try {
      const parsed = JSON.parse(value);
      if (parsed && typeof parsed === "object") {
        ["token", "access_token", "authToken", "jwt", "bearer", "session_token"].forEach(function (key) {
          if (typeof parsed[key] === "string") storageTokenCandidates(parsed[key], out);
        });
        if (parsed.user && typeof parsed.user === "object") {
          ["token", "access_token", "authToken", "jwt"].forEach(function (key) {
            if (typeof parsed.user[key] === "string") storageTokenCandidates(parsed.user[key], out);
          });
        }
      }
    } catch (_) {}
  }

  function findBearerToken() {
    const values = [];
    try {
      [window.localStorage, window.sessionStorage].forEach(function (store) {
        if (!store) return;
        for (let i = 0; i < store.length; i += 1) {
          const key = store.key(i) || "";
          if (!/(token|auth|jwt|session)/i.test(key)) continue;
          storageTokenCandidates(store.getItem(key), values);
        }
      });
    } catch (_) {}
    return values[0] || "";
  }

  async function requestAdminUsers() {
    if (typeof window.apcNativeAdminUsersIntegrationFcO45DE === "object" && typeof window.apcNativeAdminUsersIntegrationFcO45DE.requestAdminUsers === "function") {
      try {
        const result = await window.apcNativeAdminUsersIntegrationFcO45DE.requestAdminUsers();
        if (result && result.ok) return result;
      } catch (_) {}
    }

    if (typeof window.apcAdminUsersRouteRepairFcO45DCR2 === "object" && typeof window.apcAdminUsersRouteRepairFcO45DCR2.requestUsers === "function") {
      try {
        const result = await window.apcAdminUsersRouteRepairFcO45DCR2.requestUsers();
        if (result && result.ok) return result;
      } catch (_) {}
    }

    if (typeof api === "function") {
      try {
        const data = await api(USER_PATH);
        if (data) return { ok: !(data.ok === false), status: Number(data.status || 200) || 200, data: data };
      } catch (_) {}
    }

    const headers = { Accept: "application/json" };
    const token = findBearerToken();
    if (token) headers.Authorization = "Bearer " + token;

    try {
      const response = await fetch(USER_PATH, {
        method: "GET",
        credentials: "include",
        cache: "no-store",
        headers: headers
      });
      let data = null;
      try { data = await response.json(); } catch (_) { data = { detail: await response.text().catch(function () { return ""; }) }; }
      return { ok: response.ok, status: response.status, data: data };
    } catch (error) {
      return { ok: false, status: 0, data: { detail: error && error.message ? error.message : "request failed" } };
    }
  }

  function usersArray(data) {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data && data.users)) return data.users;
    if (Array.isArray(data && data.items)) return data.items;
    if (Array.isArray(data && data.results)) return data.results;
    if (Array.isArray(data && data.accounts)) return data.accounts;
    return [];
  }

  function firstPresent(paths, user) {
    for (const path of paths) {
      let cursor = user;
      let ok = true;
      for (const part of path.split(".")) {
        if (cursor && Object.prototype.hasOwnProperty.call(cursor, part)) {
          cursor = cursor[part];
        } else {
          ok = false;
          break;
        }
      }
      if (ok && cursor !== undefined && cursor !== null && cursor !== "") return cursor;
    }
    return undefined;
  }

  function numberDisplay(value) {
    if (value === undefined || value === null || value === "") {
      return "<span class=\"credit-pending\">pending backend field</span>";
    }
    const num = Number(value);
    if (Number.isFinite(num)) return esc(num.toLocaleString(undefined, { maximumFractionDigits: 2 }));
    return esc(value);
  }

  function freeLocalCredits(user) {
    return firstPresent([
      "free_local_credits",
      "freeLocalCredits",
      "free_credits",
      "freeCredits",
      "local_credits",
      "localCredits",
      "free_credits_balance",
      "local_credits_balance",
      "free_local_credits_balance",
      "credits.free_local",
      "credits.free",
      "credits.local",
      "credits.freeLocal",
      "credit_pools.free_local",
      "credit_pools.free",
      "credit_pools.local",
      "credit_summary.free_local",
      "credit_summary.free",
      "credit_summary.local",
      "balances.free_local",
      "balances.free",
      "balances.local"
    ], user);
  }

  function paidCredits(user) {
    return firstPresent([
      "paid_credits",
      "paidCredits",
      "paid_credits_balance",
      "paidCreditsBalance",
      "purchased_credits",
      "purchasedCredits",
      "credit_packs_credits",
      "credits.paid",
      "credits.purchased",
      "credit_pools.paid",
      "credit_pools.purchased",
      "credit_summary.paid",
      "credit_summary.purchased",
      "balances.paid",
      "balances.purchased"
    ], user);
  }

  function userId(user) {
    return user.id ?? user.user_id ?? user.account_id ?? "—";
  }

  function userLabel(user) {
    return user.email || user.username || user.user_email || user.name || ("User #" + (userId(user) || "—"));
  }

  function userRole(user) {
    return user.role ?? (user.is_admin ? "admin" : "user");
  }

  function userCreated(user) {
    return user.created_at ?? user.registered_at ?? user.created ?? "—";
  }

  function userLastSeen(user) {
    return user.last_seen_at ?? user.last_login_at ?? user.updated_at ?? user.created_at ?? "—";
  }

  function userActivityTime(user) {
    const value = userLastSeen(user);
    const time = Date.parse(value);
    return Number.isFinite(time) ? time : 0;
  }

  function isOnline(user) {
    return user.online === true || user.is_online === true || user.active === true;
  }

  function sortedRecent(users) {
    return users.slice().sort(function (a, b) {
      return userActivityTime(b) - userActivityTime(a);
    });
  }

  function findInsertTarget() {
    const headings = Array.from(document.querySelectorAll("h1,h2,h3,h4"));
    for (const heading of headings) {
      const text = (heading.textContent || "").replace(/\s+/g, " ").trim().toLowerCase();
      if (text === "support inbox" || text.includes("support inbox")) {
        const section = heading.closest("section, article, .card, div");
        if (section && section.parentElement) return { mode: "before", node: section };
      }
    }
    for (const heading of headings) {
      const text = (heading.textContent || "").replace(/\s+/g, " ").trim().toLowerCase();
      if (text.includes("online users")) {
        const section = heading.closest("section, article, .card, div");
        if (section && section.parentElement) return { mode: "after", node: section };
      }
    }
    return { mode: "append", node: document.querySelector("main:not([hidden])") || document.getElementById("app") || document.body };
  }

  function ensureCard() {
    ensureStyle();
    hideDuplicateFallback();

    let card = document.getElementById(CARD_ID);
    if (card) return card;

    card = document.createElement("section");
    card.id = CARD_ID;
    card.className = "card apc-recent-users-card";
    card.setAttribute("data-apc-recent-users-top50-credits", MARKER);

    const target = findInsertTarget();
    if (target.mode === "before") target.node.insertAdjacentElement("beforebegin", card);
    else if (target.mode === "after") target.node.insertAdjacentElement("afterend", card);
    else target.node.appendChild(card);

    return card;
  }

  function renderCard(users) {
    const recent = sortedRecent(users).slice(0, 50);
    const onlineCount = users.filter(isOnline).length;
    const freeKnown = recent.filter(function (user) { return freeLocalCredits(user) !== undefined; }).length;
    const paidKnown = recent.filter(function (user) { return paidCredits(user) !== undefined; }).length;

    const rows = recent.map(function (user, index) {
      return "<tr>"
        + "<td>" + esc(index + 1) + "</td>"
        + "<td>" + esc(userId(user)) + "</td>"
        + "<td>" + esc(userLabel(user)) + "</td>"
        + "<td>" + esc(userRole(user)) + "</td>"
        + "<td>" + (isOnline(user) ? "<span class=\"apc-admin-pill ok\">online</span>" : "<span class=\"apc-admin-pill\">offline/unknown</span>") + "</td>"
        + "<td>" + numberDisplay(freeLocalCredits(user)) + "</td>"
        + "<td>" + numberDisplay(paidCredits(user)) + "</td>"
        + "<td>" + esc(userLastSeen(user)) + "</td>"
        + "<td>" + esc(userCreated(user)) + "</td>"
        + "</tr>";
    }).join("");

    const creditNote = (freeKnown || paidKnown)
      ? "<span class=\"apc-admin-pill ok\">Credit fields detected</span>"
      : "<span class=\"apc-admin-pill warn\">Credit columns ready; backend user payload does not expose balances yet</span>";

    const card = ensureCard();
    card.innerHTML = [
      "<h2>Recent Users</h2>",
      "<p class=\"muted\">Top 50 users by latest activity, loaded from <code>/system/admin/users</code>. Credit balances show when the backend user payload includes free/local and paid credit fields.</p>",
      "<div class=\"apc-recent-users-summary\">",
      "<span class=\"apc-admin-pill ok\">Users returned " + esc(users.length) + "</span>",
      "<span class=\"apc-admin-pill ok\">Online users " + esc(onlineCount) + "</span>",
      "<span class=\"apc-admin-pill\">Showing " + esc(recent.length) + " of 50 max</span>",
      creditNote,
      "</div>",
      recent.length
        ? "<div class=\"apc-recent-users-scroll\"><table><thead><tr><th>#</th><th>ID</th><th>User</th><th>Role</th><th>Status</th><th>Free/local credits</th><th>Paid credits</th><th>Last activity</th><th>Created</th></tr></thead><tbody>" + rows + "</tbody></table></div>"
        : "<p class=\"muted\">No users returned yet.</p>"
    ].join("");
  }

  function signature(users) {
    try {
      return JSON.stringify(sortedRecent(users).slice(0, 50).map(function (user) {
        return [userId(user), userLabel(user), userRole(user), isOnline(user), freeLocalCredits(user), paidCredits(user), userLastSeen(user), userCreated(user)];
      }));
    } catch (_) {
      return String(Date.now());
    }
  }

  async function refresh() {
    if (!isAdminRoute()) return;
    if (!isAdminReady()) return;
    if (inFlight) return;

    inFlight = true;
    try {
      hideDuplicateFallback();
      const result = await requestAdminUsers();
      if (!result || !result.ok) return;
      const users = usersArray(result.data);
      const sig = signature(users);
      if (sig === lastSignature && document.getElementById(CARD_ID)) return;
      lastSignature = sig;
      renderCard(users);
      document.documentElement.setAttribute("data-apc-recent-users-top50-credits", MARKER);
    } finally {
      inFlight = false;
    }
  }

  function schedule() {
    if (!isAdminRoute()) return;
    hideDuplicateFallback();
    [150, 800, 1800, 3500].forEach(function (delay) {
      window.setTimeout(refresh, delay);
    });
  }

  let observer = null;
  function observe() {
    if (observer || !document.documentElement) return;
    observer = new MutationObserver(function () {
      if (!isAdminRoute()) return;
      hideDuplicateFallback();
      window.clearTimeout(observe._timer);
      observe._timer = window.setTimeout(refresh, 300);
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
  }

  window.apcRecentUsersTop50CreditsFcO45DF = { refresh, requestAdminUsers, freeLocalCredits, paidCredits };
  window.addEventListener("DOMContentLoaded", function () { observe(); schedule(); });
  window.addEventListener("popstate", schedule);
  window.addEventListener("hashchange", schedule);
  observe();
  schedule();
})();


/* APC_COMPANION_AUTH_VALIDATE_UI_FC_O45_E_S
 * Signed-in Companion auth validation test path.
 * This is a UI-only smoke helper: it calls /api/companion/chat with the
 * FC-O45-E-Q no-enqueue validation header and displays queue_write=false.
 * It also removes the direct Study tools box from the Companion page; the
 * Companion should use Study tools internally, not expose setup controls here.
 */
(function apcCompanionAuthValidateFcO45ES() {
  const MARKER = "APC_COMPANION_AUTH_VALIDATE_UI_FC_O45_E_S";
  if (window[MARKER]) return;
  window[MARKER] = true;

  const HEADER_NAME = "X-APC-Companion-Auth-Validate-Only";
  const HEADER_VALUE = "FC-O45-E-Q";
  const PANEL_ID = "apc-companion-auth-validate-panel-fc-o45-e-s";

  function visibleText(node) {
    return (node && (node.innerText || node.textContent || "") || "").trim();
  }

  function isCompanionPage() {
    const bodyText = visibleText(document.body);
    return bodyText.includes("Companion") &&
      (bodyText.includes("Supportive chat workspace") ||
       bodyText.includes("Chat with your Companion"));
  }

  function removeStudyToolsBox() {
    if (!isCompanionPage()) return;

    const headings = Array.from(document.querySelectorAll("h1,h2,h3,h4,strong,b,legend"));
    for (const heading of headings) {
      if (visibleText(heading).trim() !== "Study tools") continue;

      let candidate = heading;
      for (let i = 0; i < 7 && candidate && candidate.parentElement; i += 1) {
        const parent = candidate.parentElement;
        const text = visibleText(parent);
        const looksLikeStudyBox =
          text.includes("Study tools") &&
          text.includes("Decks") &&
          text.includes("Review queue");
        const tooBroad =
          text.includes("Companion status") ||
          text.includes("Chat with your Companion") ||
          text.includes("How this works");
        if (looksLikeStudyBox && !tooBroad) {
          parent.remove();
          return;
        }
        candidate = parent;
      }

      const fallback = heading.closest("section, article, aside, .card, .panel, .box");
      if (fallback) fallback.remove();
    }
  }

  function findBearerToken() {
    const preferredKeys = [
      "edge_session_token",
      "edge_auth_token",
      "auth_token",
      "access_token",
      "session_token",
      "token",
      "jwt"
    ];

    function usable(value) {
      return typeof value === "string" && value.length > 20 && !value.includes(" ");
    }

    for (const key of preferredKeys) {
      const value = localStorage.getItem(key) || sessionStorage.getItem(key);
      if (usable(value)) return value;
      try {
        const parsed = JSON.parse(value || "null");
        for (const inner of preferredKeys) {
          if (parsed && usable(parsed[inner])) return parsed[inner];
        }
      } catch (_) {}
    }

    for (const store of [localStorage, sessionStorage]) {
      for (let i = 0; i < store.length; i += 1) {
        const key = store.key(i);
        const value = store.getItem(key);
        if (usable(value) && /token|session|auth|jwt/i.test(key)) return value;
        try {
          const parsed = JSON.parse(value || "null");
          for (const inner of preferredKeys) {
            if (parsed && usable(parsed[inner])) return parsed[inner];
          }
        } catch (_) {}
      }
    }
    return "";
  }

  function statusTarget() {
    let existing = document.getElementById("apc-companion-auth-validate-result");
    if (existing) return existing;
    return null;
  }

  async function runValidation(button) {
    const result = statusTarget();
    const token = findBearerToken();
    const headers = {
      "Content-Type": "application/json",
      [HEADER_NAME]: HEADER_VALUE
    };
    if (token) headers.Authorization = `Bearer ${token}`;

    button.disabled = true;
    if (result) {
      result.textContent = "Checking signed-in Companion auth without queue write...";
    }

    try {
      const response = await fetch("/api/companion/chat", {
        method: "POST",
        credentials: "include",
        headers,
        body: JSON.stringify({
          message: "FC-O45-E-S UI auth validation only. Do not enqueue.",
          requested_model: "no-model-smoke"
        })
      });
      const text = await response.text();
      let data = {};
      try {
        data = JSON.parse(text);
      } catch (_) {
        data = { raw: text };
      }

      const ok = response.ok && data.auth_validated === true && data.queue_write === false;
      if (result) {
        result.textContent = ok
          ? "PASS: signed-in Companion auth validated; queue_write=false."
          : `Check failed: HTTP ${response.status}. ${text.slice(0, 180)}`;
      }
    } catch (err) {
      if (result) {
        result.textContent = `Check failed: ${err && err.message ? err.message : err}`;
      }
    } finally {
      button.disabled = false;
    }
  }

  function insertValidationPanel() {
    if (!isCompanionPage()) return;
    if (document.getElementById(PANEL_ID)) return;

    const main = document.querySelector("main") || document.body;
    const panel = document.createElement("section");
    panel.id = PANEL_ID;
    panel.setAttribute("data-apc-marker", MARKER);
    panel.style.border = "1px solid rgba(148, 163, 184, 0.35)";
    panel.style.borderRadius = "12px";
    panel.style.padding = "14px";
    panel.style.margin = "14px 0";
    panel.style.background = "rgba(15, 23, 42, 0.03)";

    const title = document.createElement("h3");
    title.textContent = "Companion auth test";
    title.style.marginTop = "0";

    const text = document.createElement("p");
    text.textContent = "Checks your signed-in Companion connection without creating a queue job.";

    const button = document.createElement("button");
    button.type = "button";
    button.textContent = "Run Companion auth test";
    button.addEventListener("click", () => runValidation(button));

    const result = document.createElement("p");
    result.id = "apc-companion-auth-validate-result";
    result.textContent = "Not run yet.";
    result.style.fontSize = "0.95rem";

    panel.appendChild(title);
    panel.appendChild(text);
    panel.appendChild(button);
    panel.appendChild(result);

    const anchors = Array.from(document.querySelectorAll("h1,h2,h3"));
    const companionHeading = anchors.find((h) => visibleText(h).trim() === "Companion");
    const statusHeading = anchors.find((h) => visibleText(h).includes("Companion status"));
    const anchor = statusHeading || companionHeading;

    if (anchor && anchor.parentElement) {
      anchor.parentElement.insertBefore(panel, anchor.nextSibling);
    } else {
      main.insertBefore(panel, main.firstChild);
    }
  }

  function refresh() {
    try {
      removeStudyToolsBox();
      insertValidationPanel();
    } catch (_) {}
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", refresh);
  } else {
    refresh();
  }

  const observer = new MutationObserver(() => refresh());
  observer.observe(document.documentElement, { childList: true, subtree: true });
  setInterval(refresh, 2500);
})();


/* APC_COMPANION_RESULT_READER_UI_FC_O45_E_AC START */
(function () {
  "use strict";
  const MARKER = "APC_COMPANION_RESULT_READER_UI_FC_O45_E_AC";
  const PANEL_ID = "apc-companion-result-reader-panel-fc-o45-e-ac";

  function visibleText(node) {
    return (node && (node.innerText || node.textContent || "") || "").trim();
  }

  function isCompanionPage() {
    const bodyText = visibleText(document.body);
    return bodyText.includes("Companion") &&
      (bodyText.includes("Supportive chat workspace") ||
       bodyText.includes("Chat with your Companion"));
  }

  function findBearerToken() {
    const preferredKeys = [
      "edge_session_token",
      "edge_auth_token",
      "auth_token",
      "access_token",
      "session_token",
      "token",
      "jwt"
    ];

    function usable(value) {
      return typeof value === "string" && value.length > 20 && !value.includes(" ");
    }

    for (const key of preferredKeys) {
      const value = localStorage.getItem(key) || sessionStorage.getItem(key);
      if (usable(value)) return value;
      try {
        const parsed = JSON.parse(value || "null");
        for (const inner of preferredKeys) {
          if (parsed && usable(parsed[inner])) return parsed[inner];
        }
      } catch (_) {}
    }

    for (const store of [localStorage, sessionStorage]) {
      for (let i = 0; i < store.length; i += 1) {
        const key = store.key(i);
        const value = store.getItem(key);
        if (usable(value) && /token|session|auth|jwt/i.test(key)) return value;
        try {
          const parsed = JSON.parse(value || "null");
          for (const inner of preferredKeys) {
            if (parsed && usable(parsed[inner])) return parsed[inner];
          }
        } catch (_) {}
      }
    }
    return "";
  }

  function companionHeaders(extra) {
    const headers = Object.assign({
      "Content-Type": "application/json",
      "Accept": "application/json,text/plain,*/*"
    }, extra || {});
    const token = findBearerToken();
    if (token) headers.Authorization = `Bearer ${token}`;
    return headers;
  }

  function mountTarget() {
    const anchors = Array.from(document.querySelectorAll("h1,h2,h3"));
    const companionHeading = anchors.find((h) => visibleText(h).trim() === "Companion");
    const statusHeading = anchors.find((h) => visibleText(h).includes("Companion status"));
    const anchor = statusHeading || companionHeading;
    if (anchor && anchor.parentElement) return { parent: anchor.parentElement, before: anchor.nextSibling };
    return { parent: document.querySelector("main") || document.body, before: null };
  }

  function resultSummary(data) {
    const job = data && data.job ? data.job : {};
    const result = data && data.result ? data.result : {};
    const lines = [];
    lines.push("PASS: Companion result read path returned a result.");
    lines.push("job_id: " + String(job.id || result.job_id || ""));
    lines.push("status: " + String(job.status || ""));
    lines.push("job_type: " + String(job.job_type || ""));
    lines.push("requested_model: " + String(job.requested_model || ""));
    lines.push("queue_write: " + String(data.queue_write));
    lines.push("");
    lines.push(String(data.response_text || result.response_text || ""));
    return lines.join("\n");
  }

  function persistLatestSubmittedJobId(jobId) {
    try {
      window.localStorage.setItem("apc_companion_latest_submitted_job_id", String(jobId || ""));
    } catch (_) {}
  }

  function readLatestSubmittedJobId() {
    try {
      return String(window.localStorage.getItem("apc_companion_latest_submitted_job_id") || "").trim();
    } catch (_) {
      return "";
    }
  }

  function setReaderJobId(jobId, options) {
    const value = String(jobId || "").trim();
    if (!value) return false;
    persistLatestSubmittedJobId(value);
    install();
    const input = document.getElementById("apc-companion-result-reader-job-id");
    const output = document.getElementById("apc-companion-result-reader-output");
    if (input) input.value = value;
    if (output) {
      output.dataset.result = "job-id-captured";
      output.textContent =
        "Latest submitted Companion job id: " + value +
        "\nClick Read result to check this job without creating another job.";
    }
    return true;
  }

  window.apcCompanionResultReaderSetJobId = setReaderJobId;
  window.apcCompanionResultReaderLatestJobId = readLatestSubmittedJobId;

  async function readResult(button, input, output) {
    const raw = String(input.value || readLatestSubmittedJobId() || "").trim();
    const jobId = Number.parseInt(raw, 10);
    if (!Number.isInteger(jobId) || jobId < 1) {
      output.dataset.result = "invalid";
      output.textContent = "Enter a positive Companion job id.";
      return;
    }

    button.disabled = true;
    output.dataset.result = "checking";
    output.textContent = "Reading Companion result for job " + jobId + "...";

    try {
      const response = await fetch("/api/companion/chat", {
        method: "POST",
        credentials: "include",
        headers: companionHeaders({
          "X-APC-Companion-Result-Read-Only": "FC-O45-E-AA"
        }),
        body: JSON.stringify({
          job_id: jobId,
          message: "FC-O45-E-AC read Companion job result by job id.",
          requested_model: "no-model-smoke"
        })
      });

      const text = await response.text();
      let data = {};
      try {
        data = JSON.parse(text);
      } catch (_) {
        data = { raw: text };
      }

      if (!response.ok) {
        output.dataset.result = "failed";
        output.textContent = "Read failed: HTTP " + response.status + ". " + text.slice(0, 500);
        return;
      }

      if (data && data.has_result === true && data.response_text) {
        output.dataset.result = "pass";
        output.textContent = resultSummary(data);
      } else {
        output.dataset.result = "no-result";
        output.textContent = "The job was found, but no result is available yet. HTTP " + response.status + ".";
      }
    } catch (err) {
      output.dataset.result = "error";
      output.textContent = "Read failed: " + (err && err.message ? err.message : String(err));
    } finally {
      button.disabled = false;
    }
  }

  function install() {
    if (!isCompanionPage()) return;
    if (document.getElementById(PANEL_ID)) return;

    const target = mountTarget();
    const panel = document.createElement("section");
    panel.id = PANEL_ID;
    panel.setAttribute("data-marker", MARKER);
    panel.style.cssText = "border:1px solid rgba(120,120,120,.35);border-radius:12px;padding:12px;margin:12px 0;background:rgba(120,120,120,.08);";

    const title = document.createElement("h3");
    title.textContent = "Companion result reader";
    title.style.marginTop = "0";

    const desc = document.createElement("p");
    desc.textContent = "Read a completed Companion job result by job id. This is signed-in, owner-scoped, read-only, and does not create jobs or run models.";

    const row = document.createElement("div");
    row.style.display = "flex";
    row.style.gap = "8px";
    row.style.flexWrap = "wrap";
    row.style.alignItems = "center";

    const label = document.createElement("label");
    label.textContent = "Job id";
    label.setAttribute("for", "apc-companion-result-reader-job-id");

    const input = document.createElement("input");
    input.id = "apc-companion-result-reader-job-id";
    input.type = "number";
    input.min = "1";
    input.placeholder = "125";
    input.value = readLatestSubmittedJobId();
    input.style.maxWidth = "120px";

    const button = document.createElement("button");
    button.type = "button";
    button.textContent = "Read result";

    const output = document.createElement("pre");
    output.id = "apc-companion-result-reader-output";
    output.style.whiteSpace = "pre-wrap";
    const latestSubmittedJobId = readLatestSubmittedJobId();
    output.textContent = latestSubmittedJobId
      ? "Latest submitted Companion job id: " + latestSubmittedJobId + "\nClick Read result to check this job without creating another job."
      : "Enter a Companion job id, then click Read result.";

    button.addEventListener("click", function () {
      readResult(button, input, output);
    });
    input.addEventListener("keydown", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        readResult(button, input, output);
      }
    });

    row.appendChild(label);
    row.appendChild(input);
    row.appendChild(button);

    panel.appendChild(title);
    panel.appendChild(desc);
    panel.appendChild(row);
    panel.appendChild(output);

    target.parent.insertBefore(panel, target.before);
  }

  function schedule() {
    [100, 600, 1500, 3000].forEach((delay) => window.setTimeout(install, delay));
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", schedule, { once: true });
  } else {
    schedule();
  }
  window.addEventListener("hashchange", schedule);
  window.addEventListener("popstate", schedule);
})();
/* APC_COMPANION_RESULT_READER_UI_FC_O45_E_AC END */


/**
 * Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold.
 *
 * Source-only helper layer. This does not change backend behavior, does not run
 * models, and does not create jobs. It gives the Companion UI a small
 * assistant-like state vocabulary that can be wired into the visible panel:
 *
 * - listening
 * - thinking
 * - speaking
 * - needs_attention
 *
 * Debug details remain available separately from the primary user experience.
 */
const COMPANION_IMMERSION_STATES = Object.freeze({
  LISTENING: "listening",
  THINKING: "thinking",
  SPEAKING: "speaking",
  NEEDS_ATTENTION: "needs_attention",
});

function companionImmersionLabel(state) {
  const normalized = String(state || "").toLowerCase();
  if (normalized === COMPANION_IMMERSION_STATES.THINKING) return "Thinking";
  if (normalized === COMPANION_IMMERSION_STATES.SPEAKING) return "Speaking";
  if (normalized === COMPANION_IMMERSION_STATES.NEEDS_ATTENTION) return "Needs attention";
  return "Listening";
}

function companionImmersionStateFromJob(job, resultPayload) {
  const status = String(job?.status || resultPayload?.status || "").toLowerCase();
  const hasResult = Boolean(
    resultPayload?.result ||
    resultPayload?.response ||
    resultPayload?.text ||
    resultPayload?.message ||
    resultPayload?.content ||
    resultPayload?.result_text
  );

  if (status === "failed" || status === "error" || resultPayload?.error) {
    return COMPANION_IMMERSION_STATES.NEEDS_ATTENTION;
  }

  if ((status === "completed" || status === "complete") && hasResult) {
    return COMPANION_IMMERSION_STATES.SPEAKING;
  }

  if (
    status === "queued" ||
    status === "running" ||
    status === "processing" ||
    status === "pending" ||
    status === "claimed"
  ) {
    return COMPANION_IMMERSION_STATES.THINKING;
  }

  return COMPANION_IMMERSION_STATES.LISTENING;
}

function companionImmersionExtractResultText(resultPayload) {
  const candidates = [
    resultPayload?.result,
    resultPayload?.result_text,
    resultPayload?.response,
    resultPayload?.text,
    resultPayload?.message,
    resultPayload?.content,
  ];

  for (const value of candidates) {
    if (typeof value === "string" && value.trim()) return value.trim();
  }

  if (resultPayload?.result && typeof resultPayload.result === "object") {
    for (const key of ["text", "message", "response", "content", "result_text"]) {
      const value = resultPayload.result[key];
      if (typeof value === "string" && value.trim()) return value.trim();
    }
  }

  return "";
}

function companionImmersionDebugDetails(context = {}) {
  const lines = [];
  if (context.job_id || context.jobId) lines.push(`job_id: ${context.job_id || context.jobId}`);
  if (context.status) lines.push(`status: ${context.status}`);
  if (context.job_type || context.jobType) lines.push(`job_type: ${context.job_type || context.jobType}`);
  if (context.requested_model || context.requestedModel) {
    lines.push(`requested_model: ${context.requested_model || context.requestedModel}`);
  }
  if (typeof context.queue_write !== "undefined") lines.push(`queue_write: ${String(context.queue_write)}`);
  if (context.worker) lines.push(`worker: ${context.worker}`);
  return lines;
}

function renderCompanionImmersionPanel(context = {}) {
  const lastUserMessage = String(context.lastUserMessage || context.message || "").trim();
  const resultText = companionImmersionExtractResultText(context.resultPayload || context);
  const state = context.state || companionImmersionStateFromJob(context.job || context, context.resultPayload || context);
  const label = companionImmersionLabel(state);
  const debugLines = companionImmersionDebugDetails(context);

  const userMessageMarkup = lastUserMessage
    ? `<p class="companion-immersion-user-message"><strong>You:</strong> ${safeText(lastUserMessage)}</p>`
    : "";

  const responseMarkup = resultText
    ? `<p class="companion-immersion-response">${safeText(resultText)}</p>`
    : "";

  const debugMarkup = debugLines.length
    ? `<details class="companion-immersion-debug"><summary>Debug details</summary><pre>${safeText(debugLines.join("\n"))}</pre></details>`
    : "";

  return `
    <section class="companion-immersion-panel" data-companion-immersion-state="${safeText(state)}">
      <div class="companion-immersion-state companion-immersion-state-${safeText(state)}">${safeText(label)}</div>
      ${userMessageMarkup}
      ${responseMarkup}
      ${debugMarkup}
    </section>
  `;
}

if (typeof window !== "undefined") {
  window.apcCompanionImmersion = Object.freeze({
    states: COMPANION_IMMERSION_STATES,
    label: companionImmersionLabel,
    stateFromJob: companionImmersionStateFromJob,
    extractResultText: companionImmersionExtractResultText,
    debugDetails: companionImmersionDebugDetails,
    renderPanel: renderCompanionImmersionPanel,
  });
}


/**
 * Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring.
 *
 * Source-only wiring. This does not deploy, does not create jobs, does not call
 * models, and does not mutate backend state. When this source is later deployed,
 * it observes the existing Companion queued-chat flow and renders a lightweight
 * Immersion panel:
 *
 *   last user message + state + final response + optional debug details
 *
 * State labels:
 * - listening
 * - thinking
 * - speaking
 * - needs_attention
 */
/* Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag.
 * Must be defined before old Companion runtime IIFEs so they skip before mutating the DOM.
 */
if (typeof window !== "undefined") {
  window.__apcCompanionStructuralMinimalMode = true;
}

(function stage16FcO45EAtWireCompanionImmersionPanel() {
  if (window.__apcCompanionStructuralMinimalMode) {
    window.__stage16FcO45EAtWireCompanionImmersionPanelSkippedForStructuralMinimalMode = true;
    return;
  }

  if (typeof window === "undefined" || window.__apcCompanionImmersionVisiblePanelInstalled) return;
  window.__apcCompanionImmersionVisiblePanelInstalled = true;

  const IMMERSION_MOUNT_ID = "companionImmersionVisiblePanel";
  const QUEUED_CHAT_PATH = "/api/chat/queued";
  const runtime = {
    lastUserMessage: "",
    state: "listening",
    job: {},
    resultPayload: {},
    queue_write: false,
    worker: "Companion queue worker",
  };

  function companionImmersionIsCompanionRoute() {
    const bodyRoute = document.body?.getAttribute("data-current-route") || "";
    const path = window.location?.pathname || "";
    return bodyRoute === "/companion" || path === "/companion" || path === "/chat";
  }

  function companionImmersionFindAnchor() {
    const headings = Array.from(document.querySelectorAll("h1,h2,h3,h4,strong,summary"));
    return headings.find((node) => {
      const text = String(node.textContent || "").trim().toLowerCase();
      return text === "conversation" ||
        text === "companion" ||
        text.includes("start a companion conversation") ||
        text.includes("supportive chat workspace");
    });
  }

  function companionImmersionEnsureMount() {
    if (!companionImmersionIsCompanionRoute()) return null;

    let mount = document.getElementById(IMMERSION_MOUNT_ID);
    if (mount) return mount;

    const main = document.querySelector("main") || document.querySelector("#app") || document.body;
    if (!main) return null;

    const anchor = companionImmersionFindAnchor();
    const anchorCard = anchor?.closest?.("section,.summary-box,.feature-card,.clean-card,.study-card,.companion-card,.route-card,.panel,div");
    mount = document.createElement("div");
    mount.id = IMMERSION_MOUNT_ID;
    mount.setAttribute("data-stage", "FC-O45-E-AT");
    mount.setAttribute("data-companion-immersion-visible-panel", "true");

    if (anchorCard && anchorCard.parentNode) {
      anchorCard.parentNode.insertBefore(mount, anchorCard);
    } else {
      main.insertBefore(mount, main.firstChild);
    }

    return mount;
  }

  function companionImmersionSetRuntime(next = {}) {
    if (typeof next.lastUserMessage === "string" && next.lastUserMessage.trim()) {
      runtime.lastUserMessage = next.lastUserMessage.trim();
    }
    if (typeof next.state === "string" && next.state.trim()) {
      runtime.state = next.state.trim();
    }
    if (next.job && typeof next.job === "object") {
      runtime.job = { ...runtime.job, ...next.job };
    }
    if (next.resultPayload && typeof next.resultPayload === "object") {
      runtime.resultPayload = { ...runtime.resultPayload, ...next.resultPayload };
    }
    if (typeof next.queue_write !== "undefined") {
      runtime.queue_write = next.queue_write;
    }
    if (typeof next.worker === "string" && next.worker.trim()) {
      runtime.worker = next.worker.trim();
    }
    companionImmersionRenderVisiblePanel();
  }

  function companionImmersionRenderVisiblePanel() {
    if (!companionImmersionIsCompanionRoute()) return;

    const api = window.apcCompanionImmersion;
    if (!api || typeof api.renderPanel !== "function") return;

    const mount = companionImmersionEnsureMount();
    if (!mount) return;

    const context = {
      ...runtime.job,
      ...runtime.resultPayload,
      lastUserMessage: runtime.lastUserMessage,
      state: runtime.state,
      job: runtime.job,
      resultPayload: runtime.resultPayload,
      job_id: runtime.job.job_id || runtime.job.id || runtime.resultPayload.job_id,
      status: runtime.job.status || runtime.resultPayload.status,
      job_type: runtime.job.job_type || runtime.resultPayload.job_type,
      requested_model: runtime.job.requested_model || runtime.resultPayload.requested_model,
      queue_write: runtime.queue_write,
      worker: runtime.worker,
    };

    mount.innerHTML = api.renderPanel(context);
  }

  function companionImmersionExtractMessageFromBody(body) {
    if (!body) return "";

    try {
      if (typeof body === "string") {
        const parsed = JSON.parse(body);
        return companionImmersionExtractMessageFromObject(parsed);
      }

      if (body instanceof FormData) {
        for (const key of ["message", "user_message", "prompt", "text", "input"]) {
          const value = body.get(key);
          if (typeof value === "string" && value.trim()) return value.trim();
        }
      }

      if (body instanceof URLSearchParams) {
        for (const key of ["message", "user_message", "prompt", "text", "input"]) {
          const value = body.get(key);
          if (typeof value === "string" && value.trim()) return value.trim();
        }
      }
    } catch (_) {
      return "";
    }

    return "";
  }

  function companionImmersionExtractMessageFromObject(payload) {
    if (!payload || typeof payload !== "object") return "";

    for (const key of ["message", "user_message", "prompt", "text", "input", "content"]) {
      const value = payload[key];
      if (typeof value === "string" && value.trim()) return value.trim();
    }

    for (const value of Object.values(payload)) {
      if (value && typeof value === "object") {
        const nested = companionImmersionExtractMessageFromObject(value);
        if (nested) return nested;
      }
    }

    return "";
  }

  function companionImmersionExtractJobFromPayload(payload) {
    if (!payload || typeof payload !== "object") return {};

    const job = payload.job && typeof payload.job === "object" ? payload.job : payload;
    const jobId = payload.job_id || payload.id || job.job_id || job.id;
    const status = payload.status || job.status;
    const jobType = payload.job_type || job.job_type;
    const requestedModel = payload.requested_model || job.requested_model;

    return {
      ...(jobId ? { job_id: jobId, id: jobId } : {}),
      ...(status ? { status } : {}),
      ...(jobType ? { job_type: jobType } : {}),
      ...(requestedModel ? { requested_model: requestedModel } : {}),
    };
  }

  function companionImmersionProcessQueuedChatResponse(url, method, payload) {
    if (!payload || typeof payload !== "object") return;

    const job = companionImmersionExtractJobFromPayload(payload);
    const api = window.apcCompanionImmersion;
    const resultText = api?.extractResultText?.(payload) || api?.extractResultText?.(payload.result || {}) || "";

    let state = "listening";
    const status = String(job.status || payload.status || "").toLowerCase();

    if (payload.error || status === "failed" || status === "error") {
      state = "needs_attention";
    } else if (resultText || status === "completed" || status === "complete") {
      state = "speaking";
    } else if (method === "POST" || status === "queued" || status === "running" || status === "pending" || status === "claimed") {
      state = "thinking";
    }

    companionImmersionSetRuntime({
      state,
      job,
      resultPayload: payload,
      queue_write: typeof payload.queue_write === "undefined" ? false : payload.queue_write,
    });
  }

  function companionImmersionInstallFetchObserver() {
    if (window.__apcCompanionImmersionFetchObserverInstalled) return;
    window.__apcCompanionImmersionFetchObserverInstalled = true;

    const originalFetch = window.fetch;
    if (typeof originalFetch !== "function") return;

    window.fetch = async function apcCompanionImmersionObservedFetch(input, init = {}) {
      const url = typeof input === "string" ? input : String(input?.url || "");
      const method = String(init?.method || input?.method || "GET").toUpperCase();
      const isQueuedChat = url.includes(QUEUED_CHAT_PATH);

      if (isQueuedChat && method === "POST") {
        const message = companionImmersionExtractMessageFromBody(init?.body);
        companionImmersionSetRuntime({
          lastUserMessage: message || runtime.lastUserMessage,
          state: "thinking",
          job: { status: "queued" },
          queue_write: true,
        });
      }

      const response = await originalFetch.apply(this, arguments);

      if (isQueuedChat && response && typeof response.clone === "function") {
        response.clone().json().then((payload) => {
          companionImmersionProcessQueuedChatResponse(url, method, payload);
        }).catch(() => {
          if (method === "POST") {
            companionImmersionSetRuntime({ state: "thinking" });
          }
        });
      }

      return response;
    };
  }

  function companionImmersionScheduleRender() {
    window.requestAnimationFrame(() => {
      companionImmersionRenderVisiblePanel();
    });
  }

  companionImmersionInstallFetchObserver();
  document.addEventListener("DOMContentLoaded", companionImmersionScheduleRender);
  window.addEventListener("popstate", companionImmersionScheduleRender);
  window.addEventListener("hashchange", companionImmersionScheduleRender);
  window.addEventListener("apc:route-rendered", companionImmersionScheduleRender);

  const observer = new MutationObserver(() => {
    companionImmersionScheduleRender();
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });

  window.apcCompanionImmersionRuntime = Object.freeze({
    set: companionImmersionSetRuntime,
    render: companionImmersionRenderVisiblePanel,
  });

  companionImmersionScheduleRender();
})();



/*
 * Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement.
 *
 * Source-only UI refinement:
 * - Move the visible Immersion panel into the main Companion workspace instead of leaving it above the page.
 * - Keep the existing queue/message flow intact.
 * - Collapse debug-like details by default.
 * - Preserve result-reader and queued chat behavior.
 * - Keep the model label aligned with the proven qwen2.5:0.5b queue-worker path when the old fallback text is rendered.
 */
(function stage16FcO45EAzCompanionImmersionPrimaryWorkspace() {
  if (window.__apcCompanionStructuralMinimalMode) {
    window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceSkippedForStructuralMinimalMode = true;
    return;
  }

  if (window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceInstalled) {
    return;
  }
  window.__stage16FcO45EAzCompanionImmersionPrimaryWorkspaceInstalled = true;

  const AZ_MARKER = "stage16FcO45EAzCompanionImmersionPrimaryWorkspace";

  function safeText(node) {
    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
  }

  function findHeadingByText(root, text) {
    const expected = String(text || "").toLowerCase();
    return Array.from(root.querySelectorAll("h1,h2,h3,h4,h5,h6,strong,legend"))
      .find((node) => safeText(node).toLowerCase() === expected) || null;
  }

  function candidateContainerFor(node) {
    if (!node) return null;
    return node.closest("section, article, main, .card, .panel, .view, .page, .workspace, div") || null;
  }

  function findCompanionWorkspace() {
    const root = document.querySelector("main") || document.body;
    const headings = Array.from(root.querySelectorAll("h1,h2,h3,h4"));
    const companionHeading = headings.find((heading) => {
      const text = safeText(heading).toLowerCase();
      if (text !== "companion") return false;
      const container = candidateContainerFor(heading);
      return container && /supportive chat workspace|talk with your local companion|start a companion conversation/i.test(safeText(container));
    });
    if (companionHeading) {
      const section = companionHeading.closest("section, article, .card, .panel, .view, .page, main, div");
      if (section) return section;
    }
    return root;
  }

  function findConversationAnchor(workspace) {
    const conversationHeading = findHeadingByText(workspace, "Conversation");
    if (conversationHeading) {
      return candidateContainerFor(conversationHeading) || conversationHeading;
    }

    const startHeading = Array.from(workspace.querySelectorAll("h1,h2,h3,h4,h5,h6,strong"))
      .find((node) => /start a companion conversation/i.test(safeText(node)));
    if (startHeading) {
      return candidateContainerFor(startHeading) || startHeading;
    }

    return workspace.firstElementChild || workspace;
  }

  function moveImmersionPanelIntoWorkspace() {
    const panelHost = document.getElementById("companionImmersionVisiblePanel");
    if (!panelHost) return false;

    const workspace = findCompanionWorkspace();
    if (!workspace || panelHost.closest("#companionImmersionPrimaryWorkspace")) {
      return false;
    }

    let primaryHost = document.getElementById("companionImmersionPrimaryWorkspace");
    if (!primaryHost) {
      primaryHost = document.createElement("section");
      primaryHost.id = "companionImmersionPrimaryWorkspace";
      primaryHost.className = "companion-immersion-primary-workspace";
      primaryHost.setAttribute("data-stage16-fc-o45-e-az", AZ_MARKER);
      primaryHost.setAttribute("aria-label", "Companion Immersion");
    }

    if (panelHost.parentElement !== primaryHost) {
      primaryHost.appendChild(panelHost);
    }

    const anchor = findConversationAnchor(workspace);
    if (anchor && primaryHost.parentElement !== workspace) {
      workspace.insertBefore(primaryHost, anchor);
    } else if (!primaryHost.parentElement) {
      workspace.insertBefore(primaryHost, workspace.firstChild);
    }

    return true;
  }

  function collapseImmersionDebugByDefault() {
    const details = document.querySelectorAll(
      "#companionImmersionPrimaryWorkspace details, #companionImmersionVisiblePanel details, .companion-immersion-debug"
    );
    details.forEach((node) => {
      if (node.tagName && node.tagName.toLowerCase() === "details") {
        node.open = false;
      }
    });
  }

  function softenLegacyConversationDebug() {
    const workspace = findCompanionWorkspace();

    Array.from(workspace.querySelectorAll("*")).forEach((node) => {
      if (node.children && node.children.length > 3) return;
      const text = safeText(node);
      if (text === "Companion status" || text === "How this works" || text === "Study phrases") {
        const block = candidateContainerFor(node);
        if (block && block !== workspace && !block.closest("#companionImmersionPrimaryWorkspace")) {
          block.classList.add("companion-legacy-debug-secondary");
        }
      }
    });

    Array.from(workspace.querySelectorAll("*")).forEach((node) => {
      if (node.childNodes.length !== 1 || node.children.length) return;
      if (safeText(node) === "fallback: gemma4:e4b") {
        node.textContent = "fallback: qwen2.5:0.5b";
        node.setAttribute("data-stage16-fc-o45-e-az-model-label", "qwen2.5:0.5b");
      }
    });
  }

  function applyCompanionImmersionPrimaryWorkspace() {
    moveImmersionPanelIntoWorkspace();
    collapseImmersionDebugByDefault();
    softenLegacyConversationDebug();
  }

  let scheduled = false;
  function scheduleApply() {
    if (scheduled) return;
    scheduled = true;
    window.requestAnimationFrame(() => {
      scheduled = false;
      applyCompanionImmersionPrimaryWorkspace();
    });
  }

  document.addEventListener("DOMContentLoaded", scheduleApply);
  window.addEventListener("load", scheduleApply);
  window.addEventListener("hashchange", scheduleApply);
  window.addEventListener("popstate", scheduleApply);

  const observer = new MutationObserver(scheduleApply);
  observer.observe(document.documentElement, { childList: true, subtree: true });

  window.apcCompanionImmersionPrimaryWorkspace = Object.freeze({
    marker: AZ_MARKER,
    apply: applyCompanionImmersionPrimaryWorkspace,
  });

  scheduleApply();
})();



/*
 * Stage 16 FC-O45-E-BB Companion clean chat workspace.
 *
 * Source-only UI refinement:
 * - Hide Companion auth test, Companion status, How this works, Study phrases, and Companion result reader from the primary user flow.
 * - Remove the debug/product header feel from the Companion page.
 * - Rename the chat card to "Chat with your Companion".
 * - Add Enter-to-send for the Companion message box while preserving Shift+Enter for a newline.
 * - Preserve existing queued chat endpoint, polling flow, result reader code, and backend behavior.
 */
(function stage16FcO45EBbCompanionCleanChatWorkspace() {
  if (window.__apcCompanionStructuralMinimalMode) {
    window.__stage16FcO45EBbCompanionCleanChatWorkspaceSkippedForStructuralMinimalMode = true;
    return;
  }

  if (window.__stage16FcO45EBbCompanionCleanChatWorkspaceInstalled) {
    return;
  }
  window.__stage16FcO45EBbCompanionCleanChatWorkspaceInstalled = true;

  const BB_MARKER = "stage16FcO45EBbCompanionCleanChatWorkspace";

  function safeText(node) {
    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
  }

  function allElements() {
    return Array.from((document.querySelector("main") || document.body).querySelectorAll("*"));
  }

  function closestBlock(node) {
    if (!node) return null;
    return node.closest("section, article, fieldset, .card, .panel, .summary-box, .auth-card, .status-card, .result-card, div");
  }

  function hideBlockByContent(requiredText, reason) {
    const needle = String(requiredText || "").toLowerCase();
    const match = allElements().find((node) => {
      const text = safeText(node).toLowerCase();
      return text.includes(needle);
    });
    if (!match) return false;
    const block = closestBlock(match);
    if (!block || block === document.body || block === document.documentElement) return false;
    block.classList.add("companion-clean-hidden");
    block.setAttribute("data-stage16-fc-o45-e-bb-hidden", reason);
    return true;
  }

  function hideExactTextElement(text, reason) {
    const wanted = String(text || "").toLowerCase();
    let didHide = false;
    allElements().forEach((node) => {
      if (safeText(node).toLowerCase() === wanted) {
        node.classList.add("companion-clean-hidden");
        node.setAttribute("data-stage16-fc-o45-e-bb-hidden", reason);
        didHide = true;
      }
    });
    return didHide;
  }

  function renameText(oldText, newText) {
    const wanted = String(oldText || "").toLowerCase();
    allElements().forEach((node) => {
      if (node.children && node.children.length) return;
      if (safeText(node).toLowerCase() === wanted) {
        node.textContent = newText;
        node.setAttribute("data-stage16-fc-o45-e-bb-renamed", "chat-title");
      }
    });
  }

  function cleanCompanionChrome() {
    hideBlockByContent("Checks your signed-in Companion connection without creating a queue job.", "companion-auth-test");
    hideBlockByContent("Read a completed Companion job result by job id.", "companion-result-reader");
    hideBlockByContent("Messages continue through /api/chat/queued.", "how-this-works");
    hideBlockByContent("Use natural phrases with Companion to control Study sessions.", "study-phrases");
    hideBlockByContent("Companion status Status Ready Queue", "companion-status");

    hideExactTextElement("Supportive chat workspace", "supportive-chat-subtitle");
    hideExactTextElement("Talk with your local Companion while the queue handles work safely behind the scenes.", "supportive-chat-description");
    hideExactTextElement("Queue-aware UI", "queue-aware-chip");

    renameText("Start a Companion conversation", "Chat with your Companion");
    renameText("Start a companion conversation", "Chat with your Companion");

    allElements().forEach((node) => {
      const text = safeText(node);
      if (text === "Send a message below. New work still uses the existing queued chat endpoint and polling flow.") {
        node.classList.add("companion-clean-hidden");
        node.setAttribute("data-stage16-fc-o45-e-bb-hidden", "queued-chat-explanation");
      }
      if (text === "Send a message to start a queued local AI chat.") {
        node.textContent = "Type a message and press Enter to send.";
        node.setAttribute("data-stage16-fc-o45-e-bb-renamed", "message-helper");
      }
    });
  }

  function findCompanionMessageField() {
    const fields = Array.from(document.querySelectorAll("textarea, input[type='text'], input:not([type])"));
    return fields.find((field) => {
      const labelText = safeText(field.closest("label") || field.parentElement || document.body).toLowerCase();
      const nameish = [
        field.getAttribute("name"),
        field.getAttribute("id"),
        field.getAttribute("placeholder"),
        field.getAttribute("aria-label")
      ].filter(Boolean).join(" ").toLowerCase();
      return /message|companion|chat/.test(labelText + " " + nameish);
    }) || null;
  }

  function findSendButton(field) {
    const form = field ? field.closest("form") : null;
    const root = form || (document.querySelector("main") || document.body);
    return Array.from(root.querySelectorAll("button, input[type='submit']"))
      .find((button) => /send message|send/i.test(safeText(button) || button.value || "")) || null;
  }

  function installEnterToSend() {
    const field = findCompanionMessageField();
    if (!field || field.dataset.stage16FcO45EBbEnterToSend === "1") return false;

    field.dataset.stage16FcO45EBbEnterToSend = "1";
    field.addEventListener("keydown", (event) => {
      if (event.key !== "Enter") return;
      if (event.shiftKey) return;

      const tag = String(field.tagName || "").toLowerCase();
      if (tag === "textarea" || tag === "input") {
        event.preventDefault();
      }

      const sendButton = findSendButton(field);
      if (sendButton && !sendButton.disabled) {
        sendButton.click();
      } else {
        const form = field.closest("form");
        if (form && typeof form.requestSubmit === "function") {
          form.requestSubmit();
        }
      }
    });

    field.setAttribute("data-stage16-fc-o45-e-bb-enter-to-send", "true");
    return true;
  }

  function applyCleanChatWorkspace() {
    cleanCompanionChrome();
    installEnterToSend();
  }

  let scheduled = false;
  function scheduleApply() {
    if (scheduled) return;
    scheduled = true;
    window.requestAnimationFrame(() => {
      scheduled = false;
      applyCleanChatWorkspace();
    });
  }

  document.addEventListener("DOMContentLoaded", scheduleApply);
  window.addEventListener("load", scheduleApply);
  window.addEventListener("hashchange", scheduleApply);
  window.addEventListener("popstate", scheduleApply);

  const observer = new MutationObserver(scheduleApply);
  observer.observe(document.documentElement, { childList: true, subtree: true });

  window.apcCompanionCleanChatWorkspace = Object.freeze({
    marker: BB_MARKER,
    apply: applyCleanChatWorkspace,
    installEnterToSend,
  });

  scheduleApply();
})();


/*
 * Stage 16 FC-O45-E-BD Companion hard-clean visible workspace.
 *
 * Corrective source patch after BC browser observation:
 * BB changed labels and Enter-to-send, but its first-match hide logic could match a broad page container
 * before finding the actual small card/panel. BD instead hides the smallest matching panel-like block.
 *
 * Target visible primary flow:
 * - Chat with your Companion
 * - Conversation
 * - Message
 * - Send message
 * - Clear
 *
 * Hidden from the primary flow:
 * - Companion auth test
 * - Supportive chat workspace text/chip/header chrome
 * - Companion status
 * - How this works
 * - Study phrases
 * - Companion result reader
 */
(function stage16FcO45EBdCompanionHardCleanVisibleWorkspace() {
  if (window.__apcCompanionStructuralMinimalMode) {
    window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceSkippedForStructuralMinimalMode = true;
    return;
  }

  if (window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceInstalled) {
    return;
  }
  window.__stage16FcO45EBdCompanionHardCleanVisibleWorkspaceInstalled = true;

  const BD_MARKER = "stage16FcO45EBdCompanionHardCleanVisibleWorkspace";

  const HIDE_RULES = [
    {
      reason: "companion-auth-test",
      any: [
        "Companion auth test",
        "Checks your signed-in Companion connection without creating a queue job."
      ]
    },
    {
      reason: "supportive-chat-workspace",
      any: [
        "Supportive chat workspace",
        "Talk with your local Companion while the queue handles work safely behind the scenes.",
        "Queue-aware UI"
      ]
    },
    {
      reason: "queued-chat-explanation",
      any: [
        "Send a message below. New work still uses the existing queued chat endpoint and polling flow."
      ]
    },
    {
      reason: "companion-status",
      any: [
        "Companion status",
        "Worker Companion queue worker Model fallback: qwen2.5:0.5b"
      ]
    },
    {
      reason: "how-this-works",
      any: [
        "How this works",
        "Messages continue through /api/chat/queued. The page polls the existing job status endpoint and displays the final assistant reply without changing backend behavior."
      ]
    },
    {
      reason: "study-phrases",
      any: [
        "Study phrases",
        "Use natural phrases with Companion to control Study sessions."
      ]
    },
    {
      reason: "companion-result-reader",
      any: [
        "Companion result reader",
        "Read a completed Companion job result by job id.",
        "Latest submitted Companion job id"
      ]
    }
  ];

  function safeText(node) {
    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
  }

  function isProtectedPrimaryChat(node) {
    const text = safeText(node);
    return text.includes("Chat with your Companion") ||
      text.includes("Conversation") ||
      text.includes("Type a message and press Enter to send.") ||
      text.includes("Send message") ||
      text.includes("Clear");
  }

  function isTooBroad(node) {
    if (!node) return true;
    const tag = String(node.tagName || "").toLowerCase();
    if (tag === "html" || tag === "body" || tag === "main") return true;
    if (node.id === "app" || node.id === "root") return true;
    return false;
  }

  function panelCandidates() {
    const root = document.querySelector("main") || document.body;
    return Array.from(root.querySelectorAll("section, article, fieldset, form, .card, .panel, .summary-box, .auth-card, .status-card, .result-card, .stage5p8h-status-card, .stage5p8h-empty-state, .stage5p8h-card, div"))
      .filter((node) => !isTooBroad(node));
  }

  function smallestMatchingPanel(phrases) {
    const needles = phrases.map((item) => String(item || "").toLowerCase()).filter(Boolean);
    const matches = panelCandidates().filter((node) => {
      const text = safeText(node).toLowerCase();
      if (!text) return false;
      if (isProtectedPrimaryChat(node) && !needles.some((needle) => needle.includes("supportive chat workspace") || needle.includes("companion status") || needle.includes("companion result reader"))) {
        return false;
      }
      return needles.some((needle) => text.includes(needle));
    });

    matches.sort((a, b) => {
      const aText = safeText(a);
      const bText = safeText(b);
      const aChildren = a.querySelectorAll("*").length;
      const bChildren = b.querySelectorAll("*").length;
      return (aText.length - bText.length) || (aChildren - bChildren);
    });

    return matches[0] || null;
  }

  function hideNode(node, reason) {
    if (!node || isTooBroad(node)) return false;
    node.classList.add("companion-hard-clean-hidden");
    node.classList.add("companion-clean-hidden");
    node.setAttribute("hidden", "");
    node.setAttribute("aria-hidden", "true");
    node.setAttribute("data-stage16-fc-o45-e-bd-hidden", reason);
    return true;
  }

  function hideSmallestPanels() {
    HIDE_RULES.forEach((rule) => {
      const panel = smallestMatchingPanel(rule.any);
      if (panel) {
        hideNode(panel, rule.reason);
      }
    });
  }

  function hideLooseTextChrome() {
    const root = document.querySelector("main") || document.body;
    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,div")).forEach((node) => {
      if (node.children && node.children.length > 0) return;
      const text = safeText(node);
      if (!text) return;
      const exactHide = [
        "Companion auth test",
        "Supportive chat workspace",
        "Talk with your local Companion while the queue handles work safely behind the scenes.",
        "Queue-aware UI",
        "How this works",
        "Study phrases",
        "Companion result reader"
      ];
      if (exactHide.includes(text)) {
        hideNode(node, "loose-text-chrome");
      }
    });
  }

  function reinforceCleanTitleAndSendCopy() {
    const root = document.querySelector("main") || document.body;
    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,label,div")).forEach((node) => {
      if (node.children && node.children.length > 0) return;
      const text = safeText(node);
      if (text === "Start a Companion conversation" || text === "Start a companion conversation") {
        node.textContent = "Chat with your Companion";
        node.setAttribute("data-stage16-fc-o45-e-bd-renamed", "chat-title");
      }
      if (text === "Send a message to start a queued local AI chat.") {
        node.textContent = "Type a message and press Enter to send.";
        node.setAttribute("data-stage16-fc-o45-e-bd-renamed", "message-helper");
      }
    });
  }

  function ensureEnterToSendStillInstalled() {
    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
      window.apcCompanionCleanChatWorkspace.installEnterToSend();
    }
  }

  function applyHardClean() {
    reinforceCleanTitleAndSendCopy();
    hideSmallestPanels();
    hideLooseTextChrome();
    ensureEnterToSendStillInstalled();
  }

  let scheduled = false;
  function scheduleApply() {
    if (scheduled) return;
    scheduled = true;
    window.requestAnimationFrame(() => {
      scheduled = false;
      applyHardClean();
    });
  }

  document.addEventListener("DOMContentLoaded", scheduleApply);
  window.addEventListener("load", scheduleApply);
  window.addEventListener("hashchange", scheduleApply);
  window.addEventListener("popstate", scheduleApply);

  const observer = new MutationObserver(scheduleApply);
  observer.observe(document.documentElement, { childList: true, subtree: true, characterData: true });

  window.apcCompanionHardCleanWorkspace = Object.freeze({
    marker: BD_MARKER,
    apply: applyHardClean,
    hideSmallestPanels,
  });

  scheduleApply();
})();


/*
 * Stage 16 FC-O45-E-BF Companion minimal chat source.
 *
 * Corrective source patch after BE browser observation:
 * - Remove the remaining "Listening / Debug details / Companion" chrome from the primary Companion flow.
 * - Remove the extra "Chat with your Companion" heading from the card.
 * - Remove queued-endpoint explanation copy from the card.
 * - Keep only the actual chat controls and conversation area visible.
 *
 * Target visible primary flow:
 * - Conversation
 * - Type a message and press Enter to send.
 * - Message
 * - Send message
 * - Clear
 */
(function stage16FcO45EBfCompanionMinimalChatSource() {
  if (window.__apcCompanionStructuralMinimalMode) {
    window.__stage16FcO45EBfCompanionMinimalChatSourceSkippedForStructuralMinimalMode = true;
    return;
  }

  if (window.__stage16FcO45EBfCompanionMinimalChatSourceInstalled) {
    return;
  }
  window.__stage16FcO45EBfCompanionMinimalChatSourceInstalled = true;

  const BF_MARKER = "stage16FcO45EBfCompanionMinimalChatSource";

  function safeText(node) {
    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
  }

  function hideNode(node, reason) {
    if (!node) return false;
    const tag = String(node.tagName || "").toLowerCase();
    if (tag === "html" || tag === "body" || tag === "main") return false;
    node.classList.add("companion-minimal-chat-hidden");
    node.classList.add("companion-hard-clean-hidden");
    node.classList.add("companion-clean-hidden");
    node.setAttribute("hidden", "");
    node.setAttribute("aria-hidden", "true");
    node.setAttribute("data-stage16-fc-o45-e-bf-hidden", reason);
    return true;
  }

  function hideExactLooseText(text, reason) {
    const root = document.querySelector("main") || document.body;
    const wanted = String(text || "").toLowerCase();
    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,div")).forEach((node) => {
      if (node.children && node.children.length > 0) return;
      if (safeText(node).toLowerCase() === wanted) {
        hideNode(node, reason);
      }
    });
  }

  function hidePanelContaining(text, reason) {
    const root = document.querySelector("main") || document.body;
    const wanted = String(text || "").toLowerCase();
    const candidates = Array.from(root.querySelectorAll("section, article, fieldset, .card, .panel, .summary-box, div"))
      .filter((node) => {
        const tag = String(node.tagName || "").toLowerCase();
        if (tag === "main" || node.id === "app" || node.id === "root") return false;
        return safeText(node).toLowerCase().includes(wanted);
      });

    candidates.sort((a, b) => {
      return (safeText(a).length - safeText(b).length) ||
        (a.querySelectorAll("*").length - b.querySelectorAll("*").length);
    });

    if (candidates[0]) {
      hideNode(candidates[0], reason);
      return true;
    }
    return false;
  }

  function hideImmersionChrome() {
    const immersionHosts = [
      document.getElementById("companionImmersionPrimaryWorkspace"),
      document.getElementById("companionImmersionVisiblePanel")
    ].filter(Boolean);

    immersionHosts.forEach((node) => hideNode(node, "immersion-status-chrome"));

    hideExactLooseText("Listening", "immersion-listening-text");
    hideExactLooseText("Debug details", "immersion-debug-details-text");
  }

  function hideCompanionPageHeaderChrome() {
    hideExactLooseText("Companion", "page-companion-heading");
    hideExactLooseText("Supportive chat workspace", "supportive-chat-subtitle");
    hideExactLooseText("Talk with your local Companion while the queue handles work safely behind the scenes.", "supportive-chat-description");
    hideExactLooseText("Queue-aware UI", "queue-aware-chip");
  }

  function hideExtraChatCardHeadingAndCopy() {
    hideExactLooseText("Chat with your Companion", "extra-chat-heading");
    hideExactLooseText("Send a message below. New work still uses the existing queued chat endpoint and polling flow.", "queued-endpoint-explanation");
    hidePanelContaining("Send a message below. New work still uses the existing queued chat endpoint and polling flow.", "queued-endpoint-explanation-panel");
  }

  function preservePrimaryChatControls() {
    const root = document.querySelector("main") || document.body;
    Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,label,div")).forEach((node) => {
      if (node.children && node.children.length > 0) return;
      const text = safeText(node);
      if (text === "Send a message to start a queued local AI chat.") {
        node.textContent = "Type a message and press Enter to send.";
        node.setAttribute("data-stage16-fc-o45-e-bf-renamed", "message-helper");
      }
    });

    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
      window.apcCompanionCleanChatWorkspace.installEnterToSend();
    }
  }

  function applyMinimalChat() {
    hideImmersionChrome();
    hideCompanionPageHeaderChrome();
    hideExtraChatCardHeadingAndCopy();
    preservePrimaryChatControls();
  }

  let scheduled = false;
  function scheduleApply() {
    if (scheduled) return;
    scheduled = true;
    window.requestAnimationFrame(() => {
      scheduled = false;
      applyMinimalChat();
    });
  }

  document.addEventListener("DOMContentLoaded", scheduleApply);
  window.addEventListener("load", scheduleApply);
  window.addEventListener("hashchange", scheduleApply);
  window.addEventListener("popstate", scheduleApply);

  const observer = new MutationObserver(scheduleApply);
  observer.observe(document.documentElement, { childList: true, subtree: true, characterData: true });

  window.apcCompanionMinimalChatWorkspace = Object.freeze({
    marker: BF_MARKER,
    apply: applyMinimalChat,
  });

  scheduleApply();
})();


/*
 * Stage 16 FC-O45-E-BH Companion dedupe minimal visible source.
 *
 * Corrective source patch after BG browser observation:
 * - Hide remaining Thinking / Debug details / Immersion chrome.
 * - Hide remaining Study phrases helper block.
 * - Hide the decorative chat icon.
 * - Deduplicate repeated visible "You ..." and "Assistant ..." message rows.
 * - Avoid another continuous MutationObserver loop; use a bounded cleanup pass.
 *
 * Target visible primary flow:
 * - Conversation
 * - Type a message and press Enter to send.
 * - Message
 * - Send message
 * - Clear
 */
(function stage16FcO45EBhCompanionDedupeMinimalVisibleSource() {
  if (window.__apcCompanionStructuralMinimalMode) {
    window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceSkippedForStructuralMinimalMode = true;
    return;
  }

  if (window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceInstalled) {
    return;
  }
  window.__stage16FcO45EBhCompanionDedupeMinimalVisibleSourceInstalled = true;

  const BH_MARKER = "stage16FcO45EBhCompanionDedupeMinimalVisibleSource";

  function safeText(node) {
    return (node && node.textContent ? node.textContent : "").replace(/\s+/g, " ").trim();
  }

  function hideNode(node, reason) {
    if (!node) return false;
    const tag = String(node.tagName || "").toLowerCase();
    if (tag === "html" || tag === "body" || tag === "main") return false;
    node.classList.add("companion-dedupe-minimal-hidden");
    node.classList.add("companion-minimal-chat-hidden");
    node.classList.add("companion-hard-clean-hidden");
    node.classList.add("companion-clean-hidden");
    node.setAttribute("hidden", "");
    node.setAttribute("aria-hidden", "true");
    node.setAttribute("data-stage16-fc-o45-e-bh-hidden", reason);
    return true;
  }

  function isHidden(node) {
    return !node || node.hidden || node.getAttribute("aria-hidden") === "true" ||
      node.classList.contains("companion-dedupe-minimal-hidden") ||
      node.classList.contains("companion-minimal-chat-hidden") ||
      node.classList.contains("companion-hard-clean-hidden") ||
      node.classList.contains("companion-clean-hidden");
  }

  function leafishElements(root) {
    return Array.from(root.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,li,div"))
      .filter((node) => !isHidden(node))
      .filter((node) => node.querySelectorAll("h1,h2,h3,h4,p,span,strong,small,li,button,input,textarea").length <= 2);
  }

  function hideExactLooseText(root, text, reason) {
    const wanted = String(text || "").toLowerCase();
    leafishElements(root).forEach((node) => {
      if (safeText(node).toLowerCase() === wanted) {
        hideNode(node, reason);
      }
    });
  }

  function smallestPanelContaining(root, text) {
    const wanted = String(text || "").toLowerCase();
    const candidates = Array.from(root.querySelectorAll("section, article, fieldset, .card, .panel, .summary-box, div"))
      .filter((node) => {
        if (isHidden(node)) return false;
        const tag = String(node.tagName || "").toLowerCase();
        if (tag === "main" || node.id === "app" || node.id === "root") return false;
        return safeText(node).toLowerCase().includes(wanted);
      });

    candidates.sort((a, b) => {
      return (safeText(a).length - safeText(b).length) ||
        (a.querySelectorAll("*").length - b.querySelectorAll("*").length);
    });

    return candidates[0] || null;
  }

  function hideRemainingChrome(root) {
    [
      "Thinking",
      "Listening",
      "Speaking",
      "Debug details",
      "Companion",
      "Study phrases",
      "Use natural phrases with Companion to control Study sessions.",
      "Start: “Study session start” or “Start a study session.”",
      "Pause: “Study session pause.”",
      "Resume: “Study session resume.”",
      "Stop: “Study session stop.”",
      "Answer: “Read the answer.”",
      "Mark: “Correct,” “wrong,” or “skip.”",
      "💬"
    ].forEach((text) => hideExactLooseText(root, text, "remaining-chrome"));

    [
      "Use natural phrases with Companion to control Study sessions.",
      "Start: “Study session start” or “Start a study session.”",
      "Study phrases"
    ].forEach((text) => {
      const panel = smallestPanelContaining(root, text);
      if (panel) hideNode(panel, "study-phrases-panel");
    });

    [
      document.getElementById("companionImmersionPrimaryWorkspace"),
      document.getElementById("companionImmersionVisiblePanel")
    ].filter(Boolean).forEach((node) => hideNode(node, "immersion-chrome-panel"));
  }

  function normalizeMessageText(text) {
    return String(text || "")
      .replace(/\s+/g, " ")
      .replace(/^You\s*:\s*/i, "You ")
      .replace(/^Assistant\s*:\s*/i, "Assistant ")
      .trim();
  }

  function messageKeyFor(text) {
    const normalized = normalizeMessageText(text);
    if (/^You\s+\S.+/i.test(normalized)) {
      return normalized.replace(/^You\s+/i, "you:");
    }
    if (/^Assistant\s+\S.+/i.test(normalized)) {
      return normalized.replace(/^Assistant\s+/i, "assistant:");
    }
    return "";
  }

  function dedupeVisibleMessages(root) {
    const seen = new Set();
    const candidates = leafishElements(root)
      .filter((node) => {
        const text = normalizeMessageText(safeText(node));
        if (text.length < 6 || text.length > 420) return false;
        return /^You\s+\S.+/i.test(text) || /^Assistant\s+\S.+/i.test(text);
      });

    candidates.forEach((node) => {
      const key = messageKeyFor(safeText(node));
      if (!key) return;
      if (seen.has(key)) {
        hideNode(node, "duplicate-visible-message");
      } else {
        seen.add(key);
        node.setAttribute("data-stage16-fc-o45-e-bh-message-kept", "true");
      }
    });
  }

  function ensureEnterToSendStillInstalled() {
    if (window.apcCompanionCleanChatWorkspace && typeof window.apcCompanionCleanChatWorkspace.installEnterToSend === "function") {
      window.apcCompanionCleanChatWorkspace.installEnterToSend();
    }
  }

  function applyDedupeMinimalVisible() {
    const root = document.querySelector("main") || document.body;
    hideRemainingChrome(root);
    dedupeVisibleMessages(root);
    ensureEnterToSendStillInstalled();
  }

  function runBoundedCleanup() {
    let remaining = 12;
    function tick() {
      applyDedupeMinimalVisible();
      remaining -= 1;
      if (remaining > 0) {
        window.setTimeout(tick, 250);
      }
    }
    tick();
  }

  document.addEventListener("DOMContentLoaded", runBoundedCleanup);
  window.addEventListener("load", runBoundedCleanup);
  window.addEventListener("hashchange", runBoundedCleanup);
  window.addEventListener("popstate", runBoundedCleanup);

  window.apcCompanionDedupeMinimalVisible = Object.freeze({
    marker: BH_MARKER,
    apply: applyDedupeMinimalVisible,
    dedupeVisibleMessages,
    hideRemainingChrome,
  });

  runBoundedCleanup();
})();


/*
 * Stage 16 FC-O45-E-BJ-R4 Companion structural minimal runtime.
 *
 * The Companion route renders minimal chat DOM directly. This runtime only installs
 * Enter-to-send. It does not hide legacy panels after render and does not install a MutationObserver.
 */
(function stage16FcO45EBjR4CompanionStructuralMinimalRuntime() {
  if (window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled) {
    return;
  }
  window.__stage16FcO45EBjR4CompanionStructuralMinimalRuntimeInstalled = true;

  function installEnterToSend() {
    const form = document.getElementById("queuedChatForm");
    const textarea = document.getElementById("queuedChatInput");
    if (!form || !textarea || textarea.dataset.stage16FcO45EBjR4EnterInstalled === "true") {
      return;
    }
    textarea.dataset.stage16FcO45EBjR4EnterInstalled = "true";
    textarea.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" || event.shiftKey || event.ctrlKey || event.altKey || event.metaKey || event.isComposing) {
        return;
      }
      event.preventDefault();
      if (typeof form.requestSubmit === "function") {
        form.requestSubmit();
      } else {
        form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
      }
    });
  }

  function installMinimalHelpers() {
    installEnterToSend();
  }

  document.addEventListener("DOMContentLoaded", installMinimalHelpers);
  window.addEventListener("load", installMinimalHelpers);
  window.addEventListener("hashchange", () => window.setTimeout(installMinimalHelpers, 0));
  window.addEventListener("popstate", () => window.setTimeout(installMinimalHelpers, 0));

  window.apcCompanionStructuralMinimalWorkspace = Object.freeze({
    marker: "stage16FcO45EBjR4CompanionStructuralMinimalRuntime",
    apply: installMinimalHelpers,
    installEnterToSend,
  });

  installMinimalHelpers();
})();



/*
 * Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source.
 *
 * Fixes route-timing where the Companion tab can render after helper setup.
 * This is delegated on document, so it works for future #queuedChatInput nodes.
 * It does not install a MutationObserver and does not hide or rewrite DOM after render.
 */
(function stage16FcO45EBlCompanionDelegatedEnterToSend() {
  if (window.__stage16FcO45EBlCompanionDelegatedEnterToSendInstalled) {
    return;
  }
  window.__stage16FcO45EBlCompanionDelegatedEnterToSendInstalled = true;

  document.addEventListener("keydown", (event) => {
    const target = event.target;
    if (!target || target.id !== "queuedChatInput") {
      return;
    }
    if (event.key !== "Enter" || event.shiftKey || event.ctrlKey || event.altKey || event.metaKey || event.isComposing) {
      return;
    }

    const form = document.getElementById("queuedChatForm");
    if (!form) {
      return;
    }

    event.preventDefault();

    if (typeof form.requestSubmit === "function") {
      form.requestSubmit();
    } else {
      const submit = document.getElementById("queuedChatSendBtn");
      if (submit && typeof submit.click === "function") {
        submit.click();
      } else {
        form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
      }
    }
  }, true);

  window.apcCompanionDelegatedEnterToSend = Object.freeze({
    marker: "stage16FcO45EBlCompanionDelegatedEnterToSend",
    inputId: "queuedChatInput",
    formId: "queuedChatForm",
    sendButtonId: "queuedChatSendBtn",
  });
})();


/*
 * Stage 16 FC-O45-E-BS: Companion result-reader hard-refresh restore.
 *
 * Source-only layer. It does not submit jobs by itself and does not call any model.
 * It restores the last queued Companion job id after hard refresh, polls the
 * authenticated queued-job status endpoint, and renders completed response_text.
 */
(function stage16FcO45EBsCompanionResultReaderRefreshRestore() {
  const root = window;
  const marker = "stage16FcO45EBsCompanionResultReaderRefreshRestore";
  if (root[marker]) return;

  const storage = {
    jobId: "apcCompanionQueuedChatLastJobId",
    prompt: "apcCompanionQueuedChatLastPrompt",
    reply: "apcCompanionQueuedChatLastReply",
    status: "apcCompanionQueuedChatLastStatus",
    updatedAt: "apcCompanionQueuedChatLastUpdatedAt"
  };

  root[marker] = {
    installed: true,
    storageKey: storage.jobId,
    source: "frontend/wrapper-ui/app.js"
  };

  let pollGeneration = 0;
  let activePollJobId = "";
  let lastRenderSignature = "";
  let restoreScheduled = false;
  root.stage16FcO45EBvCompanionStableResultPoller = {
    installed: true,
    behavior: "single-flight poll until completed/failed, then stop and keep rendered result"
  };
  root.stage16FcO45EBxCompanionFinalRenderWins = {
    installed: true,
    behavior: "completed conversation render must win over later blank placeholder rerenders"
  };
  const originalFetch = typeof root.fetch === "function" ? root.fetch.bind(root) : null;

  function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function safeString(value) {
    if (value === null || value === undefined) return "";
    return String(value);
  }

  function escapeHtml(value) {
    return safeString(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function getToken() {
    try {
      return (
        (root.authState && root.authState.token) ||
        localStorage.getItem("edgeStudyToken") ||
        ""
      );
    } catch (_err) {
      return "";
    }
  }

  function getLast(key) {
    try {
      return localStorage.getItem(key) || "";
    } catch (_err) {
      return "";
    }
  }

  function setLast(key, value) {
    try {
      if (value === null || value === undefined || value === "") {
        localStorage.removeItem(key);
      } else {
        localStorage.setItem(key, String(value));
      }
    } catch (_err) {
      // Storage may be unavailable in private/browser-restricted contexts.
    }
  }

  function clearStoredConversation() {
    setLast(storage.jobId, "");
    setLast(storage.prompt, "");
    setLast(storage.reply, "");
    setLast(storage.status, "");
    setLast(storage.updatedAt, "");
    lastRenderSignature = "";
    const messagesEl = document.getElementById("queuedChatMessages");
    if (messagesEl) {
      messagesEl.removeAttribute("data-stage16-fc-o45-e-bx-render-signature");
    }
  }

  function findDeep(value, keys, depth) {
    if (!value || depth <= 0) return "";
    if (Array.isArray(value)) {
      for (const item of value) {
        const found = findDeep(item, keys, depth - 1);
        if (found) return found;
      }
      return "";
    }
    if (typeof value !== "object") return "";
    for (const key of keys) {
      if (Object.prototype.hasOwnProperty.call(value, key)) {
        const candidate = value[key];
        if (candidate !== null && candidate !== undefined && String(candidate).trim()) {
          return String(candidate);
        }
      }
    }
    for (const nested of Object.values(value)) {
      const found = findDeep(nested, keys, depth - 1);
      if (found) return found;
    }
    return "";
  }

  function normalizeQueuedJobPayload(payload) {
    const data = payload && typeof payload === "object" ? payload : {};
    const job = data.job && typeof data.job === "object" ? data.job : data;

    const jobId =
      safeString(data.job_id || data.id || job.job_id || job.id || getLast(storage.jobId)).trim();

    const prompt =
      safeString(data.prompt || job.prompt || findDeep(data, ["prompt"], 5) || getLast(storage.prompt)).trim();

    const requestedModel =
      safeString(data.requested_model || job.requested_model || findDeep(data, ["requested_model"], 5)).trim();

    const status =
      safeString(data.status || job.status || findDeep(data, ["status"], 5) || getLast(storage.status)).trim();

    const error =
      safeString(data.error || job.error || data.last_error || job.last_error || findDeep(data, ["error", "last_error"], 5)).trim();

    const responseText =
      safeString(
        data.response_text ||
        data.responseText ||
        data.assistant_reply ||
        data.assistantReply ||
        (data.result && (data.result.response_text || data.result.responseText)) ||
        (Array.isArray(data.results) && data.results[0] && (data.results[0].response_text || data.results[0].responseText)) ||
        findDeep(data, ["response_text", "responseText", "assistant_reply", "assistantReply", "completion", "output_text"], 6) ||
        getLast(storage.reply)
      ).trim();

    return { jobId, prompt, requestedModel, status, error, responseText };
  }

  function companionElementsReady() {
    return Boolean(
      document.getElementById("queuedChatMessages") &&
      document.getElementById("queuedChatForm")
    );
  }

  function setStatus(text) {
    const statusEl = document.getElementById("queuedChatStatus");
    if (statusEl) statusEl.textContent = text;
  }

  function renderConversation(view) {
    const messagesEl = document.getElementById("queuedChatMessages");
    if (!messagesEl) return false;

    const rows = [];
    if (view.prompt) {
      rows.push({
        role: "You",
        content: view.prompt,
        detail: view.jobId ? `Job ${view.jobId}${view.requestedModel ? ` · ${view.requestedModel}` : ""}` : ""
      });
    }

    if (view.responseText) {
      rows.push({
        role: "Assistant",
        content: view.responseText,
        detail: view.status ? `Status: ${view.status}` : "Completed"
      });
    } else if (view.status) {
      rows.push({
        role: view.status === "failed" ? "System" : "Companion",
        content: view.status === "failed" ? "The queued job failed." : `Queued job is ${view.status}.`,
        detail: view.error || (view.jobId ? `Job ${view.jobId}` : "")
      });
    }

    if (!rows.length) return false;

    const signature = JSON.stringify(rows);
    const domSignature = messagesEl.getAttribute("data-stage16-fc-o45-e-bx-render-signature") || "";
    const hasRenderedConversationRows = Boolean(
      messagesEl.querySelector && messagesEl.querySelector(".queued-chat-message")
    );
    if (signature === lastRenderSignature && signature === domSignature && hasRenderedConversationRows) {
      if (view.status) setStatus(view.status === "completed" ? "Complete" : view.status);
      return true;
    }
    lastRenderSignature = signature;
    messagesEl.setAttribute("data-stage16-fc-o45-e-bx-render-signature", signature);

    messagesEl.innerHTML = rows.map((msg) => `
      <article class="summary-card queued-chat-message">
        <span>${escapeHtml(msg.role)}</span>
        <strong>${escapeHtml(msg.content)}</strong>
        ${msg.detail ? `<p>${escapeHtml(msg.detail)}</p>` : ""}
      </article>
    `).join("");

    if (view.status) setStatus(view.status === "completed" ? "Complete" : view.status);
    return true;
  }

  function persistView(view) {
    if (view.jobId) setLast(storage.jobId, view.jobId);
    if (view.prompt) setLast(storage.prompt, view.prompt);
    if (view.responseText) setLast(storage.reply, view.responseText);
    if (view.status) setLast(storage.status, view.status);
    setLast(storage.updatedAt, new Date().toISOString());
  }

  function renderCachedConversation() {
    if (!companionElementsReady()) return false;
    const jobId = getLast(storage.jobId);
    const prompt = getLast(storage.prompt);
    const responseText = getLast(storage.reply);
    const status = getLast(storage.status);
    if (!jobId && !prompt && !responseText) return false;
    return renderConversation({ jobId, prompt, responseText, status });
  }

  async function fetchQueuedJob(jobId) {
    const token = getToken();
    const headers = { "Cache-Control": "no-cache" };
    if (token) headers.Authorization = `Bearer ${token}`;

    const res = await originalFetch(`/api/chat/queued/${encodeURIComponent(jobId)}`, {
      method: "GET",
      headers,
      cache: "no-store"
    });
    const text = await res.text();
    let data = null;
    try {
      data = text ? JSON.parse(text) : {};
    } catch (_err) {
      data = { error: text || `HTTP ${res.status}` };
    }
    if (!res.ok) {
      throw new Error(`Queued status HTTP ${res.status}: ${text.slice(0, 180)}`);
    }
    return data;
  }

  async function pollQueuedJob(jobId, options) {
    if (!originalFetch || !jobId) return;
    const normalizedJobId = safeString(jobId).trim();
    if (!normalizedJobId) return;

    const force = Boolean(options && options.force);
    const cachedStatus = getLast(storage.status);
    const cachedReply = getLast(storage.reply);
    const cachedJobId = getLast(storage.jobId);

    if (!force && cachedJobId === normalizedJobId && cachedStatus === "completed" && cachedReply) {
      renderCachedConversation();
      return;
    }

    if (!force && activePollJobId === normalizedJobId) {
      return;
    }

    activePollJobId = normalizedJobId;
    const generation = ++pollGeneration;
    const maxPolls = Math.max(1, Number((options && options.maxPolls) || 120));
    const intervalMs = Math.max(1000, Number((options && options.intervalMs) || 2000));

    try {
      for (let i = 0; i < maxPolls; i += 1) {
        if (generation !== pollGeneration) return;
        if (!companionElementsReady()) {
          await delay(intervalMs);
          continue;
        }

        try {
          setStatus(i === 0 ? "Waiting for worker..." : `Waiting for worker... poll ${i + 1}`);
          const payload = await fetchQueuedJob(normalizedJobId);
          const view = normalizeQueuedJobPayload(payload);
          if (!view.jobId) view.jobId = normalizedJobId;
          persistView(view);
          renderConversation(view);

          if (view.status === "completed" || view.status === "failed") {
            activePollJobId = "";
            return;
          }
        } catch (err) {
          setStatus("Result reader error");
          renderConversation({
            jobId: normalizedJobId,
            prompt: getLast(storage.prompt),
            status: "error",
            error: err && err.message ? err.message : String(err)
          });
          activePollJobId = "";
          return;
        }

        await delay(intervalMs);
      }

      activePollJobId = "";
      setStatus("Queued job is still waiting.");
      renderConversation({
        jobId: normalizedJobId,
        prompt: getLast(storage.prompt),
        status: "queued",
        error: "Still queued. The worker may not be running yet."
      });
    } finally {
      if (activePollJobId === normalizedJobId) activePollJobId = "";
    }
  }

  function restoreLastQueuedJob() {
    if (!companionElementsReady()) return false;
    const jobId = getLast(storage.jobId);
    if (!jobId) return false;

    const status = getLast(storage.status);
    const reply = getLast(storage.reply);

    renderCachedConversation();

    if ((status === "completed" && reply) || status === "failed") {
      return true;
    }

    pollQueuedJob(jobId, { maxPolls: 120, intervalMs: 2000 });
    return true;
  }

  function scheduleRestoreLastQueuedJob(delayMs) {
    if (restoreScheduled) return;
    restoreScheduled = true;
    setTimeout(() => {
      restoreScheduled = false;
      restoreLastQueuedJob();
    }, Math.max(0, Number(delayMs) || 0));
  }

  function capturePromptFromForm() {
    const input = document.getElementById("queuedChatInput");
    const message = input && input.value ? input.value.trim() : "";
    if (message) setLast(storage.prompt, message);
  }

  function extractUrl(input) {
    try {
      if (typeof input === "string") return input;
      if (input && input.url) return input.url;
    } catch (_err) {}
    return "";
  }

  function extractMethod(input, init) {
    return safeString((init && init.method) || (input && input.method) || "GET").toUpperCase();
  }

  function extractJobId(payload) {
    const data = payload && typeof payload === "object" ? payload : {};
    return safeString(
      data.job_id ||
      data.id ||
      (data.job && (data.job.job_id || data.job.id)) ||
      findDeep(data, ["job_id"], 4)
    ).trim();
  }

  if (originalFetch && !root.stage16FcO45EBsFetchWrapped) {
    root.stage16FcO45EBsFetchWrapped = true;
    root.fetch = async function stage16FcO45EBsFetch(input, init) {
      const method = extractMethod(input, init);
      const url = extractUrl(input);
      const response = await originalFetch(input, init);

      try {
        if (url.includes("/api/chat/queued")) {
          response.clone().json().then((payload) => {
            const jobId = extractJobId(payload);
            if (method !== "GET" && jobId) {
              setLast(storage.jobId, jobId);
              setLast(storage.status, "queued");
              setLast(storage.updatedAt, new Date().toISOString());
              pollQueuedJob(jobId, { maxPolls: 120, intervalMs: 2000, force: true });
            } else if (method === "GET") {
              const view = normalizeQueuedJobPayload(payload);
              if (view.jobId || view.status || view.responseText) {
                persistView(view);
                renderConversation(view);
              }
            }
          }).catch(() => {});
        }
      } catch (_err) {
        // Fetch wrapper must never break the original caller.
      }

      return response;
    };
  }

  document.addEventListener("submit", (event) => {
    const form = event.target;
    if (form && form.id === "queuedChatForm") {
      capturePromptFromForm();
      setStatus("Creating queued job...");
    }
  }, true);

  document.addEventListener("click", (event) => {
    const target = event.target && event.target.closest ? event.target.closest("#queuedChatClearBtn, a, button") : null;
    if (!target) return;
    if (target.id === "queuedChatClearBtn") {
      clearStoredConversation();
      return;
    }
    scheduleRestoreLastQueuedJob(120);
  }, true);

  window.addEventListener("DOMContentLoaded", () => {
    scheduleRestoreLastQueuedJob(0);
  });

  window.addEventListener("hashchange", () => {
    scheduleRestoreLastQueuedJob(120);
  });

  window.addEventListener("popstate", () => {
    scheduleRestoreLastQueuedJob(120);
  });

  let bootTicks = 0;
  const bootTimer = window.setInterval(() => {
    bootTicks += 1;
    const restored = restoreLastQueuedJob();
    if (restored || bootTicks >= 8) window.clearInterval(bootTimer);
  }, 500);

  try {
    const observerRoot = document.getElementById("app") || document.body;
    if (observerRoot && root.MutationObserver) {
      const observer = new MutationObserver(() => {
        if (document.getElementById("queuedChatForm")) {
          scheduleRestoreLastQueuedJob(120);
        }
      });
      observer.observe(observerRoot, { childList: true, subtree: true });
      root.stage16FcO45EBvCompanionStableResultPoller.observer = true;
    }
  } catch (_err) {
    root.stage16FcO45EBvCompanionStableResultPoller.observer = false;
  }

  scheduleRestoreLastQueuedJob(0);
})();

