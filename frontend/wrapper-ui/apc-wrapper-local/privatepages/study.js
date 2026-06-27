(function () {
  "use strict";

  if (window.__APC_STUDY_MANAGER_V2__) return;
  window.__APC_STUDY_MANAGER_V2__ = true;

  function store() {
    return window.APC_STUDY_STORE;
  }

  function byId(id) {
    return document.getElementById(id);
  }

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function activeDeck(state) {
    return state.decks.find((deck) => deck.id === state.activeDeckId) || state.decks[0] || null;
  }

  function renderStats(state) {
    const s = store().stats(state);
    const summaryOverall =
      state.backendReviewSummary && state.backendReviewSummary.overall
        ? state.backendReviewSummary.overall
        : null;

    const progressOverall =
      state.backendProgress && state.backendProgress.overall
        ? state.backendProgress.overall
        : null;

    const backendCardsReviewed =
      summaryOverall && Number.isFinite(Number(summaryOverall.total_reviews))
        ? Number(summaryOverall.total_reviews)
        : progressOverall && Number.isFinite(Number(progressOverall.review_count))
          ? Number(progressOverall.review_count)
          : s.cardsSeen;

    const backendCorrect =
      summaryOverall && Number.isFinite(Number(summaryOverall.correct))
        ? Number(summaryOverall.correct)
        : progressOverall && Number.isFinite(Number(progressOverall.correct_count))
          ? Number(progressOverall.correct_count)
          : 0;

    const backendWrong =
      summaryOverall && Number.isFinite(Number(summaryOverall.wrong))
        ? Number(summaryOverall.wrong)
        : progressOverall && Number.isFinite(Number(progressOverall.wrong_count))
          ? Number(progressOverall.wrong_count)
          : 0;

    return `
      <section class="study-stat-grid">
        <article><strong>${s.totalDecks}</strong><span>Decks</span></article>
        <article><strong>${s.totalCards}</strong><span>Total cards</span></article>
        <article><strong>${s.reviewedCards}</strong><span>Unique cards reviewed</span></article>
        <article><strong>${backendCardsReviewed}</strong><span>Total card reviews</span></article>
        <article><strong>${backendCorrect}</strong><span>Correct</span></article>
        <article><strong>${backendWrong}</strong><span>Wrong</span></article>
      </section>
    `;
  }

  function renderDecks(state) {
    const decks = state.decks;

    return `
      <section class="study-panel">
        <h2>Decks</h2>

        <form class="study-form" data-study-form="create-deck">
          <input id="studyDeckTitle" placeholder="Deck name" />
          <input id="studyDeckDescription" placeholder="Description optional" />
          <button class="study-button" type="submit">Create deck</button>
        </form>

        <div class="study-list">
          ${
            decks.length
              ? decks.map((deck) => `
                  <article class="study-row ${deck.id === state.activeDeckId ? "active" : ""}">
                    <div>
                      <h3>${escapeHtml(deck.title)}</h3>
                      <p>${escapeHtml(deck.description || "No description")}</p>
                      <small>${state.cards.filter((card) => card.deckId === deck.id).length} card(s)</small>
                    </div>
                    <div class="study-row-actions">
                      <button class="study-button secondary" data-study-action="select-deck" data-deck-id="${escapeHtml(deck.id)}">Select</button>
                      <button class="study-button secondary" data-study-action="edit-deck" data-deck-id="${escapeHtml(deck.id)}">Edit</button>
                      <button class="study-button danger" data-study-action="delete-deck" data-deck-id="${escapeHtml(deck.id)}">Remove</button>
                    </div>
                  </article>
                `).join("")
              : `<p class="study-muted">No decks yet. Create your first deck above.</p>`
          }
        </div>
      </section>
    `;
  }

  function renderCards(state) {
    const deck = activeDeck(state);
    const deckCards = deck ? state.cards.filter((card) => card.deckId === deck.id) : [];

    return `
      <section class="study-panel">
        <h2>Cards</h2>
        <p class="study-muted">${deck ? `Active deck: ${escapeHtml(deck.title)}` : "Create or select a deck first."}</p>

        <form class="study-form card-form" data-study-form="create-card">
          <textarea id="studyCardFront" placeholder="Question / front of card"></textarea>
          <textarea id="studyCardBack" placeholder="Answer / back of card"></textarea>
          <select id="studyCardDifficulty">
            <option value="new">new</option>
            <option value="easy">easy</option>
            <option value="medium">medium</option>
            <option value="hard">hard</option>
          </select>
          <button class="study-button" type="submit" ${deck ? "" : "disabled"}>Create card</button>
        </form>

        <div class="study-list">
          ${
            deckCards.length
              ? deckCards.map((card) => `
                  <article class="study-row card">
                    <div>
                      <h3>${escapeHtml(card.front)}</h3>
                      <p>${escapeHtml(card.back)}</p>
                      <small>
                        ${escapeHtml(card.difficulty)}
                        ${card.flagged ? " · flagged" : ""}
                        · seen ${card.seenCount}
                        · correct ${card.correctCount}
                        · wrong ${card.wrongCount}
                        · skipped ${card.skipCount}
                      </small>
                    </div>
                    <div class="study-row-actions">
                      <button class="study-button secondary" data-study-action="flag-card" data-card-id="${escapeHtml(card.id)}">${card.flagged ? "Unflag" : "Flag"}</button>
                      <button class="study-button secondary" data-study-action="edit-card" data-card-id="${escapeHtml(card.id)}">Edit</button>
                      <button class="study-button danger" data-study-action="delete-card" data-card-id="${escapeHtml(card.id)}">Remove</button>
                    </div>
                  </article>
                `).join("")
              : `<p class="study-muted">No cards in this deck yet.</p>`
          }
        </div>
      </section>
    `;
  }

  function renderSessions(state) {
    const runtime = state.runtime;
    return `
      <section class="study-panel">
        <h2>Sessions</h2>

        ${
          runtime
            ? `<article class="study-live-session">
                <strong>${escapeHtml(runtime.status)}</strong>
                <span>${escapeHtml(runtime.style)} · ${runtime.cardsSeen} card(s) reviewed · ${store().formatDuration(store().activeElapsedMs(runtime))}</span>
              </article>`
            : `<p class="study-muted">No active session. Start one by asking Sol: start study.</p>`
        }

        <div class="study-list">
          ${
            state.sessions.length
              ? state.sessions.slice(0, 12).map((session) => `
                  <article class="study-row">
                    <div>
                      <h3>${escapeHtml(session.style === "backend" ? "Study session" : session.style + " study session")}</h3>
                      <p>${session.cardsSeen} card(s) · ${session.correct} correct · ${session.wrong} wrong · ${session.skipped} skipped</p>
                      <small>${escapeHtml(new Date(session.startedAt).toLocaleString())} · ${store().formatDuration(session.durationMs)}</small>
                    </div>
                  </article>
                `).join("")
              : `<p class="study-muted">No saved sessions yet. Sessions are saved after at least one card is reviewed.</p>`
          }
        </div>
      </section>
    `;
  }

  async function syncThenRender() {
    try {
      if (store() && store().syncFromBackend) {
        await store().syncFromBackend();
      }
    } catch (error) {
      console.warn("[study] backend sync failed", error);
    }
    render();
  }

  function render() {
    const el = byId("studyPrivateApp");
    if (!el || !store()) return;

    const state = store().load();

    el.innerHTML = `
      ${renderStats(state)}
      <section class="study-two-column">
        ${renderDecks(state)}
        ${renderCards(state)}
      </section>
      ${renderSessions(state)}
    `;
  }

  function bind() {
    document.addEventListener("submit", function (event) {
      const form = event.target.closest("[data-study-form]");
      if (!form || !store()) return;

      event.preventDefault();

      if (form.dataset.studyForm === "create-deck") {
        store().createDeck(byId("studyDeckTitle").value, byId("studyDeckDescription").value);
        render();
      }

      if (form.dataset.studyForm === "create-card") {
        const state = store().load();
        store().createCard(
          state.activeDeckId,
          byId("studyCardFront").value,
          byId("studyCardBack").value,
          byId("studyCardDifficulty").value
        );
        render();
      }
    });

    document.addEventListener("click", function (event) {
      const button = event.target.closest("[data-study-action]");
      if (!button || !store()) return;

      event.preventDefault();

      const action = button.dataset.studyAction;

      if (action === "select-deck") store().setActiveDeck(button.dataset.deckId);

      if (action === "delete-deck" && confirm("Remove this deck and its cards?")) {
        store().deleteDeck(button.dataset.deckId);
      }

      if (action === "edit-deck") {
        const state = store().load();
        const deck = state.decks.find((item) => item.id === button.dataset.deckId);
        if (deck) {
          const title = prompt("Deck name", deck.title);
          const description = prompt("Deck description", deck.description || "");
          store().editDeck(deck.id, { title, description });
        }
      }

      if (action === "delete-card" && confirm("Remove this card?")) {
        store().deleteCard(button.dataset.cardId);
      }

      if (action === "flag-card") {
        store().toggleFlagCard(button.dataset.cardId);
      }

      if (action === "edit-card") {
        const state = store().load();
        const card = state.cards.find((item) => item.id === button.dataset.cardId);
        if (card) {
          const front = prompt("Question / front", card.front);
          const back = prompt("Answer / back", card.back);
          const difficulty = prompt("Difficulty: new, easy, medium, hard", card.difficulty);
          store().editCard(card.id, { front, back, difficulty });
        }
      }

      render();
    });
  }

  window.APC_PRIVATE_STUDY = {
    render,
    version: "study-manager-v2"
  };

  bind();

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "study") syncThenRender();
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", syncThenRender, { once: true });
  } else {
    syncThenRender();
  }
})();
