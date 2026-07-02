(function localBackupCurrentFileAccessR13F(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_ACCESS_ADAPTER_R13F_SOURCE_ONLY";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const SNAPSHOT_PREFIX = "buddies-who-study-local-backup-v2-";
  const JSON_EXTENSION = ".json";
  const MODE = "read-and-preview-only";

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function cloneJson(value) {
    if (value === undefined) return undefined;
    return JSON.parse(JSON.stringify(value));
  }

  function stableFilePlanApi() {
    return root && root.APC_LOCAL_BACKUP_STABLE_FILE_PLAN
      ? root.APC_LOCAL_BACKUP_STABLE_FILE_PLAN
      : null;
  }

  function restorePreviewApi() {
    return root && root.APC_LOCAL_BACKUP_RESTORE_PREVIEW
      ? root.APC_LOCAL_BACKUP_RESTORE_PREVIEW
      : null;
  }

  function classifyFileName(fileName) {
    const stableApi = stableFilePlanApi();
    if (stableApi && typeof stableApi.classifyBackupFileName === "function") {
      return stableApi.classifyBackupFileName(fileName || "");
    }

    const name = String(fileName || "");
    if (name === CURRENT_FILE_NAME) {
      return {
        fileName: name,
        role: "stable-current",
        canBeMainMergeFile: true,
        shouldCreateNewSnapshot: false,
        recommendation: "Use this as the normal file to open, preview, merge, and update later."
      };
    }

    if (name.indexOf(SNAPSHOT_PREFIX) === 0 && name.endsWith(JSON_EXTENSION)) {
      return {
        fileName: name,
        role: "manual-snapshot",
        canBeMainMergeFile: false,
        shouldCreateNewSnapshot: false,
        recommendation: "Keep this as a timestamped snapshot. Preview it before merging into buddies-who-study-current.json."
      };
    }

    return {
      fileName: name,
      role: "unknown-json",
      canBeMainMergeFile: false,
      shouldCreateNewSnapshot: true,
      recommendation: "Preview this file first. If valid, merge into buddies-who-study-current.json later."
    };
  }

  function parseBackupJsonText(text) {
    if (typeof text !== "string" || text.trim() === "") {
      throw new Error("Backup file is empty.");
    }

    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch (error) {
      throw new Error("Backup file is not valid JSON.");
    }

    if (!isObject(parsed)) {
      throw new Error("Backup JSON must be an object.");
    }

    if (parsed.kind && parsed.kind !== BACKUP_KIND) {
      throw new Error("Backup kind is not buddies-who-study-local-backup.");
    }

    return parsed;
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

  function summarizeBackupPayload(payload) {
    const docs = docsObject(payload);
    const cards = docs["study/cards/v1"] && Array.isArray(docs["study/cards/v1"].cards)
      ? docs["study/cards/v1"].cards
      : [];
    const decks = docs["study/decks/v1"] && Array.isArray(docs["study/decks/v1"].decks)
      ? docs["study/decks/v1"].decks
      : [];
    const sessionsDoc = docs["study/sessions/v1"] || {};
    const sessions = Array.isArray(sessionsDoc.recentSessions)
      ? sessionsDoc.recentSessions
      : Array.isArray(sessionsDoc.sessions)
        ? sessionsDoc.sessions
        : [];
    const mediaManifest = docs["study/media-manifest/v1"] || {};

    return {
      kind: payload && payload.kind ? payload.kind : "",
      version: payload && payload.version ? Number(payload.version) : 0,
      createdAt: payload && payload.createdAt ? payload.createdAt : "",
      docCount: Object.keys(docs).length,
      hasCardsDoc: docs["study/cards/v1"] !== undefined,
      hasDecksDoc: docs["study/decks/v1"] !== undefined,
      hasProgressDoc: docs["study/progress/v1"] !== undefined,
      hasSessionsDoc: docs["study/sessions/v1"] !== undefined,
      hasStoreStateDoc: docs["study/store-state/v1"] !== undefined,
      hasMediaDocs: docs["study/media/v1"] !== undefined &&
        docs["study/media-blobs/v1"] !== undefined &&
        docs["study/card-media-refs/v1"] !== undefined &&
        docs["study/media-manifest/v1"] !== undefined,
      cardCount: cards.length,
      deckCount: decks.length,
      sessionCount: sessions.length,
      mediaCount: Number(mediaManifest.mediaCount || 0),
      totalMediaBytes: Number(mediaManifest.totalBytes || 0)
    };
  }

  function createRestorePreviewIfAvailable(payload) {
    const restore = restorePreviewApi();
    if (restore && typeof restore.createRestorePreview === "function") {
      return restore.createRestorePreview(payload);
    }

    return {
      ok: true,
      canWrite: false,
      writesEnabled: false,
      writeMode: "preview-only",
      warnings: ["Restore preview helper is not loaded."],
      errors: []
    };
  }

  function createCurrentFileReadResult(fileName, text, options) {
    const opts = options || {};
    const payload = parseBackupJsonText(text);
    const classification = classifyFileName(fileName || "");
    const summary = summarizeBackupPayload(payload);
    const restorePreview = createRestorePreviewIfAvailable(payload);

    return {
      marker: MARKER,
      mode: MODE,
      kind: "buddies-who-study-current-backup-file-read-result",
      version: 1,
      createdAt: opts.createdAt || new Date().toISOString(),
      fileName: fileName || "",
      expectedCurrentFileName: CURRENT_FILE_NAME,
      classification: classification,
      summary: summary,
      payload: payload,
      restorePreview: restorePreview,
      canWrite: false,
      writesEnabled: false,
      writeMode: "preview-only",
      requiresExplicitUserAction: true,
      errors: Array.isArray(restorePreview.errors) ? restorePreview.errors : [],
      warnings: []
        .concat(classification.role === "stable-current" ? [] : [
          "This file is not named buddies-who-study-current.json. Treat it as a snapshot or incoming backup."
        ])
        .concat(Array.isArray(restorePreview.warnings) ? restorePreview.warnings : [])
    };
  }

  async function readBackupFileObject(file, options) {
    const opts = options || {};

    if (!opts.explicitUserAction) {
      throw new Error("Reading a backup file requires an explicit user action.");
    }

    if (!file || typeof file.text !== "function") {
      throw new Error("Backup file could not be read by this browser.");
    }

    const text = await file.text();
    return createCurrentFileReadResult(file.name || "", text, opts);
  }

  function chooseBackupFileForRead(options) {
    const opts = options || {};

    if (!opts.explicitUserAction) {
      return Promise.reject(new Error("Choosing a backup file requires an explicit user action."));
    }

    if (!root || !root.document) {
      return Promise.reject(new Error("File chooser is not available outside the browser."));
    }

    return new Promise(function chooseFile(resolve, reject) {
      const input = root.document.createElement("input");
      input.type = "file";
      input.accept = "application/json,.json";
      input.style.position = "fixed";
      input.style.left = "-9999px";
      input.style.top = "-9999px";

      input.addEventListener("change", function onChange() {
        const file = input.files && input.files[0] ? input.files[0] : null;
        input.remove();

        if (!file) {
          reject(new Error("No backup file was selected."));
          return;
        }

        readBackupFileObject(file, Object.assign({}, opts, { explicitUserAction: true }))
          .then(resolve)
          .catch(reject);
      }, { once: true });

      root.document.body.appendChild(input);
      input.click();
    });
  }

  function formatReadResultLines(result) {
    const r = result || {};
    const summary = r.summary || {};
    const classification = r.classification || {};
    const lines = [
      "Current backup file preview",
      "Mode: " + String(r.mode || MODE),
      "Can write: " + String(r.canWrite === true),
      "Selected file: " + String(r.fileName || ""),
      "Expected current file: " + String(r.expectedCurrentFileName || CURRENT_FILE_NAME),
      "Selected file role: " + String(classification.role || "unknown"),
      "Recommendation: " + String(classification.recommendation || ""),
      "",
      "Backup contents",
      "Backup version: " + String(summary.version || 0),
      "Created at: " + String(summary.createdAt || ""),
      "Docs: " + String(summary.docCount || 0),
      "Decks: " + String(summary.deckCount || 0),
      "Cards: " + String(summary.cardCount || 0),
      "Sessions: " + String(summary.sessionCount || 0),
      "Media items: " + String(summary.mediaCount || 0),
      "Total media bytes: " + String(summary.totalMediaBytes || 0),
      "",
      "Safety",
      "No data was restored.",
      "No data was merged.",
      "No file was overwritten.",
      "Writing stays disabled."
    ];

    if ((r.warnings || []).length) {
      lines.push("");
      lines.push("Warnings: " + String(r.warnings.length));
      (r.warnings || []).slice(0, 10).forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    if ((r.errors || []).length) {
      lines.push("");
      lines.push("Errors: " + String(r.errors.length));
      (r.errors || []).slice(0, 10).forEach(function addError(error) {
        lines.push("- " + error);
      });
    }

    return lines;
  }

  function formatReadResultText(result) {
    return formatReadResultLines(result).join("\n");
  }

  function escapeHtml(text) {
    return String(text || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function formatReadResultHtml(result) {
    return '<pre data-apc-local-backup-current-file-read-preview="true">' +
      escapeHtml(formatReadResultText(result)) +
      "</pre>";
  }

  const api = Object.freeze({
    MARKER: MARKER,
    BACKUP_KIND: BACKUP_KIND,
    CURRENT_FILE_NAME: CURRENT_FILE_NAME,
    MODE: MODE,
    classifyFileName: classifyFileName,
    parseBackupJsonText: parseBackupJsonText,
    docsObject: docsObject,
    summarizeBackupPayload: summarizeBackupPayload,
    createRestorePreviewIfAvailable: createRestorePreviewIfAvailable,
    createCurrentFileReadResult: createCurrentFileReadResult,
    readBackupFileObject: readBackupFileObject,
    chooseBackupFileForRead: chooseBackupFileForRead,
    formatReadResultLines: formatReadResultLines,
    formatReadResultText: formatReadResultText,
    formatReadResultHtml: formatReadResultHtml
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_ACCESS = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
