/* APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY_START */
(function () {
  "use strict";

  const root = typeof window !== "undefined" ? window : globalThis;
  const MARKER = "APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12L_R2_RESTORED_CARD";
  const RESTORE_PREVIEW_BIND_MARKER_R12V = "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BIND_R12V";
  const ASYNC_DOWNLOAD_BIND_MARKER_R12Y = "APC_PROFILE_LOCAL_BACKUPS_ASYNC_DOWNLOAD_BIND_R12Y";
  const MERGE_PREVIEW_UI_BIND_MARKER_R13B = "APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_UI_BIND_R13B";
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
          setStatus(panel, "Preparing backup download...");
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
      setStatus(panel, "Preparing backup download...");

      Promise.resolve(panelApi.buildBackupPayload()).then(function onPayload(payload) {
        const url = panelApi.createDownloadUrl(payload);
        const link = root.document.createElement("a");
        link.href = url;
        link.download = panelApi.backupFileName(payload && payload.createdAt);
        root.document.body.appendChild(link);
        link.click();
        link.remove();
        root.setTimeout(function revokeUrl() {
          if (root.URL && typeof root.URL.revokeObjectURL === "function") {
            root.URL.revokeObjectURL(url);
          }
        }, 1000);
        setStatus(panel, "Backup download ready. Study docs and media docs were included.");
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
