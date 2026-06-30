/* Reusable APC header loader.
   Updates active nav tabs during SPA navigation without requiring hard reload.
*/

(function () {
  "use strict";

  const mount = document.getElementById("apcHeaderMount");
  const cacheBust = Date.now();

  function loadTextSync(url) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url, false);
    xhr.setRequestHeader("Cache-Control", "no-cache");
    xhr.send(null);

    if (xhr.status < 200 || xhr.status >= 300) {
      throw new Error("Failed to load " + url + " HTTP " + xhr.status);
    }

    return xhr.responseText;
  }

  function normalizePath(path) {
    if (!path) return "/";

    try {
      const url = new URL(path, window.location.origin);
      path = url.pathname || "/";
    } catch (_) {}

    return path.replace(/\/+$/, "") || "/";
  }

  function setActiveRoute(route) {
    const activeRoute = normalizePath(route);

    document.querySelectorAll(".nav a[data-route]").forEach((el) => {
      const tabRoute = normalizePath(el.getAttribute("data-route") || el.getAttribute("href") || "");

      const active =
        tabRoute === "/"
          ? activeRoute === "/"
          : activeRoute === tabRoute || activeRoute.startsWith(tabRoute + "/");

      el.classList.toggle("active", active);

      if (active) {
        el.setAttribute("aria-current", "page");
      } else {
        el.removeAttribute("aria-current");
      }
    });
  }

  function markActiveNav() {
    setActiveRoute(window.location.pathname);
  }

  function scheduleActiveUpdate(route) {
    if (route) {
      setActiveRoute(route);
    }

    setTimeout(() => {
      if (route) setActiveRoute(route);
      else markActiveNav();
    }, 0);

    setTimeout(markActiveNav, 50);
    setTimeout(markActiveNav, 150);
    setTimeout(markActiveNav, 300);
  }

  function wireHeaderNavigation() {
    document.addEventListener(
      "click",
      (event) => {
        const link = event.target.closest(".nav a[data-route]");
        if (!link) return;

        const route = link.getAttribute("data-route") || link.getAttribute("href") || "/";
        scheduleActiveUpdate(route);
      },
      true
    );

    window.addEventListener("popstate", () => scheduleActiveUpdate());
    window.addEventListener("hashchange", () => scheduleActiveUpdate());

    const originalPushState = history.pushState;
    const originalReplaceState = history.replaceState;

    history.pushState = function () {
      const result = originalPushState.apply(this, arguments);
      scheduleActiveUpdate();
      return result;
    };

    history.replaceState = function () {
      const result = originalReplaceState.apply(this, arguments);
      scheduleActiveUpdate();
      return result;
    };
  }

  function loadNavMetadata() {
    fetch("/header/header.nav?v=" + cacheBust, { cache: "no-store" })
      .then((res) => (res.ok ? res.json() : null))
      .then((nav) => {
        if (!nav) return;
        document.dispatchEvent(new CustomEvent("apc-header-nav-loaded", { detail: nav }));
      })
      .catch(() => {});
  }

  try {
    if (!mount) return;

    const html = loadTextSync("/header/header.html?v=" + cacheBust);
    mount.outerHTML = html;

    wireHeaderNavigation();
    markActiveNav();
    loadNavMetadata();

    document.dispatchEvent(new CustomEvent("apc-header-ready"));

    setTimeout(markActiveNav, 100);
    setTimeout(markActiveNav, 500);
  } catch (err) {
    console.error("[APC header] failed to load reusable header:", err);

    if (mount) {
      mount.innerHTML =
        '<div style="padding:12px;border:1px solid #b91c1c;color:#fecaca;background:#450a0a">' +
        "Header failed to load. Check /header/header.html." +
        "</div>";
    }
  }
})();

/* APC_HEADER_BLANK_CLICK_GUARD_R9T: blank header/brand clicks are inert; real buttons/nav still work. */
(function apcHeaderBlankClickGuardR9T() {
  const MARKER = "APC_HEADER_BLANK_CLICK_GUARD_R9T";

  function isInteractive(target) {
    if (!target || !target.closest) return null;
    return target.closest("button,a[href],input,select,textarea,[role='button'],[data-route],[data-page],[data-tab]");
  }

  function installOne(header) {
    if (!header || header.dataset.apcHeaderBlankClickGuardR9t === "true") return;
    header.dataset.apcHeaderBlankClickGuardR9t = "true";

    header.addEventListener("click", function guardHeaderBlankClick(event) {
      const target = event.target;
      if (!target || !target.closest) return;

      const brand = target.closest("[data-apc-header-brand-static], .brand");
      const interactive = isInteractive(target);

      if (interactive && !brand) return;

      if (brand || !interactive) {
        event.preventDefault();
        event.stopPropagation();
      }
    }, true);

    header.setAttribute("data-apc-header-blank-click-guard", MARKER);
  }

  function install() {
    const mount = document.getElementById("apcHeaderMount");
    const candidates = [];
    if (mount) {
      candidates.push(mount);
      const nestedHeader = mount.querySelector("header");
      if (nestedHeader) candidates.push(nestedHeader);
    }
    document.querySelectorAll("header,.site-header,.apc-header,[data-apc-header-root]").forEach((el) => candidates.push(el));
    candidates.forEach(installOne);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", install, { once: true });
  } else {
    install();
  }

  let attempts = 0;
  const timer = setInterval(function retryInstall() {
    attempts += 1;
    install();
    if (attempts >= 20) clearInterval(timer);
  }, 150);
})();
