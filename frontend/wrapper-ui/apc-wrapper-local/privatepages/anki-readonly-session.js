(function () {
  "use strict";

  var VERSION = "stage17ks-r3-anki-readonly-renderpanel-export-20260628";
  var PANEL_ID = "apc-anki-readonly-session";
  var FILE_INPUT_ID = "apc-anki-readonly-session-file";
  var SELECTION_KEY = "apc.study.sourceSelection.v1";
  var SQLJS_SCRIPT_PATH = "/vendor/sqljs/sql-wasm.js";
  var SQLJS_WASM_PATH = "/vendor/sqljs/sql-wasm.wasm";
  var FIELD_SEPARATOR = String.fromCharCode(31);

  var mountTimer = null;
  var sqlJsPromise = null;
  var selectedAnkiFile = null;

  var memoryState = freshState("idle", "Ready for a browser-local Anki session.");

  function freshState(status, message) {
    return {
      status: status || "idle",
      message: message || "",
      selected_file_name: "",
      selected_file_size: 0,
      selected_file_header_kind: "",
      selected_file_modified_ms: 0,
      active: false,
      started_at: "",
      stopped_at: "",
      reviewed_count: 0,
      correct_count: 0,
      wrong_count: 0,
      card_count_in_memory: 0,
      current_index: 0,
      answer_visible: false,
      cards: []
    };
  }

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

  function requireAnkiSelection() {
    var selection = readSelection();
    if (!selection || selection.source_type !== "anki_browser_local") {
      throw new Error("Select Study with Anki and choose a local Anki deck first.");
    }
    if (!selection.deck_id) {
      throw new Error("The Anki source selection is missing a deck id.");
    }
    return selection;
  }

  function headerKind(headerText) {
    if (headerText.indexOf("SQLite format 3") === 0) return "sqlite-anki-collection";
    if (headerText.indexOf("PK") === 0) return "zip-or-apkg";
    return "unknown";
  }

  async function inspectFileHeaderOnly(file) {
    if (!file) throw new Error("No file selected.");
    selectedAnkiFile = file;

    var headerBlob = file.slice(0, Math.min(file.size, 128));
    var buffer = await headerBlob.arrayBuffer();
    var bytes = new Uint8Array(buffer);
    var header = "";
    for (var i = 0; i < bytes.length; i += 1) header += String.fromCharCode(bytes[i]);

    var kind = headerKind(header);
    memoryState.selected_file_name = file.name || "selected-file";
    memoryState.selected_file_size = Number(file.size || 0);
    memoryState.selected_file_header_kind = kind;
    memoryState.selected_file_modified_ms = Number(file.lastModified || 0);
    memoryState.status = kind === "sqlite-anki-collection" ? "file_ready" : "file_not_supported";
    memoryState.message = kind === "sqlite-anki-collection"
      ? "Anki SQLite file is available in this browser session."
      : "This file is not a supported local Anki SQLite collection.";
    renderPanel();
    return snapshot();
  }

  function loadSqlJs() {
    if (sqlJsPromise) return sqlJsPromise;

    sqlJsPromise = new Promise(function (resolve, reject) {
      if (window.initSqlJs) {
        window.initSqlJs({ locateFile: function () { return SQLJS_WASM_PATH; } }).then(resolve).catch(reject);
        return;
      }

      var existing = document.querySelector('script[data-apc-sqljs="stage17kk"]');
      if (existing) {
        existing.addEventListener("load", function () {
          window.initSqlJs({ locateFile: function () { return SQLJS_WASM_PATH; } }).then(resolve).catch(reject);
        });
        existing.addEventListener("error", function () { reject(new Error("sql.js failed to load.")); });
        return;
      }

      var script = document.createElement("script");
      script.src = SQLJS_SCRIPT_PATH;
      script.async = true;
      script.setAttribute("data-apc-sqljs", "stage17kk");
      script.onload = function () {
        if (!window.initSqlJs) {
          reject(new Error("sql.js loaded but initSqlJs is missing."));
          return;
        }
        window.initSqlJs({ locateFile: function () { return SQLJS_WASM_PATH; } }).then(resolve).catch(reject);
      };
      script.onerror = function () { reject(new Error("sql.js failed to load.")); };
      document.head.appendChild(script);
    });

    return sqlJsPromise;
  }

  function sqlRows(db, sql, params) {
    var stmt = db.prepare(sql);
    var rows = [];
    try {
      stmt.bind(params || []);
      while (stmt.step()) rows.push(stmt.getAsObject());
    } finally {
      stmt.free();
    }
    return rows;
  }

  function listTables(db) {
    var out = {};
    sqlRows(db, "SELECT name FROM sqlite_master WHERE type='table'").forEach(function (row) {
      out[String(row.name)] = true;
    });
    return out;
  }

  function fieldsByNoteType(db, tables) {
    var out = {};
    if (!tables.fields) return out;

    sqlRows(db, "SELECT ntid, ord, name FROM fields ORDER BY ntid, ord").forEach(function (row) {
      var ntid = String(row.ntid);
      if (!out[ntid]) out[ntid] = [];
      out[ntid].push({
        ord: Number(row.ord || 0),
        name: String(row.name || "")
      });
    });

    return out;
  }

  function noteTypeNames(db, tables) {
    var out = {};
    if (tables.notetypes) {
      sqlRows(db, "SELECT id, name FROM notetypes").forEach(function (row) {
        out[String(row.id)] = String(row.name || row.id);
      });
    }
    return out;
  }

  function stripHtml(value) {
    var div = document.createElement("div");
    div.innerHTML = String(value || "");
    return (div.textContent || div.innerText || "").replace(/\s+/g, " ").trim();
  }

  function pickFrontBack(note, fieldList) {
    var parts = String(note.flds || "").split(FIELD_SEPARATOR);
    var byName = {};
    (fieldList || []).forEach(function (field) {
      byName[String(field.name || "").toLowerCase()] = parts[Number(field.ord || 0)] || "";
    });

    var front = byName.front || parts[0] || "";
    var back = byName.back || parts[1] || "";

    return {
      front: stripHtml(front),
      back: stripHtml(back),
      raw_front_length: String(front || "").length,
      raw_back_length: String(back || "").length
    };
  }

  async function extractBasicCardsIntoMemory(file) {
    var selection = requireAnkiSelection();

    if (!file && memoryState.cards && memoryState.cards.length) {
      memoryState.status = memoryState.active ? "active" : memoryState.status;
      memoryState.message = "Anki cards are already loaded in browser memory. Stage 17K-K-R4 preserved the active local session.";
      renderPanel();
      return snapshot();
    }

    await inspectFileHeaderOnly(file);

    if (memoryState.selected_file_header_kind !== "sqlite-anki-collection") {
      throw new Error("Selected file is not a supported Anki SQLite collection.");
    }

    var SQL = await loadSqlJs();
    var buffer = await file.arrayBuffer();
    selectedAnkiFile = null;
    var db = new SQL.Database(new Uint8Array(buffer));

    try {
      var tables = listTables(db);
      ["cards", "notes"].forEach(function (name) {
        if (!tables[name]) throw new Error("Missing required Anki table: " + name);
      });

      var deckId = String(selection.deck_id);
      var fieldMap = fieldsByNoteType(db, tables);
      var noteTypes = noteTypeNames(db, tables);

      var rows = sqlRows(db,
        "SELECT c.id AS card_id, c.nid AS note_id, c.did AS deck_id, c.ord AS card_ord, n.mid AS note_type_id, n.flds AS flds " +
        "FROM cards c JOIN notes n ON n.id = c.nid WHERE CAST(c.did AS TEXT) = ? ORDER BY c.id",
        [deckId]
      );

      var cards = rows.map(function (row, index) {
        var noteTypeId = String(row.note_type_id || "");
        var fieldList = fieldMap[noteTypeId] || [];
        var qa = pickFrontBack(row, fieldList);
        return {
          local_id: "anki-memory-card-" + index,
          deck_id: deckId,
          deck_name: selection.deck_name || "",
          note_type_name: noteTypes[noteTypeId] || noteTypeId || "Unknown",
          question: qa.front || "(empty front)",
          answer: qa.back || "(empty back)",
          raw_front_length: qa.raw_front_length,
          raw_back_length: qa.raw_back_length
        };
      }).filter(function (card) {
        return String(card.question || "").trim() || String(card.answer || "").trim();
      });

      memoryState.cards = cards;
      memoryState.card_count_in_memory = cards.length;
      memoryState.current_index = 0;
      memoryState.reviewed_count = 0;
      memoryState.correct_count = 0;
      memoryState.wrong_count = 0;
      memoryState.answer_visible = false;
      memoryState.active = cards.length > 0;
      memoryState.started_at = new Date().toISOString();
      memoryState.stopped_at = "";
      memoryState.status = cards.length > 0 ? "active" : "empty_deck";
      memoryState.message = cards.length > 0
        ? "Loaded " + cards.length + " Anki card(s) into browser memory only."
        : "No cards were found for the selected Anki deck.";

      renderPanel();
      return snapshot();
    } finally {
      db.close();
    }
  }

  function currentCard() {
    if (!memoryState.cards.length) return null;
    return memoryState.cards[Math.max(0, Math.min(memoryState.current_index, memoryState.cards.length - 1))] || null;
  }

  function revealAnswer() {
    memoryState.answer_visible = true;
    memoryState.message = "Answer revealed locally.";
    renderPanel();
    return snapshot();
  }

  function answerCurrent(outcome) {
    if (!memoryState.active || !currentCard()) {
      memoryState.message = "No active local Anki card is ready.";
      renderPanel();
      return snapshot();
    }

    memoryState.reviewed_count += 1;
    if (outcome === "correct") memoryState.correct_count += 1;
    if (outcome === "wrong") memoryState.wrong_count += 1;

    if (memoryState.current_index + 1 < memoryState.cards.length) {
      memoryState.current_index += 1;
      memoryState.answer_visible = false;
      memoryState.message = "Marked " + outcome + " locally. Advanced to the next card.";
    } else {
      memoryState.active = false;
      memoryState.status = "complete";
      memoryState.stopped_at = new Date().toISOString();
      memoryState.answer_visible = false;
      memoryState.message = "Local Anki session complete. Card content remains in memory until stopped or cleared.";
    }

    renderPanel();
    return snapshot();
  }

  function stopSession() {
    selectedAnkiFile = null;
    memoryState.cards = [];
    memoryState.card_count_in_memory = 0;
    memoryState.current_index = 0;
    memoryState.answer_visible = false;
    memoryState.active = false;
    memoryState.status = "stopped";
    memoryState.stopped_at = new Date().toISOString();
    memoryState.message = "Stopped local Anki session and cleared in-memory card content.";
    renderPanel();
    return snapshot();
  }

  function clearMemory() {
    selectedAnkiFile = null;
    memoryState = freshState("idle", "In-memory Anki session state cleared.");
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
      correct_count: memoryState.correct_count,
      wrong_count: memoryState.wrong_count,
      card_count_in_memory: memoryState.card_count_in_memory,
      current_index: memoryState.current_index,
      answer_visible: memoryState.answer_visible,
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
    return document.querySelector("#apc-anki-readonly-session")
      || document.querySelector("#apc-study-source-selector")
      || document.querySelector("[data-page='study']")
      || document.querySelector("main")
      || document.body;
  }

  function renderCurrentCardHtml() {
    var card = currentCard();
    if (!card) {
      return '<p class="study-muted">No in-memory Anki card is loaded.</p>';
    }

    return ''
      + '<article class="study-row card apc-anki-memory-card">'
      + '  <div>'
      + '    <strong>Question</strong>'
      + '    <p>' + escapeHtml(card.question) + '</p>'
      + (memoryState.answer_visible
          ? '<strong>Answer</strong><p>' + escapeHtml(card.answer) + '</p>'
          : '<p class="study-muted">Answer hidden.</p>')
      + '  </div>'
      + '</article>';
  }

  function renderHtml() {
    var selection = readSelection();
    var ankiSelected = selection && selection.source_type === "anki_browser_local";
    var snap = snapshot();

    return ''
      + '<section id="' + PANEL_ID + '" class="profile-card apc-anki-readonly-session-card">'
      + '  <h3>Anki read-only session</h3>'
      + '  <p class="study-muted">Reads Basic-style Anki cards into JavaScript memory only. No backend calls. No Anki writes.</p>'
      + '  <div class="profile-preference-row"><span>Adapter version</span><strong>' + escapeHtml(VERSION) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Selected source</span><strong>' + escapeHtml(selection && selection.source_label || "None") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Selected Anki deck</span><strong>' + escapeHtml(selection && selection.deck_name || "None") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Status</span><strong>' + escapeHtml(snap.status) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>File header</span><strong>' + escapeHtml(snap.selected_file_header_kind || "not selected") + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Cards in memory</span><strong>' + escapeHtml(snap.card_count_in_memory) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Reviewed</span><strong>' + escapeHtml(snap.reviewed_count) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Correct / wrong</span><strong>' + escapeHtml(snap.correct_count) + ' / ' + escapeHtml(snap.wrong_count) + '</strong></div>'
      + (memoryState.message ? '<p class="apc-anki-message">' + escapeHtml(memoryState.message) + '</p>' : '')
      + '  <div class="profile-preference-row">'
      + '    <label for="' + FILE_INPUT_ID + '"><strong>Re-select Anki file for this browser session</strong></label>'
      + '    <input id="' + FILE_INPUT_ID + '" type="file" accept=".anki2,.anki21,.sqlite,.db">'
      + '  </div>'
      + '  <div class="study-row-actions">'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="start" ' + (ankiSelected ? "" : "disabled") + '>Load selected Anki deck into memory</button>'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="reveal">Reveal answer</button>'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="correct">Right</button>'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="wrong">Wrong</button>'
      + '    <button type="button" class="study-button secondary" data-anki-session-action="stop">Stop and clear cards</button>'
      + '  </div>'
      + renderCurrentCardHtml()
      + '  <details class="apc-anki-manifest-details">'
      + '    <summary>Privacy boundary</summary>'
      + '    <p class="study-muted">Card text is held in JavaScript memory only for this active browser page. It is not saved to localStorage and is not sent to the server.</p>'
      + '    <p class="study-muted">This path does not use editable MyDecks backend writeback.</p>'
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
      button.addEventListener("click", async function () {
        var action = button.getAttribute("data-anki-session-action");
        try {
          if (action === "start") {
            var fileInput = document.getElementById(FILE_INPUT_ID);
            var file = selectedAnkiFile || (fileInput && fileInput.files && fileInput.files[0]);
            if (!file && memoryState.cards && memoryState.cards.length) {
              memoryState.status = memoryState.active ? "active" : memoryState.status;
              memoryState.message = "Anki cards are already loaded in browser memory. Use reveal/right/wrong or stop and re-select the file to reload.";
              renderPanel();
              return;
            }
            await extractBasicCardsIntoMemory(file);
          }
          if (action === "reveal") revealAnswer();
          if (action === "correct") answerCurrent("correct");
          if (action === "wrong") answerCurrent("wrong");
          if (action === "stop") stopSession();
        } catch (error) {
          memoryState.status = "error";
          memoryState.message = error && error.message ? error.message : String(error);
          renderPanel();
        }
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

      if (host.nextSibling) host.parentNode.insertBefore(existing, host.nextSibling);
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

  window.APC_ANKI_READONLY_SESSION = {
    version: VERSION,
    readSelection: readSelection,
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

  window.addEventListener("DOMContentLoaded", scheduleMount);
  window.addEventListener("hashchange", scheduleMount);
  window.addEventListener("popstate", scheduleMount);
  document.addEventListener("apc-private-page-rendered", scheduleMount);
  document.addEventListener("click", scheduleMount);

  scheduleMount();
})();
