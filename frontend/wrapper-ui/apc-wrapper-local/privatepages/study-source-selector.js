(function () {
  "use strict";

  if (window.__APC_STUDY_SOURCE_SELECTOR_NATIVE_ONLY__) return;
  window.__APC_STUDY_SOURCE_SELECTOR_NATIVE_ONLY__ = true;

  var VERSION = "stage17kw-study-page-mydecks-only-20260628";
  var PANEL_ID = "apc-study-source-selector";
  var SELECTION_KEY = "apcStudySourceSelection";
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

  function readSelection() {
    return readJson(SELECTION_KEY);
  }

  function clearSelection() {
    removeKey(SELECTION_KEY);
  }

  function saveNativeSelection() {
    writeJson(SELECTION_KEY, {
      source_type: "mydecks_apc_native",
      source_label: "Study with MyDecks",
      permissions: {
        browser_local_only: false,
        read_only: false,
        can_edit: true,
        can_create: true,
        can_delete: true,
        can_flag: true,
        can_upload_content: false
      },
      saved_at: new Date().toISOString()
    });
  }

  function isStudyRoute() {
    var routeText = String(window.location.pathname + " " + window.location.hash).toLowerCase();
    if (routeText.indexOf("study") !== -1) return true;
    return Boolean(document.querySelector("[data-page='study'], .sol-study-box"));
  }

  function findHost() {
    return document.querySelector("[data-page='study']")
      || document.querySelector(".sol-study-box")
      || document.querySelector("main")
      || document.body;
  }

  function renderSelectionStatus(selection) {
    if (selection && selection.source_type === "mydecks_apc_native") {
      return ''
        + '<p class="study-muted">Selected source: <strong>Study with MyDecks</strong>.</p>';
    }

    return '<p class="study-muted">No native study source selected yet.</p>';
  }

  function renderHtml(message) {
    var selection = readSelection();

    return ''
      + '<section id="' + PANEL_ID + '" class="profile-card apc-study-source-selector-card">'
      + '  <h3>Study source</h3>'
      + '  <p class="study-muted">Study uses APC-native MyDecks on this page.</p>'
      + (message ? '<p class="apc-anki-message">' + escapeHtml(message) + '</p>' : '')
      + renderSelectionStatus(selection)
      + '  <div class="study-grid">'
      + '    <article class="study-row">'
      + '      <div>'
      + '        <strong>Study with MyDecks</strong>'
      + '        <p class="study-muted">Uses APC-native decks. Create, edit, delete, and flag actions follow APC permissions.</p>'
      + '      </div>'
      + '      <div class="study-row-actions">'
      + '        <button type="button" class="study-button secondary" data-study-source-action="select-mydecks">Use MyDecks</button>'
      + '      </div>'
      + '    </article>'
      + '  </div>'
      + '  <details>'
      + '    <summary>Privacy and permission boundary</summary>'
      + '    <p class="study-muted">This page uses the APC-native study path and does not load external card files.</p>'
      + '  </details>'
      + '  <button type="button" class="study-button secondary" data-study-source-action="clear-selection">Clear source selection</button>'
      + '</section>';
  }

  function bindPanel(panel) {
    panel.querySelectorAll("[data-study-source-action]").forEach(function (button) {
      button.addEventListener("click", function () {
        var action = button.getAttribute("data-study-source-action");

        if (action === "select-mydecks") {
          saveNativeSelection();
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
    if (!isStudyRoute()) return;

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
    readSelection: readSelection,
    clearSelection: clearSelection,
    renderPanel: renderPanel,
    privacy: {
      study_page_native_only: true,
      external_file_ui_on_study_allowed: false,
      mydecks_native_path: true
    }
  };

  window.addEventListener("DOMContentLoaded", scheduleMount);
  window.addEventListener("popstate", scheduleMount);
  window.addEventListener("hashchange", scheduleMount);
  document.addEventListener("apc-private-page-rendered", scheduleMount);
  document.addEventListener("click", scheduleMount);

  scheduleMount();
})();
