(function profileLocalBackupsMergePreviewBridgeR13A(root) {
  "use strict";

  const MARKER = "APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE_R13A_SOURCE_ONLY";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const WRITE_MODE = "preview-only";
  const COMPACT_PREVIEW_TEXT_MARKER_R13H = "APC_PROFILE_LOCAL_BACKUPS_COMPACT_PREVIEW_TEXT_R13H";
  const STABLE_FILE_PLAN_PREVIEW_MARKER_R13D = "APC_PROFILE_LOCAL_BACKUPS_STABLE_FILE_PLAN_PREVIEW_R13D";

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function cloneJson(value) {
    if (value === undefined) return undefined;
    return JSON.parse(JSON.stringify(value));
  }

  function isPromiseLike(value) {
    return value && typeof value.then === "function";
  }

  async function awaitMaybe(value) {
    return isPromiseLike(value) ? await value : value;
  }

  function mergePlannerApi() {
    return root && root.APC_LOCAL_BACKUP_MERGE_PLANNER
      ? root.APC_LOCAL_BACKUP_MERGE_PLANNER
      : null;
  }

  function backupPanelApi() {
    return root && root.APC_PROFILE_LOCAL_BACKUPS_PANEL
      ? root.APC_PROFILE_LOCAL_BACKUPS_PANEL
      : null;
  }

  function restorePreviewApi() {
    return root && root.APC_LOCAL_BACKUP_RESTORE_PREVIEW
      ? root.APC_LOCAL_BACKUP_RESTORE_PREVIEW
      : null;
  }



  function stableFilePlanApiR13D() {
    return root && root.APC_LOCAL_BACKUP_STABLE_FILE_PLAN
      ? root.APC_LOCAL_BACKUP_STABLE_FILE_PLAN
      : null;
  }

  function createStableFilePlanIfAvailableR13D(currentPayload, incomingPayload, options) {
    const stableApi = stableFilePlanApiR13D();
    if (stableApi && typeof stableApi.createStableCurrentFilePlan === "function") {
      return stableApi.createStableCurrentFilePlan({
        currentPayload: currentPayload || {},
        incomingPayload: incomingPayload || {},
        selectedFileName: options && options.selectedFileName ? options.selectedFileName : "",
        createdAt: options && options.createdAt ? options.createdAt : new Date().toISOString()
      });
    }

    return {
      ok: true,
      writeMode: "plan-only",
      canWrite: false,
      writesEnabled: false,
      normalCurrentFileName: "buddies-who-study-current.json",
      warnings: ["Stable current backup file plan is not loaded."],
      errors: []
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

  async function buildCurrentBackupPayload(options) {
    const opts = options || {};
    if (isObject(opts.currentPayload)) {
      return cloneJson(opts.currentPayload);
    }

    const panel = backupPanelApi();
    if (panel && typeof panel.buildBackupPayload === "function") {
      return await awaitMaybe(panel.buildBackupPayload({
        createdAt: opts.createdAt || new Date().toISOString()
      }));
    }

    return {
      kind: BACKUP_KIND,
      version: 2,
      createdAt: opts.createdAt || new Date().toISOString(),
      docs: {},
      privacy: {
        serverUpload: false,
        ankiSourceMutation: false,
        sourceMutation: false,
        localOnly: true,
        originalAnkiBytesIncluded: false
      }
    };
  }

  function createRestorePreviewIfAvailable(incomingPayload) {
    const restore = restorePreviewApi();
    if (restore && typeof restore.createRestorePreview === "function") {
      return restore.createRestorePreview(incomingPayload);
    }

    return {
      ok: true,
      canWrite: false,
      writesEnabled: false,
      writeMode: WRITE_MODE,
      warnings: ["Restore preview helper is not loaded."],
      errors: []
    };
  }

  async function createMergePreviewFromPayloads(currentPayload, incomingPayload, options) {
    const planner = mergePlannerApi();
    if (!planner || typeof planner.createMergePlan !== "function") {
      throw new Error("Backup merge planner is not loaded.");
    }

    const restorePreview = createRestorePreviewIfAvailable(incomingPayload);
    const mergePlan = planner.createMergePlan(currentPayload || {}, incomingPayload || {}, {
      createdAt: options && options.createdAt ? options.createdAt : new Date().toISOString()
    });
    const stableFilePlan = createStableFilePlanIfAvailableR13D(currentPayload, incomingPayload, options || {});

    return {
      marker: MARKER,
      kind: "buddies-who-study-profile-backup-merge-preview",
      version: 1,
      createdAt: options && options.createdAt ? options.createdAt : new Date().toISOString(),
      writeMode: WRITE_MODE,
      canWrite: false,
      writesEnabled: false,
      requiresExplicitConfirmation: true,
      overwriteExistingLocalData: false,
      restorePreview: restorePreview,
      mergePlan: mergePlan,
      stableFilePlan: stableFilePlan,
      ok: Boolean((restorePreview ? restorePreview.ok !== false : true) && mergePlan && mergePlan.ok !== false),
      errors: []
        .concat(restorePreview && Array.isArray(restorePreview.errors) ? restorePreview.errors : [])
        .concat(mergePlan && Array.isArray(mergePlan.errors) ? mergePlan.errors : [])
        .concat(stableFilePlan && Array.isArray(stableFilePlan.errors) ? stableFilePlan.errors : []),
      warnings: []
        .concat(restorePreview && Array.isArray(restorePreview.warnings) ? restorePreview.warnings : [])
        .concat(mergePlan && Array.isArray(mergePlan.warnings) ? mergePlan.warnings : [])
        .concat(stableFilePlan && Array.isArray(stableFilePlan.warnings) ? stableFilePlan.warnings : [])
    };
  }

  async function createMergePreviewFromIncomingBackup(incomingPayload, options) {
    const currentPayload = await buildCurrentBackupPayload(options || {});
    return createMergePreviewFromPayloads(currentPayload, incomingPayload, options || {});
  }

  async function previewMergeBackupText(text, options) {
    const incomingPayload = parseBackupJsonText(text);
    return createMergePreviewFromIncomingBackup(incomingPayload, options || {});
  }

  async function previewMergeBackupFile(file, options) {
    const opts = options || {};

    if (!opts.explicitUserAction) {
      throw new Error("Previewing a backup file requires an explicit user action.");
    }

    if (!file || typeof file.text !== "function") {
      throw new Error("Backup file could not be read by this browser.");
    }

    const text = await file.text();
    return previewMergeBackupText(text, Object.assign({}, opts, {
      selectedFileName: file && file.name ? file.name : undefined
    }));
  }

  function chooseBackupFileForMergePreview(options) {
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

        previewMergeBackupFile(file, Object.assign({}, opts, { explicitUserAction: true }))
          .then(resolve)
          .catch(reject);
      }, { once: true });

      root.document.body.appendChild(input);
      input.click();
    });
  }



  function stableFilePlanLinesForPreviewR13D(preview) {
    const stable = preview && preview.stableFilePlan ? preview.stableFilePlan : null;
    if (!stable) return [];

    const selected = stable.selectedFile || {};
    const lines = [
      "",
      "Backup file naming",
      "Normal file to keep using: " + String(stable.normalCurrentFileName || "buddies-who-study-current.json"),
      "Selected file role: " + String(selected.role || "unknown"),
      "Recommendation: " + String(selected.recommendation || "Use the stable current file for normal backup merges."),
      "Timestamped downloads should stay manual snapshots.",
      "Normal browser downloads may create duplicate files like buddies-who-study-current (1).json.",
      "Updating the same file later requires a user-selected file or folder.",
      "No data was restored or overwritten."
    ];

    return lines;
  }


  function formatMergePreviewLinesVerboseR13H(preview) {
    const p = preview || {};
    const plan = p.mergePlan || {};
    const planner = mergePlannerApi();
    const planLines = planner && typeof planner.formatMergePlanLines === "function"
      ? planner.formatMergePlanLines(plan)
      : [
          "Backup merge preview",
          "Write mode: " + (p.writeMode || WRITE_MODE),
          "Can write: " + String(p.canWrite === true)
        ];

    const lines = [
      "Profile backup preview",
      "Write mode: " + (p.writeMode || WRITE_MODE),
      "Can write: " + String(p.canWrite === true),
      "Restore preview ok: " + String(p.restorePreview ? p.restorePreview.ok !== false : true),
      "Merge preview ok: " + String(plan ? plan.ok !== false : false),
      ""
    ].concat(planLines).concat(stableFilePlanLinesForPreviewR13D(p));

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

  function formatMergePreviewLines(preview) {
    const verboseLines = typeof formatMergePreviewLinesVerboseR13H === "function"
      ? formatMergePreviewLinesVerboseR13H(preview)
      : [];

    function valueAfter(prefix, fallback) {
      const found = verboseLines.find(function findLine(line) {
        return String(line || "").indexOf(prefix) === 0;
      });
      if (!found) return fallback || "";
      return String(found).slice(prefix.length).trim();
    }

    function collectBulletsAfter(prefix) {
      const out = [];
      const start = verboseLines.findIndex(function findLine(line) {
        return String(line || "").indexOf(prefix) === 0;
      });
      if (start < 0) return out;
      for (let i = start + 1; i < verboseLines.length; i += 1) {
        const line = String(verboseLines[i] || "");
        if (line.indexOf("- ") === 0) out.push(line);
        else if (line.trim() === "") continue;
        else break;
      }
      return out;
    }

    const writeMode = valueAfter("Write mode:", "preview-only");
    const canWrite = valueAfter("Can write:", "false");
    const version = valueAfter("Incoming version:", "");
    const adds = valueAfter("Adds:", "0");
    const updates = valueAfter("Updates:", "0");
    const skipped = valueAfter("Skipped:", "0");
    const conflicts = valueAfter("Conflicts:", "0");
    const deckAdds = valueAfter("Deck adds:", "0");
    const cardAdds = valueAfter("Card adds:", "0");
    const sessionAdds = valueAfter("Session adds:", "0");
    const mediaAdds = valueAfter("Media adds:", "0");
    const currentFile = valueAfter("Normal file to keep using:", "buddies-who-study-current.json");
    const selectedRole = valueAfter("Selected file role:", "unknown");
    const recommendation = valueAfter("Recommendation:", "");
    const warningsCount = valueAfter("Warnings:", "0");
    const errorsCount = valueAfter("Errors:", "0");
    const warnings = collectBulletsAfter("Warnings:");
    const errors = collectBulletsAfter("Errors:");

    const lines = [
      "Backup preview",
      "Mode: " + writeMode,
      "Can write: " + canWrite,
      "Incoming version: " + version,
      "",
      "Merge plan summary",
      "Changes: " + adds + " adds, " + updates + " updates, " + skipped + " skipped, " + conflicts + " conflicts",
      "New items: " + deckAdds + " decks, " + cardAdds + " cards, " + sessionAdds + " sessions, " + mediaAdds + " media",
      "",
      "File naming",
      "Current file: " + currentFile,
      "Selected file role: " + selectedRole,
      recommendation ? "Recommendation: " + recommendation : "Recommendation: Preview first, then use the current file for normal backup updates.",
      "",
      "Safety",
      "Preview only. No data was restored or overwritten.",
      "Writing stays disabled."
    ];

    if (warningsCount !== "0" || warnings.length) {
      lines.push("");
      lines.push("Warnings: " + warningsCount);
      warnings.slice(0, 5).forEach(function addWarning(line) {
        lines.push(line);
      });
    }

    if (errorsCount !== "0" || errors.length) {
      lines.push("");
      lines.push("Errors: " + errorsCount);
      errors.slice(0, 5).forEach(function addError(line) {
        lines.push(line);
      });
    }

    return lines;
  }

  function formatMergePreviewText(preview) {
    return formatMergePreviewLines(preview).join("\n");
  }

  function escapeHtml(text) {
    return String(text || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function formatMergePreviewHtml(preview) {
    return '<pre data-apc-local-backup-profile-merge-preview="true">' +
      escapeHtml(formatMergePreviewText(preview)) +
      "</pre>";
  }

  const api = Object.freeze({
    MARKER: MARKER,
    BACKUP_KIND: BACKUP_KIND,
    WRITE_MODE: WRITE_MODE,
    parseBackupJsonText: parseBackupJsonText,
    buildCurrentBackupPayload: buildCurrentBackupPayload,
    createRestorePreviewIfAvailable: createRestorePreviewIfAvailable,
    createMergePreviewFromPayloads: createMergePreviewFromPayloads,
    createMergePreviewFromIncomingBackup: createMergePreviewFromIncomingBackup,
    previewMergeBackupText: previewMergeBackupText,
    previewMergeBackupFile: previewMergeBackupFile,
    chooseBackupFileForMergePreview: chooseBackupFileForMergePreview,
    formatMergePreviewLines: formatMergePreviewLines,
    formatMergePreviewText: formatMergePreviewText,
    formatMergePreviewHtml: formatMergePreviewHtml
  });

  root.APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
