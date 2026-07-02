(function localBackupMergePlannerR12Z(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_MERGE_PLANNER_R12Z_SOURCE_ONLY";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const WRITE_MODE = "preview-only";

  const PRIMARY_STUDY_DOC_KEYS = Object.freeze([
    "study/cards/v1",
    "study/decks/v1",
    "study/progress/v1",
    "study/sessions/v1",
    "study/store-state/v1"
  ]);

  const MEDIA_DOC_KEYS = Object.freeze([
    "study/media/v1",
    "study/media-blobs/v1",
    "study/card-media-refs/v1",
    "study/media-manifest/v1",
    "study/anki-media/v1",
    "study/anki-imports/v1"
  ]);

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function cloneJson(value) {
    if (value === undefined) return undefined;
    return JSON.parse(JSON.stringify(value));
  }

  function parseDateMs(value) {
    if (!value || typeof value !== "string") return 0;
    const ms = Date.parse(value);
    return Number.isFinite(ms) ? ms : 0;
  }

  function updatedAtOf(item) {
    if (!item || typeof item !== "object") return 0;
    return Math.max(
      parseDateMs(item.updatedAt),
      parseDateMs(item.modifiedAt),
      parseDateMs(item.createdAt),
      parseDateMs(item.lastSeenAt),
      parseDateMs(item.reviewedAt),
      parseDateMs(item.startedAt),
      parseDateMs(item.endedAt)
    );
  }

  function stableStringify(value) {
    if (Array.isArray(value)) {
      return "[" + value.map(stableStringify).join(",") + "]";
    }

    if (isObject(value)) {
      return "{" + Object.keys(value).sort().map(function stringifyKey(key) {
        return JSON.stringify(key) + ":" + stableStringify(value[key]);
      }).join(",") + "}";
    }

    return JSON.stringify(value);
  }

  function valuesEqual(a, b) {
    return stableStringify(a) === stableStringify(b);
  }

  function docsObject(payload) {
    if (!payload || payload.docs === undefined || payload.docs === null) return {};

    if (Array.isArray(payload.docs)) {
      const out = {};
      payload.docs.forEach(function copyLegacyDoc(entry) {
        if (!entry || !entry.key) return;
        out[String(entry.key)] = entry.value === undefined ? null : cloneJson(entry.value);
      });
      return out;
    }

    if (isObject(payload.docs)) {
      return cloneJson(payload.docs);
    }

    return {};
  }

  function backupEnvelope(value) {
    const payload = isObject(value) ? cloneJson(value) : {};
    payload.kind = payload.kind || BACKUP_KIND;
    payload.version = Number(payload.version || 1);
    payload.docs = docsObject(payload);
    return payload;
  }

  function getDoc(payload, key) {
    const docs = docsObject(payload);
    return docs[key];
  }

  function listFromDoc(doc, names) {
    if (!doc) return [];
    for (const name of names) {
      if (Array.isArray(doc[name])) return doc[name];
    }
    return [];
  }

  function itemId(item, fallbackPrefix, index) {
    if (!item || typeof item !== "object") return fallbackPrefix + "-" + index;
    return String(
      item.id ||
      item.cardId ||
      item.deckId ||
      item.importId ||
      item.mediaId ||
      item.sha256 ||
      item.hash ||
      item.originalFilename ||
      fallbackPrefix + "-" + index
    );
  }

  function compareById(currentList, incomingList, options) {
    const opts = options || {};
    const fallbackPrefix = opts.fallbackPrefix || "item";
    const currentById = new Map();
    const incomingById = new Map();
    const adds = [];
    const updates = [];
    const skips = [];
    const conflicts = [];

    (currentList || []).forEach(function indexCurrent(item, index) {
      currentById.set(itemId(item, fallbackPrefix, index), item);
    });

    (incomingList || []).forEach(function indexIncoming(item, index) {
      incomingById.set(itemId(item, fallbackPrefix, index), item);
    });

    incomingById.forEach(function compareIncoming(incoming, id) {
      if (!currentById.has(id)) {
        adds.push({ id: id, incoming: cloneJson(incoming) });
        return;
      }

      const current = currentById.get(id);
      if (valuesEqual(current, incoming)) {
        skips.push({ id: id, reason: "same" });
        return;
      }

      const currentMs = updatedAtOf(current);
      const incomingMs = updatedAtOf(incoming);

      if (incomingMs > currentMs) {
        updates.push({ id: id, reason: "incoming-newer", currentUpdatedAt: current.updatedAt || null, incomingUpdatedAt: incoming.updatedAt || null });
        return;
      }

      if (currentMs > incomingMs) {
        skips.push({ id: id, reason: "current-newer", currentUpdatedAt: current.updatedAt || null, incomingUpdatedAt: incoming.updatedAt || null });
        return;
      }

      conflicts.push({
        id: id,
        reason: "same-timestamp-different-content",
        currentUpdatedAt: current && current.updatedAt ? current.updatedAt : null,
        incomingUpdatedAt: incoming && incoming.updatedAt ? incoming.updatedAt : null
      });
    });

    return {
      currentCount: currentById.size,
      incomingCount: incomingById.size,
      addCount: adds.length,
      updateCount: updates.length,
      skipCount: skips.length,
      conflictCount: conflicts.length,
      adds: adds,
      updates: updates,
      skips: skips,
      conflicts: conflicts
    };
  }

  function compareDecks(currentPayload, incomingPayload) {
    return compareById(
      listFromDoc(getDoc(currentPayload, "study/decks/v1"), ["decks"]),
      listFromDoc(getDoc(incomingPayload, "study/decks/v1"), ["decks"]),
      { fallbackPrefix: "deck" }
    );
  }

  function compareCards(currentPayload, incomingPayload) {
    return compareById(
      listFromDoc(getDoc(currentPayload, "study/cards/v1"), ["cards"]),
      listFromDoc(getDoc(incomingPayload, "study/cards/v1"), ["cards"]),
      { fallbackPrefix: "card" }
    );
  }

  function compareSessions(currentPayload, incomingPayload) {
    return compareById(
      listFromDoc(getDoc(currentPayload, "study/sessions/v1"), ["recentSessions", "sessions"]),
      listFromDoc(getDoc(incomingPayload, "study/sessions/v1"), ["recentSessions", "sessions"]),
      { fallbackPrefix: "session" }
    );
  }

  function compareMedia(currentPayload, incomingPayload) {
    const currentMedia = []
      .concat(listFromDoc(getDoc(currentPayload, "study/media/v1"), ["items"]))
      .concat(listFromDoc(getDoc(currentPayload, "study/media-manifest/v1"), ["items"]));

    const incomingMedia = []
      .concat(listFromDoc(getDoc(incomingPayload, "study/media/v1"), ["items"]))
      .concat(listFromDoc(getDoc(incomingPayload, "study/media-manifest/v1"), ["items"]));

    return compareById(currentMedia, incomingMedia, { fallbackPrefix: "media" });
  }

  function compareCardMediaRefs(currentPayload, incomingPayload) {
    return compareById(
      listFromDoc(getDoc(currentPayload, "study/card-media-refs/v1"), ["refs"]),
      listFromDoc(getDoc(incomingPayload, "study/card-media-refs/v1"), ["refs"]),
      { fallbackPrefix: "card-media-ref" }
    );
  }

  function compareAnkiImports(currentPayload, incomingPayload) {
    return compareById(
      listFromDoc(getDoc(currentPayload, "study/anki-imports/v1"), ["imports"]),
      listFromDoc(getDoc(incomingPayload, "study/anki-imports/v1"), ["imports"]),
      { fallbackPrefix: "anki-import" }
    );
  }

  function docPresence(currentPayload, incomingPayload) {
    const currentDocs = docsObject(currentPayload);
    const incomingDocs = docsObject(incomingPayload);
    const allKeys = Array.from(new Set(
      PRIMARY_STUDY_DOC_KEYS
        .concat(MEDIA_DOC_KEYS)
        .concat(Object.keys(currentDocs))
        .concat(Object.keys(incomingDocs))
    )).sort();

    return allKeys.map(function mapKey(key) {
      return {
        key: key,
        currentPresent: currentDocs[key] !== undefined,
        incomingPresent: incomingDocs[key] !== undefined
      };
    });
  }

  function countTotals(plan) {
    const sections = [
      plan.decks,
      plan.cards,
      plan.sessions,
      plan.media,
      plan.cardMediaRefs,
      plan.ankiImports
    ];

    return sections.reduce(function reduceTotals(total, section) {
      total.adds += section.addCount || 0;
      total.updates += section.updateCount || 0;
      total.skips += section.skipCount || 0;
      total.conflicts += section.conflictCount || 0;
      return total;
    }, { adds: 0, updates: 0, skips: 0, conflicts: 0 });
  }

  function createMergePlan(currentValue, incomingValue, options) {
    const current = backupEnvelope(currentValue || {});
    const incoming = backupEnvelope(incomingValue || {});
    const errors = [];
    const warnings = [];

    if (incoming.kind !== BACKUP_KIND) {
      errors.push("Incoming backup kind is not buddies-who-study-local-backup.");
    }

    if (!incoming.docs || !isObject(incoming.docs)) {
      errors.push("Incoming backup docs could not be read.");
    }

    PRIMARY_STUDY_DOC_KEYS.forEach(function requireStudyDoc(key) {
      if (incoming.docs[key] === undefined) {
        warnings.push("Incoming backup is missing primary Study doc: " + key);
      }
    });

    MEDIA_DOC_KEYS.forEach(function noteMediaDoc(key) {
      if (incoming.docs[key] === undefined) {
        warnings.push("Incoming backup is missing media doc: " + key);
      }
    });

    const plan = {
      marker: MARKER,
      kind: "buddies-who-study-backup-merge-plan",
      version: 1,
      createdAt: options && options.createdAt ? options.createdAt : new Date().toISOString(),
      writeMode: WRITE_MODE,
      canWrite: false,
      writesEnabled: false,
      requiresExplicitConfirmation: true,
      overwriteExistingLocalData: false,
      current: {
        kind: current.kind,
        version: current.version || 0,
        docCount: Object.keys(current.docs || {}).length
      },
      incoming: {
        kind: incoming.kind,
        version: incoming.version || 0,
        docCount: Object.keys(incoming.docs || {}).length
      },
      docPresence: docPresence(current, incoming),
      decks: compareDecks(current, incoming),
      cards: compareCards(current, incoming),
      sessions: compareSessions(current, incoming),
      media: compareMedia(current, incoming),
      cardMediaRefs: compareCardMediaRefs(current, incoming),
      ankiImports: compareAnkiImports(current, incoming),
      progress: {
        strategy: "recompute-from-cards-and-sessions-before-write",
        canApplyDirectly: false
      },
      storeState: {
        strategy: "merge-canonical-state-only-and-drop-transient-cache-fields-before-write",
        canApplyDirectly: false
      },
      errors: errors,
      warnings: warnings
    };

    plan.totals = countTotals(plan);
    plan.ok = errors.length === 0;
    return plan;
  }

  function formatMergePlanLines(plan) {
    const p = plan || {};
    const totals = p.totals || {};
    const lines = [
      "Backup merge preview",
      "Write mode: " + (p.writeMode || WRITE_MODE),
      "Can write: " + String(p.canWrite === true),
      "Incoming version: " + String(p.incoming && p.incoming.version ? p.incoming.version : "unknown"),
      "Adds: " + String(totals.adds || 0),
      "Updates: " + String(totals.updates || 0),
      "Skipped: " + String(totals.skips || 0),
      "Conflicts: " + String(totals.conflicts || 0),
      "Deck adds: " + String(p.decks ? p.decks.addCount : 0),
      "Card adds: " + String(p.cards ? p.cards.addCount : 0),
      "Session adds: " + String(p.sessions ? p.sessions.addCount : 0),
      "Media adds: " + String(p.media ? p.media.addCount : 0),
      "Warnings: " + String((p.warnings || []).length),
      "Errors: " + String((p.errors || []).length)
    ];

    (p.warnings || []).slice(0, 8).forEach(function addWarning(warning) {
      lines.push("Warning: " + warning);
    });

    (p.errors || []).slice(0, 8).forEach(function addError(error) {
      lines.push("Error: " + error);
    });

    return lines;
  }

  function formatMergePlanText(plan) {
    return formatMergePlanLines(plan).join("\n");
  }

  function formatMergePlanHtml(plan) {
    const text = formatMergePlanText(plan);
    const escaped = text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
    return '<pre data-apc-local-backup-merge-plan-preview="true">' + escaped + "</pre>";
  }

  const api = Object.freeze({
    MARKER: MARKER,
    BACKUP_KIND: BACKUP_KIND,
    WRITE_MODE: WRITE_MODE,
    PRIMARY_STUDY_DOC_KEYS: PRIMARY_STUDY_DOC_KEYS,
    MEDIA_DOC_KEYS: MEDIA_DOC_KEYS,
    docsObject: docsObject,
    backupEnvelope: backupEnvelope,
    compareById: compareById,
    createMergePlan: createMergePlan,
    formatMergePlanLines: formatMergePlanLines,
    formatMergePlanText: formatMergePlanText,
    formatMergePlanHtml: formatMergePlanHtml
  });

  root.APC_LOCAL_BACKUP_MERGE_PLANNER = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
