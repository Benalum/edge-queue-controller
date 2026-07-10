(function apcProfileCompanionCustomMediaR16BX(root) {
  "use strict";

  const MARKER = "APC_PROFILE_COMPANION_CUSTOM_MEDIA_R16BX";
  if (root.APC_PROFILE_COMPANION_CUSTOM_MEDIA_R16BX) return;

  function byId(id) { return document.getElementById(id); }
  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }
  function currentUserEmail() {
    try {
      const user = root.APC_PRIVATEPAGES && root.APC_PRIVATEPAGES.me ? root.APC_PRIVATEPAGES.me() : null;
      if (user && user.email) return user.email;
    } catch (_) {}
    return "browser-local@buddies.local";
  }
  function companionKey() { return "apcPrivateCompanionVoiceSettings:" + currentUserEmail(); }
  function loadSettings() {
    try {
      const parsed = JSON.parse(localStorage.getItem(companionKey()) || "{}");
      return parsed && typeof parsed === "object" ? parsed : {};
    } catch (_) { return {}; }
  }
  function saveSettings(settings) { localStorage.setItem(companionKey(), JSON.stringify(settings || {})); }

  function localSave() {
    return root.APC_LOCAL_SAVE && typeof root.APC_LOCAL_SAVE.putMedia === "function" ? root.APC_LOCAL_SAVE : null;
  }

  async function saveFileToMedia(file, slot) {
    const api = localSave();
    if (!api) throw new Error("Local media storage is not available yet.");
    const result = await api.putMedia(file, {
      mimeType: file.type || "video/mp4",
      originalName: file.name || slot + " companion clip",
      altText: slot + " companion clip",
      refHint: "companion/" + slot
    });
    return {
      sha256: result.sha256,
      mimeType: result.mimeType || file.type || "video/mp4",
      sizeBytes: result.sizeBytes || file.size || 0,
      originalName: file.name || "",
      altText: slot + " companion clip",
      kind: "companion-video",
      slot,
      createdAt: result.createdAt || new Date().toISOString()
    };
  }

  function mediaRefSummary(ref) {
    if (!ref || !ref.sha256) return "No custom file saved.";
    return `${ref.originalName || ref.sha256.slice(0, 12)} · ${Math.round(Number(ref.sizeBytes || 0) / 1024)} KB`;
  }

  function renderPanelHtml(settings) {
    const listening = settings.listeningMediaRef || null;
    const talking = settings.talkingMediaRef || null;
    const thinking = settings.thinkingMediaRef || null;
    return `
      <section class="apc-companion-custom-media" data-apc-companion-custom-media="true" style="border:1px solid rgba(120,120,120,.28);border-radius:14px;padding:12px;margin:12px 0;background:rgba(255,255,255,.04);">
        <h3 style="margin:.1rem 0 .35rem;">Custom companion media</h3>
        <p class="study-muted" style="margin:.25rem 0 .75rem;">Pick local video clips for your companion. Files stay in this browser's local storage and are included in local backups.</p>
        <div style="display:grid;gap:10px;">
          <label style="display:grid;gap:5px;font-weight:600;">Listening clip
            <input type="file" accept="video/*" data-apc-companion-media-file="listening" />
            <span class="study-muted">${escapeHtml(mediaRefSummary(listening))}</span>
          </label>
          <label style="display:grid;gap:5px;font-weight:600;">Talking clip
            <input type="file" accept="video/*" data-apc-companion-media-file="talking" />
            <span class="study-muted">${escapeHtml(mediaRefSummary(talking))}</span>
          </label>
          <label style="display:grid;gap:5px;font-weight:600;">Thinking clip
            <input type="file" accept="video/*" data-apc-companion-media-file="thinking" />
            <span class="study-muted">${escapeHtml(mediaRefSummary(thinking))}</span>
          </label>
        </div>
        <div class="private-actions" style="margin-top:10px;">
          <button type="button" class="private-button secondary" data-apc-companion-media-clear>Clear custom companion clips</button>
        </div>
        <p class="study-muted" data-apc-companion-media-status role="status">Companion preset stays in Profile. Choosing a file switches to custom media.</p>
      </section>
    `;
  }

  function setStatus(text) {
    const node = document.querySelector("[data-apc-companion-media-status]");
    if (node) node.textContent = text || "";
  }

  function render() {
    const mount = byId("profileLocalFirstSettings");
    if (!mount) return;
    const form = mount.querySelector("[data-profile-local-settings-form]");
    if (!form) return;
    const old = form.querySelector("[data-apc-companion-custom-media]");
    if (old) old.remove();
    form.insertAdjacentHTML("beforeend", renderPanelHtml(loadSettings()));
  }

  document.addEventListener("change", async function (event) {
    const input = event.target && event.target.closest ? event.target.closest("[data-apc-companion-media-file]") : null;
    if (!input) return;
    const file = input.files && input.files[0] ? input.files[0] : null;
    const slot = input.getAttribute("data-apc-companion-media-file");
    if (!file || !slot) return;
    try {
      setStatus("Saving " + slot + " clip locally...");
      const ref = await saveFileToMedia(file, slot);
      const settings = loadSettings();
      settings.companionPresetId = "custom";
      settings[slot + "MediaRef"] = ref;
      settings[slot + "VideoUrl"] = "";
      saveSettings(settings);
      if (root.APC_LOCAL_SAVE && typeof root.APC_LOCAL_SAVE.setDoc === "function") {
        await root.APC_LOCAL_SAVE.setDoc("companion/preferences/v1", {
          schemaVersion: 1,
          updatedAt: new Date().toISOString(),
          settings
        }, { namespace: "companion", recordType: "apc_companion_preferences" });
      }
      document.dispatchEvent(new CustomEvent("apc-companion-settings-changed", { detail: settings }));
      render();
      setStatus("Saved " + slot + " clip locally.");
    } catch (error) {
      setStatus("Could not save clip: " + String(error && error.message ? error.message : error));
    }
  });

  document.addEventListener("click", function (event) {
    const button = event.target && event.target.closest ? event.target.closest("[data-apc-companion-media-clear]") : null;
    if (!button) return;
    event.preventDefault();
    const settings = loadSettings();
    delete settings.listeningMediaRef;
    delete settings.talkingMediaRef;
    delete settings.thinkingMediaRef;
    saveSettings(settings);
    document.dispatchEvent(new CustomEvent("apc-companion-settings-changed", { detail: settings }));
    render();
  });

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "profile") {
      setTimeout(render, 0);
      setTimeout(render, 150);
    }
  });
  document.addEventListener("apc-companion-settings-changed", function () { setTimeout(render, 50); });

  root.APC_PROFILE_COMPANION_CUSTOM_MEDIA_R16BX = Object.freeze({ marker: MARKER, render });
})(typeof window !== "undefined" ? window : globalThis);
