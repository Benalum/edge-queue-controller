/* APC_CLOSED_BETA_SIGNUP_GUARD_STAGE_17K_Z_R8B */
(function () {
  "use strict";

  const MESSAGE =
    "Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.";

  window.APC_CLOSED_BETA_SIGNUP = Object.freeze({
    stage: "17K-Z-R8B",
    brandName: "Buddies Who Study",
    productDomain: "buddieswhostudy.com",
    publicSignupEnabled: false,
    existingUserSigninEnabled: true,
    message: MESSAGE,
  });

  function showMessage() {
    let banner = document.getElementById("apcClosedBetaSignupNotice");
    if (!banner) {
      banner = document.createElement("div");
      banner.id = "apcClosedBetaSignupNotice";
      banner.setAttribute("role", "status");
      banner.setAttribute("aria-live", "polite");
      banner.style.border = "1px solid currentColor";
      banner.style.borderRadius = "12px";
      banner.style.padding = "0.75rem";
      banner.style.margin = "0.75rem 0";
      banner.style.fontWeight = "600";
      const modal = document.getElementById("authModal");
      if (modal) modal.prepend(banner);
      else if (document.body) document.body.prepend(banner);
    }
    banner.textContent = MESSAGE;

    for (const id of ["authStatus", "authMessage"]) {
      const el = document.getElementById(id);
      if (el) el.textContent = MESSAGE;
    }
  }

  function disableRegister() {
    const btn = document.getElementById("registerTabBtn");
    if (btn) {
      btn.disabled = true;
      btn.hidden = true;
      btn.setAttribute("aria-disabled", "true");
      btn.setAttribute("data-closed-beta-disabled", "true");
      btn.textContent = "Beta closed";
    }
  }

  const nativeFetch = window.fetch ? window.fetch.bind(window) : null;
  if (nativeFetch) {
    window.fetch = function closedBetaFetchGuard(input, init) {
      const url =
        typeof input === "string"
          ? input
          : input && typeof input.url === "string"
            ? input.url
            : "";
      if (/\/auth\/register|\/register|\/signup/i.test(url)) {
        showMessage();
        return Promise.resolve(new Response(JSON.stringify({
          ok: false,
          code: "closed_beta_signup_disabled",
          message: MESSAGE
        }), {
          status: 403,
          headers: { "content-type": "application/json" }
        }));
      }
      return nativeFetch(input, init);
    };
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      disableRegister();
    });
  } else {
    disableRegister();
  }
})();
