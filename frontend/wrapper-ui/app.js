const API_BASE =
  localStorage.getItem("AH_API_BASE") ||
  (["127.0.0.1", "localhost"].includes(location.hostname)
    ? "/api"
    : "https://edge-public-proxy.alexhartel179.workers.dev/api");

const $ = (id) => document.getElementById(id);

let lastStatus = null;
let adminStatus = null;
let accountCredits = null;
let gpuCatalog = null;
let gpuQuote = null;
let gpuReserveResult = null;
let gpuSessions = null;
let adRewardStatus = null;
let authMode = "login";

const authState = {
  token: localStorage.getItem("edgeStudyToken") || "",
  user: null,
};

const pages = {
  "/": {
    eyebrow: "Welcome",
    title: "Welcome to your AI-powered learning space",
    subtitle:
      "Practice smarter with study tools, guided review, and an AI companion designed to help you focus on what matters most.",
    cards: [
      ["Study", "Create decks, review cards, track progress, and focus on cards that need more practice.", "/study"],
      ["Companion", "Practice with an AI helper that can explain concepts, ask follow-up questions, and support studying.", "/companion"],
      ["Calendar", "Plan study sessions, reminders, deadlines, and future schedule-aware companion help.", "/calendar"],
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
    eyebrow: "Feature summary",
    title: "Calendar",
    subtitle:
      "Calendar will help users organize study time, reminders, deadlines, events, and future companion planning.",
    boxes: [
      ["Schedule overview", "Show upcoming events, study sessions, deadlines, and reminders."],
      ["Study planning", "Help users plan when to review decks and prepare for upcoming work."],
      ["Companion context", "The companion can eventually use schedule context to give better recommendations."],
      ["Future automation", "Calendar actions can trigger reminders, study prompts, and planning workflows."],
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
  const credits =
    user.paid_credit_balance ??
    user.credit_balance ??
    0;

  pill.classList.toggle("hidden", !loggedIn);

  if (!loggedIn) {
    pill.textContent = "Credits: —";
    return;
  }

  pill.innerHTML = `Credits: ${formatNumber(credits)}${user.plan ? ` <small>${user.plan}</small>` : ""}`;
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
      state: normalizeApiState(study, "unknown"),
      detail: normalizeApiDetail(study, "Decks, cards, reviews, stats, and study progress."),
    },
    {
      id: "companion-api",
      name: "Companion API",
      state: "planned",
      detail: "Future companion chat, grading, and context API.",
    },
    {
      id: "profile-api",
      name: "Profile API",
      state: "planned",
      detail: "Future profile, preferences, permissions, and user settings API.",
    },
    {
      id: "calendar-api",
      name: "Calendar API",
      state: "planned",
      detail: "Future calendar, reminders, deadlines, and scheduling API.",
    },
    {
      id: "images-api",
      name: "Images API",
      state: "planned",
      detail: "Future ComfyUI-backed image generation for user-specific companion images.",
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

async function loadGpuCatalog() {
  gpuCatalog = null;

  if (!authState.token) {
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
    renderPage();
  } catch (err) {
    alert(err.message);
  }
}

function renderCreditsPage() {
  const loggedIn = Boolean(authState.token);
  const live = accountCredits || {};
  const user = live.user || authState.user || {};
  const credits = live.credits || {};

  const freeAvailable = credits.free_available ?? 0;
  const paidAvailable = credits.paid_available ?? 0;
  const totalAvailable = credits.total_available ?? credits.available ?? user.credit_balance ?? 0;

  const freeReserved = credits.free_reserved ?? 0;
  const paidReserved = credits.paid_reserved ?? 0;
  const totalReserved = credits.total_reserved ?? credits.reserved ?? 0;

  const monthlyFree = credits.monthly_free_allowance ?? credits.monthly_allowance ?? user.monthly_credit_allowance ?? 0;
  const monthlyPaid = credits.monthly_paid_allowance ?? 0;
  const storage = credits.storage_quota_mb ?? user.storage_quota_mb ?? 0;
  const plan = credits.plan || user.plan || (loggedIn ? "free" : "not logged in");
  const billing = credits.billing_status || user.billing_status || "none";

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
            <strong>${adRewardStatus?.can_claim ? "Available" : "Locked"}</strong>
            <p>${safeText(adRewardStatus?.blocked_reason || "Rewarded ad claim is available.")}</p>
          </div>
        </div>

        ${isLocalDevHost() ? `
          <div class="actions">
            <button
              id="claimAdRewardBtn"
              class="primary-btn"
              type="button"
              ${adRewardStatus && !adRewardStatus.can_claim ? "disabled" : ""}
            >
              Watch mock ad
            </button>
          </div>

          <div class="notice">
            Local development mode: this simulates a rewarded ad and grants free/local credits only.
          </div>
        ` : `
          <div class="actions">
            <button class="primary-btn" type="button" disabled>
              Earn free credits coming soon
            </button>
          </div>

          <div class="notice">
            Rewarded ads will be enabled after real provider verification is connected. Ad-earned credits will be free/local credits only.
          </div>
        `}
      </section>

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

  return `
    <section class="system-section">
      <h2>APIs</h2>
      <p class="section-copy">
        Public users can see whether platform API areas are online, degraded, offline, or planned.
      </p>
      ${renderApiCards(apiGroups())}
    </section>

    ${isAdmin ? `
      <section class="system-section">
        <h2>Infrastructure</h2>
        <p class="section-copy">
          Admin-only view of controller, server, CPU, GPU, and storage node capacity.
        </p>
        ${renderInfraCards(infrastructureGroups())}
      </section>
    ` : `
      <div class="notice">
        Infrastructure details are visible to admins only.
      </div>
    `}

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

  const isHome = path === "/";
  const isSystem = path === "/system";
  const isCredits = path === "/credits";

  $("app").innerHTML = `
    <section class="${isHome ? "hero-card" : "page-card"}">
      <p class="eyebrow">${page.eyebrow}</p>
      <h1>${page.title}</h1>
      <p class="subtitle">${page.subtitle}</p>

      ${page.cards ? renderCards(page.cards) : ""}
      ${page.boxes?.length ? renderBoxes(page.boxes) : ""}
      ${isCredits ? renderCreditsPage() : ""}
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
  $("gpuQuoteBtn")?.addEventListener("click", quoteMockGpuSession);
  $("gpuReserveQuoteBtn")?.addEventListener("click", reserveMockGpuQuote);

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

  $("drawerSummary").textContent =
    `API state: ${titleCase(lastStatus?.overall_state || "unknown")}. Last checked: ${lastStatus?.checked_at || "unknown"}.`;

  if (isAdmin) {
    renderDrawerItems("drawerNodes", infrastructureGroups(), "infra");
  } else {
    renderDrawerItems("drawerNodes", [
      {
        name: "Admin-only",
        state: "planned",
        detail: "Infrastructure details are hidden for non-admin users.",
      },
    ], "api");
  }

  renderDrawerItems("drawerServices", apiGroups(), "api");
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

async function loadAccountCredits() {
  accountCredits = null;
  gpuSessions = null;

  if (!authState.token) {
    return;
  }

  await loadAdRewardStatus();
  await loadGpuCatalog();

  try {
    accountCredits = await api("/account/credit-pools", {
      method: "GET",
    });

    if (accountCredits?.user) {
      authState.user = accountCredits.user;
    }

    await loadGpuSessions();
  } catch {
    accountCredits = null;
  }
}

async function loadSystemStatus() {
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

  await loadAccountCredits();

  adminStatus = null;

  if (authState.token) {
    try {
      adminStatus = await api("/system/admin-status", {
        method: "GET",
      });
    } catch {
      adminStatus = null;
    }
  }

  renderPage();
  renderSystemDrawer();
}

function setAuthMode(mode) {
  authMode = mode === "register" ? "register" : "login";

  $("authTitle").textContent = authMode === "register" ? "Register" : "Login";
  $("authSubtitle").textContent =
    authMode === "register"
      ? "Create an account to use platform services."
      : "Sign in to access your dashboard and future live services.";

  $("authSubmitBtn").textContent = authMode === "register" ? "Register" : "Login";
  $("loginTabBtn").classList.toggle("active", authMode === "login");
  $("registerTabBtn").classList.toggle("active", authMode === "register");
}

function openAuthModal(mode = "login") {
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
  $("authSubmitBtn").textContent = authMode === "register" ? "Registering..." : "Logging in...";

  try {
    const data = await api(authMode === "register" ? "/auth/register" : "/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });

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
$("authForm").addEventListener("submit", handleAuthSubmit);

renderPage();
checkExistingLogin();
loadSystemStatus();
setInterval(loadSystemStatus, 30000);
