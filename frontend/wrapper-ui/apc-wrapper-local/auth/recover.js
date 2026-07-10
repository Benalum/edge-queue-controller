(function () {
  "use strict";

  if (window.__APC_AUTH_RECOVER_CLICK_FIX__) return;
  window.__APC_AUTH_RECOVER_CLICK_FIX__ = true;

  const RECOVER_PATHS = [
    "/api/auth/forgot-password",
    "/public/auth/forgot-password"
  ];

  function byId(id) {
    return document.getElementById(id);
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
    return data.message || data.detail || data.error || fallback;
  }

  function setMessage(message, good) {
    const el = byId("authRecoverMessage");
    if (!el) return;

    el.textContent = message || "";
    el.classList.toggle("hidden", !message);
    el.classList.toggle("auth-message-ok", Boolean(good));
    el.classList.toggle("auth-message-bad", Boolean(message && !good));
  }

  function ensureRecoverPanel() {
    const authCard = document.querySelector("#authModal .auth-card");
    const authForm = byId("authForm");

    if (!authCard || !authForm) {
      console.warn("[auth-recover] auth modal/form missing");
      return false;
    }

    if (!byId("forgotPasswordBtn")) {
      const wrap = document.createElement("div");
      wrap.className = "auth-recover-link";

      const btn = document.createElement("button");
      btn.id = "forgotPasswordBtn";
      btn.className = "ghost-btn";
      btn.type = "button";
      btn.textContent = "Forgot password?";

      wrap.appendChild(btn);
      authForm.insertAdjacentElement("afterend", wrap);
    }

    if (!byId("authRecoverPanel")) {
      const panel = document.createElement("section");
      panel.id = "authRecoverPanel";
      panel.className = "auth-recover-panel hidden";
      panel.innerHTML = `
        <p class="subtitle">
          Enter your email and we will send password reset instructions if an account exists.
        </p>

        <label>
          Email
          <input id="authRecoverEmail" type="email" autocomplete="email" required />
        </label>

        <div class="auth-recover-actions">
          <button id="authRecoverSubmitBtn" class="primary-btn" type="button">
            Send recovery link
          </button>
          <button id="authBackToLoginBtn" class="ghost-btn" type="button">
            Back to login
          </button>
        </div>

        <div id="authRecoverMessage" class="notice hidden"></div>
      `;

      authCard.appendChild(panel);
    }

    return true;
  }

  function setRecoverMode(enabled) {
    ensureRecoverPanel();

    const isRecover = Boolean(enabled);

    byId("authForm")?.classList.toggle("hidden", isRecover);
    document.querySelector("#authModal .auth-tabs")?.classList.toggle("hidden", isRecover);
    byId("forgotPasswordBtn")?.closest(".auth-recover-link")?.classList.toggle("hidden", isRecover);
    byId("authRecoverPanel")?.classList.toggle("hidden", !isRecover);

    if (byId("authTitle")) {
      byId("authTitle").textContent = isRecover ? "Recover password" : "Login";
    }

    if (byId("authSubtitle")) {
      byId("authSubtitle").textContent = isRecover
        ? "Request a password reset email."
        : "Sign in to access your dashboard and future live services.";
    }

    setMessage("", true);

    if (isRecover) {
      const existingEmail = byId("authEmail")?.value.trim() || "";
      if (existingEmail && byId("authRecoverEmail")) {
        byId("authRecoverEmail").value = existingEmail;
      }
      setTimeout(() => byId("authRecoverEmail")?.focus(), 0);
    }
  }

  async function postRecover(email) {
    let lastError = null;

    for (const path of RECOVER_PATHS) {
      try {
        const response = await fetch(path, {
          method: "POST",
          credentials: "same-origin",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ email })
        });

        const text = await response.text();
        const data = parseJsonSafe(text);

        if (response.status === 404) {
          lastError = new Error(path + " returned 404");
          continue;
        }

        if (!response.ok) {
          throw new Error(messageFrom(data, path + " failed with HTTP " + response.status));
        }

        return { path, data };
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError || new Error("Password recovery request failed.");
  }

  async function submitRecover() {
    ensureRecoverPanel();

    const email = byId("authRecoverEmail")?.value.trim() || byId("authEmail")?.value.trim() || "";

    if (!email) {
      setMessage("Enter your email address.", false);
      return;
    }

    const btn = byId("authRecoverSubmitBtn");
    if (btn) {
      btn.disabled = true;
      btn.textContent = "Sending...";
    }

    setMessage("Sending recovery request...", true);

    try {
      const result = await postRecover(email);
      const delivery = result.data && result.data.email_delivery ? " Delivery: " + result.data.email_delivery + "." : "";
      setMessage("Password reset request sent. Check your inbox and spam folder." + delivery, true);
      console.info("[auth-recover] sent", result.path, result.data);
    } catch (error) {
      console.error("[auth-recover] failed", error);
      setMessage(error.message || "Password recovery failed.", false);
    } finally {
      if (btn) {
        btn.disabled = false;
        btn.textContent = "Send recovery link";
      }
    }
  }

  function init() {
    ensureRecoverPanel();
  }

  document.addEventListener("click", function (event) {
    const forgot = event.target.closest("#forgotPasswordBtn");
    const back = event.target.closest("#authBackToLoginBtn");
    const submit = event.target.closest("#authRecoverSubmitBtn");

    if (forgot) {
      event.preventDefault();
      setRecoverMode(true);
      return;
    }

    if (back) {
      event.preventDefault();
      setRecoverMode(false);
      return;
    }

    if (submit) {
      event.preventDefault();
      submitRecover();
    }
  }, true);

  document.addEventListener("keydown", function (event) {
    if (event.key !== "Enter") return;
    if (!byId("authRecoverPanel") || byId("authRecoverPanel").classList.contains("hidden")) return;
    if (event.target && event.target.id === "authRecoverEmail") {
      event.preventDefault();
      submitRecover();
    }
  });

  window.APC_AUTH_RECOVER = {
    open: function () {
      setRecoverMode(true);
    },
    close: function () {
      setRecoverMode(false);
    },
    submit: submitRecover,
    endpoints: RECOVER_PATHS
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }

  window.addEventListener("load", init, { once: true });
  document.addEventListener("apc-header-ready", init);
})();
