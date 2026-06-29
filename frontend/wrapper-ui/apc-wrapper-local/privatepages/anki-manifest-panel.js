(function () {
  "use strict";

  var PANEL_ID = "apc-anki-manifest-panel";
  var FILE_INPUT_ID = "apc-anki-file-input";
  var CLEAR_BUTTON_ID = "apc-anki-clear-file-proof";
  var FILE_PROOF_KEY = "apc.profile.anki.fileProof.v2";
  var DECK_SUMMARY_KEY = "apc.profile.anki.localDeckSummary.v1";
  var SQLJS_SCRIPT_PATH = "/vendor/sqljs/sql-wasm.js";
  var SQLJS_WASM_PATH = "/vendor/sqljs/sql-wasm.wasm";

  var mountTimer = null;
  var sqlJsPromise = null;

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function formatBytes(bytes) {
    var size = Number(bytes || 0);
    if (!Number.isFinite(size) || size < 0) return "unknown";
    if (size < 1024) return size + " B";
    if (size < 1024 * 1024) return (size / 1024).toFixed(1) + " KiB";
    if (size < 1024 * 1024 * 1024) return (size / (1024 * 1024)).toFixed(1) + " MiB";
    return (size / (1024 * 1024 * 1024)).toFixed(1) + " GiB";
  }

  function formatDate(ms) {
    if (!ms) return "unknown";
    try {
      return new Date(ms).toLocaleString();
    } catch (_) {
      return "unknown";
    }
  }

  function storageRead(key) {
    try {
      var raw = window.localStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  function storageWrite(key, value) {
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch (_) {}
  }

  function storageRemove(key) {
    try {
      window.localStorage.removeItem(key);
    } catch (_) {}
  }

  function readSavedFileProof() {
    return storageRead(FILE_PROOF_KEY)
      || storageRead("apc.profile.anki.fileProof.v1")
      || storageRead("apcAnkiFileProof")
      || storageRead("apcAnkiFileProof.v1");
  }

  function saveFileProof(proof) {
    storageWrite(FILE_PROOF_KEY, proof);
  }

  function clearSavedFileProof() {
    storageRemove(FILE_PROOF_KEY);
    storageRemove("apc.profile.anki.fileProof.v1");
    storageRemove("apcAnkiFileProof");
    storageRemove("apcAnkiFileProof.v1");
  }

  function readSavedDeckSummary() {
    return storageRead(DECK_SUMMARY_KEY);
  }

  function saveDeckSummary(summary) {
    storageWrite(DECK_SUMMARY_KEY, summary);
  }

  function clearSavedDeckSummary() {
    storageRemove(DECK_SUMMARY_KEY);
  }

  function bytesToHeaderText(bytes) {
    var text = "";
    var max = Math.min(bytes.length, 16);
    for (var i = 0; i < max; i += 1) {
      var code = bytes[i];
      text += code >= 32 && code <= 126 ? String.fromCharCode(code) : ".";
    }
    return text;
  }

  function detectHeaderKind(headerText) {
    if (headerText.indexOf("SQLite format 3") === 0) return "sqlite-anki-collection";
    return "unknown";
  }

  async function sha256Hex(bytes) {
    var digest = await window.crypto.subtle.digest("SHA-256", bytes);
    var hashArray = Array.from(new Uint8Array(digest));
    return hashArray.map(function (b) {
      return b.toString(16).padStart(2, "0");
    }).join("");
  }

  async function buildFileProof(file) {
    var sample = new Uint8Array(await file.slice(0, 1024 * 1024).arrayBuffer());
    var headerText = bytesToHeaderText(sample);
    return {
      status: "selected",
      name: file.name,
      size_bytes: file.size,
      size_label: formatBytes(file.size),
      last_modified_ms: file.lastModified || null,
      last_modified: formatDate(file.lastModified),
      header_text: headerText,
      header_kind: detectHeaderKind(headerText),
      sample_bytes: sample.length,
      sample_sha256: await sha256Hex(sample),
      proof_created_at: new Date().toISOString(),
      privacy: {
        browser_local_only: true,
        uploads_performed: false,
        server_saved_anki_content: false,
        anki_file_modified: false
      }
    };
  }

  function loadScriptOnce(src) {
    return new Promise(function (resolve, reject) {
      var existing = document.querySelector('script[data-apc-sqljs="true"]');
      if (existing) {
        if (window.initSqlJs) {
          resolve();
          return;
        }
        existing.addEventListener("load", function () { resolve(); }, { once: true });
        existing.addEventListener("error", function () { reject(new Error("Could not load " + src)); }, { once: true });
        return;
      }

      var script = document.createElement("script");
      script.src = src;
      script.async = true;
      script.dataset.apcSqljs = "true";
      script.onload = function () { resolve(); };
      script.onerror = function () { reject(new Error("Could not load " + src)); };
      document.head.appendChild(script);
    });
  }

  async function loadSqlJsLocal() {
    if (sqlJsPromise) return sqlJsPromise;

    sqlJsPromise = (async function () {
      await loadScriptOnce(SQLJS_SCRIPT_PATH);
      if (!window.initSqlJs) {
        throw new Error("sql.js loader did not expose initSqlJs");
      }
      return window.initSqlJs({
        locateFile: function (fileName) {
          if (fileName === "sql-wasm.wasm") return SQLJS_WASM_PATH;
          return "/vendor/sqljs/" + fileName;
        }
      });
    })();

    return sqlJsPromise;
  }

  function sqlRows(db, sql) {
    var result = db.exec(sql);
    if (!result || !result.length) return [];
    var columns = result[0].columns || [];
    var values = result[0].values || [];
    return values.map(function (rowValues) {
      var row = {};
      columns.forEach(function (column, index) {
        row[column] = rowValues[index];
      });
      return row;
    });
  }

  function countScalar(db, sql) {
    var rows = sqlRows(db, sql);
    if (!rows.length) return 0;
    var keys = Object.keys(rows[0]);
    return Number(rows[0][keys[0]] || 0);
  }

  function tableSet(db) {
    var rows = sqlRows(db, "SELECT name FROM sqlite_master WHERE type = 'table'");
    var out = {};
    rows.forEach(function (row) {
      out[String(row.name)] = true;
    });
    return out;
  }

  function loadJsonObjectTolerant(raw, label, warnings) {
    if (raw == null || String(raw).trim() === "") {
      warnings.push({ field: label, warning: "empty" });
      return {};
    }
    try {
      var parsed = JSON.parse(String(raw));
      return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
    } catch (error) {
      warnings.push({ field: label, warning: "json_decode_error", message: String(error && error.message || error) });
      return {};
    }
  }

  function intSortKey(value) {
    var text = String(value);
    var number = Number(text);
    return Number.isFinite(number) ? number : text;
  }

  function sortByNameThenId(items) {
    return items.sort(function (a, b) {
      var an = String(a.name || "").toLowerCase();
      var bn = String(b.name || "").toLowerCase();
      if (an < bn) return -1;
      if (an > bn) return 1;
      var ai = intSortKey(a.id);
      var bi = intSortKey(b.id);
      if (ai < bi) return -1;
      if (ai > bi) return 1;
      return 0;
    });
  }

  async function extractLocalAnkiSummary(file) {
    var SQL = await loadSqlJsLocal();
    var buffer = await file.arrayBuffer();
    var db = new SQL.Database(new Uint8Array(buffer));

    try {
      var tables = tableSet(db);
      var warnings = [];

      if (!tables.cards || !tables.notes || !tables.col) {
        throw new Error("Selected file is SQLite but does not look like an Anki collection.");
      }

      var colRows = sqlRows(db, "SELECT decks, models FROM col LIMIT 1");
      var decksRaw = {};
      var modelsRaw = {};

      if (colRows.length) {
        decksRaw = loadJsonObjectTolerant(colRows[0].decks, "decks", warnings);
        modelsRaw = loadJsonObjectTolerant(colRows[0].models, "models", warnings);
      }

      var deckNames = {};
      if (tables.decks) {
        sqlRows(db, "SELECT id, name FROM decks").forEach(function (row) {
          deckNames[String(row.id)] = String(row.name || row.id);
        });
      }

      var noteTypeNames = {};
      if (tables.notetypes) {
        sqlRows(db, "SELECT id, name FROM notetypes").forEach(function (row) {
          noteTypeNames[String(row.id)] = String(row.name || row.id);
        });
      }

      var fieldsByNoteType = {};
      if (tables.fields) {
        sqlRows(db, "SELECT ntid, ord, name FROM fields").forEach(function (row) {
          var id = String(row.ntid);
          if (!fieldsByNoteType[id]) fieldsByNoteType[id] = [];
          fieldsByNoteType[id].push({ ord: Number(row.ord || 0), name: String(row.name || "") });
        });
      }

      var templatesByNoteType = {};
      if (tables.templates) {
        sqlRows(db, "SELECT ntid, ord, name FROM templates").forEach(function (row) {
          var id = String(row.ntid);
          if (!templatesByNoteType[id]) templatesByNoteType[id] = [];
          templatesByNoteType[id].push({ ord: Number(row.ord || 0), name: String(row.name || "") });
        });
      }

      Object.keys(fieldsByNoteType).forEach(function (id) {
        fieldsByNoteType[id] = fieldsByNoteType[id]
          .sort(function (a, b) { return a.ord - b.ord; })
          .map(function (item) { return item.name; });
      });

      Object.keys(templatesByNoteType).forEach(function (id) {
        templatesByNoteType[id] = templatesByNoteType[id]
          .sort(function (a, b) { return a.ord - b.ord; })
          .map(function (item) { return item.name; });
      });

      var cardCounts = {};
      var noteCountsByDeck = {};
      sqlRows(db, "SELECT did, COUNT(*) AS card_count, COUNT(DISTINCT nid) AS note_count FROM cards GROUP BY did").forEach(function (row) {
        cardCounts[String(row.did)] = Number(row.card_count || 0);
        noteCountsByDeck[String(row.did)] = Number(row.note_count || 0);
      });

      var noteCountsByType = {};
      sqlRows(db, "SELECT mid, COUNT(*) AS note_count FROM notes GROUP BY mid").forEach(function (row) {
        noteCountsByType[String(row.mid)] = Number(row.note_count || 0);
      });

      var deckIds = {};
      Object.keys(cardCounts).forEach(function (id) { deckIds[id] = true; });
      Object.keys(noteCountsByDeck).forEach(function (id) { deckIds[id] = true; });
      Object.keys(deckNames).forEach(function (id) { deckIds[id] = true; });
      Object.keys(decksRaw).forEach(function (id) { deckIds[id] = true; });

      var decks = Object.keys(deckIds).map(function (id) {
        var name = "";
        var source = "";
        if (deckNames[id]) {
          name = deckNames[id];
          source = "decks_table";
        } else if (decksRaw[id] && typeof decksRaw[id] === "object" && decksRaw[id].name) {
          name = String(decksRaw[id].name);
          source = "col.decks";
        } else {
          name = id === "1" ? "Default" : "Deck " + id;
          source = "fallback_cards_did";
        }

        return {
          id: id,
          name: name,
          name_source: source,
          card_count: Number(cardCounts[id] || 0),
          note_count: Number(noteCountsByDeck[id] || 0)
        };
      }).filter(function (deck) {
        return deck.card_count > 0 || deck.note_count > 0;
      });

      sortByNameThenId(decks);

      var noteTypeIds = {};
      Object.keys(noteCountsByType).forEach(function (id) { noteTypeIds[id] = true; });
      Object.keys(noteTypeNames).forEach(function (id) { noteTypeIds[id] = true; });
      Object.keys(modelsRaw).forEach(function (id) { noteTypeIds[id] = true; });

      var noteTypes = Object.keys(noteTypeIds).map(function (id) {
        var name = "";
        var source = "";
        if (noteTypeNames[id]) {
          name = noteTypeNames[id];
          source = "notetypes_table";
        } else if (modelsRaw[id] && typeof modelsRaw[id] === "object" && modelsRaw[id].name) {
          name = String(modelsRaw[id].name);
          source = "col.models";
        } else {
          name = "Note Type " + id;
          source = "fallback_notes_mid";
        }

        var fieldNames = fieldsByNoteType[id] || [];
        var templateNames = templatesByNoteType[id] || [];

        return {
          id: id,
          name: name,
          name_source: source,
          note_count: Number(noteCountsByType[id] || 0),
          field_count: fieldNames.length,
          field_names: fieldNames,
          template_count: templateNames.length,
          template_names: templateNames
        };
      }).sort(function (a, b) {
        var activeDiff = Number(b.note_count > 0) - Number(a.note_count > 0);
        if (activeDiff) return activeDiff;
        return String(a.name || "").localeCompare(String(b.name || ""));
      });

      var tagCounts = {};
      sqlRows(db, "SELECT tags FROM notes").forEach(function (row) {
        String(row.tags || "").trim().split(/\s+/).forEach(function (tag) {
          if (tag) tagCounts[tag] = Number(tagCounts[tag] || 0) + 1;
        });
      });

      var topTags = Object.keys(tagCounts)
        .map(function (tag) { return { tag: tag, count: tagCounts[tag] }; })
        .sort(function (a, b) { return b.count - a.count || a.tag.localeCompare(b.tag); })
        .slice(0, 25);

      return {
        status: "extracted",
        source_type: "anki_browser_local",
        extracted_at: new Date().toISOString(),
        file_name: file.name,
        summary: {
          card_count: countScalar(db, "SELECT COUNT(*) AS n FROM cards"),
          note_count: countScalar(db, "SELECT COUNT(*) AS n FROM notes"),
          deck_count_with_cards: decks.filter(function (deck) { return deck.card_count > 0; }).length,
          deck_count_total_in_collection: Object.keys(deckIds).length,
          note_type_count_with_notes: noteTypes.filter(function (noteType) { return noteType.note_count > 0; }).length,
          note_type_count_total_in_collection: noteTypes.length,
          tag_count: Object.keys(tagCounts).length
        },
        decks: decks,
        note_types: noteTypes,
        top_tags: topTags,
        parse_warnings: warnings,
        schema_features: {
          has_decks_table: Boolean(tables.decks),
          has_notetypes_table: Boolean(tables.notetypes),
          has_fields_table: Boolean(tables.fields),
          has_templates_table: Boolean(tables.templates),
          deck_name_source: Object.keys(deckNames).length ? "decks_table" : "col.decks_or_fallback",
          note_type_name_source: Object.keys(noteTypeNames).length ? "notetypes_table" : "col.models_or_fallback"
        },
        privacy: {
          browser_local_only: true,
          uploads_performed: false,
          server_saved_anki_content: false,
          anki_file_modified: false,
          deck_names_sent_to_server: false,
          card_text_sent_to_server: false,
          media_sent_to_server: false
        }
      };
    } finally {
      db.close();
    }
  }




  function renderAnkiFileHelpHtml() {
    return ''
      + '<details class="apc-anki-file-location-help">'
      + '  <summary>Where is my Anki file?</summary>'
      + '  <div class="study-muted">'
      + '    <p>Look for <code>collection.anki2</code> inside your Anki profile folder.</p>'
      + '    <ul>'
      + '      <li><strong>Windows:</strong> <code>%APPDATA%\\Anki2\\&lt;Profile&gt;\\collection.anki2</code></li>'
      + '      <li><strong>macOS:</strong> <code>~/Library/Application Support/Anki2/&lt;Profile&gt;/collection.anki2</code></li>'
      + '      <li><strong>Linux:</strong> <code>~/.local/share/Anki2/&lt;Profile&gt;/collection.anki2</code> or <code>$XDG_DATA_HOME/Anki2/&lt;Profile&gt;/collection.anki2</code></li>'
      + '      <li><strong>Android / AnkiDroid:</strong> check AnkiDroid Settings → Advanced → Collection path. If the browser cannot open that folder, export/copy the collection file to Downloads first.</li>'
      + '      <li><strong>iPhone / iPad:</strong> export or transfer from AnkiMobile using Add/Export, AirDrop, Finder, or iTunes, then choose the exported file from this browser.</li>'
      + '    </ul>'
      + '  </div>'
      + '</details>';
  }

  function renderMinimalDeckSummaryHtml() {
    var deckSummary = storageRead(DECK_SUMMARY_KEY);
    if (!deckSummary || deckSummary.status !== "extracted") {
      return '<p class="study-muted">Choose an Anki file to show deck and card counts.</p>';
    }

    var summary = deckSummary.summary || {};
    var decks = Array.isArray(deckSummary.decks) ? deckSummary.decks : [];
    var deckRows = decks.length
      ? decks.map(function (deck) {
          return ''
            + '<div class="profile-preference-row apc-anki-minimal-deck-row">'
            + '  <span>' + escapeHtml(deck.name || deck.id || "Unnamed deck") + '</span>'
            + '  <strong>' + escapeHtml(deck.card_count || 0) + ' card(s)</strong>'
            + '</div>';
        }).join("")
      : '<p class="study-muted">No decks with cards were found.</p>';

    return ''
      + '<div class="apc-anki-minimal-summary">'
      + '  <div class="profile-preference-row"><span>Decks</span><strong>' + escapeHtml(summary.deck_count_with_cards || decks.length || 0) + '</strong></div>'
      + '  <div class="profile-preference-row"><span>Total cards</span><strong>' + escapeHtml(summary.card_count || 0) + '</strong></div>'
      + '  <h4>Deck card counts</h4>'
      + deckRows
      + '</div>';
  }

  function renderPanelHtml(message) {
    return ''
      + '<section class="profile-card apc-anki-minimal-card" id="' + PANEL_ID + '-card">'
      + '  <h3>Anki</h3>'
      + '  <p class="study-muted">Choose your Anki collection file. APC reads deck names and card counts locally in this browser.</p>'
      + renderAnkiFileHelpHtml()
      + (message ? '<p class="apc-anki-message">' + escapeHtml(message) + '</p>' : '')
      + '  <div class="profile-preference-row">'
      + '    <label for="' + FILE_INPUT_ID + '"><strong>Choose Anki file</strong></label>'
      + '    <input id="' + FILE_INPUT_ID + '" type="file" accept=".anki2,.anki21,.sqlite,.db,.colpkg,.apkg">'
      + '  </div>'
      + renderMinimalDeckSummaryHtml()
      + '</section>';
  }

  function isProfileRoute() {
    var routeText = String(window.location.pathname + " " + window.location.hash).toLowerCase();
    if (routeText.indexOf("profile") !== -1) return true;
    return Boolean(document.querySelector("[data-page='profile'], #profilePrivateApp, .apc-profile-root"));
  }



  function findMountHost() {
    return document.querySelector("[data-page='profile']")
      || document.querySelector(".profile-grid")
      || document.querySelector(".private-profile-grid")
      || document.querySelector("main")
      || document.body;
  }

  function bindPanel(panel) {
    var fileInput = panel.querySelector("#" + FILE_INPUT_ID);
    var clearFileButton = panel.querySelector("#" + CLEAR_BUTTON_ID);

    if (fileInput) {
      fileInput.addEventListener("change", async function () {
        var file = fileInput.files && fileInput.files[0] ? fileInput.files[0] : null;
        if (!file) return;

        try {
          renderPanel("Reading local Anki file proof…");
          var proof = await buildFileProof(file);
          saveFileProof(proof);
          clearSavedDeckSummary();

          if (proof.header_kind !== "sqlite-anki-collection") {
            saveDeckSummary({
              status: "error",
              message: "This file does not look like an Anki SQLite collection.",
              privacy: {
                browser_local_only: true,
                uploads_performed: false,
                anki_file_modified: false
              }
            });
            renderPanel("File proof saved locally, but deck extraction was skipped.");
            return;
          }

          renderPanel("Extracting deck names locally in this browser…");
          var summary = await extractLocalAnkiSummary(file);
          saveDeckSummary(summary);
          renderPanel("Local Anki deck extraction complete. No Anki content was uploaded.");
        } catch (error) {
          saveDeckSummary({
            status: "error",
            message: String(error && error.message || error),
            privacy: {
              browser_local_only: true,
              uploads_performed: false,
              anki_file_modified: false
            }
          });
          renderPanel("Local Anki deck extraction failed.");
        }
      });
    }

    if (clearFileButton) {
      clearFileButton.addEventListener("click", function () {
        clearSavedFileProof();
        clearSavedDeckSummary();
        renderPanel("Local Anki proof cleared.");
      });
    }
  }

  function removeManifestPanel() {
    var panel = document.getElementById(PANEL_ID);
    if (panel && panel.parentNode) panel.parentNode.removeChild(panel);
    var card = document.getElementById(PANEL_ID + "-card");
    if (card && card.parentNode) card.parentNode.removeChild(card);
    document.querySelectorAll(".apc-anki-manifest-panel, .apc-anki-local-only-panel, .apc-anki-local-card, .apc-anki-ownership-card").forEach(function (el) {
      if (el && el.parentNode) el.parentNode.removeChild(el);
    });
  }


  function renderPanel(message) {
    if (!isProfileRoute()) { removeManifestPanel(); return; }

    var host = findMountHost();
    if (!host) return;

    var panel = document.getElementById(PANEL_ID);
    if (!panel) {
      panel = document.createElement("section");
      panel.id = PANEL_ID;
      panel.className = "apc-anki-manifest-panel apc-anki-local-only-panel";
      host.appendChild(panel);
    }

    panel.innerHTML = renderPanelHtml(message);
    bindPanel(panel);
  }

  function scheduleMount() {
    if (mountTimer) window.clearTimeout(mountTimer);
    mountTimer = window.setTimeout(function () {
      renderPanel();
    }, 50);
  }

  window.APC_ANKI_LOCAL = {
    version: "stage17ky-profile-anki-minimal-panel-20260629",
    readSavedFileProof: readSavedFileProof,
    readSavedDeckSummary: readSavedDeckSummary,
    clearSavedFileProof: clearSavedFileProof,
    clearSavedDeckSummary: clearSavedDeckSummary,
    extractLocalAnkiSummary: extractLocalAnkiSummary,
    renderPanel: renderPanel,
    privacy: {
      browser_local_only: true,
      uploads_performed: false,
      server_saved_anki_content: false,
      anki_write_allowed: false
    }
  };

  window.addEventListener("DOMContentLoaded", scheduleMount);
  window.addEventListener("popstate", scheduleMount);
  window.addEventListener("hashchange", scheduleMount);

  document.addEventListener("apc-private-page-rendered", function () {
    scheduleMount();
  });

  document.addEventListener("click", function () {
    scheduleMount();
  });

  scheduleMount();
})();
