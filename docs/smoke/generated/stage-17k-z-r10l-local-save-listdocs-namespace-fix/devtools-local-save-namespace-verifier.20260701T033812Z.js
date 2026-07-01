/*
R10L verifier: confirms APC_LOCAL_SAVE.listDocs({ namespace: "study" })
returns the study docs that exportAll() already exposes.

Use after signing in, opening Study, and refreshing once:
  await window.__APC_R10L_VERIFY_LISTDOCS_NAMESPACE__()
*/

(() => {
  window.__APC_R10L_VERIFY_LISTDOCS_NAMESPACE__ = async () => {
    const studyStore = window.APC_STUDY_STORE;
    const localSave = window.APC_LOCAL_SAVE;

    if (!studyStore || !localSave) {
      const missing = {
        pass: false,
        error: "Missing APC_STUDY_STORE or APC_LOCAL_SAVE",
        studyStoreAvailable: Boolean(studyStore),
        localSaveAvailable: Boolean(localSave)
      };
      console.error("[R10L]", missing);
      return missing;
    }

    if (typeof studyStore.flushLocalSaveMirror === "function") {
      await studyStore.flushLocalSaveMirror();
    }

    await new Promise((resolve) => setTimeout(resolve, 500));

    const state = typeof studyStore.load === "function" ? studyStore.load() : null;
    const docs = typeof localSave.listDocs === "function"
      ? await localSave.listDocs({ namespace: "study" })
      : [];

    const keys = Array.isArray(docs)
      ? docs.map((doc) => doc.key || doc.id || doc.name || doc.record?.key || doc.record?.id).filter(Boolean)
      : [];

    const expectedKeys = [
      "study/cards/v1",
      "study/decks/v1",
      "study/progress/v1",
      "study/sessions/v1",
      "study/store-state/v1"
    ];

    const report = {
      checkedAt: new Date().toISOString(),
      studyStoreAvailable: Boolean(studyStore),
      studyStoreMode: studyStore && studyStore.mode || null,
      localSaveAvailable: Boolean(localSave),
      patchMarker: Boolean(localSave && localSave.APC_LOCAL_SAVE_LISTDOCS_NAMESPACE_PREFIX_R10L),
      deckCount: state && Array.isArray(state.decks) ? state.decks.length : null,
      cardCount: state && Array.isArray(state.cards) ? state.cards.length : null,
      docsByNamespaceCount: Array.isArray(docs) ? docs.length : null,
      docsByNamespaceKeys: keys,
      expectedKeysPresent: expectedKeys.filter((key) => keys.includes(key)),
      pass: (
        Boolean(studyStore) &&
        studyStore.mode === "browser-local-only" &&
        Boolean(localSave) &&
        Array.isArray(docs) &&
        docs.length >= 5 &&
        expectedKeys.every((key) => keys.includes(key))
      )
    };

    console.table({
      studyStoreMode: report.studyStoreMode,
      localSaveAvailable: report.localSaveAvailable,
      patchMarker: report.patchMarker,
      deckCount: report.deckCount,
      cardCount: report.cardCount,
      docsByNamespaceCount: report.docsByNamespaceCount,
      expectedKeysPresent: report.expectedKeysPresent.length,
      pass: report.pass
    });

    console.log("[R10L listDocs namespace report]", report);
    return report;
  };

  console.log("[R10L] Verifier installed. Run:");
  console.log("await window.__APC_R10L_VERIFY_LISTDOCS_NAMESPACE__()");
})();
