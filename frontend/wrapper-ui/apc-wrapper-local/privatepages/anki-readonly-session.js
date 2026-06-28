(function () {
  "use strict";

  var VERSION = "stage17kj-anki-readonly-session-skeleton-20260628";
  var PANEL_ID = "apc-anki-readonly-session";
  var FILE_INPUT_ID = "apc-anki-readonly-session-file";
  var SELECTION_KEY = "apc.study.sourceSelection.v1";

  var mountTimer = null;
  var memoryState = {
    status: "idle",
    selected_file_name: "",
    selected_file_size: 0,
    selected_file_header_kind: "",
    selected_file_modified_ms: 0,
    active: false,
    started_at: "",
    stopped_at: "",
    reviewed_count: 0,
    card_count_in_memory: 0,
    message: ""
  };

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

  function readSelection() {
    var selector = window.APC_STUDY_SOURCE_SELECTOR;
    if (selector && typeof selector.readSelection === "function") {
      return selector.readSelection();
    }
    return readJson(SELECTION_KEY);
  }

  function isAnkiSelected() {
    var selection = readSelection();
    return Boolean(selection && selection.source_type === "anki_browser_local");
  }

  function selectedDeckLabel() {
    var selection = readSelection();
    if (!selection || selection.source_type !== "anki_browser_local") return "";
    return selection.deck_name || selection.deck_id || "Selected Anki deck";
  }

  function headerKind(headerText) {
    if (headerText.indexOf("SQLite format 3") === 0) return "sqlite-anki-collection";
    if (headerText.indexOf("PK") === 0) return "zip-or-apkg";
    return "unknown";
  }

  async function inspectFileHeaderOnly(file) {
    if (!file) {
      throw new Error("No file selected.");
    }

    var headerBlob = file.slice(0, Math.min(file.size, 128));
    var buffer = await headerBlob.arrayBuffer();
    var bytes = new Uint8Array(buffer);
    var header = "";
    for (var i = 0; i < bytes.length; i += 1) {
      header += String.fromCharCode(bytes[i]);
    }

    var kind = headerKind(header);

    memoryState.status = kind === "sqlite-anki-collection" ? "file_ready" : "file_not_supported";
    memoryState.selected_file_name = file.name || "selected-file";
    memoryState.selected_file_size = Number(file.size || 0);
    memoryState.selected_file_header_kind = kind;
    memoryState.selected_file_modified_ms = Number(file.lastModified || 0);
    memoryState.card_count_in_memory = 0;
    memoryState.reviewed_count = 0;
    memoryState.active = false;
    memoryState.started_at = "";
    memoryState.stopped_at = "";
    memoryState.message = kind === "sqlite-anki-collection"
      ? "Anki SQLite file is available in this browser session. Card extraction is not enabled in this skeleton."
      : "This file is not a supported local Anki SQLite collection for the first adapter skeleton.";

    return snapshot();
  }

  function startSkeletonSession() {
    if (!isAnkiSelected()) {
      memoryState.status = "blocked";
      memoryState.message = "Select Study with Anki and choose a local deck first.";
      renderPanel();
      return snapshot();
    }

    if (memoryState.status !== "file_ready") {
      memoryState.status = "needs_file";
      memoryState.message = "Re-select collection.anki2 before starting a local Anki session.";
      renderPanel();
      return snapshot();
    }

    memoryState.status = "skeleton_active";
    memoryState.active = true;
    memoryState.started_at = new Date().toISOString();
    memoryState.stopped_at = "";
    memoryState.reviewed_count = 0;
    memoryState.card_count_in_memory = 0;
    memoryState.message = "Skeleton session started. No card text has been extracted or stored yet.";
    renderPanel();
    return snapshot();
  }

  function stopSession() {
    memoryState.status = "stopped";
    memoryState.active = false;
    memoryState.stopped_at = new Date().toISOString();
    memoryState.reviewed_count = 0;
    memoryState.card_count_in_memory = 0;
    memoryState.message = "Skeleton session stopped. Any future in-memory card content would be cleared here.";
    renderPanel();
    return snapshot();
  }

  function clearMemory() {
    memoryState = {
      status: "idle",
      selected_file_name: "",
      selected_file_size: 0,
      selected_file_header_kind: "",
      selected_file_modified_ms: 0,
      active: false,
      started_at: "",
      stopped_at: "",
      reviewed_count: 0,
      card_count_in_memory: 0,
      message: "In-memory Anki session state cleared."
    };
    renderPanel();
    return snapshot();
  }

  function snapshot() {
    var selection = readSelection();
    return {
      version: VERSION,
      selection_source_type: selection && selection.source_type || "",
      selected_deck_name: selection && selection.deck_name || "",
      selected_deck_id: selection && selection.deck_id || "",
      status: memoryState.status,
      active: memoryState.active,
      selected_file_name: memoryState.selected_file_name,
      selected_file_size: memoryState.selected_file_size,
      selected_file_header_kind: memoryState.selected_file_header_kind,
      reviewed_count: memoryState.reviewed_count,
      card_count_in_memory: memoryState.card_count_in_memory,
      message: memoryState.message,
      privacy: {
        browser_memory_only: true,
        card_text_localstorage_allowed: false,
        backend_calls_allowed: false,
        anki_write_allowed: false,
        mydecks_writeback_allowed: false
      }
    };
  }

  function isStudyRoute() {
    var routeText = String(window.location.pathname + " " + window.location.hash).toLowerCase();
    if (routeText.indexOf("study") !== -1) return true;
    return Boolean(document.querySelector("[data-page='study'], #apc-study-source-selector"));
  }

  function findHost() {
    return document.querySelector("#apc-study-source-selector")
      || document.querySelector("[data-page='study']")
      || document.querySelector("main")
      || document.body;
  }

  function renderHtml() {
    var selection = readSelection();
    var ankiSelected = selection && selection.source_type === "anki_browser_local";
    var snap = snapshot();

    return ''
      + '<section id="' + PANEL_ID + '" class="profile-card apc-anki-readonly-session-card">'
      + '  <h3>Anki read-only session</h3>'
      + '  <p class="study-muted">This is the local-only adapter skeleton. It does not extract card text yet and does not call the backend.</p>'
      + '  <div class="profile-preference-row"><span>Adapter version</span><strong>' + escapeHtml(VERSION) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Selected source</span><strong>' + escapeHtml(selection && selection.source_label || "None") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Selected Anki deck</span><strong>' + escapeHtml(selectedDeckLabel() || "None") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Status</span><strong>' + escapeHtml(snap.status) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>File header</span><strong>' + escapeHtml(snap.selected_file_header_kind || "not selected") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Cards in memory</span><strong>' + escapeHtml(snap.card_count_in_memory) + '</strong></div>'
      + (memoryState.message ? '<p class="apc-anki-message">' + escapeHtml(memoryState.message) + '</p>' : '')
      + '  <div class="profile-preference-row">'
      + '    <label for="' + FILE_INPUT_ID + '"><strong>Re-select Anki file for this browser session</strong></label>'
      + '    <input id="' + FILE_INPUT_ID + '" type="file" accept=".anki2,.anki21,.sqlite,.db">'
      + '  </div>'
      + '  <div class="study-row-actions">'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="start" ' + (ankiSelected ? '' : 'disabled') + '>Start local Anki skeleton session</button>'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="stop">Stop</button>'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="clear">Clear in-memory state</button>'
      + '  </div>'
      + '  <details class="apc-anki-manifest-details">'
      + '    <summary>Privacy boundary</summary>'
      + '    <p class="study-muted">This skeleton keeps session state in JavaScript memory only. It does not save Anki card text to localStorage.</p>'
      + '    <p class="study-muted">It does not use the editable MyDecks backend writeback path.</p>'
      + '  </details>'
      + '</section>';
  }

  function bindPanel(panel) {
    var input = panel.querySelector("#" + FILE_INPUT_ID);
    if (input) {
      input.addEventListener("change", async function () {
        try {
          var file = input.files && input.files[0];
          await inspectFileHeaderOnly(file);
        } catch (error) {
          memoryState.status = "error";
          memoryState.message = error && error.message ? error.message : String(error);
          renderPanel();
        }
      });
    }

    panel.querySelectorAll("[data-anki-session-action]").forEach(function (button) {
      button.addEventListener("click", function () {
        var action = button.getAttribute("data-anki-session-action");
        if (action === "start") startSkeletonSession();
        if (action === "stop") stopSession();
        if (action === "clear") clearMemory();
      });
    });
  }

  function renderPanel() {
    if (!isStudyRoute()) return;

    var host = findHost();
    if (!host) return;

    var existing = document.getElementById(PANEL_ID);
    if (!existing) {
      existing = document.createElement("section");
      existing.id = PANEL_ID;

      if (host.nextSibling) {
        host.parentNode.insertBefore(existing, host.nextSibling);
      } else if (host.parentNode) {
        host.parentNode.appendChild(existing);
      } else {
        document.body.appendChild(existing);
      }
    }

    existing.outerHTML = renderHtml();
    bindPanel(document.getElementById(PANEL_ID));
  }

  function scheduleMount() {
    if (mountTimer) window.clearTimeout(mountTimer);
    mountTimer = window.setTimeout(renderPanel, 50);
  }

  window.APC_ANKI_READONLY_SESSION = {
    version: VERSION,
    readSelection: readSelection,
    inspectFileHeaderOnly: inspectFileHeaderOnly,
    startSkeletonSession: startSkeletonSession,
    stopSession: stopSession,
    clearMemory: clearMemory,
    snapshot: snapshot,
    privacy: {
      browser_memory_only: true,
      card_text_localstorage_allowed: false,
      backend_calls_allowed: false,
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
