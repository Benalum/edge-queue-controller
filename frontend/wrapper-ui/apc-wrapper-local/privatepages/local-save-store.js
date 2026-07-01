/* Stage 17K-Z-R10B: Browser local save store.
 *
 * Purpose:
 * - Keep private user study/profile/deck/card data browser-local first.
 * - Avoid server persistence for private decks/cards/progress.
 * - Provide one stable local document/media/event API that can later sync to
 *   Google Drive appDataFolder.
 *
 * Storage model:
 * - docs: canonical JSON documents keyed by namespaced document key.
 * - events: compact history/progress events, not full card/deck bodies.
 * - media: de-duplicated blobs by SHA-256, similar to Anki-style media refs.
 */
(function apcLocalSaveStoreR10B() {
  "use strict";

  if (window.APC_LOCAL_SAVE && window.APC_LOCAL_SAVE.version) return;

  const VERSION = "stage-17k-z-r10b-local-save-store";
  const DB_NAME = "buddies_who_study_local_v1";
  const DB_VERSION = 1;

  const STORE_DOCS = "docs";
  const STORE_EVENTS = "events";
  const STORE_MEDIA = "media";

  const DEFAULT_EVENT_LIMIT = 500;
  const MAX_EVENT_PAYLOAD_BYTES = 24 * 1024;
  const MAX_DOC_BYTES_WARN = 512 * 1024;
  const MAX_MEDIA_BYTES = 25 * 1024 * 1024;

  const POLICY = Object.freeze({
    mode: "browser-local-first",
    privateUserDataAuthority: "browser-indexeddb",
    serverPersistenceAllowed: false,
    deckCardServerUploadAllowed: false,
    studyProgressServerUploadAllowed: false,
    ankiContentServerUploadAllowed: false,
    googleDriveSyncAllowedLater: true,
    googleDriveSyncEnabled: false,
    mediaStorage: "indexeddb-content-addressed-sha256",
    progressStorage: "compact-events-plus-rollups",
    tokenStorageAllowed: false
  });

  const DEFAULT_DOC_KEYS = Object.freeze({
    manifest: "sync/manifest/v1",
    profilePreferences: "profile/preferences/v1",
    studyDecks: "study/decks/v1",
    studySessions: "study/sessions/v1",
    studyProgress: "study/progress/v1",
    companionPreferences: "companion/preferences/v1",
    companionLocalMemory: "companion/local-memory/v1"
  });

  function nowIso() {
    return new Date().toISOString();
  }

  function assertIndexedDb() {
    if (!("indexedDB" in window)) {
      throw new Error("IndexedDB is not available in this browser.");
    }
  }

  function cloneJson(value) {
    if (value === undefined) return null;
    return JSON.parse(JSON.stringify(value));
  }

  function jsonSizeBytes(value) {
    try {
      return new TextEncoder().encode(JSON.stringify(value)).length;
    } catch (_) {
      return 0;
    }
  }

  function namespaceFromKey(key) {
    const text = String(key || "");
    const slash = text.indexOf("/");
    return slash > 0 ? text.slice(0, slash) : "misc";
  }

  function dayKeyFromIso(iso) {
    return String(iso || nowIso()).slice(0, 10);
  }

  function randomId(prefix) {
    const rand = (window.crypto && window.crypto.randomUUID)
      ? window.crypto.randomUUID()
      : Math.random().toString(36).slice(2) + "-" + Date.now().toString(36);
    return `${prefix}-${rand}`;
  }

  function requestToPromise(request) {
    return new Promise((resolve, reject) => {
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error || new Error("IndexedDB request failed"));
    });
  }

  let dbPromise = null;

  function openDb() {
    assertIndexedDb();

    if (dbPromise) return dbPromise;

    dbPromise = new Promise((resolve, reject) => {
      const request = window.indexedDB.open(DB_NAME, DB_VERSION);

      request.onupgradeneeded = () => {
        const db = request.result;

        if (!db.objectStoreNames.contains(STORE_DOCS)) {
          const docs = db.createObjectStore(STORE_DOCS, { keyPath: "key" });
          docs.createIndex("namespace", "namespace", { unique: false });
          docs.createIndex("updatedAt", "updatedAt", { unique: false });
          docs.createIndex("recordType", "recordType", { unique: false });
        }

        if (!db.objectStoreNames.contains(STORE_EVENTS)) {
          const events = db.createObjectStore(STORE_EVENTS, { keyPath: "id" });
          events.createIndex("eventType", "eventType", { unique: false });
          events.createIndex("createdAt", "createdAt", { unique: false });
          events.createIndex("dayKey", "dayKey", { unique: false });
          events.createIndex("deckId", "deckId", { unique: false });
          events.createIndex("cardId", "cardId", { unique: false });
          events.createIndex("sessionId", "sessionId", { unique: false });
        }

        if (!db.objectStoreNames.contains(STORE_MEDIA)) {
          const media = db.createObjectStore(STORE_MEDIA, { keyPath: "sha256" });
          media.createIndex("createdAt", "createdAt", { unique: false });
          media.createIndex("mimeType", "mimeType", { unique: false });
          media.createIndex("sizeBytes", "sizeBytes", { unique: false });
        }
      };

      request.onsuccess = () => {
        const db = request.result;
        db.onversionchange = () => {
          try { db.close(); } catch (_) {}
          dbPromise = null;
        };
        resolve(db);
      };

      request.onerror = () => {
        dbPromise = null;
        reject(request.error || new Error("Unable to open local save database"));
      };

      request.onblocked = () => {
        console.warn("[APC_LOCAL_SAVE] IndexedDB open is blocked by another tab.");
      };
    });

    return dbPromise;
  }

  async function withStore(storeName, mode, callback) {
    const db = await openDb();

    return new Promise((resolve, reject) => {
      const tx = db.transaction(storeName, mode);
      const store = tx.objectStore(storeName);
      let callbackResult;

      tx.oncomplete = () => resolve(callbackResult);
      tx.onerror = () => reject(tx.error || new Error(`Transaction failed: ${storeName}`));
      tx.onabort = () => reject(tx.error || new Error(`Transaction aborted: ${storeName}`));

      try {
        callbackResult = callback(store, tx);
      } catch (error) {
        try { tx.abort(); } catch (_) {}
        reject(error);
      }
    });
  }

  async function getRecord(key) {
    if (!key) throw new Error("getRecord requires a key.");
    return withStore(STORE_DOCS, "readonly", (store) => requestToPromise(store.get(String(key))));
  }

  async function getDoc(key, fallbackValue) {
    const record = await getRecord(key);
    if (!record) return fallbackValue === undefined ? null : fallbackValue;
    return record.value;
  }

  async function setDoc(key, value, options) {
    if (!key) throw new Error("setDoc requires a key.");

    const opts = options || {};
    const cleanValue = cloneJson(value);
    const sizeBytes = jsonSizeBytes(cleanValue);
    const current = await getRecord(key);
    const createdAt = current && current.createdAt ? current.createdAt : nowIso();
    const updatedAt = nowIso();

    if (sizeBytes > MAX_DOC_BYTES_WARN) {
      console.warn("[APC_LOCAL_SAVE] large document saved", { key, sizeBytes });
    }

    const record = {
      key: String(key),
      namespace: opts.namespace || namespaceFromKey(key),
      recordType: opts.recordType || "apc_local_doc",
      schemaVersion: opts.schemaVersion || 1,
      value: cleanValue,
      sizeBytes,
      createdAt,
      updatedAt,
      dirty: opts.dirty !== false,
      syncState: opts.syncState || "local-only",
      deleted: false
    };

    await withStore(STORE_DOCS, "readwrite", (store) => store.put(record));
    return record;
  }

  async function patchDoc(key, patch, options) {
    const current = await getDoc(key, {});
    const next = Object.assign({}, current || {}, cloneJson(patch || {}));
    return setDoc(key, next, options);
  }

  async function deleteDoc(key) {
    if (!key) throw new Error("deleteDoc requires a key.");
    await withStore(STORE_DOCS, "readwrite", (store) => store.delete(String(key)));
    return true;
  }

  async function listDocs(prefix) {
    const rows = [];

    await withStore(STORE_DOCS, "readonly", (store) => {
      return new Promise((resolve, reject) => {
        const request = store.openCursor();

        request.onerror = () => reject(request.error || new Error("Unable to list docs"));
        request.onsuccess = () => {
          const cursor = request.result;
          if (!cursor) {
            resolve();
            return;
          }

          const value = cursor.value;
          if (!prefix || String(value.key).startsWith(String(prefix))) {
            rows.push(value);
          }

          cursor.continue();
        };
      });
    });

    rows.sort((a, b) => String(a.key).localeCompare(String(b.key)));
    return rows;
  }

  function compactEventPayload(payload) {
    const clean = cloneJson(payload || {});
    const size = jsonSizeBytes(clean);

    if (size > MAX_EVENT_PAYLOAD_BYTES) {
      throw new Error(`Event payload too large: ${size} bytes. Store large data as a doc or media reference.`);
    }

    return clean;
  }

  async function appendEvent(eventType, payload, options) {
    if (!eventType) throw new Error("appendEvent requires an eventType.");

    const opts = options || {};
    const createdAt = opts.createdAt || nowIso();
    const cleanPayload = compactEventPayload(payload);

    const event = {
      id: opts.id || randomId("evt"),
      eventType: String(eventType),
      createdAt,
      dayKey: opts.dayKey || dayKeyFromIso(createdAt),
      deckId: opts.deckId || cleanPayload.deckId || null,
      cardId: opts.cardId || cleanPayload.cardId || null,
      sessionId: opts.sessionId || cleanPayload.sessionId || null,
      payload: cleanPayload,
      schemaVersion: opts.schemaVersion || 1
    };

    await withStore(STORE_EVENTS, "readwrite", (store) => store.put(event));
    return event;
  }

  async function listEvents(options) {
    const opts = options || {};
    const limit = Math.max(1, Math.min(Number(opts.limit || DEFAULT_EVENT_LIMIT), 5000));
    const rows = [];

    await withStore(STORE_EVENTS, "readonly", (store) => {
      return new Promise((resolve, reject) => {
        const request = store.openCursor(null, "prev");

        request.onerror = () => reject(request.error || new Error("Unable to list events"));
        request.onsuccess = () => {
          const cursor = request.result;
          if (!cursor || rows.length >= limit) {
            resolve();
            return;
          }

          const event = cursor.value;
          const ok =
            (!opts.eventType || event.eventType === opts.eventType) &&
            (!opts.deckId || event.deckId === opts.deckId) &&
            (!opts.cardId || event.cardId === opts.cardId) &&
            (!opts.sessionId || event.sessionId === opts.sessionId) &&
            (!opts.since || String(event.createdAt) >= String(opts.since));

          if (ok) rows.push(event);
          cursor.continue();
        };
      });
    });

    rows.sort((a, b) => String(a.createdAt).localeCompare(String(b.createdAt)));
    return rows;
  }

  function emptyCardRollup(cardId, now) {
    return {
      cardId: cardId || null,
      reviews: 0,
      correct: 0,
      wrong: 0,
      skipped: 0,
      totalAnswerMs: 0,
      lastReviewedAt: null,
      firstReviewedAt: now,
      streakCorrect: 0,
      easeScore: 0,
      updatedAt: now
    };
  }

  function emptyDeckRollup(deckId, now) {
    return {
      deckId: deckId || null,
      reviews: 0,
      correct: 0,
      wrong: 0,
      skipped: 0,
      totalAnswerMs: 0,
      uniqueCards: {},
      lastReviewedAt: null,
      firstReviewedAt: now,
      updatedAt: now
    };
  }

  function emptyDailyRollup(dayKey, now) {
    return {
      dayKey,
      reviews: 0,
      correct: 0,
      wrong: 0,
      skipped: 0,
      studySeconds: 0,
      sessionTypes: {},
      deckIds: {},
      updatedAt: now
    };
  }

  async function recordCardReview(input) {
    const review = input || {};
    if (!review.cardId) throw new Error("recordCardReview requires cardId.");

    const now = review.reviewedAt || nowIso();
    const deckId = review.deckId || "unknown";
    const cardId = String(review.cardId);
    const dayKey = dayKeyFromIso(now);
    const wasCorrect = review.wasCorrect === true;
    const wasSkipped = review.wasSkipped === true;
    const answerMs = Math.max(0, Number(review.answerMs || 0));
    const sessionType = review.sessionType || "standard";

    const event = await appendEvent("card_review", {
      deckId,
      cardId,
      sessionId: review.sessionId || null,
      wasCorrect,
      wasSkipped,
      answerMs,
      sessionType
    }, {
      createdAt: now,
      deckId,
      cardId,
      sessionId: review.sessionId || null
    });

    const cardKey = `progress/cards/${cardId}/v1`;
    const deckKey = `progress/decks/${deckId}/v1`;
    const dailyKey = `progress/daily/${dayKey}/v1`;

    const card = Object.assign(emptyCardRollup(cardId, now), await getDoc(cardKey, {}));
    card.reviews += 1;
    card.correct += wasCorrect ? 1 : 0;
    card.wrong += (!wasCorrect && !wasSkipped) ? 1 : 0;
    card.skipped += wasSkipped ? 1 : 0;
    card.totalAnswerMs += answerMs;
    card.lastReviewedAt = now;
    card.streakCorrect = wasCorrect ? Number(card.streakCorrect || 0) + 1 : 0;
    card.easeScore = Number(card.easeScore || 0) + (wasCorrect ? 1 : -1);
    card.updatedAt = now;

    const deck = Object.assign(emptyDeckRollup(deckId, now), await getDoc(deckKey, {}));
    deck.reviews += 1;
    deck.correct += wasCorrect ? 1 : 0;
    deck.wrong += (!wasCorrect && !wasSkipped) ? 1 : 0;
    deck.skipped += wasSkipped ? 1 : 0;
    deck.totalAnswerMs += answerMs;
    deck.uniqueCards = deck.uniqueCards || {};
    deck.uniqueCards[cardId] = true;
    deck.lastReviewedAt = now;
    deck.updatedAt = now;

    const daily = Object.assign(emptyDailyRollup(dayKey, now), await getDoc(dailyKey, {}));
    daily.reviews += 1;
    daily.correct += wasCorrect ? 1 : 0;
    daily.wrong += (!wasCorrect && !wasSkipped) ? 1 : 0;
    daily.skipped += wasSkipped ? 1 : 0;
    daily.studySeconds += Math.max(0, Math.round(answerMs / 1000));
    daily.sessionTypes = daily.sessionTypes || {};
    daily.sessionTypes[sessionType] = (daily.sessionTypes[sessionType] || 0) + 1;
    daily.deckIds = daily.deckIds || {};
    daily.deckIds[deckId] = true;
    daily.updatedAt = now;

    await setDoc(cardKey, card, { namespace: "progress", recordType: "apc_card_progress_rollup" });
    await setDoc(deckKey, deck, { namespace: "progress", recordType: "apc_deck_progress_rollup" });
    await setDoc(dailyKey, daily, { namespace: "progress", recordType: "apc_daily_progress_rollup" });

    return { event, card, deck, daily };
  }

  async function sha256Hex(bytes) {
    if (!window.crypto || !window.crypto.subtle) {
      throw new Error("crypto.subtle is required for content-addressed media.");
    }

    const digest = await window.crypto.subtle.digest("SHA-256", bytes);
    return Array.from(new Uint8Array(digest))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  }

  async function blobToArrayBuffer(input) {
    if (input instanceof Blob) return input.arrayBuffer();
    if (input instanceof ArrayBuffer) return input;
    if (ArrayBuffer.isView(input)) return input.buffer.slice(input.byteOffset, input.byteOffset + input.byteLength);
    throw new Error("putMedia expects a Blob, ArrayBuffer, or typed array.");
  }

  async function putMedia(input, metadata) {
    const meta = metadata || {};
    const bytes = await blobToArrayBuffer(input);
    const sizeBytes = bytes.byteLength || 0;

    if (sizeBytes <= 0) throw new Error("Cannot store empty media.");
    if (sizeBytes > MAX_MEDIA_BYTES) {
      throw new Error(`Media too large: ${sizeBytes} bytes. Limit is ${MAX_MEDIA_BYTES} bytes.`);
    }

    const mimeType = meta.mimeType || (input instanceof Blob ? input.type : "") || "application/octet-stream";
    const sha256 = await sha256Hex(bytes);
    const existing = await getMediaRecord(sha256);

    if (existing) {
      return {
        sha256,
        duplicate: true,
        sizeBytes: existing.sizeBytes,
        mimeType: existing.mimeType,
        createdAt: existing.createdAt
      };
    }

    const blob = input instanceof Blob ? input : new Blob([bytes], { type: mimeType });
    const record = {
      sha256,
      blob,
      mimeType,
      sizeBytes,
      originalName: meta.originalName || "",
      altText: meta.altText || "",
      createdAt: nowIso(),
      updatedAt: nowIso(),
      refHint: meta.refHint || ""
    };

    await withStore(STORE_MEDIA, "readwrite", (store) => store.put(record));

    return {
      sha256,
      duplicate: false,
      sizeBytes,
      mimeType,
      createdAt: record.createdAt
    };
  }

  async function getMediaRecord(sha256) {
    if (!sha256) throw new Error("getMediaRecord requires sha256.");
    return withStore(STORE_MEDIA, "readonly", (store) => requestToPromise(store.get(String(sha256))));
  }

  async function getMediaBlob(sha256) {
    const record = await getMediaRecord(sha256);
    return record ? record.blob : null;
  }

  async function listMedia() {
    const rows = [];

    await withStore(STORE_MEDIA, "readonly", (store) => {
      return new Promise((resolve, reject) => {
        const request = store.openCursor();

        request.onerror = () => reject(request.error || new Error("Unable to list media"));
        request.onsuccess = () => {
          const cursor = request.result;
          if (!cursor) {
            resolve();
            return;
          }

          const value = cursor.value;
          rows.push({
            sha256: value.sha256,
            mimeType: value.mimeType,
            sizeBytes: value.sizeBytes,
            originalName: value.originalName || "",
            altText: value.altText || "",
            createdAt: value.createdAt,
            updatedAt: value.updatedAt
          });

          cursor.continue();
        };
      });
    });

    rows.sort((a, b) => String(a.createdAt).localeCompare(String(b.createdAt)));
    return rows;
  }

  async function deleteMedia(sha256) {
    if (!sha256) throw new Error("deleteMedia requires sha256.");
    await withStore(STORE_MEDIA, "readwrite", (store) => store.delete(String(sha256)));
    return true;
  }

  async function exportAll() {
    return {
      recordType: "buddies_who_study_local_export",
      schemaVersion: 1,
      exportedAt: nowIso(),
      policy: POLICY,
      docs: await listDocs(),
      events: await listEvents({ limit: 5000 }),
      media: await listMedia()
    };
  }

  async function importDocs(payload, options) {
    const opts = options || {};
    const docs = Array.isArray(payload && payload.docs) ? payload.docs : [];
    const imported = [];

    for (const record of docs) {
      if (!record || !record.key) continue;
      const next = opts.keepEnvelope
        ? record
        : {
            key: record.key,
            value: record.value,
            namespace: record.namespace,
            recordType: record.recordType,
            schemaVersion: record.schemaVersion
          };

      await setDoc(next.key, next.value, next);
      imported.push(next.key);
    }

    return { importedDocKeys: imported };
  }

  async function estimateStorage() {
    if (navigator.storage && navigator.storage.estimate) {
      return navigator.storage.estimate();
    }
    return { quota: null, usage: null };
  }

  async function requestPersistentStorage() {
    if (navigator.storage && navigator.storage.persist) {
      return navigator.storage.persist();
    }
    return false;
  }

  async function ensureManifest() {
    const existing = await getDoc(DEFAULT_DOC_KEYS.manifest, null);
    if (existing) return existing;

    const manifest = {
      app: "Buddies Who Study",
      schemaVersion: 1,
      createdAt: nowIso(),
      updatedAt: nowIso(),
      localDatabase: DB_NAME,
      documents: DEFAULT_DOC_KEYS,
      media: {
        strategy: "content-addressed-sha256",
        maxMediaBytes: MAX_MEDIA_BYTES
      },
      progress: {
        strategy: "compact-events-plus-rollups",
        eventPayloadLimitBytes: MAX_EVENT_PAYLOAD_BYTES
      },
      sync: {
        googleDriveEnabled: false,
        googleDriveStorageSpace: "appDataFolder",
        lastSyncAt: null
      },
      policy: POLICY
    };

    await setDoc(DEFAULT_DOC_KEYS.manifest, manifest, {
      namespace: "sync",
      recordType: "apc_local_manifest",
      dirty: false
    });

    return manifest;
  }

  async function debug() {
    const docs = await listDocs();
    const events = await listEvents({ limit: 1 });
    const media = await listMedia();
    const storage = await estimateStorage();

    return {
      version: VERSION,
      dbName: DB_NAME,
      dbVersion: DB_VERSION,
      policy: POLICY,
      docCount: docs.length,
      latestEventCountSampled: events.length,
      mediaCount: media.length,
      storage
    };
  }

  const api = Object.freeze({
    version: VERSION,
    dbName: DB_NAME,
    dbVersion: DB_VERSION,
    policy: POLICY,
    keys: DEFAULT_DOC_KEYS,

    openDb,
    ensureManifest,

    getRecord,
    getDoc,
    setDoc,
    patchDoc,
    deleteDoc,
    listDocs,

    appendEvent,
    listEvents,
    recordCardReview,

    putMedia,
    getMediaRecord,
    getMediaBlob,
    listMedia,
    deleteMedia,

    exportAll,
    importDocs,

    estimateStorage,
    requestPersistentStorage,
    debug
  });

  window.APC_LOCAL_SAVE = api;
  window.APC_LOCAL_SAVE_POLICY = POLICY;

  try {
    document.documentElement.setAttribute("data-apc-local-save-store", VERSION);
    document.dispatchEvent(new CustomEvent("apc-local-save-ready", { detail: { version: VERSION } }));
  } catch (_) {}

  ensureManifest().catch((error) => {
    console.warn("[APC_LOCAL_SAVE] manifest initialization failed", error);
  });
})();
