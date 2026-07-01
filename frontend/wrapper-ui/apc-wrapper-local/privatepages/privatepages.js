(function () {
  "use strict";

  if (window.__APC_PRIVATEPAGES_INSTALLED__) return;
  window.__APC_PRIVATEPAGES_INSTALLED__ = true;

  const TOKEN_KEY = "edgeStudyToken";
  const USER_KEY = "edgeStudyUser";

  const PRIVATE_ROUTES = new Set([
    "/",
    "/home",
    "/dashboard",
    "/study",
    "/companion",
    "/profile",
    "/system",
    "/admin",
    "/support"
  ]);

  const PAGE_BY_ROUTE = {
    "/": "dashboard",
    "/home": "dashboard",
    "/dashboard": "dashboard",
    "/study": "study",
    "/companion": "companion",
    "/profile": "profile",
    "/system": "system",
    "/admin": "admin",
    "/support": "support"
  };

  const TITLE_BY_PAGE = {
    dashboard: "Dashboard",
    study: "Study",
    companion: "Companion",
    profile: "Profile",
    system: "System",
    admin: "Admin",
    support: "Support"
  };

  let currentUser = null;
  let privateRenderInFlight = 0;

  function byId(id) {
    return document.getElementById(id);
  }

  function appRoot() {
    return byId("app");
  }

  function cleanPath() {
    return window.location.pathname.replace(/\/+$/, "") || "/";
  }

  function getToken() {
    try {
      return localStorage.getItem(TOKEN_KEY) || "";
    } catch (_) {
      return "";
    }
  }

  function parseJsonSafe(text) {
    try {
      return JSON.parse(text);
    } catch (_) {
      return text || "";
    }
  }

  function normalizeUser(raw) {
    const user = raw && raw.user ? raw.user : raw || {};
    return {
      id: user.id || user.user_id || "",
      email: user.email || user.username || "",
      role: user.role || user.account_role || user.user_role || user.permission || "",
      plan: user.plan || user.account_plan || user.tier || "",
      status: user.status || user.account_status || "active",
      raw: user
    };
  }

  function isAdmin(user) {
    const role = String(user?.role || "").toLowerCase();
    return Boolean(
      user?.is_admin ||
      role === "admin" ||
      role === "owner" ||
      role === "superadmin"
    );
  }

  function syncGlobalHeaderAdminSupport(user) {
    const admin = isAdmin(user);

    document.querySelectorAll('header a, nav a').forEach((link) => {
      const href = link.getAttribute("href") || "";
      const label = (link.textContent || "").trim().toLowerCase();

      const isSupportLink = href === "/support" || href.endsWith("/support") || label === "support";
      const isAdminLink = href === "/admin" || href.endsWith("/admin") || label === "admin";

      if (!admin && isAdminLink) {
        link.href = "/support";
        link.textContent = "Support";
        link.dataset.privateRoleLink = "support";
        return;
      }

      if (admin && isSupportLink) {
        link.href = "/admin";
        link.textContent = "Admin";
        link.dataset.privateRoleLink = "admin";
      }
    });
  }


  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function fillTemplate(html, user) {
    const safe = {
      email: escapeHtml(user.email || "signed-in user"),
      role: escapeHtml(user.role || "user"),
      plan: escapeHtml(user.plan || "standard"),
      status: escapeHtml(user.status || "active")
    };

    return html
      .replaceAll("{{email}}", safe.email)
      .replaceAll("{{role}}", safe.role)
      .replaceAll("{{plan}}", safe.plan)
      .replaceAll("{{status}}", safe.status);
  }

  function routeIsPrivate(path) {
    return PRIVATE_ROUTES.has(path);
  }

  function routeNeedsLogin(path) {
    return path === "/dashboard" || path === "/home" || path === "/admin";
  }

  async function fetchMe() {
    const token = getToken();

    if (!token) {
      currentUser = null;
      syncGlobalHeaderAdminSupport(null);
      return null;
    }

    const headers = {
      Accept: "application/json"
    };

    headers.Authorization = "Bearer " + token;

    try {
      const response = await fetch("/api/me", {
        method: "GET",
        credentials: "same-origin",
        headers
      });

      const text = await response.text();
      const data = parseJsonSafe(text);

      if (!response.ok) {
        currentUser = null;
        syncGlobalHeaderAdminSupport(null);
        return null;
      }

      currentUser = normalizeUser(data);
      syncGlobalHeaderAdminSupport(currentUser);

      try {
        localStorage.setItem(USER_KEY, JSON.stringify(currentUser.raw || currentUser));
      } catch (_) {}

      return currentUser;
    } catch (error) {
      console.warn("[privatepages] /api/me failed", error);
      currentUser = null;
      return null;
    }
  }

  function setLoading(message) {
    const app = appRoot();
    if (!app) return;
    app.innerHTML = `<div class="private-loading">${escapeHtml(message || "Loading private page...")}</div>`;
  }

  function showLoginRequired() {
    const app = appRoot();
    if (!app) return;

    app.innerHTML = `
      <section class="private-shell">
        <section class="private-hero">
          <p class="private-eyebrow">Sign in required</p>
          <h1>This page is private</h1>
          <p>Log in to open your dashboard and private workspace.</p>
          <div class="private-actions">
            <button class="private-button" type="button" data-private-open-login>Open login</button>
            <a class="private-button" href="/">Back to public home</a>
          </div>
        </section>
      </section>
    `;
  }

  function privateNav(user, page) {
    const admin = isAdmin(user);

    const links = [
      ["/dashboard", "Dashboard", "dashboard"],
      ["/study", "Study", "study"],
      ["/companion", "Companion", "companion"],
      ["/profile", "Profile", "profile"],
      ["/system", "System", "system"],
      [admin ? "/admin" : "/support", admin ? "Admin" : "Support", admin ? "admin" : "support"]
    ];

    return `
      <header class="private-topbar">
        <div class="private-brand">
          <strong>Study Companion</strong>
          <span>${escapeHtml(user.email || "Signed in")} · ${escapeHtml(user.role || "user")}</span>
        </div>

        <nav class="private-nav" aria-label="Private navigation">
          ${links.map(([href, label, key]) => `
            <a href="${href}" class="${key === page ? "active" : ""}">${label}</a>
          `).join("")}
        </nav>
      </header>
    `;
  }

  async function loadPageFragment(page) {
    const response = await fetch(`/privatepages/pages/${page}.html?v=stage17j-r3-profile-fragment-cache-20260628`, {
      method: "GET",
      credentials: "same-origin",
      cache: "no-store",
      headers: { Accept: "text/html" }
    });

    if (!response.ok) {
      throw new Error(`Private page fragment failed: ${page} HTTP ${response.status}`);
    }

    return response.text();
  }

  function postProcessPage(user, page) {
    const admin = isAdmin(user);

    document.querySelectorAll("[data-admin-card]").forEach((el) => {
      el.hidden = !admin;
    });

    document.querySelectorAll("[data-support-card]").forEach((el) => {
      el.hidden = admin;
    });

    document.querySelectorAll("[data-private-open-login]").forEach((el) => {
      el.addEventListener("click", function () {
        if (window.APC_AUTH && typeof window.APC_AUTH.open === "function") {
          window.APC_AUTH.open("login");
        }
      });
    });

    document.querySelectorAll("[data-private-open-recover]").forEach((el) => {
      el.addEventListener("click", function () {
        if (window.APC_AUTH_RECOVER && typeof window.APC_AUTH_RECOVER.open === "function") {
          window.APC_AUTH_RECOVER.open();
        } else if (window.APC_AUTH && typeof window.APC_AUTH.open === "function") {
          window.APC_AUTH.open("login");
        }
      });
    });

    document.title = `${TITLE_BY_PAGE[page] || "Private"} | Buddies Who Study`;
  }

  async function renderPrivateRoute() {
    const renderId = ++privateRenderInFlight;
    const path = cleanPath();

    if (!routeIsPrivate(path)) return false;

    const token = getToken();

    if (!token) {
      if (routeNeedsLogin(path)) {
        showLoginRequired();
        return true;
      }

      // Let publicpages render signed-out public pages like /study, /companion, /profile, /system, /support.
      return false;
    }

    setLoading("Loading private page...");

    const user = await fetchMe();

    if (renderId !== privateRenderInFlight) return true;

    if (!user) {
      showLoginRequired();
      return true;
    }

    let page = PAGE_BY_ROUTE[path] || "dashboard";
    const admin = isAdmin(user);

    if (page === "admin" && !admin) {
      page = "support";
    }

    if (page === "support" && admin) {
      page = "admin";
    }

    try {
      const fragment = await loadPageFragment(page);

      if (renderId !== privateRenderInFlight) return true;

      const app = appRoot();
      if (!app) return false;

      app.innerHTML = `
        <section class="private-shell" data-private-page="${escapeHtml(page)}">
          ${fillTemplate(fragment, user)}
        </section>
      `;

      postProcessPage(user, page);
      document.dispatchEvent(new CustomEvent("apc-private-page-rendered", {
        detail: { page, user }
      }));
      return true;
    } catch (error) {
      console.error("[privatepages] render failed", error);
      const app = appRoot();
      if (app) {
        app.innerHTML = `
          <section class="private-shell">
            <article class="private-card private-danger">
              <h1>Private page failed to load</h1>
              <p>${escapeHtml(error.message || "Unknown private page error")}</p>
            </article>
          </section>
        `;
      }
      return true;
    }
  }

  function hijackPrivateLinks() {
    window.addEventListener("click", function (event) {
      // Let browser-native new tab/window behavior work.
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
        return;
      }

      const link = event.target && event.target.closest
        ? event.target.closest("a[href]")
        : null;

      if (!link) return;

      const url = new URL(link.href, window.location.origin);
      if (url.origin !== window.location.origin) return;

      const path = url.pathname.replace(/\/+$/, "") || "/";
      if (!routeIsPrivate(path)) return;

      const signedIn = Boolean(getToken());

      // Signed-out public pages should remain public.
      if (!signedIn && !routeNeedsLogin(path)) {
        return;
      }

      // Signed-in users should always get private pages for these routes.
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      window.history.pushState({}, "", url.pathname + url.search + url.hash);
      renderPrivateRoute();
    }, true);
  }


  function init() {
    syncGlobalHeaderAdminSupport(currentUser);
    renderPrivateRoute();
  }

  window.APC_PRIVATEPAGES = {
    render: renderPrivateRoute,
    me: function () { return currentUser; },
    isAdmin: function () { return isAdmin(currentUser); },
    routes: Array.from(PRIVATE_ROUTES)
  };

  hijackPrivateLinks();

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }

  window.addEventListener("popstate", init);
  document.addEventListener("apc-auth-changed", init);
  window.addEventListener("storage", function (event) {
    if (event.key === TOKEN_KEY || event.key === USER_KEY) init();
  });
})();
