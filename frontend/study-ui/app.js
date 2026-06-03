const API_BASE = "https://edge-public-proxy.alexhartel179.workers.dev/api";

const state = {
  token: localStorage.getItem("edgeStudyToken") || "",
  user: null,
  decks: [],
  selectedDeckId: "",
  queue: [],
  currentCardIndex: 0,
  showingAnswer: false
};

const $ = (id) => document.getElementById(id);

function setMessage(id, text, type = "") {
  const el = $(id);
  el.textContent = text || "";
  el.className = `message ${type}`.trim();
}

function authHeaders(json = false) {
  const headers = {};
  if (json) headers["Content-Type"] = "application/json";
  if (state.token) headers.Authorization = `Bearer ${state.token}`;
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

  $("welcomeTitle").textContent = `Welcome${state.user?.display_name ? `, ${state.user.display_name}` : ""}`;
  $("userEmail").textContent = state.user?.email || "";
}

function showLoggedOutUI() {
  $("authPanel").classList.remove("hidden");
  $("dashboardPanel").classList.add("hidden");
  $("studyGrid").classList.add("hidden");
  $("reviewPanel").classList.add("hidden");
  $("cardsPanel").classList.add("hidden");
}

async function loadMe() {
  if (!state.token) {
    showLoggedOutUI();
    return;
  }

  try {
    const data = await api("/me", {
      headers: authHeaders()
    });
    state.user = data.user;
    showAuthedUI();
    await refreshAll();
  } catch {
    state.token = "";
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

$("authForm").addEventListener("submit", handleAuthSubmit);
$("logoutBtn").addEventListener("click", logout);
$("deckForm").addEventListener("submit", createDeck);
$("cardForm").addEventListener("submit", createCard);
$("deckSelect").addEventListener("change", async (event) => {
  state.selectedDeckId = event.target.value;
  renderDeckSummary();
  await loadCardsAndStats();
});
$("loadQueueBtn").addEventListener("click", loadReviewQueue);

checkApiStatus();
loadMe();
