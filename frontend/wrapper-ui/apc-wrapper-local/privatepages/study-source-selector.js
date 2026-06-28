(function () {
  "use strict";

  var VERSION = "stage17kh-study-source-selector-ui-20260628";
  var PANEL_ID = "apc-study-source-selector";
  var SELECTION_KEY = "apc.study.sourceSelection.v1";
  var ANKI_SUMMARY_KEY = "apc.profile.anki.localDeckSummary.v1";

  var mountTimer = null;

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function readJson(key) {
    try {
      var raw = window.localStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  function writeJson(key, value) {
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch (_) {}
  }

  function removeKey(key) {
    try {
      window.localStorage.removeItem(key);
    } catch (_) {}
  }

  function readAnkiSummary() {
    var api = window.APC_ANKI_LOCAL;
    if (api && typeof api.readSavedDeckSummary === "function") {
      return api.readSavedDeckSummary();
    }
    return readJson(ANKI_SUMMARY_KEY);
  }

  function readSelection() {
    return readJson(SELECTION_KEY);
  }

  function saveSelection(selection) {
    writeJson(SELECTION_KEY, selection);
  }

  function clearSelection() {
    removeKey(SELECTION_KEY);
  }

  function isStudyOrCompanionRoute() {
    var routeText = String(window.location.pathname + " " + window.location.hash).toLowerCase();
    if (routeText.indexOf("study") !== -1) return true;
    if (routeText.indexOf("companion") !== -1) return true;
    if (document.querySelector("#companionPrivateApp, .sol-study-box, [data-page='study'], [data-page='companion']")) return true;
    return false;
  }

  function findHost() {
    return document.querySelector("[data-page='study']")
      || document.querySelector("#companionPrivateApp")
      || document.querySelector(".sol-study-box")
      || document.querySelector("main")
      || document.body;
  }

  function ankiDeckRows(summary, selection) {
    var decks = summary && Array.isArray(summary.decks) ? summary.decks : [];
    if (!summary || summary.status !== "extracted") {
      return ''
        + '<p class="study-muted">No browser-local Anki deck summary is loaded yet. Go to Profile, choose your Anki file, then return here.</p>';
    }

    if (!decks.length) {
      return '<p class="study-muted">No Anki decks with cards were found in the local browser summary.</p>';
    }

    return decks.map(function (deck) {
      var selected = selection
        && selection.source_type === "anki_browser_local"
        && String(selection.deck_id) === String(deck.id);

      return ''
        + '<button type="button" class="study-button ' + (selected ? '' : 'secondary') + '"'
        + ' data-study-source-action="select-anki-deck"'
        + ' data-deck-id="' + escapeHtml(deck.id) + '"'
        + ' data-deck-name="' + escapeHtml(deck.name) + '"'
        + ' data-card-count="' + escapeHtml(deck.card_count || 0) + '"'
        + ' data-note-count="' + escapeHtml(deck.note_count || 0) + '">'
        + (selected ? 'Selected: ' : 'Use ')
        + escapeHtml(deck.name)
        + ' · ' + escapeHtml(deck.card_count || 0) + ' cards'
        + '</button>';
    }).join("");
  }

  function renderSelectionStatus(selection) {
    if (!selection) {
      return '<p class="study-muted">No study source selected yet.</p>';
    }

    if (selection.source_type === "anki_browser_local") {
      return ''
        + '<p class="study-muted">'
        + 'Selected source: <strong>Study with Anki</strong>. '
        + 'Deck is browser-local/read-only. No Anki content is sent to the server.'
        + '</p>'
        + '<div class="profile-preference-row"><span>Selected Anki deck</span><strong>' + escapeHtml(selection.deck_name || selection.deck_id || "Unknown") + '</strong></div>';
    }

    if (selection.source_type === "mydecks_apc_native") {
      return ''
        + '<p class="study-muted">'
        + 'Selected source: <strong>Study with MyDecks</strong>. '
        + 'This is the APC-native editable deck path.'
        + '</p>';
    }

    return '<p class="study-muted">Selected source: ' + escapeHtml(selection.source_type || "unknown") + '</p>';
  }

  function renderHtml(message) {
    var summary = readAnkiSummary();
    var selection = readSelection();
    var deckCount = summary && summary.summary ? Number(summary.summary.deck_count_with_cards || 0) : 0;
    var cardCount = summary && summary.summary ? Number(summary.summary.card_count || 0) : 0;
    var hasAnki = summary && summary.status === "extracted";

    return ''
      + '<section id="' + PANEL_ID + '" class="profile-card apc-study-source-selector-card">'
      + '  <h3>Study source</h3>'
      + '  <p class="study-muted">Choose where this study session should come from. Anki stays browser-local and read-only. MyDecks is APC-native.</p>'
      + (message ? '<p class="apc-anki-message">' + escapeHtml(message) + '</p>' : '')
      + renderSelectionStatus(selection)
      + '  <div class="study-grid">'
      + '    <article class="study-row">'
      + '      <div>'
      + '        <strong>Study with Anki</strong>'
      + '        <p class="study-muted">Uses the browser-local Anki summary from Profile. Read-only: no edit, flag, create, delete, or Anki write actions.</p>'
      + '        <p class="study-muted">Local decks loaded: ' + escapeHtml(deckCount) + ' · local cards: ' + escapeHtml(cardCount) + '</p>'
      + '      </div>'
      + '      <div class="study-row-actions">'
      + (hasAnki ? ankiDeckRows(summary, selection) : '<button type="button" class="study-button secondary" disabled>Load Anki in Profile first</button>')
      + '      </div>'
      + '    </article>'
      + '    <article class="study-row">'
      + '      <div>'
      + '        <strong>Study with MyDecks</strong>'
      + '        <p class="study-muted">Uses APC-native decks. This path may allow create/edit/delete/flag according to APC permissions.</p>'
      + '      </div>'
      + '      <div class="study-row-actions">'
      + '        <button type="button" class="study-button secondary" data-study-source-action="select-mydecks">Use MyDecks</button>'
      + '      </div>'
      + '    </article>'
      + '  </div>'
      + '  <details class="apc-anki-manifest-details">'
      + '    <summary>Privacy and permission boundary</summary>'
      + '    <p class="study-muted">Anki deck names, card text, answers, tags, and media remain local to this browser. The selector stores only a browser-local choice in localStorage.</p>'
      + '    <p class="study-muted">Initial Anki server metrics later may be aggregate-only: source type, session completed marker, session length seconds, and cards reviewed count.</p>'
      + '  </details>'
      + '  <button type="button" class="study-button secondary" data-study-source-action="clear-selection">Clear source selection</button>'
      + '</section>';
  }

  function bindPanel(panel) {
    panel.querySelectorAll("[data-study-source-action]").forEach(function (button) {
      button.addEventListener("click", function () {
        var action = button.getAttribute("data-study-source-action");

        if (action === "select-anki-deck") {
          saveSelection({
            source_type: "anki_browser_local",
            source_label: "Study with Anki",
            deck_id: button.getAttribute("data-deck-id") || "",
            deck_name: button.getAttribute("data-deck-name") || "",
            card_count: Number(button.getAttribute("data-card-count") || 0),
            note_count: Number(button.getAttribute("data-note-count") || 0),
            permissions: {
              browser_local_only: true,
              read_only: true,
              can_edit: false,
              can_create: false,
              can_delete: false,
              can_flag: false,
              can_write_anki: false,
              can_upload_anki_content: false
            },
            saved_at: new Date().toISOString()
          });
          renderPanel("Selected Anki deck locally. No Anki content was sent to the server.");
          return;
        }

        if (action === "select-mydecks") {
          saveSelection({
            source_type: "mydecks_apc_native",
            source_label: "Study with MyDecks",
            permissions: {
              browser_local_only: false,
              read_only: false,
              can_edit: true,
              can_create: true,
              can_delete: true,
              can_flag: true,
              can_write_anki: false,
              can_upload_anki_content: false
            },
            saved_at: new Date().toISOString()
          });
          renderPanel("Selected MyDecks as the APC-native study source.");
          return;
        }

        if (action === "clear-selection") {
          clearSelection();
          renderPanel("Study source selection cleared.");
        }
      });
    });
  }

  function renderPanel(message) {
    if (!isStudyOrCompanionRoute()) return;

    var host = findHost();
    if (!host) return;

    var existing = document.getElementById(PANEL_ID);
    if (!existing) {
      existing = document.createElement("section");
      existing.id = PANEL_ID;
      existing.className = "apc-study-source-selector-shell";

      if (host.firstChild) {
        host.insertBefore(existing, host.firstChild);
      } else {
        host.appendChild(existing);
      }
    }

    existing.outerHTML = renderHtml(message);
    bindPanel(document.getElementById(PANEL_ID));
  }

  function scheduleMount() {
    if (mountTimer) window.clearTimeout(mountTimer);
    mountTimer = window.setTimeout(function () {
      renderPanel();
    }, 50);
  }

  window.APC_STUDY_SOURCE_SELECTOR = {
    version: VERSION,
    readAnkiSummary: readAnkiSummary,
    readSelection: readSelection,
    clearSelection: clearSelection,
    renderPanel: renderPanel,
    privacy: {
      anki_browser_local_only: true,
      anki_read_only: true,
      anki_server_content_upload_allowed: false,
      mydecks_native_path_separate: true
    }
  };

  window.addEventListener("DOMContentLoaded", scheduleMount);
  window.addEventListener("popstate", scheduleMount);
  window.addEventListener("hashchange", scheduleMount);
  document.addEventListener("apc-private-page-rendered", scheduleMount);
  document.addEventListener("click", scheduleMount);

  scheduleMount();
})();
