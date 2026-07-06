/* APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY_START */
(function () {
  "use strict";

  const root = typeof window !== "undefined" ? window : globalThis;
  const MARKER = "APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12L_R2_RESTORED_CARD";
  const RESTORE_PREVIEW_BIND_MARKER_R12V = "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BIND_R12V";
  const ASYNC_DOWNLOAD_BIND_MARKER_R12Y = "APC_PROFILE_LOCAL_BACKUPS_ASYNC_DOWNLOAD_BIND_R12Y";
  const MERGE_PREVIEW_UI_BIND_MARKER_R13B = "APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_UI_BIND_R13B";
  const OPEN_CURRENT_FILE_PREVIEW_BIND_MARKER_R13G_R2 = "APC_PROFILE_LOCAL_BACKUPS_OPEN_CURRENT_FILE_PREVIEW_BIND_R13G_R2";
  const SAVE_PLAN_PREVIEW_BIND_MARKER_R13J_R2 = "APC_PROFILE_LOCAL_BACKUPS_SAVE_PLAN_PREVIEW_BIND_R13J_R2";
  const SANITIZER_PREVIEW_BIND_MARKER_R13L = "APC_PROFILE_LOCAL_BACKUPS_SANITIZER_PREVIEW_BIND_R13L";
  const SANITIZED_PAYLOAD_PREVIEW_BIND_MARKER_R13N = "APC_PROFILE_LOCAL_BACKUPS_SANITIZED_PAYLOAD_PREVIEW_BIND_R13N";
  const SANITIZED_DOWNLOAD_SNAPSHOT_MARKER_R13Q_R4 = "APC_PROFILE_LOCAL_BACKUPS_SANITIZED_DOWNLOAD_SNAPSHOT_R13Q_R4";
  const GET_PANEL_API_FIX_MARKER_R13Q_R7 = "APC_PROFILE_LOCAL_BACKUPS_GET_PANEL_API_FIX_R13Q_R7";
  const SAVE_WRITER_PLAN_PREVIEW_MARKER_R13V = "APC_PROFILE_LOCAL_BACKUPS_SAVE_WRITER_PLAN_PREVIEW_R13V";
  const PANEL_SELECTOR = "[data-apc-profile-local-backups-panel='true']";
  const BOUND_ATTR = "data-apc-local-backups-bound";

  function documentRef() {
    return root && root.document ? root.document : null;
  }

  function api() {
    return root && root.APC_PROFILE_LOCAL_BACKUPS_PANEL
      ? root.APC_PROFILE_LOCAL_BACKUPS_PANEL
      : null;
  }

  function isPrivateProfileRenderEvent(event) {
    const detail = event && event.detail ? event.detail : null;
    return Boolean(detail && detail.page === "profile" && detail.user);
  }

  function hasPrivateProfileShell() {
    const document = documentRef();
    return Boolean(document && document.querySelector('.private-shell[data-private-page="profile"]'));
  }

  function findMountHost() {
    const document = documentRef();
    if (!document) return null;
    return (
      document.querySelector('.private-shell[data-private-page="profile"] .private-grid') ||
      document.querySelector('.private-shell[data-private-page="profile"]') ||
      null
    );
  }

  function panelNode() {
    const document = documentRef();
    return document ? document.querySelector(PANEL_SELECTOR) : null;
  }

  function removePanel() {
    const panel = panelNode();
    if (panel && panel.parentNode) panel.parentNode.removeChild(panel);
  }

  function statusNode(panel) {
    return panel && panel.querySelector ? panel.querySelector("[data-apc-local-backup-status]") : null;
  }

  function setStatus(panel, message, detail) {
    const node = statusNode(panel);
    if (!node) return;
    const lines = [String(message || "")].filter(Boolean);
    if (detail !== undefined && detail !== null && detail !== "") {
      if (typeof detail === "string") {
        lines.push(detail);
      } else {
        lines.push(JSON.stringify(detail, null, 2));
      }
    }
    node.textContent = lines.join("\n");
    node.hidden = lines.length === 0;
  }

  function triggerDownload(panelApi, payload) {
    const document = documentRef();
    if (!document) throw new Error("Document is not available.");
    const href = panelApi.createDownloadUrl(payload);
    const link = document.createElement("a");
    link.href = href;
    link.download = panelApi.backupFileName(payload.createdAt);
    link.rel = "noopener";
    document.body.appendChild(link);
    link.click();
    link.remove();
    root.setTimeout(function () {
      root.URL.revokeObjectURL(href);
    }, 5000);
    return {
      fileName: link.download,
      downloadStarted: true,
      uploadsToServer: false
    };
  }

  function bindPanel(panel) {
    if (!panel || panel.getAttribute(BOUND_ATTR) === "true") return panel;

    const panelApi = api();
    if (!panelApi) {
      setStatus(panel, "Local backup module is not loaded.");
      return panel;
    }

    const chooseButton = panel.querySelector("[data-apc-local-backup-choose-folder]");
    const downloadButton = panel.querySelector("[data-apc-local-backup-download]");

    if (chooseButton) {
      chooseButton.addEventListener("click", async function () {
        try {
          setStatus(panel, "Preparing local backup...");
          const result = await panelApi.chooseFolderAndWriteBackup();
          setStatus(panel, "Backup saved to your selected local folder.", result);
        } catch (error) {
          setStatus(panel, "Could not save to a local folder.", String(error && error.message ? error.message : error));
        }
      });
    }

    if (downloadButton) {
      downloadButton.addEventListener("click", async function () {
        try {
          setStatus(panel, "Preparing sanitized backup download...");
          const payload = await panelApi.buildBackupPayload();
          const result = triggerDownload(panelApi, payload);
          setStatus(panel, "Backup download started.", result);
        } catch (error) {
          setStatus(panel, "Could not create backup download.", String(error && error.message ? error.message : error));
        }
      });
    }

    panel.setAttribute(BOUND_ATTR, "true");
    return panel;
  }

  function mountFromPrivateProfileEvent(event) {
    if (!isPrivateProfileRenderEvent(event)) {
      removePanel();
      return null;
    }

    return mountIfPrivateProfileShell();
  }

  function mountIfPrivateProfileShell() {
    if (!hasPrivateProfileShell()) {
      removePanel();
      return null;
    }

    const panelApi = api();
    const host = findMountHost();
    if (!panelApi || !host) {
      removePanel();
      return null;
    }

    const panel = panelApi.mountPanel(host);
    bindPanel(panel);
    return panel;
  }

  function scheduleMountIfPrivateProfileShell() {
    root.setTimeout(function () {
      mountIfPrivateProfileShell();
    }, 0);
    root.setTimeout(function () {
      mountIfPrivateProfileShell();
    }, 150);
    root.setTimeout(function () {
      mountIfPrivateProfileShell();
    }, 500);
  }

  function cleanupIfNotPrivateProfile() {
    root.setTimeout(function () {
      if (!hasPrivateProfileShell()) removePanel();
    }, 0);
  }

  const mountApi = Object.freeze({
    marker: MARKER,
    mountIfPrivateProfileShell: mountIfPrivateProfileShell,
    scheduleMountIfPrivateProfileShell: scheduleMountIfPrivateProfileShell,
    isPrivateProfileRenderEvent: isPrivateProfileRenderEvent,
    hasPrivateProfileShell: hasPrivateProfileShell,
    findMountHost: findMountHost,
    mountFromPrivateProfileEvent: mountFromPrivateProfileEvent,
    cleanupIfNotPrivateProfile: cleanupIfNotPrivateProfile,
    removePanel: removePanel
  });



  function getRestorePreviewBridgeR12V() {
    return root && root.APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE
      ? root.APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BRIDGE
      : null;
  }

  function findRestorePreviewOutputR12V(panel) {
    return panel && panel.querySelector
      ? panel.querySelector("[data-apc-local-backup-restore-preview-output]")
      : null;
  }

  function setRestorePreviewOutputR12V(panel, text) {
    const output = findRestorePreviewOutputR12V(panel);
    if (!output) return;
    output.hidden = false;
    output.textContent = text || "";
  }

  function bindRestorePreviewClickOnceR12V() {
    if (!root || !root.document || root.APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_CLICK_BOUND_R12V === true) {
      return;
    }

    root.APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_CLICK_BOUND_R12V = true;

    root.document.addEventListener("click", function onRestorePreviewClickR12V(event) {
      const target = event && event.target && event.target.closest
        ? event.target.closest("[data-apc-local-backup-preview-restore]")
        : null;

      if (!target) return;

      const panel = target.closest ? target.closest(PANEL_SELECTOR) : null;
      if (!panel) return;

      const bridge = getRestorePreviewBridgeR12V();
      if (!bridge || typeof bridge.chooseBackupFileForPreview !== "function") {
        setStatus(panel, "Backup restore preview module is not loaded.");
        return;
      }

      target.disabled = true;
      setStatus(panel, "Choose a backup JSON file to preview.");

      bridge.chooseBackupFileForPreview({ explicitUserAction: true }).then(function onPreview(preview) {
        const text = typeof bridge.formatPreviewText === "function"
          ? bridge.formatPreviewText(preview)
          : JSON.stringify(preview, null, 2);

        setRestorePreviewOutputR12V(panel, text);

        if (preview && preview.ok) {
          setStatus(panel, "Backup preview complete. No data was restored.");
        } else {
          setStatus(panel, "Backup preview found issues. No data was restored.");
        }
      }).catch(function onPreviewError(error) {
        setStatus(panel, "Could not preview backup file.", String(error && error.message ? error.message : error));
      }).finally(function onPreviewDone() {
        target.disabled = false;
      });
    });
  }

  bindRestorePreviewClickOnceR12V();






  function getCurrentBackupSaveWriterR13V() {
    return root && root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER
      ? root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER
      : null;
  }

  function backupPanelRootR13V() {
    return root && root.document
      ? root.document.querySelector("[data-apc-profile-local-backups-panel='true']")
      : null;
  }

  function ensureSaveWriterPlanPreviewNodeR13V(panel) {
    if (!panel || !root.document) return null;

    let wrap = panel.querySelector("[data-apc-local-backup-save-writer-plan-preview-r13v='true']");
    if (wrap) return wrap;

    wrap = root.document.createElement("section");
    wrap.setAttribute("data-apc-local-backup-save-writer-plan-preview-r13v", "true");
    wrap.style.marginTop = "1rem";
    wrap.style.padding = "0.875rem";
    wrap.style.border = "1px solid rgba(148, 163, 184, 0.35)";
    wrap.style.borderRadius = "0.75rem";
    wrap.style.background = "rgba(15, 23, 42, 0.035)";

    const heading = root.document.createElement("h3");
    heading.textContent = "Current backup save plan";
    heading.style.margin = "0 0 0.35rem";

    const note = root.document.createElement("p");
    note.textContent = "Preview only. No file is saved, replaced, merged, restored, or overwritten.";
    note.style.margin = "0 0 0.65rem";

    const pre = root.document.createElement("pre");
    pre.setAttribute("data-apc-local-backup-save-writer-plan-preview-text-r13v", "true");
    pre.style.whiteSpace = "pre-wrap";
    pre.style.margin = "0";
    pre.style.fontSize = "0.85rem";
    pre.style.lineHeight = "1.35";
    pre.textContent = "Preparing current backup save plan preview…";

    wrap.appendChild(heading);
    wrap.appendChild(note);
    wrap.appendChild(pre);
    panel.appendChild(wrap);
    return wrap;
  }

  function setSaveWriterPlanPreviewTextR13V(text) {
    const panel = backupPanelRootR13V();
    const wrap = ensureSaveWriterPlanPreviewNodeR13V(panel);
    const pre = wrap
      ? wrap.querySelector("[data-apc-local-backup-save-writer-plan-preview-text-r13v='true']")
      : null;

    if (pre) pre.textContent = String(text || "");
    return Boolean(pre);
  }

  function renderSaveWriterPlanPreviewR13V() {
    const panel = backupPanelRootR13V();
    if (!panel) return false;

    const panelApi = getPanelApi();
    const writerApi = getCurrentBackupSaveWriterR13V();

    ensureSaveWriterPlanPreviewNodeR13V(panel);

    if (!panelApi || typeof panelApi.buildBackupPayload !== "function") {
      setSaveWriterPlanPreviewTextR13V("Current backup save plan preview unavailable: backup panel API is not ready.");
      return false;
    }

    if (!writerApi || typeof writerApi.createCurrentBackupSaveWriterPlan !== "function") {
      setSaveWriterPlanPreviewTextR13V("Current backup save plan preview unavailable: save writer helper is not loaded.");
      return false;
    }

    Promise.resolve(panelApi.buildBackupPayload()).then(function onPayload(payload) {
      const plan = writerApi.createCurrentBackupSaveWriterPlan({
        selectedFileName: writerApi.CURRENT_FILE_NAME || "buddies-who-study-current.json",
        payload: payload
      }, {
        createdAt: new Date().toISOString()
      });

      const text = typeof writerApi.formatCurrentBackupSaveWriterPlanText === "function"
        ? writerApi.formatCurrentBackupSaveWriterPlanText(plan)
        : JSON.stringify(plan, null, 2);

      setSaveWriterPlanPreviewTextR13V(text);
    }).catch(function onError(error) {
      setSaveWriterPlanPreviewTextR13V("Current backup save plan preview failed: " + String(error && error.message ? error.message : error));
    });

    return true;
  }

  function scheduleSaveWriterPlanPreviewR13V() {
    let attempts = 0;

    function tick() {
      attempts += 1;
      const rendered = renderSaveWriterPlanPreviewR13V();
      if (!rendered && attempts < 30) {
        root.setTimeout(tick, 250);
      }
    }

    if (!root || !root.document) return;

    if (root.document.readyState === "loading") {
      root.document.addEventListener("DOMContentLoaded", function onReady() {
        root.setTimeout(tick, 0);
      }, { once: true });
    } else {
      root.setTimeout(tick, 0);
    }
  }


  function bindAsyncDownloadClickOnceR12Y() {
    if (!root || !root.document || root.APC_PROFILE_LOCAL_BACKUPS_ASYNC_DOWNLOAD_CLICK_BOUND_R12Y === true) {
      return;
    }

    root.APC_PROFILE_LOCAL_BACKUPS_ASYNC_DOWNLOAD_CLICK_BOUND_R12Y = true;

    root.document.addEventListener("click", function onAsyncDownloadClickR12Y(event) {
      const target = event && event.target && event.target.closest
        ? event.target.closest("[data-apc-local-backup-download]")
        : null;

      if (!target) return;

      const panel = target.closest ? target.closest(PANEL_SELECTOR) : null;
      if (!panel) return;

      event.preventDefault();
      event.stopPropagation();
      if (typeof event.stopImmediatePropagation === "function") {
        event.stopImmediatePropagation();
      }

      const panelApi = getPanelApi();
      if (!panelApi || typeof panelApi.buildBackupPayload !== "function" || typeof panelApi.createDownloadUrl !== "function") {
        setStatus(panel, "Local backup module is not loaded.");
        return;
      }

      target.disabled = true;
      setStatus(panel, "Preparing sanitized backup download...");

      Promise.resolve(panelApi.buildBackupPayload()).then(function onPayload(payload) {
        const sanitizedSnapshotOutputR13QR4 = prepareSanitizedSnapshotDownloadR13QR4(payload);
        const blob = new Blob([sanitizedSnapshotOutputR13QR4.jsonText], { type: sanitizedSnapshotOutputR13QR4.mimeType || "application/json" });
        const url = root.URL.createObjectURL(blob);
        const link = root.document.createElement("a");
        link.href = url;
        link.download = sanitizedSnapshotOutputR13QR4.fileName;
        root.document.body.appendChild(link);
        link.click();
        link.remove();
        root.setTimeout(function revokeUrl() {
          if (root.URL && typeof root.URL.revokeObjectURL === "function") {
            root.URL.revokeObjectURL(url);
          }
        }, 1000);
        setStatus(panel, "Sanitized backup download ready. Study docs and media docs were included; legacy backend cache fields were excluded.");
      }).catch(function onDownloadError(error) {
        setStatus(panel, "Could not create backup download.", String(error && error.message ? error.message : error));
      }).finally(function onDownloadDone() {
        target.disabled = false;
      });
    }, true);
  }

  bindAsyncDownloadClickOnceR12Y();




  function getMergePreviewBridgeR13B() {
    return root && root.APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE
      ? root.APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE
      : null;
  }

  function findMergePreviewOutputR13B(panel) {
    return panel && panel.querySelector
      ? panel.querySelector("[data-apc-local-backup-restore-preview-output]")
      : null;
  }

  function setMergePreviewOutputR13B(panel, text) {
    const output = findMergePreviewOutputR13B(panel);
    if (!output) return;
    output.hidden = false;
    output.textContent = text || "";
  }

  function bindMergePreviewClickOnceR13B() {
    if (!root || !root.document || root.APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_CLICK_BOUND_R13B === true) {
      return;
    }

    root.APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_CLICK_BOUND_R13B = true;

    root.document.addEventListener("click", function onMergePreviewClickR13B(event) {
      const target = event && event.target && event.target.closest
        ? event.target.closest("[data-apc-local-backup-preview-restore]")
        : null;

      if (!target) return;

      const panel = target.closest ? target.closest(PANEL_SELECTOR) : null;
      if (!panel) return;

      event.preventDefault();
      event.stopPropagation();
      if (typeof event.stopImmediatePropagation === "function") {
        event.stopImmediatePropagation();
      }

      const bridge = getMergePreviewBridgeR13B();
      if (!bridge || typeof bridge.chooseBackupFileForMergePreview !== "function") {
        setStatus(panel, "Backup merge preview module is not loaded.");
        return;
      }

      target.disabled = true;
      setStatus(panel, "Choose a backup JSON file to preview for merge.");

      bridge.chooseBackupFileForMergePreview({ explicitUserAction: true }).then(function onMergePreview(preview) {
        const text = typeof bridge.formatMergePreviewText === "function"
          ? bridge.formatMergePreviewText(preview)
          : JSON.stringify(preview, null, 2);

        setMergePreviewOutputR13B(panel, text);

        if (preview && preview.ok) {
          setStatus(panel, "Backup merge preview complete. No data was restored.");
        } else {
          setStatus(panel, "Backup merge preview found issues. No data was restored.");
        }
      }).catch(function onMergePreviewError(error) {
        setStatus(panel, "Could not preview backup merge.", String(error && error.message ? error.message : error));
      }).finally(function onMergePreviewDone() {
        target.disabled = false;
      });
    }, true);
  }

  bindMergePreviewClickOnceR13B();




  function getCurrentBackupFileAccessR13GR2() {
    return root && root.APC_LOCAL_BACKUP_CURRENT_FILE_ACCESS
      ? root.APC_LOCAL_BACKUP_CURRENT_FILE_ACCESS
      : null;
  }

  function ensureCurrentBackupPreviewOutputR13GR2(panel) {
    if (!panel || !panel.querySelector) return null;

    let output = panel.querySelector("[data-apc-local-backup-current-file-output]");
    if (output) return output;

    output = root.document.createElement("pre");
    output.setAttribute("data-apc-local-backup-current-file-output", "true");
    output.hidden = true;
    output.style.whiteSpace = "pre-wrap";

    const previewOutput = panel.querySelector("[data-apc-local-backup-restore-preview-output]");
    if (previewOutput && previewOutput.parentNode) {
      previewOutput.parentNode.insertBefore(output, previewOutput.nextSibling);
    } else {
      panel.appendChild(output);
    }

    return output;
  }

  function setCurrentBackupPreviewOutputR13GR2(panel, text) {
    const output = ensureCurrentBackupPreviewOutputR13GR2(panel);
    if (!output) return;
    output.hidden = false;
    output.textContent = text || "";
  }

  function ensureOpenCurrentBackupFileButtonR13GR2(panel) {
    if (!panel || !panel.querySelector) return;
    if (panel.querySelector("[data-apc-local-backup-open-current]")) return;

    const previewButton = panel.querySelector("[data-apc-local-backup-preview-restore]");
    if (!previewButton || !previewButton.parentNode) return;

    const button = root.document.createElement("button");
    button.type = "button";
    button.setAttribute("data-apc-local-backup-open-current", "true");
    button.textContent = "Open current backup file";
    button.title = "Preview buddies-who-study-current.json. No data will be restored or overwritten.";

    previewButton.parentNode.insertBefore(button, previewButton.nextSibling);
  }

  function ensureOpenCurrentBackupFileButtonsR13GR2() {
    if (!root || !root.document || !root.document.querySelectorAll) return;
    root.document.querySelectorAll(PANEL_SELECTOR).forEach(ensureOpenCurrentBackupFileButtonR13GR2);
  }











  function getPanelApi() {
    return root && root.APC_PROFILE_LOCAL_BACKUPS_PANEL
      ? root.APC_PROFILE_LOCAL_BACKUPS_PANEL
      : null;
  }


  function getSanitizedSnapshotOutputHelperR13QR4() {
    return root && root.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT
      ? root.APC_LOCAL_BACKUP_SANITIZED_SNAPSHOT_OUTPUT
      : null;
  }

  function prepareSanitizedSnapshotDownloadR13QR4(payload) {
    const helperApi = getSanitizedSnapshotOutputHelperR13QR4();
    if (!helperApi || typeof helperApi.prepareSanitizedSnapshotOutput !== "function") {
      throw new Error("Sanitized snapshot output helper is not loaded.");
    }

    const now = new Date().toISOString();
    const prepared = helperApi.prepareSanitizedSnapshotOutput(payload || {}, {
      createdAt: now,
      updatedAt: now
    });

    if (!prepared || prepared.downloadPrepared !== true) {
      throw new Error("Sanitized snapshot output was not prepared.");
    }

    if (prepared.errors && prepared.errors.length) {
      throw new Error(prepared.errors.join("; "));
    }

    return prepared;
  }


  function getSanitizedBackupPayloadBuilderR13N() {
    return root && root.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER
      ? root.APC_LOCAL_BACKUP_SANITIZED_PAYLOAD_BUILDER
      : null;
  }

  function appendSanitizedBackupPayloadPreviewR13N(panel, readResult) {
    if (!panel || !readResult) return;

    const builderApi = getSanitizedBackupPayloadBuilderR13N();
    if (!builderApi || typeof builderApi.createSanitizedBackupPayloadPreview !== "function") {
      return;
    }

    const preview = builderApi.createSanitizedBackupPayloadPreview(readResult.payload || null, {
      updatedAt: new Date().toISOString()
    });

    const text = typeof builderApi.formatSanitizedBackupPayloadPreviewText === "function"
      ? builderApi.formatSanitizedBackupPayloadPreviewText(preview)
      : JSON.stringify(preview, null, 2);

    const output = ensureCurrentBackupPreviewOutputR13GR2(panel);
    if (!output) return;

    output.hidden = false;
    output.textContent = String(output.textContent || "").trimEnd() +
      "\n\n" +
      text +
      "\n\nSanitized payload preview only. The cleaned backup payload was not saved anywhere.";
  }


  function getLegacyBackendCacheSanitizerR13L() {
    return root && root.APC_LOCAL_BACKUP_LEGACY_BACKEND_CACHE_SANITIZER
      ? root.APC_LOCAL_BACKUP_LEGACY_BACKEND_CACHE_SANITIZER
      : null;
  }

  function appendLegacyBackendCacheSanitizerPreviewR13L(panel, readResult) {
    if (!panel || !readResult) return;

    const sanitizerApi = getLegacyBackendCacheSanitizerR13L();
    if (!sanitizerApi || typeof sanitizerApi.createBackupSanitizationPreview !== "function") {
      return;
    }

    const preview = sanitizerApi.createBackupSanitizationPreview(readResult.payload || null, {
      updatedAt: new Date().toISOString()
    });

    const text = typeof sanitizerApi.formatSanitizationPreviewText === "function"
      ? sanitizerApi.formatSanitizationPreviewText(preview)
      : JSON.stringify(preview, null, 2);

    const output = ensureCurrentBackupPreviewOutputR13GR2(panel);
    if (!output) return;

    output.hidden = false;
    output.textContent = String(output.textContent || "").trimEnd() +
      "\n\n" +
      text +
      "\n\nSanitizer preview only. Legacy backend cache fields are not removed from your browser data yet.";
  }


  function getCurrentBackupSavePlanR13JR2() {
    return root && root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN
      ? root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_PLAN
      : null;
  }

  function appendCurrentBackupSavePlanPreviewR13JR2(panel, readResult) {
    if (!panel || !readResult) return;

    const savePlanApi = getCurrentBackupSavePlanR13JR2();
    if (!savePlanApi || typeof savePlanApi.createSavePlan !== "function") {
      return;
    }

    const summary = readResult.summary || {};
    const plan = savePlanApi.createSavePlan({
      selectedFileName: readResult.fileName || "",
      incomingPayload: readResult.payload || null,
      currentPayload: readResult.payload || null,
      mergePreview: {
        adds: 0,
        updates: 0,
        skipped: Number(summary.docCount || 0),
        conflicts: 0,
        canWrite: false,
        writeMode: "preview-only"
      },
      createdAt: new Date().toISOString()
    });

    const text = typeof savePlanApi.formatSavePlanText === "function"
      ? savePlanApi.formatSavePlanText(plan)
      : JSON.stringify(plan, null, 2);

    const output = ensureCurrentBackupPreviewOutputR13GR2(panel);
    if (!output) return;

    output.hidden = false;
    output.textContent = String(output.textContent || "").trimEnd() +
      "\n\n" +
      text +
      "\n\nSave-plan preview only. No save, merge, restore, or overwrite action is available.";
  }


  function bindOpenCurrentBackupFileClickOnceR13GR2() {
    if (!root || !root.document || root.APC_PROFILE_LOCAL_BACKUPS_OPEN_CURRENT_FILE_CLICK_BOUND_R13G_R2 === true) {
      return;
    }

    root.APC_PROFILE_LOCAL_BACKUPS_OPEN_CURRENT_FILE_CLICK_BOUND_R13G_R2 = true;

    root.document.addEventListener("click", function onOpenCurrentBackupFileClickR13GR2(event) {
      const target = event && event.target && event.target.closest
        ? event.target.closest("[data-apc-local-backup-open-current]")
        : null;

      if (!target) return;

      const panel = target.closest ? target.closest(PANEL_SELECTOR) : null;
      if (!panel) return;

      event.preventDefault();
      event.stopPropagation();
      if (typeof event.stopImmediatePropagation === "function") {
        event.stopImmediatePropagation();
      }

      const adapter = getCurrentBackupFileAccessR13GR2();
      if (!adapter || typeof adapter.chooseBackupFileForRead !== "function") {
        setStatus(panel, "Current backup file preview module is not loaded.");
        return;
      }

      target.disabled = true;
      setStatus(panel, "Choose buddies-who-study-current.json to preview. No data will be restored or overwritten.");

      adapter.chooseBackupFileForRead({ explicitUserAction: true }).then(function onCurrentBackupPreview(result) {
        const text = typeof adapter.formatReadResultText === "function"
          ? adapter.formatReadResultText(result)
          : JSON.stringify(result, null, 2);

        setCurrentBackupPreviewOutputR13GR2(panel, text);

            appendLegacyBackendCacheSanitizerPreviewR13L(panel, result);
            appendSanitizedBackupPayloadPreviewR13N(panel, result);
            appendCurrentBackupSavePlanPreviewR13JR2(panel, result);
setStatus(panel, "Current backup, sanitizer, sanitized payload, and save-plan previews complete. No data was saved, restored, merged, or overwritten.");
      }).catch(function onCurrentBackupPreviewError(error) {
        setStatus(panel, "Could not preview current backup file.", String(error && error.message ? error.message : error));
      }).finally(function onCurrentBackupPreviewDone() {
        target.disabled = false;
      });
    }, true);
  }

  function installOpenCurrentBackupFilePreviewR13GR2() {
    bindOpenCurrentBackupFileClickOnceR13GR2();
    ensureOpenCurrentBackupFileButtonsR13GR2();

    if (root && root.document) {
      root.document.addEventListener("apc-private-page-rendered", function onPrivatePageRenderedR13GR2(event) {
        const detail = event && event.detail ? event.detail : {};
        if (detail.page !== "profile" || !detail.user) return;
        root.setTimeout(ensureOpenCurrentBackupFileButtonsR13GR2, 0);
      });

      root.setTimeout(ensureOpenCurrentBackupFileButtonsR13GR2, 0);
      root.setTimeout(ensureOpenCurrentBackupFileButtonsR13GR2, 250);
    }
  }

  installOpenCurrentBackupFilePreviewR13GR2();


  scheduleSaveWriterPlanPreviewR13V();

  root.APC_PROFILE_LOCAL_BACKUPS_MOUNT = mountApi;

  if (root && root.document) {
    if (root.document.readyState === "loading") {
      root.document.addEventListener("DOMContentLoaded", scheduleMountIfPrivateProfileShell, { once: true });
    } else {
      scheduleMountIfPrivateProfileShell();
    }

    root.addEventListener("hashchange", scheduleMountIfPrivateProfileShell);
    root.addEventListener("popstate", scheduleMountIfPrivateProfileShell);
    root.document.addEventListener("apc-auth-changed", scheduleMountIfPrivateProfileShell);
    root.document.addEventListener("apc-private-page-rendered", mountFromPrivateProfileEvent);
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = mountApi;
  }
})();
/* APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY_END */

(function profileLocalBackupsSaveActionStatusPreviewR14IR2(root) {
  "use strict";

  var MARKER = "APC_PROFILE_LOCAL_BACKUPS_SAVE_ACTION_STATUS_PREVIEW_R14I_R2";
  var CURRENT_FILE_NAME = "buddies-who-study-current.json";
  var PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";

  function onReady(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn, { once: true });
      return;
    }
    fn();
  }

  function findAnchor() {
    return document.querySelector("[data-apc-local-backup-save-writer-plan-preview-r13v='true']");
  }

  function textLine(label, value) {
    return label + ": " + String(value);
  }

  function buildPreviewText() {
    var controller = root.APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER;
    var panel = root.APC_PROFILE_LOCAL_BACKUPS_PANEL;
    var lines = [
      "Current backup save action status",
      "Mode: preview-only",
      "Button added: false",
      "Click handler added: false",
      "Current-file save enabled: false",
      "Same-file write enabled: false",
      "Executor call from UI allowed: false",
      ""
    ];

    if (!controller || typeof controller.createSaveCurrentBackupActionState !== "function") {
      lines.push("Controller loaded: false");
      lines.push("Future eligible: false");
      lines.push("Reason: save action controller is not available.");
      return lines.join("\n");
    }

    if (!panel || typeof panel.buildBackupPayload !== "function") {
      lines.push("Controller loaded: true");
      lines.push("Future eligible: false");
      lines.push("Reason: backup payload builder is not available.");
      return lines.join("\n");
    }

    try {
      var payload = panel.buildBackupPayload();
      var state = controller.createSaveCurrentBackupActionState({
        selectedFileName: CURRENT_FILE_NAME,
        currentFileHandle: { name: CURRENT_FILE_NAME },
        directoryHandle: {
          getFileHandle: function getFileHandle() {
            return Promise.resolve({ name: PREVIOUS_FILE_NAME });
          }
        },
        payload: payload
      }, {
        createdAt: new Date().toISOString()
      });

      lines.push(textLine("Controller loaded", true));
      lines.push(textLine("Controller marker", controller.MARKER || ""));
      lines.push(textLine("Future eligible", state.eligibleForFutureEnablement));
      lines.push(textLine("Future save button may be shown later", state.canShowFutureSaveButton));
      lines.push(textLine("Can write now", state.canWriteNow));
      lines.push(textLine("Writes enabled now", state.writesEnabledNow));
      lines.push(textLine("Executor call allowed now", state.executorCallAllowedNow));
      lines.push(textLine("Executor called", state.executorCalled));
      lines.push(textLine("Selected file", state.selectedFileName));
      lines.push(textLine("Expected current file", state.currentFileName));
      lines.push(textLine("Last-good file", state.previousFileName));
      lines.push(textLine("Legacy backend cache fields removed", state.removedFieldCount));
      lines.push(textLine("After legacy backend cache fields", state.afterLegacyFieldPaths && state.afterLegacyFieldPaths.length ? state.afterLegacyFieldPaths.join(", ") : "none"));
      lines.push("");
      lines.push("Safety");
      lines.push("Preview only. No file is saved, replaced, merged, restored, or overwritten.");
      lines.push("No Save button was added in this stage.");
      lines.push("No Profile click handler calls the write executor.");

      if (state.blockers && state.blockers.length) {
        lines.push("");
        lines.push("Blockers: " + state.blockers.length);
        state.blockers.forEach(function eachBlocker(blocker) {
          lines.push("- " + blocker);
        });
      }

      if (state.warnings && state.warnings.length) {
        lines.push("");
        lines.push("Warnings: " + state.warnings.length);
        state.warnings.forEach(function eachWarning(warning) {
          lines.push("- " + warning);
        });
      }
    } catch (error) {
      lines.push(textLine("Controller loaded", true));
      lines.push("Future eligible: false");
      lines.push("Reason: " + String(error && error.message ? error.message : error));
    }

    return lines.join("\n");
  }

  function render() {
    var anchor = findAnchor();
    if (!anchor) {
      return false;
    }

    var existing = document.querySelector("[data-apc-local-backup-save-action-status-preview-r14i-r2='true']");
    if (!existing) {
      existing = document.createElement("section");
      existing.setAttribute("data-apc-local-backup-save-action-status-preview-r14i-r2", "true");
      existing.style.marginTop = "12px";
      existing.style.padding = "12px";
      existing.style.border = "1px solid rgba(148, 163, 184, 0.45)";
      existing.style.borderRadius = "12px";
      existing.style.background = "rgba(15, 23, 42, 0.04)";

      var heading = document.createElement("h3");
      heading.textContent = "Current backup save action status";
      heading.style.margin = "0 0 8px";
      existing.appendChild(heading);

      var pre = document.createElement("pre");
      pre.setAttribute("data-apc-local-backup-save-action-status-preview-text-r14i-r2", "true");
      pre.style.whiteSpace = "pre-wrap";
      pre.style.margin = "0";
      pre.style.fontSize = "12px";
      pre.style.lineHeight = "1.45";
      existing.appendChild(pre);

      anchor.insertAdjacentElement("afterend", existing);
    }

    var textNode = existing.querySelector("[data-apc-local-backup-save-action-status-preview-text-r14i-r2='true']");
    if (textNode) {
      textNode.textContent = buildPreviewText();
    }

    root.APC_PROFILE_LOCAL_BACKUPS_SAVE_ACTION_STATUS_PREVIEW_R14I_R2 = {
      marker: MARKER,
      rendered: true,
      updatedAt: new Date().toISOString()
    };

    return true;
  }

  function schedule() {
    var attempts = 0;
    var timer = setInterval(function retry() {
      attempts += 1;
      if (render() || attempts >= 40) {
        clearInterval(timer);
      }
    }, 250);
  }

  onReady(schedule);
})(typeof window !== "undefined" ? window : globalThis);
