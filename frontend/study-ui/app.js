// APC_PHASE_14J_CD_STATIC_UI_CONTRACT: static metadata/accessibility contract marker only; no runtime behavior change.
// APC_PHASE_14J_CB_STATIC_UI_PATCH: static accessibility/copy marker only; no runtime behavior change.
// APC_PHASE_14J_BZ_STATIC_UI_PATCH: static UI copy/layout marker only; no runtime behavior change.
const API_BASE = "/api";

const state = {
  token: "cookie-session",
  user: null,
  decks: [],
  selectedDeckId: "",
  queue: [],
  currentCardIndex: 0,
  showingAnswer: false
};

const $ = (id) => document.getElementById(id);

function on(id, eventName, handler, options) {
  const el = $(id);
  if (!el) {
    console.warn(`[study-ui] Missing element #${id}; skipped ${eventName} listener.`);
    return null;
  }
  el.addEventListener(eventName, handler, options);
  return el;
}

function safeNavigate(url, reason = "study-ui navigation") {
  const target = String(url || "");

  if (
    target.includes("/login") ||
    target.includes("login?next") ||
    target.includes("/api/public/auth-status")
  ) {
    console.warn(`[study-ui] Blocked legacy login redirect from ${reason}: ${target}`);
    return false;
  }

  window.location.assign(target);
  return true;
}




function setMessage(id, text, type = "") {
  const el = $(id);
  el.textContent = text || "";
  el.className = `message ${type}`.trim();
}

function authHeaders(json = false) {
  const headers = {};
  if (json) headers["Content-Type"] = "application/json";
  return headers;
}

async function api(path, options = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      ...(options.headers || {})
    }
  });

  const text = await response.text();
  let data = null;

  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = { ok: false, detail: text || "Non-JSON response" };
  }

  if (!response.ok) {
    const detail = data?.detail || `HTTP ${response.status}`;
    throw new Error(detail);
  }

  return data;
}

async function checkApiStatus() {
  try {
    const data = await api("/status");
    $("apiDot").className = "status-dot ok";
    $("apiStatusText").textContent = "API online";
    $("workerStatusText").textContent = `Jobs forwarded: ${data.queue?.forwarded ?? 0}`;
  } catch (err) {
    $("apiDot").className = "status-dot bad";
    $("apiStatusText").textContent = "API issue";
    $("workerStatusText").textContent = err.message;
  }
}

function showAuthedUI() {
  $("authPanel").classList.add("hidden");
  $("dashboardPanel").classList.remove("hidden");
  $("studyGrid").classList.remove("hidden");
  $("reviewPanel").classList.remove("hidden");
  $("cardsPanel").classList.remove("hidden");

}

function showLoggedOutUI() {
  $("authPanel").classList.remove("hidden");
  $("dashboardPanel").classList.add("hidden");
  $("studyGrid").classList.add("hidden");
  $("reviewPanel").classList.add("hidden");
  $("cardsPanel").classList.add("hidden");
}

async function loadMe() {
  try {
    const data = await api("/me", {
      headers: authHeaders()
    });
    state.user = data.user;
    state.token = "cookie-session";
    showAuthedUI();
    await refreshAll();
  } catch {
    state.token = "cookie-session";
    state.user = null;
    localStorage.removeItem("edgeStudyToken");
    showLoggedOutUI();
  }
}

async function handleAuthSubmit(event) {
  event.preventDefault();

  const mode = document.querySelector(".tab.active").dataset.authTab;
  const email = $("emailInput").value.trim();
  const password = $("passwordInput").value;
  const displayName = $("displayNameInput").value.trim();

  const path = mode === "register" ? "/auth/register" : "/auth/login";
  const payload = { email, password };

  if (mode === "register") payload.display_name = displayName || "Student";

  try {
    setMessage("authMessage", "Working...");
    const data = await api(path, {
      method: "POST",
      headers: authHeaders(true),
      body: JSON.stringify(payload)
    });

    state.token = data.session.access_token;
    state.user = data.user;
    localStorage.setItem("edgeStudyToken", state.token);

    setMessage("authMessage", "Success.", "success");
    showAuthedUI();
    await refreshAll();
  } catch (err) {
    setMessage("authMessage", err.message, "error");
  }
}

async function logout() {
  try {
    if (state.token) {
      await api("/auth/logout", {
        method: "POST",
        headers: authHeaders()
      });
    }
  } catch {
    // logout locally either way
  }

  state.token = "";
  state.user = null;
  state.decks = [];
  state.selectedDeckId = "";
  state.queue = [];
  localStorage.removeItem("edgeStudyToken");
  showLoggedOutUI();
}

async function refreshAll() {
  await Promise.all([
    loadProgress(),
    loadDecks()
  ]);

  if (state.selectedDeckId) {
    await loadCardsAndStats();
  }
}

async function loadProgress() {
  const data = await api("/study/progress", {
    headers: authHeaders()
  });

  const overall = data.overall || {};
  $("deckCount").textContent = overall.deck_count ?? 0;
  $("cardCount").textContent = overall.card_count ?? 0;
  $("reviewCount").textContent = overall.review_count ?? 0;
  $("accuracyValue").textContent =
    overall.accuracy === null || overall.accuracy === undefined
      ? "—"
      : `${Math.round(overall.accuracy * 100)}%`;
}

async function loadDecks() {
  const data = await api("/study/decks", {
    headers: authHeaders()
  });

  state.decks = data.decks || [];

  const select = $("deckSelect");
  const previous = state.selectedDeckId;

  select.innerHTML = `<option value="">No deck selected</option>`;

  for (const deck of state.decks) {
    const option = document.createElement("option");
    option.value = String(deck.id);
    option.textContent = `${deck.title} (${deck.card_count || 0} cards)`;
    select.appendChild(option);
  }

  if (previous && state.decks.some((deck) => String(deck.id) === String(previous))) {
    select.value = previous;
  } else if (state.decks.length) {
    select.value = String(state.decks[0].id);
    state.selectedDeckId = select.value;
  } else {
    state.selectedDeckId = "";
  }

  renderDeckSummary();
}

function renderDeckSummary() {
  const deck = state.decks.find((item) => String(item.id) === String(state.selectedDeckId));
  const el = $("deckSummary");

  if (!deck) {
    el.innerHTML = `<p class="muted">Create or select a deck to begin.</p>`;
    return;
  }

  const accuracy = deck.accuracy === null || deck.accuracy === undefined
    ? "—"
    : `${Math.round(deck.accuracy * 100)}%`;

  el.innerHTML = `
    <h3>${escapeHtml(deck.title)}</h3>
    <p class="muted">${escapeHtml(deck.description || "No description")}</p>
    <div class="card-meta">
      <span class="pill">${deck.card_count || 0} cards</span>
      <span class="pill">${deck.total_reviews || 0} reviews</span>
      <span class="pill">${accuracy} accuracy</span>
    </div>
  `;
}

async function createDeck(event) {
  event.preventDefault();

  const title = $("deckTitleInput").value.trim();
  const description = $("deckDescriptionInput").value.trim();

  if (!title) return;

  const data = await api("/study/decks", {
    method: "POST",
    headers: authHeaders(true),
    body: JSON.stringify({ title, description })
  });

  $("deckTitleInput").value = "";
  $("deckDescriptionInput").value = "";

  state.selectedDeckId = String(data.deck.id);
  await refreshAll();
}

async function createCard(event) {
  event.preventDefault();

  if (!state.selectedDeckId) {
    alert("Select or create a deck first.");
    return;
  }

  const payload = {
    question: $("questionInput").value.trim(),
    answer: $("answerInput").value.trim(),
    explanation: $("explanationInput").value.trim(),
    difficulty: $("difficultyInput").value,
    tags: $("tagsInput").value
  };

  if (!payload.question || !payload.answer) return;

  await api(`/study/decks/${state.selectedDeckId}/cards`, {
    method: "POST",
    headers: authHeaders(true),
    body: JSON.stringify(payload)
  });

  $("questionInput").value = "";
  $("answerInput").value = "";
  $("explanationInput").value = "";
  $("difficultyInput").value = "";
  $("tagsInput").value = "";

  await refreshAll();
}

async function loadCardsAndStats() {
  if (!state.selectedDeckId) return;

  const data = await api(`/study/decks/${state.selectedDeckId}/card-stats`, {
    headers: authHeaders()
  });

  const buckets = data.bucket_counts || {};
  $("bucketNew").textContent = buckets.new || 0;
  $("bucketHard").textContent = buckets.hard || 0;
  $("bucketMedium").textContent = buckets.medium || 0;
  $("bucketEasy").textContent = buckets.easy || 0;

  renderCards(data.cards || []);
}

function renderCards(cards) {
  const el = $("cardsList");

  if (!cards.length) {
    el.innerHTML = `<p class="muted">No cards yet. Add your first card.</p>`;
    return;
  }

  el.innerHTML = cards.map((card) => {
    const accuracy = card.accuracy === null || card.accuracy === undefined
      ? "—"
      : `${Math.round(card.accuracy * 100)}%`;

    const bucket = card.performance_bucket || "new";

    return `
      <div class="card-row">
        <strong>${escapeHtml(card.question)}</strong>
        <div class="card-meta">
          <span class="pill ${bucket}">${bucket}</span>
          <span class="pill">${card.total_reviews || 0} reviews</span>
          <span class="pill">${accuracy} accuracy</span>
          <span class="pill">Wrong streak: ${card.recent_wrong_streak || 0}</span>
          <span class="pill">Confidence: ${card.avg_confidence ?? "—"}</span>
        </div>
      </div>
    `;
  }).join("");
}

async function loadReviewQueue() {
  if (!state.selectedDeckId) {
    alert("Select or create a deck first.");
    return;
  }

  const mode = $("reviewMode").value;
  const data = await api(`/study/decks/${state.selectedDeckId}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
    headers: authHeaders()
  });

  state.queue = data.cards || [];
  state.currentCardIndex = 0;
  state.showingAnswer = false;

  const buckets = data.bucket_counts || {};
  $("bucketNew").textContent = buckets.new || 0;
  $("bucketHard").textContent = buckets.hard || 0;
  $("bucketMedium").textContent = buckets.medium || 0;
  $("bucketEasy").textContent = buckets.easy || 0;

  renderReviewCard();
}

function renderReviewCard() {
  const el = $("reviewCard");

  if (!state.queue.length) {
    el.className = "review-card empty";
    el.innerHTML = "No cards available in this deck yet.";
    return;
  }

  const card = state.queue[state.currentCardIndex];

  if (!card) {
    el.className = "review-card empty";
    el.innerHTML = "Review queue complete. Load another queue or change mode.";
    return;
  }

  el.className = "review-card";

  const bucket = card.performance_bucket || "new";
  const indexText = `${state.currentCardIndex + 1} / ${state.queue.length}`;

  el.innerHTML = `
    <div class="card-meta">
      <span class="pill">${indexText}</span>
      <span class="pill ${bucket}">${bucket}</span>
      <span class="pill">${card.total_reviews || 0} reviews</span>
      <span class="pill">Accuracy: ${card.accuracy === null || card.accuracy === undefined ? "—" : `${Math.round(card.accuracy * 100)}%`}</span>
    </div>

    <div class="review-question">${escapeHtml(card.question)}</div>

    ${state.showingAnswer ? `
      <div class="review-answer">
        <strong>Answer:</strong><br />
        ${escapeHtml(card.answer)}
        ${card.explanation ? `<br /><br /><strong>Explanation:</strong><br />${escapeHtml(card.explanation)}` : ""}
      </div>
    ` : ""}

    <div class="review-actions">
      ${!state.showingAnswer ? `
        <button class="primary" id="showAnswerBtn">Show Answer</button>
      ` : `
        <button class="secondary" data-review="wrong">Wrong</button>
        <button class="primary" data-review="correct">Correct</button>
      `}
      <button class="secondary" id="skipCardBtn">Skip</button>
    </div>
  `;

  const showAnswerBtn = $("showAnswerBtn");
  if (showAnswerBtn) {
    showAnswerBtn.addEventListener("click", () => {
      state.showingAnswer = true;
      renderReviewCard();
    });
  }

  const skipCardBtn = $("skipCardBtn");
  if (skipCardBtn) {
    skipCardBtn.addEventListener("click", () => {
      state.currentCardIndex += 1;
      state.showingAnswer = false;
      renderReviewCard();
    });
  }

  document.querySelectorAll("[data-review]").forEach((button) => {
    button.addEventListener("click", async () => {
      const correct = button.dataset.review === "correct";
      await submitReview(card.id, correct);
    });
  });
}

async function submitReview(cardId, wasCorrect) {
  await api(`/study/cards/${cardId}/reviews`, {
    method: "POST",
    headers: authHeaders(true),
    body: JSON.stringify({
      was_correct: wasCorrect,
      confidence: wasCorrect ? 4 : 2
    })
  });

  state.currentCardIndex += 1;
  state.showingAnswer = false;

  await loadProgress();
  await loadCardsAndStats();
  renderReviewCard();
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

document.querySelectorAll("[data-auth-tab]").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll("[data-auth-tab]").forEach((b) => b.classList.remove("active"));
    button.classList.add("active");

    const mode = button.dataset.authTab;
    $("displayNameWrap").classList.toggle("hidden", mode !== "register");
    $("authSubmit").textContent = mode === "register" ? "Register" : "Login";
    $("passwordInput").autocomplete = mode === "register" ? "new-password" : "current-password";
    setMessage("authMessage", "");
  });
});

on("authForm", "submit", handleAuthSubmit);
const logoutBtn = $("logoutBtn");
if (logoutBtn) {
  logoutBtn.addEventListener("click", logout);
}
on("deckForm", "submit", createDeck);
on("cardForm", "submit", createCard);
on("deckSelect", "change", async (event) => {
  state.selectedDeckId = event.target.value;
  renderDeckSummary();
  await loadCardsAndStats();
});
on("loadQueueBtn", "click", loadReviewQueue);

checkApiStatus();
loadMe();

/* =========================
   App navigation
   ========================= */

function showPage(page) {
  document.querySelectorAll("[data-page-link]").forEach((button) => {
    button.classList.toggle("active", button.dataset.pageLink === page);
  });

  document.querySelectorAll("[data-page]").forEach((el) => {
    el.classList.toggle("hidden", el.dataset.page !== page);
  });

  if (false && page === "study" && !state.token) {
    showPage("auth");
    return;
  }

  if (page === "auth") {
    $("authPanel").classList.remove("hidden");
  }
}

function syncNavAuth() {
  const loggedIn = Boolean(state.user || state.token);

  const sharedAuthLink = $("sharedAuthLink");
  if (sharedAuthLink) {
    sharedAuthLink.textContent = loggedIn ? "Account" : "Login / Register";
    sharedAuthLink.href = loggedIn ? "/" : "/";
  }

  const navAuthBtn = $("navAuthBtn");
  if (navAuthBtn) {
    navAuthBtn.classList.toggle("hidden", loggedIn);
  }

  const navLogoutBtn = $("navLogoutBtn");
  if (navLogoutBtn) {
    navLogoutBtn.classList.toggle("hidden", !loggedIn);
  }

  const logoutBtn = $("logoutBtn");
  if (logoutBtn) {
    logoutBtn.classList.toggle("hidden", !loggedIn);
  }
}


document.querySelectorAll("[data-page-link]").forEach((button) => {
  button.addEventListener("click", (event) => {
    event.preventDefault();
    showPage(button.dataset.pageLink);
  });
});

on("navAuthBtn", "click", () => { safeNavigate("/", "window.location.href assignment"); });
on("navLogoutBtn", "click", logout);

const originalShowAuthedUI = showAuthedUI;
showAuthedUI = function patchedShowAuthedUI() {
  originalShowAuthedUI();
  syncNavAuth();
  showPage("study");
};

const originalShowLoggedOutUI = showLoggedOutUI;
showLoggedOutUI = function patchedShowLoggedOutUI() {
  originalShowLoggedOutUI();
  syncNavAuth();
  showPage("home");
};

/* =========================
   Companion study mode
   ========================= */

state.companionQueue = [];
state.companionIndex = 0;
state.companionCurrentCard = null;
state.companionPendingUnsure = null;

function companionAddMessage(role, text) {
  const chat = $("companionChat");
  if (!chat) return;

  const bubble = document.createElement("div");
  bubble.className = `chat-bubble ${role}`;
  bubble.textContent = text;
  chat.appendChild(bubble);
  chat.scrollTop = chat.scrollHeight;
}

function companionClearChat() {
  const chat = $("companionChat");
  if (!chat) return;
  chat.innerHTML = "";
}

function syncCompanionDeckSelect() {
  const select = $("companionDeckSelect");
  if (!select) return;

  const previous = select.value;
  select.innerHTML = `<option value="">No deck selected</option>`;

  for (const deck of state.decks || []) {
    const option = document.createElement("option");
    option.value = String(deck.id);
    option.textContent = `${deck.title} (${deck.card_count || 0} cards)`;
    select.appendChild(option);
  }

  if (previous && state.decks.some((deck) => String(deck.id) === String(previous))) {
    select.value = previous;
  } else if (state.selectedDeckId) {
    select.value = state.selectedDeckId;
  }
}

const originalLoadDecksForCompanion = loadDecks;
loadDecks = async function patchedLoadDecksForCompanion() {
  await originalLoadDecksForCompanion();
  syncCompanionDeckSelect();
};

async function companionStartQueue() {
  if (!state.token) {
    showPage("auth");
    return;
  }

  const deckId = $("companionDeckSelect").value;
  const mode = $("companionReviewMode").value;

  if (!deckId) {
    companionClearChat();
    companionAddMessage("assistant", "Please select a deck first.");
    return;
  }

  try {
    companionClearChat();
    companionAddMessage("assistant", "Loading your review queue...");

    const data = await api(`/study/decks/${deckId}/review-queue?mode=${encodeURIComponent(mode)}&limit=10`, {
      headers: authHeaders()
    });

    state.companionQueue = data.cards || [];
    state.companionIndex = 0;
    state.companionPendingUnsure = null;

    companionClearChat();

    if (!state.companionQueue.length) {
      companionAddMessage("assistant", "This deck does not have cards yet. Add cards on the Study page first.");
      return;
    }

    companionAddMessage(
      "system",
      `Mode: ${data.mode}. ${data.selection_explanation}`
    );

    companionAskCurrentCard();
  } catch (err) {
    companionClearChat();
    companionAddMessage("assistant", `I could not load the queue: ${err.message}`);
  }
}

function companionAskCurrentCard() {
  const card = state.companionQueue[state.companionIndex];
  state.companionCurrentCard = card || null;
  state.companionPendingUnsure = null;

  $("companionConfirmActions")?.classList.add("hidden");

  if (!card) {
    companionAddMessage("assistant", "Review complete. Load another queue when you are ready.");
    return;
  }

  const bucket = card.performance_bucket || "new";
  const count = `${state.companionIndex + 1}/${state.companionQueue.length}`;

  companionAddMessage(
    "assistant",
    `Card ${count} · ${bucket.toUpperCase()}\n\n${card.question}`
  );

  $("companionAnswerInput").value = "";
  $("companionAnswerInput").focus();
}

async function companionSubmitAnswer(event) {
  event.preventDefault();

  const card = state.companionCurrentCard;
  if (!card) {
    companionAddMessage("assistant", "Load a review queue first.");
    return;
  }

  const answer = $("companionAnswerInput").value.trim();
  if (!answer) return;

  companionAddMessage("user", answer);
  $("companionAnswerInput").value = "";

  try {
    const data = await api("/companion/study/grade", {
      method: "POST",
      headers: authHeaders(true),
      body: JSON.stringify({
        card_id: card.id,
        user_answer: answer
      })
    });

    if (data.verdict === "correct") {
      companionAddMessage("assistant", `Correct. ${data.feedback}`);
      await companionAfterRecordedReview();
      return;
    }

    if (data.verdict === "incorrect") {
      companionAddMessage(
        "assistant",
        `Not quite. ${data.feedback}\n\nStored answer: ${data.card.answer}`
      );
      await companionAfterRecordedReview();
      return;
    }

    state.companionPendingUnsure = {
      card,
      userAnswer: answer,
      feedback: data.feedback
    };

    companionAddMessage(
      "assistant",
      `${data.feedback}\n\nStored answer: ${data.card.answer}\n\nShould I mark your answer correct or wrong?`
    );

    $("companionConfirmActions")?.classList.remove("hidden");
  } catch (err) {
    companionAddMessage("assistant", `I could not grade that answer: ${err.message}`);
  }
}

async function companionRecordManualReview(wasCorrect) {
  const pending = state.companionPendingUnsure;
  const card = pending?.card || state.companionCurrentCard;

  if (!card) return;

  await api(`/study/cards/${card.id}/reviews`, {
    method: "POST",
    headers: authHeaders(true),
    body: JSON.stringify({
      was_correct: Boolean(wasCorrect),
      confidence: wasCorrect ? 4 : 2,
      notes: "Companion user-confirmed review."
    })
  });

  companionAddMessage("assistant", wasCorrect ? "Marked correct." : "Marked wrong.");
  $("companionConfirmActions")?.classList.add("hidden");

  await companionAfterRecordedReview();
}

async function companionAfterRecordedReview() {
  await loadProgress();

  if (state.selectedDeckId) {
    await loadCardsAndStats();
  }

  state.companionIndex += 1;
  state.companionPendingUnsure = null;

  setTimeout(() => companionAskCurrentCard(), 350);
}

const companionLoadQueueBtn = $("companionLoadQueueBtn");
if (companionLoadQueueBtn) {
  companionLoadQueueBtn.addEventListener("click", companionStartQueue);
}

const companionAnswerForm = $("companionAnswerForm");
if (companionAnswerForm) {
  companionAnswerForm.addEventListener("submit", companionSubmitAnswer);
}

const companionConfirmCorrectBtn = $("companionConfirmCorrectBtn");
if (companionConfirmCorrectBtn) {
  companionConfirmCorrectBtn.addEventListener("click", () => companionRecordManualReview(true));
}

const companionConfirmWrongBtn = $("companionConfirmWrongBtn");
if (companionConfirmWrongBtn) {
  companionConfirmWrongBtn.addEventListener("click", () => companionRecordManualReview(false));
}


/* === Companion + local calendar patch === */
(function () {
  const CHAT_KEY = "aiStudyCompanionChat:v1";
  const CALENDAR_KEY = "aiStudyCalendarReminders:v1";

  function getApiBase() {
    try {
      if (typeof API_BASE !== "undefined" && API_BASE) return API_BASE;
    } catch (_) {}
    return "/api";
  }

  function studyUiLegacyJobsFallbackEnabled() {
    // PHASE_14I_X_STUDY_UI_LEGACY_JOBS_FALLBACK_FLAG: default-enabled legacy jobs fallback.
    try {
      if (typeof window !== "undefined" && Object.prototype.hasOwnProperty.call(window, "STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED")) {
        const value = window.STUDY_UI_LEGACY_JOBS_FALLBACK_ENABLED;
        if (value === false || value === 0) return false;
        if (typeof value === "string" && /^(false|0|off|no)$/i.test(value.trim())) return false;
      }
    } catch (_) {}
    return true;
  }

  function getAuthToken() {
    const keys = ["authToken", "token", "accessToken", "aiStudyToken"];
    for (const key of keys) {
      const value = localStorage.getItem(key);
      if (value) return value;
    }
    return "";
  }

  function jsonHeaders() {
    const headers = { "Content-Type": "application/json" };
    const token = getAuthToken();
        return headers;
  }

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function loadJson(key, fallback) {
    try {
      return JSON.parse(localStorage.getItem(key) || JSON.stringify(fallback));
    } catch (_) {
      return fallback;
    }
  }

  function saveJson(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
  }

  function extractText(data) {
    if (!data) return "";

    if (typeof data === "string") return data;

    const candidates = [
      data.reply,
      data.answer,
      data.response,
      data.output,
      data.content,
      data.message?.content,
      data.result?.reply,
      data.result?.answer,
      data.result?.response,
      data.result?.output,
      data.result?.content,
      data.result?.message?.content,
      data.job?.result?.reply,
      data.job?.result?.answer,
      data.job?.result?.response,
      data.job?.result?.output,
      data.job?.result?.content,
      data.job?.result?.message?.content,
    ];

    for (const item of candidates) {
      if (typeof item === "string" && item.trim()) return item.trim();
    }

    if (data.status && data.id) {
      return `Job ${data.id} is ${data.status}.`;
    }

    if (data.job?.status && data.job?.id) {
      return `Job ${data.job.id} is ${data.job.status}.`;
    }

    return "";
  }

  // COMPANION_TRANSIENT_GATEWAY_V1
  // Cloudflare/proxy errors must never be saved as assistant chat text.
  // Treat 502/503/504 and HTML error pages as transient gateway failures.
  function getJobId(data) {
    return data?.job_id || data?.id || data?.job?.id || data?.result?.job_id || data?.result?.id || null;
  }

  function getPollUrl(data) {
    return data?.poll_url || data?.job?.poll_url || data?.result?.poll_url || "";
  }

  function getJobStatus(data) {
    return data?.status || data?.job?.status || data?.result?.status || "";
  }

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function isCloudflareHtml(text) {
    const value = String(text || "").trim().toLowerCase();
    return (
      value.startsWith("<!doctype html") ||
      value.startsWith("<html") ||
      value.includes("cloudflare") && value.includes("bad gateway") ||
      value.includes("error code 502") ||
      value.includes("error code 503") ||
      value.includes("error code 504")
    );
  }

  function isTransientStatus(status) {
    return [408, 425, 429, 500, 502, 503, 504].includes(Number(status));
  }

  function transientGatewayError(message, status = 0) {
    const err = new Error(message || "Temporary gateway issue while the companion is responding.");
    err.transient = true;
    err.status = status;
    return err;
  }

  async function fetchJson(url, options) {
    let res;

    try {
      res = await fetch(url, options);
    } catch (err) {
      throw transientGatewayError("Network/proxy connection interrupted while the companion was responding.");
    }

    const text = await res.text();

    let data = null;
    try {
      data = text ? JSON.parse(text) : {};
    } catch (_) {
      data = { raw: text };
    }

    if (!res.ok) {
      if (isTransientStatus(res.status) || isCloudflareHtml(text)) {
        throw transientGatewayError(
          `Temporary gateway error ${res.status || ""}. The companion may still be working.`,
          res.status
        );
      }

      const message = data?.detail || data?.error || data?.message || `${res.status} ${res.statusText}`;
      throw new Error(message);
    }

    if (isCloudflareHtml(text)) {
      throw transientGatewayError("Temporary Cloudflare gateway page returned instead of JSON.");
    }

    return data;
  }

  async function pollJob(jobId, pollUrl = "") {
    const base = getApiBase();

    function normalizePollUrl(path) {
      if (!path) return "";
      if (/^https?:\/\//i.test(path)) return path;
      if (path.startsWith("/public/")) return `${base}${path.replace(/^\/public/, "")}`;
      if (path.startsWith("/api/")) return `${base}${path.replace(/^\/api/, "")}`;
      return `${base}${path.startsWith("/") ? path : `/${path}`}`;
    }

    const paths = [
      normalizePollUrl(pollUrl),
      `${base}/chat/queued/${encodeURIComponent(jobId)}`,
    ].filter(Boolean);

    if (studyUiLegacyJobsFallbackEnabled()) {
      paths.push(`${base}/jobs/${jobId}`);
      paths.push(`${base}/job/${jobId}`);
    }

    for (let attempt = 0; attempt < 48; attempt++) {
      for (const url of paths) {
        try {
          const data = await fetchJson(url, { headers: jsonHeaders() });
          const text = extractText(data);
          const status = getJobStatus(data);

          if (["failed", "error"].includes(String(status).toLowerCase())) {
            throw new Error(data?.last_error || data?.error || `Job ${jobId} failed`);
          }

          if (["forwarded", "done", "complete", "completed", "succeeded", "success"].includes(String(status).toLowerCase()) && text) {
            return text;
          }

          if (text && !/queued|poll|pending|running/i.test(text)) return text;
        } catch (err) {
          if (!err.transient && attempt > 2) console.warn("Job poll issue:", err);
        }
      }

      if (attempt === 4) {
        addCompanionMessage("system", "The companion is still thinking. I am waiting for the queued response instead of showing a gateway error.");
      }

      await sleep(2500);
    }

    return `Your message was queued as job ${jobId}, but the browser could not fetch the final answer yet. Refresh in a moment or try again.`;
  }

  function buildCompanionPrompt(message) {
    let studyHint = "";

    try {
      if (typeof state !== "undefined") {
        const selectedDeck = state.decks?.find?.((d) => String(d.id) === String(state.selectedDeckId));
        const cards = Array.isArray(state.cards) ? state.cards.slice(0, 40) : [];

        studyHint = JSON.stringify({
          selected_deck: selectedDeck || null,
          cards: cards.map((card) => ({
            id: card.id,
            question: card.question,
            answer: card.answer,
            difficulty: card.difficulty,
            correct_reviews: card.correct_reviews,
            incorrect_reviews: card.incorrect_reviews,
            accuracy: card.accuracy,
            tags: card.tags,
          })),
        });
      }
    } catch (_) {}

    return [
      "You are the user's AI study companion.",
      "Use the user's study-card context when provided.",
      "Do not invent cards or deck details.",
      "If the user asks what to study, prioritize hard cards, missed cards, and cards with low accuracy.",
      "Keep answers short, helpful, and actionable.",
      studyHint ? `STUDY_CONTEXT_JSON: ${studyHint}` : "STUDY_CONTEXT_JSON: unavailable from this page state.",
      `USER_MESSAGE: ${message}`,
    ].join("\n\n");
  }

  async function sendCompanionToApi(message) {
    const base = getApiBase();
    const prompt = buildCompanionPrompt(message);

    const attempts = [
      // PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER: prefer app_jobs queued chat before legacy local jobs.
      {
        url: `${base}/chat/queued`,
        body: { message: prompt, requested_model: "gemma4:e4b" },
      },
    ];

    if (studyUiLegacyJobsFallbackEnabled()) {
      // COMPANION_JOB_FIRST_V1: keep legacy local jobs fallback during migration.
      attempts.push({
        url: `${base}/jobs`,
        body: { job_type: "ollama_chat", prompt, requested_model: "gemma4:e4b" },
      });
    }

    attempts.push(
      {
        url: `${base}/chat`,
        body: { message, prompt, model: "gemma4:e4b" },
      },
      {
        url: `${base}/companion/chat`,
        body: { message, prompt, model: "gemma4:e4b" },
      },
    );

    for (const attempt of attempts) {
      try {
        const data = await fetchJson(attempt.url, {
          method: "POST",
          headers: jsonHeaders(),
          body: JSON.stringify(attempt.body),
        });

        const jobId = getJobId(data);
        const pollUrl = getPollUrl(data);
        const status = getJobStatus(data);
        const directText = extractText(data);

        if (jobId) {
          if (String(status).toLowerCase() === "queued") {
            addCompanionMessage("system", `Queued with Gemma E4B as job ${jobId}. Waiting for the worker...`);
          }
          return await pollJob(jobId, pollUrl);
        }

        if (directText && !/queued|poll|pending|running/i.test(directText)) return directText;
      } catch (err) {
        if (err.transient) {
          errors.push(`${attempt.url}: temporary gateway issue`);
          await sleep(1500);
        } else {
          errors.push(`${attempt.url}: ${err.message}`);
        }
      }
    }

    throw new Error(errors.join("\n"));
  }

  function getCompanionMessages() {
    return loadJson(CHAT_KEY, [
      {
        role: "assistant",
        text: "Hi, I am your study companion. Ask me what to study, paste an answer for me to check, or ask me to help make a card.",
      },
    ]);
  }

  function setCompanionMessages(messages) {
    saveJson(CHAT_KEY, messages);
  }

  function renderCompanionMessages() {
    const wrap = document.getElementById("companionMessages");
    if (!wrap) return;

    const messages = getCompanionMessages();
    wrap.innerHTML = messages
      .map((m) => `<div class="chat-bubble ${escapeHtml(m.role)}">${escapeHtml(m.text)}</div>`)
      .join("");

    wrap.scrollTop = wrap.scrollHeight;
  }

  function addCompanionMessage(role, text) {
    const messages = getCompanionMessages();
    messages.push({ role, text });
    setCompanionMessages(messages);
    renderCompanionMessages();
  }

  async function handleCompanionSubmit(message) {
    const input = document.getElementById("companionInput");
    const sendBtn = document.getElementById("companionSendBtn");
    const status = document.getElementById("companionMessage");

    const clean = String(message || input?.value || "").trim();
    if (!clean) return;

    if (input) input.value = "";
    addCompanionMessage("user", clean);

    if (sendBtn) sendBtn.disabled = true;
    if (status) status.textContent = "Thinking with Gemma E4B...";

    try {
      const answer = await sendCompanionToApi(clean);
      addCompanionMessage("assistant", answer || "I got a response, but it did not include readable text.");
      if (status) status.textContent = "";
    } catch (err) {
      console.error(err);
      const cleanError = err.transient
        ? "The companion may still be working, but the gateway timed out before the browser received the final response. I did not save the raw Cloudflare error page. Refresh in a moment or try again."
        : err.message;

      addCompanionMessage(
        "system",
        "I could not finish the companion response yet.\n\n" + cleanError
      );
      if (status) status.textContent = err.transient ? "Companion is still pending after a gateway timeout." : "Companion API route failed.";
    } finally {
      if (sendBtn) sendBtn.disabled = false;
    }
  }

  function setupCompanion() {
    renderCompanionMessages();

    const form = document.getElementById("companionForm");
    const clearBtn = document.getElementById("companionClearBtn");
    const suggestBtn = document.getElementById("companionStudySuggestBtn");

    if (form && !form.dataset.bound) {
      form.dataset.bound = "1";
      form.addEventListener("submit", (event) => {
        event.preventDefault();
        handleCompanionSubmit();
      });
    }

    if (clearBtn && !clearBtn.dataset.bound) {
      clearBtn.dataset.bound = "1";
      clearBtn.addEventListener("click", () => {
        localStorage.removeItem(CHAT_KEY);
        renderCompanionMessages();
      });
    }

    if (suggestBtn && !suggestBtn.dataset.bound) {
      suggestBtn.dataset.bound = "1";
      suggestBtn.addEventListener("click", () => {
        handleCompanionSubmit("What should I study right now based on my cards?");
      });
    }
  }

  function getReminders() {
    return loadJson(CALENDAR_KEY, []);
  }

  function setReminders(items) {
    saveJson(CALENDAR_KEY, items);
  }

  function renderCalendar() {
    const list = document.getElementById("calendarList");
    if (!list) return;

    const reminders = getReminders().sort((a, b) => String(a.time).localeCompare(String(b.time)));

    if (!reminders.length) {
      list.innerHTML = `<p class="muted">No reminders yet.</p>`;
      return;
    }

    list.innerHTML = reminders
      .map((item) => {
        const when = item.time ? new Date(item.time).toLocaleString() : "No time";
        return `
          <div class="calendar-item">
            <strong>${escapeHtml(item.title)}</strong>
            <time>${escapeHtml(when)}</time>
            ${item.notes ? `<p>${escapeHtml(item.notes)}</p>` : ""}
            <div class="mode-row">
              <button class="secondary" type="button" data-delete-reminder="${escapeHtml(item.id)}">Delete</button>
            </div>
          </div>
        `;
      })
      .join("");
  }

  function setupCalendar() {
    renderCalendar();

    const form = document.getElementById("calendarForm");
    const list = document.getElementById("calendarList");

    if (form && !form.dataset.bound) {
      form.dataset.bound = "1";
      form.addEventListener("submit", (event) => {
        event.preventDefault();

        const title = document.getElementById("calendarTitleInput")?.value?.trim();
        const time = document.getElementById("calendarTimeInput")?.value;
        const notes = document.getElementById("calendarNotesInput")?.value?.trim();

        if (!title || !time) return;

        const reminders = getReminders();
        reminders.push({
          id: String(Date.now()),
          title,
          time,
          notes,
        });

        setReminders(reminders);
        form.reset();
        renderCalendar();
      });
    }

    if (list && !list.dataset.bound) {
      list.dataset.bound = "1";
      list.addEventListener("click", (event) => {
        const btn = event.target.closest("[data-delete-reminder]");
        if (!btn) return;

        const id = btn.getAttribute("data-delete-reminder");
        setReminders(getReminders().filter((item) => String(item.id) !== String(id)));
        renderCalendar();
      });
    }
  }

  function setupExtraPageLinks() {
    document.querySelectorAll("[data-page-link]").forEach((btn) => {
      if (btn.dataset.extraBound) return;
      btn.dataset.extraBound = "1";
      btn.addEventListener("click", () => {
        setupCompanion();
        setupCalendar();
      });
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    setupCompanion();
    setupCalendar();
    setupExtraPageLinks();
  });
})();


/* === Shared Account auth redirect patch === */
(function () {
  const ACCOUNT_LOGIN = "https://alexhartel.com/";
  const ACCOUNT_REGISTER = "https://alexhartel.com/";
  const ACCOUNT_LOGOUT = "https://alexhartel.com/logout";
  const ACCOUNT_PROFILE = "https://alexhartel.com/profile";

  function go(url) {
    safeNavigate(url, "window.location.href assignment");
  }

  function isOldLoginTarget(value) {
    value = String(value || "").toLowerCase();
    return value === "login" || value === "#login" || value === "/login" || value.includes("loginpanel");
  }

  function isOldRegisterTarget(value) {
    value = String(value || "").toLowerCase();
    return value === "register" || value === "#register" || value === "/register" || value.includes("registerpanel");
  }

  function isOldProfileTarget(value) {
    value = String(value || "").toLowerCase();
    return value === "profile" || value === "#profile" || value === "/profile" || value.includes("profilepanel");
  }

  function rewriteAuthLinks() {
    document.querySelectorAll("a, button").forEach((el) => {
      const href = el.getAttribute("href");
      const pageLink = el.getAttribute("data-page-link");
      const text = (el.textContent || "").trim().toLowerCase();

      if (isOldLoginTarget(href) || isOldLoginTarget(pageLink) || text === "login" || text === "login / register") {
        el.setAttribute("href", ACCOUNT_LOGIN);
        el.removeAttribute("data-page-link");
      }

      if (isOldRegisterTarget(href) || isOldRegisterTarget(pageLink) || text === "register" || text === "create account") {
        el.setAttribute("href", ACCOUNT_REGISTER);
        el.removeAttribute("data-page-link");
      }

      if (isOldProfileTarget(href) || isOldProfileTarget(pageLink) || text === "profile") {
        el.setAttribute("href", ACCOUNT_PROFILE);
        el.removeAttribute("data-page-link");
      }

      if (text === "logout" || href === "/logout" || pageLink === "logout") {
        el.setAttribute("href", ACCOUNT_LOGOUT);
        el.removeAttribute("data-page-link");
      }
    });
  }

  document.addEventListener("click", (event) => {
    const el = event.target.closest("a, button");
    if (!el) return;

    const href = el.getAttribute("href");
    const pageLink = el.getAttribute("data-page-link");
    const text = (el.textContent || "").trim().toLowerCase();

    if (isOldLoginTarget(href) || isOldLoginTarget(pageLink) || text === "login" || text === "login / register") {
      event.preventDefault();
      event.stopPropagation();
      go(ACCOUNT_LOGIN);
      return;
    }

    if (isOldRegisterTarget(href) || isOldRegisterTarget(pageLink) || text === "register" || text === "create account") {
      event.preventDefault();
      event.stopPropagation();
      go(ACCOUNT_REGISTER);
      return;
    }

    if (isOldProfileTarget(href) || isOldProfileTarget(pageLink) || text === "profile") {
      event.preventDefault();
      event.stopPropagation();
      go(ACCOUNT_PROFILE);
      return;
    }

    if (text === "logout" || href === "/logout" || pageLink === "logout") {
      event.preventDefault();
      event.stopPropagation();
      go(ACCOUNT_LOGOUT);
    }
  }, true);

  document.addEventListener("DOMContentLoaded", rewriteAuthLinks);
  setInterval(rewriteAuthLinks, 1000);

  if (["#login", "#register", "#profile", "#logout"].includes(window.location.hash.toLowerCase())) {
    const hash = window.location.hash.toLowerCase();
    if (hash === "#login") go(ACCOUNT_LOGIN);
    if (hash === "#register") go(ACCOUNT_REGISTER);
    if (hash === "#profile") go(ACCOUNT_PROFILE);
    if (hash === "#logout") go(ACCOUNT_LOGOUT);
  }
})();


/* === Disable old Study auth panel and normalize Home/Study routing === */
(function () {
  const ACCOUNT_LOGIN = "https://alexhartel.com/";
  const ACCOUNT_REGISTER = "https://alexhartel.com/";

  function $(id) {
    return document.getElementById(id);
  }

  function hasOldStudyToken() {
    return true;
  }



  function hideAllPages() {
    document.querySelectorAll(".page-block").forEach((el) => el.classList.add("hidden"));
  }

  function showPage(page) {
    hideAllPages();
    const panel = document.querySelector(`[data-page="${page}"]`);
    if (panel) panel.classList.remove("hidden");
  }

  function showHome() {
    showPage("home");
    document.body.dataset.currentPage = "home";
  }

  function showStudyOrAccountLogin() {
    showPage("study");
    document.body.dataset.currentPage = "study";
  }



  function disableOldAuthPanel() {
    const authPanel = $("authPanel");
    if (!authPanel) return;

    // If old app tries to show authPanel, immediately replace it with shared account message.
    const title = authPanel.querySelector("h2");
    if (title) title.textContent = "Use your shared AI Platform account";

    authPanel.querySelectorAll("form").forEach((form) => {
      form.addEventListener("submit", (event) => {
        event.preventDefault();
        safeNavigate(ACCOUNT_LOGIN, "window.location.href assignment");
      }, true);
    });

    authPanel.querySelectorAll("[data-auth-tab]").forEach((btn) => {
      btn.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();
        const mode = btn.getAttribute("data-auth-tab");
        safeNavigate(mode === "register" ? ACCOUNT_REGISTER : ACCOUNT_LOGIN, "window.location.href assignment");
      }, true);
    });
  }

  function routeFromHash() {
    const path = String(window.location.pathname || "").toLowerCase();
    const hash = String(window.location.hash || "#home").toLowerCase();

    if (path === "/study" || path.startsWith("/study/") || hash === "#study") {
      showStudyOrAccountLogin();
      return;
    }

    if (hash === "#login" || hash === "#auth") {
      safeNavigate(ACCOUNT_LOGIN, "window.location.href assignment");
      return;
    }

    if (hash === "#register") {
      safeNavigate(ACCOUNT_REGISTER, "window.location.href assignment");
      return;
    }

    showHome();
  }

  document.addEventListener("click", (event) => {
    const link = event.target.closest("a, button");
    if (!link) return;

    const href = link.getAttribute("href") || "";
    const pageLink = link.getAttribute("data-page-link") || "";
    const text = (link.textContent || "").trim().toLowerCase();

    if (href.endsWith("#home") || pageLink === "home" || text === "home") {
      event.preventDefault();
      event.stopPropagation();
      history.pushState(null, "", "#home");
      showHome();
      return;
    }

    if (href.endsWith("#study") || pageLink === "study" || text === "study") {
      event.preventDefault();
      event.stopPropagation();
      history.pushState(null, "", "#study");
      showStudyOrAccountLogin();
      return;
    }

    if (pageLink === "auth" || text === "login" || text === "login / register") {
      event.preventDefault();
      event.stopPropagation();
      safeNavigate(ACCOUNT_LOGIN, "window.location.href assignment");
    }
  }, true);

  window.addEventListener("hashchange", routeFromHash);

  document.addEventListener("DOMContentLoaded", () => {
    disableOldAuthPanel();

    if (window.location.pathname === "/study" || window.location.pathname.startsWith("/study/")) {
      history.replaceState(null, "", "/study#study");
      showStudyOrAccountLogin();
      return;
    }

    setTimeout(routeFromHash, 0);
    setTimeout(routeFromHash, 250);
  });

  // If the older app reveals authPanel after async API checks, push the user to shared account instead.
  const observer = new MutationObserver(() => {
    const authPanel = $("authPanel");
    if (authPanel && !authPanel.classList.contains("hidden")) {
      if (window.location.hash.toLowerCase() === "#study" && !hasOldStudyToken()) {
        safeNavigate(`${ACCOUNT_LOGIN}?next=${encodeURIComponent("https://alexhartel.com/study")}`, "window.location.href assignment");
      }
    }
  });

  document.addEventListener("DOMContentLoaded", () => {
    observer.observe(document.body, {
      attributes: true,
      subtree: true,
      attributeFilter: ["class"],
    });
  });
})();


/* === Shared Account dynamic header auth state === */
(function () {
  const ACCOUNT_LOGIN = "https://alexhartel.com/";
  const ACCOUNT_LOGOUT = "https://alexhartel.com/logout";
  const AUTH_STATUS_URL = "/api/me";

  async function updateSharedAuthHeader() {
    const link = document.getElementById("sharedAuthLink");
    if (!link) return;

    link.textContent = "Login / Register";
    link.href = ACCOUNT_LOGIN;

    try {
      const res = await fetch(AUTH_STATUS_URL, {
        method: "GET",
        credentials: "include",
        cache: "no-store",
      });

      if (!res.ok) return;

      const data = await res.json();

      if (data && data.authenticated) {
        link.textContent = "Logout";
        link.href = ACCOUNT_LOGOUT;
      }
    } catch {
      // If cross-domain status fails, keep Login/Register visible.
    }
  }

  document.addEventListener("DOMContentLoaded", updateSharedAuthHeader);
  window.addEventListener("focus", updateSharedAuthHeader);
})();

/* ============================================================
   System status header panel
   Shows controller/server/container/service state from:
   GET  /api/system/status
   POST /api/system/pveso/boot
   ============================================================ */

(function systemStatusPanelPatch() {
  const SYSTEM_REFRESH_MS = 30000;

  function systemTitleCase(value) {
    if (!value) return "Unknown";
    return String(value).slice(0, 1).toUpperCase() + String(value).slice(1);
  }

  function systemApiBase() {
    // Reuse the existing frontend API base when available.
    // In this app API_BASE usually ends with /api.
    if (typeof API_BASE !== "undefined" && API_BASE) return API_BASE;
    return "/api";
  }

  function systemAuthHeaders() {
    const headers = {
      "Content-Type": "application/json",
    };

    const token =
      localStorage.getItem("edgeStudyToken") ||
      localStorage.getItem("aiStudyToken") ||
      localStorage.getItem("authToken") ||
      localStorage.getItem("token") ||
      "";

    if (token) {
      // Wrapper cookie auth is used; do not send stale Authorization headers.
    }

            return headers;
  }

  function systemCreatePanel() {
    if (document.getElementById("systemStatusButton")) return;

    const button = document.createElement("button");
    button.id = "systemStatusButton";
    button.type = "button";
    button.className = "system-status-pill";
    button.innerHTML = `
      <span id="systemStatusDot" class="system-status-dot unknown"></span>
      <span id="systemStatusLabel">System</span>
    `;

    const panel = document.createElement("section");
    panel.id = "systemStatusPanel";
    panel.className = "system-status-panel hidden";
    panel.innerHTML = `
      <div class="system-status-head">
        <div>
          <h2>System Status</h2>
          <p id="systemStatusSummary">Checking system...</p>
        </div>
        <button id="systemBootServerBtn" class="system-status-primary" type="button">
          Start Server
        </button>
      </div>

      <div class="system-status-grid">
        <div>
          <h3>Nodes</h3>
          <div id="systemNodesList" class="system-status-list"></div>
        </div>

        <div>
          <h3>Services</h3>
          <div id="systemServicesList" class="system-status-list"></div>
        </div>
      </div>

      <div id="systemOfflineNotice" class="system-status-notice hidden">
        The compute server is offline. The website can stay loaded from Cloudflare,
        and the controller can wake the server when needed.
      </div>
    `;

    const headerTarget =
      document.querySelector(".hdr-nav") ||
      document.querySelector("header nav") ||
      document.querySelector(".app-header") ||
      document.querySelector(".top-nav") ||
      document.querySelector("header") ||
      document.body;

    headerTarget.appendChild(button);
    document.body.appendChild(panel);

    button.addEventListener("click", () => {
      panel.classList.toggle("hidden");
      systemLoadStatus();
    });

    document
      .getElementById("systemBootServerBtn")
      ?.addEventListener("click", systemBootServer);
  }

  function systemSetState(state) {
    const clean = state || "unknown";
    const dot = document.getElementById("systemStatusDot");
    const label = document.getElementById("systemStatusLabel");

    if (dot) dot.className = `system-status-dot ${clean}`;
    if (label) label.textContent = `System: ${systemTitleCase(clean)}`;
  }

  function systemRenderItems(targetId, items) {
    const target = document.getElementById(targetId);
    if (!target) return;

    target.innerHTML = "";

    for (const item of items || []) {
      const state = item.state || "unknown";

      const row = document.createElement("div");
      row.className = "system-status-item";
      row.innerHTML = `
        <div class="system-status-row">
          <div class="system-status-name"></div>
          <span class="system-status-badge ${state}"></span>
        </div>
        <div class="system-status-detail"></div>
      `;

      row.querySelector(".system-status-name").textContent =
        item.name || item.id || "Unknown";

      row.querySelector(".system-status-badge").textContent = state;

      row.querySelector(".system-status-detail").textContent =
        item.detail || item.role || "";

      target.appendChild(row);
    }
  }

  async function systemLoadStatus() {
    const summary = document.getElementById("systemStatusSummary");
    const bootBtn = document.getElementById("systemBootServerBtn");
    const offlineNotice = document.getElementById("systemOfflineNotice");

    try {
      const res = await fetch(`${systemApiBase()}/system/status`, {
        method: "GET",
        headers: systemAuthHeaders(),
        cache: "no-store",
      });

      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }

      const data = await res.json();

      systemSetState(data.overall_state);

      if (summary) {
        summary.textContent = `Overall state: ${systemTitleCase(data.overall_state)}. Last checked: ${data.checked_at || "unknown"}.`;
      }

      systemRenderItems("systemNodesList", data.nodes || []);
      systemRenderItems("systemServicesList", data.services || []);

      const pveso = (data.nodes || []).find((n) => n.id === "pveso");

      if (pveso?.state === "offline") {
        offlineNotice?.classList.remove("hidden");
        if (bootBtn) {
          bootBtn.disabled = true;
          bootBtn.textContent = state.token ? "Start Server" : "Login to Start Server";
        }
      } else if (pveso?.state === "booting") {
        offlineNotice?.classList.remove("hidden");
        if (bootBtn) {
          bootBtn.disabled = true;
          bootBtn.textContent = "Server Booting";
        }
      } else {
        offlineNotice?.classList.add("hidden");
        if (bootBtn) {
          bootBtn.disabled = true;
          bootBtn.textContent = state.token ? "Start Server" : "Login to Start Server";
        }
      }
    } catch (err) {
      systemSetState("unknown");

      if (summary) {
        summary.textContent = `Could not reach system controller: ${err.message}`;
      }

      systemRenderItems("systemNodesList", []);
      systemRenderItems("systemServicesList", []);
      offlineNotice?.classList.remove("hidden");
    }
  }

  async function systemBootServer() {
    const bootBtn = document.getElementById("systemBootServerBtn");

    if (bootBtn) {
      bootBtn.disabled = true;
      bootBtn.textContent = "Sending wake signal...";
    }

    try {
      if (!state.token) {
        alert("Please log in before starting the server.");
        return;
      }

      const res = await fetch(`${systemApiBase()}/system/pveso/boot`, {
        method: "POST",
        headers: systemAuthHeaders(),
        body: JSON.stringify({ confirm: "BOOT_PVESO" }),
      });

      const data = await res.json();

      if (!data.ok) {
        throw new Error(data.error || data.blocked_reason || "Boot request failed");
      }

      await systemLoadStatus();
    } catch (err) {
      alert(`Could not start server: ${err.message}`);
    } finally {
      if (bootBtn) {
        bootBtn.disabled = false;
        bootBtn.textContent = "Start Server";
      }
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    systemCreatePanel();
    systemLoadStatus();
    setInterval(systemLoadStatus, SYSTEM_REFRESH_MS);
  });
})();

/* FORCE_PRIVATE_STUDY_PANEL_ON_STUDY_PATH_V1 */
(function () {
  function forcePrivateStudyPanel() {
    const onStudyPath =
      window.location.pathname === "/study" ||
      window.location.pathname.startsWith("/study/");

    if (!onStudyPath) return;

    document.querySelectorAll(".page-block").forEach((el) => {
      el.classList.add("hidden");
    });

    document.querySelectorAll('[data-page="study"]').forEach((el) => {
      el.classList.remove("hidden");
    });

    document.body.dataset.currentPage = "study";

    const authLink = document.getElementById("sharedAuthLink");
    if (authLink && localStorage.getItem("edgeStudyToken")) {
      authLink.textContent = "Profile";
      authLink.href = "https://alexhartel.com/profile";
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    forcePrivateStudyPanel();
    setTimeout(forcePrivateStudyPanel, 100);
    setTimeout(forcePrivateStudyPanel, 500);
    setTimeout(forcePrivateStudyPanel, 1500);
  });

  window.addEventListener("load", forcePrivateStudyPanel);
})();
