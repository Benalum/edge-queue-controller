/* APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE_R12U_START */
(function attachProfileLocalBackupsRestorePreviewBridge(root) {
  "use strict";

  const MARKER = "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE_R12U_SOURCE_ONLY";
  const VERSION = 1;
  const MAX_PREVIEW_BYTES = 10 * 1024 * 1024;

  function restoreApi() {
    return root && root.APC_LOCAL_BACKUP_RESTORE_PREVIEW ? root.APC_LOCAL_BACKUP_RESTORE_PREVIEW : null;
  }

  function exportApi() {
    return root && root.APC_LOCAL_BACKUP_MEDIA_EXPORT ? root.APC_LOCAL_BACKUP_MEDIA_EXPORT : null;
  }

  function stringOrEmpty(value) {
    return value === undefined || value === null ? "" : String(value);
  }

  function requireExplicitUserAction(options) {
    const opts = options || {};
    if (opts.explicitUserAction !== true) {
      throw new Error("Backup restore preview requires explicit user action.");
    }
  }

  function escapeText(value) {
    return stringOrEmpty(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function validateBackupFileLike(file, options) {
    const opts = options || {};
    const maxBytes = Number(opts.maxBytes || MAX_PREVIEW_BYTES);
    const errors = [];
    const warnings = [];

    if (!file || typeof file !== "object") {
      errors.push("Choose a backup JSON file first.");
      return { ok: false, errors: errors, warnings: warnings };
    }

    const name = stringOrEmpty(file.name);
    if (name && !name.toLowerCase().endsWith(".json")) {
      warnings.push("This file does not end with .json.");
    }

    if (Number(file.size || 0) <= 0) {
      errors.push("Backup file is empty.");
    }

    if (Number(file.size || 0) > maxBytes) {
      errors.push("Backup file is larger than the preview limit.");
    }

    if (typeof file.text !== "function") {
      errors.push("This browser file object cannot be read as text.");
    }

    return { ok: errors.length === 0, errors: errors, warnings: warnings };
  }

  async function previewBackupFile(file, options) {
    requireExplicitUserAction(options);

    const validation = validateBackupFileLike(file, options);
    if (!validation.ok) {
      return {
        ok: false,
        canWrite: false,
        marker: MARKER,
        errors: validation.errors,
        warnings: validation.warnings,
        file: {
          name: stringOrEmpty(file && file.name),
          size: Number(file && file.size || 0),
          type: stringOrEmpty(file && file.type)
        },
        summary: {},
        restorePlan: {
          writesEnabled: false,
          writeMode: "preview-only",
          requiresExplicitConfirmation: true,
          overwriteExistingLocalData: false
        }
      };
    }

    const api = restoreApi();
    if (!api || typeof api.previewBackupText !== "function") {
      throw new Error("Backup restore preview helper is not loaded.");
    }

    const text = await file.text();
    const preview = api.previewBackupText(text, options);

    if (typeof api.assertPreviewOnly === "function") {
      api.assertPreviewOnly(preview);
    }

    preview.file = {
      name: stringOrEmpty(file.name),
      size: Number(file.size || 0),
      type: stringOrEmpty(file.type)
    };

    return preview;
  }

  function buildPreviewSummaryLines(preview) {
    const item = preview || {};
    const summary = item.summary || {};
    const study = summary.study || {};
    const media = summary.media || {};
    const lines = [];

    lines.push("Backup preview");
    lines.push("Status: " + (item.ok ? "looks valid" : "needs attention"));

    if (item.file && item.file.name) {
      lines.push("File: " + item.file.name);
    }

    if (item.createdAt) {
      lines.push("Created: " + item.createdAt);
    }

    if (item.label) {
      lines.push("Label: " + item.label);
    }

    lines.push("Docs: " + Number(item.docCount || 0));
    lines.push("Decks: " + Number(study.decks || 0));
    lines.push("Cards: " + Number(study.cards || 0));
    lines.push("Progress records: " + Number(study.progress || 0));
    lines.push("Sessions: " + Number(study.sessions || 0));
    lines.push("Media items: " + Number(media.mediaCount || 0));
    lines.push("Media refs: " + Number(media.cardMediaRefs || 0));
    lines.push("Media bytes: " + Number(media.totalBytes || 0));
    lines.push("Write mode: preview-only");

    if (Array.isArray(item.warnings) && item.warnings.length) {
      lines.push("Warnings:");
      item.warnings.forEach(function addWarning(warning) {
        lines.push("- " + warning);
      });
    }

    if (Array.isArray(item.errors) && item.errors.length) {
      lines.push("Errors:");
      item.errors.forEach(function addError(error) {
        lines.push("- " + error);
      });
    }

    return lines;
  }

  function formatPreviewText(preview) {
    return buildPreviewSummaryLines(preview).join("\n");
  }

  function formatPreviewHtml(preview) {
    const text = formatPreviewText(preview);
    return "<pre data-apc-local-backup-restore-preview-output=\"true\">" + escapeText(text) + "</pre>";
  }

  function createHiddenFileInput(options) {
    const opts = options || {};
    if (!root.document || typeof root.document.createElement !== "function") {
      throw new Error("Document is not available.");
    }

    const input = root.document.createElement("input");
    input.type = "file";
    input.accept = opts.accept || "application/json,.json";
    input.hidden = true;
    input.setAttribute("data-apc-local-backup-restore-preview-input", "true");
    return input;
  }

  function chooseBackupFileForPreview(options) {
    requireExplicitUserAction(options);

    if (!root.document || !root.document.body) {
      return Promise.reject(new Error("Document body is not available."));
    }

    return new Promise(function choose(resolve, reject) {
      const input = createHiddenFileInput(options);
      let settled = false;

      function cleanup() {
        if (input.parentNode) {
          input.parentNode.removeChild(input);
        }
      }

      input.addEventListener("change", function onChange() {
        const file = input.files && input.files[0];
        if (!file) {
          cleanup();
          if (!settled) {
            settled = true;
            resolve({
              ok: false,
              canWrite: false,
              marker: MARKER,
              errors: ["No backup file selected."],
              warnings: [],
              summary: {},
              restorePlan: {
                writesEnabled: false,
                writeMode: "preview-only",
                requiresExplicitConfirmation: true,
                overwriteExistingLocalData: false
              }
            });
          }
          return;
        }

        previewBackupFile(file, options).then(function done(preview) {
          cleanup();
          if (!settled) {
            settled = true;
            resolve(preview);
          }
        }, function failed(error) {
          cleanup();
          if (!settled) {
            settled = true;
            reject(error);
          }
        });
      });

      root.document.body.appendChild(input);
      input.click();
    });
  }

  function createPreviewFromExistingBackupPayload(payload, options) {
    const api = restoreApi();
    if (!api || typeof api.createRestorePreview !== "function") {
      throw new Error("Backup restore preview helper is not loaded.");
    }

    const preview = api.createRestorePreview(payload, options);

    if (typeof api.assertPreviewOnly === "function") {
      api.assertPreviewOnly(preview);
    }

    return preview;
  }

  function createPreviewFromEmptyMediaBackup(options) {
    const exporter = exportApi();
    if (!exporter || typeof exporter.createEmptyMediaBackupPayload !== "function") {
      throw new Error("Backup media export helper is not loaded.");
    }
    return createPreviewFromExistingBackupPayload(exporter.createEmptyMediaBackupPayload(options), options);
  }

  const api = Object.freeze({
    marker: MARKER,
    version: VERSION,
    maxPreviewBytes: MAX_PREVIEW_BYTES,
    validateBackupFileLike: validateBackupFileLike,
    previewBackupFile: previewBackupFile,
    chooseBackupFileForPreview: chooseBackupFileForPreview,
    createPreviewFromExistingBackupPayload: createPreviewFromExistingBackupPayload,
    createPreviewFromEmptyMediaBackup: createPreviewFromEmptyMediaBackup,
    buildPreviewSummaryLines: buildPreviewSummaryLines,
    formatPreviewText: formatPreviewText,
    formatPreviewHtml: formatPreviewHtml
  });

  root.APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
/* APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE_R12U_END */
