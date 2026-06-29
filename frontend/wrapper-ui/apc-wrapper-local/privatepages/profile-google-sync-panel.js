/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_START */
(function apcProfileGoogleSyncPanelStage17kZr7() {
  const marker = 'APC_GOOGLE_SYNC_PROFILE_MODULE_MARKER_STAGE_17K_Z_R6C';
  const liveMarker = 'APC_GOOGLE_SYNC_PROFILE_OAUTH_DRIVE_DEV_PROOF_STAGE_17K_Z_R7';
  const panelId = 'apc-google-sync-profile-panel-stage-17k-z-r7';
  const styleId = 'apc-google-sync-profile-style-stage-17k-z-r7';
  const apiName = 'APC_PROFILE_GOOGLE_SYNC_PANEL_STAGE_17K_Z_R6C';
  const tokenScope = 'https://www.googleapis.com/auth/drive.file';
  const gisScriptUrl = 'https://accounts.google.com/gsi/client';
  const driveUploadUrl = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name,webViewLink,createdTime';
  const driveFilesUrl = 'https://www.googleapis.com/drive/v3/files';
  const sessionKey = 'apcGoogleSyncDevProofStage17kZr7';

  const officialLibraryDecision = Object.freeze({
    auth: 'Google Identity Services JavaScript authorization client',
    drive: 'Google Drive REST API',
    picker: 'Google Picker for later user-selected files and folders',
    preferredScope: tokenScope,
    oauthActivated: true,
    driveReadsEnabled: true,
    driveWritesEnabled: true,
    profileOnly: true,
    explicitConsentRequired: true
  });

  let accessToken = '';
  let tokenClient = null;
  let lastTestFileId = '';

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
    const write = document.querySelector('[data-apc-google-sync-write-test]');
    const read = document.querySelector('[data-apc-google-sync-read-test]');
    const rollback = document.querySelector('[data-apc-google-sync-rollback-test]');
    if (connect) connect.disabled = !(configured && consent);
    if (write) write.disabled = !(configured && consent && accessToken);
    if (read) read.disabled = !(configured && consent && accessToken && lastTestFileId);
    if (rollback) rollback.disabled = !(configured && consent && accessToken && lastTestFileId);
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
    setStatus('Opening Google consent...', 'Requesting narrow drive.file access only.');
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
        setStatus('Connected for this browser session', 'Token is held in memory only. No refresh token is stored.');
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

  async function writeHarmlessTestFile() {
    if (!accessToken) {
      setStatus('Connect first', 'Google consent is required before writing the harmless test file.');
      return;
    }
    if (!consentChecked()) {
      setStatus('Consent required', 'Check the explicit consent box first.');
      return;
    }
    const createdAt = new Date().toISOString();
    const metadata = {
      name: 'APC GoogleSync Dev Proof ' + createdAt.replace(/[:.]/g, '-') + '.apc-test.json',
      mimeType: 'application/json'
    };
    const content = {
      record_type: 'apc_google_sync_dev_proof',
      stage: '17K-Z-R7',
      created_at: createdAt,
      harmless: true,
      purpose: 'Verify explicit-consent Google Drive file create path for APC Profile GoogleSync.',
      rollback: 'Use the Profile rollback button to delete this test file.'
    };
    const multipart = makeMultipartBody(metadata, content);
    setStatus('Writing harmless Drive test file...', metadata.name);
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
      setStatus('Drive test write failed', JSON.stringify(result, null, 2));
      updateButtons();
      return;
    }
    lastTestFileId = result.id;
    writeSessionState({ lastTestFileId, lastTestFileName: result.name || metadata.name, lastWriteAt: createdAt });
    setStatus('Drive test file created', JSON.stringify(result, null, 2));
    updateButtons();
  }

  async function readHarmlessTestFile() {
    const state = readSessionState();
    const fileId = lastTestFileId || state.lastTestFileId;
    if (!accessToken || !fileId) {
      setStatus('Nothing to read yet', 'Connect and create a test file first.');
      return;
    }
    const url = driveFilesUrl + '/' + encodeURIComponent(fileId) + '?fields=id,name,mimeType,createdTime,modifiedTime,webViewLink';
    setStatus('Reading Drive test file metadata...', fileId);
    const response = await fetch(url, {
      method: 'GET',
      headers: { Authorization: 'Bearer ' + accessToken }
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok) {
      setStatus('Drive test read failed', JSON.stringify(result, null, 2));
      return;
    }
    setStatus('Drive test file read succeeded', JSON.stringify(result, null, 2));
  }

  async function rollbackHarmlessTestFile() {
    const state = readSessionState();
    const fileId = lastTestFileId || state.lastTestFileId;
    if (!accessToken || !fileId) {
      setStatus('Nothing to roll back', 'Connect and create a test file first.');
      return;
    }
    setStatus('Deleting Drive test file...', fileId);
    const response = await fetch(driveFilesUrl + '/' + encodeURIComponent(fileId), {
      method: 'DELETE',
      headers: { Authorization: 'Bearer ' + accessToken }
    });
    if (!response.ok && response.status !== 404) {
      const result = await response.json().catch(() => ({}));
      setStatus('Rollback delete failed', JSON.stringify(result, null, 2));
      return;
    }
    lastTestFileId = '';
    writeSessionState({ lastTestFileId: '', lastRollbackAt: new Date().toISOString() });
    setStatus('Rollback complete', 'The APC GoogleSync dev proof test file was deleted or was already gone.');
    updateButtons();
  }

  function renderPanel() {
    if (!document.body || !isProfileSurface()) return;
    if (document.getElementById(panelId)) return;
    installStyle();
    const state = readSessionState();
    lastTestFileId = state.lastTestFileId || lastTestFileId || '';
    const configured = Boolean(getConfiguredClientId());
    const panel = document.createElement('section');
    panel.id = panelId;
    panel.className = 'apc-google-sync-profile-panel';
    panel.setAttribute('data-apc-google-sync-profile-panel', 'true');
    panel.setAttribute('data-apc-google-sync-profile-only', 'true');
    panel.setAttribute('data-apc-google-sync-oauth-active', 'dev-proof-explicit-consent-only');
    panel.setAttribute('data-apc-google-sync-drive-reads', 'dev-proof-explicit-consent-only');
    panel.setAttribute('data-apc-google-sync-drive-writes', 'dev-proof-explicit-consent-only');
    panel.setAttribute('data-apc-google-sync-scope', tokenScope);
    panel.setAttribute('data-apc-marker', liveMarker);
    panel.innerHTML = [
      '<h3>Google Drive sync</h3>',
      '<p>Profile-only developer proof using Google Identity Services and narrow Drive file access.</p>',
      '<div class="apc-google-sync-status"><span class="apc-google-sync-dot" aria-hidden="true"></span><span data-apc-google-sync-status-text>' + (configured ? 'Ready for explicit consent' : 'Google client ID not configured') + '</span></div>',
      '<label><input type="checkbox" data-apc-google-sync-explicit-consent> I understand this test can create one harmless APC test file in my Google Drive and the rollback button can delete that test file.</label>',
      '<div class="apc-google-sync-actions">',
      '<button type="button" data-apc-google-sync-connect>Connect Google Drive</button>',
      '<button type="button" data-apc-google-sync-write-test>Write harmless test file</button>',
      '<button type="button" data-apc-google-sync-read-test>Read test file metadata</button>',
      '<button type="button" data-apc-google-sync-rollback-test>Rollback/delete test file</button>',
      '</div>',
      '<small>Scope: drive.file. Token is kept in memory only. No backend queue, no DB write, and no broad Drive access.</small>',
      '<pre data-apc-google-sync-proof-detail></pre>'
    ].join('');
    findProfileAnchor().appendChild(panel);
    panel.querySelector('[data-apc-google-sync-explicit-consent]').addEventListener('change', updateButtons);
    panel.querySelector('[data-apc-google-sync-connect]').addEventListener('click', () => connectGoogleDrive().catch((err) => setStatus('Google connection error', err.message || String(err))));
    panel.querySelector('[data-apc-google-sync-write-test]').addEventListener('click', () => writeHarmlessTestFile().catch((err) => setStatus('Drive test write error', err.message || String(err))));
    panel.querySelector('[data-apc-google-sync-read-test]').addEventListener('click', () => readHarmlessTestFile().catch((err) => setStatus('Drive test read error', err.message || String(err))));
    panel.querySelector('[data-apc-google-sync-rollback-test]').addEventListener('click', () => rollbackHarmlessTestFile().catch((err) => setStatus('Rollback error', err.message || String(err))));
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
  document.addEventListener('apc:privatepage:rendered', install);
})();
/* APC_GOOGLE_SYNC_PROFILE_MODULE_STAGE_17K_Z_R6C_END */
