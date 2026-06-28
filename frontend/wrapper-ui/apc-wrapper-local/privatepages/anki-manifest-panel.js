(function () {
  "use strict";

  const PANEL_ID = "apcAnkiManifestProfilePanel";
  const TEXTAREA_ID = "apcAnkiManifestProfileInput";
  const STORAGE_PREFIX = "apcProfileAnkiManifest:";

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

  function renderPanelHtml(manifest, message) {
    const summary = manifestSummary(manifest);
    const loaded = Boolean(manifest);
    const safeMessage = message ? '<p class="profile-preference-save-message">' + escapeHtml(message) + '</p>' : '';
    return ''
      + '<section class="summary-card profile-preferences-card apc-anki-manifest-card" id="' + PANEL_ID + '">'
      + '  <span class="eyebrow">Stage 17H · Anki Manifest</span>'
      + '  <strong>Profile Anki discovery manifest</strong>'
      + '  <p>Paste an APC Anki discovery manifest here to save deck availability with your profile. This is browser-local and read-only for now.</p>'
      + '  <div class="profile-preference-list apc-anki-summary-list">'
      + '    <div class="profile-preference-row"><span>Status</span><strong>' + escapeHtml(summary.status) + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Profiles</span><strong>' + summary.profileCount + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Decks</span><strong>' + summary.deckCount + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Cards / notes</span><strong>' + summary.cardCount + ' / ' + summary.noteCount + '</strong></div>'
      + '    <div class="profile-preference-row"><span>Media files</span><strong>' + summary.mediaFileCount + '</strong></div>'
      + '  </div>'
      + '  <div class="apc-anki-profile-list">' + renderProfiles(manifest) + '</div>'
      + '  <details class="apc-anki-manifest-details"' + (loaded ? '' : ' open') + '>'
      + '    <summary>Paste/update discovery manifest</summary>'
      + '    <p class="muted">Generate with ops/anki/anki_readonly_discovery.py and ops/anki/anki_discovery_manifest.py, then paste the JSON here.</p>'
      + '    <textarea id="' + TEXTAREA_ID + '" rows="8" spellcheck="false" placeholder="Paste /tmp/apc-anki-manifest.json here"></textarea>'
      + '    <div class="profile-preference-actions">'
      + '      <button class="primary-btn" type="button" data-anki-manifest-action="load">Save manifest to profile</button>'
      + '      <button class="ghost-btn" type="button" data-anki-manifest-action="clear">Clear saved manifest</button>'
      + '    </div>'
      +      safeMessage
      + '  </details>'
      + '  <p class="muted">Safety: no Anki writes, no card import, no media copy, no backend save, no DB migration.</p>'
      + '</section>';
  }

  function bindPanel(panel) {
    const textarea = panel.querySelector("#" + TEXTAREA_ID);
    const loadButton = panel.querySelector('[data-anki-manifest-action="load"]');
    const clearButton = panel.querySelector('[data-anki-manifest-action="clear"]');

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

    observer.observe(app, { childList: true, subtree: true });
  }

  window.addEventListener("DOMContentLoaded", function () {
    installRouteMutationObserver();
    scheduleMount();
  });
  window.addEventListener("popstate", scheduleMount);
  window.addEventListener("hashchange", scheduleMount);
  document.addEventListener("click", function () {
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
