(function () {
  "use strict";

  if (window.__APC_STUDY_SOURCE_SELECTOR_REMOVED__) return;
  window.__APC_STUDY_SOURCE_SELECTOR_REMOVED__ = true;

  var VERSION = "stage17kwr4-study-source-panel-removed-20260629";
  var PANEL_ID = "apc-study-source-selector";
  var SELECTION_KEY = "apcStudySourceSelection";

  function readJson(key) {
    try {
      var raw = window.localStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  function removeKey(key) {
    try {
      window.localStorage.removeItem(key);
    } catch (_) {}
  }

  function readSelection() {
    return readJson(SELECTION_KEY);
  }

  function removePanel() {
    var existing = document.getElementById(PANEL_ID);
    if (existing && existing.parentNode) existing.parentNode.removeChild(existing);
  }

  function clearSelection() {
    removeKey(SELECTION_KEY);
    removePanel();
  }

  function renderPanel() {
    removePanel();
  }

  function scheduleRemoval() {
    window.setTimeout(removePanel, 0);
    window.setTimeout(removePanel, 50);
    window.setTimeout(removePanel, 250);
  }

  window.APC_STUDY_SOURCE_SELECTOR = {
    version: VERSION,
    readSelection: readSelection,
    clearSelection: clearSelection,
    renderPanel: renderPanel,
    privacy: {
      study_page_source_panel_enabled: false,
      external_file_ui_on_study_allowed: false,
      mydecks_source_picker_on_study_enabled: false
    }
  };

  window.addEventListener("DOMContentLoaded", scheduleRemoval);
  window.addEventListener("popstate", scheduleRemoval);
  window.addEventListener("hashchange", scheduleRemoval);
  document.addEventListener("apc-private-page-rendered", scheduleRemoval);
  document.addEventListener("click", scheduleRemoval);

  scheduleRemoval();
})();
