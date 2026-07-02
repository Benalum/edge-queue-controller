(function localBackupCurrentFileSavePlanR13I(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN_R13I_SOURCE_ONLY";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const SNAPSHOT_PREFIX = "buddies-who-study-local-backup-v2-";
  const MODE = "plan-only";

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function nowIso(options) {
    return options && options.createdAt ? String(options.createdAt) : new Date().toISOString();
  }

  function timestampForFileName(iso) {
    return String(iso || new Date().toISOString())
      .replace(/[:.]/g, "-")
      .replace(/Z$/, "Z");
  }

  function classifyFileName(fileName) {
    const name = String(fileName || "");
    if (name === CURRENT_FILE_NAME) {
      return {
        fileName: name,
        role: "stable-current",
        canBeMainMergeFile: true,
        shouldCreateNewSnapshot: false
      };
    }

    if (name.indexOf(SNAPSHOT_PREFIX) === 0 && name.endsWith(".json")) {
      return {
        fileName: name,
        role: "manual-snapshot",
        canBeMainMergeFile: false,
        shouldCreateNewSnapshot: false
      };
    }

    return {
      fileName: name,
      role: "unknown-json",
      canBeMainMergeFile: false,
      shouldCreateNewSnapshot: true
    };
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

  function createSnapshotFileName(createdAt) {
    return SNAPSHOT_PREFIX + timestampForFileName(createdAt) + ".json";
  }

  function createSavePlan(args) {
    const input = args || {};
    const selectedFileName = String(input.selectedFileName || "");
    const incomingPayload = input.incomingPayload || null;
    const currentPayload = input.currentPayload || null;
    const mergePreview = input.mergePreview || null;
    const createdAt = nowIso(input);
    const classification = classifyFileName(selectedFileName);
    const incomingSummary = summarizePayload(incomingPayload || {});
    const currentSummary = summarizePayload(currentPayload || {});
    const errors = [];
    const warnings = [];

    if (selectedFileName !== CURRENT_FILE_NAME) {
      errors.push("Selected file must be buddies-who-study-current.json before same-file saving can be enabled.");
    }

    if (!incomingPayload || !isObject(incomingPayload)) {
      errors.push("Incoming backup payload is missing.");
    }

    if (incomingPayload && incomingPayload.kind !== "buddies-who-study-local-backup") {
      errors.push("Incoming payload kind is not buddies-who-study-local-backup.");
    }

    if (incomingPayload && Number(incomingPayload.version || 0) !== 2) {
      warnings.push("Incoming backup is not version 2.");
    }

    if (!currentPayload || !isObject(currentPayload)) {
      warnings.push("Current backup payload is missing; first save would create the stable current file from the incoming backup.");
    }

    if (mergePreview && mergePreview.canWrite === true) {
      warnings.push("Merge preview reported canWrite=true, but R13I save plan keeps writing disabled.");
    }

    return {
      marker: MARKER,
      kind: "buddies-who-study-current-file-save-plan",
      version: 1,
      createdAt: createdAt,
      mode: MODE,
      selectedFileName: selectedFileName,
      expectedCurrentFileName: CURRENT_FILE_NAME,
      previousFileName: PREVIOUS_FILE_NAME,
      snapshotFileName: createSnapshotFileName(createdAt),
      classification: classification,
      incomingSummary: incomingSummary,
      currentSummary: currentSummary,
      mergePreviewSummary: mergePreview ? {
        adds: Number(mergePreview.adds || 0),
        updates: Number(mergePreview.updates || 0),
        skipped: Number(mergePreview.skipped || 0),
        conflicts: Number(mergePreview.conflicts || 0),
        canWrite: mergePreview.canWrite === true,
        writeMode: String(mergePreview.writeMode || "preview-only")
      } : null,
      requiredBeforeFutureWrite: [
        "User explicitly selects buddies-who-study-current.json.",
        "Browser creates or verifies a last-good copy plan for buddies-who-study-current.previous.json.",
        "Browser shows merge summary before any write.",
        "User confirms the exact file update.",
        "Write helper verifies current file role is stable-current immediately before writing.",
        "Write helper refuses timestamped snapshot files.",
        "Original Anki files are never modified.",
        "No server upload is performed."
      ],
      canWrite: false,
      writesEnabled: false,
      writeMode: "plan-only",
      requiresExplicitConfirmation: true,
      sameFileWriteEnabled: false,
      createWritableAllowed: false,
      overwriteAllowed: false,
      serverUploadAllowed: false,
      ankiSourceMutationAllowed: false,
      localStudyRestoreWriteAllowed: false,
      errors: errors,
      warnings: warnings
    };
  }

  function formatSavePlanLines(plan) {
    const p = plan || {};
    const incoming = p.incomingSummary || {};
    const current = p.currentSummary || {};
    const merge = p.mergePreviewSummary || {};
    const lines = [
      "Current backup save plan",
      "Mode: " + String(p.mode || MODE),
      "Can write: " + String(p.canWrite === true),
      "Selected file: " + String(p.selectedFileName || ""),
      "Expected file: " + String(p.expectedCurrentFileName || CURRENT_FILE_NAME),
      "Last-good file: " + String(p.previousFileName || PREVIOUS_FILE_NAME),
      "Snapshot file: " + String(p.snapshotFileName || ""),
      "",
      "Incoming backup",
      String(incoming.deckCount || 0) + " decks, " + String(incoming.cardCount || 0) + " cards, " + String(incoming.sessionCount || 0) + " sessions, " + String(incoming.mediaCount || 0) + " media",
      "",
      "Current backup",
      String(current.deckCount || 0) + " decks, " + String(current.cardCount || 0) + " cards, " + String(current.sessionCount || 0) + " sessions, " + String(current.mediaCount || 0) + " media",
      "",
      "Merge preview",
      String(merge.adds || 0) + " adds, " + String(merge.updates || 0) + " updates, " + String(merge.skipped || 0) + " skipped, " + String(merge.conflicts || 0) + " conflicts",
      "",
      "Safety",
      "Plan only. No file was saved, merged, restored, or overwritten.",
      "Writing stays disabled."
    ];

    if ((p.errors || []).length) {
      lines.push("");
      lines.push("Errors: " + String(p.errors.length));
      (p.errors || []).slice(0, 8).forEach(function addError(error) {
        lines.push("- " + error);
      });
    }

    if ((p.warnings || []).length) {
      lines.push("");
      lines.push("Warnings: " + String(p.warnings.length));
      (p.warnings || []).slice(0, 8).forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    return lines;
  }

  function formatSavePlanText(plan) {
    return formatSavePlanLines(plan).join("\n");
  }

  const api = Object.freeze({
    MARKER: MARKER,
    CURRENT_FILE_NAME: CURRENT_FILE_NAME,
    PREVIOUS_FILE_NAME: PREVIOUS_FILE_NAME,
    SNAPSHOT_PREFIX: SNAPSHOT_PREFIX,
    MODE: MODE,
    classifyFileName: classifyFileName,
    summarizePayload: summarizePayload,
    createSnapshotFileName: createSnapshotFileName,
    createSavePlan: createSavePlan,
    formatSavePlanLines: formatSavePlanLines,
    formatSavePlanText: formatSavePlanText
  });

  root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
