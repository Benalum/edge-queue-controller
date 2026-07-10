(function () {
  "use strict";

  if (window.__APC_COMPANION_PRESETS_R16BV__) return;
  window.__APC_COMPANION_PRESETS_R16BV__ = true;

  const MARKER = "APC_COMPANION_PRESETS_R16BW_PROFILE_ONLY_SOL_SOURCE_ONLY";

  const PRESETS = [
    {
      id: "sol",
      label: "Sol",
      companionName: "Sol",
      description: "Default Buddies Who Study companion.",
      listeningVideoUrl: "/privatepages/assets/sol-clips/dog_listening_236b385d.mp4",
      thinkingVideoUrl: "/privatepages/assets/sol-clips/dog_thinking_8dcd159e.mp4",
      talkingVideoUrl: "/privatepages/assets/sol-clips/dog_talking_f28d314b.mp4"
    }
  ];

  function byId(id) {
    return document.getElementById(id);
  }

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
      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me ? window.APC_PRIVATEPAGES.me() : null;
      if (user && user.email) return user.email;
    } catch (_) {}
    return "browser-local@buddies.local";
  }

  function companionKey() {
    return "apcPrivateCompanionVoiceSettings:" + currentUserEmail();
  }

  function loadJson(key) {
    try {
      const parsed = JSON.parse(localStorage.getItem(key) || "{}");
      return parsed && typeof parsed === "object" ? parsed : {};
    } catch (_) {
      return {};
    }
  }

  function saveJson(key, value) {
    localStorage.setItem(key, JSON.stringify(value || {}));
  }

  function presetById(id) {
    return PRESETS.find((preset) => preset.id === id) || PRESETS[0];
  }

  function selectedPresetId() {
    const settings = loadJson(companionKey());
    return settings.companionPresetId || "custom";
  }

  function applyPreset(id) {
    const preset = presetById(id);
    const settings = loadJson(companionKey());

    settings.companionPresetId = preset.id;
    settings.companionName = preset.companionName || preset.label || "Sol";
    settings.listeningVideoUrl = preset.listeningVideoUrl || "";
    settings.thinkingVideoUrl = preset.thinkingVideoUrl || "";
    settings.talkingVideoUrl = preset.talkingVideoUrl || "";

    saveJson(companionKey(), settings);

    document.dispatchEvent(new CustomEvent("apc-companion-settings-changed", {
      detail: Object.assign({}, settings, { preset })
    }));

    renderPresetControlsSoon();
    return settings;
  }

  function setCustomMode() {
    const settings = loadJson(companionKey());
    settings.companionPresetId = "custom";
    saveJson(companionKey(), settings);
    document.dispatchEvent(new CustomEvent("apc-companion-settings-changed", { detail: settings }));
    renderPresetControlsSoon();
    return settings;
  }

  function selectHtml(context) {
    const current = selectedPresetId();
    const options = [
      `<option value="custom"${current === "custom" ? " selected" : ""}>Custom / my own media</option>`,
      ...PRESETS.map((preset) => `<option value="${escapeHtml(preset.id)}"${current === preset.id ? " selected" : ""}>${escapeHtml(preset.label)}</option>`)
    ].join("");

    const currentPreset = current === "custom" ? null : presetById(current);
    const description = currentPreset
      ? `${currentPreset.description || "Built-in companion preset."}`
      : "Use the custom name and video URL fields below.";

    return `
      <section class="apc-companion-preset-card" data-apc-companion-preset-card="${escapeHtml(context)}" style="border:1px solid rgba(120,120,120,.28);border-radius:14px;padding:12px;margin:10px 0;background:rgba(255,255,255,.04);">
        <h3 style="margin:.1rem 0 .35rem;">Choose companion</h3>
        <label style="display:grid;gap:6px;font-weight:600;">
          Companion preset
          <select data-apc-companion-preset-select style="width:100%;max-width:420px;">
            ${options}
          </select>
        </label>
        <p class="study-muted" style="margin:.55rem 0 0;">${escapeHtml(description)}</p>
        <p class="study-muted" style="margin:.25rem 0 0;">Current built-in list: Sol.</p>
      </section>
    `;
  }

  function renderIntoProfile() {
    const mount = byId("profileLocalFirstSettings");
    if (!mount) return;

    const form = mount.querySelector("[data-profile-local-settings-form]");
    if (!form) return;

    const old = form.querySelector("[data-apc-companion-preset-card]");
    if (old) old.remove();

    form.insertAdjacentHTML("afterbegin", selectHtml("profile"));
  }

  function renderIntoCompanion() {
    // R16BW: Companion selection lives only in Profile.
    // Companion still reads and reflects the saved local settings.
    return;
  }

  function wireVideoFallback() {
    const video = byId("solStateVideo");
    if (!video || video.dataset.apcPresetFallbackWired === "true") return;

    video.dataset.apcPresetFallbackWired = "true";
    video.addEventListener("error", function () {
      const settings = loadJson(companionKey());
      if ((settings.companionPresetId || "sol") !== "sol") return;

      video.hidden = true;
      let fallback = byId("apcSolVideoFallback");
      if (!fallback) {
        fallback = document.createElement("div");
        fallback.id = "apcSolVideoFallback";
        fallback.setAttribute("role", "img");
        fallback.setAttribute("aria-label", "Sol companion placeholder");
        fallback.style.cssText = "width:180px;height:135px;display:grid;place-items:center;border-radius:16px;border:1px solid rgba(120,120,120,.35);background:linear-gradient(135deg,rgba(117,106,246,.18),rgba(52,211,153,.18));font-weight:800;letter-spacing:.02em;";
        fallback.textContent = "Sol";
        video.insertAdjacentElement("afterend", fallback);
      }
    });
  }

  function renderPresetControls() {
    renderIntoProfile();
    wireVideoFallback();
  }

  function renderPresetControlsSoon() {
    window.setTimeout(renderPresetControls, 0);
    window.setTimeout(renderPresetControls, 150);
  }

  document.addEventListener("change", function (event) {
    const select = event.target && event.target.closest ? event.target.closest("[data-apc-companion-preset-select]") : null;
    if (!select) return;

    if (select.value === "custom") {
      setCustomMode();
      return;
    }

    applyPreset(select.value);
  });

  document.addEventListener("input", function (event) {
    const target = event.target;
    if (!target || !target.id) return;
    if (!["profileCompanionName", "profileCompanionListeningVideo", "profileCompanionTalkingVideo"].includes(target.id)) return;

    const settings = loadJson(companionKey());
    if (settings.companionPresetId && settings.companionPresetId !== "custom") {
      settings.companionPresetId = "custom";
      saveJson(companionKey(), settings);
      renderPresetControlsSoon();
    }
  });

  document.addEventListener("apc-private-page-rendered", renderPresetControlsSoon);
  document.addEventListener("apc-companion-settings-changed", renderPresetControlsSoon);

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", renderPresetControlsSoon);
  } else {
    renderPresetControlsSoon();
  }

  window.APC_COMPANION_PRESETS_R16BV = {
    marker: MARKER,
    presets: PRESETS.slice(),
    applyPreset,
    selectedPresetId,
    render: renderPresetControls
  };
})();
