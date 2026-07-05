(function currentBackupSaveWriterPlanR13S(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER_R13S_SOURCE_ONLY";
  const MODE = "source-only-plan";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const BACKUP_VERSION = 2;

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function cloneJson(value) {
    if (value === undefined) return undefined;
    return JSON.parse(JSON.stringify(value));
  }

  function fileNameFromCandidate(candidate) {
    if (typeof candidate === "string") return candidate;
    if (candidate && typeof candidate.name === "string") return candidate.name;
    if (candidate && typeof candidate.fileName === "string") return candidate.fileName;
    return "";
  }

  function isExpectedCurrentFileName(fileName) {
    return String(fileName || "") === CURRENT_FILE_NAME;
  }

  function getSanitizedSnapshotOutputHelper() {
    return root && root.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT
      ? root.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT
      : null;
  }

  function summarizePayload(payload) {
    const helperApi = getSanitizedSnapshotOutputHelper();
    if (helperApi && typeof helperApi.summarizePayload === "function") {
      return helperApi.summarizePayload(payload || {});
    }

    const docs = payload && isObject(payload.docs) ? payload.docs : {};
    const decksDoc = docs["study/decks/v1"] || {};
    const cardsDoc = docs["study/cards/v1"] || {};
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

  function findLegacyBackendCacheKeys(payload) {
    const docs = payload && isObject(payload.docs) ? payload.docs : {};
    const storeDoc = docs["study/store-state/v1"];
    const state = storeDoc && isObject(storeDoc.state) ? storeDoc.state : null;
    const legacyKeys = ["backendProgress", "backendReviewSummary", "backendSessions", "backendSyncedAt"];

    if (!state) return [];

    return legacyKeys
      .filter(function hasKey(key) {
        return Object.prototype.hasOwnProperty.call(state, key);
      })
      .map(function toPath(key) {
        return "study/store-state/v1.state." + key;
      });
  }

  function createCurrentBackupSaveWriterPlan(input, options) {
    const opts = options || {};
    const source = input || {};
    const selectedFileName = fileNameFromCandidate(
      source.selectedFile ||
      source.selectedFileHandle ||
      source.file ||
      source.fileHandle ||
      source.selectedFileName ||
      opts.selectedFileName ||
      ""
    );

    const payload = source.payload || source.currentPayload || source.backupPayload || source;
    const payloadClone = cloneJson(payload || {});
    const now = opts.createdAt || opts.updatedAt || new Date().toISOString();
    const errors = [];
    const warnings = [];
    const selectedFileAllowed = isExpectedCurrentFileName(selectedFileName);
    const helperApi = getSanitizedSnapshotOutputHelper();

    if (!selectedFileAllowed) {
      errors.push("Refusing current backup save plan because selected file is not " + CURRENT_FILE_NAME + ".");
    }

    if (!helperApi || typeof helperApi.prepareSanitizedSnapshotOutput !== "function") {
      errors.push("Sanitized snapshot output helper is not loaded.");
    }

    let prepared = null;
    if (helperApi && typeof helperApi.prepareSanitizedSnapshotOutput === "function") {
      prepared = helperApi.prepareSanitizedSnapshotOutput(payloadClone || {}, {
        createdAt: now,
        updatedAt: now
      });

      if (!prepared || prepared.downloadPrepared !== true) {
        errors.push("Sanitized backup payload was not prepared.");
      } else if (prepared.errors && prepared.errors.length) {
        prepared.errors.forEach(function addPreparedError(error) {
          errors.push(error);
        });
      }
    }

    const sanitizedJsonText = prepared && prepared.jsonText ? String(prepared.jsonText) : "";
    const sanitizedLegacyKeys = sanitizedJsonText
      ? findLegacyBackendCacheKeys(JSON.parse(sanitizedJsonText))
      : [];

    if (sanitizedLegacyKeys.length) {
      errors.push("Sanitized payload still contains legacy backend cache fields.");
    }

    if (prepared && Number(prepared.removedFieldCount || 0) > 0) {
      warnings.push("Legacy backend cache fields will be excluded from the current backup output.");
    }

    const readyForFutureWriteEnablement = selectedFileAllowed &&
      errors.length === 0 &&
      Boolean(sanitizedJsonText);

    return {
      marker: MARKER,
      mode: MODE,
      canWrite: false,
      writesEnabled: false,
      sameFileWriteEnabled: false,
      currentFileWriteEnabled: false,
      previousFileWriteEnabled: false,
      readyForFutureWriteEnablement: readyForFutureWriteEnablement,
      selectedFileName: selectedFileName,
      selectedFileAllowed: selectedFileAllowed,
      expectedCurrentFileName: CURRENT_FILE_NAME,
      previousFileName: PREVIOUS_FILE_NAME,
      previousFileMustBeWrittenFirst: true,
      currentFileMustBeWrittenSecond: true,
      replaceCurrentFileOnlyAfterPreviousFile: true,
      backupKind: BACKUP_KIND,
      backupVersion: BACKUP_VERSION,
      generatedAt: now,
      beforeLegacyFieldPaths: findLegacyBackendCacheKeys(payloadClone || {}),
      afterLegacyFieldPaths: sanitizedLegacyKeys,
      removedFieldCount: prepared ? Number(prepared.removedFieldCount || 0) : 0,
      beforeSummary: prepared && prepared.beforeSummary ? prepared.beforeSummary : summarizePayload(payloadClone || {}),
      afterSummary: prepared && prepared.afterSummary ? prepared.afterSummary : summarizePayload(payloadClone || {}),
      sanitizedJsonText: sanitizedJsonText,
      sanitizedByteLength: sanitizedJsonText.length,
      writeSequencePlan: [
        "Refuse unless selected file name is " + CURRENT_FILE_NAME + ".",
        "Prepare sanitized local-only backup JSON in memory.",
        "Prepare last-good copy named " + PREVIOUS_FILE_NAME + " before replacing the current file.",
        "Replace " + CURRENT_FILE_NAME + " only after last-good preparation succeeds.",
        "Verify readback JSON shape and absence of legacy backend cache fields."
      ],
      warnings: warnings,
      errors: errors,
      serverUploadAllowed: false,
      ankiSourceMutationAllowed: false,
      localStudyRestoreWriteAllowed: false,
      currentBrowserDataMutationAllowed: false
    };
  }

  function formatCurrentBackupSaveWriterPlanLines(plan) {
    const p = plan || {};
    const before = p.beforeSummary || {};
    const after = p.afterSummary || {};
    const lines = [
      "Current backup save writer plan",
      "Mode: " + String(p.mode || MODE),
      "Can write: " + String(p.canWrite === true),
      "Writes enabled: " + String(p.writesEnabled === true),
      "Same-file write enabled: " + String(p.sameFileWriteEnabled === true),
      "Selected file: " + String(p.selectedFileName || ""),
      "Expected current file: " + CURRENT_FILE_NAME,
      "Last-good file: " + PREVIOUS_FILE_NAME,
      "Ready for future write enablement: " + String(p.readyForFutureWriteEnablement === true),
      "",
      "Before",
      String(before.deckCount || 0) + " decks, " + String(before.cardCount || 0) + " cards, " + String(before.sessionCount || 0) + " sessions, " + String(before.mediaCount || 0) + " media",
      "",
      "After",
      String(after.deckCount || 0) + " decks, " + String(after.cardCount || 0) + " cards, " + String(after.sessionCount || 0) + " sessions, " + String(after.mediaCount || 0) + " media",
      "",
      "Legacy backend cache fields removed: " + String(p.removedFieldCount || 0),
      "",
      "Safety",
      "Source-only plan. No file was saved, replaced, merged, restored, or overwritten.",
      "Writing stays disabled."
    ];

    if ((p.writeSequencePlan || []).length) {
      lines.push("");
      lines.push("Future guarded sequence:");
      (p.writeSequencePlan || []).forEach(function addStep(step, index) {
        lines.push(String(index + 1) + ". " + step);
      });
    }

    if ((p.beforeLegacyFieldPaths || []).length) {
      lines.push("");
      lines.push("Legacy fields that would be excluded:");
      (p.beforeLegacyFieldPaths || []).forEach(function addPath(path) {
        lines.push("- " + path);
      });
    }

    if ((p.warnings || []).length) {
      lines.push("");
      lines.push("Warnings: " + String(p.warnings.length));
      (p.warnings || []).forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    if ((p.errors || []).length) {
      lines.push("");
      lines.push("Errors: " + String(p.errors.length));
      (p.errors || []).forEach(function addError(error) {
        lines.push("- " + error);
      });
    }

    return lines;
  }

  function formatCurrentBackupSaveWriterPlanText(plan) {
    return formatCurrentBackupSaveWriterPlanLines(plan).join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    MODE: MODE,
    CURRENT_FILE_NAME: CURRENT_FILE_NAME,
    PREVIOUS_FILE_NAME: PREVIOUS_FILE_NAME,
    isExpectedCurrentFileName: isExpectedCurrentFileName,
    summarizePayload: summarizePayload,
    findLegacyBackendCacheKeys: findLegacyBackendCacheKeys,
    createCurrentBackupSaveWriterPlan: createCurrentBackupSaveWriterPlan,
    formatCurrentBackupSaveWriterPlanLines: formatCurrentBackupSaveWriterPlanLines,
    formatCurrentBackupSaveWriterPlanText: formatCurrentBackupSaveWriterPlanText
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
