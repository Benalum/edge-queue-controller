/* APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY_START */
(function () {
  "use strict";

  const root = typeof window !== "undefined" ? window : globalThis;
  const MARKER = "APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY";
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

  function cleanupIfNotPrivateProfile() {
    root.setTimeout(function () {
      if (!hasPrivateProfileShell()) removePanel();
    }, 0);
  }

  const mountApi = Object.freeze({
    marker: MARKER,
    isPrivateProfileRenderEvent: isPrivateProfileRenderEvent,
    hasPrivateProfileShell: hasPrivateProfileShell,
    findMountHost: findMountHost,
    mountFromPrivateProfileEvent: mountFromPrivateProfileEvent,
    cleanupIfNotPrivateProfile: cleanupIfNotPrivateProfile,
    removePanel: removePanel
  });

  root.APC_PROFILE_LOCAL_BACKUPS_MOUNT = mountApi;

  if (root && root.document) {
    if (root.document.readyState === "loading") {
      root.document.addEventListener("DOMContentLoaded", cleanupIfNotPrivateProfile, { once: true });
    } else {
      cleanupIfNotPrivateProfile();
    }

    root.addEventListener("hashchange", cleanupIfNotPrivateProfile);
    root.addEventListener("popstate", cleanupIfNotPrivateProfile);
    root.document.addEventListener("apc-auth-changed", cleanupIfNotPrivateProfile);
    root.document.addEventListener("apc-private-page-rendered", mountFromPrivateProfileEvent);
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = mountApi;
  }
})();
/* APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY_END */
