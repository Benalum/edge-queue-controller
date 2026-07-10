(function apcProfileCompleteLocalBackupManagerR16BY(root) {
  "use strict";

  const MARKER = "APC_PROFILE_COMPLETE_LOCAL_BACKUP_MANAGER_R16BY";
  const CURRENT_FILE_NAME = "buddies-who-study-current.json";
  const PANEL_SELECTOR = "[data-apc-profile-local-backups-panel='true']";
  const MANAGER_SELECTOR = "[data-apc-complete-local-backup-manager='true']";

  if (root.APC_PROFILE_COMPLETE_LOCAL_BACKUP_MANAGER_R16BY) return;

  function doc() { return root && root.document ? root.document : null; }
  function nowIso() { return new Date().toISOString(); }
  function isObj(value) { return value !== null && typeof value === "object" && !Array.isArray(value); }
  function arr(value) { return Array.isArray(value) ? value : []; }
  function clone(value) { return value === undefined ? undefined : JSON.parse(JSON.stringify(value)); }
  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function panelApi() {
    return root && root.APC_PROFILE_LOCAL_BACKUPS_PANEL ? root.APC_PROFILE_LOCAL_BACKUPS_PANEL : null;
  }

  function findDocs(payload) {
    if (!payload || !isObj(payload.docs)) return {};
    return payload.docs;
  }

  function unwrapArrayDoc(docValue, propNames) {
    if (Array.isArray(docValue)) return docValue;
    if (!isObj(docValue)) return [];
    for (const prop of propNames) {
      if (Array.isArray(docValue[prop])) return docValue[prop];
    }
    if (Array.isArray(docValue.value)) return docValue.value;
    if (isObj(docValue.value)) return unwrapArrayDoc(docValue.value, propNames);
    return [];
  }

  function deckList(payload) {
    const docs = findDocs(payload);
    return unwrapArrayDoc(docs["study/decks/v1"], ["decks", "items", "records"]);
  }

  function cardList(payload) {
    const docs = findDocs(payload);
    return unwrapArrayDoc(docs["study/cards/v1"], ["cards", "items", "records"]);
  }

  function sessionList(payload) {
    const docs = findDocs(payload);
    const value = docs["study/sessions/v1"];
    const sessions = unwrapArrayDoc(value, ["sessions", "recentSessions", "items", "records"]);
    if (sessions.length) return sessions;
    if (isObj(value) && Array.isArray(value.recentSessions)) return value.recentSessions;
    return [];
  }

  function mediaManifest(payload) {
    const docs = findDocs(payload);
    const local = docs["local/media-manifest/v1"];
    const legacy = docs["study/media-manifest/v1"];
    const manifest = isObj(local) ? local : (isObj(legacy) ? legacy : {});
    return {
      items: arr(manifest.items),
      mediaCount: Number(manifest.mediaCount || arr(manifest.items).length || 0),
      totalBytes: Number(manifest.totalBytes || 0)
    };
  }

  function mediaBlobs(payload) {
    const docs = findDocs(payload);
    const local = docs["local/media-blobs/v1"];
    const legacy = docs["study/media-blobs/v1"];
    const value = isObj(local) ? local : (isObj(legacy) ? legacy : {});
    return arr(value.blobs);
  }

  function progress(payload) {
    const docs = findDocs(payload);
    const p = docs["study/progress/v1"];
    return isObj(p) ? p : {};
  }

  function companionDoc(payload) {
    const docs = findDocs(payload);
    const c = docs["companion/preferences/v1"];
    return isObj(c) ? c : {};
  }

  function profileDoc(payload) {
    const docs = findDocs(payload);
    const p = docs["profile/preferences/v1"];
    return isObj(p) ? p : {};
  }

  function ankiPolicy(payload) {
    const docs = findDocs(payload);
    const p = docs["anki/read-only-policy/v1"];
    return isObj(p) ? p : {};
  }

  function shortText(value, maxLen) {
    const text = String(value == null ? "" : value).replace(/\s+/g, " ").trim();
    const n = maxLen || 80;
    return text.length > n ? text.slice(0, n - 1) + "…" : text;
  }

  function cardTitle(card, index) {
    return shortText(card.front || card.question || card.prompt || card.title || card.name || ("Card " + (index + 1)), 90);
  }

  function imageFlag(card) {
    const front = Boolean(card && (card.frontImage || card.questionImage));
    const back = Boolean(card && (card.backImage || card.answerImage));
    if (front && back) return "front+back images";
    if (front) return "front image";
    if (back) return "back image";
    return "no images";
  }

  function deckName(deck, index) {
    return shortText(deck.name || deck.title || deck.deckName || ("Deck " + (index + 1)), 80);
  }

  function mediaName(item, index) {
    return shortText(item.originalName || item.name || item.altText || item.sha256 || ("Media " + (index + 1)), 80);
  }

  function bytes(n) {
    const value = Number(n || 0);
    if (value > 1024 * 1024) return (value / (1024 * 1024)).toFixed(1) + " MB";
    if (value > 1024) return Math.round(value / 1024) + " KB";
    return value + " bytes";
  }

  function summarizePayload(payload) {
    const decks = deckList(payload);
    const cards = cardList(payload);
    const sessions = sessionList(payload);
    const media = mediaManifest(payload);
    const blobs = mediaBlobs(payload);
    const prog = progress(payload);
    const companion = companionDoc(payload);
    const profile = profileDoc(payload);
    const policy = ankiPolicy(payload);
    const settings = isObj(companion.settings) ? companion.settings : {};
    const profileSettings = isObj(profile.settings) ? profile.settings : {};
    const coverage = isObj(payload && payload.coverage) ? payload.coverage : {};
    const cardImageCount = cards.reduce((sum, card) => sum + (card.frontImage || card.questionImage ? 1 : 0) + (card.backImage || card.answerImage ? 1 : 0), 0);
    const companionMediaRefs = [settings.listeningMediaRef, settings.talkingMediaRef, settings.thinkingMediaRef].filter(Boolean).length;

    return {
      createdAt: payload && payload.createdAt || nowIso(),
      version: payload && payload.version,
      docs: Object.keys(findDocs(payload)).sort(),
      decks,
      cards,
      sessions,
      media,
      blobs,
      progress: prog,
      companion: settings,
      profile: profileSettings,
      policy,
      coverage,
      cardImageCount,
      companionMediaRefs
    };
  }

  function renderSummaryHtml(payload, label) {
    const s = summarizePayload(payload);
    const totals = isObj(s.progress.totals) ? s.progress.totals : {};
    const deckRows = s.decks.slice(0, 20).map((deck, i) => `<li>${escapeHtml(deckName(deck, i))}</li>`).join("");
    const cardRows = s.cards.slice(0, 30).map((card, i) => `<li><strong>${escapeHtml(cardTitle(card, i))}</strong> <span class="study-muted">(${escapeHtml(imageFlag(card))})</span></li>`).join("");
    const mediaRows = s.media.items.slice(0, 25).map((item, i) => `<li>${escapeHtml(mediaName(item, i))} <span class="study-muted">${escapeHtml(bytes(item.sizeBytes || item.size || 0))}</span></li>`).join("");
    const docRows = s.docs.map((key) => `<code>${escapeHtml(key)}</code>`).join(" ");
    const companionName = s.companion.companionName || s.companion.name || "Sol";
    const displayName = s.profile.displayName || s.companion.displayName || "";

    return `
      <div class="apc-complete-backup-summary-card">
        <h4>${escapeHtml(label || "Complete local backup preview")}</h4>
        <p class="study-muted">Version ${escapeHtml(s.version || "?")} · ${escapeHtml(s.createdAt)}</p>
        <div class="apc-complete-backup-grid" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(145px,1fr));gap:8px;margin:.75rem 0;">
          <div><strong>${s.decks.length}</strong><br><span class="study-muted">decks</span></div>
          <div><strong>${s.cards.length}</strong><br><span class="study-muted">cards</span></div>
          <div><strong>${s.sessions.length}</strong><br><span class="study-muted">sessions</span></div>
          <div><strong>${s.cardImageCount}</strong><br><span class="study-muted">card images</span></div>
          <div><strong>${s.companionMediaRefs}</strong><br><span class="study-muted">companion clips</span></div>
          <div><strong>${s.media.mediaCount || s.media.items.length}</strong><br><span class="study-muted">local media</span></div>
          <div><strong>${escapeHtml(bytes(s.media.totalBytes))}</strong><br><span class="study-muted">media bytes</span></div>
          <div><strong>${escapeHtml(totals.correct || 0)}/${escapeHtml(totals.wrong || 0)}</strong><br><span class="study-muted">right/wrong</span></div>
        </div>
        <p><strong>Companion:</strong> ${escapeHtml(companionName)}${displayName ? ` · Display name: ${escapeHtml(displayName)}` : ""}</p>
        <p><strong>Anki policy:</strong> ${s.policy.writesAnkiFiles === false ? "read-only Anki source; Buddies progress saved locally only" : "not declared"}</p>
        <details open><summary>Decks</summary><ul>${deckRows || "<li>No decks found in this payload.</li>"}</ul></details>
        <details><summary>Cards and image coverage</summary><ul>${cardRows || "<li>No cards found in this payload.</li>"}</ul></details>
        <details><summary>Local media and companion clips</summary><ul>${mediaRows || "<li>No media items found in this payload.</li>"}</ul><p class="study-muted">Media blob records in backup: ${escapeHtml(s.blobs.length)}</p></details>
        <details><summary>Backup document keys</summary><p style="line-height:1.8">${docRows || "No docs."}</p></details>
      </div>
    `;
  }

  async function buildCompletePayload() {
    const api = panelApi();
    if (!api || typeof api.buildBackupPayload !== "function") {
      throw new Error("Backup builder is not loaded yet.");
    }
    return await api.buildBackupPayload({ requestedBy: MARKER, createdAt: nowIso() });
  }

  function downloadPayload(payload, fileName) {
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = doc().createElement("a");
    link.href = url;
    link.download = fileName || CURRENT_FILE_NAME;
    link.rel = "noopener";
    doc().body.appendChild(link);
    link.click();
    link.remove();
    root.setTimeout(() => URL.revokeObjectURL(url), 5000);
  }

  function setStatus(text) {
    const node = doc() && doc().querySelector("[data-apc-complete-local-backup-status]");
    if (node) node.textContent = text || "";
  }

  function setOutput(html) {
    const node = doc() && doc().querySelector("[data-apc-complete-local-backup-output]");
    if (!node) return;
    node.innerHTML = html || "";
    node.hidden = !html;
  }

  function renderManagerHtml() {
    return `
      <section class="private-card apc-complete-local-backup-manager" data-apc-complete-local-backup-manager="true" style="border:1px solid rgba(76,175,80,.35);border-radius:16px;padding:14px;margin:0 0 14px;background:rgba(76,175,80,.06);">
        <h3 style="margin:.1rem 0 .35rem;">Complete local backup</h3>
        <p class="study-muted">Use this for the current local-first app. It includes decks, cards, stats, sessions, card images, companion settings, custom companion clips, and the Anki read-only policy.</p>
        <div class="private-actions" style="display:flex;flex-wrap:wrap;gap:8px;margin:.75rem 0;">
          <button type="button" class="private-button" data-apc-complete-backup-preview-current>Preview current browser data</button>
          <button type="button" class="private-button" data-apc-complete-backup-download-current>Download ${escapeHtml(CURRENT_FILE_NAME)}</button>
          <button type="button" class="private-button secondary" data-apc-complete-backup-open-file>Open backup file details</button>
        </div>
        <input type="file" accept="application/json,.json" data-apc-complete-backup-file-input hidden />
        <p class="study-muted" data-apc-complete-local-backup-status>Ready. No server upload. No Anki writes.</p>
        <div data-apc-complete-local-backup-output hidden></div>
        <p class="study-muted">The older preview-only backup diagnostics are hidden below to keep Profile readable.</p>
      </section>
    `;
  }

  function backupPanel() {
    return doc() ? doc().querySelector(PANEL_SELECTOR) : null;
  }

  function hideLegacyNoise() {
    const panel = backupPanel();
    if (!panel) return;
    [
      "[data-apc-local-backup-save-writer-plan-preview-r13v='true']",
      "[data-apc-local-backup-save-action-status-preview-r14i-r2='true']",
      "[data-apc-local-backup-disabled-save-button-html-preview-r14u='true']",
      "[data-apc-local-backup-current-file-output]"
    ].forEach((selector) => {
      panel.querySelectorAll(selector).forEach((node) => {
        node.hidden = true;
        node.style.display = "none";
      });
    });
    const oldCurrent = panel.querySelector("[data-apc-local-backup-open-current]");
    if (oldCurrent) oldCurrent.textContent = "Open backup file details";
  }

  function mount() {
    const panel = backupPanel();
    if (!panel) return false;
    if (!panel.querySelector(MANAGER_SELECTOR)) {
      panel.insertAdjacentHTML("afterbegin", renderManagerHtml());
    }
    hideLegacyNoise();
    return true;
  }

  function scheduleMount() {
    mount();
    root.setTimeout(mount, 0);
    root.setTimeout(mount, 150);
    root.setTimeout(mount, 500);
    root.setTimeout(hideLegacyNoise, 900);
  }

  async function previewCurrent() {
    setStatus("Building complete local backup preview…");
    const payload = await buildCompletePayload();
    setOutput(renderSummaryHtml(payload, "Current browser data"));
    setStatus("Preview complete. Nothing was uploaded or restored.");
    return payload;
  }

  async function downloadCurrent() {
    setStatus("Building complete local backup file…");
    const payload = await buildCompletePayload();
    downloadPayload(payload, CURRENT_FILE_NAME);
    setOutput(renderSummaryHtml(payload, "Downloaded backup contents"));
    setStatus("Download started as " + CURRENT_FILE_NAME + ". Nothing was uploaded or restored.");
    return payload;
  }

  function openFilePicker() {
    const input = doc() && doc().querySelector("[data-apc-complete-backup-file-input]");
    if (!input) return;
    input.value = "";
    input.click();
  }

  async function previewFile(file) {
    if (!file) return null;
    setStatus("Reading backup file details…");
    const text = await file.text();
    const payload = JSON.parse(text);
    setOutput(renderSummaryHtml(payload, "Opened backup file: " + file.name));
    setStatus("Backup file details shown. No data was restored or merged.");
    return payload;
  }

  function bindClicks() {
    if (!doc() || root.APC_PROFILE_COMPLETE_LOCAL_BACKUP_MANAGER_CLICK_BOUND_R16BY) return;
    root.APC_PROFILE_COMPLETE_LOCAL_BACKUP_MANAGER_CLICK_BOUND_R16BY = true;

    doc().addEventListener("click", function onClick(event) {
      const target = event.target && event.target.closest ? event.target.closest("[data-apc-complete-backup-preview-current],[data-apc-complete-backup-download-current],[data-apc-complete-backup-open-file]") : null;
      if (!target) return;
      event.preventDefault();
      if (target.matches("[data-apc-complete-backup-preview-current]")) {
        previewCurrent().catch((error) => setStatus("Preview failed: " + String(error && error.message ? error.message : error)));
      } else if (target.matches("[data-apc-complete-backup-download-current]")) {
        downloadCurrent().catch((error) => setStatus("Download failed: " + String(error && error.message ? error.message : error)));
      } else if (target.matches("[data-apc-complete-backup-open-file]")) {
        openFilePicker();
      }
    });

    doc().addEventListener("click", function interceptLegacyOpenCurrent(event) {
      const target = event.target && event.target.closest ? event.target.closest("[data-apc-local-backup-open-current]") : null;
      if (!target) return;
      event.preventDefault();
      event.stopPropagation();
      if (typeof event.stopImmediatePropagation === "function") event.stopImmediatePropagation();
      mount();
      openFilePicker();
    }, true);

    doc().addEventListener("change", function onFileChange(event) {
      const input = event.target && event.target.closest ? event.target.closest("[data-apc-complete-backup-file-input]") : null;
      if (!input) return;
      const file = input.files && input.files[0] ? input.files[0] : null;
      previewFile(file).catch((error) => setStatus("Could not open backup file: " + String(error && error.message ? error.message : error)));
    });
  }

  bindClicks();
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

  root.APC_PROFILE_COMPLETE_LOCAL_BACKUP_MANAGER_R16BY = Object.freeze({
    marker: MARKER,
    mount,
    scheduleMount,
    previewCurrent,
    downloadCurrent,
    previewFile,
    summarizePayload,
    currentFileName: CURRENT_FILE_NAME
  });
})(typeof window !== "undefined" ? window : globalThis);
