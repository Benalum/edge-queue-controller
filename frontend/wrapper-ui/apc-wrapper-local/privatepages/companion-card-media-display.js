(function apcCompanionCardMediaDisplayR16BX(root) {
  "use strict";

  const MARKER = "APC_COMPANION_CARD_MEDIA_DISPLAY_R16BX";
  if (root.APC_COMPANION_CARD_MEDIA_DISPLAY_R16BX) return;
  const objectUrls = new Map();

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }
  function store() { return root.APC_STUDY_STORE; }
  function activeCardAndSide() {
    const s = store();
    if (!s || typeof s.load !== "function" || typeof s.currentCard !== "function") return { card: null, side: "front" };
    const state = s.load();
    const card = s.currentCard(state);
    const rt = state.runtime || null;
    const side = rt && rt.pendingSelfAssessment && rt.pendingSelfAssessment.cardId === (card && card.id) ? "back" : "front";
    return { card, side };
  }
  async function mediaUrl(ref) {
    if (!ref) return "";
    if (ref.dataUrl) return ref.dataUrl;
    if (ref.url) return ref.url;
    if (!ref.sha256 || !root.APC_LOCAL_SAVE || typeof root.APC_LOCAL_SAVE.getMediaBlob !== "function") return "";
    if (objectUrls.has(ref.sha256)) return objectUrls.get(ref.sha256);
    const blob = await root.APC_LOCAL_SAVE.getMediaBlob(ref.sha256);
    if (!blob) return "";
    const url = URL.createObjectURL(blob);
    objectUrls.set(ref.sha256, url);
    return url;
  }
  function ensureMount() {
    const title = document.querySelector("#companionPrivateApp .sol-title");
    if (!title) return null;
    const parent = title.parentElement || title;
    if (parent && !parent.dataset.apcCompanionCardMediaFlex) {
      parent.dataset.apcCompanionCardMediaFlex = "true";
      parent.style.display = parent.style.display || "flex";
      parent.style.alignItems = parent.style.alignItems || "center";
      parent.style.gap = parent.style.gap || "12px";
      parent.style.flexWrap = parent.style.flexWrap || "wrap";
    }
    let mount = document.getElementById("apcCompanionCurrentCardImage");
    if (!mount) {
      mount = document.createElement("div");
      mount.id = "apcCompanionCurrentCardImage";
      mount.setAttribute("aria-live", "polite");
      title.insertAdjacentElement("afterend", mount);
    }
    return mount;
  }
  async function update() {
    const mount = ensureMount();
    if (!mount) return;
    const { card, side } = activeCardAndSide();
    const ref = card ? (side === "back" ? card.backImage : card.frontImage) : null;
    if (!card || !ref) {
      mount.innerHTML = "";
      mount.hidden = true;
      return;
    }
    const url = await mediaUrl(ref);
    if (!url) {
      mount.innerHTML = `<span class="study-muted">${escapeHtml(side)} image saved</span>`;
      mount.hidden = false;
      return;
    }
    mount.hidden = false;
    mount.innerHTML = `<img src="${escapeHtml(url)}" alt="${escapeHtml(side)} side card image" title="${escapeHtml(side)} side card image" style="width:96px;height:72px;object-fit:contain;border-radius:12px;border:1px solid rgba(120,120,120,.3);background:rgba(255,255,255,.06);" />`;
  }
  function scheduleUpdate() {
    setTimeout(() => update().catch(console.warn), 0);
    setTimeout(() => update().catch(console.warn), 150);
    setTimeout(() => update().catch(console.warn), 500);
  }
  ["apc-private-page-rendered", "apc-study-card-media-changed", "apc-study-local-save-updated", "apc-companion-settings-changed"].forEach((name) => {
    document.addEventListener(name, function (event) {
      if (name === "apc-private-page-rendered" && (!event.detail || event.detail.page !== "companion")) return;
      scheduleUpdate();
    });
  });
  root.setInterval(scheduleUpdate, 1500);
  root.APC_COMPANION_CARD_MEDIA_DISPLAY_R16BX = Object.freeze({ marker: MARKER, update, scheduleUpdate });
})(typeof window !== "undefined" ? window : globalThis);
