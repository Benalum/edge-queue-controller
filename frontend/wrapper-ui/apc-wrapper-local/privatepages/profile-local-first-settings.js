(function () {
  "use strict";

  if (window.__APC_PROFILE_LOCAL_FIRST_SETTINGS__) return;
  window.__APC_PROFILE_LOCAL_FIRST_SETTINGS__ = true;

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
      const user = window.APC_PRIVATEPAGES && window.APC_PRIVATEPAGES.me ? window.APC_PRIVATEPAGES.me() : null;
      if (user && user.email) return user.email;
    } catch (_) {}
    return "browser-local@buddies.local";
  }

  function profileKey() { return "apcLocalProfileSettings:" + currentUserEmail(); }
  function companionKey() { return "apcPrivateCompanionVoiceSettings:" + currentUserEmail(); }

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

  function render() {
    const mount = byId("profileLocalFirstSettings");
    if (!mount) return;

    const profile = loadJson(profileKey());
    const companion = loadJson(companionKey());

    mount.innerHTML = `
      <h2>Local settings</h2>
      <form class="auth-form" data-profile-local-settings-form>
        <label>
          Display name
          <input id="profileDisplayName" type="text" maxlength="80" value="${escapeHtml(profile.displayName || "")}" placeholder="Your name" />
        </label>
        <label>
          Companion name
          <input id="profileCompanionName" type="text" maxlength="80" value="${escapeHtml(companion.companionName || "Sol")}" placeholder="Sol" />
        </label>
        <label>
          Companion listening video URL
          <input id="profileCompanionListeningVideo" type="url" value="${escapeHtml(companion.listeningVideoUrl || "")}" placeholder="Leave blank for default listening video" />
        </label>
        <label>
          Companion talking video URL
          <input id="profileCompanionTalkingVideo" type="url" value="${escapeHtml(companion.talkingVideoUrl || "")}" placeholder="Leave blank for default talking video" />
        </label>
        <button class="private-button" type="submit">Save local settings</button>
        <button class="private-button secondary" type="button" data-profile-local-settings-reset>Reset companion media</button>
      </form>
      <p id="profileLocalSettingsStatus" class="study-muted" role="status">Saved in this browser only.</p>
    `;
  }

  function saveFromForm() {
    const profile = loadJson(profileKey());
    const companion = loadJson(companionKey());

    profile.displayName = byId("profileDisplayName")?.value.trim() || "";
    companion.companionName = byId("profileCompanionName")?.value.trim() || "Sol";
    companion.listeningVideoUrl = byId("profileCompanionListeningVideo")?.value.trim() || "";
    companion.talkingVideoUrl = byId("profileCompanionTalkingVideo")?.value.trim() || "";

    saveJson(profileKey(), profile);
    saveJson(companionKey(), companion);

    const status = byId("profileLocalSettingsStatus");
    if (status) status.textContent = "Saved locally.";

    document.dispatchEvent(new CustomEvent("apc-companion-settings-changed", { detail: companion }));
  }

  document.addEventListener("submit", function (event) {
    const form = event.target && event.target.closest ? event.target.closest("[data-profile-local-settings-form]") : null;
    if (!form) return;
    event.preventDefault();
    saveFromForm();
  });

  document.addEventListener("click", function (event) {
    const button = event.target && event.target.closest ? event.target.closest("[data-profile-local-settings-reset]") : null;
    if (!button) return;
    event.preventDefault();
    const companion = loadJson(companionKey());
    companion.listeningVideoUrl = "";
    companion.talkingVideoUrl = "";
    saveJson(companionKey(), companion);
    render();
    document.dispatchEvent(new CustomEvent("apc-companion-settings-changed", { detail: companion }));
  });

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "profile") render();
  });

  if (document.readyState !== "loading") render();
})();
