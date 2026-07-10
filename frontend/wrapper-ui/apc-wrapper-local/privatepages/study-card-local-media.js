(function apcStudyCardLocalMediaR16BX(root) {
  "use strict";

  const MARKER = "APC_STUDY_CARD_LOCAL_MEDIA_R16BX_FRONT_BACK_IMAGES";
  if (root.APC_STUDY_CARD_LOCAL_MEDIA_R16BX) return;

  const objectUrls = new Map();

  function store() { return root.APC_STUDY_STORE; }
  function byId(id) { return document.getElementById(id); }
  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }
  function uid(prefix) {
    if (root.crypto && root.crypto.randomUUID) return prefix + "-" + root.crypto.randomUUID();
    return prefix + "-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8);
  }
  function nowIso() { return new Date().toISOString(); }
  function localSave() { return root.APC_LOCAL_SAVE && typeof root.APC_LOCAL_SAVE.putMedia === "function" ? root.APC_LOCAL_SAVE : null; }

  async function saveImageFile(file, side, cardId) {
    const api = localSave();
    if (!api) throw new Error("Local media storage is not available yet.");
    const result = await api.putMedia(file, {
      mimeType: file.type || "image/*",
      originalName: file.name || side + " card image",
      altText: side + " side card image",
      refHint: "study/card/" + (cardId || "new") + "/" + side
    });
    return {
      sha256: result.sha256,
      mimeType: result.mimeType || file.type || "image/*",
      sizeBytes: result.sizeBytes || file.size || 0,
      originalName: file.name || "",
      altText: side + " side card image",
      kind: "study-card-image",
      side,
      createdAt: result.createdAt || nowIso(),
      updatedAt: nowIso()
    };
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

  function imageInputHtml(side, label) {
    return `
      <label class="study-card-image-input" style="display:grid;gap:5px;font-weight:600;">
        ${escapeHtml(label)}
        <input type="file" accept="image/*" data-apc-study-new-card-image="${escapeHtml(side)}" />
        <span class="study-muted" data-apc-study-new-card-image-status="${escapeHtml(side)}">Optional</span>
      </label>
    `;
  }

  function ensureCreateInputs() {
    const form = document.querySelector('[data-study-form="create-card"]');
    if (!form || form.querySelector('[data-apc-study-card-image-create-controls="true"]')) return;
    const controls = document.createElement("div");
    controls.setAttribute("data-apc-study-card-image-create-controls", "true");
    controls.style.cssText = "display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;";
    controls.innerHTML = imageInputHtml("front", "Question/front image") + imageInputHtml("back", "Answer/back image");
    const difficulty = byId("studyCardDifficulty");
    if (difficulty && difficulty.parentNode === form) {
      form.insertBefore(controls, difficulty);
    } else {
      form.appendChild(controls);
    }
  }

  function cardRowMediaControls(card) {
    return `
      <div data-apc-study-card-image-controls="${escapeHtml(card.id)}" style="display:grid;gap:6px;margin-top:8px;">
        <div data-apc-study-card-image-preview="front" data-card-id="${escapeHtml(card.id)}"></div>
        <div data-apc-study-card-image-preview="back" data-card-id="${escapeHtml(card.id)}"></div>
        <label class="study-muted">Front image <input type="file" accept="image/*" data-apc-study-existing-card-image="front" data-card-id="${escapeHtml(card.id)}" /></label>
        <label class="study-muted">Back image <input type="file" accept="image/*" data-apc-study-existing-card-image="back" data-card-id="${escapeHtml(card.id)}" /></label>
        <div class="study-row-actions">
          <button type="button" class="study-button secondary" data-apc-study-remove-card-image="front" data-card-id="${escapeHtml(card.id)}">Remove front image</button>
          <button type="button" class="study-button secondary" data-apc-study-remove-card-image="back" data-card-id="${escapeHtml(card.id)}">Remove back image</button>
        </div>
      </div>
    `;
  }

  function ensureExistingControls() {
    const s = store();
    if (!s || typeof s.load !== "function") return;
    const state = s.load();
    (state.cards || []).forEach((card) => {
      const button = document.querySelector(`[data-study-action="edit-card"][data-card-id="${CSS.escape(card.id)}"]`);
      const row = button && button.closest ? button.closest(".study-row.card") : null;
      if (!row || row.querySelector(`[data-apc-study-card-image-controls="${CSS.escape(card.id)}"]`)) return;
      const textBlock = row.firstElementChild || row;
      textBlock.insertAdjacentHTML("beforeend", cardRowMediaControls(card));
    });
  }

  async function renderImagePreviews() {
    const s = store();
    if (!s || typeof s.load !== "function") return;
    const state = s.load();
    const cardsById = new Map((state.cards || []).map((card) => [String(card.id), card]));
    const previews = Array.from(document.querySelectorAll("[data-apc-study-card-image-preview]"));
    for (const node of previews) {
      const card = cardsById.get(String(node.getAttribute("data-card-id") || ""));
      const side = node.getAttribute("data-apc-study-card-image-preview");
      const ref = card ? (side === "back" ? card.backImage : card.frontImage) : null;
      if (!ref) {
        node.innerHTML = `<span class="study-muted">No ${escapeHtml(side)} image.</span>`;
        continue;
      }
      const url = await mediaUrl(ref);
      if (!url) {
        node.innerHTML = `<span class="study-muted">${escapeHtml(side)} image saved locally.</span>`;
        continue;
      }
      node.innerHTML = `<img src="${escapeHtml(url)}" alt="${escapeHtml(side)} card image" style="max-width:180px;max-height:120px;object-fit:contain;border-radius:10px;border:1px solid rgba(120,120,120,.25);" />`;
    }
  }

  function enhance() {
    ensureCreateInputs();
    ensureExistingControls();
    renderImagePreviews().catch((error) => console.warn("[study-card-media] preview failed", error));
  }

  async function handleCreateWithImages(form, event) {
    const frontFile = form.querySelector('[data-apc-study-new-card-image="front"]')?.files?.[0] || null;
    const backFile = form.querySelector('[data-apc-study-new-card-image="back"]')?.files?.[0] || null;
    if (!frontFile && !backFile) return false;

    event.preventDefault();
    event.stopImmediatePropagation();

    const s = store();
    if (!s || typeof s.load !== "function" || typeof s.save !== "function") return true;
    const state = s.load();
    const targetDeckId = state.activeDeckId || (state.decks[0] && state.decks[0].id) || "";
    if (!targetDeckId) return true;

    const cardId = uid("card");
    const media = {};
    if (frontFile) media.frontImage = await saveImageFile(frontFile, "front", cardId);
    if (backFile) media.backImage = await saveImageFile(backFile, "back", cardId);

    state.cards.unshift({
      id: cardId,
      deckId: targetDeckId,
      front: byId("studyCardFront")?.value.trim() || "",
      back: byId("studyCardBack")?.value.trim() || "",
      difficulty: byId("studyCardDifficulty")?.value || "new",
      flagged: false,
      seenCount: 0,
      correctCount: 0,
      wrongCount: 0,
      skipCount: 0,
      lastResult: "",
      lastSeenAt: "",
      createdAt: nowIso(),
      updatedAt: nowIso(),
      frontImage: media.frontImage || null,
      backImage: media.backImage || null
    });
    state.activeDeckId = targetDeckId;
    s.save(state);
    form.reset();
    if (root.APC_PRIVATE_STUDY && typeof root.APC_PRIVATE_STUDY.render === "function") root.APC_PRIVATE_STUDY.render();
    document.dispatchEvent(new CustomEvent("apc-study-card-media-changed", { detail: { cardId } }));
    setTimeout(enhance, 0);
    return true;
  }

  document.addEventListener("submit", function (event) {
    const form = event.target && event.target.closest ? event.target.closest('[data-study-form="create-card"]') : null;
    if (!form) return;
    handleCreateWithImages(form, event).catch((error) => {
      console.warn("[study-card-media] create with images failed", error);
      alert("Could not save card image: " + String(error && error.message ? error.message : error));
    });
  }, true);

  document.addEventListener("change", async function (event) {
    const input = event.target && event.target.closest ? event.target.closest("[data-apc-study-existing-card-image]") : null;
    if (!input) return;
    const file = input.files && input.files[0] ? input.files[0] : null;
    if (!file) return;
    const side = input.getAttribute("data-apc-study-existing-card-image") || "front";
    const cardId = input.getAttribute("data-card-id") || "";
    const ref = await saveImageFile(file, side, cardId);
    const patch = side === "back" ? { backImage: ref } : { frontImage: ref };
    store().editCard(cardId, patch);
    if (root.APC_PRIVATE_STUDY && typeof root.APC_PRIVATE_STUDY.render === "function") root.APC_PRIVATE_STUDY.render();
    setTimeout(enhance, 0);
    document.dispatchEvent(new CustomEvent("apc-study-card-media-changed", { detail: { cardId, side } }));
  });

  document.addEventListener("click", function (event) {
    const button = event.target && event.target.closest ? event.target.closest("[data-apc-study-remove-card-image]") : null;
    if (!button) return;
    event.preventDefault();
    const side = button.getAttribute("data-apc-study-remove-card-image") || "front";
    const cardId = button.getAttribute("data-card-id") || "";
    store().editCard(cardId, side === "back" ? { backImage: null } : { frontImage: null });
    if (root.APC_PRIVATE_STUDY && typeof root.APC_PRIVATE_STUDY.render === "function") root.APC_PRIVATE_STUDY.render();
    setTimeout(enhance, 0);
    document.dispatchEvent(new CustomEvent("apc-study-card-media-changed", { detail: { cardId, side, removed: true } }));
  });

  ["apc-private-page-rendered", "apc-study-card-media-changed", "apc-study-local-save-updated"].forEach((eventName) => {
    document.addEventListener(eventName, function (event) {
      if (eventName === "apc-private-page-rendered" && (!event.detail || event.detail.page !== "study")) return;
      setTimeout(enhance, 0);
      setTimeout(enhance, 150);
    });
  });

  root.APC_STUDY_CARD_LOCAL_MEDIA_R16BX = Object.freeze({ marker: MARKER, enhance, mediaUrl });
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", enhance, { once: true });
  else enhance();
})(typeof window !== "undefined" ? window : globalThis);
