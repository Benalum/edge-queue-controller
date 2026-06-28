/* APC_ADMIN_USERS_ADMIN_FOLDER_R3U */
(function apcAdminUsersAdminFolderR3U() {
  "use strict";

  const MARKER = "APC_ADMIN_USERS_ADMIN_FOLDER_R3U";
  const API_PATHS = ["/api/admin/users", "/system/admin/users"];
  let inFlight = false;
  let lastRenderAt = 0;

  function esc(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function extractBearerToken(value) {
    if (!value) return "";
    if (typeof value === "string") {
      const raw = value.trim();
      if (!raw) return "";
      if (raw.toLowerCase().startsWith("bearer ")) return raw.replace(/^Bearer\s+/i, "");
      if (raw.startsWith("eyJ") || raw.length > 40) return raw;
      try {
        return extractBearerToken(JSON.parse(raw));
      } catch (_) {
        return "";
      }
    }

    if (typeof value === "object") {
      const direct = value.access_token
        || value.accessToken
        || value.token
        || value.jwt
        || value.authToken
        || value.sessionToken
        || value.session_token
        || value.bearer
        || (value.session && (
          value.session.access_token
          || value.session.accessToken
          || value.session.token
          || value.session.jwt
        ))
        || (value.auth && (
          value.auth.access_token
          || value.auth.accessToken
          || value.auth.token
          || value.auth.jwt
        ));

      if (direct) return extractBearerToken(direct);
    }

    return "";
  }

  function findBearerToken() {
    const globals = [
      window.authState,
      window.APC_AUTH,
      window.APC_AUTH_STATE,
      window.APC_SESSION,
      window.APC_PRIVATE_SESSION,
    ];

    for (const item of globals) {
      const token = extractBearerToken(item);
      if (token) return token;
    }

    const storageKeys = [
      "edgeStudyToken",
      "access_token",
      "accessToken",
      "apc_access_token",
      "token",
      "jwt",
      "authToken",
      "sessionToken",
      "session_token",
      "apcAuth",
      "apc_auth",
      "apcSession",
      "apc_session",
    ];

    for (const store of [localStorage, sessionStorage]) {
      for (const key of storageKeys) {
        try {
          const token = extractBearerToken(store.getItem(key));
          if (token) return token;
        } catch (_) {}
      }

      try {
        for (let i = 0; i < store.length; i += 1) {
          const key = store.key(i);
          if (!key || !/token|auth|session|jwt/i.test(key)) continue;
          const token = extractBearerToken(store.getItem(key));
          if (token) return token;
        }
      } catch (_) {}
    }

    return "";
  }

  function buildHeaders() {
    const headers = { Accept: "application/json" };
    const token = findBearerToken();
    if (token) headers.Authorization = "Bearer " + token;
    return headers;
  }

  function currentAdminEmail(payload) {
    const direct = payload && (payload.admin_email || payload.current_admin || payload.email);
    if (direct) return direct;
    try {
      return localStorage.getItem("apcLastKnownSignedInEmail") || "";
    } catch (_) {
      return "";
    }
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

  function normalizeUser(user) {
    const email = user.email || user.user_email || user.account_email || "";
    const name = user.name || user.display_name || user.full_name || user.username || "";
    const role = user.role || user.account_role || (user.is_admin ? "admin" : "user");
    const created = user.created_at || user.created || user.createdAt || "";
    const lastSeen = user.last_seen_at || user.last_seen || user.last_login_at || user.updated_at || "";
    const rawOnline = user.online ?? user.is_online ?? user.online_now ?? user.present;
    const status = String(user.status || user.presence || user.activity_status || "").toLowerCase();

    let online = false;
    if (rawOnline === true || rawOnline === 1 || rawOnline === "true" || rawOnline === "online") online = true;
    if (status === "online" || status === "active" || status === "present") online = true;

    return {
      id: user.id || user.user_id || user.account_id || email || name || "user",
      email,
      name,
      role,
      created,
      lastSeen,
      online,
    };
  }

  function isAdminRouteOrPage() {
    const path = String(location.pathname || "").replace(/\/+$/, "") || "/";
    if (path === "/admin") return true;
    const hash = String(location.hash || "").toLowerCase();
    if (hash.includes("admin")) return true;

    const app = document.getElementById("app");
    const text = app ? String(app.textContent || "") : "";
    return /Admin console|Admin only|User support|Platform controls|Open System/i.test(text);
  }

  async function fetchUsers() {
    let lastError = null;

    for (const path of API_PATHS) {
      try {
        const response = await fetch(path, {
          credentials: "include",
          cache: "no-store",
          headers: buildHeaders(),
        });
        const text = await response.text();
        let data = null;
        try { data = text ? JSON.parse(text) : null; } catch (_) {}

        if (response.ok) {
          return { ok: true, path, status: response.status, data };
        }

        lastError = {
          ok: false,
          path,
          status: response.status,
          data,
          text: text.slice(0, 500),
        };

        if (response.status !== 404) return lastError;
      } catch (error) {
        lastError = { ok: false, path, status: 0, text: String(error) };
      }
    }

    return lastError || { ok: false, path: API_PATHS[0], status: 0, text: "No admin users route reached." };
  }

  function renderShell(message) {
    const app = document.getElementById("app");
    if (!app) return;
    app.innerHTML = `
      <section class="apc-admin-users-page" data-apc-admin-users="${MARKER}">
        <div class="apc-admin-users-head">
          <div>
            <p class="apc-admin-users-muted">Admin only</p>
            <h1>Admin console</h1>
            <p class="apc-admin-users-muted">${esc(message || "Loading users...")}</p>
          </div>
          <div class="apc-admin-users-actions">
            <button class="apc-admin-users-btn" type="button" data-apc-admin-refresh="true">Refresh</button>
          </div>
        </div>
        <div class="apc-admin-users-card">Loading users...</div>
      </section>
    `;
  }

  function renderError(result) {
    const app = document.getElementById("app");
    if (!app) return;
    const status = result && result.status ? result.status : "network";
    const path = result && result.path ? result.path : API_PATHS.join(", ");
    const detail = result && (result.text || (result.data && result.data.detail)) || "Unable to load admin users.";
    app.innerHTML = `
      <section class="apc-admin-users-page" data-apc-admin-users="${MARKER}">
        <div class="apc-admin-users-head">
          <div>
            <p class="apc-admin-users-muted">Admin only</p>
            <h1>Admin console</h1>
            <p class="apc-admin-users-muted">Users online/offline</p>
          </div>
          <div class="apc-admin-users-actions">
            <button class="apc-admin-users-btn" type="button" data-apc-admin-refresh="true">Refresh</button>
          </div>
        </div>
        <div class="apc-admin-users-error">
          <strong>Could not load users.</strong><br />
          Route: <code>${esc(path)}</code><br />
          Status: <code>${esc(status)}</code><br />
          ${esc(detail)}
        </div>
      </section>
    `;
  }

  function renderUsers(result) {
    const app = document.getElementById("app");
    if (!app) return;

    const payload = result.data || {};
    const users = asArray(payload).map(normalizeUser);
    const onlineCount = users.filter((user) => user.online).length;
    const offlineCount = Math.max(0, users.length - onlineCount);
    const adminEmail = currentAdminEmail(payload);

    const rows = users.length
      ? users.map((user) => `
          <tr>
            <td><span class="apc-admin-users-badge ${user.online ? "online" : "offline"}">${user.online ? "online" : "offline"}</span></td>
            <td>${esc(user.email || user.id)}</td>
            <td>${esc(user.name || "—")}</td>
            <td>${esc(user.role || "user")}</td>
            <td>${esc(user.lastSeen || "—")}</td>
            <td>${esc(user.created || "—")}</td>
          </tr>
        `).join("")
      : `<tr><td colspan="6">No users returned by the admin users API.</td></tr>`;

    app.innerHTML = `
      <section class="apc-admin-users-page" data-apc-admin-users="${MARKER}">
        <div class="apc-admin-users-head">
          <div>
            <p class="apc-admin-users-muted">Admin only</p>
            <h1>Admin console</h1>
            <p class="apc-admin-users-muted">Current admin: ${esc(adminEmail || "signed-in admin")}</p>
          </div>
          <div class="apc-admin-users-actions">
            <button class="apc-admin-users-btn" type="button" data-apc-admin-refresh="true">Refresh</button>
          </div>
        </div>

        <div class="apc-admin-users-summary">
          <div class="apc-admin-users-card">Total users<strong>${users.length}</strong></div>
          <div class="apc-admin-users-card">Online<strong>${onlineCount}</strong></div>
          <div class="apc-admin-users-card">Offline<strong>${offlineCount}</strong></div>
        </div>

        <div class="apc-admin-users-table-wrap">
          <table class="apc-admin-users-table">
            <thead>
              <tr>
                <th>Status</th>
                <th>Email</th>
                <th>Name</th>
                <th>Role</th>
                <th>Last seen/login</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>
        </div>

        <p class="apc-admin-users-muted" style="margin-top:12px;">
          Loaded from <code>${esc(result.path)}</code>.
        </p>
      </section>
    `;
  }

  async function renderAdminUsers() {
    if (!isAdminRouteOrPage()) return;
    if (inFlight) return;

    const now = Date.now();
    if (now - lastRenderAt < 500) return;
    lastRenderAt = now;

    inFlight = true;
    renderShell("Loading users from the admin API...");

    try {
      const result = await fetchUsers();
      if (result && result.ok) renderUsers(result);
      else renderError(result);
    } finally {
      inFlight = false;
    }
  }

  document.addEventListener("click", function (event) {
    const refresh = event.target && event.target.closest && event.target.closest("[data-apc-admin-refresh]");
    if (refresh) {
      event.preventDefault();
      renderAdminUsers();
      return;
    }

    const nav = event.target && event.target.closest && event.target.closest("a,button,[role='tab'],[data-route],[data-page]");
    if (!nav) return;
    const marker = [
      nav.textContent,
      nav.getAttribute("href"),
      nav.getAttribute("data-route"),
      nav.getAttribute("data-page"),
      nav.getAttribute("data-tab"),
    ].join(" ");
    if (/admin/i.test(marker)) {
      setTimeout(renderAdminUsers, 80);
      setTimeout(renderAdminUsers, 350);
      setTimeout(renderAdminUsers, 900);
    }
  }, true);

  window.addEventListener("popstate", function () { setTimeout(renderAdminUsers, 50); });
  window.addEventListener("hashchange", function () { setTimeout(renderAdminUsers, 50); });
  document.addEventListener("DOMContentLoaded", function () {
    setTimeout(renderAdminUsers, 50);
    setTimeout(renderAdminUsers, 700);
  });

  const observer = new MutationObserver(function () {
    const app = document.getElementById("app");
    if (!app) return;
    if (!isAdminRouteOrPage()) return;
    if (app.querySelector("[data-apc-admin-users='" + MARKER + "']")) return;
    setTimeout(renderAdminUsers, 50);
  });

  observer.observe(document.documentElement, { childList: true, subtree: true });
  window.APC_ADMIN_USERS_ADMIN_FOLDER_R3U = { marker: MARKER, render: renderAdminUsers };
})();
