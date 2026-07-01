/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_START */
(function apcProfileGoogleSyncPanelStage17kZr7cAppdata() {
  const marker = 'APC_GOOGLE_SYNC_PROFILE_MODULE_MARKER_STAGE_17K_Z_R6C';
  const liveMarker = 'APC_GOOGLE_SYNC_PROFILE_APPDATA_BOUNDARY_STAGE_17K_Z_R7C';
  const panelId = 'apc-google-sync-profile-panel-stage-17k-z-r7c-appdata';
  const styleId = 'apc-google-sync-profile-style-stage-17k-z-r7c-appdata';
  const apiName = 'APC_PROFILE_GOOGLE_SYNC_PANEL_STAGE_17K_Z_R6C';
  const tokenScope = 'https://www.googleapis.com/auth/drive.appdata';
  const appDataSpace = 'appDataFolder';
  const gisScriptUrl = 'https://accounts.google.com/gsi/client';
  const driveUploadUrl = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,createdTime,spaces';
  const driveFilesUrl = 'https://www.googleapis.com/drive/v3/files';
  const sessionKey = 'apcGoogleSyncAppDataProofStage17kZr7c';

  const officialLibraryDecision = Object.freeze({
    auth: 'Google Identity Services JavaScript authorization client',
    drive: 'Google Drive REST API',
    picker: 'Google Picker only for future visible-folder mode, not hidden app data mode',
    preferredScope: tokenScope,
    storageSpace: appDataSpace,
    oauthActivated: true,
    driveReadsEnabled: true,
    driveWritesEnabled: true,
    profileOnly: true,
    explicitConsentRequired: true,
    userVisibleDriveFolder: false,
    canBrowseUserDrive: false
  });

  let accessToken = '';
  let tokenClient = null;
  let manifestFileId = '';
  let databaseFileId = '';

  function readSessionState() {
    try {
      const raw = window.sessionStorage && window.sessionStorage.getItem(sessionKey);
      return raw ? JSON.parse(raw) : {};
    } catch (_err) {
      return {};
    }
  }

  function writeSessionState(next) {
    try {
      const current = readSessionState();
      window.sessionStorage && window.sessionStorage.setItem(sessionKey, JSON.stringify(Object.assign({}, current, next)));
    } catch (_err) {
      /* best effort only; never store tokens here */
    }
  }

  function getConfiguredClientId() {
    const fromWindow = window.APC_GOOGLE_SYNC_CONFIG && window.APC_GOOGLE_SYNC_CONFIG.googleClientId;
    const fromMeta = document.querySelector('meta[name="apc-google-client-id"]');
    const value = fromWindow || (fromMeta && fromMeta.content) || '';
    return String(value || '').trim();
  }

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
      '.apc-google-sync-profile-panel label { display: block; margin: 10px 0; line-height: 1.35; }',
      '.apc-google-sync-profile-panel input[type="checkbox"] { margin-right: 8px; }',
      '.apc-google-sync-profile-panel .apc-google-sync-status { display: inline-flex; align-items: center; gap: 8px; margin: 8px 0 12px; font-weight: 700; }',
      '.apc-google-sync-profile-panel .apc-google-sync-dot { width: 9px; height: 9px; border-radius: 999px; background: #94a3b8; display: inline-block; }',
      '.apc-google-sync-profile-panel .apc-google-sync-actions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 12px; }',
      '.apc-google-sync-profile-panel button { border: 0; border-radius: 999px; padding: 10px 14px; font-weight: 700; cursor: pointer; }',
      '.apc-google-sync-profile-panel button:disabled { cursor: not-allowed; opacity: .55; }',
      '.apc-google-sync-profile-panel small { display: block; margin-top: 10px; opacity: .8; }',
      '.apc-google-sync-profile-panel pre { white-space: pre-wrap; overflow-wrap: anywhere; padding: 10px; border-radius: 10px; background: rgba(15,23,42,.08); }'
    ].join('\n');
    document.head.appendChild(style);
  }

  function findProfileAnchor() {
    const selectors = [
      '[data-apc-profile-google-sync-host]',
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

  function setStatus(message, detail) {
    const status = document.querySelector('[data-apc-google-sync-status-text]');
    const detailNode = document.querySelector('[data-apc-google-sync-proof-detail]');
    if (status) status.textContent = message;
    if (detailNode && typeof detail !== 'undefined') detailNode.textContent = detail ? String(detail) : '';
  }

  function consentChecked() {
    const checkbox = document.querySelector('[data-apc-google-sync-explicit-consent]');
    return Boolean(checkbox && checkbox.checked);
  }

  function updateButtons() {
    const configured = Boolean(getConfiguredClientId());
    const consent = consentChecked();
    const connect = document.querySelector('[data-apc-google-sync-connect]');
    const bootstrap = document.querySelector('[data-apc-google-sync-bootstrap-appdata]');
    const list = document.querySelector('[data-apc-google-sync-list-appdata]');
    const rollback = document.querySelector('[data-apc-google-sync-rollback-appdata-proof]');
    if (connect) connect.disabled = !(configured && consent);
    if (bootstrap) bootstrap.disabled = !(configured && consent && accessToken);
    if (list) list.disabled = !(configured && consent && accessToken);
    if (rollback) rollback.disabled = !(configured && consent && accessToken && (manifestFileId || databaseFileId));
  }

  function loadGoogleIdentityServices() {
    return new Promise((resolve, reject) => {
      if (window.google && window.google.accounts && window.google.accounts.oauth2) {
        resolve();
        return;
      }
      const existing = document.querySelector('script[data-apc-google-identity-services="true"]');
      if (existing) {
        existing.addEventListener('load', () => resolve(), { once: true });
        existing.addEventListener('error', () => reject(new Error('Google Identity Services failed to load')), { once: true });
        return;
      }
      const script = document.createElement('script');
      script.src = gisScriptUrl;
      script.async = true;
      script.defer = true;
      script.setAttribute('data-apc-google-identity-services', 'true');
      script.onload = () => resolve();
      script.onerror = () => reject(new Error('Google Identity Services failed to load'));
      document.head.appendChild(script);
    });
  }

  async function connectGoogleDrive() {
    const clientId = getConfiguredClientId();
    if (!clientId) {
      setStatus('Missing Google client ID', 'Set window.APC_GOOGLE_SYNC_CONFIG.googleClientId or a meta tag named apc-google-client-id.');
      updateButtons();
      return;
    }
    if (!consentChecked()) {
      setStatus('Consent required', 'Check the explicit consent box first.');
      updateButtons();
      return;
    }
    setStatus('Opening Google consent...', 'Requesting hidden app data access only. APC will not browse your Drive.');
    await loadGoogleIdentityServices();
    tokenClient = window.google.accounts.oauth2.initTokenClient({
      client_id: clientId,
      scope: tokenScope,
      prompt: 'consent',
      callback: (response) => {
        if (!response || response.error || !response.access_token) {
          setStatus('Google consent failed', response && response.error ? response.error : 'No access token returned.');
          updateButtons();
          return;
        }
        accessToken = response.access_token;
        setStatus('Connected for this browser session', 'Token is held in memory only. APC can use its hidden appDataFolder, not your normal Drive folders.');
        updateButtons();
      }
    });
    tokenClient.requestAccessToken({ prompt: 'consent' });
  }

  function makeMultipartBody(metadata, content) {
    const boundary = 'apc_google_sync_boundary_' + Math.random().toString(36).slice(2);
    const delimiter = '--' + boundary;
    const closeDelimiter = '--' + boundary + '--';
    const body = [
      delimiter,
      'Content-Type: application/json; charset=UTF-8',
      '',
      JSON.stringify(metadata),
      delimiter,
      'Content-Type: application/json; charset=UTF-8',
      '',
      JSON.stringify(content, null, 2),
      closeDelimiter
    ].join('\r\n');
    return { boundary, body };
  }

  async function createAppDataJsonFile(name, content) {
    const metadata = {
      name,
      mimeType: 'application/json',
      parents: [appDataSpace]
    };
    const multipart = makeMultipartBody(metadata, content);
    const response = await fetch(driveUploadUrl, {
      method: 'POST',
      headers: {
        Authorization: 'Bearer ' + accessToken,
        'Content-Type': 'multipart/related; boundary=' + multipart.boundary
      },
      body: multipart.body
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || !result.id) {
      throw new Error(JSON.stringify(result, null, 2));
    }
    return result;
  }

  async function bootstrapHiddenAppDatabase() {
    if (!accessToken) {
      setStatus('Connect first', 'Google consent is required before creating hidden APC app data.');
      return;
    }
    if (!consentChecked()) {
      setStatus('Consent required', 'Check the explicit consent box first.');
      return;
    }

    const createdAt = new Date().toISOString();
    setStatus('Creating hidden APC app data...', 'Creating manifest and database bootstrap in Google Drive appDataFolder.');

    const manifest = await createAppDataJsonFile('apc-google-sync-manifest.json', {
      record_type: 'apc_google_sync_manifest',
      stage: '17K-Z-R7C',
      created_at: createdAt,
      storage_space: appDataSpace,
      visibility: 'hidden_app_data_folder',
      user_visible_drive_folder: false,
      can_browse_user_drive: false,
      files: {
        database: 'apc-google-sync-database.json'
      }
    });

    const database = await createAppDataJsonFile('apc-google-sync-database.json', {
      record_type: 'apc_google_sync_database',
      schema_version: 1,
      stage: '17K-Z-R7C',
      created_at: createdAt,
      storage_space: appDataSpace,
      decks: [],
      sessions: [],
      history: [],
      stats: {},
      anki_upload_default: false
    });

    manifestFileId = manifest.id;
    databaseFileId = database.id;
    writeSessionState({ manifestFileId, databaseFileId, lastBootstrapAt: createdAt });

    setStatus('Hidden APC app data created', JSON.stringify({ manifest, database }, null, 2));
    updateButtons();
  }

  async function listHiddenAppDataFiles() {
    if (!accessToken) {
      setStatus('Connect first', 'Google consent is required before reading hidden APC app data metadata.');
      return;
    }
    const url = driveFilesUrl + '?spaces=appDataFolder&fields=files(id,name,mimeType,createdTime,modifiedTime,spaces)';
    setStatus('Reading hidden APC app data metadata...', appDataSpace);
    const response = await fetch(url, {
      method: 'GET',
      headers: { Authorization: 'Bearer ' + accessToken }
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok) {
      setStatus('Hidden app data metadata read failed', JSON.stringify(result, null, 2));
      return;
    }
    setStatus('Hidden APC app data metadata read succeeded', JSON.stringify(result, null, 2));
  }

  async function rollbackHiddenAppDataProof() {
    const state = readSessionState();
    const ids = [manifestFileId || state.manifestFileId, databaseFileId || state.databaseFileId].filter(Boolean);
    if (!accessToken || ids.length === 0) {
      setStatus('Nothing to roll back', 'Connect and create the hidden app data proof first.');
      return;
    }

    const results = [];
    for (const fileId of ids) {
      const response = await fetch(driveFilesUrl + '/' + encodeURIComponent(fileId), {
        method: 'DELETE',
        headers: { Authorization: 'Bearer ' + accessToken }
      });
      results.push({ fileId, ok: response.ok || response.status === 404, status: response.status });
    }

    manifestFileId = '';
    databaseFileId = '';
    writeSessionState({ manifestFileId: '', databaseFileId: '', lastRollbackAt: new Date().toISOString() });
    setStatus('Rollback complete', JSON.stringify(results, null, 2));
    updateButtons();
  }

  function renderPanel() {
    if (!document.body || !isProfileSurface()) return;
    if (document.getElementById(panelId)) return;
    installStyle();

    const state = readSessionState();
    manifestFileId = state.manifestFileId || manifestFileId || '';
    databaseFileId = state.databaseFileId || databaseFileId || '';

    const configured = Boolean(getConfiguredClientId());
    const panel = document.createElement('section');
    panel.id = panelId;
    panel.className = 'apc-google-sync-profile-panel';
    panel.setAttribute('data-apc-google-sync-profile-panel', 'true');
    panel.setAttribute('data-apc-google-sync-profile-only', 'true');
    panel.setAttribute('data-apc-google-sync-oauth-active', 'appdata-explicit-consent-only');
    panel.setAttribute('data-apc-google-sync-drive-reads', 'appdata-explicit-consent-only');
    panel.setAttribute('data-apc-google-sync-drive-writes', 'appdata-explicit-consent-only');
    panel.setAttribute('data-apc-google-sync-scope', tokenScope);
    panel.setAttribute('data-apc-google-sync-storage-space', appDataSpace);
    panel.setAttribute('data-apc-google-sync-user-visible-folder', 'false');
    panel.setAttribute('data-apc-marker', liveMarker);
    panel.innerHTML = [
      '<h3>Google Drive sync</h3>',
      '<p>Buddies Who Study will only create and manage its own hidden Google Drive app data. It will not browse, read, or modify your other Drive files or folders.</p>',
      '<div class="apc-google-sync-status"><span class="apc-google-sync-dot" aria-hidden="true"></span><span data-apc-google-sync-status-text>' + (configured ? 'Ready for explicit consent' : 'Google client ID not configured') + '</span></div>',
      '<label><input type="checkbox" data-apc-google-sync-explicit-consent> I understand APC will create hidden app data in my Google Drive for APC-native decks, sessions, history, and stats. APC will not upload Anki files unless I explicitly choose an import/convert option later.</label>',
      '<div class="apc-google-sync-actions">',
      '<button type="button" data-apc-google-sync-connect>Connect Google Drive</button>',
      '<button type="button" data-apc-google-sync-bootstrap-appdata>Create hidden APC sync database</button>',
      '<button type="button" data-apc-google-sync-list-appdata>Read APC app data metadata</button>',
      '<button type="button" data-apc-google-sync-rollback-appdata-proof>Rollback/delete APC proof files</button>',
      '</div>',
      '<small>Scope: drive.appdata. Storage: appDataFolder. Token is kept in memory only. No backend queue, no DB write, and no broad Drive access.</small>',
      '<pre data-apc-google-sync-proof-detail></pre>'
    ].join('');

    findProfileAnchor().appendChild(panel);
    panel.querySelector('[data-apc-google-sync-explicit-consent]').addEventListener('change', updateButtons);
    panel.querySelector('[data-apc-google-sync-connect]').addEventListener('click', () => connectGoogleDrive().catch((err) => setStatus('Google connection error', err.message || String(err))));
    panel.querySelector('[data-apc-google-sync-bootstrap-appdata]').addEventListener('click', () => bootstrapHiddenAppDatabase().catch((err) => setStatus('Hidden app data create error', err.message || String(err))));
    panel.querySelector('[data-apc-google-sync-list-appdata]').addEventListener('click', () => listHiddenAppDataFiles().catch((err) => setStatus('Hidden app data read error', err.message || String(err))));
    panel.querySelector('[data-apc-google-sync-rollback-appdata-proof]').addEventListener('click', () => rollbackHiddenAppDataProof().catch((err) => setStatus('Rollback error', err.message || String(err))));
    updateButtons();
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
    liveMarker,
    officialLibraryDecision,
    scope: tokenScope,
    storageSpace: appDataSpace,
    profileOnly: true,
    explicitConsentRequired: true
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', install, { once: true });
  } else {
    install();
  }
  window.addEventListener('hashchange', install);
  window.addEventListener('popstate', install);
  document.addEventListener('apc-private-page-rendered', install);
})();
/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_END */
