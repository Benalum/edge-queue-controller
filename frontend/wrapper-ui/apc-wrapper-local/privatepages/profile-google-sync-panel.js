/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_START */
(function apcProfileGoogleSyncPanelStage17kZr6c() {
  const marker = 'APC_GOOGLE_SYNC_PROFILE_MODULE_MARKER_STAGE_17K_Z_R6C';
  const panelId = 'apc-google-sync-profile-panel-stage-17k-z-r6c';
  const styleId = 'apc-google-sync-profile-style-stage-17k-z-r6c';
  const apiName = 'APC_PROFILE_GOOGLE_SYNC_PANEL_STAGE_17K_Z_R6C';

  const officialLibraryDecision = Object.freeze({
    auth: 'Google Identity Services JavaScript authorization client',
    drive: 'Google Drive REST API',
    picker: 'Google Picker for user-selected files and folders',
    preferredScope: 'drive.file',
    oauthActivated: false,
    driveReadsEnabled: false,
    driveWritesEnabled: false
  });

  function isProfileSurface() {
    const path = String(window.location && window.location.pathname || '').toLowerCase();
    const hash = String(window.location && window.location.hash || '').toLowerCase();
    const title = String(document.title || '').toLowerCase();
    const body = document.body;
    const profileHints = [
      '[data-apc-profile-root]',
      '[data-profile-root]',
      '[data-page="profile"]',
      '[data-route="profile"]',
      '.profile-page',
      '#profile',
      '#profile-page'
    ];
    const hasProfileNode = profileHints.some((selector) => Boolean(document.querySelector(selector)));
    const bodyLooksProfile = body && String(body.getAttribute('data-page') || body.className || '').toLowerCase().includes('profile');
    return path.includes('profile') || hash.includes('profile') || title.includes('profile') || hasProfileNode || bodyLooksProfile;
  }

  function installStyle() {
    if (document.getElementById(styleId)) return;
    const style = document.createElement('style');
    style.id = styleId;
    style.textContent = [
      '.apc-google-sync-profile-panel { margin-top: 16px; padding: 16px; border: 1px solid rgba(148,163,184,.35); border-radius: 14px; background: rgba(15,23,42,.04); }',
      '.apc-google-sync-profile-panel h3 { margin: 0 0 8px; font-size: 1.05rem; }',
      '.apc-google-sync-profile-panel p { margin: 6px 0; line-height: 1.45; }',
      '.apc-google-sync-profile-panel .apc-google-sync-status { display: inline-flex; align-items: center; gap: 8px; margin: 8px 0 12px; font-weight: 700; }',
      '.apc-google-sync-profile-panel .apc-google-sync-dot { width: 9px; height: 9px; border-radius: 999px; background: #94a3b8; display: inline-block; }',
      '.apc-google-sync-profile-panel .apc-google-sync-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 12px; }',
      '.apc-google-sync-profile-panel button { border: 0; border-radius: 999px; padding: 10px 14px; font-weight: 700; cursor: not-allowed; opacity: .7; }',
      '.apc-google-sync-profile-panel small { display: block; margin-top: 10px; opacity: .8; }'
    ].join('\n');
    document.head.appendChild(style);
  }

  function findProfileAnchor() {
    const selectors = [
      '[data-apc-profile-root]',
      '[data-profile-root]',
      '[data-page="profile"]',
      '[data-route="profile"]',
      '.profile-page',
      '#profile',
      '#profile-page',
      'main',
      '#app',
      'body'
    ];
    for (const selector of selectors) {
      const node = document.querySelector(selector);
      if (node) return node;
    }
    return document.body;
  }

  function renderPanel() {
    if (!document.body || !isProfileSurface()) return;
    if (document.getElementById(panelId)) return;
    installStyle();
    const panel = document.createElement('section');
    panel.id = panelId;
    panel.className = 'apc-google-sync-profile-panel';
    panel.setAttribute('data-apc-google-sync-profile-panel', 'true');
    panel.setAttribute('data-apc-google-sync-profile-only', 'true');
    panel.setAttribute('data-apc-google-sync-oauth-active', 'false');
    panel.setAttribute('data-apc-google-sync-drive-reads', 'false');
    panel.setAttribute('data-apc-google-sync-drive-writes', 'false');
    panel.setAttribute('data-apc-google-sync-official-auth-library', officialLibraryDecision.auth);
    panel.setAttribute('data-apc-google-sync-official-drive-library', officialLibraryDecision.drive);
    panel.setAttribute('data-apc-marker', marker);
    panel.innerHTML = [
      '<h3>Google Drive sync</h3>',
      '<p>Keep your APC-native decks, study sessions, history, and stats in user-owned Google Drive storage.</p>',
      '<div class="apc-google-sync-status"><span class="apc-google-sync-dot" aria-hidden="true"></span><span>Not connected</span></div>',
      '<div class="apc-google-sync-actions"><button type="button" disabled aria-disabled="true">Connect Google Drive</button><button type="button" disabled aria-disabled="true">Sync now</button></div>',
      '<small>Profile-only preview. OAuth is not enabled yet, and this build performs no Drive reads or writes. The next implementation should use the official Google browser libraries.</small>'
    ].join('');
    findProfileAnchor().appendChild(panel);
  }

  function install() {
    renderPanel();
    window.setTimeout(renderPanel, 50);
    window.setTimeout(renderPanel, 250);
    window.setTimeout(renderPanel, 750);
  }

  window[apiName] = Object.freeze({
    install,
    marker,
    officialLibraryDecision,
    oauthActivated: false,
    driveReadsEnabled: false,
    driveWritesEnabled: false
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', install, { once: true });
  } else {
    install();
  }
  window.addEventListener('hashchange', install);
  window.addEventListener('popstate', install);
  document.addEventListener('apc:privatepage:rendered', install);
})();
/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_END */
