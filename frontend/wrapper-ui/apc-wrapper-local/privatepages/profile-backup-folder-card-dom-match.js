(function () {
  "use strict";

  var MARKER = "APC_PROFILE_BACKUP_FOLDER_CARD_DOM_MATCH_R16CE_R3";
  var STYLE_ID = "apc-profile-backup-folder-card-dom-match-r16ce-r3-style";
  var RUN_ATTR = "data-apc-profile-backup-card-matched";

  function text(el) {
    return ((el && el.textContent) || "").replace(/\s+/g, " ").trim();
  }

  function closestUsefulCard(node) {
    if (!node) return null;
    return node.closest(
      ".private-card, .profile-card, .local-profile-card, .profile-section, .settings-card, .apc-profile-card, .apc-card, section, article, .card, .panel, .private-panel, .profile-panel, div"
    );
  }

  function hasHeadingText(el, matcher) {
    if (!el) return false;
    var headings = el.querySelectorAll("h1,h2,h3,h4,h5,legend,strong");
    for (var i = 0; i < headings.length; i += 1) {
      if (matcher.test(text(headings[i]))) return true;
    }
    return matcher.test(text(el).slice(0, 160));
  }

  function findCardByTitle(matcher) {
    var headingNodes = document.querySelectorAll("h1,h2,h3,h4,h5,legend,strong");
    for (var i = 0; i < headingNodes.length; i += 1) {
      if (matcher.test(text(headingNodes[i]))) {
        return closestUsefulCard(headingNodes[i]);
      }
    }

    var blocks = document.querySelectorAll(".private-card, .profile-card, .local-profile-card, .profile-section, .settings-card, .apc-profile-card, section, article, .card, .panel, div");
    for (var j = 0; j < blocks.length; j += 1) {
      if (hasHeadingText(blocks[j], matcher)) return blocks[j];
    }
    return null;
  }

  function copyClasses(fromEl, toEl) {
    if (!fromEl || !toEl) return;
    Array.prototype.forEach.call(fromEl.classList || [], function (className) {
      if (className && !/^apc-profile-backup/.test(className)) {
        toEl.classList.add(className);
      }
    });
  }

  function findReferenceButton(referenceCard, backupCard) {
    var button = referenceCard && referenceCard.querySelector("button, .button, .btn, [role='button']");
    if (button && !backupCard.contains(button)) return button;
    var buttons = document.querySelectorAll("button, .button, .btn, [role='button']");
    for (var i = 0; i < buttons.length; i += 1) {
      if (!backupCard.contains(buttons[i])) return buttons[i];
    }
    return null;
  }

  function injectFallbackStyle() {
    if (document.getElementById(STYLE_ID)) return;
    var style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = "\n" +
      "/* " + MARKER + " fallback */\n" +
      ".apc-profile-backup-folder-card,\n" +
      ".apc-profile-local-backup-folder-card {\n" +
      "  background: #fff;\n" +
      "  border: 1px solid rgba(36, 52, 45, 0.14);\n" +
      "  border-radius: 22px;\n" +
      "  box-shadow: 0 14px 38px rgba(31, 45, 38, 0.08);\n" +
      "  padding: 1.25rem;\n" +
      "  margin: 1rem 0;\n" +
      "  color: inherit;\n" +
      "}\n" +
      ".apc-profile-backup-folder-card h2,\n" +
      ".apc-profile-backup-folder-card h3,\n" +
      ".apc-profile-local-backup-folder-card h2,\n" +
      ".apc-profile-local-backup-folder-card h3 {\n" +
      "  margin-top: 0;\n" +
      "  margin-bottom: 0.45rem;\n" +
      "  color: #173c30;\n" +
      "}\n" +
      ".apc-profile-backup-folder-card p,\n" +
      ".apc-profile-local-backup-folder-card p {\n" +
      "  color: rgba(31, 45, 38, 0.76);\n" +
      "}\n" +
      ".apc-profile-backup-folder-card button,\n" +
      ".apc-profile-local-backup-folder-card button {\n" +
      "  border: 1px solid rgba(32, 93, 74, 0.28);\n" +
      "  border-radius: 999px;\n" +
      "  padding: 0.65rem 1rem;\n" +
      "  background: #f5fbf8;\n" +
      "  color: #173c30;\n" +
      "  font-weight: 700;\n" +
      "  cursor: pointer;\n" +
      "  margin: 0.25rem 0.35rem 0.25rem 0;\n" +
      "}\n" +
      ".apc-profile-backup-folder-card button:hover,\n" +
      ".apc-profile-local-backup-folder-card button:hover {\n" +
      "  background: #e9f7f1;\n" +
      "}\n" +
      ".apc-profile-backup-folder-card input[type='file'],\n" +
      ".apc-profile-local-backup-folder-card input[type='file'] {\n" +
      "  display: inline-block;\n" +
      "  margin: 0.35rem 0;\n" +
      "}\n" +
      ".apc-profile-backup-folder-card [class*='status'],\n" +
      ".apc-profile-backup-folder-card [class*='summary'],\n" +
      ".apc-profile-local-backup-folder-card [class*='status'],\n" +
      ".apc-profile-local-backup-folder-card [class*='summary'] {\n" +
      "  margin-top: 0.9rem;\n" +
      "  border-radius: 16px;\n" +
      "  background: rgba(245, 251, 248, 0.95);\n" +
      "  border: 1px solid rgba(36, 52, 45, 0.10);\n" +
      "  padding: 0.9rem;\n" +
      "}\n";
    document.head.appendChild(style);
  }

  function matchBackupFolderCard() {
    injectFallbackStyle();

    var backupCard = findCardByTitle(/^Local backup folder$/i) || findCardByTitle(/Local backup folder/i);
    if (!backupCard) return false;

    var localSettingsCard = findCardByTitle(/^Local settings$/i) || findCardByTitle(/Choose companion/i);
    var ankiCard = findCardByTitle(/^Anki$/i) || findCardByTitle(/Choose your Anki collection/i);
    var referenceCard = localSettingsCard || ankiCard;

    if (referenceCard && referenceCard !== backupCard) {
      copyClasses(referenceCard, backupCard);
    }

    backupCard.classList.add("apc-profile-backup-folder-card", "apc-profile-local-backup-folder-card");
    backupCard.setAttribute(RUN_ATTR, "true");
    backupCard.setAttribute("data-apc-marker", MARKER);

    var referenceButton = findReferenceButton(referenceCard, backupCard);
    var buttons = backupCard.querySelectorAll("button");
    Array.prototype.forEach.call(buttons, function (button) {
      if (referenceButton) copyClasses(referenceButton, button);
      button.classList.add("apc-profile-backup-folder-button");
    });

    var fileInputs = backupCard.querySelectorAll("input[type='file']");
    Array.prototype.forEach.call(fileInputs, function (input) {
      input.classList.add("apc-profile-backup-folder-file-input");
    });

    return true;
  }

  function scheduleMatches() {
    matchBackupFolderCard();
    [50, 150, 350, 700, 1200, 2000].forEach(function (ms) {
      window.setTimeout(matchBackupFolderCard, ms);
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", scheduleMatches, { once: true });
  } else {
    scheduleMatches();
  }

  if (window.MutationObserver) {
    var observer = new MutationObserver(function () {
      matchBackupFolderCard();
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
  }

  window.APC_PROFILE_BACKUP_FOLDER_CARD_DOM_MATCH_R16CE_R3 = {
    marker: MARKER,
    match: matchBackupFolderCard,
    status: function () {
      var card = document.querySelector("[" + RUN_ATTR + "='true']");
      return {
        marker: MARKER,
        matched: Boolean(card),
        className: card ? card.className : "",
        hasFallbackStyle: Boolean(document.getElementById(STYLE_ID))
      };
    }
  };
}());
