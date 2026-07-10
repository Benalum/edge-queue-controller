(function apcProfileBackupFolderWorkspaceR16BZ(root) {
  "use strict";

  const MARKER = "APC_PROFILE_BACKUP_FOLDER_WORKSPACE_R16BZ";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PREVIOUS_FILE_NAME = "buddies-who-study-current.previous.json";
  const PANEL_SELECTOR = "[data-apc-complete-local-backup-manager='true']";
  const WORKSPACE_SELECTOR = "[data-apc-backup-folder-workspace='true']";
  const IDB_NAME = "buddies_who_study_backup_folder_v1";
  const IDB_STORE = "handles";
  const IDB_KEY = "backup-folder";

  if (root.APC_PROFILE_BACKUP_FOLDER_WORKSPACE_R16BZ) return;

  function doc() { return root && root.document ? root.document : null; }
  function isObj(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
  function arr(value) { return Array.isArray(value) ? value : []; }
  function clone(value) { return value === undefined ? undefined : JSON.parse(JSON.stringify(value)); }
  function nowIso() { return new Date().toISOString(); }
  function safeFileStamp() { return nowIso().replace(/[:.]/g, "-"); }
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
    if (value > 1024 * 1024) return (value / (1024 * 1024)).toFixed(1) + " MB";
    if (value > 1024) return Math.round(value / 1024) + " KB";
    return value + " bytes";
  }

  function supportsWritableFolder() {
    return Boolean(root.showDirectoryPicker && root.FileSystemDirectoryHandle);
  }

  function backupPanelApi() {
    return root.APC_PROFILE_LOCAL_BACKUPS_PANEL || null;
  }

  async function buildCurrentPayload() {
    const api = backupPanelApi();
    if (!api || typeof api.buildBackupPayload !== "function") {
      throw new Error("Complete local backup builder is not loaded yet.");
    }
    const payload = await api.buildBackupPayload({ requestedBy: MARKER, createdAt: nowIso() });
    if (!isObj(payload)) throw new Error("Backup builder returned an invalid payload.");
    return payload;
  }

  function openDb() {
    return new Promise((resolve, reject) => {
      const req = root.indexedDB.open(IDB_NAME, 1);
      req.onupgradeneeded = () => {
        const db = req.result;
        if (!db.objectStoreNames.contains(IDB_STORE)) db.createObjectStore(IDB_STORE);
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error || new Error("Could not open backup folder handle store."));
    });
  }

  async function idbGet(key) {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(IDB_STORE, "readonly");
      const req = tx.objectStore(IDB_STORE).get(key);
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => reject(req.error || new Error("Could not read folder handle."));
      tx.oncomplete = () => db.close();
    });
  }

  async function idbPut(key, value) {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(IDB_STORE, "readwrite");
      const req = tx.objectStore(IDB_STORE).put(value, key);
      req.onsuccess = () => resolve(true);
      req.onerror = () => reject(req.error || new Error("Could not save folder handle."));
      tx.oncomplete = () => db.close();
    });
  }

  async function ensurePermission(handle, mode) {
    if (!handle || typeof handle.queryPermission !== "function") return true;
    const opts = { mode: mode || "read" };
    const current = await handle.queryPermission(opts);
    if (current === "granted") return true;
    if (typeof handle.requestPermission !== "function") return false;
    return (await handle.requestPermission(opts)) === "granted";
  }

  async function pickWritableFolder() {
    if (!supportsWritableFolder()) {
      throw new Error("This browser cannot write to a picked folder. Use Chrome or Edge for Pick Backup Folder, or use the download fallback.");
    }
    const handle = await root.showDirectoryPicker({ mode: "readwrite" });
    const ok = await ensurePermission(handle, "readwrite");
    if (!ok) throw new Error("Folder write permission was not granted.");
    await idbPut(IDB_KEY, handle);
    setStatus("Backup folder selected: " + (handle.name || "folder") + ". Save-to-folder is enabled for this browser profile.");
    await scanWritableFolder(handle);
    return handle;
  }

  async function getSavedWritableFolder() {
    const handle = await idbGet(IDB_KEY);
    if (!handle) return null;
    const ok = await ensurePermission(handle, "readwrite");
    return ok ? handle : null;
  }

  async function readJsonFileHandle(fileHandle) {
    const file = await fileHandle.getFile();
    const text = await file.text();
    return JSON.parse(text);
  }

  async function writeTextFile(dirHandle, fileName, text) {
    const fileHandle = await dirHandle.getFileHandle(fileName, { create: true });
    const writable = await fileHandle.createWritable();
    await writable.write(text);
    await writable.close();
    return fileHandle;
  }

  async function readCurrentFromDir(dirHandle) {
    try {
      const fileHandle = await dirHandle.getFileHandle(CURRENT_FILE_NAME, { create: false });
      const file = await fileHandle.getFile();
      return { payload: JSON.parse(await file.text()), file, exists: true };
    } catch (error) {
      return { payload: null, file: null, exists: false, error };
    }
  }

  function identityKey(item, index) {
    if (!isObj(item)) return "primitive:" + String(item);
    const keys = ["id", "deckId", "cardId", "sessionId", "mediaId", "blobId", "sha256", "hash", "fileName", "name", "createdAt", "updatedAt"];
    for (const key of keys) {
      if (item[key] !== undefined && item[key] !== null && String(item[key]).trim()) return key + ":" + String(item[key]);
    }
    return "index:" + index + ":" + JSON.stringify(item).slice(0, 120);
  }

  function mergeArrays(oldArr, newArr) {
    const map = new Map();
    arr(oldArr).forEach((item, index) => map.set(identityKey(item, index), clone(item)));
    arr(newArr).forEach((item, index) => {
      const key = identityKey(item, index);
      const previous = map.get(key);
      if (isObj(previous) && isObj(item)) map.set(key, mergeObjects(previous, item));
      else map.set(key, clone(item));
    });
    return Array.from(map.values());
  }

  function mergeObjects(oldObj, newObj) {
    const out = isObj(oldObj) ? clone(oldObj) : {};
    if (!isObj(newObj)) return clone(newObj);
    Object.keys(newObj).forEach((key) => {
      const oldValue = out[key];
      const newValue = newObj[key];
      if (Array.isArray(oldValue) || Array.isArray(newValue)) out[key] = mergeArrays(oldValue, newValue);
      else if (isObj(oldValue) && isObj(newValue)) out[key] = mergeObjects(oldValue, newValue);
      else out[key] = clone(newValue);
    });
    return out;
  }

  function mergeBackupPayload(existingPayload, currentPayload) {
    const existing = isObj(existingPayload) ? existingPayload : {};
    const current = isObj(currentPayload) ? currentPayload : {};
    const merged = mergeObjects(existing, current);
    merged.version = Math.max(Number(existing.version || 0), Number(current.version || 0), 3);
    merged.createdAt = existing.createdAt || current.createdAt || nowIso();
    merged.updatedAt = nowIso();
    merged.backupRole = "current";
    merged.fileName = CURRENT_FILE_NAME;
    merged.localFirst = true;
    merged.mergePolicy = "folder-save preserves existing backup docs and adds/updates current browser-local data by stable ids when available";
    merged.safety = mergeObjects(existing.safety || {}, current.safety || {});
    merged.safety.backendUpload = false;
    merged.safety.googleDriveSync = false;
    merged.safety.ankiWrites = false;
    merged.safety.restoreOrMergeIntoBrowser = false;
    return merged;
  }

  function docs(payload) { return isObj(payload && payload.docs) ? payload.docs : {}; }
  function unwrapArrayDoc(docValue, propNames) {
    if (Array.isArray(docValue)) return docValue;
    if (!isObj(docValue)) return [];
    for (const prop of propNames) if (Array.isArray(docValue[prop])) return docValue[prop];
    if (Array.isArray(docValue.value)) return docValue.value;
    if (isObj(docValue.value)) return unwrapArrayDoc(docValue.value, propNames);
    return [];
  }
  function countDecks(payload) { return unwrapArrayDoc(docs(payload)["study/decks/v1"], ["decks", "items", "records"]).length; }
  function countCards(payload) { return unwrapArrayDoc(docs(payload)["study/cards/v1"], ["cards", "items", "records"]).length; }
  function countSessions(payload) {
    const value = docs(payload)["study/sessions/v1"];
    return unwrapArrayDoc(value, ["sessions", "recentSessions", "items", "records"]).length;
  }
  function mediaSummary(payload) {
    const d = docs(payload);
    const manifest = isObj(d["local/media-manifest/v1"]) ? d["local/media-manifest/v1"] : (isObj(d["study/media-manifest/v1"]) ? d["study/media-manifest/v1"] : {});
    const blobs = isObj(d["local/media-blobs/v1"]) ? d["local/media-blobs/v1"] : (isObj(d["study/media-blobs/v1"]) ? d["study/media-blobs/v1"] : {});
    return {
      mediaCount: Number(manifest.mediaCount || arr(manifest.items).length || 0),
      blobCount: arr(blobs.blobs).length,
      totalBytes: Number(manifest.totalBytes || 0)
    };
  }

  function summaryLine(payload) {
    const m = mediaSummary(payload);
    return `${countDecks(payload)} decks, ${countCards(payload)} cards, ${countSessions(payload)} sessions, ${m.mediaCount} media items, ${m.blobCount} media blobs, ${bytes(m.totalBytes)}`;
  }

  async function scanWritableFolder(handle) {
    const dirHandle = handle || await getSavedWritableFolder();
    if (!dirHandle) {
      setStatus("No writable backup folder is selected yet.");
      return null;
    }
    const found = [];
    for await (const [name, entry] of dirHandle.entries()) {
      if (entry.kind === "file" && (name === CURRENT_FILE_NAME || name === PREVIOUS_FILE_NAME || /^buddies-who-study-local-backup-.*\.json$/.test(name))) {
        found.push(name);
      }
    }
    found.sort();
    const current = await readCurrentFromDir(dirHandle);
    const currentSummary = current.exists ? summaryLine(current.payload) : "No buddies-who-study-current.json found yet.";
    renderOutput(`
      <div class="study-muted"><strong>Selected folder:</strong> ${escapeHtml(dirHandle.name || "folder")}</div>
      <p><strong>Current file:</strong> ${escapeHtml(currentSummary)}</p>
      <p><strong>Backup files found:</strong> ${found.length}</p>
      <ul>${found.map((name) => `<li>${escapeHtml(name)}</li>`).join("") || "<li>No backup JSON files found yet.</li>"}</ul>
    `);
    setStatus("Backup folder scan complete.");
    return { dirHandle, found, current };
  }

  async function saveCurrentToFolder() {
    const dirHandle = await getSavedWritableFolder();
    if (!dirHandle) throw new Error("Pick a writable backup folder first. In browsers without folder-write support, use Download current backup instead.");
    const ok = await ensurePermission(dirHandle, "readwrite");
    if (!ok) throw new Error("Folder write permission is not available.");

    setStatus("Building current local backup and reading existing folder file…");
    const currentPayload = await buildCurrentPayload();
    const existing = await readCurrentFromDir(dirHandle);
    const merged = mergeBackupPayload(existing.payload, currentPayload);
    const mergedText = JSON.stringify(merged, null, 2);

    if (existing.exists && existing.file) {
      const previousText = await existing.file.text();
      await writeTextFile(dirHandle, PREVIOUS_FILE_NAME, previousText);
    }
    await writeTextFile(dirHandle, CURRENT_FILE_NAME, mergedText);
    const snapshotName = "buddies-who-study-local-backup-v3-" + safeFileStamp() + ".json";
    await writeTextFile(dirHandle, snapshotName, mergedText);

    renderOutput(`
      <p><strong>Saved current backup to folder.</strong></p>
      <p>${escapeHtml(summaryLine(merged))}</p>
      <ul>
        <li>Updated: ${escapeHtml(CURRENT_FILE_NAME)}</li>
        <li>${existing.exists ? "Wrote last-good copy: " + escapeHtml(PREVIOUS_FILE_NAME) : "No previous current file existed, so no last-good file was needed."}</li>
        <li>Wrote snapshot: ${escapeHtml(snapshotName)}</li>
      </ul>
      <p class="study-muted">No browser data was restored. No backend upload. No Google Drive sync. No Anki file writes.</p>
    `);
    setStatus("Save complete. New browser-local data has been added/updated in the picked folder backup.");
    return merged;
  }

  function summarizeFallbackFiles(files) {
    const list = Array.from(files || []);
    const backupFiles = list.filter((file) => /(^|\/)buddies-who-study-(current|current\.previous|local-backup-.*)\.json$/.test(file.webkitRelativePath || file.name));
    const current = backupFiles.find((file) => (file.webkitRelativePath || file.name).endsWith("/" + CURRENT_FILE_NAME) || file.name === CURRENT_FILE_NAME);
    renderOutput(`
      <p><strong>Folder inspected in read-only mode.</strong></p>
      <p>Files selected: ${escapeHtml(list.length)}. Backup JSON files found: ${escapeHtml(backupFiles.length)}.</p>
      <p>${current ? "Found " + escapeHtml(CURRENT_FILE_NAME) + "." : "No " + escapeHtml(CURRENT_FILE_NAME) + " found in the selected folder."}</p>
      <ul>${backupFiles.slice(0, 40).map((file) => `<li>${escapeHtml(file.webkitRelativePath || file.name)} · ${escapeHtml(bytes(file.size))}</li>`).join("") || "<li>No matching backup JSON files found.</li>"}</ul>
      <p class="study-muted">This browser path can inspect folder contents, but cannot safely write back to the selected folder. Use Chrome/Edge Pick Backup Folder for direct save, or use Download current backup.</p>
    `);
    setStatus("Read-only folder inspection complete.");
  }

  function setStatus(text) {
    const node = doc() && doc().querySelector("[data-apc-backup-folder-status]");
    if (node) node.textContent = text || "";
  }
  function renderOutput(html) {
    const node = doc() && doc().querySelector("[data-apc-backup-folder-output]");
    if (!node) return;
    node.innerHTML = html || "";
    node.hidden = !html;
  }

  function openFallbackFolderPicker() {
    const input = doc() && doc().querySelector("[data-apc-backup-folder-input]");
    if (input) {
      input.value = "";
      input.click();
    }
  }

  function triggerDownloadFallback() {
    const button = doc() && doc().querySelector("[data-apc-complete-backup-download-current]");
    if (button) button.click();
  }

  function renderHtml() {
    const writable = supportsWritableFolder();
    return `
      <section class="private-card apc-backup-folder-workspace" data-apc-backup-folder-workspace="true" style="border:1px solid rgba(76, 122, 255, .35);border-radius:16px;padding:14px;margin:0 0 14px;background:rgba(76,122,255,.06);">
        <h3 style="margin:.1rem 0 .35rem;">Backup folder workspace</h3>
        <p class="study-muted">Pick a backup folder once. Buddies Who Study will look for ${escapeHtml(CURRENT_FILE_NAME)}, read what is already there, and when you save it writes a merged current file plus a last-good copy and snapshot.</p>
        <div class="private-actions" style="display:flex;flex-wrap:wrap;gap:8px;margin:.75rem 0;">
          <button type="button" class="private-button" data-apc-pick-backup-folder ${writable ? "" : "disabled"}>Pick backup folder</button>
          <button type="button" class="private-button secondary" data-apc-scan-backup-folder ${writable ? "" : "disabled"}>Scan picked folder</button>
          <button type="button" class="private-button" data-apc-save-current-to-folder ${writable ? "" : "disabled"}>Save current to folder</button>
          <button type="button" class="private-button secondary" data-apc-inspect-folder-fallback>Inspect folder read-only</button>
          <button type="button" class="private-button secondary" data-apc-folder-download-fallback>Download current backup</button>
        </div>
        <input type="file" data-apc-backup-folder-input webkitdirectory directory multiple hidden />
        <p class="study-muted" data-apc-backup-folder-status>${writable ? "Ready for folder save in this browser." : "Folder write is not available in this browser. You can inspect a folder or download the current backup."}</p>
        <div data-apc-backup-folder-output hidden></div>
        <p class="study-muted">Safety: local folder only, no server upload, no Google Drive sync, no restore into browser data, and no Anki source writes.</p>
      </section>
    `;
  }

  function mount() {
    const d = doc();
    if (!d) return false;
    const complete = d.querySelector(PANEL_SELECTOR);
    if (!complete) return false;
    if (d.querySelector(WORKSPACE_SELECTOR)) return true;
    complete.insertAdjacentHTML("afterend", renderHtml());
    tryAutoRestore().catch(() => {});
    return true;
  }

  async function tryAutoRestore() {
    if (!supportsWritableFolder()) return;
    const handle = await getSavedWritableFolder();
    if (handle) {
      setStatus("Restored backup folder permission: " + (handle.name || "folder") + ".");
      await scanWritableFolder(handle);
    }
  }

  function scheduleMount() {
    mount();
    root.setTimeout(mount, 0);
    root.setTimeout(mount, 150);
    root.setTimeout(mount, 500);
  }

  function bind() {
    const d = doc();
    if (!d || root.APC_PROFILE_BACKUP_FOLDER_WORKSPACE_CLICK_BOUND_R16BZ) return;
    root.APC_PROFILE_BACKUP_FOLDER_WORKSPACE_CLICK_BOUND_R16BZ = true;

    d.addEventListener("click", function onClick(event) {
      const target = event.target && event.target.closest ? event.target.closest("[data-apc-pick-backup-folder],[data-apc-scan-backup-folder],[data-apc-save-current-to-folder],[data-apc-inspect-folder-fallback],[data-apc-folder-download-fallback]") : null;
      if (!target) return;
      event.preventDefault();
      if (target.matches("[data-apc-pick-backup-folder]")) {
        pickWritableFolder().catch((error) => setStatus("Pick folder failed: " + String(error && error.message ? error.message : error)));
      } else if (target.matches("[data-apc-scan-backup-folder]")) {
        scanWritableFolder().catch((error) => setStatus("Scan failed: " + String(error && error.message ? error.message : error)));
      } else if (target.matches("[data-apc-save-current-to-folder]")) {
        saveCurrentToFolder().catch((error) => setStatus("Save failed: " + String(error && error.message ? error.message : error)));
      } else if (target.matches("[data-apc-inspect-folder-fallback]")) {
        openFallbackFolderPicker();
      } else if (target.matches("[data-apc-folder-download-fallback]")) {
        triggerDownloadFallback();
      }
    });

    d.addEventListener("change", function onChange(event) {
      const input = event.target && event.target.closest ? event.target.closest("[data-apc-backup-folder-input]") : null;
      if (!input) return;
      summarizeFallbackFiles(input.files || []);
    });
  }

  bind();
  ["apc-private-page-rendered", "apc-study-local-save-updated", "apc-companion-settings-changed", "apc-study-card-media-changed"].forEach((name) => {
    doc().addEventListener(name, function (event) {
      if (name === "apc-private-page-rendered" && (!event.detail || event.detail.page !== "profile")) return;
      scheduleMount();
    });
  });

  if (doc().readyState === "loading") {
    doc().addEventListener("DOMContentLoaded", scheduleMount, { once: true });
  } else {
    scheduleMount();
  }

  root.APC_PROFILE_BACKUP_FOLDER_WORKSPACE_R16BZ = Object.freeze({
    marker: MARKER,
    mount,
    scheduleMount,
    supportsWritableFolder,
    pickWritableFolder,
    scanWritableFolder,
    saveCurrentToFolder,
    mergeBackupPayload,
    currentFileName: CURRENT_FILE_NAME,
    previousFileName: PREVIOUS_FILE_NAME
  });
})(typeof window !== "undefined" ? window : globalThis);
