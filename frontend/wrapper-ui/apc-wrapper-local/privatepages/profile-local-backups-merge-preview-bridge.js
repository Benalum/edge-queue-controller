(function profileLocalBackupsMergePreviewBridgeR13A(root) {
  "use strict";

  const MARKER = "APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE_R13A_SOURCE_ONLY";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const WRITE_MODE = "preview-only";

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
      ok: Boolean((restorePreview ? restorePreview.ok !== false : true) && mergePlan && mergePlan.ok !== false),
      errors: []
        .concat(restorePreview && Array.isArray(restorePreview.errors) ? restorePreview.errors : [])
        .concat(mergePlan && Array.isArray(mergePlan.errors) ? mergePlan.errors : []),
      warnings: []
        .concat(restorePreview && Array.isArray(restorePreview.warnings) ? restorePreview.warnings : [])
        .concat(mergePlan && Array.isArray(mergePlan.warnings) ? mergePlan.warnings : [])
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
    return previewMergeBackupText(text, opts);
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

  function formatMergePreviewLines(preview) {
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
    ].concat(planLines);

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
