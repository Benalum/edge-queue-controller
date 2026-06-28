(function () {
  "use strict";

  var VERSION = "stage17kn-companion-local-anki-bridge-source-20260628";
  var PANEL_ID = "apc-companion-local-anki-bridge";
  var mountTimer = null;

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function ankiApi() {
    return window.APC_ANKI_READONLY_SESSION || null;
  }

  function safeAnkiSnapshot() {
    var api = ankiApi();
    if (!api || typeof api.snapshot !== "function") return null;

    try {
      return api.snapshot();
    } catch (_) {
      return null;
    }
  }

  function safeCurrentCard() {
    var api = ankiApi();
    if (!api || typeof api.currentCard !== "function") return null;

    try {
      return api.currentCard();
    } catch (_) {
      return null;
    }
  }

  function currentCardShape() {
    var snap = safeAnkiSnapshot();
    var card = safeCurrentCard();

    if (!card) {
      return {
        present: false,
        has_question: false,
        has_answer: false,
        deck_name: snap && snap.selected_deck_name || "",
        note_type_name: "",
        question_length: 0,
        answer_length: 0
      };
    }

    return {
      present: true,
      has_question: Boolean(card.question),
      has_answer: Boolean(card.answer),
      deck_name: card.deck_name || snap && snap.selected_deck_name || "",
      note_type_name: card.note_type_name || "",
      question_length: String(card.question || "").length,
      answer_length: String(card.answer || "").length
    };
  }

  function snapshot() {
    var snap = safeAnkiSnapshot();
    var shape = currentCardShape();

    return {
      version: VERSION,
      bridge_ready: true,
      anki_adapter_present: Boolean(ankiApi()),
      source_type: snap && snap.selection_source_type || "",
      status: snap && snap.status || "missing_anki_session",
      active: Boolean(snap && snap.active),
      selected_deck_name: snap && snap.selected_deck_name || "",
      selected_deck_id: snap && snap.selected_deck_id || "",
      card_count_in_memory: Number(snap && snap.card_count_in_memory || 0),
      reviewed_count: Number(snap && snap.reviewed_count || 0),
      correct_count: Number(snap && snap.correct_count || 0),
      wrong_count: Number(snap && snap.wrong_count || 0),
      current_index: Number(snap && snap.current_index || 0),
      current_card_shape: shape,
      privacy: {
        browser_memory_only: true,
        card_text_returned_by_bridge: false,
        backend_calls_allowed: false,
        model_calls_allowed: false,
        anki_write_allowed: false,
        mydecks_writeback_allowed: false
      }
    };
  }

  function isCompanionRoute() {
    var routeText = String(window.location.pathname + " " + window.location.hash).toLowerCase();
    if (routeText.indexOf("companion") !== -1) return true;
    return Boolean(document.querySelector("#companionPrivateApp, [data-page='companion']"));
  }

  function findHost() {
    return document.querySelector("#companionPrivateApp")
      || document.querySelector("[data-page='companion']")
      || document.querySelector("main")
      || document.body;
  }

  function renderHtml() {
    var state = snapshot();
    var shape = state.current_card_shape || {};

    return ''
      + '<section id="' + PANEL_ID + '" class="profile-card apc-companion-local-anki-bridge-card">'
      + '  <h3>Companion local Anki bridge</h3>'
      + '  <p class="study-muted">Browser-memory bridge only. It reports the current local Anki card shape without returning card text.</p>'
      + '  <div class="profile-preference-row"><span>Bridge version</span><strong>' + escapeHtml(VERSION) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Anki adapter</span><strong>' + escapeHtml(state.anki_adapter_present ? "present" : "missing") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Source</span><strong>' + escapeHtml(state.source_type || "none") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Status</span><strong>' + escapeHtml(state.status) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Active</span><strong>' + escapeHtml(state.active ? "yes" : "no") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Deck</span><strong>' + escapeHtml(state.selected_deck_name || "none") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Cards in memory</span><strong>' + escapeHtml(state.card_count_in_memory) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Current card shape</span><strong>' + escapeHtml(shape.present ? "present" : "none") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Question / answer present</span><strong>' + escapeHtml(shape.has_question ? "question" : "no question") + ' / ' + escapeHtml(shape.has_answer ? "answer" : "no answer") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Note type</span><strong>' + escapeHtml(shape.note_type_name || "none") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Reviewed</span><strong>' + escapeHtml(state.reviewed_count) + '</strong></div>'
      + '  <button type="button" class="study-button secondary" data-local-anki-bridge-action="refresh">Refresh local bridge</button>'
      + '  <details class="apc-anki-manifest-details">'
      + '    <summary>Privacy boundary</summary>'
      + '    <p class="study-muted">This bridge does not return card question text or answer text. It exposes only shape and counters for local Companion UI integration.</p>'
      + '    <p class="study-muted">No backend call, model call, Anki write, or MyDecks writeback is allowed by this bridge.</p>'
      + '  </details>'
      + '</section>';
  }

  function bindPanel(panel) {
    panel.querySelectorAll("[data-local-anki-bridge-action='refresh']").forEach(function (button) {
      button.addEventListener("click", renderPanel);
    });
  }

  function renderPanel() {
    if (!isCompanionRoute()) return;

    var host = findHost();
    if (!host) return;

    var existing = document.getElementById(PANEL_ID);
    if (!existing) {
      existing = document.createElement("section");
      existing.id = PANEL_ID;
      if (host.nextSibling && host.parentNode) host.parentNode.insertBefore(existing, host.nextSibling);
      else if (host.parentNode) host.parentNode.appendChild(existing);
      else document.body.appendChild(existing);
    }

    existing.outerHTML = renderHtml();
    bindPanel(document.getElementById(PANEL_ID));
  }

  function scheduleMount() {
    if (mountTimer) window.clearTimeout(mountTimer);
    mountTimer = window.setTimeout(renderPanel, 50);
  }

  window.APC_COMPANION_LOCAL_ANKI_BRIDGE = {
    version: VERSION,
    snapshot: snapshot,
    currentCardShape: currentCardShape,
    renderPanel: renderPanel,
    privacy: {
      browser_memory_only: true,
      card_text_returned_by_bridge: false,
      backend_calls_allowed: false,
      model_calls_allowed: false,
      anki_write_allowed: false,
      mydecks_writeback_allowed: false
    }
  };

  window.addEventListener("DOMContentLoaded", scheduleMount);
  window.addEventListener("hashchange", scheduleMount);
  window.addEventListener("popstate", scheduleMount);
  document.addEventListener("apc-private-page-rendered", scheduleMount);
  document.addEventListener("click", scheduleMount);

  scheduleMount();
})();
