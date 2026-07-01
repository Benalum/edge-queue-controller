/*
R10L-R3A runtime diagnostic.

Use on the signed-in Study page after Ctrl+Shift+R:
  paste this snippet
  await window.__APC_R10L_R3A_DIAGNOSE_LOCAL_SAVE__()
*/

(() => {
  window.__APC_R10L_R3A_DIAGNOSE_LOCAL_SAVE__ = async () => {
    const api = window.APC_LOCAL_SAVE;
    const studyStore = window.APC_STUDY_STORE;

    const descriptor = Object.getOwnPropertyDescriptor(window, "APC_LOCAL_SAVE");
    const resources = performance.getEntriesByType("resource")
      .filter((entry) => String(entry.name).includes("local-save-store.js"))
      .map((entry) => entry.name);

    let listDocsResult = null;
    let listDocsError = null;
    let exportAllShape = null;
    let exportStudyKeys = [];
    let directPatchWorks = false;
    let directPatchError = null;

    try {
      if (studyStore?.flushLocalSaveMirror) {
        await studyStore.flushLocalSaveMirror();
      }
      await new Promise((resolve) => setTimeout(resolve, 800));
    } catch (error) {
      console.warn("[R10L-R3A] flush failed", error);
    }

    try {
      const docs = await api.listDocs({ namespace: "study" });
      listDocsResult = {
        isArray: Array.isArray(docs),
        count: Array.isArray(docs) ? docs.length : null,
        sample: Array.isArray(docs) ? docs.slice(0, 3) : docs
      };
    } catch (error) {
      listDocsError = String(error && error.message ? error.message : error);
    }

    try {
      const payload = await api.exportAll();
      exportAllShape = {
        type: Object.prototype.toString.call(payload),
        keys: payload && typeof payload === "object" ? Object.keys(payload) : [],
        docsIsArray: Boolean(payload && Array.isArray(payload.docs)),
        docsCount: payload && Array.isArray(payload.docs) ? payload.docs.length : null,
        sample: payload && Array.isArray(payload.docs) ? payload.docs.slice(0, 3) : payload
      };

      exportStudyKeys = payload && Array.isArray(payload.docs)
        ? payload.docs
            .map((doc) => doc.key || doc.id || doc.name || doc.path || doc.record?.key || doc.record?.id || doc.meta?.key)
            .filter((key) => String(key || "").startsWith("study/"))
        : [];
    } catch (error) {
      exportAllShape = { error: String(error && error.message ? error.message : error) };
    }

    try {
      if (api && typeof api.listDocs === "function" && typeof api.exportAll === "function") {
        const original = api.listDocs.bind(api);
        api.__r10lr3aDirectPatchTest = true;
        api.listDocs = async function patchedForDiagnostic(options = {}) {
          const namespace = options && options.namespace;
          const originalDocs = await original(options).catch(() => []);
          if (namespace !== "study" || (Array.isArray(originalDocs) && originalDocs.length > 0)) {
            return originalDocs;
          }
          const exported = await api.exportAll();
          return (exported.docs || []).filter((doc) => String(doc.key || doc.id || "").startsWith("study/"));
        };

        const patchedDocs = await api.listDocs({ namespace: "study" });
        directPatchWorks = Array.isArray(patchedDocs) && patchedDocs.length >= 5;
      }
    } catch (error) {
      directPatchError = String(error && error.message ? error.message : error);
    }

    const state = studyStore?.load?.();

    const report = {
      checkedAt: new Date().toISOString(),
      location: location.href,
      resources,
      globalPatchMarkerR10LR2: Boolean(window.APC_LOCAL_SAVE_LISTDOCS_NAMESPACE_PREFIX_R10L_R2),
      apiPatchMarkerR10LR2: Boolean(api?.APC_LOCAL_SAVE_LISTDOCS_NAMESPACE_PREFIX_R10L_R2),
      apiExists: Boolean(api),
      apiExtensible: api ? Object.isExtensible(api) : null,
      apiFrozen: api ? Object.isFrozen(api) : null,
      apiSealed: api ? Object.isSealed(api) : null,
      apiKeys: api ? Object.keys(api).sort() : [],
      descriptor: descriptor ? {
        configurable: descriptor.configurable,
        enumerable: descriptor.enumerable,
        hasGetter: typeof descriptor.get === "function",
        hasSetter: typeof descriptor.set === "function",
        writable: descriptor.writable
      } : null,
      listDocsType: typeof api?.listDocs,
      exportAllType: typeof api?.exportAll,
      listDocsSourceStart: String(api?.listDocs || "").slice(0, 500),
      listDocsResult,
      listDocsError,
      exportAllShape,
      exportStudyKeys,
      directPatchWorks,
      directPatchError,
      stateSummary: state ? {
        deckCount: Array.isArray(state.decks) ? state.decks.length : null,
        cardCount: Array.isArray(state.cards) ? state.cards.length : null,
        sessionCount: Array.isArray(state.sessions) ? state.sessions.length : null
      } : null
    };

    console.table({
      globalPatchMarkerR10LR2: report.globalPatchMarkerR10LR2,
      apiPatchMarkerR10LR2: report.apiPatchMarkerR10LR2,
      apiExtensible: report.apiExtensible,
      listDocsCount: report.listDocsResult && report.listDocsResult.count,
      exportStudyKeys: report.exportStudyKeys.length,
      directPatchWorks: report.directPatchWorks,
      deckCount: report.stateSummary && report.stateSummary.deckCount,
      cardCount: report.stateSummary && report.stateSummary.cardCount
    });

    console.log("[R10L-R3A local-save runtime diagnostic]", report);
    return report;
  };

  console.log("[R10L-R3A] Diagnostic installed. Run:");
  console.log("await window.__APC_R10L_R3A_DIAGNOSE_LOCAL_SAVE__()");
})();
