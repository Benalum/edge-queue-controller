(function () {
  'use strict';

  var MARKER = 'APC_PROFILE_ACCORDION_INPUT_POLISH_R16CG_R3';
  window[MARKER] = true;

  function textOf(el) {
    return (el && el.textContent ? el.textContent : '').replace(/\s+/g, ' ').trim();
  }

  function lowerText(el) {
    return textOf(el).toLowerCase();
  }

  function isProfileRoute() {
    return String(window.location.pathname || '').replace(/\/+$/, '') === '/profile' || /Your profile/i.test(document.body ? document.body.textContent || '' : '');
  }

  function findProfileRoot() {
    return document.querySelector('[data-apc-profile-root]') ||
      document.querySelector('#privateApp') ||
      document.querySelector('main') ||
      document.body;
  }

  function usefulCardForText(root, needles) {
    var candidates = Array.prototype.slice.call(root.querySelectorAll('section, article, .private-card, .profile-card, .apc-profile-card, .local-profile-card, div'));
    var best = null;
    var bestScore = -1;
    candidates.forEach(function (el) {
      var t = lowerText(el);
      var hit = needles.some(function (needle) { return t.indexOf(needle) !== -1; });
      if (!hit) return;
      var len = t.length;
      var score = 0;
      if (el.className && /card|panel|section|profile/i.test(String(el.className))) score += 1000;
      if (el.matches && el.matches('.private-card,.profile-card,.apc-profile-card,.local-profile-card,section,article')) score += 500;
      score -= Math.min(len, 5000) / 20;
      if (score > bestScore) {
        best = el;
        bestScore = score;
      }
    });
    return best;
  }

  function closestCardFromHeading(root, headingNeedles) {
    var headings = Array.prototype.slice.call(root.querySelectorAll('h1,h2,h3,h4,h5,h6,legend,strong,b'));
    for (var i = 0; i < headings.length; i += 1) {
      var t = lowerText(headings[i]);
      if (headingNeedles.some(function (needle) { return t.indexOf(needle) !== -1; })) {
        return headings[i].closest('.private-card,.profile-card,.apc-profile-card,.local-profile-card,section,article,div') || headings[i].parentElement;
      }
    }
    return null;
  }

  function makeAccordion(card, title, defaultOpen, storageKey) {
    if (!card || card.dataset.apcProfileAccordionReady === 'true') return false;
    card.dataset.apcProfileAccordionReady = 'true';
    card.classList.add('apc-profile-accordion-card');

    var body = document.createElement('div');
    body.className = 'apc-profile-accordion-body';
    body.id = 'apc-profile-accordion-body-' + storageKey.replace(/[^a-z0-9_-]/gi, '-');

    while (card.firstChild) {
      body.appendChild(card.firstChild);
    }

    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'apc-profile-accordion-toggle';
    btn.setAttribute('aria-controls', body.id);
    btn.innerHTML = '<span class="apc-profile-accordion-title"></span><span class="apc-profile-accordion-chevron" aria-hidden="true">⌄</span>';
    btn.querySelector('.apc-profile-accordion-title').textContent = title;

    var saved = null;
    try { saved = window.localStorage.getItem('apc.profile.accordion.' + storageKey); } catch (err) {}
    var open = saved === null ? !!defaultOpen : saved === 'open';

    function setOpen(next) {
      open = !!next;
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      body.hidden = !open;
      try { window.localStorage.setItem('apc.profile.accordion.' + storageKey, open ? 'open' : 'closed'); } catch (err) {}
    }

    btn.addEventListener('click', function () { setOpen(!open); });
    card.appendChild(btn);
    card.appendChild(body);
    setOpen(open);
    return true;
  }

  function normalizeInputsAndButtons(root) {
    Array.prototype.slice.call(root.querySelectorAll('input, textarea, select')).forEach(function (el) {
      el.classList.add('apc-profile-readable-input');
    });
    Array.prototype.slice.call(root.querySelectorAll('button')).forEach(function (btn) {
      if (!btn.classList.contains('apc-profile-accordion-toggle')) {
        btn.classList.add('apc-profile-unified-button');
      }
    });
  }

  function applyBackupPlacementHint(root) {
    var backup = usefulCardForText(root, ['local backup folder', 'pick backup folder', 'save current backup']);
    if (!backup) return;
    backup.classList.add('apc-profile-local-backup-folder-card', 'private-card');
  }

  function apply() {
    if (!isProfileRoute()) return;
    var root = findProfileRoot();
    if (!root) return;
    root.setAttribute('data-apc-profile-root', 'true');

    applyBackupPlacementHint(root);
    normalizeInputsAndButtons(root);

    var chooseCard = closestCardFromHeading(root, ['local settings', 'choose companion']) || usefulCardForText(root, ['choose companion', 'companion preset']);
    var backupCard = usefulCardForText(root, ['local backup folder', 'pick backup folder', 'save current backup']);
    var ankiCard = closestCardFromHeading(root, ['anki']);

    makeAccordion(chooseCard, 'Choose companion', true, 'choose-companion');
    makeAccordion(backupCard, 'Local backup folder', false, 'local-backup-folder');

    if (ankiCard && ankiCard !== chooseCard && ankiCard !== backupCard) {
      ankiCard.classList.add('private-card');
    }

    // Custom media is usually inside the Choose companion card. Add a small nested collapse if the heading is found.
    var mediaHeading = Array.prototype.slice.call(root.querySelectorAll('h2,h3,h4,strong,b,legend')).find(function (el) {
      return lowerText(el).indexOf('custom companion media') !== -1;
    });
    if (mediaHeading && !mediaHeading.dataset.apcMediaAccordionReady) {
      mediaHeading.dataset.apcMediaAccordionReady = 'true';
      var parent = mediaHeading.parentElement;
      if (parent) {
        var nested = document.createElement('div');
        nested.className = 'apc-profile-accordion-body apc-profile-nested-media-body';
        nested.id = 'apc-profile-custom-media-body';
        var toggle = document.createElement('button');
        toggle.type = 'button';
        toggle.className = 'apc-profile-accordion-toggle apc-profile-nested-accordion-toggle';
        toggle.setAttribute('aria-controls', nested.id);
        toggle.innerHTML = '<span class="apc-profile-accordion-title">Custom companion media</span><span class="apc-profile-accordion-chevron" aria-hidden="true">⌄</span>';
        mediaHeading.style.display = 'none';
        parent.insertBefore(toggle, mediaHeading);
        var cursor = mediaHeading.nextSibling;
        while (cursor) {
          var next = cursor.nextSibling;
          nested.appendChild(cursor);
          cursor = next;
        }
        parent.appendChild(nested);
        var open = false;
        function setNestedOpen(nextOpen) {
          open = !!nextOpen;
          toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
          nested.hidden = !open;
        }
        toggle.addEventListener('click', function () { setNestedOpen(!open); });
        setNestedOpen(false);
      }
    }
  }

  function schedule() {
    apply();
    window.setTimeout(apply, 150);
    window.setTimeout(apply, 600);
    window.setTimeout(apply, 1400);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', schedule);
  } else {
    schedule();
  }
  window.addEventListener('hashchange', schedule);
  window.addEventListener('popstate', schedule);
})();
