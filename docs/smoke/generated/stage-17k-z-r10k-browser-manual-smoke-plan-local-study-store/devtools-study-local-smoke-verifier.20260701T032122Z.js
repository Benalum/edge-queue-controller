/*
Buddies Who Study R10K local study smoke verifier.

Use:
1. Sign in normally.
2. Open Study.
3. Open DevTools Console.
4. Paste this entire snippet and press Enter.
5. Create/edit/delete a test deck/card in the UI.
6. Refresh the page.
7. Run window.__APC_R10K_REPORT__() in the Console.

Pass conditions:
- privateStudyFetchCount stays 0
- localSaveAvailable is true
- studyStoreMode is "browser-local-only"
- IndexedDB docs include study keys after using Study
*/

(() => {
  const previousFetch = window.fetch ? window.fetch.bind(window) : null;
  const privateStudyCalls = [];

  if (!window.__APC_R10K_FETCH_PATCHED__ && previousFetch) {
    window.fetch = async (...args) => {
      const url = String(args[0] && args[0].url ? args[0].url : args[0]);
      if (
        url.includes("/api/study/decks") ||
        url.includes("/api/study/cards-lite") ||
        url.includes("/api/study/progress") ||
        url.includes("/api/study/review-summary-lite") ||
        url.includes("/api/study/sessions-lite") ||
        url.includes("/api/study/session-writeback-lite") ||
        url.includes("/api/study/deck-writeback-lite") ||
        url.includes("/api/study/card-writeback-lite") ||
        url.includes("/public/study/decks") ||
        url.includes("/public/study/progress")
      ) {
        privateStudyCalls.push({
          at: new Date().toISOString(),
          url
        });
        console.error("[R10K] Private study server persistence call detected:", url);
      }
      return previousFetch(...args);
    };
    window.__APC_R10K_FETCH_PATCHED__ = true;
  }

  async function collectLocalSaveDebug() {
    const localSave = window.APC_LOCAL_SAVE;
    if (!localSave) return { available: false };

    const result = {
      available: true,
      hasSetDoc: typeof localSave.setDoc === "function",
      hasGetDoc: typeof localSave.getDoc === "function",
      hasListDocs: typeof localSave.listDocs === "function",
      hasRecordCardReview: typeof localSave.recordCardReview === "function"
    };

    try {
      if (typeof localSave.ensureManifest === "function") {
        await localSave.ensureManifest();
      }
      if (typeof localSave.listDocs === "function") {
        const docs = await localSave.listDocs({ namespace: "study" });
        result.studyDocCount = Array.isArray(docs) ? docs.length : null;
        result.studyDocKeys = Array.isArray(docs) ? docs.map((doc) => doc.key || doc.id || doc.name).filter(Boolean).slice(0, 50) : [];
      }
      if (typeof localSave.debug === "function") {
        result.debug = await localSave.debug();
      }
    } catch (error) {
      result.error = String(error && error.message ? error.message : error);
    }

    return result;
  }

  window.__APC_R10K_REPORT__ = async () => {
    const studyStore = window.APC_STUDY_STORE;
    const state = studyStore && typeof studyStore.load === "function" ? studyStore.load() : null;
    const localSave = await collectLocalSaveDebug();

    const report = {
      checkedAt: new Date().toISOString(),
      location: location.href,
      privateStudyFetchCount: privateStudyCalls.length,
      privateStudyCalls: privateStudyCalls.slice(),
      studyStoreAvailable: Boolean(studyStore),
      studyStoreMode: studyStore && studyStore.mode || null,
      localSaveAvailable: Boolean(window.APC_LOCAL_SAVE),
      localSave,
      stateSummary: state ? {
        deckCount: Array.isArray(state.decks) ? state.decks.length : null,
        cardCount: Array.isArray(state.cards) ? state.cards.length : null,
        sessionCount: Array.isArray(state.sessions) ? state.sessions.length : null,
        activeDeckId: state.activeDeckId || null,
        runtimeActive: Boolean(state.runtime)
      } : null,
      pass: (
        privateStudyCalls.length === 0 &&
        Boolean(studyStore) &&
        studyStore.mode === "browser-local-only" &&
        Boolean(window.APC_LOCAL_SAVE)
      )
    };

    console.table({
      privateStudyFetchCount: report.privateStudyFetchCount,
      studyStoreAvailable: report.studyStoreAvailable,
      studyStoreMode: report.studyStoreMode,
      localSaveAvailable: report.localSaveAvailable,
      deckCount: report.stateSummary && report.stateSummary.deckCount,
      cardCount: report.stateSummary && report.stateSummary.cardCount,
      pass: report.pass
    });

    console.log("[R10K] Full report:", report);
    return report;
  };

  console.log("[R10K] Fetch monitor installed. Use Study normally, refresh, then run:");
  console.log("await window.__APC_R10K_REPORT__()");
})();
