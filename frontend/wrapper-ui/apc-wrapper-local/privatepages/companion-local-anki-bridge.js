(function () {
  "use strict";

  var VERSION = "stage17kv-companion-anki-consented-current-card-handoff-20260628";
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

  function currentCardShapeCommand() {
    var state = snapshot();
    var shape = state.current_card_shape || {};
    var lines = [];

    lines.push("Local Anki bridge status:");
    lines.push("- source: " + (state.source_type || "none"));
    lines.push("- status: " + (state.status || "unknown"));
    lines.push("- active: " + (state.active ? "yes" : "no"));
    lines.push("- deck: " + (state.selected_deck_name || "none"));
    lines.push("- cards in memory: " + String(state.card_count_in_memory || 0));
    lines.push("- current card shape: " + (shape.present ? "present" : "none"));
    lines.push("- question present: " + (shape.has_question ? "yes" : "no"));
    lines.push("- answer present: " + (shape.has_answer ? "yes" : "no"));
    lines.push("- note type: " + (shape.note_type_name || "none"));
    lines.push("");
    lines.push("Privacy: this command does not return card question text or answer text, and it does not call a backend or model.");

    return {
      version: VERSION,
      ok: true,
      command: "current_anki_card_shape",
      message: lines.join("\n"),
      shape: {
        present: Boolean(shape.present),
        has_question: Boolean(shape.has_question),
        has_answer: Boolean(shape.has_answer),
        deck_name: shape.deck_name || "",
        note_type_name: shape.note_type_name || "",
        question_length: Number(shape.question_length || 0),
        answer_length: Number(shape.answer_length || 0)
      },
      privacy: {
        browser_memory_only: true,
        card_text_returned_by_command: false,
        backend_calls_allowed: false,
        model_calls_allowed: false,
        anki_write_allowed: false,
        mydecks_writeback_allowed: false
      }
    };
  }

  function currentAnkiCardForConsent() {
    var api = window.APC_ANKI_READONLY_SESSION;
    if (!api || typeof api.currentCard !== "function") return null;

    try {
      return api.currentCard();
    } catch (error) {
      return null;
    }
  }

  function consentedCurrentAnkiCardForStudyCommand(consented) {
    var state = snapshot();
    var shape = state.current_card_shape || {};
    var card = currentAnkiCardForConsent();
    var allowed = consented === true;
    var present = Boolean(card && (String(card.question || "").trim() || String(card.answer || "").trim()));
    var cardTextReturned = Boolean(allowed && present);
    var lines = [];

    lines.push("Consented local Anki study handoff:");
    lines.push("- consented: " + (allowed ? "yes" : "no"));
    lines.push("- card present: " + (present ? "yes" : "no"));
    lines.push("- deck: " + (shape.deck_name || state.selected_deck_name || "none"));
    lines.push("- note type: " + (shape.note_type_name || "none"));
    lines.push("- question length: " + String(shape.question_length || 0));
    lines.push("- answer length: " + String(shape.answer_length || 0));
    lines.push("");

    if (!allowed) {
      lines.push("Card text was not returned. Use the consent button for this browser-only study interaction.");
    } else if (!present) {
      lines.push("No current in-memory Anki card is available.");
    } else {
      lines.push("Current card text is available in this browser command result only. It is not persisted, sent to a backend, sent to a model, written to Anki, or written to MyDecks.");
    }

    var safeCard = {
      present: present,
      deck_name: shape.deck_name || state.selected_deck_name || "",
      note_type_name: shape.note_type_name || "",
      question_length: Number(shape.question_length || 0),
      answer_length: Number(shape.answer_length || 0)
    };

    if (cardTextReturned) {
      safeCard.question = String(card.question || "");
      safeCard.answer = String(card.answer || "");
    }

    return {
      version: VERSION,
      ok: true,
      command: "consented_current_anki_card_for_study",
      consented: Boolean(cardTextReturned),
      message: lines.join("\n"),
      card: safeCard,
      privacy: {
        browser_memory_only: true,
        card_text_returned_by_command: cardTextReturned,
        card_text_persisted: false,
        backend_calls_allowed: false,
        model_calls_allowed: false,
        anki_write_allowed: false,
        mydecks_writeback_allowed: false
      }
    };
  }

  function ankiSessionStatusShape(raw) {
    raw = raw || {};
    return {
      source_type: raw.source_type || "anki_browser_local",
      status: raw.status || "unavailable",
      active: Boolean(raw.active),
      selected_deck_name: raw.selected_deck_name || "",
      selected_deck_id: raw.selected_deck_id || "",
      card_count_in_memory: Number(raw.card_count_in_memory || 0),
      reviewed_count: Number(raw.reviewed_count || 0),
      correct_count: Number(raw.correct_count || 0),
      wrong_count: Number(raw.wrong_count || 0),
      current_index: Number(raw.current_index || 0)
    };
  }

  function ensureMountOutput(panel) {
    if (!panel) return null;

    var output = panel.querySelector(".apc-companion-local-anki-session-mount-output");
    if (output) return output;

    output = document.createElement("pre");
    output.className = "study-muted apc-companion-local-anki-session-mount-output";
    output.setAttribute("aria-live", "polite");
    output.textContent = "Local Anki session controls can be mounted here. Card text stays in the read-only Anki session UI only.";

    var details = panel.querySelector(".apc-anki-manifest-details");
    if (details && details.parentNode) {
      details.parentNode.insertBefore(output, details);
    } else {
      panel.appendChild(output);
    }

    return output;
  }

  function ankiSessionMountCommand() {
    var api = window.APC_ANKI_READONLY_SESSION;
    var raw = null;
    var mounted = false;
    var renderError = "";

    if (api && typeof api.snapshot === "function") {
      try {
        raw = api.snapshot();
      } catch (error) {
        raw = null;
      }
    }

    if (api && typeof api.renderPanel === "function") {
      try {
        api.renderPanel();
        mounted = true;
      } catch (error) {
        renderError = String(error && error.message ? error.message : error);
      }
    }

    var state = ankiSessionStatusShape(raw);
    var lines = [];

    lines.push("Local Anki session mount:");
    lines.push("- adapter present: " + (api ? "yes" : "no"));
    lines.push("- adapter rendered: " + (mounted ? "yes" : "no"));
    lines.push("- source: " + (state.source_type || "anki_browser_local"));
    lines.push("- status: " + (state.status || "unknown"));
    lines.push("- active: " + (state.active ? "yes" : "no"));
    lines.push("- deck: " + (state.selected_deck_name || "none"));
    lines.push("- cards in memory: " + String(state.card_count_in_memory || 0));
    lines.push("- reviewed: " + String(state.reviewed_count || 0));
    lines.push("- correct / wrong: " + String(state.correct_count || 0) + " / " + String(state.wrong_count || 0));
    if (renderError) lines.push("- render note: " + renderError);
    lines.push("");
    lines.push("Use the local Anki session controls to load, reveal, and mark cards. Companion bridge only reports status, counters, and shape.");

    try {
      ensureMountOutput(document.getElementById(PANEL_ID));
    } catch (error) {}

    return {
      version: VERSION,
      ok: Boolean(api),
      command: "mount_anki_session_adapter",
      mounted: mounted,
      message: lines.join("\n"),
      session: state,
      privacy: {
        browser_memory_only: true,
        card_text_returned_by_mount_command: false,
        backend_calls_allowed: false,
        model_calls_allowed: false,
        anki_write_allowed: false,
        mydecks_writeback_allowed: false
      }
    };
  }

  function bindAnkiSessionMountAction() {
    if (window.__APC_COMPANION_LOCAL_ANKI_SESSION_MOUNT_BOUND) return;
    window.__APC_COMPANION_LOCAL_ANKI_SESSION_MOUNT_BOUND = true;

    document.addEventListener("click", function (event) {
      var target = event.target && event.target.closest
        ? event.target.closest("[data-local-anki-bridge-action='mount-anki-session']")
        : null;
      if (!target) return;

      var result = ankiSessionMountCommand();
      var panel = document.getElementById(PANEL_ID);
      var output = ensureMountOutput(panel);
      if (output) output.textContent = result.message;
    });
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
      + '  <p class="study-muted apc-companion-local-anki-visible-privacy-copy">This bridge does not return card question text or answer text.</p>'
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
      + '  <button type="button" class="study-button secondary" data-local-anki-bridge-action="describe-shape">Describe current local Anki card shape</button>'
      + '  <button type="button" class="study-button secondary" data-local-anki-bridge-action="mount-anki-session">Mount local Anki session controls</button>'
      + '  <button type="button" class="study-button secondary" data-local-anki-bridge-action="consent-current-card">Use current Anki card in Companion study</button>'
      + '  <pre class="study-muted apc-companion-local-anki-command-output" aria-live="polite">' + escapeHtml(currentCardShapeCommand().message) + '</pre>'
      + '  <pre class="study-muted apc-companion-local-anki-consent-output" aria-live="polite">Consent required before current Anki card text can be returned to a browser-only study command.</pre>'
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

    panel.querySelectorAll("[data-local-anki-bridge-action='describe-shape']").forEach(function (button) {
      button.addEventListener("click", function () {
        var output = panel.querySelector(".apc-companion-local-anki-command-output");
        if (output) output.textContent = currentCardShapeCommand().message;
      });
    });

    panel.querySelectorAll("[data-local-anki-bridge-action='consent-current-card']").forEach(function (button) {
      button.addEventListener("click", function () {
        var result = consentedCurrentAnkiCardForStudyCommand(true);
        var output = panel.querySelector(".apc-companion-local-anki-consent-output");
        if (output) output.textContent = result.message;
      });
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
    ensureMountOutput(document.getElementById(PANEL_ID));
  }

  function scheduleMount() {
    if (mountTimer) window.clearTimeout(mountTimer);
    mountTimer = window.setTimeout(renderPanel, 50);
  }

  bindAnkiSessionMountAction();
  window.APC_COMPANION_LOCAL_ANKI_BRIDGE = {
    version: VERSION,
    snapshot: snapshot,
    currentCardShape: currentCardShape,
    currentCardShapeCommand: currentCardShapeCommand,
    consentedCurrentAnkiCardForStudyCommand: consentedCurrentAnkiCardForStudyCommand,
    ankiSessionMountCommand: ankiSessionMountCommand,
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
