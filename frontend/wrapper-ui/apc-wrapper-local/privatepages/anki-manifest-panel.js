(function () {
  "use strict";

  const PANEL_ID = "apcAnkiManifestPanel";
  const TEXTAREA_ID = "apcAnkiManifestInput";
  const STORAGE_PREFIX = "apcPrivateAnkiDiscoveryManifest:";

  function getUserEmail() {
    try {
      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me
        ? window.APC_PRIVATEPAGES.me()
        : null;
      const email = user && user.email ? String(user.email).trim().toLowerCase() : "";
      if (email) return email;
    } catch (_error) {
      // Ignore private page lookup errors.
    }
    try {
      const last = window.localStorage ? window.localStorage.getItem("apcLastKnownSignedInEmail") : "";
      return String(last || "local-user").trim().toLowerCase() || "local-user";
    } catch (_error) {
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
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function readStoredManifest() {
    try {
      const raw = window.localStorage ? window.localStorage.getItem(storageKey()) : "";
      return raw ? JSON.parse(raw) : null;
    } catch (_error) {
      return null;
    }
  }

  function writeStoredManifest(manifest) {
    if (!window.localStorage) return;
    window.localStorage.setItem(storageKey(), JSON.stringify(manifest));
  }

  function clearStoredManifest() {
    if (!window.localStorage) return;
    window.localStorage.removeItem(storageKey());
  }

  function summarizeManifest(manifest) {
    const summary = manifest && manifest.summary ? manifest.summary : {};
    return {
      status: manifest && manifest.status ? String(manifest.status) : "not_loaded",
      profileCount: Number(summary.profile_count || 0),
      deckCount: Number(summary.deck_count || 0),
      cardCount: Number(summary.card_count || 0),
      noteCount: Number(summary.note_count || 0),
      mediaFileCount: Number(summary.media_file_count || 0),
      ankiRunning: !!(manifest && manifest.source && manifest.source.anki_running),
      writesPerformed: !!(manifest && manifest.safety && manifest.safety.writes_performed),
      cardsImported: !!(manifest && manifest.safety && manifest.safety.cards_imported),
      mediaCopied: !!(manifest && manifest.safety && manifest.safety.media_copied)
    };
  }

  function renderDeckRows(manifest) {
    const profiles = manifest && Array.isArray(manifest.profiles) ? manifest.profiles : [];
    if (!profiles.length) {
      return '<p class="study-muted">No Anki discovery manifest loaded yet.</p>';
    }

    return profiles.map(function (profile) {
      const decks = Array.isArray(profile.decks) ? profile.decks : [];
      const deckRows = decks.length
        ? decks.map(function (deck) {
            return ''
              + '<article class="study-row apc-anki-deck-row">'
              + '  <div>'
              + '    <h3>' + escapeHtml(deck.name || "Unnamed Anki deck") + '</h3>'
              + '    <small>'
              +        Number(deck.card_count || 0) + ' card(s) · '
              +        Number(deck.note_count || 0) + ' note(s) · '
              +        (deck.media_present ? 'media referenced' : 'no deck media detected')
              + '    </small>'
              + '  </div>'
              + '  <div class="study-row-actions">'
              + '    <span class="pill">Read-only</span>'
              + '  </div>'
              + '</article>';
          }).join("")
        : '<p class="study-muted">No decks found in this Anki profile.</p>';

      return ''
        + '<div class="apc-anki-profile-block">'
        + '  <div class="study-row">'
        + '    <div>'
        + '      <h3>Profile: ' + escapeHtml(profile.profile_name || "Unknown profile") + '</h3>'
        + '      <small>'
        +          Number(profile.total_card_count || 0) + ' card(s) · '
        +          Number(profile.total_note_count || 0) + ' note(s) · '
        +          (profile.media_present ? 'collection.media present' : 'no media folder detected')
        +          ' · ' + Number(profile.media_file_count || 0) + ' media file(s)'
        + '      </small>'
        + '    </div>'
        + '  </div>'
        + deckRows
        + '</div>';
    }).join("");
  }

  function renderPanel() {
    const panel = document.getElementById(PANEL_ID);
    if (!panel) return;

    const manifest = readStoredManifest();
    const summary = summarizeManifest(manifest);
    const statusText = manifest
      ? 'Manifest loaded: ' + summary.deckCount + ' deck(s), ' + summary.cardCount + ' card(s), ' + summary.noteCount + ' note(s).'
      : 'Paste a Stage 17C APC Anki discovery manifest to preview Anki decks.';

    panel.innerHTML = ''
      + '<section class="study-card apc-anki-manifest-card">'
      + '  <div class="study-section-header">'
      + '    <div>'
      + '      <p class="eyebrow">Stage 17D · Anki Discovery</p>'
      + '      <h2>Anki decks found locally</h2>'
      + '      <p class="study-muted">' + escapeHtml(statusText) + '</p>'
      + '    </div>'
      + '    <span class="pill">Read-only</span>'
      + '  </div>'
      + '  <div class="study-list compact">'
      +        renderDeckRows(manifest)
      + '  </div>'
      + '  <div class="summary-grid compact">'
      + '    <div><strong>' + summary.profileCount + '</strong><small>Profiles</small></div>'
      + '    <div><strong>' + summary.deckCount + '</strong><small>Decks</small></div>'
      + '    <div><strong>' + summary.cardCount + '</strong><small>Cards</small></div>'
      + '    <div><strong>' + summary.mediaFileCount + '</strong><small>Media files</small></div>'
      + '  </div>'
      + '  <details class="apc-anki-manifest-details">'
      + '    <summary>Paste/update discovery manifest</summary>'
      + '    <p class="study-muted">This panel only stores a manifest copy in browser localStorage for display. It does not import cards, copy media, or write to Anki.</p>'
      + '    <textarea id="' + TEXTAREA_ID + '" rows="8" spellcheck="false" placeholder="Paste /tmp/apc-anki-manifest.json here"></textarea>'
      + '    <div class="study-actions">'
      + '      <button class="study-button" type="button" data-anki-manifest-action="load">Load manifest</button>'
      + '      <button class="study-button secondary" type="button" data-anki-manifest-action="clear">Clear manifest</button>'
      + '    </div>'
      + '  </details>'
      + '  <p class="study-muted">Safety: no Anki writes, no cards imported, no media copied, no destructive actions.</p>'
      + '</section>';

    const textarea = document.getElementById(TEXTAREA_ID);
    if (textarea && manifest) {
      textarea.value = JSON.stringify(manifest, null, 2);
    }

    const loadButton = panel.querySelector('[data-anki-manifest-action="load"]');
    if (loadButton) {
      loadButton.addEventListener("click", function () {
        const input = document.getElementById(TEXTAREA_ID);
        try {
          const parsed = JSON.parse(input ? input.value : "");
          if (!parsed || parsed.tool !== "apc_anki_discovery_manifest") {
            throw new Error("Expected tool=apc_anki_discovery_manifest");
          }
          if (parsed.safety && parsed.safety.writes_performed !== false) {
            throw new Error("Manifest safety did not report writes_performed=false");
          }
          writeStoredManifest(parsed);
          renderPanel();
        } catch (error) {
          window.alert("Could not load Anki manifest: " + (error && error.message ? error.message : error));
        }
      });
    }

    const clearButton = panel.querySelector('[data-anki-manifest-action="clear"]');
    if (clearButton) {
      clearButton.addEventListener("click", function () {
        clearStoredManifest();
        renderPanel();
      });
    }
  }

  function mountPanel() {
    if (window.location.pathname !== "/study") return;
    if (document.getElementById(PANEL_ID)) {
      renderPanel();
      return;
    }

    const target =
      document.querySelector("[data-private-page-root]") ||
      document.querySelector("#privatePageRoot") ||
      document.querySelector("main") ||
      document.body;

    if (!target) return;

    const wrapper = document.createElement("div");
    wrapper.id = PANEL_ID;
    wrapper.setAttribute("data-stage17d-anki-manifest-panel", "true");
    target.appendChild(wrapper);
    renderPanel();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", mountPanel);
  } else {
    mountPanel();
  }

  window.APC_ANKI_MANIFEST_PANEL = {
    render: renderPanel,
    storageKey: storageKey
  };
})();
