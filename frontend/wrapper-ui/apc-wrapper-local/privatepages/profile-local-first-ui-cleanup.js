(function apcProfileLocalFirstUiCleanupR16CA(root) {
  "use strict";

  const MARKER = "APC_PROFILE_LOCAL_FIRST_UI_CLEANUP_R16CA";
  if (root.APC_PROFILE_LOCAL_FIRST_UI_CLEANUP_R16CA) return;

  const REMOVE_SELECTORS = [
    "[data-apc-complete-local-backup-manager='true']",
    "[data-apc-backup-folder-workspace='true']",
    "[data-apc-profile-local-backups-panel='true']",
    "[data-apc-google-sync-profile-panel='true']",
    "[data-apc-local-backup-save-writer-plan-preview-r13v='true']",
    "[data-apc-local-backup-save-action-status-preview-r14i-r2='true']",
    "[data-apc-local-backup-disabled-save-button-html-preview-r14u='true']",
    "[data-apc-local-backup-current-file-output]"
  ];

  const REMOVE_HEADINGS = new Set([
    "local profile",
    "google drive sync",
    "complete local backup",
    "buddies who study local backups",
    "backup folder workspace",
    "current backup file preview",
    "legacy backend cache sanitizer",
    "sanitized backup payload preview",
    "current backup save plan",
    "current backup save writer plan",
    "current backup save action status"
  ]);

  function closestCard(node) {
    return node && node.closest ? node.closest("section, article, .private-card, .profile-card") : null;
  }

  function cleanupProfile() {
    const path = root.location && root.location.pathname ? root.location.pathname : "";
    if (path !== "/profile") return;

    REMOVE_SELECTORS.forEach((selector) => {
      document.querySelectorAll(selector).forEach((node) => {
        const card = closestCard(node) || node;
        if (card && card.remove) card.remove();
      });
    });

    document.querySelectorAll("h2,h3").forEach((heading) => {
      const text = String(heading.textContent || "").trim().toLowerCase();
      if (!REMOVE_HEADINGS.has(text)) return;
      const card = closestCard(heading);
      if (card && card.remove) card.remove();
    });

    document.querySelectorAll(".private-hero p").forEach((node) => {
      const text = String(node.textContent || "");
      if (text.includes("browser-local@buddies.local") || text.includes("Account information for")) {
        node.textContent = "Manage your companion, study sources, and local browser settings.";
      }
    });
  }

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "profile") {
      setTimeout(cleanupProfile, 0);
      setTimeout(cleanupProfile, 150);
      setTimeout(cleanupProfile, 600);
    }
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", cleanupProfile, { once: true });
  } else {
    cleanupProfile();
  }

  root.APC_PROFILE_LOCAL_FIRST_UI_CLEANUP_R16CA = Object.freeze({ marker: MARKER, cleanupProfile });
})(typeof window !== "undefined" ? window : globalThis);
