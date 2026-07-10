(function apcProfileBackupFolderCardStyleGuardR16CE(root) {
  "use strict";

  const MARKER = "APC_PROFILE_BACKUP_FOLDER_CARD_STYLE_GUARD_R16CE";
  const STYLE_ID = "apc-profile-backup-folder-card-style-guard-r16ce";
  const PANEL_SELECTOR = "[data-apc-local-backup-folder-panel-r16cb='true']";

  const CSS = String.raw`/* R16CE: strong card-style guard for the one visible local-backup-folder box. */
:root {
  --apc-backup-card-bg: #ffffff;
  --apc-backup-card-ink: #22352b;
  --apc-backup-card-muted: rgba(34, 53, 43, 0.68);
  --apc-backup-card-border: rgba(43, 70, 54, 0.13);
  --apc-backup-card-soft: rgba(49, 83, 63, 0.07);
  --apc-backup-card-green: #284734;
}

[data-apc-local-backup-folder-panel-r16cb="true"].apc-profile-backup-folder-panel,
article[data-apc-local-backup-folder-panel-r16cb="true"],
.private-card[data-apc-local-backup-folder-panel-r16cb="true"] {
  box-sizing: border-box !important;
  display: block !important;
  width: 100% !important;
  margin: 1rem 0 0 !important;
  padding: clamp(1rem, 2vw, 1.35rem) !important;
  border: 1px solid var(--apc-backup-card-border) !important;
  border-radius: 22px !important;
  background: var(--apc-backup-card-bg) !important;
  color: var(--apc-backup-card-ink) !important;
  box-shadow: 0 18px 40px rgba(28, 52, 39, 0.08) !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] h2 {
  margin: 0 0 0.45rem !important;
  color: #1f3b2d !important;
  font-size: clamp(1.2rem, 2vw, 1.45rem) !important;
  line-height: 1.2 !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] p {
  margin: 0.55rem 0 0 !important;
  max-width: 74ch !important;
  color: var(--apc-backup-card-muted) !important;
  line-height: 1.55 !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] p:first-of-type {
  color: rgba(34, 53, 43, 0.82) !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] strong {
  color: #1f3b2d !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-actions {
  display: grid !important;
  grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)) !important;
  gap: 0.7rem !important;
  margin: 1rem 0 0.85rem !important;
  align-items: stretch !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-actions button,
[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-file-label {
  appearance: none !important;
  box-sizing: border-box !important;
  min-height: 44px !important;
  width: 100% !important;
  display: inline-flex !important;
  align-items: center !important;
  justify-content: center !important;
  gap: 0.45rem !important;
  padding: 0.75rem 1rem !important;
  border-radius: 999px !important;
  border: 1px solid rgba(43, 70, 54, 0.16) !important;
  font: inherit !important;
  font-weight: 750 !important;
  line-height: 1.1 !important;
  cursor: pointer !important;
  text-decoration: none !important;
  transition: transform 140ms ease, box-shadow 140ms ease, filter 140ms ease !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-actions button:hover,
[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-file-label:hover {
  transform: translateY(-1px) !important;
  filter: brightness(1.03) !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] [data-apc-pick-backup-folder],
[data-apc-local-backup-folder-panel-r16cb="true"] [data-apc-save-backup-folder] {
  background: var(--apc-backup-card-green) !important;
  color: #fff !important;
  box-shadow: 0 10px 22px rgba(40, 71, 52, 0.18) !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] [data-apc-scan-backup-folder],
[data-apc-local-backup-folder-panel-r16cb="true"] [data-apc-download-backup-snapshot],
[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-file-label {
  background: #fff !important;
  color: #24372d !important;
  box-shadow: 0 7px 16px rgba(28, 52, 39, 0.07) !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-file-label input[type="file"] {
  position: fixed !important;
  left: -10000px !important;
  top: auto !important;
  width: 1px !important;
  height: 1px !important;
  opacity: 0 !important;
  pointer-events: none !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-status {
  margin-top: 0.95rem !important;
  padding: 0.85rem 0.95rem !important;
  border: 1px solid rgba(43, 70, 54, 0.12) !important;
  border-radius: 16px !important;
  background: linear-gradient(180deg, rgba(49, 83, 63, 0.08), rgba(49, 83, 63, 0.045)) !important;
  color: #253a2e !important;
  line-height: 1.45 !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-status:empty,
[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-details:empty {
  display: none !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-details {
  margin-top: 0.95rem !important;
  padding: 1rem !important;
  border: 1px solid rgba(43, 70, 54, 0.12) !important;
  border-radius: 18px !important;
  background: #fbfdfb !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-grid {
  display: grid !important;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)) !important;
  gap: 0.65rem !important;
  margin: 0.85rem 0 !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-grid span {
  min-height: 4.2rem !important;
  padding: 0.75rem !important;
  border: 1px solid rgba(43, 70, 54, 0.1) !important;
  border-radius: 14px !important;
  background: #fff !important;
  box-shadow: 0 8px 18px rgba(28, 52, 39, 0.05) !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-grid strong {
  display: block !important;
  margin-bottom: 0.2rem !important;
  font-size: 1.2rem !important;
}

[data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-folder-grid small {
  display: block !important;
  color: rgba(34, 53, 43, 0.62) !important;
  font-size: 0.76rem !important;
  letter-spacing: 0.04em !important;
  text-transform: uppercase !important;
}

@media (max-width: 640px) {
  [data-apc-local-backup-folder-panel-r16cb="true"] .apc-profile-backup-actions {
    grid-template-columns: 1fr !important;
  }
}
`;

  function ensureStyles() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.setAttribute("data-apc-stage", MARKER);
    style.textContent = CSS;
    (document.head || document.documentElement).appendChild(style);
  }

  function normalizePanel() {
    ensureStyles();
    const panel = document.querySelector(PANEL_SELECTOR);
    if (!panel) return false;
    panel.classList.add("private-card", "apc-profile-backup-folder-panel", "apc-profile-backup-folder-card-r16ce");
    const fileInput = panel.querySelector("input[type='file'][data-apc-preview-backup-file]");
    if (fileInput) {
      fileInput.setAttribute("tabindex", "-1");
      fileInput.setAttribute("aria-hidden", "true");
    }
    const fileLabel = panel.querySelector(".apc-profile-backup-file-label");
    if (fileLabel) fileLabel.setAttribute("role", "button");
    return true;
  }

  function boot() {
    ensureStyles();
    normalizePanel();
    try {
      const observer = new MutationObserver(() => normalizePanel());
      observer.observe(document.documentElement || document.body, { childList: true, subtree: true });
      root.setTimeout(() => { try { observer.disconnect(); } catch (_) {} }, 15000);
    } catch (_) {}
  }

  root.APC_PROFILE_BACKUP_FOLDER_CARD_STYLE_GUARD_R16CE = {
    marker: MARKER,
    styleId: STYLE_ID,
    panelSelector: PANEL_SELECTOR,
    ensureStyles,
    normalizePanel
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})(window);
