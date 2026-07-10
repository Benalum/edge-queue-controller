(function apcProfileLocalBackupFolderPanelR16CB(root) {
  "use strict";

  const MARKER = "APC_PROFILE_LOCAL_BACKUP_FOLDER_PANEL_R16CB";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const SNAPSHOT_PREFIX = "buddies-who-study-local-backup-v3-";
  const PANEL_ATTR = "data-apc-local-backup-folder-panel-r16cb";
  const IDB_NAME = "buddies_who_study_backup_folder_r16cb_v1";
  const IDB_STORE = "handles";
  const IDB_KEY = "backup-folder";

  if (root.APC_PROFILE_LOCAL_BACKUP_FOLDER_PANEL_R16CB) return;

  function isObj(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
  function arr(value) { return Array.isArray(value) ? value : []; }
  function clone(value) { return value === undefined ? undefined : JSON.parse(JSON.stringify(value)); }
  function nowIso() { return new Date().toISOString(); }
  function stamp() { return nowIso().replace(/[:.]/g, "-"); }
  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
  function bytes(n) {
    const value = Number(n || 0);
    if (value >= 1024 * 1024) return (value / (1024 * 1024)).toFixed(1) + " MB";
    if (value >= 1024) return Math.round(value / 1024) + " KB";
    return value + " bytes";
  }
  function supportsFolderWrite() {
    return Boolean(root.showDirectoryPicker && root.FileSystemDirectoryHandle);
  }
  function currentEmail() {
    try {
      const me = root.APC_PRIVATEPAGES && typeof root.APC_PRIVATEPAGES.me === "function" ? root.APC_PRIVATEPAGES.me() : null;
      if (me && me.email) return String(me.email);
    } catch (_) {}
    return "browser-local@buddies.local";
  }
  function readJson(key, fallback) {
    try {
      const raw = root.localStorage.getItem(key);
      if (!raw) return fallback;
      const parsed = JSON.parse(raw);
      return parsed == null ? fallback : parsed;
    } catch (_) {
      return fallback;
    }
  }
  function localStorageSnapshot() {
    const prefixes = [
      "apcPrivateStudyState:",
      "apcLocalProfileSettings:",
      "apcPrivateCompanionVoiceSettings:",
      "apcPrivateCompanionMessages:",
      "apcLastKnownSignedInEmail",
      "apcStudy",
      "buddies"
    ];
    const items = [];
    try {
      for (let i = 0; i < root.localStorage.length; i += 1) {
        const key = root.localStorage.key(i);
        if (!key) continue;
        if (!prefixes.some((prefix) => String(key).startsWith(prefix))) continue;
        items.push({ key, value: root.localStorage.getItem(key) || "" });
      }
    } catch (_) {}
    return items.sort((a, b) => String(a.key).localeCompare(String(b.key)));
  }
  async function blobToDataUrl(blob) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result || ""));
      reader.onerror = () => reject(reader.error || new Error("Unable to read local media blob."));
      reader.readAsDataURL(blob);
    });
  }
  async function collectLocalSaveDocs(docs, payload) {
    const api = root.APC_LOCAL_SAVE;
    let media = [];
    let events = [];

    if (!api) {
      docs["local/media-manifest/v1"] = { schemaVersion: 1, updatedAt: nowIso(), mediaCount: 0, totalBytes: 0, items: [] };
      docs["local/media-blobs/v1"] = { schemaVersion: 1, updatedAt: nowIso(), blobCount: 0, blobs: [] };
      return { media, events };
    }

    if (typeof api.ensureManifest === "function") {
      try { await api.ensureManifest(); } catch (_) {}
    }
    if (typeof api.listDocs === "function") {
      try {
        const listed = await api.listDocs();
        arr(listed).forEach((record) => {
          if (!record || !record.key) return;
          docs[String(record.key)] = record.value === undefined ? null : clone(record.value);
        });
      } catch (error) {
        console.warn("[backup-folder] listDocs failed", error);
      }
    }
    if (typeof api.listEvents === "function") {
      try { events = arr(await api.listEvents({ limit: 5000 })); } catch (_) { events = []; }
      docs["study/events/v1"] = { schemaVersion: 1, updatedAt: nowIso(), events: clone(events) };
    }
    if (typeof api.listMedia === "function") {
      try { media = arr(await api.listMedia()); } catch (_) { media = []; }
    }

    const blobs = [];
    if (media.length && typeof api.getMediaBlob === "function") {
      for (const item of media) {
        try {
          const blob = await api.getMediaBlob(item.sha256);
          if (!blob) continue;
          blobs.push(Object.assign({}, clone(item), { dataUrl: await blobToDataUrl(blob), backedUpAt: nowIso() }));
        } catch (error) {
          blobs.push(Object.assign({}, clone(item), { backupError: String(error && error.message ? error.message : error) }));
        }
      }
    }

    docs["local/media-manifest/v1"] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      mediaCount: media.length,
      totalBytes: media.reduce((sum, item) => sum + Number(item.sizeBytes || 0), 0),
      items: clone(media)
    };
    docs["local/media-blobs/v1"] = { schemaVersion: 1, updatedAt: nowIso(), blobCount: blobs.length, blobs };
    payload.media = {
      count: media.length,
      totalBytes: media.reduce((sum, item) => sum + Number(item.sizeBytes || 0), 0),
      includesLocalBlobDataUrls: true
    };
    return { media, events };
  }
  function progressFromStudyState(state) {
    const cards = arr(state && state.cards);
    const decks = arr(state && state.decks);
    const sessions = arr(state && state.sessions);
    return {
      schemaVersion: 1,
      updatedAt: nowIso(),
      totals: {
        totalDecks: decks.length,
        totalCards: cards.length,
        totalSessions: sessions.length,
        reviewedCards: cards.filter((card) => Number(card.seenCount || 0) > 0).length,
        correct: cards.reduce((sum, card) => sum + Number(card.correctCount || 0), 0),
        wrong: cards.reduce((sum, card) => sum + Number(card.wrongCount || 0), 0),
        skipped: cards.reduce((sum, card) => sum + Number(card.skipCount || 0), 0)
      }
    };
  }
  async function buildBackupPayload(options) {
    const email = currentEmail();
    const docs = {};
    const payload = {
      kind: "buddies-who-study-local-backup",
      version: 3,
      app: "Buddies Who Study",
      label: "Buddies Who Study current local data",
      createdAt: nowIso(),
      updatedAt: nowIso(),
      requestedBy: options && options.requestedBy ? options.requestedBy : MARKER,
      emailScope: email,
      privacy: {
        localOnly: true,
        serverUpload: false,
        uploadsToServer: false,
        googleDriveSyncEnabled: false,
        ankiSourceMutation: false,
        writesAnkiFiles: false,
        originalAnkiBytesIncluded: false
      },
      docs
    };

    const store = root.APC_STUDY_STORE;
    let state = null;
    if (store && typeof store.flushLocalSaveMirror === "function") {
      try { await store.flushLocalSaveMirror(); } catch (_) {}
    }
    if (store && typeof store.load === "function") {
      try { state = store.load(); } catch (_) { state = null; }
    }
    if (state && isObj(state)) {
      docs["study/store-state/v1"] = { schemaVersion: 1, updatedAt: nowIso(), state: clone(state) };
      docs["study/decks/v1"] = { schemaVersion: 1, updatedAt: nowIso(), decks: clone(arr(state.decks)) };
      docs["study/cards/v1"] = { schemaVersion: 1, updatedAt: nowIso(), cards: clone(arr(state.cards)) };
      docs["study/sessions/v1"] = { schemaVersion: 1, updatedAt: nowIso(), sessions: clone(arr(state.sessions)), activeSession: clone(state.runtime || null) };
      docs["study/progress/v1"] = progressFromStudyState(state);
    }

    const localSave = await collectLocalSaveDocs(docs, payload);
    const profile = readJson("apcLocalProfileSettings:" + email, {});
    const companion = readJson("apcPrivateCompanionVoiceSettings:" + email, {});
    const messages = readJson("apcPrivateCompanionMessages:" + email, []);
    docs["profile/preferences/v1"] = { schemaVersion: 1, updatedAt: nowIso(), emailScope: email, settings: clone(profile || {}) };
    docs["companion/preferences/v1"] = { schemaVersion: 1, updatedAt: nowIso(), emailScope: email, settings: clone(companion || {}), messages: arr(messages).slice(-50) };
    docs["local/local-storage/v1"] = { schemaVersion: 1, updatedAt: nowIso(), items: localStorageSnapshot() };
    docs["anki/read-only-policy/v1"] = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      mode: "read-only-source-progress-local-only",
      readsAnkiCardsAndDecks: true,
      writesAnkiFiles: false,
      mutatesAnkiCards: false,
      mutatesAnkiDecks: false,
      storesBuddiesProgressOnly: true,
      originalAnkiBytesIncluded: false
    };

    const cards = state && isObj(state) ? arr(state.cards) : arr(docs["study/cards/v1"] && docs["study/cards/v1"].cards);
    const decks = state && isObj(state) ? arr(state.decks) : arr(docs["study/decks/v1"] && docs["study/decks/v1"].decks);
    const sessions = state && isObj(state) ? arr(state.sessions) : arr(docs["study/sessions/v1"] && docs["study/sessions/v1"].sessions);
    const cardImageRefs = cards.flatMap((card) => [card.frontImage, card.backImage, card.questionImage, card.answerImage]).filter(Boolean);
    const companionMediaRefs = [companion.listeningMediaRef, companion.talkingMediaRef, companion.thinkingMediaRef, companion.listeningVideoUrl, companion.talkingVideoUrl].filter(Boolean);

    payload.backupDocs = Object.keys(docs).sort();
    payload.coverage = {
      schemaVersion: 1,
      updatedAt: nowIso(),
      deckCount: decks.length,
      cardCount: cards.length,
      sessionCount: sessions.length,
      cardImageRefCount: cardImageRefs.length,
      companionMediaRefCount: companionMediaRefs.length,
      localMediaCount: localSave.media.length,
      localEventCount: localSave.events.length,
      includesStudyDecks: true,
      includesStudyCards: true,
      includesStudyStats: true,
      includesStudySessions: true,
      includesCardImages: true,
      includesCompanionSettings: true,
      includesCompanionClips: true,
      includesLocalMediaBlobs: true,
      includesAnkiProgressPolicy: true
    };
    return payload;
  }
  function summarizePayload(payload) {
    const docs = isObj(payload && payload.docs) ? payload.docs : {};
    const decks = arr(docs["study/decks/v1"] && docs["study/decks/v1"].decks);
    const cards = arr(docs["study/cards/v1"] && docs["study/cards/v1"].cards);
    const sessionsDoc = docs["study/sessions/v1"] || {};
    const sessions = arr(sessionsDoc.sessions || sessionsDoc.recentSessions);
    const progress = docs["study/progress/v1"] && docs["study/progress/v1"].totals ? docs["study/progress/v1"].totals : {};
    const mediaManifest = docs["local/media-manifest/v1"] || {};
    const mediaBlobs = docs["local/media-blobs/v1"] || {};
    const companion = docs["companion/preferences/v1"] && docs["companion/preferences/v1"].settings ? docs["companion/preferences/v1"].settings : {};
    const cardImageRefs = cards.flatMap((card) => [card.frontImage, card.backImage, card.questionImage, card.answerImage]).filter(Boolean);
    const companionRefs = [companion.listeningMediaRef, companion.talkingMediaRef, companion.thinkingMediaRef, companion.listeningVideoUrl, companion.talkingVideoUrl].filter(Boolean);
    return {
      version: payload && payload.version ? payload.version : "unknown",
      updatedAt: payload && (payload.updatedAt || payload.createdAt) ? (payload.updatedAt || payload.createdAt) : "unknown",
      decks: decks.length,
      cards: cards.length,
      sessions: sessions.length,
      cardImages: cardImageRefs.length,
      companionClips: companionRefs.length,
      localMedia: Number(mediaManifest.mediaCount || mediaBlobs.blobCount || 0),
      mediaBytes: Number(mediaManifest.totalBytes || 0),
      correct: Number(progress.correct || 0),
      wrong: Number(progress.wrong || 0),
      companionName: companion.displayName || companion.companionName || companion.name || "Sol",
      docCount: Object.keys(docs).length,
      decksList: decks.map((deck) => deck.name || deck.title || deck.id).filter(Boolean).slice(0, 12)
    };
  }
  function mergeBackupPayload(existing, current) {
    if (!isObj(existing) || !isObj(existing.docs)) return current;
    const merged = clone(existing);
    merged.version = Math.max(Number(existing.version || 1), Number(current.version || 3));
    merged.kind = current.kind || existing.kind || "buddies-who-study-local-backup";
    merged.app = current.app || existing.app || "Buddies Who Study";
    merged.label = "Buddies Who Study current local data";
    merged.createdAt = existing.createdAt || current.createdAt || nowIso();
    merged.updatedAt = nowIso();
    merged.privacy = Object.assign({}, existing.privacy || {}, current.privacy || {});
    merged.docs = Object.assign({}, existing.docs || {}, current.docs || {});
    merged.media = Object.assign({}, existing.media || {}, current.media || {});
    merged.coverage = Object.assign({}, existing.coverage || {}, current.coverage || {}, { updatedAt: nowIso() });
    merged.backupDocs = Object.keys(merged.docs).sort();
    merged.merge = {
      schemaVersion: 1,
      mergedAt: nowIso(),
      strategy: "preserve existing docs and replace changed Buddies Who Study docs with current browser-local data",
      noAnkiWrites: true,
      noServerUpload: true
    };
    return merged;
  }
  function renderSummary(summary) {
    return `
      <div class="apc-profile-backup-folder-grid">
        <span><strong>${escapeHtml(summary.decks)}</strong><small>decks</small></span>
        <span><strong>${escapeHtml(summary.cards)}</strong><small>cards</small></span>
        <span><strong>${escapeHtml(summary.sessions)}</strong><small>sessions</small></span>
        <span><strong>${escapeHtml(summary.cardImages)}</strong><small>card images</small></span>
        <span><strong>${escapeHtml(summary.companionClips)}</strong><small>companion clips</small></span>
        <span><strong>${escapeHtml(summary.localMedia)}</strong><small>local media</small></span>
        <span><strong>${escapeHtml(bytes(summary.mediaBytes))}</strong><small>media bytes</small></span>
        <span><strong>${escapeHtml(summary.correct + "/" + summary.wrong)}</strong><small>right/wrong</small></span>
      </div>
      <p><strong>Companion:</strong> ${escapeHtml(summary.companionName)}</p>
      <p><strong>Backup version:</strong> ${escapeHtml(summary.version)} · ${escapeHtml(summary.updatedAt)}</p>
      <p><strong>Document keys:</strong> ${escapeHtml(summary.docCount)}</p>
      ${summary.decksList.length ? `<p><strong>Decks:</strong> ${summary.decksList.map(escapeHtml).join(", ")}</p>` : `<p>No decks found yet.</p>`}
    `;
  }
  function downloadPayload(payload, name) {
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 500);
  }
  function openDb() {
    return new Promise((resolve, reject) => {
      const request = root.indexedDB.open(IDB_NAME, 1);
      request.onupgradeneeded = () => {
        const db = request.result;
        if (!db.objectStoreNames.contains(IDB_STORE)) db.createObjectStore(IDB_STORE);
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error || new Error("Could not open folder handle store."));
    });
  }
  async function idbGet(key) {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(IDB_STORE, "readonly");
      const request = tx.objectStore(IDB_STORE).get(key);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => reject(request.error || new Error("Could not read folder handle."));
      tx.oncomplete = () => db.close();
    });
  }
  async function idbPut(key, value) {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(IDB_STORE, "readwrite");
      const request = tx.objectStore(IDB_STORE).put(value, key);
      request.onsuccess = () => resolve(true);
      request.onerror = () => reject(request.error || new Error("Could not save folder handle."));
      tx.oncomplete = () => db.close();
    });
  }
  async function ensurePermission(handle, mode) {
    if (!handle || typeof handle.queryPermission !== "function") return true;
    const opts = { mode: mode || "read" };
    if ((await handle.queryPermission(opts)) === "granted") return true;
    if (typeof handle.requestPermission !== "function") return false;
    return (await handle.requestPermission(opts)) === "granted";
  }
  async function readFileFromHandle(fileHandle) {
    const file = await fileHandle.getFile();
    const text = await file.text();
    return JSON.parse(text);
  }
  async function writeJsonFile(directoryHandle, name, payload) {
    const fileHandle = await directoryHandle.getFileHandle(name, { create: true });
    const writable = await fileHandle.createWritable();
    await writable.write(JSON.stringify(payload, null, 2));
    await writable.close();
  }
  async function readCurrentFromFolder(handle) {
    try {
      const fileHandle = await handle.getFileHandle(CURRENT_FILE_NAME, { create: false });
      return await readFileFromHandle(fileHandle);
    } catch (_) {
      return null;
    }
  }
  async function listBackupFolder(handle) {
    const names = [];
    try {
      for await (const [name, child] of handle.entries()) {
        if (child && child.kind === "file" && String(name).endsWith(".json")) names.push(String(name));
      }
    } catch (_) {}
    return names.sort();
  }
  async function pickBackupFolder() {
    if (!supportsFolderWrite()) throw new Error("Folder write access is not supported in this browser. Use Chrome or Edge, or use Download snapshot.");
    const handle = await root.showDirectoryPicker({ id: "buddies-who-study-backup-folder", mode: "readwrite" });
    if (!(await ensurePermission(handle, "readwrite"))) throw new Error("Folder write permission was not granted.");
    await idbPut(IDB_KEY, handle);
    state.folderHandle = handle;
    await scanFolder();
    setStatus("Backup folder selected: " + escapeHtml(handle.name || "folder") + ".");
  }
  async function restoreSavedFolderHandle() {
    if (!supportsFolderWrite()) return null;
    try {
      const handle = await idbGet(IDB_KEY);
      if (!handle) return null;
      if (!(await ensurePermission(handle, "readwrite"))) return null;
      state.folderHandle = handle;
      return handle;
    } catch (_) {
      return null;
    }
  }
  async function scanFolder() {
    if (!state.folderHandle) throw new Error("Pick a backup folder first.");
    const names = await listBackupFolder(state.folderHandle);
    const current = await readCurrentFromFolder(state.folderHandle);
    const summary = current ? summarizePayload(current) : null;
    const currentLine = current ? "Found " + CURRENT_FILE_NAME + "." : "No current file found. It will be created on save.";
    setDetails(`
      <h3>Backup folder scan</h3>
      <p>${escapeHtml(currentLine)}</p>
      <p><strong>JSON files found:</strong> ${escapeHtml(names.length)}</p>
      ${summary ? renderSummary(summary) : ""}
      <p class="muted">Save current backup will add new browser-local Study, Companion, Profile, card image, and media data to this folder. No Anki files are written.</p>
    `);
  }
  async function saveCurrentToFolder() {
    if (!state.folderHandle) throw new Error("Pick a backup folder first.");
    if (!(await ensurePermission(state.folderHandle, "readwrite"))) throw new Error("Folder write permission was not granted.");
    setStatus("Building backup from current browser data...");
    const current = await buildBackupPayload({ requestedBy: MARKER });
    const existing = await readCurrentFromFolder(state.folderHandle);
    const merged = mergeBackupPayload(existing, current);
    if (existing) await writeJsonFile(state.folderHandle, PREVIOUS_FILE_NAME, existing);
    await writeJsonFile(state.folderHandle, CURRENT_FILE_NAME, merged);
    await writeJsonFile(state.folderHandle, SNAPSHOT_PREFIX + stamp() + ".json", merged);
    const summary = summarizePayload(merged);
    setStatus("Saved current browser data into backup folder.");
    setDetails(`
      <h3>Saved backup folder</h3>
      <p>Updated <strong>${escapeHtml(CURRENT_FILE_NAME)}</strong>${existing ? " and refreshed the previous-file copy" : ""}. A timestamped snapshot was also created.</p>
      ${renderSummary(summary)}
      <p class="muted">No server upload. No Google Drive sync. No Anki file writes.</p>
    `);
  }
  async function downloadSnapshot() {
    const payload = await buildBackupPayload({ requestedBy: MARKER + ":download" });
    downloadPayload(payload, CURRENT_FILE_NAME);
    setStatus("Downloaded " + CURRENT_FILE_NAME + ". Nothing was uploaded.");
    setDetails("<h3>Downloaded snapshot</h3>" + renderSummary(summarizePayload(payload)));
  }
  async function previewPickedFiles(files) {
    const file = files && files[0];
    if (!file) return;
    const text = await file.text();
    const payload = JSON.parse(text);
    setStatus("Previewed backup file: " + escapeHtml(file.name) + ". No data was restored.");
    setDetails("<h3>Backup file details</h3>" + renderSummary(summarizePayload(payload)) + "<p class=\"muted\">Preview only. No restore, merge, upload, or Anki write happened.</p>");
  }

  const state = { folderHandle: null };
  let statusNode = null;
  let detailsNode = null;

  function setStatus(message) {
    if (statusNode) statusNode.innerHTML = String(message || "");
  }
  function setDetails(html) {
    if (detailsNode) detailsNode.innerHTML = String(html || "");
  }
  function rootMount() {
    return document.getElementById("profileLocalFirstSettings") || document.querySelector("main") || document.body;
  }
  function panelHtml() {
    return `
      <article class="private-card apc-profile-backup-folder-panel" ${PANEL_ATTR}="true">
        <h2>Local backup folder</h2>
        <p>Pick a folder once. Buddies Who Study will look for <strong>${CURRENT_FILE_NAME}</strong>, read what is already there, and when you save it will add the newest local decks, cards, stats, images, companion clips, and settings.</p>
        <div class="apc-profile-backup-actions">
          <button type="button" data-apc-pick-backup-folder>Pick Backup Folder</button>
          <button type="button" data-apc-scan-backup-folder>Scan folder</button>
          <button type="button" data-apc-save-backup-folder>Save current backup</button>
          <button type="button" data-apc-download-backup-snapshot>Download snapshot</button>
          <label class="apc-profile-backup-file-label">Preview backup file <input type="file" accept="application/json,.json" data-apc-preview-backup-file></label>
        </div>
        <p class="muted">Chrome and Edge can save directly to a picked folder. Firefox can preview/download, but cannot write to a folder from a website yet.</p>
        <p class="muted"><strong>Anki safety:</strong> Anki decks/cards may be read as a source, but Buddies Who Study only saves progress and local media in its own backup. It never writes to Anki files.</p>
        <div class="apc-profile-backup-folder-status" data-apc-backup-folder-status></div>
        <div class="apc-profile-backup-folder-details" data-apc-backup-folder-details></div>
      </article>
    `;
  }
  function bindPanel(panel) {
    statusNode = panel.querySelector("[data-apc-backup-folder-status]");
    detailsNode = panel.querySelector("[data-apc-backup-folder-details]");
    const wrap = (fn) => async () => {
      try { await fn(); } catch (error) { setStatus("Error: " + escapeHtml(error && error.message ? error.message : error)); }
    };
    panel.querySelector("[data-apc-pick-backup-folder]").addEventListener("click", wrap(pickBackupFolder));
    panel.querySelector("[data-apc-scan-backup-folder]").addEventListener("click", wrap(scanFolder));
    panel.querySelector("[data-apc-save-backup-folder]").addEventListener("click", wrap(saveCurrentToFolder));
    panel.querySelector("[data-apc-download-backup-snapshot]").addEventListener("click", wrap(downloadSnapshot));
    panel.querySelector("[data-apc-preview-backup-file]").addEventListener("change", (event) => previewPickedFiles(event.target.files).catch((error) => setStatus("Error: " + escapeHtml(error && error.message ? error.message : error))));

    if (!supportsFolderWrite()) {
      setStatus("Folder saving is unavailable in this browser. Use Download snapshot or Preview backup file, or use Chrome/Edge for Pick Backup Folder.");
    } else {
      setStatus("Ready. Pick a backup folder, then Save current backup.");
      restoreSavedFolderHandle().then((handle) => {
        if (handle) {
          setStatus("Previous backup folder permission found. You can scan or save.");
          scanFolder().catch(() => {});
        }
      }).catch(() => {});
    }
  }
  function mountPanel() {
    const path = root.location && root.location.pathname ? root.location.pathname : "";
    if (path !== "/profile") return;
    if (document.querySelector("[" + PANEL_ATTR + "]")) return;
    const mount = rootMount();
    if (!mount) return;
    const holder = document.createElement("div");
    holder.innerHTML = panelHtml().trim();
    const panel = holder.firstElementChild;
    mount.insertAdjacentElement("afterend", panel);
    bindPanel(panel);
  }

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "profile") {
      setTimeout(mountPanel, 0);
      setTimeout(mountPanel, 150);
      setTimeout(mountPanel, 600);
    }
  });
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", mountPanel, { once: true });
  } else {
    mountPanel();
  }

  root.APC_PROFILE_LOCAL_BACKUP_FOLDER_PANEL_R16CB = Object.freeze({
    marker: MARKER,
    buildBackupPayload,
    mergeBackupPayload,
    summarizePayload,
    mountPanel,
    noAnkiWrites: true,
    noServerUpload: true
  });
})(typeof window !== "undefined" ? window : globalThis);
