(function () {
  "use strict";

  const PANEL_ID = "apcAnkiManifestProfilePanel";
  const TEXTAREA_ID = "apcAnkiManifestProfileInput";
  const FILE_INPUT_ID = "apcAnkiFilePickerInput";
  const STORAGE_PREFIX = "apcProfileAnkiManifest:";
  const FILE_PROOF_PREFIX = "apcProfileAnkiFileProof:";
  const STAGE17J_MARKER = "APC_STAGE_17J_ANKI_FILE_PICKER_BROWSER_LOCAL";

  function currentRoute() {
    const raw = window.location && window.location.pathname ? window.location.pathname : "/";
    const clean = raw.replace(/\/+$/, "") || "/";
    return clean;
  }

  function isProfileRoute() {
    return currentRoute() === "/profile";
  }

  function getUserEmail() {
    try {
      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me
        ? window.APC_PRIVATEPAGES.me()
        : null;
      const email = user && user.email ? String(user.email).trim().toLowerCase() : "";
      if (email) return email;
      const last = window.localStorage ? window.localStorage.getItem("apcLastKnownSignedInEmail") : "";
      return String(last || "local-user").trim().toLowerCase() || "local-user";
    } catch (error) {
      return "local-user";
    }
  }

  function storageKey() {
    return STORAGE_PREFIX + getUserEmail();
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function readSavedManifest() {
    try {
      if (!window.localStorage) return null;
      const raw = window.localStorage.getItem(storageKey());
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (error) {
      return null;
    }
  }

  function saveManifest(manifest) {
    if (!window.localStorage) return;
    window.localStorage.setItem(storageKey(), JSON.stringify(manifest));
  }

  function clearManifest() {
    if (!window.localStorage) return;
    window.localStorage.removeItem(storageKey());
  }

  function fileProofStorageKey() {
    return FILE_PROOF_PREFIX + getUserEmail();
  }

  function readSavedFileProof() {
    try {
      if (!window.localStorage) return null;
      const raw = window.localStorage.getItem(fileProofStorageKey());
      return raw ? JSON.parse(raw) : null;
    } catch (error) {
      return null;
    }
  }

  function saveFileProof(proof) {
    if (!window.localStorage) return;
    window.localStorage.setItem(fileProofStorageKey(), JSON.stringify(proof));
  }

  function clearFileProof() {
    if (!window.localStorage) return;
    window.localStorage.removeItem(fileProofStorageKey());
  }

  function formatBytes(bytes) {
    const n = Number(bytes || 0);
    if (!Number.isFinite(n) || n <= 0) return "0 B";
    const units = ["B", "KB", "MB", "GB"];
    let value = n;
    let unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value = value / 1024;
      unit += 1;
    }
    return value.toFixed(value >= 10 || unit === 0 ? 0 : 1) + " " + units[unit];
  }

  function hexFromBuffer(buffer) {
    return Array.from(new Uint8Array(buffer))
      .map(function (byte) { return byte.toString(16).padStart(2, "0"); })
      .join("");
  }

  function headerKind(bytes) {
    const text = Array.from(bytes.slice(0, 16))
      .map(function (byte) { return byte >= 32 && byte <= 126 ? String.fromCharCode(byte) : "."; })
      .join("");

    if (text.indexOf("SQLite format 3") === 0) return "sqlite-anki-collection";
    if (bytes[0] === 0x50 && bytes[1] === 0x4b) return "zip-anki-package";
    return "unknown";
  }

  async function buildFileProof(file) {
    const name = String(file && file.name ? file.name : "");
    const extension = name.includes(".") ? name.split(".").pop().toLowerCase() : "";
    const allowed = ["anki2", "anki21", "apkg", "colpkg"].includes(extension);
    const sampleBuffer = await file.slice(0, 1024 * 1024).arrayBuffer();
    const sampleBytes = new Uint8Array(sampleBuffer.slice(0, 16));
    const digest = window.crypto && window.crypto.subtle
      ? await window.crypto.subtle.digest("SHA-256", sampleBuffer)
      : null;

    return {
      marker: STAGE17J_MARKER,
      status: allowed ? "selected" : "unsupported-extension",
      name,
      extension,
      size_bytes: Number(file.size || 0),
      size_label: formatBytes(file.size || 0),
      last_modified: file.lastModified ? new Date(file.lastModified).toISOString() : "",
      header_kind: headerKind(sampleBytes),
      sample_sha256: digest ? hexFromBuffer(digest) : "",
      sample_bytes: sampleBuffer.byteLength,
      note: "Browser-local proof only. Stage 17J does not upload, parse SQLite, modify Anki, or store full file contents."
    };
  }

  function validateManifest(manifest) {
    if (!manifest || typeof manifest !== "object") {
      return "Manifest must be a JSON object.";
    }
    if (manifest.tool !== "apc_anki_discovery_manifest") {
      return "Manifest tool must be apc_anki_discovery_manifest.";
    }
    if (!manifest.safety || manifest.safety.writes_performed !== false) {
      return "Manifest safety must explicitly report writes_performed=false.";
    }
    if (manifest.safety.cards_imported !== false || manifest.safety.media_copied !== false) {
      return "Manifest must be discovery-only: cards_imported=false and media_copied=false.";
    }
    return "";
  }

  function manifestSummary(manifest) {
    const summary = manifest && manifest.summary ? manifest.summary : {};
    return {
      status: manifest && manifest.status ? String(manifest.status) : "not loaded",
      profileCount: Number(summary.profile_count || 0),
      deckCount: Number(summary.deck_count || 0),
      cardCount: Number(summary.card_count || 0),
      noteCount: Number(summary.note_count || 0),
      mediaFileCount: Number(summary.media_file_count || 0),
    };
  }

  function renderDeckRows(profile) {
    const decks = Array.isArray(profile.decks) ? profile.decks : [];
    if (!decks.length) {
      return '<p class="muted">No decks found in this Anki profile.</p>';
    }
    return '<div class="profile-preference-list apc-anki-deck-list">'
      + decks.map(function (deck) {
        return '<div class="profile-preference-row apc-anki-deck-row">'
          + '  <span>'
          + '    <strong>' + escapeHtml(deck.name || "Unnamed deck") + '</strong>'
          + '    <small>'
          +        Number(deck.card_count || 0) + ' card(s) · '
          +        Number(deck.note_count || 0) + ' note(s) · '
          +        escapeHtml(deck.import_status || "available")
          + '    </small>'
          + '  </span>'
          + '  <strong>Read-only</strong>'
          + '</div>';
      }).join("")
      + '</div>';
  }

  function renderProfiles(manifest) {
    const profiles = manifest && Array.isArray(manifest.profiles) ? manifest.profiles : [];
    if (!profiles.length) {
      return '<p class="muted">No Anki profiles are loaded yet.</p>';
    }
    return profiles.map(function (profile) {
      return '<div class="apc-anki-profile-block">'
        + '<h3>Profile: ' + escapeHtml(profile.profile_name || "Unknown profile") + '</h3>'
        + '<p class="muted">'
        +   Number(profile.total_card_count || 0) + ' card(s) · '
        +   Number(profile.total_note_count || 0) + ' note(s) · '
        +   (profile.media_present ? 'collection.media present' : 'no media folder detected')
        +   ' · ' + Number(profile.media_file_count || 0) + ' media file(s)'
        + '</p>'
        + renderDeckRows(profile)
        + '</div>';
    }).join("");
  }

  function renderFilePickerHtml(fileProof) {
    const hasProof = Boolean(fileProof);
    const status = hasProof ? escapeHtml(fileProof.status || "selected") : "not selected";
    const fileName = hasProof ? escapeHtml(fileProof.name || "") : "No file selected yet";
    const fileSize = hasProof ? escapeHtml(fileProof.size_label || "") : "—";
    const header = hasProof ? escapeHtml(fileProof.header_kind || "unknown") : "—";
    const modified = hasProof ? escapeHtml(fileProof.last_modified || "unknown") : "—";
    const sampleHash = hasProof && fileProof.sample_sha256
      ? escapeHtml(String(fileProof.sample_sha256).slice(0, 24) + "…")
      : "—";

    return ''
      + '<details class="apc-anki-manifest-details apc-anki-file-picker-details">'
      + '  <summary>Choose Anki file</summary>'
      + '  <p class="muted">Choose a file yourself. APC can only read what you explicitly select, and Stage 17J only stores a browser-local proof.</p>'
      + '  <div class="profile-preference-list apc-anki-location-list">'
      + '    <div class="profile-preference-row"><span>Windows desktop</span><strong>%APPDATA%\\Anki2\\&lt;Profile&gt;\\collection.anki2</strong></div>'
      + '    <div class="profile-preference-row"><span>macOS desktop</span><strong>~/Library/Application Support/Anki2/&lt;Profile&gt;/collection.anki2</strong></div>'
      + '    <div class="profile-preference-row"><span>Linux desktop</span><strong>~/.local/share/Anki2/&lt;Profile&gt;/collection.anki2</strong></div>'
      + '    <div class="profile-preference-row"><span>Linux Flatpak</span><strong>~/.var/app/net.ankiweb.Anki/data/Anki2/&lt;Profile&gt;/collection.anki2</strong></div>'
      + '    <div class="profile-preference-row"><span>Android / AnkiDroid</span><strong>Prefer Export collection → collection.apkg, or check Settings → Advanced → AnkiDroid Directory</strong></div>'
      + '    <div class="profile-preference-row"><span>iPhone / iPad AnkiMobile</span><strong>Prefer Add/Export → Export to Share/Finder/iTunes → collection.colpkg</strong></div>'
      + '  </div>'
      + '  <p class="muted">Accepted files: collection.anki2, collection.anki21, .apkg, .colpkg. Close Anki before selecting a live collection file.</p>'
      + '  <input id="' + FILE_INPUT_ID + '" type="file" accept=".anki2,.anki21,.apkg,.colpkg,application/zip,application/octet-stream" />'
      + '  <div class="profile-preference-actions">'
      + '    <button class="ghost-btn" type="button" data-anki-file-action="clear">Clear selected file proof</button>'
      + '  </div>'
      + '  <div class="profile-preference-list apc-anki-file-proof-list">'
      + '    <div class="profile-preference-row"><span>File status</span><strong>' + status + '</strong></div>'
      + '    <div class="profile-preference-row"><span>File name</span><strong>' + fileName + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Size</span><strong>' + fileSize + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Header</span><strong>' + header + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Modified</span><strong>' + modified + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Sample SHA-256</span><strong>' + sampleHash + '</strong></div>'
      + '  </div>'
      + '  <p class="muted">Stage 17J reads only the first 1 MiB for a file proof. Stage 17K can add browser-side deck extraction.</p>'
      + '</details>';
  }

  function renderPanelHtml(manifest, message) {
    const safeMessage = message ? '<p class="profile-preference-save-message">' + escapeHtml(message) + '</p>' : '';
    return ''
      + '<section class="summary-card profile-preferences-card apc-anki-manifest-card" id="' + PANEL_ID + '">'
      + '  <span class="eyebrow">Anki file picker</span>'
      + '  <strong>Choose your Anki file</strong>'
      + '  <p>Select your Anki collection or export file. APC reads only a browser-local proof for now; deck extraction comes next.</p>'
      + renderFilePickerHtml(readSavedFileProof())
      + safeMessage
      + '  <p class="muted">Safety: browser-local only, no Anki writes, no card import, no media copy, no backend save, no DB migration, no full-file storage.</p>'
      + '</section>';
  }

  function bindPanel(panel) {
    const textarea = panel.querySelector("#" + TEXTAREA_ID);
    const fileInput = panel.querySelector("#" + FILE_INPUT_ID);
    const loadButton = panel.querySelector('[data-anki-manifest-action="load"]');
    const clearButton = panel.querySelector('[data-anki-manifest-action="clear"]');
    const clearFileButton = panel.querySelector('[data-anki-file-action="clear"]');

    if (fileInput) {
      fileInput.addEventListener("change", async function () {
        const file = fileInput.files && fileInput.files[0] ? fileInput.files[0] : null;
        if (!file) return;
        try {
          const proof = await buildFileProof(file);
          saveFileProof(proof);
          mountPanel("Anki file proof saved locally: " + proof.name);
        } catch (error) {
          mountPanel("Could not read selected Anki file proof: " + (error && error.message ? error.message : error));
        }
      });
    }

    if (clearFileButton) {
      clearFileButton.addEventListener("click", function () {
        clearFileProof();
        mountPanel("Selected Anki file proof cleared.");
      });
    }

    if (loadButton) {
      loadButton.addEventListener("click", function () {
        try {
          const manifest = JSON.parse(textarea ? textarea.value : "");
          const validationError = validateManifest(manifest);
          if (validationError) {
            mountPanel(validationError);
            return;
          }
          saveManifest(manifest);
          mountPanel("Anki manifest saved to this browser profile.");
        } catch (error) {
          mountPanel("Could not parse manifest JSON: " + (error && error.message ? error.message : error));
        }
      });
    }

    if (clearButton) {
      clearButton.addEventListener("click", function () {
        clearManifest();
        mountPanel("Saved Anki manifest cleared.");
      });
    }
  }

  function findProfileAnchor() {
    const app = document.getElementById("app") || document.body;
    if (!app) return null;

    const privateGrid = app.querySelector(".private-grid");
    if (privateGrid) {
      const cards = Array.from(privateGrid.querySelectorAll(".private-card"));
      const preferencesCard = cards.find(function (card) {
        return /Preferences/i.test(String(card.textContent || ""));
      });
      if (preferencesCard && preferencesCard.parentElement) {
        return preferencesCard.parentElement;
      }
      return privateGrid;
    }

    return document.querySelector(".profile-page")
      || document.querySelector('[data-current-route="/profile"] #app')
      || app;
  }

  function mountPanel(message) {
    if (!isProfileRoute()) {
      const existing = document.getElementById(PANEL_ID);
      if (existing) existing.remove();
      return;
    }

    const anchor = findProfileAnchor();
    if (!anchor) return;

    const manifest = readSavedManifest();
    const existing = document.getElementById(PANEL_ID);
    const wrapper = document.createElement("div");
    wrapper.innerHTML = renderPanelHtml(manifest, message || "");
    const panel = wrapper.firstElementChild;
    if (!panel) return;

    if (existing) {
      existing.replaceWith(panel);
    } else {
      anchor.appendChild(panel);
    }
    bindPanel(panel);
  }

  function scheduleMount() {
    window.setTimeout(function () { mountPanel(""); }, 0);
    window.setTimeout(function () { mountPanel(""); }, 250);
    window.setTimeout(function () { mountPanel(""); }, 1000);
    window.setTimeout(function () { mountPanel(""); }, 2000);
  }

  function installRouteMutationObserver() {
    const app = document.getElementById("app");
    if (!app || app.dataset.apcAnkiManifestObserver === "true") return;
    app.dataset.apcAnkiManifestObserver = "true";

    const observer = new MutationObserver(function () {
      if (!isProfileRoute()) return;
      window.clearTimeout(installRouteMutationObserver._timer);
      installRouteMutationObserver._timer = window.setTimeout(function () {
        mountPanel("");
      }, 80);
    });

    observer.observe(app, { childList: true, subtree: false });
  }

  window.addEventListener("DOMContentLoaded", function () {
    installRouteMutationObserver();
    scheduleMount();
  });
  window.addEventListener("popstate", scheduleMount);
  window.addEventListener("hashchange", scheduleMount);
  document.addEventListener("apc-private-page-rendered", function (event) {
    const page = event && event.detail ? event.detail.page : "";
    if (page === "profile") scheduleMount();
  });
  document.addEventListener("click", function (event) {
    if (event && event.target && event.target.closest && event.target.closest("#" + PANEL_ID)) {
      return;
    }

    window.setTimeout(function () {
      installRouteMutationObserver();
      scheduleMount();
    }, 50);
  });

  if (document.readyState === "interactive" || document.readyState === "complete") {
    installRouteMutationObserver();
    scheduleMount();
  }

  window.APC_PROFILE_ANKI_MANIFEST_PANEL = {
    mount: mountPanel,
    readSavedManifest: readSavedManifest,
    validateManifest: validateManifest,
  };
})();
