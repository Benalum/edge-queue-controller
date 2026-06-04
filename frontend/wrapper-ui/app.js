const API_BASE = "https://edge-public-proxy.alexhartel179.workers.dev/api";

const $ = (id) => document.getElementById(id);

let lastStatus = null;
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
      "Practice smarter with study cards, guided review, and an AI companion that can help you focus on what you need most. The goal is simple: make studying more active, more personalized, and easier to keep up with.",
    cards: [
      ["Study", "Create decks, review cards, and track what needs more practice.", "/study"],
      ["Companion", "Practice with an AI companion that can help check answers and explain concepts.", "/companion"],
      ["AI Tools", "Use AI-powered tools for generation, automation, and future learning workflows.", "/ai"],
      ["System", "View platform status, services, workers, and power state.", "/system"],
    ],
    boxes: [
      ["Why it helps", "Active practice and personalized feedback can help learners focus on weak areas instead of reviewing everything the same way."],
      ["Research note", "Studies on intelligent tutoring systems and AI-assisted personalized learning suggest adaptive support can improve learning outcomes when implemented well."],
      ["How this platform uses it", "Study cards, review history, answer feedback, and companion context can work together to guide what to study next."],
      ["Best use", "Use AI as a coach for practice and feedback, not as a replacement for thinking through the answer yourself."],
    ],
  },

  "/study": {
    eyebrow: "Study wrapper",
    title: "Study",
    subtitle:
      "Create decks, add cards, review cards, track accuracy, and prioritize new, hard, medium, and easy cards. This wrapper stays available even if the study backend is asleep.",
    boxes: [
      ["Purpose", "Decks, cards, review queues, card difficulty, and progress stats."],
      ["When online", "The live Study dashboard can create decks, add cards, grade reviews, and show stats."],
      ["When offline", "This summary page stays available and shows the system state."],
      ["Power behavior", "Login will eventually wake the host and start the Study/API container if needed."],
    ],
  },

  "/companion": {
    eyebrow: "Companion wrapper",
    title: "Companion",
    subtitle:
      "The companion page will be a clean chat interface that can pull study, calendar, profile, and other user context when authorized.",
    boxes: [
      ["Purpose", "Chat with the AI companion and use your platform data in conversation."],
      ["Study integration", "The companion can read card questions/answers and help determine whether answers are correct."],
      ["Future tools", "Calendar, files, reminders, profile, and other context can be connected later."],
      ["Power behavior", "Login or chat intent can wake the host and start the LLM worker."],
    ],
  },

  "/calendar": {
    eyebrow: "Calendar wrapper",
    title: "Calendar",
    subtitle:
      "Calendar will eventually let the companion and dashboard understand schedules, reminders, events, deadlines, and task planning.",
    boxes: [
      ["Purpose", "Show upcoming events, reminders, and study/work schedule."],
      ["Companion use", "The companion can use calendar context when answering questions."],
      ["Offline state", "This wrapper can explain calendar features even when backend services are asleep."],
      ["Power behavior", "Calendar services can remain lightweight and only wake backend when required."],
    ],
  },

  "/profile": {
    eyebrow: "Profile wrapper",
    title: "Profile",
    subtitle:
      "Profile will store user settings, preferences, account status, service permissions, and connected tools.",
    boxes: [
      ["Purpose", "Manage user account, preferences, service access, and profile context."],
      ["Security", "Do not expose private server credentials in the browser."],
      ["Future role", "Profile can control what context the companion is allowed to use."],
      ["Power behavior", "Profile access can stay wrapper-only unless private data is requested."],
    ],
  },

  "/ai": {
    eyebrow: "AI tools wrapper",
    title: "AI Tools",
    subtitle:
      "AI tools will include ComfyUI image generation, LLM jobs, queues, worker routing, and future automation tools.",
    boxes: [
      ["Purpose", "Submit AI jobs into a queue and route them to available workers."],
      ["ComfyUI", "Image and animation generation can run when CT 108 is online."],
      ["LLMs", "Companion and chat jobs can run through CT 101 / Ollama."],
      ["Power behavior", "Submitting a job can wake the host and start the needed worker container."],
    ],
  },

  "/system": {
    eyebrow: "System wrapper",
    title: "System",
    subtitle:
      "Monitor the controller node, Proxmox host, worker containers, services, and power state. Boot controls will stay protected behind login/session logic.",
    boxes: [
      ["Controller Node", "The laptop/main controller should stay online."],
      ["Compute Host", "pveso can be offline, booting, online, or error."],
      ["Worker Nodes", "CT 101 and CT 108 can be started only when needed."],
      ["Idle policy", "Containers and host can shut down after no visitors, users, or jobs remain."],
    ],
  },
};

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
  if (text) text.textContent = `System`;
}

function renderAuthButtons() {
  const loggedIn = Boolean(authState.token);

  $("authOpenBtn")?.classList.toggle("hidden", loggedIn);
  $("logoutBtn")?.classList.toggle("hidden", !loggedIn);
}

function navigate(path) {
  if (!pages[path]) path = "/";
  history.pushState({}, "", path);
  renderPage();
}

function nodeById(id) {
  return (lastStatus?.nodes || []).find((node) => node.id === id);
}

function serviceById(id) {
  return (lastStatus?.services || []).find((service) => service.id === id);
}

function stateText(value) {
  return value || "unknown";
}

function renderNotice() {
  const pveso = nodeById("pveso");
  const overall = lastStatus?.overall_state || "unknown";

  if (!lastStatus) {
    return `<div class="notice">Checking system status...</div>`;
  }

  if (pveso?.state === "offline") {
    return `<div class="notice">Main server is offline. The Cloudflare wrapper is still online. Login-based host wake and container start will be added next.</div>`;
  }

  if (pveso?.state === "booting") {
    return `<div class="notice">Main server is booting. Services may become available shortly.</div>`;
  }

  return `<div class="notice">System state: ${overall}.</div>`;
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

function renderSystemSnapshot() {
  const study = serviceById("study-api");
  const openwebui = serviceById("openwebui");
  const comfy = serviceById("comfyui");

  return `
    <div class="route-pill">
      <span class="dot ${lastStatus?.overall_state || "unknown"}"></span>
      <span>System: ${titleCase(lastStatus?.overall_state || "unknown")}</span>
    </div>

    <div class="summary-grid">
      <div class="summary-box"><span>Overall</span><strong>${stateText(lastStatus?.overall_state)}</strong></div>
      <div class="summary-box"><span>Study API</span><strong>${stateText(study?.state)}</strong></div>
      <div class="summary-box"><span>OpenWebUI</span><strong>${stateText(openwebui?.state)}</strong></div>
      <div class="summary-box"><span>ComfyUI</span><strong>${stateText(comfy?.state)}</strong></div>
    </div>
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

  $("app").innerHTML = `
    <section class="${isHome ? "hero-card" : "page-card"}">
      <p class="eyebrow">${page.eyebrow}</p>
      <h1>${page.title}</h1>
      <p class="subtitle">${page.subtitle}</p>

      ${page.cards ? renderCards(page.cards) : ""}
      ${page.boxes ? renderBoxes(page.boxes) : ""}
      ${isSystem ? renderSystemSnapshot() : ""}
      ${isSystem ? renderNotice() : ""}

      ${isSystem ? `
        <div class="actions">
          <button class="primary-btn" type="button" id="openSystemBtn">Open System Panel</button>
          <button class="primary-btn" type="button" id="wakeLoginBtn">${authState.token ? "Wake Services Soon" : "Login to Wake Services"}</button>
        </div>
      ` : ""}
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
}

function renderStatusItems(targetId, items) {
  const target = $(targetId);
  if (!target) return;

  target.innerHTML = "";

  for (const item of items || []) {
    const state = item.state || "unknown";

    const row = document.createElement("div");
    row.className = "status-item";
    row.innerHTML = `
      <div class="status-row">
        <div class="status-name"></div>
        <div class="badge ${state}"></div>
      </div>
      <div class="status-detail"></div>
    `;

    row.querySelector(".status-name").textContent = item.name || item.id || "Unknown";
    row.querySelector(".badge").textContent = state;
    row.querySelector(".status-detail").textContent = item.detail || item.role || "";

    target.appendChild(row);
  }
}

function renderSystemDrawer() {
  $("drawerSummary").textContent =
    `Overall state: ${titleCase(lastStatus?.overall_state || "unknown")}. Last checked: ${lastStatus?.checked_at || "unknown"}.`;

  renderStatusItems("drawerNodes", lastStatus?.nodes || []);
  renderStatusItems("drawerServices", lastStatus?.services || []);
}

function openSystemDrawer() {
  $("systemDrawer").classList.remove("hidden");
  renderSystemDrawer();
}

function closeSystemDrawer() {
  $("systemDrawer").classList.add("hidden");
}

async function loadSystemStatus() {
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
      nodes: [],
      services: [],
      error: err.message,
    };
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
      : "Sign in to wake services and access your dashboard.";

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

    closeAuthModal();
    renderPage();

    alert(authMode === "register" ? "Account created and logged in." : "Logged in.");
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
