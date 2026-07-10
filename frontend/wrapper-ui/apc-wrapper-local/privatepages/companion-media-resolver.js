(function apcCompanionMediaResolverR16BX(root) {
  "use strict";

  const MARKER = "APC_COMPANION_MEDIA_RESOLVER_R16BX";
  if (root.APC_COMPANION_MEDIA_RESOLVER_R16BX) return;
  const objectUrls = new Map();

  function currentUserEmail() {
    try {
      const user = root.APC_PRIVATEPAGES && root.APC_PRIVATEPAGES.me ? root.APC_PRIVATEPAGES.me() : null;
      if (user && user.email) return user.email;
    } catch (_) {}
    return "browser-local@buddies.local";
  }
  function settingsKey() { return "apcPrivateCompanionVoiceSettings:" + currentUserEmail(); }
  function loadSettings() {
    try {
      const parsed = JSON.parse(localStorage.getItem(settingsKey()) || "{}");
      return parsed && typeof parsed === "object" ? parsed : {};
    } catch (_) { return {}; }
  }
  function stateFromSrc(src) {
    const text = String(src || "").toLowerCase();
    if (text.includes("talking")) return "talking";
    if (text.includes("thinking")) return "thinking";
    return "listening";
  }
  async function urlForRef(ref) {
    if (!ref) return "";
    if (ref.url) return ref.url;
    if (ref.dataUrl) return ref.dataUrl;
    if (!ref.sha256 || !root.APC_LOCAL_SAVE || typeof root.APC_LOCAL_SAVE.getMediaBlob !== "function") return "";
    if (objectUrls.has(ref.sha256)) return objectUrls.get(ref.sha256);
    const blob = await root.APC_LOCAL_SAVE.getMediaBlob(ref.sha256);
    if (!blob) return "";
    const url = URL.createObjectURL(blob);
    objectUrls.set(ref.sha256, url);
    return url;
  }
  async function resolve() {
    const video = document.getElementById("solStateVideo");
    if (!video) return;
    const settings = loadSettings();
    const state = stateFromSrc(video.getAttribute("src") || video.currentSrc || "");
    const ref = settings[state + "MediaRef"] || null;
    if (!ref) return;
    const url = await urlForRef(ref);
    if (!url) return;
    if (video.getAttribute("src") !== url) {
      video.setAttribute("src", url);
      video.dataset.apcCompanionMediaResolved = state;
      video.load();
      video.play().catch(function () {});
    }
  }
  function scheduleResolve() {
    setTimeout(() => resolve().catch(console.warn), 0);
    setTimeout(() => resolve().catch(console.warn), 150);
    setTimeout(() => resolve().catch(console.warn), 500);
  }
  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "companion") scheduleResolve();
  });
  document.addEventListener("apc-companion-settings-changed", scheduleResolve);
  const observer = new MutationObserver(scheduleResolve);
  if (document.documentElement) observer.observe(document.documentElement, { childList: true, subtree: true });
  root.APC_COMPANION_MEDIA_RESOLVER_R16BX = Object.freeze({ marker: MARKER, resolve, scheduleResolve });
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", scheduleResolve, { once: true });
  else scheduleResolve();
})(typeof window !== "undefined" ? window : globalThis);
