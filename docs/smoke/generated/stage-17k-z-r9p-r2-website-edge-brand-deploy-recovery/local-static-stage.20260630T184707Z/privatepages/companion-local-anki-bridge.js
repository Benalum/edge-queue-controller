(function () {
  "use strict";

  if (window.__APC_COMPANION_LOCAL_CARD_BRIDGE_UI_REMOVED__) return;
  window.__APC_COMPANION_LOCAL_CARD_BRIDGE_UI_REMOVED__ = true;

  var VERSION = "stage17kxr2-companion-local-card-ui-removed-20260629";
  var PANEL_ID = "apc-companion-local-anki-bridge";

  function removePanel() {
    var existing = document.getElementById(PANEL_ID);
    if (existing && existing.parentNode) existing.parentNode.removeChild(existing);

    document.querySelectorAll(".apc-companion-local-anki-bridge-card, .apc-companion-local-anki-session-mount-output, .apc-companion-local-anki-command-output, .apc-companion-local-anki-consent-output").forEach(function (el) {
      if (el && el.parentNode) el.parentNode.removeChild(el);
    });
  }

  function snapshot() {
    removePanel();
    return {
      version: VERSION,
      status: "ui_removed",
      active: false,
      current_card_shape: {
        present: false,
        has_question: false,
        has_answer: false,
        question_length: 0,
        answer_length: 0
      },
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

  function currentCardShape() {
    return snapshot().current_card_shape;
  }

  function currentCardShapeCommand() {
    var state = snapshot();
    return {
      version: VERSION,
      ok: true,
      command: "current_local_card_shape",
      message: "Local card bridge UI removed from Companion.",
      shape: state.current_card_shape,
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

  function consentedCurrentAnkiCardForStudyCommand() {
    removePanel();
    return {
      version: VERSION,
      ok: false,
      command: "consented_current_local_card_for_study",
      consented: false,
      message: "Local card handoff UI removed from Companion.",
      card: {
        present: false,
        question_length: 0,
        answer_length: 0
      },
      privacy: {
        browser_memory_only: true,
        card_text_returned_by_command: false,
        card_text_persisted: false,
        backend_calls_allowed: false,
        model_calls_allowed: false,
        anki_write_allowed: false,
        mydecks_writeback_allowed: false
      }
    };
  }

  function ankiSessionMountCommand() {
    removePanel();
    return {
      version: VERSION,
      ok: false,
      command: "mount_local_card_adapter",
      mounted: false,
      message: "Local card controls removed from Companion.",
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

  function renderPanel() {
    removePanel();
  }

  function scheduleRemoval() {
    window.setTimeout(removePanel, 0);
    window.setTimeout(removePanel, 50);
    window.setTimeout(removePanel, 250);
  }

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

  window.addEventListener("DOMContentLoaded", scheduleRemoval);
  window.addEventListener("hashchange", scheduleRemoval);
  window.addEventListener("popstate", scheduleRemoval);
  document.addEventListener("apc-private-page-rendered", scheduleRemoval);
  document.addEventListener("click", scheduleRemoval);

  scheduleRemoval();
})();
