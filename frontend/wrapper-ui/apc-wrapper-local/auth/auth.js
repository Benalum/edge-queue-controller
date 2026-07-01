(function () {
  "use strict";

  if (window.__APC_STANDALONE_AUTH_INSTALLED__) return;
  window.__APC_STANDALONE_AUTH_INSTALLED__ = true;

  const TOKEN_KEY = "edgeStudyToken";
  const USER_KEY = "edgeStudyUser";
  const LOGIN_PATHS = ["/api/auth/login", "/public/auth/login", "/auth/login"];
  const REGISTER_PATHS = ["/api/auth/register", "/public/auth/register", "/auth/register"];
  const LOGOUT_PATHS = ["/api/auth/logout", "/public/auth/logout", "/auth/logout"];
  const ME_PATHS = ["/api/me", "/public/me", "/me"];

  let mode = "login";

  function byId(id) {
    return document.getElementById(id);
  }

  function safeJsonParse(text) {
    try {
      return JSON.parse(text);
    } catch (_) {
      return text || "";
    }
  }

  function getToken() {
    try {
      return localStorage.getItem(TOKEN_KEY) || "";
    } catch (_) {
      return "";
    }
  }

  function setToken(token, user) {
    try {
      if (token) {
        localStorage.setItem(TOKEN_KEY, token);
      } else {
        localStorage.removeItem(TOKEN_KEY);
      }

      if (user) {
        localStorage.setItem(USER_KEY, JSON.stringify(user));
      } else if (!token) {
        localStorage.removeItem(USER_KEY);
      }
    } catch (_) {}

    window.authState = {
      token: token || "",
      user: user || null
    };

    document.dispatchEvent(
      new CustomEvent("apc-auth-changed", {
        detail: {
          loggedIn: Boolean(token),
          user: user || null
        }
      })
    );
  }

  function readStoredUser() {
    try {
      const raw = localStorage.getItem(USER_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  function extractToken(data) {
    if (!data || typeof data !== "object") return "";

    return (
      data.token ||
      data.access_token ||
      data.accessToken ||
      data.session_token ||
      data.sessionToken ||
      (data.session && (data.session.token || data.session.access_token)) ||
      ""
    );
  }

  function extractUser(data) {
    if (!data || typeof data !== "object") return null;

    return (
      data.user ||
      data.account ||
      data.profile ||
      data.me ||
      null
    );
  }

  function extractMessage(data, fallback) {
    if (!data) return fallback;

    if (typeof data === "string") return data || fallback;

    return (
      data.message ||
      data.detail ||
      data.error ||
      data.reason ||
      fallback
    );
  }

  async function apiRequest(paths, options) {
    const opts = options || {};
    const method = opts.method || "GET";
    const body = opts.body;
    const needsAuth = Boolean(opts.auth);
    const headers = {
      Accept: "application/json"
    };

    if (body !== undefined) {
      headers["Content-Type"] = "application/json";
    }

    const token = getToken();
    if (needsAuth && token) {
      headers.Authorization = "Bearer " + token;
    }

    let last404 = null;

    for (const path of paths) {
      const response = await fetch(path, {
        method,
        headers,
        credentials: "same-origin",
        body: body === undefined ? undefined : JSON.stringify(body)
      });

      const text = await response.text();
      const data = safeJsonParse(text);

      if (response.status === 404) {
        last404 = {
          path,
          status: response.status,
          data
        };
        continue;
      }

      if (!response.ok) {
        const message = extractMessage(data, "Request failed with HTTP " + response.status);
        const error = new Error(message);
        error.status = response.status;
        error.path = path;
        error.data = data;
        throw error;
      }

      return {
        path,
        status: response.status,
        data
      };
    }

    const error = new Error("No auth endpoint was found. Last missing path: " + (last404 ? last404.path : paths[0]));
    error.status = 404;
    throw error;
  }

  function findHeaderTarget() {
    return (
      document.querySelector("[data-apc-header-component='true'] .actions") ||
      document.querySelector("[data-apc-header-component='true'] .header-actions") ||
      document.querySelector("[data-apc-header-component='true'] nav") ||
      document.querySelector("[data-apc-header-component='true']") ||
      document.querySelector("header") ||
      document.body
    );
  }

  function ensureAuthButtons() {
    if (byId("authOpenBtn") && byId("logoutBtn")) return;

    let controls = byId("authControls");
    if (!controls) {
      controls = document.createElement("div");
      controls.id = "authControls";
      controls.className = "auth-controls";
      controls.dataset.authControls = "true";
    }

    if (!byId("authOpenBtn")) {
      const loginBtn = document.createElement("button");
      loginBtn.id = "authOpenBtn";
      loginBtn.className = "primary-btn";
      loginBtn.type = "button";
      loginBtn.textContent = "Login";
      controls.appendChild(loginBtn);
    }

    if (!byId("logoutBtn")) {
      const logoutBtn = document.createElement("button");
      logoutBtn.id = "logoutBtn";
      logoutBtn.className = "ghost-btn hidden";
      logoutBtn.type = "button";
      logoutBtn.textContent = "Logout";
      controls.appendChild(logoutBtn);
    }

    const target = findHeaderTarget();
    target.appendChild(controls);
  }

  function setMessage(message, good) {
    const el = byId("authMessage");
    if (!el) return;

    el.textContent = message || "";
    el.classList.toggle("hidden", !message);
    el.classList.toggle("auth-message-ok", Boolean(good));
    el.classList.toggle("auth-message-bad", Boolean(message && !good));
  }

  function setMode(nextMode) {
    mode = nextMode === "register" ? "register" : "login";

    const isRegister = mode === "register";

    if (byId("authTitle")) {
      byId("authTitle").textContent = isRegister ? "Register" : "Login";
    }

    if (byId("authSubtitle")) {
      byId("authSubtitle").textContent = isRegister
        ? "Create an account for Study, Companion, Profile, and future private tools."
        : "Sign in to access your dashboard and future live services.";
    }

    if (byId("authSubmitBtn")) {
      byId("authSubmitBtn").textContent = isRegister ? "Register" : "Login";
    }

    if (byId("authPassword")) {
      byId("authPassword").autocomplete = isRegister ? "new-password" : "current-password";
    }

    byId("loginTabBtn")?.classList.toggle("active", !isRegister);
    byId("registerTabBtn")?.classList.toggle("active", isRegister);

    setMessage("", true);
  }

  function openAuth(nextMode) {
    setMode(nextMode || "login");

    const modal = byId("authModal");
    if (!modal) {
      alert("Auth modal is missing from index.html.");
      return;
    }

    modal.classList.remove("hidden");
    modal.setAttribute("aria-hidden", "false");

    setTimeout(() => {
      byId("authEmail")?.focus();
    }, 0);
  }

  function closeAuth() {
    const modal = byId("authModal");
    if (!modal) return;

    modal.classList.add("hidden");
    modal.setAttribute("aria-hidden", "true");
  }

  function updateAuthButtons() {
    ensureAuthButtons();

    const token = getToken();
    const loggedIn = Boolean(token);

    byId("authOpenBtn")?.classList.toggle("hidden", loggedIn);
    byId("logoutBtn")?.classList.toggle("hidden", !loggedIn);

    const user = readStoredUser();
    window.authState = {
      token,
      user
    };
  }

  async function refreshMe() {
    const token = getToken();

    if (!token) {
      setToken("", null);
      updateAuthButtons();
      return;
    }

    try {
      const result = await apiRequest(ME_PATHS, {
        method: "GET",
        auth: true
      });

      const user = extractUser(result.data) || result.data || readStoredUser();
      setToken(token, user);
    } catch (error) {
      if (error.status === 401 || error.status === 403) {
        setToken("", null);
      }
    }

    updateAuthButtons();
  }

  async function handleAuthSubmit(event) {
    event.preventDefault();

    const email = byId("authEmail")?.value.trim() || "";
    const password = byId("authPassword")?.value || "";

    if (!email || !password) {
      setMessage("Enter both email and password.", false);
      return;
    }

    const submitBtn = byId("authSubmitBtn");
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.textContent = mode === "register" ? "Registering..." : "Logging in...";
    }

    setMessage(mode === "register" ? "Creating account..." : "Signing in...", true);

    try {
      const paths = mode === "register" ? REGISTER_PATHS : LOGIN_PATHS;
      const result = await apiRequest(paths, {
        method: "POST",
        body: {
          email,
          password
        }
      });

      const token = extractToken(result.data);
      const user = extractUser(result.data) || {
        email
      };

      if (token) {
        setToken(token, user);
        updateAuthButtons();
        closeAuth();
        setMessage("", true);
      } else if (mode === "register") {
        setMessage("Registration submitted. If email verification is enabled, check your inbox. Otherwise switch to Login.", true);
        setMode("login");
      } else {
        setMessage("Login succeeded, but no token was returned. Check the auth API response shape.", false);
      }
    } catch (error) {
      setMessage(error.message || "Auth request failed.", false);
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = mode === "register" ? "Register" : "Login";
      }
    }
  }

  async function logout() {
    const token = getToken();

    try {
      if (token) {
        await apiRequest(LOGOUT_PATHS, {
          method: "POST",
          auth: true
        });
      }
    } catch (_) {
      // Local logout still succeeds even if the server has no logout endpoint.
    }

    setToken("", null);
    updateAuthButtons();
    closeAuth();
  }

  function wireEvents() {
    ensureAuthButtons();

    byId("authOpenBtn")?.addEventListener("click", () => openAuth("login"));
    byId("logoutBtn")?.addEventListener("click", logout);
    byId("authCloseBtn")?.addEventListener("click", closeAuth);
    byId("loginTabBtn")?.addEventListener("click", () => setMode("login"));
    byId("registerTabBtn")?.addEventListener("click", () => setMode("register"));
    byId("authForm")?.addEventListener("submit", handleAuthSubmit);

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") closeAuth();
    });
  }

  function init() {
    ensureAuthButtons();
    wireEvents();
    updateAuthButtons();
    refreshMe();

    setTimeout(ensureAuthButtons, 50);
    setTimeout(updateAuthButtons, 100);
    setTimeout(updateAuthButtons, 500);
  }

  window.APC_AUTH = {
    open: openAuth,
    close: closeAuth,
    logout,
    refresh: refreshMe,
    getToken,
    debug: function () {
      return {
        tokenPresent: Boolean(getToken()),
        user: readStoredUser(),
        loginPaths: LOGIN_PATHS,
        registerPaths: REGISTER_PATHS,
        logoutPaths: LOGOUT_PATHS,
        mePaths: ME_PATHS
      };
    }
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }

  document.addEventListener("apc-header-ready", () => {
    ensureAuthButtons();
    updateAuthButtons();
  });
})();

/* APC force hard refresh after logout */
(function () {
  "use strict";

  if (window.__APC_FORCE_HARD_LOGOUT_RELOAD__) return;
  window.__APC_FORCE_HARD_LOGOUT_RELOAD__ = true;

  function forceHardLogoutReload(reason) {
    try {
      localStorage.removeItem("edgeStudyToken");
      localStorage.removeItem("edgeStudyUser");
      sessionStorage.removeItem("edgeStudyToken");
      sessionStorage.removeItem("edgeStudyUser");
      sessionStorage.setItem("apcLogoutReloadReason", reason || "logout");
    } catch (_) {}

    window.location.replace("/");
  }

  document.addEventListener("click", function (event) {
    const el = event.target && event.target.closest
      ? event.target.closest("#logoutBtn, [data-logout], [data-auth-logout], [data-action='logout'], [data-action=\"logout\"], a[href*='/logout'], button, a, [role='button']")
      : null;

    if (!el) return;

    const joined = [
      el.textContent || "",
      el.id || "",
      el.className || "",
      el.getAttribute("data-action") || "",
      el.getAttribute("aria-label") || "",
      el.getAttribute("href") || ""
    ].join(" ").toLowerCase();

    if (
      joined.includes("logout") ||
      joined.includes("log out") ||
      joined.includes("sign out") ||
      joined.includes("signout")
    ) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      forceHardLogoutReload("logout_click");
    }
  }, true);

  window.APC_FORCE_HARD_LOGOUT_RELOAD = forceHardLogoutReload;
})();
