(function () {
  "use strict";

  if (window.__APC_LOCAL_CARD_SESSION_UI_REMOVED__) return;
  window.__APC_LOCAL_CARD_SESSION_UI_REMOVED__ = true;

  var VERSION = "stage17kxr2-local-card-session-ui-removed-20260629";
  var PANEL_ID = "apc-anki-readonly-session";

  function removePanel() {
    var existing = document.getElementById(PANEL_ID);
    if (existing && existing.parentNode) existing.parentNode.removeChild(existing);

    document.querySelectorAll(".apc-anki-readonly-session-card, .apc-anki-memory-card").forEach(function (el) {
      if (el && el.parentNode) el.parentNode.removeChild(el);
    });
  }

  function snapshot() {
    removePanel();
    return {
      version: VERSION,
      status: "ui_removed",
      active: false,
      selected_deck_name: "",
      selected_deck_id: "",
      selected_file_name: "",
      selected_file_size: 0,
      selected_file_header_kind: "",
      reviewed_count: 0,
      correct_count: 0,
      wrong_count: 0,
      card_count_in_memory: 0,
      current_index: 0,
      answer_visible: false,
      message: "Local card session UI removed from this page.",
      privacy: {
        browser_memory_only: true,
        card_text_localstorage_allowed: false,
        backend_calls_allowed: false,
        anki_write_allowed: false,
        mydecks_writeback_allowed: false
      }
    };
  }

  function currentCard() {
    removePanel();
    return null;
  }

  function renderPanel() {
    removePanel();
  }

  function clearMemory() {
    return snapshot();
  }

  function stopSession() {
    return snapshot();
  }

  function revealAnswer() {
    return snapshot();
  }

  function answerCurrent() {
    return snapshot();
  }

  async function inspectFileHeaderOnly() {
    return snapshot();
  }

  async function extractBasicCardsIntoMemory() {
    return snapshot();
  }

  function scheduleRemoval() {
    window.setTimeout(removePanel, 0);
    window.setTimeout(removePanel, 50);
    window.setTimeout(removePanel, 250);
  }

  window.APC_ANKI_READONLY_SESSION = {
    version: VERSION,
    readSelection: function () { return null; },
    inspectFileHeaderOnly: inspectFileHeaderOnly,
    extractBasicCardsIntoMemory: extractBasicCardsIntoMemory,
    revealAnswer: revealAnswer,
    answerCurrent: answerCurrent,
    stopSession: stopSession,
    clearMemory: clearMemory,
    snapshot: snapshot,
    currentCard: currentCard,
    renderPanel: renderPanel,
    privacy: {
      browser_memory_only: true,
      card_text_localstorage_allowed: false,
      backend_calls_allowed: false,
      anki_write_allowed: false,
      mydecks_writeback_allowed: false
    }
  };

  window.addEventListener("DOMContentLoaded", scheduleRemoval);
  window.addEventListener("hashchange", scheduleRemoval);
  window.addEventListener("popstate", scheduleRemoval);
  document.addEventListener("apc-private-page-rendered", scheduleRemoval);
  document.addEventListener("click", scheduleRemoval);

  scheduleRemoval();
})();
