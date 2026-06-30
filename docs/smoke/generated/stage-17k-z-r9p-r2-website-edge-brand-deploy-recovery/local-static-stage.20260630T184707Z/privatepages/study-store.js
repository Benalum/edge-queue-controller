(function () {
  "use strict";

  /* Stage 16 R3R stable owner fallback */
  function apcStableOwnerFallbackR3R() {
    try {
      const gate = window.APC_AUTH_GATE_STATUS || '';
      const last = window.localStorage ? window.localStorage.getItem('apcLastKnownSignedInEmail') : '';
      if ((gate === 'checking' || gate === 'signed_in') && last) return last;
    } catch (_) {}
    return 'local-user';
  }


  if (window.APC_STUDY_STORE) return;

  const VERSION = "study-store-v2";

  function nowIso() {
    return new Date().toISOString();
  }

  function uid(prefix) {
    return prefix + "-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8);
  }

  function getUserEmail() {
    try {
      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me
        ? window.APC_PRIVATEPAGES.me()
        : null;
      return user && user.email ? user.email : apcStableOwnerFallbackR3R();
    } catch (_) {
      return apcStableOwnerFallbackR3R();
    }
  }

  function key() {
    return "apcPrivateStudyState:" + getUserEmail();
  }

  function defaults() {
    return {
      version: VERSION,
      activeDeckId: "",
      decks: [],
      cards: [],
      sessions: [],
      runtime: null
    };
  }

  function normalize(state) {
    const base = defaults();
    const out = { ...base, ...(state || {}) };

    out.decks = Array.isArray(out.decks) ? out.decks : [];
    out.cards = Array.isArray(out.cards) ? out.cards : [];
    out.sessions = Array.isArray(out.sessions) ? out.sessions : [];
    out.runtime = out.runtime && typeof out.runtime === "object" ? out.runtime : null;

    out.decks = out.decks.map((deck) => ({
      id: deck.id || deck.deckId || uid("deck"),
      title: deck.title || deck.name || deck.deckName || deck.subject || "Untitled deck",
      description: deck.description || deck.subject || deck.notes || "",
      createdAt: deck.createdAt || deck.created_at || nowIso(),
      updatedAt: deck.updatedAt || deck.updated_at || nowIso()
    }));

    out.cards = out.cards.map((card) => {
      const front = card.front || card.question || card.prompt || card.term || card.title || "";
      const back = card.back || card.answer || card.response || card.definition || card.content || "";
      return {
        id: card.id || card.cardId || uid("card"),
        deckId: card.deckId || card.deck_id || card.deck || out.activeDeckId || (out.decks[0] && out.decks[0].id) || "",
        front,
        back,
        difficulty: card.difficulty || card.level || "new",
        flagged: Boolean(card.flagged || card.flag || card.isFlagged),
        seenCount: Number(card.seenCount || card.seen_count || card.reviewCount || 0),
        correctCount: Number(card.correctCount || card.correct_count || 0),
        wrongCount: Number(card.wrongCount || card.wrong_count || 0),
        skipCount: Number(card.skipCount || card.skip_count || 0),
        lastResult: card.lastResult || card.last_result || "",
        lastSeenAt: card.lastSeenAt || card.last_seen_at || "",
        createdAt: card.createdAt || card.created_at || nowIso(),
        updatedAt: card.updatedAt || card.updated_at || nowIso()
      };
    }).filter((card) => card.deckId && String(card.front).trim() && String(card.back).trim());

    if (!out.activeDeckId && out.decks[0]) out.activeDeckId = out.decks[0].id;
    if (out.activeDeckId && !out.decks.some((deck) => deck.id === out.activeDeckId)) {
      out.activeDeckId = out.decks[0] ? out.decks[0].id : "";
    }

    out.version = VERSION;
    return out;
  }

  function load() {
    try {
      return normalize(JSON.parse(localStorage.getItem(key()) || "{}"));
    } catch (_) {
      return defaults();
    }
  }

  function save(state) {
    const normalized = normalize(state);
    localStorage.setItem(key(), JSON.stringify(normalized));
    return normalized;
  }

  function update(mutator) {
    const state = load();
    mutator(state);
    return save(state);
  }

  function createDeck(title, description) {
    return update((state) => {
      const deck = {
        id: uid("deck"),
        title: String(title || "").trim() || "Untitled deck",
        description: String(description || "").trim(),
        createdAt: nowIso(),
        updatedAt: nowIso()
      };
      state.decks.unshift(deck);
      state.activeDeckId = deck.id;
    });
  }

  function editDeck(deckId, patch) {
    return update((state) => {
      const deck = state.decks.find((item) => item.id === deckId);
      if (!deck) return;
      if ("title" in patch) deck.title = String(patch.title || "").trim() || deck.title;
      if ("description" in patch) deck.description = String(patch.description || "").trim();
      deck.updatedAt = nowIso();
    });
  }

  function deleteDeck(deckId) {
    return update((state) => {
      state.decks = state.decks.filter((deck) => deck.id !== deckId);
      state.cards = state.cards.filter((card) => card.deckId !== deckId);
      if (state.activeDeckId === deckId) state.activeDeckId = state.decks[0] ? state.decks[0].id : "";
      if (state.runtime && state.runtime.deckIds && state.runtime.deckIds.includes(deckId)) {
        state.runtime = null;
      }
    });
  }

  function setActiveDeck(deckId) {
    return update((state) => {
      if (state.decks.some((deck) => deck.id === deckId)) state.activeDeckId = deckId;
    });
  }

  function createCard(deckId, front, back, difficulty) {
    return update((state) => {
      const targetDeckId = deckId || state.activeDeckId || (state.decks[0] && state.decks[0].id);
      if (!targetDeckId) return;

      state.cards.unshift({
        id: uid("card"),
        deckId: targetDeckId,
        front: String(front || "").trim(),
        back: String(back || "").trim(),
        difficulty: difficulty || "new",
        flagged: false,
        seenCount: 0,
        correctCount: 0,
        wrongCount: 0,
        skipCount: 0,
        lastResult: "",
        lastSeenAt: "",
        createdAt: nowIso(),
        updatedAt: nowIso()
      });
      state.activeDeckId = targetDeckId;
    });
  }

  function editCard(cardId, patch) {
    return update((state) => {
      const card = state.cards.find((item) => item.id === cardId);
      if (!card) return;
      if ("front" in patch) card.front = String(patch.front || "").trim() || card.front;
      if ("back" in patch) card.back = String(patch.back || "").trim() || card.back;
      if ("difficulty" in patch) card.difficulty = patch.difficulty || card.difficulty;
      if ("deckId" in patch && state.decks.some((deck) => deck.id === patch.deckId)) card.deckId = patch.deckId;
      card.updatedAt = nowIso();
    });
  }

  function deleteCard(cardId) {
    return update((state) => {
      state.cards = state.cards.filter((card) => card.id !== cardId);
      if (state.runtime && state.runtime.currentCardId === cardId) {
        state.runtime.currentCardId = "";
      }
    });
  }

  function toggleFlagCard(cardId) {
    return update((state) => {
      const card = state.cards.find((item) => item.id === cardId);
      if (!card) return;
      card.flagged = !card.flagged;
      card.updatedAt = nowIso();
    });
  }

  function cardsForDecks(state, deckIds) {
    const ids = new Set(deckIds || []);
    return state.cards.filter((card) => ids.has(card.deckId));
  }

  function cardScore(card) {
    if (!card.seenCount) return -100;
    return (card.wrongCount * 4) + (card.flagged ? 5 : 0) - (card.correctCount * 2) + card.skipCount;
  }

  function filterByStyle(cards, style) {
    const cleanStyle = style || "balanced";
    let selected = cards.slice();

    if (cleanStyle === "new") selected = cards.filter((card) => !card.seenCount || card.difficulty === "new");
    if (cleanStyle === "all") selected = cards.slice();
    if (cleanStyle === "hard") selected = cards.filter((card) => card.difficulty === "hard" || card.flagged || card.wrongCount > card.correctCount);
    if (cleanStyle === "medium") selected = cards.filter((card) => card.difficulty === "medium");
    if (cleanStyle === "easy") selected = cards.filter((card) => card.difficulty === "easy");
    if (cleanStyle === "balanced") {
      selected = cards.slice().sort((a, b) => cardScore(b) - cardScore(a));
    }

    if (!selected.length && cleanStyle !== "all") selected = cards.slice();

    return selected;
  }

  function startSession(style, deckIds) {
    let result = null;

    const state = update((draft) => {
      if (draft.runtime && ["active", "paused"].includes(draft.runtime.status)) {
        result = { ok: false, message: "A study session is already running." };
        return;
      }

      const cleanDeckIds = (deckIds || []).filter((id) => draft.decks.some((deck) => deck.id === id));
      const useDeckIds = cleanDeckIds.length ? cleanDeckIds : (draft.activeDeckId ? [draft.activeDeckId] : []);

      const eligible = filterByStyle(cardsForDecks(draft, useDeckIds), style);
      const queue = eligible.map((card) => card.id);

      if (!queue.length) {
        result = { ok: false, message: "No cards are available for that deck/style yet." };
        return;
      }

      draft.runtime = {
        id: uid("session"),
        status: "active",
        style: style || "balanced",
        deckIds: useDeckIds,
        queue,
        index: 0,
        currentCardId: queue[0],
        pendingSelfAssessment: null,
        startedAt: nowIso(),
        pausedAt: "",
        totalPausedMs: 0,
        cardsSeen: 0,
        correct: 0,
        wrong: 0,
        skipped: 0
      };

      result = { ok: true, message: "Study session started.", runtime: draft.runtime };
    });

    return result || { ok: true, state };
  }

  function activeElapsedMs(runtime) {
    if (!runtime || !runtime.startedAt) return 0;
    const start = Date.parse(runtime.startedAt);
    const now = runtime.status === "paused" && runtime.pausedAt ? Date.parse(runtime.pausedAt) : Date.now();
    return Math.max(0, now - start - Number(runtime.totalPausedMs || 0));
  }

  function pauseSession() {
    let message = "No active session to pause.";
    const state = update((draft) => {
      const rt = draft.runtime;
      if (!rt || rt.status !== "active") return;
      rt.status = "paused";
      rt.pausedAt = nowIso();
      message = "Study session paused.";
    });
    return { state, message };
  }

  function resumeSession() {
    let message = "No paused session to resume.";
    const state = update((draft) => {
      const rt = draft.runtime;
      if (!rt || rt.status !== "paused") return;
      if (rt.pausedAt) rt.totalPausedMs += Math.max(0, Date.now() - Date.parse(rt.pausedAt));
      rt.status = "active";
      rt.pausedAt = "";
      message = "Study session resumed.";
    });
    return { state, message };
  }

  function finishRuntime(draft, reason) {
    const rt = draft.runtime;
    if (!rt) return null;

    if (rt.status === "paused" && rt.pausedAt) {
      rt.totalPausedMs += Math.max(0, Date.now() - Date.parse(rt.pausedAt));
    }

    const endedAt = nowIso();
    const durationMs = activeElapsedMs({ ...rt, status: "active", pausedAt: "" });

    const record = {
      id: rt.id,
      startedAt: rt.startedAt,
      endedAt,
      durationMs,
      style: rt.style,
      deckIds: rt.deckIds || [],
      cardsSeen: rt.cardsSeen || 0,
      correct: rt.correct || 0,
      wrong: rt.wrong || 0,
      skipped: rt.skipped || 0,
      reason: reason || "completed"
    };

    if (record.cardsSeen > 0) {
      draft.sessions.unshift(record);
    }

    draft.runtime = null;
    return record;
  }

  function stopSession() {
    let record = null;
    const state = update((draft) => {
      record = finishRuntime(draft, "stopped");
    });
    return {
      state,
      record,
      message: record && record.cardsSeen > 0
        ? "Study session stopped and saved."
        : "Study session stopped. No session was saved because no cards were reviewed."
    };
  }

  function currentCard(state) {
    const rt = state.runtime;
    if (!rt || !rt.currentCardId) return null;
    return state.cards.find((card) => card.id === rt.currentCardId) || null;
  }

  function questionText(state) {
    const card = currentCard(state);
    if (!card) return "";
    return "Question:\n\n" + card.front;
  }

  function normalizeAnswer(value) {
    return String(value || "")
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function classifySelfGrade(answer) {
    const a = normalizeAnswer(answer);
    if (["right", "correct", "yes", "y", "i was right", "got it"].some((x) => a === x || a.includes(x))) return "correct";
    if (["wrong", "incorrect", "no", "n", "i was wrong"].some((x) => a === x || a.includes(x))) return "wrong";
    if (["skip", "skipped", "pass"].some((x) => a === x || a.includes(x))) return "skipped";
    return "";
  }

  function recordResult(draft, result) {
    const rt = draft.runtime;
    const card = currentCard(draft);
    if (!rt || !card) return { done: true, nextQuestion: "" };

    card.seenCount += 1;
    card.lastSeenAt = nowIso();
    card.lastResult = result;
    card.updatedAt = nowIso();

    rt.cardsSeen += 1;

    if (result === "correct") {
      card.correctCount += 1;
      rt.correct += 1;
      if (card.seenCount >= 3 && card.correctCount >= card.wrongCount + 2) card.difficulty = "easy";
      else if (card.difficulty === "new") card.difficulty = "medium";
    }

    if (result === "wrong") {
      card.wrongCount += 1;
      rt.wrong += 1;
      card.difficulty = "hard";
    }

    if (result === "skipped") {
      card.skipCount += 1;
      rt.skipped += 1;
    }

    rt.pendingSelfAssessment = null;
    rt.index += 1;
    rt.currentCardId = rt.queue[rt.index] || "";

    if (!rt.currentCardId) {
      const record = finishRuntime(draft, "completed");
      return { done: true, record };
    }

    return { done: false, nextQuestion: questionText(draft) };
  }

  function answerCurrent(answer) {
    let reply = "";
    let savedState = null;

    savedState = update((draft) => {
      const rt = draft.runtime;
      const card = currentCard(draft);

      if (!rt || !card) {
        reply = "";
        return;
      }

      if (rt.status === "paused") {
        reply = "The study session is paused. Resume it when you are ready.";
        return;
      }

      if (rt.pendingSelfAssessment) {
        const grade = classifySelfGrade(answer);
        if (!grade) {
          reply = "Was your answer right, wrong, or should we skip this card?";
          return;
        }

        const outcome = recordResult(draft, grade);
        if (outcome.done) {
          reply = `Session complete. You went over ${outcome.record.cardsSeen} card${outcome.record.cardsSeen === 1 ? "" : "s"}.`;
        } else {
          reply = `${grade === "correct" ? "Marked correct." : grade === "wrong" ? "Marked wrong." : "Skipped."}\n\n${outcome.nextQuestion}`;
        }
        return;
      }

      const userAnswer = normalizeAnswer(answer);
      const expected = normalizeAnswer(card.back);

      if (userAnswer && expected && (userAnswer === expected || userAnswer.includes(expected) || expected.includes(userAnswer))) {
        const outcome = recordResult(draft, "correct");
        if (outcome.done) {
          reply = `Correct. Session complete. You went over ${outcome.record.cardsSeen} card${outcome.record.cardsSeen === 1 ? "" : "s"}.`;
        } else {
          reply = `Correct.\n\n${outcome.nextQuestion}`;
        }
        return;
      }

      rt.pendingSelfAssessment = {
        cardId: card.id,
        userAnswer: String(answer || ""),
        answerShownAt: nowIso()
      };

      reply = `The answer on the card is:\n\n${card.back}\n\nWere you right, wrong, or do you want to skip this card?`;
    });

    return { state: savedState, reply };
  }

  function stats(state) {
    const totalCards = state.cards.length;
    const reviewedCards = state.cards.filter((card) => card.seenCount > 0).length;
    const flaggedCards = state.cards.filter((card) => card.flagged).length;
    const cardsSeen = state.sessions.reduce((sum, session) => sum + Number(session.cardsSeen || 0), 0);
    const totalMs = state.sessions.reduce((sum, session) => sum + Number(session.durationMs || 0), 0);

    return {
      totalDecks: state.decks.length,
      totalCards,
      reviewedCards,
      flaggedCards,
      savedSessions: state.sessions.length,
      cardsSeen,
      totalMs
    };
  }

  function formatDuration(ms) {
    const total = Math.max(0, Math.floor(Number(ms || 0) / 1000));
    const minutes = Math.floor(total / 60);
    const seconds = total % 60;
    if (minutes <= 0) return seconds + "s";
    return minutes + "m " + seconds.toString().padStart(2, "0") + "s";
  }

  async function apiGet(path) {
    const token = localStorage.getItem("edgeStudyToken");
    const response = await fetch(path, {
      method: "GET",
      credentials: "same-origin",
      headers: token ? { Authorization: "Bearer " + token } : {}
    });

    if (!response.ok) {
      throw new Error(path + " failed HTTP " + response.status);
    }

    return await response.json();
  }

  async function syncFromBackend() {
    const current = load();

    const token = localStorage.getItem("edgeStudyToken");
    if (!token) {
      console.warn("[study-store] skipping backend sync because no login token is available yet");
      return current;
    }

    const decksResponse = await apiGet("/api/study/decks");
    const backendDecks = Array.isArray(decksResponse.decks) ? decksResponse.decks : [];

    const decks = backendDecks.map((deck) => ({
      id: String(deck.id),
      title: deck.title || deck.name || "Untitled deck",
      description: deck.description || "",
      createdAt: deck.created_at || deck.createdAt || nowIso(),
      updatedAt: deck.updated_at || deck.updatedAt || nowIso()
    }));

    const cards = [];

    for (const deck of decks) {
      try {
        const cardResponse = await apiGet("/api/study/cards-lite?deck_id=" + encodeURIComponent(deck.id));
        const backendCards = Array.isArray(cardResponse.cards) ? cardResponse.cards : [];

        backendCards.forEach((card) => {
          const backendTags = parseBackendTags(card.tags_json || card.tagsJson || card.tags || []);
          const backendFlagged =
            card.flagged === true ||
            card.flagged === 1 ||
            card.flagged === "true" ||
            backendFlaggedFromTags(backendTags);

          cards.push({
            id: String(card.id),
            deckId: String(card.deck_id || card.deckId || deck.id),
            front: card.front || card.question || "",
            back: card.back || card.answer || "",
            difficulty: card.difficulty || backendDifficultyFromTags(backendTags) || "new",
            flagged: backendFlagged,
            seenCount: Number(card.seenCount || card.seen_count || 0),
            correctCount: Number(card.correctCount || card.correct_count || 0),
            wrongCount: Number(card.wrongCount || card.wrong_count || 0),
            skipCount: Number(card.skipCount || card.skip_count || 0),
            lastResult: card.lastResult || "",
            lastSeenAt: card.lastSeenAt || "",
            createdAt: card.created_at || card.createdAt || nowIso(),
            updatedAt: card.updated_at || card.updatedAt || nowIso(),
            backend: true
          });
        });
      } catch (error) {
        console.warn("[study-store] backend cards sync failed for deck", deck.id, error);
      }
    }

    let progress = null;
    try {
      progress = await apiGet("/api/study/progress");
    } catch (error) {
      console.warn("[study-store] backend progress sync failed", error);
    }

    let reviewSummary = null;
    try {
      reviewSummary = await apiGet("/api/study/review-summary-lite");
    } catch (error) {
      console.warn("[study-store] backend review summary sync failed", error);
    }

    if (reviewSummary && reviewSummary.by_card) {
      cards.forEach((card) => {
        const summary = reviewSummary.by_card[String(card.id)];
        if (!summary) return;

        card.seenCount = Number(summary.seen || 0);
        card.correctCount = Number(summary.correct || 0);
        card.wrongCount = Number(summary.wrong || 0);
        card.skipCount = Number(summary.skipped || 0);
        card.lastResult = summary.last_result || "";
        card.lastSeenAt = summary.last_seen_at || "";
      });
    }

    let backendSessions = null;
    try {
      backendSessions = await apiGet("/api/study/sessions-lite");
    } catch (error) {
      console.warn("[study-store] backend sessions sync failed", error);
    }

    const sessions = backendSessions && Array.isArray(backendSessions.sessions)
      ? backendSessions.sessions.map((session) => {
          const started = session.started_at ? Date.parse(session.started_at) : 0;
          const ended = session.ended_at ? Date.parse(session.ended_at) : 0;
          return {
            id: String(session.id),
            startedAt: session.started_at || "",
            endedAt: session.ended_at || "",
            durationMs: started && ended ? Math.max(0, ended - started) : 0,
            style: "backend",
            deckIds: session.deck_id ? [String(session.deck_id)] : [],
            cardsSeen: Number(session.cards_seen || 0),
            correct: Number(session.correct || 0),
            wrong: Number(session.wrong || 0),
            skipped: Number(session.skipped || 0),
            reason: session.status || "saved",
            backend: true
          };
        })
      : current.sessions;

    const next = {
      ...current,
      decks,
      cards,
      sessions,
      backendProgress: progress,
      backendReviewSummary: reviewSummary,
      backendSessions,
      activeDeckId: decks.some((deck) => deck.id === String(current.activeDeckId))
        ? String(current.activeDeckId)
        : (decks[0] ? decks[0].id : ""),
      backendSyncedAt: nowIso()
    };

    return save(next);
  }


  window.APC_STUDY_STORE = {
    version: VERSION,
    load,
    save,
    stats,
    formatDuration,
    syncFromBackend,
    activeElapsedMs,
    currentCard,
    questionText,
    createDeck: createDeckWithBackend,
    editDeck: editDeckWithBackend,
    deleteDeck: deleteDeckWithBackend,
    setActiveDeck,
    createCard: createCardWithBackend,
    editCard: editCardWithBackend,
    deleteCard: deleteCardWithBackend,
    toggleFlagCard: toggleFlagCardWithBackend,
    startSession: startSessionWithBackend,
    pauseSession,
    resumeSession,
    stopSession: stopSessionWithBackend,
    answerCurrent: answerCurrentWithBackend,
  };

  /* CT203 writeback wrapper block R3 */
  async function apiPost(path, body) {
    const token = localStorage.getItem("edgeStudyToken");
    if (!token) throw new Error("No login token available for backend writeback.");

    const response = await fetch(path, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer " + token
      },
      body: JSON.stringify(body || {})
    });

    if (!response.ok) {
      let detail = "";
      try {
        detail = JSON.stringify(await response.json());
      } catch {
        detail = await response.text().catch(() => "");
      }
      throw new Error(path + " failed HTTP " + response.status + " " + detail);
    }

    return await response.json();
  }

  let backendStartPromise = null;

  function intOrNull(value) {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }

  function rememberBackendSessionId(sessionId) {
    if (!sessionId) return;

    const state = load();
    if (!state.runtime || state.runtime.status === "idle") return;

    state.runtime.backendSessionId = String(sessionId);
    save(state);
  }

  async function backendStartRuntime() {
    const state = load();
    const rt = state.runtime || {};

    if (!rt || rt.status === "idle") return null;
    if (rt.backendSessionId) return String(rt.backendSessionId);
    if (backendStartPromise) return backendStartPromise;

    const card = currentCard(state);
    const deckId =
      (rt.deckIds && rt.deckIds.length ? rt.deckIds[0] : "") ||
      (card ? card.deckId : "") ||
      state.activeDeckId ||
      "";

    if (!card || !deckId) {
      console.warn("[study-store] CT203 start skipped: missing card/deck", { card, deckId, runtime: rt });
      return null;
    }

    console.log("[study-store] CT203 session start writeback", {
      deckId,
      cardId: card.id,
      style: rt.style || "balanced"
    });

    backendStartPromise = apiPost("/api/study/session-writeback-lite", {
      action: "start",
      style: rt.style || "balanced",
      deck_id: intOrNull(deckId),
      current_card_id: intOrNull(card.id),
      queue: Array.isArray(rt.queue) ? rt.queue.map(intOrNull).filter((x) => x !== null) : []
    }).then((data) => {
      console.log("[study-store] CT203 session start complete", data);
      if (data && data.session_id) {
        rememberBackendSessionId(data.session_id);
        return String(data.session_id);
      }
      return null;
    }).catch((error) => {
      console.warn("[study-store] backend session start writeback failed", error);
      return null;
    }).finally(() => {
      backendStartPromise = null;
    });

    return backendStartPromise;
  }

  async function backendRecordReview(card, result) {
    if (!card || !result) return;

    const sessionId = await backendStartRuntime();

    console.log("[study-store] CT203 review writeback", {
      sessionId,
      cardId: card.id,
      deckId: card.deckId,
      result
    });

    const data = await apiPost("/api/study/session-writeback-lite", {
      action: "review",
      session_id: sessionId ? intOrNull(sessionId) : null,
      deck_id: intOrNull(card.deckId),
      card_id: intOrNull(card.id),
      result
    });

    console.log("[study-store] CT203 review writeback complete", data);

    if (data && data.session_id) rememberBackendSessionId(data.session_id);
  }

  async function backendStopSession(sessionId, pendingStart) {
    let resolvedSessionId = sessionId || null;

    if (!resolvedSessionId && pendingStart) {
      try {
        resolvedSessionId = await pendingStart;
      } catch {
        resolvedSessionId = null;
      }
    }

    if (!resolvedSessionId) {
      console.warn("[study-store] CT203 stop skipped: no backend session id");
      return;
    }

    console.log("[study-store] CT203 stop writeback", { sessionId: resolvedSessionId });

    await apiPost("/api/study/session-writeback-lite", {
      action: "stop",
      session_id: intOrNull(resolvedSessionId)
    });

    console.log("[study-store] CT203 stop writeback complete", { sessionId: resolvedSessionId });
  }

  function startSessionWithBackend(style, deckIds) {
    const result = startSession(style, deckIds);

    console.log("[study-store] startSessionWithBackend", { style, deckIds, result });

    if (result && result.ok) {
      backendStartRuntime().catch((error) => {
        console.warn("[study-store] backend start writeback failed", error);
      });
    }

    return result;
  }

  function answerCurrentWithBackend(text) {
    const before = load();
    const beforeCard = currentCard(before);
    const beforeCardSnapshot = beforeCard ? { ...beforeCard } : null;

    const result = answerCurrent(text);

    const after = load();
    const afterCard = beforeCardSnapshot
      ? after.cards.find((card) => String(card.id) === String(beforeCardSnapshot.id))
      : null;

    let outcome = "";

    if (beforeCardSnapshot && afterCard) {
      if (Number(afterCard.correctCount || 0) > Number(beforeCardSnapshot.correctCount || 0)) {
        outcome = "correct";
      } else if (Number(afterCard.wrongCount || 0) > Number(beforeCardSnapshot.wrongCount || 0)) {
        outcome = "wrong";
      } else if (Number(afterCard.skipCount || 0) > Number(beforeCardSnapshot.skipCount || 0)) {
        outcome = "skipped";
      }
    }

    console.log("[study-store] answerCurrentWithBackend", {
      text,
      beforeCard: beforeCardSnapshot,
      afterCard,
      outcome,
      result
    });

    if (outcome) {
      backendRecordReview(beforeCardSnapshot, outcome)
        .then(() => syncFromBackend().catch(() => null))
        .catch((error) => {
          console.warn("[study-store] backend review writeback failed", error);
        });
    } else {
      console.warn("[study-store] no CT203 review outcome detected", {
        beforeCard: beforeCardSnapshot,
        afterCard,
        promptText: text
      });
    }

    return result;
  }

  function stopSessionWithBackend() {
    const before = load();
    const rt = before.runtime || {};
    const sessionId = rt.backendSessionId || null;
    const pendingStart = backendStartPromise;

    const result = stopSession();

    console.log("[study-store] stopSessionWithBackend", { sessionId, result });

    backendStopSession(sessionId, pendingStart)
      .then(() => syncFromBackend().catch(() => null))
      .catch((error) => {
        console.warn("[study-store] backend stop writeback failed", error);
      });

    return result;
  }
  /* end CT203 writeback wrapper block */


  function parseBackendTags(value) {
    if (!value) return [];
    if (Array.isArray(value)) return value.map(String);
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed.map(String) : [];
    } catch {
      return [];
    }
  }

  function backendDifficultyFromTags(tags) {
    const found = (tags || []).find((tag) => String(tag).startsWith("apc:difficulty:"));
    return found ? String(found).split(":").slice(2).join(":") || "new" : "new";
  }

  function backendFlaggedFromTags(tags) {
    return (tags || []).includes("apc:flagged");
  }




  /* CT203 deck/card CRUD writeback block R2 */
  function isBackendId(value) {
    const n = Number(value);
    return Number.isInteger(n) && n > 0;
  }

  function afterBackendMutation(label, promise) {
    promise
      .then((data) => {
        console.log("[study-store] " + label + " saved to CT203", data);
        return syncFromBackend().catch((error) => {
          console.warn("[study-store] " + label + " backend refresh failed", error);
          return null;
        });
      })
      .catch((error) => {
        console.warn("[study-store] " + label + " CT203 save failed", error);
      });
  }

  function createDeckWithBackend(title, description) {
    const result = createDeck(title, description);

    const safeTitle = String(title || "Untitled deck").trim() || "Untitled deck";
    const safeDescription = String(description || "").trim();

    console.log("[study-store] deck create writeback", {
      title: safeTitle,
      description: safeDescription
    });

    afterBackendMutation("deck create", apiPost("/api/study/deck-writeback-lite", {
      action: "create",
      title: safeTitle,
      description: safeDescription
    }));

    return result;
  }

  function editDeckWithBackend(deckId, patch) {
    const result = editDeck(deckId, patch);

    const state = load();
    const deck = (state.decks || []).find((item) => String(item.id) === String(deckId));
    const merged = Object.assign({}, deck || {}, patch || {});

    if (deck && isBackendId(deck.id)) {
      console.log("[study-store] deck update writeback", {
        deckId: deck.id,
        patch: patch || {},
        merged
      });

      afterBackendMutation("deck update", apiPost("/api/study/deck-writeback-lite", {
        action: "update",
        deck_id: Number(deck.id),
        title: merged.title || "Untitled deck",
        description: merged.description || ""
      }));
    } else {
      console.warn("[study-store] deck update skipped: not a backend deck", {
        deckId,
        deck
      });
    }

    return result;
  }

  function deleteDeckWithBackend(deckId) {
    const before = load();
    const deck = (before.decks || []).find((item) => String(item.id) === String(deckId));

    const result = deleteDeck(deckId);

    if (deck && isBackendId(deck.id)) {
      console.log("[study-store] deck delete writeback", { deckId: deck.id });

      afterBackendMutation("deck delete", apiPost("/api/study/deck-writeback-lite", {
        action: "delete",
        deck_id: Number(deck.id)
      }));
    } else {
      console.warn("[study-store] deck delete skipped: not a backend deck", {
        deckId,
        deck
      });
    }

    return result;
  }

  function createCardWithBackend(deckId, front, back, difficulty) {
    const result = createCard(deckId, front, back, difficulty);

    const payload = {
      action: "create",
      deck_id: Number(deckId),
      front: String(front || "").trim(),
      back: String(back || "").trim(),
      difficulty: String(difficulty || "new").trim() || "new",
      flagged: false
    };

    if (isBackendId(deckId) && payload.front && payload.back) {
      console.log("[study-store] card create writeback", payload);

      afterBackendMutation("card create", apiPost("/api/study/card-writeback-lite", payload));
    } else {
      console.warn("[study-store] card create skipped: missing backend deck or card text", {
        deckId,
        payload
      });
    }

    return result;
  }

  function editCardWithBackend(cardId, patch) {
    const result = editCard(cardId, patch);

    const state = load();
    const card = (state.cards || []).find((item) => String(item.id) === String(cardId));
    const merged = Object.assign({}, card || {}, patch || {});

    if (card && isBackendId(card.id) && isBackendId(merged.deckId || merged.deck_id)) {
      const payload = {
        action: "update",
        card_id: Number(card.id),
        deck_id: Number(merged.deckId || merged.deck_id),
        front: String(merged.front || "").trim(),
        back: String(merged.back || "").trim(),
        difficulty: String(merged.difficulty || "new").trim() || "new",
        flagged: Boolean(merged.flagged)
      };

      console.log("[study-store] card update writeback", payload);

      afterBackendMutation("card update", apiPost("/api/study/card-writeback-lite", payload));
    } else {
      console.warn("[study-store] card update skipped: not a backend card", {
        cardId,
        patch,
        card,
        merged
      });
    }

    return result;
  }

  function deleteCardWithBackend(cardId) {
    const before = load();
    const card = (before.cards || []).find((item) => String(item.id) === String(cardId));

    const result = deleteCard(cardId);

    if (card && isBackendId(card.id)) {
      console.log("[study-store] card delete writeback", { cardId: card.id });

      afterBackendMutation("card delete", apiPost("/api/study/card-writeback-lite", {
        action: "delete",
        card_id: Number(card.id)
      }));
    } else {
      console.warn("[study-store] card delete skipped: not a backend card", {
        cardId,
        card
      });
    }

    return result;
  }

  function toggleFlagCardWithBackend(cardId) {
    const result = toggleFlagCard(cardId);

    const state = load();
    const card = (state.cards || []).find((item) => String(item.id) === String(cardId));

    if (card && isBackendId(card.id) && isBackendId(card.deckId)) {
      const payload = {
        action: "update",
        card_id: Number(card.id),
        deck_id: Number(card.deckId),
        front: String(card.front || "").trim(),
        back: String(card.back || "").trim(),
        difficulty: String(card.difficulty || "new").trim() || "new",
        flagged: Boolean(card.flagged)
      };

      console.log("[study-store] card flag writeback", payload);

      afterBackendMutation("card flag", apiPost("/api/study/card-writeback-lite", payload));
    } else {
      console.warn("[study-store] card flag skipped: not a backend card", {
        cardId,
        card
      });
    }

    return result;
  }
  /* end CT203 deck/card CRUD writeback block */


})();
