(function localBackupStableFilePlanR13C(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_STABLE_FILE_PLAN_R13C_SOURCE_ONLY";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const PLAN_KIND = "buddies-who-study-stable-current-backup-file-plan";
  const WRITE_MODE = "plan-only";

  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const MANIFEST_FILE_NAME = "manifest.json";
  const SNAPSHOT_PREFIX = "buddies-who-study-local-backup-v2-";
  const SNAPSHOT_EXTENSION = ".json";
  const SNAPSHOTS_DIR = "snapshots";
  const LAST_GOOD_DIR = "last-good";
  const STUDY_DIR = "study";
  const MEDIA_DIR = "media";
  const MEDIA_BLOBS_DIR = "media/blobs";

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function cloneJson(value) {
    if (value === undefined) return undefined;
    return JSON.parse(JSON.stringify(value));
  }

  function nowIso(options) {
    return options && options.createdAt ? options.createdAt : new Date().toISOString();
  }

  function safeTimestamp(value) {
    return String(value || new Date().toISOString()).replace(/[:.]/g, "-");
  }

  function snapshotFileName(createdAt) {
    return SNAPSHOT_PREFIX + safeTimestamp(createdAt) + SNAPSHOT_EXTENSION;
  }

  function stableBackupSetLayout() {
    return {
      rootLabel: "Buddies Who Study Backups",
      manifest: MANIFEST_FILE_NAME,
      current: CURRENT_FILE_NAME,
      previous: LAST_GOOD_DIR + "/" + PREVIOUS_FILE_NAME,
      snapshotsDir: SNAPSHOTS_DIR,
      studyDir: STUDY_DIR,
      mediaDir: MEDIA_DIR,
      mediaBlobsDir: MEDIA_BLOBS_DIR,
      stableFiles: [
        MANIFEST_FILE_NAME,
        CURRENT_FILE_NAME,
        LAST_GOOD_DIR + "/" + PREVIOUS_FILE_NAME,
        STUDY_DIR + "/cards.json",
        STUDY_DIR + "/decks.json",
        STUDY_DIR + "/progress.json",
        STUDY_DIR + "/sessions.json",
        MEDIA_DIR + "/manifest.json"
      ]
    };
  }

  function isStableCurrentFileName(fileName) {
    return String(fileName || "") === CURRENT_FILE_NAME;
  }

  function isPreviousCurrentFileName(fileName) {
    const name = String(fileName || "");
    return name === PREVIOUS_FILE_NAME || name === LAST_GOOD_DIR + "/" + PREVIOUS_FILE_NAME;
  }

  function isSnapshotFileName(fileName) {
    const name = String(fileName || "");
    return name.indexOf(SNAPSHOT_PREFIX) === 0 && name.endsWith(SNAPSHOT_EXTENSION);
  }

  function classifyBackupFileName(fileName) {
    const name = String(fileName || "");

    if (isStableCurrentFileName(name)) {
      return {
        fileName: name,
        role: "stable-current",
        canBeMainMergeFile: true,
        shouldCreateNewSnapshot: false,
        recommendation: "Use this as the normal file to open, preview, merge, and update."
      };
    }

    if (isPreviousCurrentFileName(name)) {
      return {
        fileName: name,
        role: "last-good-previous",
        canBeMainMergeFile: false,
        shouldCreateNewSnapshot: false,
        recommendation: "Use this only as a rollback copy, not as the main current file."
      };
    }

    if (isSnapshotFileName(name)) {
      return {
        fileName: name,
        role: "manual-snapshot",
        canBeMainMergeFile: false,
        shouldCreateNewSnapshot: false,
        recommendation: "Keep this as a snapshot archive. Import or preview it, then merge into buddies-who-study-current.json."
      };
    }

    return {
      fileName: name,
      role: "unknown-json",
      canBeMainMergeFile: false,
      shouldCreateNewSnapshot: true,
      recommendation: "Preview this file first. If valid, merge into buddies-who-study-current.json."
    };
  }

  function backupEnvelope(value) {
    const payload = isObject(value) ? cloneJson(value) : {};
    payload.kind = payload.kind || BACKUP_KIND;
    payload.version = Number(payload.version || 1);
    payload.docs = isObject(payload.docs) || Array.isArray(payload.docs) ? payload.docs : {};
    return payload;
  }

  function mergePlannerApi() {
    return root && root.APC_LOCAL_BACKUP_MERGE_PLANNER
      ? root.APC_LOCAL_BACKUP_MERGE_PLANNER
      : null;
  }

  function createMergePlanIfAvailable(currentPayload, incomingPayload, options) {
    const planner = mergePlannerApi();
    if (planner && typeof planner.createMergePlan === "function") {
      return planner.createMergePlan(currentPayload || {}, incomingPayload || {}, {
        createdAt: nowIso(options)
      });
    }

    return {
      ok: true,
      writeMode: "preview-only",
      canWrite: false,
      writesEnabled: false,
      warnings: ["Backup merge planner is not loaded."],
      errors: [],
      totals: {
        adds: 0,
        updates: 0,
        skips: 0,
        conflicts: 0
      }
    };
  }

  function createStableCurrentFilePlan(options) {
    const opts = options || {};
    const createdAt = nowIso(opts);
    const currentPayload = backupEnvelope(opts.currentPayload || {});
    const incomingPayload = backupEnvelope(opts.incomingPayload || {});
    const selectedFileName = opts.selectedFileName || CURRENT_FILE_NAME;
    const selectedFile = classifyBackupFileName(selectedFileName);
    const mergePlan = createMergePlanIfAvailable(currentPayload, incomingPayload, opts);

    const warnings = [];
    if (!selectedFile.canBeMainMergeFile) {
      warnings.push("Selected file is not the stable current backup file. Merge should target " + CURRENT_FILE_NAME + ".");
    }
    if (selectedFile.role === "manual-snapshot") {
      warnings.push("Timestamped backup files should remain snapshots, not the normal file that gets updated.");
    }
    if (incomingPayload.kind !== BACKUP_KIND) {
      warnings.push("Incoming file is not a recognized Buddies Who Study backup kind.");
    }

    return {
      marker: MARKER,
      kind: PLAN_KIND,
      version: 1,
      createdAt: createdAt,
      writeMode: WRITE_MODE,
      canWrite: false,
      writesEnabled: false,
      requiresExplicitConfirmation: true,
      overwriteExistingLocalData: false,
      normalCurrentFileName: CURRENT_FILE_NAME,
      manualSnapshotFileName: snapshotFileName(createdAt),
      selectedFile: selectedFile,
      layout: stableBackupSetLayout(),
      mergePlan: mergePlan,
      futureFlow: [
        "Choose or create a Buddies Who Study Backups folder.",
        "Open " + CURRENT_FILE_NAME + " when it exists.",
        "If only a timestamped backup exists, preview it as an incoming snapshot.",
        "Create a merge preview against current browser-local Study data.",
        "Show adds, updates, skips, and conflicts before any future write.",
        "Only after explicit confirmation, save a safety copy to " + LAST_GOOD_DIR + "/" + PREVIOUS_FILE_NAME + ".",
        "Only after explicit confirmation, update " + CURRENT_FILE_NAME + ".",
        "Optionally copy timestamped snapshots into " + SNAPSHOTS_DIR + "/."
      ],
      browserDownloadRule: {
        normalDownloadsMayCreateDuplicates: true,
        stableFileUpdatesRequireUserSelectedFileOrFolder: true,
        duplicateExample: [
          "buddies-who-study-current.json",
          "buddies-who-study-current (1).json",
          "buddies-who-study-current (2).json"
        ]
      },
      errors: [],
      warnings: warnings.concat(Array.isArray(mergePlan.warnings) ? mergePlan.warnings : [])
    };
  }

  function formatStableCurrentFilePlanLines(plan) {
    const p = plan || {};
    const selected = p.selectedFile || {};
    const merge = p.mergePlan || {};
    const totals = merge.totals || {};

    const lines = [
      "Stable backup file plan",
      "Write mode: " + String(p.writeMode || WRITE_MODE),
      "Can write: " + String(p.canWrite === true),
      "Normal file: " + String(p.normalCurrentFileName || CURRENT_FILE_NAME),
      "Selected file role: " + String(selected.role || "unknown"),
      "Selected file recommendation: " + String(selected.recommendation || ""),
      "Manual snapshot example: " + String(p.manualSnapshotFileName || ""),
      "",
      "Merge preview totals",
      "Adds: " + String(totals.adds || 0),
      "Updates: " + String(totals.updates || 0),
      "Skipped: " + String(totals.skips || 0),
      "Conflicts: " + String(totals.conflicts || 0),
      "",
      "Future flow"
    ];

    (p.futureFlow || []).forEach(function addStep(step, index) {
      lines.push(String(index + 1) + ". " + step);
    });

    if ((p.warnings || []).length) {
      lines.push("");
      lines.push("Warnings: " + String(p.warnings.length));
      (p.warnings || []).slice(0, 10).forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    if ((p.errors || []).length) {
      lines.push("");
      lines.push("Errors: " + String(p.errors.length));
      (p.errors || []).slice(0, 10).forEach(function addError(error) {
        lines.push("- " + error);
      });
    }

    return lines;
  }

  function formatStableCurrentFilePlanText(plan) {
    return formatStableCurrentFilePlanLines(plan).join("\n");
  }

  function escapeHtml(text) {
    return String(text || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function formatStableCurrentFilePlanHtml(plan) {
    return '<pre data-apc-local-backup-stable-file-plan-preview="true">' +
      escapeHtml(formatStableCurrentFilePlanText(plan)) +
      "</pre>";
  }

  const api = Object.freeze({
    MARKER: MARKER,
    BACKUP_KIND: BACKUP_KIND,
    PLAN_KIND: PLAN_KIND,
    WRITE_MODE: WRITE_MODE,
    CURRENT_FILE_NAME: CURRENT_FILE_NAME,
    PREVIOUS_FILE_NAME: PREVIOUS_FILE_NAME,
    MANIFEST_FILE_NAME: MANIFEST_FILE_NAME,
    SNAPSHOT_PREFIX: SNAPSHOT_PREFIX,
    SNAPSHOTS_DIR: SNAPSHOTS_DIR,
    LAST_GOOD_DIR: LAST_GOOD_DIR,
    stableBackupSetLayout: stableBackupSetLayout,
    snapshotFileName: snapshotFileName,
    isStableCurrentFileName: isStableCurrentFileName,
    isPreviousCurrentFileName: isPreviousCurrentFileName,
    isSnapshotFileName: isSnapshotFileName,
    classifyBackupFileName: classifyBackupFileName,
    backupEnvelope: backupEnvelope,
    createStableCurrentFilePlan: createStableCurrentFilePlan,
    formatStableCurrentFilePlanLines: formatStableCurrentFilePlanLines,
    formatStableCurrentFilePlanText: formatStableCurrentFilePlanText,
    formatStableCurrentFilePlanHtml: formatStableCurrentFilePlanHtml
  });

  root.APC_LOCAL_BACKUP_STABLE_FILE_PLAN = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
