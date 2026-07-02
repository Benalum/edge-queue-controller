(function localBackupSanitizedPayloadBuilderR13M(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER_R13M_SOURCE_ONLY";
  const MODE = "preview-only";
  const STORE_STATE_KEY = "study/store-state/v1";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const BACKUP_VERSION = 2;
  const LEGACY_BACKEND_CACHE_KEYS = Object.freeze([
    "backendProgress",
    "backendReviewSummary",
    "backendSessions",
    "backendSyncedAt"
  ]);

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function cloneJson(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function ensurePrivacyFlags(payload) {
    const clone = payload;
    clone.privacy = isObject(clone.privacy) ? clone.privacy : {};
    clone.privacy.serverUpload = false;
    clone.privacy.uploadsToServer = false;
    clone.privacy.ankiSourceMutation = false;
    clone.privacy.sourceMutation = false;
    clone.privacy.modifiesAnkiSourceFiles = false;
    clone.privacy.includesAnkiSourceFileBytes = false;
    clone.privacy.originalAnkiBytesIncluded = false;
    clone.privacy.localOnly = true;
    return clone;
  }

  function summarizePayload(payload) {
    const docs = payload && isObject(payload.docs) ? payload.docs : {};
    const cardsDoc = docs["study/cards/v1"] || {};
    const decksDoc = docs["study/decks/v1"] || {};
    const sessionsDoc = docs["study/sessions/v1"] || {};
    const mediaDoc = docs["study/media-manifest/v1"] || {};

    const cards = Array.isArray(cardsDoc.cards) ? cardsDoc.cards : [];
    const decks = Array.isArray(decksDoc.decks) ? decksDoc.decks : [];
    const sessions = Array.isArray(sessionsDoc.recentSessions)
      ? sessionsDoc.recentSessions
      : Array.isArray(sessionsDoc.sessions)
        ? sessionsDoc.sessions
        : [];

    return {
      docCount: Object.keys(docs).length,
      deckCount: decks.length,
      cardCount: cards.length,
      sessionCount: sessions.length,
      mediaCount: Number(mediaDoc.mediaCount || 0),
      totalMediaBytes: Number(mediaDoc.totalBytes || 0)
    };
  }

  function stripLegacyBackendCacheFromPayloadClone(payloadClone, options) {
    const removed = [];
    const warnings = [];

    if (!payloadClone || !isObject(payloadClone.docs)) {
      warnings.push("No docs object found in backup payload.");
      return { removed: removed, warnings: warnings };
    }

    const storeDoc = payloadClone.docs[STORE_STATE_KEY];
    if (!isObject(storeDoc) || !isObject(storeDoc.state)) {
      warnings.push("No study/store-state/v1 state object found.");
      return { removed: removed, warnings: warnings };
    }

    LEGACY_BACKEND_CACHE_KEYS.forEach(function removeKey(key) {
      if (Object.prototype.hasOwnProperty.call(storeDoc.state, key)) {
        delete storeDoc.state[key];
        removed.push({
          key: key,
          path: STORE_STATE_KEY + ".state." + key
        });
      }
    });

    if (options && options.updatedAt) {
      storeDoc.updatedAt = String(options.updatedAt);
    }

    return {
      removed: removed,
      warnings: removed.length
        ? ["Legacy backend cache fields were removed from the cloned sanitized backup payload only."]
        : warnings
    };
  }

  function createSanitizedBackupPayload(payload, options) {
    const input = isObject(payload) ? payload : {};
    const createdAt = options && options.createdAt ? String(options.createdAt) : new Date().toISOString();
    const clone = ensurePrivacyFlags(cloneJson(input));

    clone.kind = clone.kind || BACKUP_KIND;
    clone.version = Number(clone.version || BACKUP_VERSION);

    if (options && options.updateCreatedAt === true) {
      clone.createdAt = createdAt;
    }

    if (isObject(clone.docs)) {
      clone.backupDocs = Object.keys(clone.docs);
    }

    const strip = stripLegacyBackendCacheFromPayloadClone(clone, {
      updatedAt: options && options.updatedAt ? String(options.updatedAt) : null
    });

    return {
      marker: MARKER,
      mode: MODE,
      canWrite: false,
      writesEnabled: false,
      writeMode: MODE,
      sanitizedPayload: clone,
      removedFromSanitizedPayload: strip.removed,
      removedFieldCount: strip.removed.length,
      warnings: strip.warnings,
      errors: [],
      serverUploadAllowed: false,
      ankiSourceMutationAllowed: false,
      localStudyRestoreWriteAllowed: false,
      sameFileWriteEnabled: false
    };
  }

  function createSanitizedBackupPayloadPreview(payload, options) {
    const beforeSummary = summarizePayload(payload || {});
    const result = createSanitizedBackupPayload(payload || {}, options || {});
    const afterSummary = summarizePayload(result.sanitizedPayload || {});

    return {
      marker: MARKER,
      kind: "buddies-who-study-sanitized-backup-payload-preview",
      version: 1,
      mode: MODE,
      canWrite: false,
      writesEnabled: false,
      writeMode: MODE,
      beforeSummary: beforeSummary,
      afterSummary: afterSummary,
      removedFieldCount: result.removedFieldCount,
      removedFromSanitizedPayload: result.removedFromSanitizedPayload,
      sanitizedPayload: result.sanitizedPayload,
      requiredBeforeFutureSave: [
        "Use sanitized payload output for future Download snapshot.",
        "Use sanitized payload output before future current-file save.",
        "Keep original browser Study data unchanged unless a separate explicit local-only migration is approved.",
        "Do not upload private Study data to the server.",
        "Do not mutate original Anki files."
      ],
      serverUploadAllowed: false,
      ankiSourceMutationAllowed: false,
      localStudyRestoreWriteAllowed: false,
      sameFileWriteEnabled: false,
      warnings: result.warnings,
      errors: result.errors
    };
  }

  function formatSanitizedBackupPayloadPreviewLines(preview) {
    const p = preview || {};
    const before = p.beforeSummary || {};
    const after = p.afterSummary || {};
    const lines = [
      "Sanitized backup payload preview",
      "Mode: " + String(p.mode || MODE),
      "Can write: " + String(p.canWrite === true),
      "Legacy fields removed from sanitized payload: " + String(p.removedFieldCount || 0),
      "",
      "Before",
      String(before.deckCount || 0) + " decks, " + String(before.cardCount || 0) + " cards, " + String(before.sessionCount || 0) + " sessions, " + String(before.mediaCount || 0) + " media",
      "",
      "After",
      String(after.deckCount || 0) + " decks, " + String(after.cardCount || 0) + " cards, " + String(after.sessionCount || 0) + " sessions, " + String(after.mediaCount || 0) + " media",
      "",
      "Safety",
      "Preview only. No data was saved, restored, merged, or overwritten.",
      "Writing stays disabled."
    ];

    if ((p.removedFromSanitizedPayload || []).length) {
      lines.push("");
      lines.push("Fields removed from cloned sanitized payload:");
      (p.removedFromSanitizedPayload || []).forEach(function addRemoved(field) {
        lines.push("- " + field.path);
      });
    }

    if ((p.warnings || []).length) {
      lines.push("");
      lines.push("Warnings: " + String(p.warnings.length));
      (p.warnings || []).slice(0, 8).forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    if ((p.errors || []).length) {
      lines.push("");
      lines.push("Errors: " + String(p.errors.length));
      (p.errors || []).slice(0, 8).forEach(function addError(error) {
        lines.push("- " + error);
      });
    }

    return lines;
  }

  function formatSanitizedBackupPayloadPreviewText(preview) {
    return formatSanitizedBackupPayloadPreviewLines(preview).join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    STORE_STATE_KEY: STORE_STATE_KEY,
    BACKUP_KIND: BACKUP_KIND,
    BACKUP_VERSION: BACKUP_VERSION,
    LEGACY_BACKEND_CACHE_KEYS: LEGACY_BACKEND_CACHE_KEYS,
    summarizePayload: summarizePayload,
    createSanitizedBackupPayload: createSanitizedBackupPayload,
    createSanitizedBackupPayloadPreview: createSanitizedBackupPayloadPreview,
    formatSanitizedBackupPayloadPreviewLines: formatSanitizedBackupPayloadPreviewLines,
    formatSanitizedBackupPayloadPreviewText: formatSanitizedBackupPayloadPreviewText
  });

  root.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
