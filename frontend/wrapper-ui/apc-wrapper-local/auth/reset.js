(function () {
  "use strict";

  if (window.__APC_AUTH_RESET_INSTALLED__) return;
  window.__APC_AUTH_RESET_INSTALLED__ = true;

  const RESET_PATHS = [
    "/api/auth/reset-password",
    "/api/auth/password-reset/confirm",
    "/api/auth/password-reset",
    "/public/auth/reset-password",
    "/public/auth/password-reset/confirm",
    "/system/session/reset-password",
    "/system/session/password-reset"
  ];

  function byId(id) {
    return document.getElementById(id);
  }

  function currentPath() {
    return window.location.pathname.replace(/\/+$/, "") || "/";
  }

  function getToken() {
    const params = new URLSearchParams(window.location.search);
    return params.get("token") || "";
  }

  function parseJsonSafe(text) {
    try {
      return JSON.parse(text);
    } catch (_) {
      return text || "";
    }
  }

  function messageFrom(data, fallback) {
    if (!data) return fallback;
    if (typeof data === "string") return data || fallback;
    return data.message || data.detail || data.error || data.reason || fallback;
  }

  function setMessage(message, good) {
    const el = byId("resetPasswordMessage");
    if (!el) return;

    el.textContent = message || "";
    el.classList.toggle("hidden", !message);
    el.classList.toggle("auth-message-ok", Boolean(good));
    el.classList.toggle("auth-message-bad", Boolean(message && !good));
  }

  function renderResetPage() {
    const app = byId("app");
    if (!app) return false;

    const token = getToken();

    document.title = "Reset Password | Buddies Who Study";

    app.innerHTML = `
      <section class="public-hero auth-reset-page">
        <p class="eyebrow">Account recovery</p>
        <h1>Reset your password</h1>
        <p class="subtitle">
          Enter a new password for your Study Companion account.
        </p>

        <div class="auth-reset-card">
          ${
            token
              ? ""
              : `<div class="notice auth-message-bad">
                   This reset link is missing a token. Request a new password reset email.
                 </div>`
          }

          <form id="resetPasswordForm" class="auth-form">
            <label>
              New password
              <input id="resetPasswordInput" type="password" autocomplete="new-password" required minlength="8" />
            </label>

            <label>
              Confirm new password
              <input id="resetPasswordConfirmInput" type="password" autocomplete="new-password" required minlength="8" />
            </label>

            <button id="resetPasswordSubmitBtn" class="primary-btn" type="submit" ${token ? "" : "disabled"}>
              Update password
            </button>
          </form>

          <div id="resetPasswordMessage" class="notice hidden"></div>

          <div class="auth-recover-actions">
            <a class="ghost-btn" href="/">Back to home</a>
            <button id="resetOpenLoginBtn" class="ghost-btn" type="button">
              Open login
            </button>
          </div>
        </div>
      </section>
    `;

    return true;
  }

  async function postReset(path, payload) {
    const response = await fetch(path, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const text = await response.text();
    const data = parseJsonSafe(text);

    if (!response.ok) {
      const error = new Error(messageFrom(data, path + " failed with HTTP " + response.status));
      error.status = response.status;
      error.path = path;
      error.data = data;
      throw error;
    }

    return { path, data };
  }

  async function submitReset(event) {
    event.preventDefault();

    const token = getToken();
    const password = byId("resetPasswordInput")?.value || "";
    const confirm = byId("resetPasswordConfirmInput")?.value || "";

    if (!token) {
      setMessage("This reset link is missing a token. Request a new password reset email.", false);
      return;
    }

    if (password.length < 8) {
      setMessage("Use at least 8 characters for the new password.", false);
      return;
    }

    if (password !== confirm) {
      setMessage("The two password fields do not match.", false);
      return;
    }

    const btn = byId("resetPasswordSubmitBtn");
    if (btn) {
      btn.disabled = true;
      btn.textContent = "Updating...";
    }

    setMessage("Updating password...", true);

    const payloads = [
      { token, new_password: password },
      { reset_token: token, new_password: password },
      { token, password },
      { reset_token: token, password }
    ];

    let lastError = null;

    try {
      for (const path of RESET_PATHS) {
        for (const payload of payloads) {
          try {
            const result = await postReset(path, payload);

            setMessage("Password updated. You can now log in with the new password.", true);

            if (btn) {
              btn.textContent = "Password updated";
            }

            console.info("[auth-reset] password reset success", result.path, result.data);
            return;
          } catch (error) {
            lastError = error;

            // 404 means this endpoint name is not present; try the next one.
            if (error.status === 404) break;

            // 422 often means payload shape mismatch; try the next payload.
            if (error.status === 422) continue;

            // Some backend routes return 400 when the payload field name is wrong.
            // If it looks like a missing/short password error, try the next payload shape.
            if (
              error.status === 400 &&
              /password.*(8|character|short|required|missing)/i.test(error.message || "")
            ) {
              continue;
            }

            // For invalid/expired tokens, stop early and show the backend message.
            if (error.status === 400 || error.status === 401 || error.status === 403) {
              throw error;
            }
          }
        }
      }

      throw lastError || new Error("Password reset endpoint was not found.");
    } catch (error) {
      console.error("[auth-reset] failed", error);
      setMessage(error.message || "Password reset failed.", false);

      if (btn) {
        btn.disabled = false;
        btn.textContent = "Update password";
      }
    }
  }

  function openLogin() {
    if (window.APC_AUTH && typeof window.APC_AUTH.open === "function") {
      window.history.pushState({}, "", "/");
      window.APC_AUTH.open("login");
      return;
    }

    window.location.href = "/";
  }

  function init() {
    if (currentPath() !== "/reset-password") return;

    renderResetPage();

    byId("resetPasswordForm")?.addEventListener("submit", submitReset);
    byId("resetOpenLoginBtn")?.addEventListener("click", openLogin);

    if (typeof window.stage5o13SyncHeaderNavActiveState === "function") {
      window.stage5o13SyncHeaderNavActiveState();
    }
  }

  window.APC_AUTH_RESET = {
    render: renderResetPage,
    submit: submitReset,
    endpoints: RESET_PATHS
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }

  window.addEventListener("popstate", init);
})();
