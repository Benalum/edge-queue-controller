(function localBackupLegacyBackendCacheSanitizerR13K(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_LEGACY_BACKEND_CACHE_SANITIZER_R13K_SOURCE_ONLY";
  const MODE = "preview-only";
  const STORE_STATE_KEY = "study/store-state/v1";
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

  function docsFromPayloadOrDocs(payloadOrDocs) {
    if (!payloadOrDocs) return {};
    if (isObject(payloadOrDocs.docs)) return payloadOrDocs.docs;
    if (isObject(payloadOrDocs) && isObject(payloadOrDocs[STORE_STATE_KEY])) return payloadOrDocs;
    return {};
  }

  function getStoreStateDoc(payloadOrDocs) {
    const docs = docsFromPayloadOrDocs(payloadOrDocs);
    return isObject(docs[STORE_STATE_KEY]) ? docs[STORE_STATE_KEY] : null;
  }

  function getStoreStateObject(storeStateDoc) {
    if (!isObject(storeStateDoc)) return null;
    if (isObject(storeStateDoc.state)) return storeStateDoc.state;
    return null;
  }

  function findLegacyBackendCacheFields(payloadOrDocs) {
    const storeStateDoc = getStoreStateDoc(payloadOrDocs);
    const state = getStoreStateObject(storeStateDoc);
    const fields = [];

    if (!state) {
      return {
        marker: MARKER,
        storeStateFound: false,
        legacyFieldCount: 0,
        fields: fields,
        warnings: ["No study/store-state/v1 state object found."]
      };
    }

    LEGACY_BACKEND_CACHE_KEYS.forEach(function checkKey(key) {
      if (Object.prototype.hasOwnProperty.call(state, key)) {
        fields.push({
          key: key,
          path: STORE_STATE_KEY + ".state." + key,
          valueType: Array.isArray(state[key]) ? "array" : typeof state[key]
        });
      }
    });

    return {
      marker: MARKER,
      storeStateFound: true,
      legacyFieldCount: fields.length,
      fields: fields,
      warnings: fields.length
        ? ["Legacy backend cache fields found. Future local-only backup output should exclude these fields."]
        : []
    };
  }

  function createSanitizedStoreStateDoc(storeStateDoc, options) {
    const input = isObject(storeStateDoc) ? storeStateDoc : {};
    const cloned = cloneJson(input);
    const state = getStoreStateObject(cloned);
    const removed = [];
    const warnings = [];

    if (!state) {
      warnings.push("No state object found in study/store-state/v1.");
      return {
        marker: MARKER,
        mode: MODE,
        canWrite: false,
        writesEnabled: false,
        removed: removed,
        sanitizedDoc: cloned,
        warnings: warnings
      };
    }

    LEGACY_BACKEND_CACHE_KEYS.forEach(function removeKey(key) {
      if (Object.prototype.hasOwnProperty.call(state, key)) {
        delete state[key];
        removed.push({
          key: key,
          path: STORE_STATE_KEY + ".state." + key
        });
      }
    });

    if (options && options.updatedAt) {
      cloned.updatedAt = String(options.updatedAt);
    }

    return {
      marker: MARKER,
      mode: MODE,
      canWrite: false,
      writesEnabled: false,
      removed: removed,
      sanitizedDoc: cloned,
      warnings: removed.length
        ? ["Sanitized preview removed legacy backend cache fields from the cloned preview only."]
        : []
    };
  }

  function createBackupSanitizationPreview(payloadOrDocs, options) {
    const docs = docsFromPayloadOrDocs(payloadOrDocs);
    const storeStateDoc = getStoreStateDoc(docs);
    const found = findLegacyBackendCacheFields(docs);
    const sanitized = storeStateDoc
      ? createSanitizedStoreStateDoc(storeStateDoc, options || {})
      : null;

    return {
      marker: MARKER,
      kind: "buddies-who-study-local-backup-sanitization-preview",
      version: 1,
      mode: MODE,
      canWrite: false,
      writesEnabled: false,
      writeMode: MODE,
      legacyFieldCount: found.legacyFieldCount,
      fields: found.fields,
      removedFromPreviewOnly: sanitized ? sanitized.removed : [],
      storeStateFound: found.storeStateFound,
      sanitizedStoreStateDoc: sanitized ? sanitized.sanitizedDoc : null,
      requiredBeforeFutureSave: [
        "Exclude legacy backend cache fields from future local-only backup output.",
        "Do not send private Study cards, decks, notes, sessions, or Anki content to the server.",
        "Do not mutate original Anki files.",
        "Show sanitizer preview before enabling any same-file update path."
      ],
      serverUploadAllowed: false,
      ankiSourceMutationAllowed: false,
      localStudyRestoreWriteAllowed: false,
      sameFileWriteEnabled: false,
      warnings: [].concat(found.warnings || [], sanitized ? sanitized.warnings || [] : []),
      errors: []
    };
  }

  function formatSanitizationPreviewLines(preview) {
    const p = preview || {};
    const lines = [
      "Legacy backend cache sanitizer",
      "Mode: " + String(p.mode || MODE),
      "Can write: " + String(p.canWrite === true),
      "Store state found: " + String(p.storeStateFound === true),
      "Legacy fields found: " + String(p.legacyFieldCount || 0),
      "",
      "Safety",
      "Preview only. No data was saved, restored, merged, or overwritten.",
      "Writing stays disabled."
    ];

    if ((p.fields || []).length) {
      lines.push("");
      lines.push("Fields that future local-only backups should exclude:");
      (p.fields || []).forEach(function addField(field) {
        lines.push("- " + field.path + " (" + field.valueType + ")");
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

  function formatSanitizationPreviewText(preview) {
    return formatSanitizationPreviewLines(preview).join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    STORE_STATE_KEY: STORE_STATE_KEY,
    LEGACY_BACKEND_CACHE_KEYS: LEGACY_BACKEND_CACHE_KEYS,
    findLegacyBackendCacheFields: findLegacyBackendCacheFields,
    createSanitizedStoreStateDoc: createSanitizedStoreStateDoc,
    createBackupSanitizationPreview: createBackupSanitizationPreview,
    formatSanitizationPreviewLines: formatSanitizationPreviewLines,
    formatSanitizationPreviewText: formatSanitizationPreviewText
  });

  root.APC_LOCAL_BACKUP_LEGACY_BACKEND_CACHE_SANITIZER = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
