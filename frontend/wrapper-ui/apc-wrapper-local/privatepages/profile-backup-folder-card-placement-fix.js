(function () {
  "use strict";

  var MARKER = "APC_PROFILE_BACKUP_FOLDER_CARD_PLACEMENT_FIX_R16CF";
  var PANEL_SELECTOR = "[data-apc-local-backup-folder-panel-r16cb], .apc-profile-backup-folder-panel";
  var RUN_ATTR = "data-apc-profile-backup-folder-placed-r16cf";

  function cleanText(value) {
    return String(value || "").replace(/\s+/g, " ").trim();
  }

  function hasClassLike(el, words) {
    if (!el || !el.className) return false;
    var cls = String(el.className).toLowerCase();
    return words.some(function (word) { return cls.indexOf(word) !== -1; });
  }

  function closestProfileCard(start) {
    var node = start;
    for (var i = 0; node && i < 10; i += 1, node = node.parentElement) {
      if (node === document.body || node === document.documentElement) break;
      if (node.matches && node.matches("article.private-card, section.private-card, .private-card, article.profile-card, section.profile-card, .profile-card, article.card, section.card, .card")) {
        return node;
      }
      if (node.tagName === "ARTICLE" || node.tagName === "SECTION") {
        return node;
      }
      if (hasClassLike(node, ["private-card", "profile-card", "settings-card", "local-settings", "anki", "card"])) {
        return node;
      }
    }
    return null;
  }

  function findHeadingCard(pattern) {
    var headings = document.querySelectorAll("h1,h2,h3,h4,h5,legend,strong");
    for (var i = 0; i < headings.length; i += 1) {
      if (pattern.test(cleanText(headings[i].textContent))) {
        var card = closestProfileCard(headings[i]);
        if (card) return card;
      }
    }
    return null;
  }

  function findLocalSettingsCard() {
    var byId = document.getElementById("profileLocalFirstSettings");
    var card = byId ? closestProfileCard(byId) : null;
    return card || findHeadingCard(/^Local settings$/i) || findHeadingCard(/Choose companion/i);
  }

  function findAnkiCard() {
    return findHeadingCard(/^Anki$/i) || findHeadingCard(/Choose your Anki collection/i);
  }

  function likelyProfileGrid(localCard, ankiCard) {
    if (localCard && ankiCard && localCard.parentElement && localCard.parentElement === ankiCard.parentElement) {
      return localCard.parentElement;
    }
    if (localCard && localCard.parentElement) return localCard.parentElement;
    if (ankiCard && ankiCard.parentElement) return ankiCard.parentElement;
    var profileRoot = document.querySelector("#profilePrivateApp, #profileApp, [data-apc-profile-root], main");
    return profileRoot || null;
  }

  function sameOrContains(a, b) {
    return Boolean(a && b && (a === b || a.contains(b)));
  }

  function copyCardClasses(referenceCard, panel) {
    if (!referenceCard || !panel) return;
    Array.prototype.forEach.call(referenceCard.classList || [], function (className) {
      if (className && !/^apc-profile-backup/.test(className)) {
        panel.classList.add(className);
      }
    });
  }

  function placeBackupFolderCard() {
    var panel = document.querySelector(PANEL_SELECTOR);
    if (!panel) return false;

    var localCard = findLocalSettingsCard();
    var ankiCard = findAnkiCard();
    var grid = likelyProfileGrid(localCard, ankiCard);
    if (!grid) return false;

    if (sameOrContains(panel, localCard) || sameOrContains(panel, ankiCard)) return false;

    copyCardClasses(localCard || ankiCard, panel);
    panel.classList.add("private-card", "apc-profile-backup-folder-card", "apc-profile-local-backup-folder-card", "apc-profile-backup-folder-card-placed");
    panel.setAttribute(RUN_ATTR, "true");
    panel.setAttribute("data-apc-marker", MARKER);
    panel.removeAttribute("style");

    var inserted = false;
    if (ankiCard && ankiCard.parentElement === grid && panel !== ankiCard) {
      grid.insertBefore(panel, ankiCard);
      inserted = true;
    } else if (localCard && localCard.parentElement === grid && panel !== localCard) {
      if (localCard.nextSibling) grid.insertBefore(panel, localCard.nextSibling);
      else grid.appendChild(panel);
      inserted = true;
    } else if (panel.parentElement !== grid) {
      grid.appendChild(panel);
      inserted = true;
    }

    var buttons = panel.querySelectorAll("button");
    Array.prototype.forEach.call(buttons, function (button) {
      button.classList.add("apc-profile-backup-folder-button");
    });

    window.APC_PROFILE_BACKUP_FOLDER_CARD_PLACEMENT_FIX_R16CF_STATE = {
      marker: MARKER,
      placed: true,
      inserted: inserted,
      parentClassName: panel.parentElement ? panel.parentElement.className : "",
      panelClassName: panel.className
    };
    return true;
  }

  function schedule() {
    placeBackupFolderCard();
    [40, 120, 300, 700, 1200, 2000].forEach(function (delay) {
      window.setTimeout(placeBackupFolderCard, delay);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", schedule, { once: true });
  } else {
    schedule();
  }
  document.addEventListener("apc-private-page-rendered", function (event) {
    if (!event.detail || event.detail.page === "profile") schedule();
  });
  if (window.MutationObserver) {
    var pending = false;
    var observer = new MutationObserver(function () {
      if (pending) return;
      pending = true;
      window.setTimeout(function () {
        pending = false;
        placeBackupFolderCard();
      }, 40);
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
  }

  window.APC_PROFILE_BACKUP_FOLDER_CARD_PLACEMENT_FIX_R16CF = {
    marker: MARKER,
    place: placeBackupFolderCard,
    status: function () {
      var panel = document.querySelector(PANEL_SELECTOR);
      return {
        marker: MARKER,
        panelFound: Boolean(panel),
        placed: Boolean(panel && panel.getAttribute(RUN_ATTR) === "true"),
        parentClassName: panel && panel.parentElement ? panel.parentElement.className : "",
        panelClassName: panel ? panel.className : ""
      };
    }
  };
}());
