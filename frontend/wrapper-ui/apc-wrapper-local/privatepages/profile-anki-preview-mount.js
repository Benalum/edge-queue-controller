(function attachApcProfileAnkiPreviewMount(root) {
  "use strict";

  const PATCH_MARKER = "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G";
  const MOUNT_ID = "apc-profile-anki-preview-panel-r11g";
  const MAX_RETRIES = 20;

  function safeString(value) {
    return value == null ? "" : String(value);
  }

  function getPanel(explicitPanel) {
    const panel = explicitPanel || root.APC_PROFILE_ANKI_PREVIEW_PANEL;
    if (!panel || typeof panel.renderPanel !== "function") {
      throw new Error("Profile Anki preview mount requires APC_PROFILE_ANKI_PREVIEW_PANEL.renderPanel.");
    }
    return panel;
  }

  function isProfileSurface(documentRef) {
    const locationRef = root.location || {};
    const path = safeString(locationRef.pathname).toLowerCase();
    const hash = safeString(locationRef.hash).toLowerCase();
    const search = safeString(locationRef.search).toLowerCase();

    if (path.includes("profile") || hash.includes("profile") || search.includes("profile")) {
      return true;
    }

    if (!documentRef || typeof documentRef.querySelector !== "function") {
      return false;
    }

    return Boolean(
      documentRef.querySelector('[data-apc-profile-root]') ||
          documentRef.querySelector('[data-route="profile"]') ||
      documentRef.querySelector('[data-apc-private-page="profile"]') ||
      documentRef.querySelector('[data-apc-page="profile"]') ||
      documentRef.querySelector('.apc-profile-page') ||
      documentRef.querySelector('#profileRoot')
    );
  }

  function findProfileTarget(documentRef) {
    if (!documentRef || typeof documentRef.querySelector !== "function") {
      return null;
    }

    const selectors = [
      "[data-apc-profile-anki-preview-host]",
      "[data-apc-profile-root]",
      '[data-apc-private-page="profile"]',
      '[data-apc-page="profile"]',
      ".apc-profile-page",
      "#profileRoot",
      "#privatePageContent",
      "#privatePagesApp",
      "#companionPrivateApp",
      "main"
    ];

    for (const selector of selectors) {
      const node = documentRef.querySelector(selector);
      if (node && typeof node.appendChild === "function") {
        return node;
      }
    }

    if (documentRef.body && typeof documentRef.body.appendChild === "function") {
      return documentRef.body;
    }

    return null;
  }

  function ensureProfileAnkiPreviewMounted(options) {
    const opts = options || {};
    const documentRef = opts.document || root.document;

    if (root.APC_PROFILE_ANKI_PREVIEW_MOUNT_DISABLED === true && opts.force !== true) {
      return Object.freeze({
        marker: PATCH_MARKER,
        mounted: false,
        reason: "disabled"
      });
    }

    if (!documentRef) {
      return Object.freeze({
        marker: PATCH_MARKER,
        mounted: false,
        reason: "missing-document"
      });
    }

    if (!isProfileSurface(documentRef) && opts.force !== true) {
      return Object.freeze({
        marker: PATCH_MARKER,
        mounted: false,
        reason: "not-profile-surface"
      });
    }

    if (documentRef.getElementById && documentRef.getElementById(MOUNT_ID)) {
      return Object.freeze({
        marker: PATCH_MARKER,
        mounted: true,
        reason: "already-mounted",
        node: documentRef.getElementById(MOUNT_ID)
      });
    }

    const target = opts.target || findProfileTarget(documentRef);
    if (!target) {
      return Object.freeze({
        marker: PATCH_MARKER,
        mounted: false,
        reason: "missing-target"
      });
    }

    const panel = getPanel(opts.panel);
    const host = documentRef.createElement("section");
    host.id = MOUNT_ID;
    host.setAttribute("data-apc-profile-anki-preview-mount", "true");
    host.setAttribute("data-apc-profile-anki-preview-source", "r11g");
    target.appendChild(host);

    const rendered = panel.renderPanel(host, {
      bridge: opts.bridge || root.APC_PROFILE_ANKI_IMPORT_BRIDGE,
      importer: opts.importer || root.APC_ANKI_IMPORT_LOCAL
    });

    return Object.freeze({
      marker: PATCH_MARKER,
      mounted: true,
      reason: "mounted",
      node: host,
      rendered
    });
  }

  function scheduleAutoMount(options) {
    const opts = options || {};
    const windowRef = opts.window || root;
    let attempts = 0;
    let stopped = false;

    function attempt() {
      if (stopped) return null;
      attempts += 1;
      const result = ensureProfileAnkiPreviewMounted(opts);
      if (result.mounted || attempts >= MAX_RETRIES) {
        stopped = true;
      }
      return result;
    }

    if (windowRef.document && windowRef.document.readyState === "loading" && typeof windowRef.addEventListener === "function") {
      windowRef.addEventListener("DOMContentLoaded", attempt, { once: true });
    } else {
      attempt();
    }

    if (typeof windowRef.setInterval === "function") {
      const timer = windowRef.setInterval(() => {
        const result = attempt();
        if (stopped && typeof windowRef.clearInterval === "function") {
          windowRef.clearInterval(timer);
        }
        return result;
      }, 250);
    }

    return Object.freeze({
      marker: PATCH_MARKER,
      scheduled: true,
      maxRetries: MAX_RETRIES
    });
  }

  const api = Object.freeze({
    marker: PATCH_MARKER,
    mountId: MOUNT_ID,
    isProfileSurface,
    findProfileTarget,
    ensureProfileAnkiPreviewMounted,
    scheduleAutoMount
  });

  root.APC_PROFILE_ANKI_PREVIEW_MOUNT = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }

  if (root && root.document && root.APC_PROFILE_ANKI_PREVIEW_MOUNT_DISABLED !== true) {
    root.document.addEventListener("apc-private-page-rendered", function () {
      scheduleAutoMount();
    });
    scheduleAutoMount();
  }
})(typeof globalThis !== "undefined" ? globalThis : window);
