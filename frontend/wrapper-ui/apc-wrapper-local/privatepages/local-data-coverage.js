(function apcLocalDataCoverageR16BX(root) {
  "use strict";

  const MARKER = "APC_LOCAL_DATA_COVERAGE_R16BX_FULL_LOCAL_BACKUP";
  const VERSION = 1;
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const MEDIA_BLOB_KEY = "local/media-blobs/v1";
  const MEDIA_MANIFEST_KEY = "local/media-manifest/v1";
  const LOCAL_STORAGE_KEY = "local/local-storage/v1";
  const COMPANION_SETTINGS_KEY = "companion/preferences/v1";
  const PROFILE_SETTINGS_KEY = "profile/preferences/v1";
  const ANKI_POLICY_KEY = "anki/read-only-policy/v1";

  if (root.APC_LOCAL_DATA_COVERAGE_R16BX) return;

  function nowIso() { return new Date().toISOString(); }
  function isObject(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
  function cloneJson(value) { return value === undefined ? undefined : JSON.parse(JSON.stringify(value)); }

  function currentUserEmail() {
    try {
      const user = root.APC_PRIVATEPAGES && root.APC_PRIVATEPAGES.me ? root.APC_PRIVATEPAGES.me() : null;
      if (user && user.email) return user.email;
    } catch (_) {}
    return "browser-local@buddies.local";
  }

  function readJsonLocalStorage(key, fallback) {
    try {
      const parsed = JSON.parse(root.localStorage.getItem(key) || "null");
      return parsed && typeof parsed === "object" ? parsed : fallback;
    } catch (_) {
      return fallback;
    }
  }

  function localStorageSnapshot() {
    const prefixes = [
      "apcPrivateStudyState:",
      "apcLocalProfileSettings:",
      "apcPrivateCompanionVoiceSettings:",
      "apcPrivateCompanionMessages:",
      "apcLastKnownSignedInEmail",
      "apcStudy",
      "buddies"
    ];
    const items = [];
    try {
      for (let i = 0; i < root.localStorage.length; i += 1) {
        const key = root.localStorage.key(i);
        if (!key) continue;
        if (!prefixes.some((prefix) => String(key).startsWith(prefix))) continue;
        items.push({ key, value: root.localStorage.getItem(key) || "" });
      }
    } catch (_) {}
    return items.sort((a, b) => String(a.key).localeCompare(String(b.key)));
  }

  function ensureDocs(payload) {
    const next = isObject(payload) ? cloneJson(payload) : {};
    next.kind = next.kind || BACKUP_KIND;
    next.version = Math.max(Number(next.version || 1), 3);
    next.createdAt = next.createdAt || nowIso();
    next.app = next.app || "Buddies Who Study";
    next.label = next.label || "Buddies Who Study complete local data";
    next.privacy = Object.assign({}, next.privacy || {}, {
      serverUpload: false,
      uploadsToServer: false,
      localOnly: true,
      ankiSourceMutation: false,
      modifiesAnkiSourceFiles: false,
      sourceMutation: false,
      includesAnkiSourceFileBytes: false,
      originalAnkiBytesIncluded: false,
      googleDriveSyncEnabled: false
    });
    if (!isObject(next.docs)) next.docs = {};
    return next;
  }

  async function blobToDataUrl(blob) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result || ""));
      reader.onerror = () => reject(reader.error || new Error("Unable to read media blob."));
      reader.readAsDataURL(blob);
    });
  }

  function progressFromStudyState(state) {
    const cards = Array.isArray(state && state.cards) ? state.cards : [];
    const decks = Array.isArray(state && state.decks) ? state.decks : [];
    return {
      schemaVersion: 1,
      updatedAt: nowIso(),
      totals: {
        totalDecks: decks.length,
        totalCards: cards.length,
        reviewedCards: cards.filter((card) => Number(card.seenCount || 0) > 0).length,
        correct: cards.reduce((sum, card) => sum + Number(card.correctCount || 0), 0),
        wrong: cards.reduce((sum, card) => sum + Number(card.wrongCount || 0), 0),
        skipped: cards.reduce((sum, card) => sum + Number(card.skipCount || 0), 0)
      }
    };
  }

  async function mirrorStudyStore(docs) {
    const store = root.APC_STUDY_STORE;
    if (!store || typeof store.load !== "function") return null;

    try {
      if (typeof store.flushLocalSaveMirror === "function") {
        await store.flushLocalSaveMirror();
      }
    } catch (error) {
      console.warn("[local-data-coverage] Study mirror flush failed", error);
    }

    const state = store.load();
    if (!state || !isObject(state)) return null;

    docs["study/store-state/v1"] = { schemaVersion: 1, updatedAt: nowIso(), state: cloneJson(state) };
    docs["study/decks/v1"] = { schemaVersion: 1, updatedAt: nowIso(), decks: cloneJson(state.decks || []) };
    docs["study/cards/v1"] = { schemaVersion: 1, updatedAt: nowIso(), cards: cloneJson(state.cards || []) };
    docs["study/sessions/v1"] = { schemaVersion: 1, updatedAt: nowIso(), activeSession: cloneJson(state.runtime || null), recentSessions: cloneJson(state.sessions || []) };
    docs["study/progress/v1"] = progressFromStudyState(state);
    return state;
  }

  async function mergeLocalSave(docs, payload) {
    const api = root.APC_LOCAL_SAVE;
    if (!api) return { media: [], events: [] };

    if (typeof api.ensureManifest === "function") {
      try { await api.ensureManifest(); } catch (_) {}
    }

    if (typeof api.listDocs === "function") {
      try {
        const listed = await api.listDocs();
        if (Array.isArray(listed)) {
          listed.forEach((record) => {
            if (!record || !record.key) return;
            docs[String(record.key)] = record.value === undefined ? null : cloneJson(record.value);
          });
        }
      } catch (error) {
        console.warn("[local-data-coverage] listDocs failed", error);
      }
    }

    let events = [];
    if (typeof api.listEvents === "function") {
      try { events = await api.listEvents({ limit: 5000 }); } catch (_) { events = []; }
      docs["study/events/v1"] = {
        schemaVersion: 1,
        updatedAt: nowIso(),
        events: cloneJson(events || [])
      };
    }

    let media = [];
    if (typeof api.listMedia === "function") {
      try { media = await api.listMedia(); } catch (_) { media = []; }
    }

    const blobs = [];
    if (media.length && typeof api.getMediaBlob === "function") {
      for (const item of media) {
        try {
          const blob = await api.getMediaBlob(item.sha256);
          if (!blob) continue;
          blobs.push(Object.assign({}, cloneJson(item), {
            dataUrl: await blobToDataUrl(blob),
            backedUpAt: nowIso()
          }));
        } catch (error) {
          blobs.push(Object.assign({}, cloneJson(item), {
            backupError: String(error && error.message ? error.message : error)
          }));
        }
      }
    }

    docs[MEDIA_MANIFEST_KEY] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      mediaCount: media.length,
      totalBytes: media.reduce((sum, item) => sum + Number(item.sizeBytes || 0), 0),
      items: cloneJson(media)
    };
    docs[MEDIA_BLOB_KEY] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      blobCount: blobs.length,
      blobs
    };

    payload.media = Object.assign({}, payload.media || {}, {
      manifestKey: MEDIA_MANIFEST_KEY,
      blobsKey: MEDIA_BLOB_KEY,
      count: media.length,
      totalBytes: media.reduce((sum, item) => sum + Number(item.sizeBytes || 0), 0),
      includesLocalBlobDataUrls: true
    });

    return { media, events };
  }

  function mirrorProfileAndCompanionSettings(docs) {
    const email = currentUserEmail();
    const profile = readJsonLocalStorage("apcLocalProfileSettings:" + email, {});
    const companion = readJsonLocalStorage("apcPrivateCompanionVoiceSettings:" + email, {});
    const messages = readJsonLocalStorage("apcPrivateCompanionMessages:" + email, []);

    docs[PROFILE_SETTINGS_KEY] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      emailScope: email,
      settings: cloneJson(profile || {})
    };

    docs[COMPANION_SETTINGS_KEY] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      emailScope: email,
      settings: cloneJson(companion || {}),
      messages: Array.isArray(messages) ? cloneJson(messages.slice(-50)) : []
    };

    docs[LOCAL_STORAGE_KEY] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      items: localStorageSnapshot()
    };
  }

  function ensureAnkiPolicy(docs) {
    docs[ANKI_POLICY_KEY] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      mode: "read-only-source-progress-local-only",
      readsAnkiCardsAndDecks: true,
      writesAnkiFiles: false,
      mutatesAnkiCards: false,
      mutatesAnkiDecks: false,
      storesBuddiesProgressOnly: true,
      originalAnkiBytesIncluded: false
    };
  }

  async function augmentBackupPayload(payload, options) {
    const next = ensureDocs(payload);
    const docs = next.docs;
    const state = await mirrorStudyStore(docs);
    const localSave = await mergeLocalSave(docs, next);
    mirrorProfileAndCompanionSettings(docs);
    ensureAnkiPolicy(docs);

    const cards = state && Array.isArray(state.cards) ? state.cards : [];
    const decks = state && Array.isArray(state.decks) ? state.decks : [];
    const sessions = state && Array.isArray(state.sessions) ? state.sessions : [];
    const cardImageRefs = cards.flatMap((card) => [card.frontImage, card.backImage]).filter(Boolean);
    const companion = docs[COMPANION_SETTINGS_KEY] && docs[COMPANION_SETTINGS_KEY].settings ? docs[COMPANION_SETTINGS_KEY].settings : {};
    const companionRefs = [companion.listeningMediaRef, companion.thinkingMediaRef, companion.talkingMediaRef].filter(Boolean);

    next.backupDocs = Object.keys(docs).sort();
    next.coverage = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      includesStudyDecks: true,
      includesStudyCards: true,
      includesStudyStats: true,
      includesStudySessions: true,
      includesCardImages: true,
      includesCompanionSettings: true,
      includesCompanionClips: true,
      includesLocalMediaBlobs: true,
      includesAnkiProgressPolicy: true,
      deckCount: decks.length,
      cardCount: cards.length,
      sessionCount: sessions.length,
      cardImageRefCount: cardImageRefs.length,
      companionMediaRefCount: companionRefs.length,
      localMediaCount: localSave.media.length,
      localEventCount: localSave.events.length,
      note: "This backup contains Buddies Who Study local data only. It does not contain private server data and does not mutate Anki source files."
    };

    return next;
  }

  function wrapProfileBackupPanel() {
    const panel = root.APC_PROFILE_LOCAL_BACKUPS_PANEL;
    if (!panel || panel.__apcLocalDataCoverageR16BX) return false;
    if (typeof panel.buildBackupPayload !== "function") return false;

    const baseBuild = panel.buildBackupPayload.bind(panel);
    const baseWrite = typeof panel.writeBackupToDirectoryHandle === "function"
      ? panel.writeBackupToDirectoryHandle.bind(panel)
      : null;

    async function buildBackupPayload(options) {
      const payload = await baseBuild(options || {});
      return augmentBackupPayload(payload, options || {});
    }

    async function chooseFolderAndWriteBackup(options) {
      if (typeof root.showDirectoryPicker !== "function") {
        throw new Error("Folder picker is not supported in this browser. Use download backup instead.");
      }
      if (!baseWrite) {
        throw new Error("Backup file writer is not available.");
      }
      const payload = await buildBackupPayload(options || {});
      const directoryHandle = await root.showDirectoryPicker({
        id: "buddies-who-study-local-backups",
        mode: "readwrite"
      });
      return baseWrite(directoryHandle, payload);
    }

    const wrapped = Object.freeze(Object.assign({}, panel, {
      __apcLocalDataCoverageR16BX: true,
      marker: String(panel.marker || "") + "+" + MARKER,
      buildBackupPayload,
      chooseFolderAndWriteBackup
    }));

    root.APC_PROFILE_LOCAL_BACKUPS_PANEL = wrapped;
    return true;
  }

  function scheduleWrap() {
    wrapProfileBackupPanel();
    root.setTimeout(wrapProfileBackupPanel, 0);
    root.setTimeout(wrapProfileBackupPanel, 150);
    root.setTimeout(wrapProfileBackupPanel, 500);
  }

  root.APC_LOCAL_DATA_COVERAGE_R16BX = Object.freeze({
    marker: MARKER,
    version: VERSION,
    augmentBackupPayload,
    wrapProfileBackupPanel,
    scheduleWrap
  });

  document.addEventListener("apc-private-page-rendered", scheduleWrap);
  document.addEventListener("apc-study-local-save-updated", scheduleWrap);
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", scheduleWrap, { once: true });
  } else {
    scheduleWrap();
  }
})(typeof window !== "undefined" ? window : globalThis);
