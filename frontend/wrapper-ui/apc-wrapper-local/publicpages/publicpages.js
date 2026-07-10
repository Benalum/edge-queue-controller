(function () {
  "use strict";

  const PUBLIC_PAGES = {
    "/": {
      title: "Buddies Who Study",
      file: "/publicpages/pages/home.html",
      publicEvenWhenLoggedIn: true
    }
  };

  const LOCAL_FIRST_APP_ROUTES = new Set(["/study", "/companion", "/profile"]);
  const AUTH_REQUIRED_ROUTES = new Set(["/support", "/admin"]);

  let renderTimer = null;
  let renderInFlight = false;
  let lastRenderedRoute = "";

  function normalizePath(path) {
    if (!path) return "/";

    try {
      const url = new URL(path, window.location.origin);
      path = url.pathname || "/";
    } catch (_) {}

    path = path.split("?")[0].split("#")[0] || "/";
    if (path.length > 1) path = path.replace(/\/+$/, "");
    return path || "/";
  }

  function isPublicPage(path) {
    return Object.prototype.hasOwnProperty.call(PUBLIC_PAGES, normalizePath(path));
  }

  function hasLoginToken() {
    try {
      if (window.authState && window.authState.token) return true;
    } catch (_) {}

    try {
      const token = window.localStorage.getItem("edgeStudyToken");
      if (token && String(token).trim()) return true;
    } catch (_) {}

    return false;
  }

  function shouldPublicPagesOwnRoute(path) {
    const route = normalizePath(path || window.location.pathname);
    const page = PUBLIC_PAGES[route];

    if (!page) return false;
    if (page.publicEvenWhenLoggedIn) return true;

    return !hasLoginToken(); // Signed-in users are owned by privatepages for private-capable routes
  }

  function setPending(isPending) {
    if (!document.body) return;
    document.body.classList.toggle("publicpages-pending", Boolean(isPending));
  }

  async function renderPublicPage(path) {
    const route = normalizePath(path || window.location.pathname);
    const page = PUBLIC_PAGES[route];
    const app = document.getElementById("app");

    if (!app) return false;

    if (!page || !shouldPublicPagesOwnRoute(route)) {
      setPending(false);
      return false;
    }

    if (renderInFlight) return false;

    renderInFlight = true;
    setPending(true);

    try {
      const response = await fetch(page.file + "?v=" + Date.now(), {
        cache: "no-store"
      });

      if (!response.ok) {
        throw new Error("Failed to load " + page.file + " HTTP " + response.status);
      }

      app.innerHTML = await response.text();
      document.title = page.title || "Buddies Who Study";
      lastRenderedRoute = route;

      if (typeof window.stage5o13SyncHeaderNavActiveState === "function") {
        window.stage5o13SyncHeaderNavActiveState();
      }

      setPending(false);
      return true;
    } catch (error) {
      console.error("[publicpages] render failed", error);
      app.innerHTML = `
        <section class="public-hero">
          <p class="eyebrow">Page error</p>
          <h1>Public page failed to load</h1>
          <p class="subtitle">Missing or broken file: ${page ? page.file : route}</p>
        </section>
      `;
      setPending(false);
      return false;
    } finally {
      renderInFlight = false;
    }
  }

  function scheduleRender(path) {
    const route = normalizePath(path || window.location.pathname);

    if (!isPublicPage(route) || !shouldPublicPagesOwnRoute(route)) {
      setPending(false);
      return;
    }

    if (route === lastRenderedRoute) {
      setPending(false);
      return;
    }

    setPending(true);

    if (renderTimer) {
      clearTimeout(renderTimer);
    }

    renderTimer = setTimeout(() => {
      renderTimer = null;
      renderPublicPage(route);
    }, 30);
  }

  function installRouteHooks() {
    const oldPushState = history.pushState;
    history.pushState = function publicPagesPushState() {
      const result = oldPushState.apply(this, arguments);
      scheduleRender(window.location.pathname);
      return result;
    };

    const oldReplaceState = history.replaceState;
    history.replaceState = function publicPagesReplaceState() {
      const result = oldReplaceState.apply(this, arguments);
      scheduleRender(window.location.pathname);
      return result;
    };

    window.addEventListener("popstate", () => {
      lastRenderedRoute = "";
      scheduleRender();
    });

    window.addEventListener("hashchange", () => {
      lastRenderedRoute = "";
      scheduleRender();
    });

    document.addEventListener("click", (event) => {
      const link = event.target.closest("a[href], a[data-route]");
      if (!link) return;

      const href = link.getAttribute("data-route") || link.getAttribute("href") || "/";
      const route = normalizePath(href);

      if (!isPublicPage(route)) return;
      if (!shouldPublicPagesOwnRoute(route)) return;

      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      lastRenderedRoute = "";
      history.pushState({}, "", route);
      scheduleRender(route);
    }, true);
  }

  window.APC_PUBLIC_PAGES = {
    routes: PUBLIC_PAGES,
    render: renderPublicPage,
    scheduleRender,
    hasLoginToken,
    shouldPublicPagesOwnRoute
  };

  installRouteHooks();
  scheduleRender();
})();
