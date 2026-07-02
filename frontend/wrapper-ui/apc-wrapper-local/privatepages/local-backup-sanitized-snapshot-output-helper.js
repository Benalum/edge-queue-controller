(function localBackupSanitizedSnapshotOutputHelperR13O(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT_HELPER_R13O_SOURCE_ONLY";
  const MODE = "prepare-only";
  const SNAPSHOT_PREFIX = "buddies-who-study-local-backup-v2-";
  const SNAPSHOT_SUFFIX = ".json";

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function timestampForFileName(iso) {
    return String(iso || new Date().toISOString())
      .replace(/[:.]/g, "-")
      .replace(/Z$/, "Z");
  }

  function createSnapshotFileName(createdAt) {
    return SNAPSHOT_PREFIX + timestampForFileName(createdAt) + SNAPSHOT_SUFFIX;
  }

  function getSanitizedPayloadBuilder() {
    return root && root.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER
      ? root.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER
      : null;
  }

  function summarizePayload(payload) {
    const builder = getSanitizedPayloadBuilder();
    if (builder && typeof builder.summarizePayload === "function") {
      return builder.summarizePayload(payload || {});
    }

    const docs = payload && isObject(payload.docs) ? payload.docs : {};
    const cardsDoc = docs["study/cards/v1"] || {};
    const decksDoc = docs["study/decks/v1"] || {};
    const sessionsDoc = docs["study/sessions/v1"] || {};
    const mediaDoc = docs["study/media-manifest/v1"] || {};
    return {
      docCount: Object.keys(docs).length,
      deckCount: Array.isArray(decksDoc.decks) ? decksDoc.decks.length : 0,
      cardCount: Array.isArray(cardsDoc.cards) ? cardsDoc.cards.length : 0,
      sessionCount: Array.isArray(sessionsDoc.recentSessions) ? sessionsDoc.recentSessions.length : 0,
      mediaCount: Number(mediaDoc.mediaCount || 0),
      totalMediaBytes: Number(mediaDoc.totalBytes || 0)
    };
  }

  function prepareSanitizedSnapshotOutput(payload, options) {
    const createdAt = options && options.createdAt ? String(options.createdAt) : new Date().toISOString();
    const builder = getSanitizedPayloadBuilder();
    const warnings = [];
    const errors = [];

    if (!builder || typeof builder.createSanitizedBackupPayloadPreview !== "function") {
      errors.push("Sanitized payload builder is not loaded.");
      return {
        marker: MARKER,
        mode: MODE,
        canWrite: false,
        writesEnabled: false,
        downloadPrepared: false,
        fileName: createSnapshotFileName(createdAt),
        mimeType: "application/json",
        jsonText: "",
        byteLength: 0,
        removedFieldCount: 0,
        beforeSummary: summarizePayload(payload || {}),
        afterSummary: summarizePayload(payload || {}),
        warnings: warnings,
        errors: errors,
        serverUploadAllowed: false,
        ankiSourceMutationAllowed: false,
        localStudyRestoreWriteAllowed: false,
        sameFileWriteEnabled: false
      };
    }

    const preview = builder.createSanitizedBackupPayloadPreview(payload || {}, {
      createdAt: createdAt,
      updatedAt: options && options.updatedAt ? String(options.updatedAt) : createdAt
    });

    const sanitizedPayload = preview.sanitizedPayload || {};
    const jsonText = JSON.stringify(sanitizedPayload, null, 2) + "\n";

    return {
      marker: MARKER,
      mode: MODE,
      canWrite: false,
      writesEnabled: false,
      downloadPrepared: true,
      fileName: createSnapshotFileName(createdAt),
      mimeType: "application/json",
      jsonText: jsonText,
      byteLength: jsonText.length,
      removedFieldCount: Number(preview.removedFieldCount || 0),
      removedFromSanitizedPayload: preview.removedFromSanitizedPayload || [],
      beforeSummary: preview.beforeSummary || summarizePayload(payload || {}),
      afterSummary: preview.afterSummary || summarizePayload(sanitizedPayload),
      warnings: preview.warnings || [],
      errors: preview.errors || [],
      serverUploadAllowed: false,
      ankiSourceMutationAllowed: false,
      localStudyRestoreWriteAllowed: false,
      sameFileWriteEnabled: false
    };
  }

  function formatSanitizedSnapshotOutputLines(result) {
    const r = result || {};
    const before = r.beforeSummary || {};
    const after = r.afterSummary || {};
    const lines = [
      "Sanitized snapshot output",
      "Mode: " + String(r.mode || MODE),
      "Can write: " + String(r.canWrite === true),
      "Download prepared: " + String(r.downloadPrepared === true),
      "File name: " + String(r.fileName || ""),
      "Bytes: " + String(r.byteLength || 0),
      "Legacy fields removed: " + String(r.removedFieldCount || 0),
      "",
      "Before",
      String(before.deckCount || 0) + " decks, " + String(before.cardCount || 0) + " cards, " + String(before.sessionCount || 0) + " sessions, " + String(before.mediaCount || 0) + " media",
      "",
      "After",
      String(after.deckCount || 0) + " decks, " + String(after.cardCount || 0) + " cards, " + String(after.sessionCount || 0) + " sessions, " + String(after.mediaCount || 0) + " media",
      "",
      "Safety",
      "Prepare only. No file download was started by this helper.",
      "No data was saved, restored, merged, or overwritten."
    ];

    if ((r.removedFromSanitizedPayload || []).length) {
      lines.push("");
      lines.push("Fields removed from prepared snapshot payload:");
      (r.removedFromSanitizedPayload || []).forEach(function addRemoved(field) {
        lines.push("- " + field.path);
      });
    }

    if ((r.warnings || []).length) {
      lines.push("");
      lines.push("Warnings: " + String(r.warnings.length));
      (r.warnings || []).slice(0, 8).forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    if ((r.errors || []).length) {
      lines.push("");
      lines.push("Errors: " + String(r.errors.length));
      (r.errors || []).slice(0, 8).forEach(function addError(error) {
        lines.push("- " + error);
      });
    }

    return lines;
  }

  function formatSanitizedSnapshotOutputText(result) {
    return formatSanitizedSnapshotOutputLines(result).join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    SNAPSHOT_PREFIX: SNAPSHOT_PREFIX,
    SNAPSHOT_SUFFIX: SNAPSHOT_SUFFIX,
    timestampForFileName: timestampForFileName,
    createSnapshotFileName: createSnapshotFileName,
    summarizePayload: summarizePayload,
    prepareSanitizedSnapshotOutput: prepareSanitizedSnapshotOutput,
    formatSanitizedSnapshotOutputLines: formatSanitizedSnapshotOutputLines,
    formatSanitizedSnapshotOutputText: formatSanitizedSnapshotOutputText
  });

  root.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
