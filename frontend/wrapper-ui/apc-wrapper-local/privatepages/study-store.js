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

  const APC_STUDY_STORE_CARD_MEDIA_REFS_R16BX = true;

  function normalizeMediaRefR16BX(value) {
    if (!value || typeof value !== "object") return null;
    const sha256 = value.sha256 ? String(value.sha256) : "";
    const url = value.url ? String(value.url) : "";
    const dataUrl = value.dataUrl ? String(value.dataUrl) : "";
    if (!sha256 && !url && !dataUrl) return null;
    return {
      sha256,
      url,
      dataUrl,
      mimeType: value.mimeType ? String(value.mimeType) : "",
      sizeBytes: Number(value.sizeBytes || 0),
      originalName: value.originalName ? String(value.originalName) : "",
      altText: value.altText ? String(value.altText) : "",
      kind: value.kind ? String(value.kind) : "local-media",
      createdAt: value.createdAt || nowIso(),
      updatedAt: value.updatedAt || nowIso()
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
        updatedAt: card.updatedAt || card.updated_at || nowIso(),
        frontImage: normalizeMediaRefR16BX(card.frontImage || card.front_image || card.questionImage || card.question_image || null),
        backImage: normalizeMediaRefR16BX(card.backImage || card.back_image || card.answerImage || card.answer_image || null)
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
    mirrorStateToLocalSave(normalized);
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

  function createCard(deckId, front, back, difficulty, media) {
    return update((state) => {
      const targetDeckId = deckId || state.activeDeckId || (state.decks[0] && state.decks[0].id);
      if (!targetDeckId) return;

      const mediaRefs = media && typeof media === "object" ? media : {};

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
        updatedAt: nowIso(),
        frontImage: normalizeMediaRefR16BX(mediaRefs.frontImage || mediaRefs.questionImage || null),
        backImage: normalizeMediaRefR16BX(mediaRefs.backImage || mediaRefs.answerImage || null)
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
      if ("frontImage" in patch) card.frontImage = normalizeMediaRefR16BX(patch.frontImage);
      if ("backImage" in patch) card.backImage = normalizeMediaRefR16BX(patch.backImage);
      if ("questionImage" in patch) card.frontImage = normalizeMediaRefR16BX(patch.questionImage);
      if ("answerImage" in patch) card.backImage = normalizeMediaRefR16BX(patch.answerImage);
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
    recordLocalReviewEvent(card, result, rt);

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


  const LOCAL_SAVE_STORE_STATE_KEY = "study/store-state/v1";
  const LOCAL_SAVE_DECKS_KEY = "study/decks/v1";
  const LOCAL_SAVE_CARDS_KEY = "study/cards/v1";
  const LOCAL_SAVE_SESSIONS_KEY = "study/sessions/v1";
  const LOCAL_SAVE_PROGRESS_KEY = "study/progress/v1";

  let localSaveMirrorTimer = null;
  let pendingLocalSaveState = null;

  function getStudyLocalSave() {
    return window.APC_LOCAL_SAVE && typeof window.APC_LOCAL_SAVE.setDoc === "function"
      ? window.APC_LOCAL_SAVE
      : null;
  }

  function buildProgressDoc(state) {
    const summary = stats(state);
    const byDeck = {};
    const bySessionType = {};

    (state.decks || []).forEach((deck) => {
      const deckCards = (state.cards || []).filter((card) => String(card.deckId) === String(deck.id));
      byDeck[deck.id] = {
        deckId: deck.id,
        title: deck.title || "Untitled deck",
        totalCards: deckCards.length,
        reviewedCards: deckCards.filter((card) => Number(card.seenCount || 0) > 0).length,
        flaggedCards: deckCards.filter((card) => Boolean(card.flagged)).length,
        correctCount: deckCards.reduce((sum, card) => sum + Number(card.correctCount || 0), 0),
        wrongCount: deckCards.reduce((sum, card) => sum + Number(card.wrongCount || 0), 0),
        skipCount: deckCards.reduce((sum, card) => sum + Number(card.skipCount || 0), 0),
        updatedAt: nowIso()
      };
    });

    (state.sessions || []).forEach((session) => {
      const type = session.style || "standard";
      if (!bySessionType[type]) {
        bySessionType[type] = {
          sessionType: type,
          sessions: 0,
          cardsSeen: 0,
          correct: 0,
          wrong: 0,
          skipped: 0,
          totalMs: 0
        };
      }

      bySessionType[type].sessions += 1;
      bySessionType[type].cardsSeen += Number(session.cardsSeen || 0);
      bySessionType[type].correct += Number(session.correct || 0);
      bySessionType[type].wrong += Number(session.wrong || 0);
      bySessionType[type].skipped += Number(session.skipped || 0);
      bySessionType[type].totalMs += Number(session.durationMs || 0);
    });

    return {
      schemaVersion: 1,
      updatedAt: nowIso(),
      totals: summary,
      byDeck,
      bySessionType
    };
  }

  async function flushLocalSaveMirror() {
    const store = getStudyLocalSave();
    const state = pendingLocalSaveState ? normalize(pendingLocalSaveState) : null;

    pendingLocalSaveState = null;
    localSaveMirrorTimer = null;

    if (!store || !state) return state || load();

    try {
      if (typeof store.ensureManifest === "function") {
        await store.ensureManifest();
      }

      const updatedAt = nowIso();
      const progress = buildProgressDoc(state);

      await Promise.all([
        store.setDoc(LOCAL_SAVE_STORE_STATE_KEY, {
          schemaVersion: 1,
          updatedAt,
          state
        }, {
          namespace: "study",
          recordType: "apc_study_store_state"
        }),

        store.setDoc(LOCAL_SAVE_DECKS_KEY, {
          schemaVersion: 1,
          updatedAt,
          decks: state.decks || []
        }, {
          namespace: "study",
          recordType: "apc_study_decks"
        }),

        store.setDoc(LOCAL_SAVE_CARDS_KEY, {
          schemaVersion: 1,
          updatedAt,
          cards: state.cards || []
        }, {
          namespace: "study",
          recordType: "apc_study_cards"
        }),

        store.setDoc(LOCAL_SAVE_SESSIONS_KEY, {
          schemaVersion: 1,
          updatedAt,
          activeSession: state.runtime || null,
          recentSessions: state.sessions || []
        }, {
          namespace: "study",
          recordType: "apc_study_sessions"
        }),

        store.setDoc(LOCAL_SAVE_PROGRESS_KEY, progress, {
          namespace: "study",
          recordType: "apc_study_progress"
        })
      ]);

      try {
        document.dispatchEvent(new CustomEvent("apc-study-local-save-updated", {
          detail: {
            version: VERSION,
            updatedAt,
            deckCount: (state.decks || []).length,
            cardCount: (state.cards || []).length,
            sessionCount: (state.sessions || []).length
          }
        }));
      } catch (_) {}

      return state;
    } catch (error) {
      console.warn("[study-store] APC_LOCAL_SAVE mirror failed", error);
      return state;
    }
  }

  function mirrorStateToLocalSave(state) {
    pendingLocalSaveState = normalize(state);

    if (localSaveMirrorTimer) return;

    localSaveMirrorTimer = window.setTimeout(() => {
      flushLocalSaveMirror().catch((error) => {
        console.warn("[study-store] local save mirror flush failed", error);
      });
    }, 150);
  }

  function applyLocalSaveState(state) {
    const normalized = normalize(state);
    localStorage.setItem(key(), JSON.stringify(normalized));

    try {
      document.dispatchEvent(new CustomEvent("apc-study-local-save-hydrated", {
        detail: {
          version: VERSION,
          deckCount: normalized.decks.length,
          cardCount: normalized.cards.length,
          sessionCount: normalized.sessions.length
        }
      }));
    } catch (_) {}

    return normalized;
  }

  async function syncFromLocalSave() {
    const current = load();
    const store = getStudyLocalSave();

    if (!store) {
      return current;
    }

    try {
      if (typeof store.ensureManifest === "function") {
        await store.ensureManifest();
      }

      const [storeStateDoc, decksDoc, cardsDoc, sessionsDoc] = await Promise.all([
        store.getDoc(LOCAL_SAVE_STORE_STATE_KEY, null),
        store.getDoc(LOCAL_SAVE_DECKS_KEY, null),
        store.getDoc(LOCAL_SAVE_CARDS_KEY, null),
        store.getDoc(LOCAL_SAVE_SESSIONS_KEY, null)
      ]);

      const storeState = storeStateDoc && storeStateDoc.state ? storeStateDoc.state : null;

      const hasSplitDocs =
        decksDoc && Array.isArray(decksDoc.decks) &&
        cardsDoc && Array.isArray(cardsDoc.cards);

      const hasAnyCurrentData =
        (current.decks && current.decks.length) ||
        (current.cards && current.cards.length) ||
        (current.sessions && current.sessions.length) ||
        current.runtime;

      if (storeState) {
        return applyLocalSaveState(storeState);
      }

      if (hasSplitDocs) {
        return applyLocalSaveState({
          ...current,
          decks: decksDoc.decks || [],
          cards: cardsDoc.cards || [],
          sessions: sessionsDoc && Array.isArray(sessionsDoc.recentSessions) ? sessionsDoc.recentSessions : current.sessions,
          runtime: sessionsDoc && sessionsDoc.activeSession ? sessionsDoc.activeSession : current.runtime
        });
      }

      if (hasAnyCurrentData) {
        mirrorStateToLocalSave(current);
      }

      return current;
    } catch (error) {
      console.warn("[study-store] local save sync failed", error);
      return current;
    }
  }

  function recordLocalReviewEvent(card, result, runtime) {
    const store = getStudyLocalSave();
    if (!store || typeof store.recordCardReview !== "function") return;

    const wasSkipped = result === "skipped";
    const wasCorrect = result === "correct";
    const grade = result === "correct" ? "good" : result === "wrong" ? "again" : "hard";

    store.recordCardReview({
      deckId: card.deckId || (runtime && runtime.deckIds && runtime.deckIds[0]) || "unknown",
      cardId: card.id,
      sessionId: runtime && runtime.id ? runtime.id : null,
      wasCorrect,
      wasSkipped,
      answerMs: 0,
      sessionType: runtime && runtime.style ? runtime.style : "standard",
      grade
    }).catch((error) => {
      console.warn("[study-store] local review event failed", error);
    });
  }

  async function syncFromBackend() {
    return syncFromLocalSave();
  }


  window.APC_STUDY_STORE = {
    version: VERSION,
    mode: "browser-local-only",
    load,
    save,
    stats,
    formatDuration,
    syncFromBackend,
    syncFromLocalSave,
    flushLocalSaveMirror,
    activeElapsedMs,
    currentCard,
    questionText,
    createDeck,
    editDeck,
    deleteDeck,
    setActiveDeck,
    createCard,
    editCard,
    deleteCard,
    toggleFlagCard,
    startSession,
    pauseSession,
    resumeSession,
    stopSession,
    answerCurrent
  };



  syncFromLocalSave().catch((error) => {
    console.warn("[study-store] startup local save hydration failed", error);
  });


})();
