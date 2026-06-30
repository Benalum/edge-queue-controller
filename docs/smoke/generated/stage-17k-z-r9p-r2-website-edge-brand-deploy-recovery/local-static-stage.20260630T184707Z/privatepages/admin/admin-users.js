/* APC_ADMIN_USERS_MOUNT_ONLY_R3U12 */
(function () {
  "use strict";

  const MARKER = "APC_ADMIN_USERS_MOUNT_ONLY_R3U12";
  const TOKEN_KEYS = [
    "edgeStudyToken",
    "apcAuthToken",
    "apcToken",
    "authToken",
    "token",
    "access_token"
  ];

  const API_PATHS = [
    "/api/admin/users",
    "/system/admin/users"
  ];

  function escapeHtml(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function appRoute() {
    return String(location.pathname || "").replace(/\/+$/, "") || "/";
  }

  function isAdminRoute() {
    const path = appRoute();
    const hash = String(location.hash || "").toLowerCase();
    return path === "/admin" || hash === "#admin" || hash === "#/admin";
  }

  function root() {
    return document.querySelector("[data-apc-admin-users-root]");
  }

  function readStorageToken() {
    try {
      for (const key of TOKEN_KEYS) {
        const value = localStorage.getItem(key) || sessionStorage.getItem(key);
        if (value) return value;
      }
    } catch (_) {}
    return "";
  }

  function tokenFromObject(value, depth) {
    if (!value || depth > 4) return "";
    if (typeof value === "string") return value;

    if (typeof value !== "object") return "";

    const directKeys = [
      "token",
      "access_token",
      "accessToken",
      "jwt",
      "bearer",
      "id_token",
      "idToken"
    ];

    for (const key of directKeys) {
      if (typeof value[key] === "string" && value[key]) return value[key];
    }

    const nestedKeys = [
      "auth",
      "session",
      "user",
      "currentUser",
      "data",
      "raw"
    ];

    for (const key of nestedKeys) {
      const found = tokenFromObject(value[key], depth + 1);
      if (found) return found;
    }

    return "";
  }

  function findBearerToken() {
    const storageToken = readStorageToken();
    if (storageToken) return storageToken;

    const globals = [
      window.authState,
      window.APC_AUTH,
      window.APC_AUTH_STATE,
      window.edgeStudyAuth,
      window.currentUser
    ];

    for (const candidate of globals) {
      const found = tokenFromObject(candidate, 0);
      if (found) return found;
    }

    return "";
  }

  function buildHeaders() {
    const headers = {
      Accept: "application/json"
    };

    const token = findBearerToken();
    if (token) {
      headers.Authorization = token.toLowerCase().startsWith("bearer ")
        ? token
        : "Bearer " + token;
    }

    return headers;
  }

  async function readJson(response) {
    const text = await response.text();
    if (!text) return null;

    try {
      return JSON.parse(text);
    } catch (_) {
      return { text };
    }
  }

  async function fetchUsers() {
    let lastResult = null;

    for (const path of API_PATHS) {
      try {
        const response = await fetch(path, {
          method: "GET",
          credentials: "include",
          cache: "no-store",
          headers: buildHeaders()
        });

        const data = await readJson(response);
        const result = {
          ok: response.ok,
          status: response.status,
          path,
          data
        };

        if (response.ok) return result;
        lastResult = result;
      } catch (error) {
        lastResult = {
          ok: false,
          status: 0,
          path,
          error
        };
      }
    }

    return lastResult || {
      ok: false,
      status: 0,
      path: API_PATHS[0],
      error: new Error("Admin users request failed.")
    };
  }

  function asArray(payload) {
    if (!payload) return [];
    if (Array.isArray(payload)) return payload;
    if (Array.isArray(payload.users)) return payload.users;
    if (Array.isArray(payload.rows)) return payload.rows;
    if (payload.data && Array.isArray(payload.data.users)) return payload.data.users;
    if (payload.result && Array.isArray(payload.result.users)) return payload.result.users;
    return [];
  }

  function currentAdminEmail(payload) {
    const direct = payload && (payload.admin_email || payload.current_admin || payload.email);
    if (direct) return direct;

    try {
      const user = JSON.parse(localStorage.getItem("edgeStudyUser") || "{}");
      return user.email || user.username || "";
    } catch (_) {
      return "";
    }
  }

  function normalizeUser(row) {
    const email = row.email || row.username || row.user_email || row.account_email || "";
    const role = row.role || row.account_role || row.user_role || "user";
    const status = row.status || row.account_status || "";
    const online = Boolean(
      row.online ||
      row.is_online ||
      row.active_now ||
      row.is_active ||
      String(status).toLowerCase() === "online"
    );

    return {
      email,
      role,
      status,
      online,
      lastSeen: row.last_seen_at || row.last_seen || row.last_login_at || row.updated_at || "",
      created: row.created_at || row.inserted_at || ""
    };
  }

  function renderLoading(message) {
    const mount = root();
    if (!mount) return false;

    mount.innerHTML = `
      <div class="apc-admin-users-head">
        <div>
          <p class="apc-admin-users-kicker">Admin only</p>
          <h1>Admin console</h1>
          <p class="apc-admin-users-muted">${escapeHtml(message || "Loading users online/offline…")}</p>
        </div>
        <button class="apc-admin-users-btn" type="button" data-apc-admin-refresh="true">Refresh</button>
      </div>

      <div class="apc-admin-users-card">
        <strong>Loading admin users…</strong>
        <p class="apc-admin-users-muted">Checking admin access and loading the users list.</p>
      </div>
    `;
    return true;
  }

  function renderError(result) {
    const mount = root();
    if (!mount) return false;

    const detail = result && (
      result.text ||
      (result.data && result.data.detail) ||
      (result.error && result.error.message)
    ) || "Unable to load admin users.";

    mount.innerHTML = `
      <div class="apc-admin-users-head">
        <div>
          <p class="apc-admin-users-kicker">Admin only</p>
          <h1>Admin console</h1>
          <p class="apc-admin-users-muted">Could not load the users list.</p>
        </div>
        <button class="apc-admin-users-btn" type="button" data-apc-admin-refresh="true">Retry</button>
      </div>

      <div class="apc-admin-users-card apc-admin-users-error">
        <strong>Could not load users.</strong><br />
        <span>${escapeHtml(detail)}</span>
        <p class="apc-admin-users-muted">Endpoint: ${escapeHtml(result && result.path || API_PATHS[0])}</p>
      </div>
    `;
    return true;
  }

  function renderUsers(result) {
    const mount = root();
    if (!mount) return false;

    const payload = result.data || {};
    const users = asArray(payload).map(normalizeUser);
    const online = users.filter((user) => user.online).length;
    const offline = Math.max(users.length - online, 0);
    const adminEmail = currentAdminEmail(payload);

    mount.innerHTML = `
      <div class="apc-admin-users-head">
        <div>
          <p class="apc-admin-users-kicker">Admin only</p>
          <h1>Admin console</h1>
          <p class="apc-admin-users-muted">Current admin: ${escapeHtml(adminEmail || "signed-in admin")}</p>
        </div>
        <button class="apc-admin-users-btn" type="button" data-apc-admin-refresh="true">Refresh</button>
      </div>

      <div class="apc-admin-users-summary" aria-label="User summary">
        <article><strong>${escapeHtml(users.length)}</strong><span>Total users</span></article>
        <article><strong>${escapeHtml(online)}</strong><span>Online</span></article>
        <article><strong>${escapeHtml(offline)}</strong><span>Offline</span></article>
      </div>

      <div class="apc-admin-users-card">
        <h2>Users</h2>
        <div class="apc-admin-users-table-wrap">
          <table class="apc-admin-users-table">
            <thead>
              <tr>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
                <th>Last seen/login</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              ${users.map((user) => `
                <tr>
                  <td>${escapeHtml(user.email || "unknown")}</td>
                  <td>${escapeHtml(user.role)}</td>
                  <td><span class="apc-admin-users-pill ${user.online ? "online" : "offline"}">${user.online ? "Online" : "Offline"}</span></td>
                  <td>${escapeHtml(user.lastSeen || "—")}</td>
                  <td>${escapeHtml(user.created || "—")}</td>
                </tr>
              `).join("") || `
                <tr>
                  <td colspan="5">No users returned.</td>
                </tr>
              `}
            </tbody>
          </table>
        </div>
        <p class="apc-admin-users-muted">Loaded from ${escapeHtml(result.path)}.</p>
      </div>
    `;
    return true;
  }

  async function renderAdminUsers() {
    if (!isAdminRoute()) return false;

    const mount = root();
    if (!mount) return false;

    renderLoading("Loading users from the admin API...");

    const result = await fetchUsers();

    if (!root()) return false;

    if (result && result.ok) {
      renderUsers(result);
    } else {
      renderError(result);
    }

    return true;
  }

  function scheduleRender() {
    window.setTimeout(renderAdminUsers, 0);
  }

  document.addEventListener("apc-private-page-rendered", function (event) {
    if (event.detail && event.detail.page === "admin") {
      scheduleRender();
    }
  });

  document.addEventListener("click", function (event) {
    const refresh = event.target && event.target.closest
      ? event.target.closest("[data-apc-admin-refresh]")
      : null;

    if (!refresh) return;

    event.preventDefault();
    renderAdminUsers();
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", scheduleRender, { once: true });
  } else {
    scheduleRender();
  }

  window.APC_ADMIN_USERS_ADMIN_FOLDER_R3U = {
    marker: MARKER,
    render: renderAdminUsers
  };

  window.APC_ADMIN_USERS_MOUNT_ONLY_R3U12 = {
    marker: MARKER,
    render: renderAdminUsers
  };
})();
