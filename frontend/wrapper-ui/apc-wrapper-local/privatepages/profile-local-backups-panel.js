/* APC_PROFILE_LOCAL_BACKUPS_PANEL_R12D_SOURCE_ONLY_START */
(function () {
  "use strict";

  const root = typeof window !== "undefined" ? window : globalThis;
  const MARKER = "APC_PROFILE_LOCAL_BACKUPS_PANEL_R12L_R2_RESTORED_CARD";
  const RESTORE_PREVIEW_BUTTON_MARKER_R12V = "APC_PROFILE_LOCAL_BACKUPS_RESTORE_PREVIEW_BUTTON_R12V";
  const MEDIA_AWARE_EXPORT_MARKER_R12W = "APC_PROFILE_LOCAL_BACKUPS_MEDIA_AWARE_EXPORT_R12W";
  const PANEL_TITLE = "Buddies Who Study local backups";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const BACKUP_VERSION = 1;
  const STUDY_NAMESPACE = "study";
  const STUDY_DOC_KEYS = [
    "study/cards/v1",
    "study/decks/v1",
    "study/progress/v1",
    "study/sessions/v1",
    "study/store-state/v1"
  ];

  function nowIso() {
    return new Date().toISOString();
  }

  function safeFileStamp(date) {
    return String(date || nowIso()).replace(/[:.]/g, "-");
  }

  function backupFileName(date) {
    return "buddies-who-study-local-backup-v2-" + safeFileStamp(date) + ".json";
  }

  function hasDirectoryPicker() {
    return Boolean(root && typeof root.showDirectoryPicker === "function");
  }

  function localSaveApi() {
    return root && root.APC_LOCAL_SAVE ? root.APC_LOCAL_SAVE : null;
  }

  function normalizeDocRecord(key, value) {
    return {
      key: key,
      value: value === undefined ? null : value
    };
  }

  async function readStudyDocsFromLocalSave(api) {
    const docs = [];
    if (!api) return docs;

    if (typeof api.readDoc === "function") {
      for (const key of STUDY_DOC_KEYS) {
        try {
          const value = await api.readDoc(key);
          if (value !== undefined && value !== null) docs.push(normalizeDocRecord(key, value));
        } catch (error) {
          docs.push({
            key: key,
            error: String(error && error.message ? error.message : error)
          });
        }
      }
      return docs;
    }

    if (typeof api.listDocs === "function") {
      const listed = await api.listDocs({ namespace: STUDY_NAMESPACE });
      if (Array.isArray(listed)) {
        return listed.map(function (item) {
          if (typeof item === "string") return normalizeDocRecord(item, null);
          if (item && typeof item === "object") {
            return {
              key: item.key || item.id || item.path || "unknown",
              value: item.value === undefined ? null : item.value,
              meta: item.meta || null
            };
          }
          return normalizeDocRecord("unknown", item);
        });
      }
    }

    return docs;
  }

  async function buildBackupPayload(options) {
    const opts = options || {};
    const api = opts.localSave || localSaveApi();
    const createdAt = nowIso();
    const docs = await readStudyDocsFromLocalSave(api);

    return {
      kind: BACKUP_KIND,
      version: BACKUP_VERSION,
      createdAt: createdAt,
      app: "Buddies Who Study",
      label: "Buddies Who Study local data",
      privacy: {
        uploadsToServer: false,
        modifiesAnkiSourceFiles: false,
        includesAnkiSourceFileBytes: false,
        intendedStorage: "user-selected local backup file"
      },
      namespaces: [STUDY_NAMESPACE],
      docs: docs
    };
  }

  function stringifyBackup(payload) {
    return JSON.stringify(payload, null, 2);
  }

  function createDownloadUrl(payload) {
    const blob = new Blob([stringifyBackup(payload)], { type: "application/json" });
    return URL.createObjectURL(blob);
  }

  async function writeBackupToDirectoryHandle(directoryHandle, payload, fileName) {
    if (!directoryHandle || typeof directoryHandle.getFileHandle !== "function") {
      throw new Error("Directory handle is not available.");
    }

    const name = fileName || backupFileName(payload && payload.createdAt);
    const fileHandle = await directoryHandle.getFileHandle(name, { create: true });
    const writable = await fileHandle.createWritable();
    await writable.write(stringifyBackup(payload));
    await writable.close();

    return {
      fileName: name,
      wroteLocalFile: true,
      uploadsToServer: false
    };
  }

  async function chooseFolderAndWriteBackup(options) {
    if (!hasDirectoryPicker()) {
      throw new Error("Folder picker is not supported in this browser. Use download backup instead.");
    }

    const payload = await buildBackupPayload(options);
    const directoryHandle = await root.showDirectoryPicker({
      id: "buddies-who-study-local-backups",
      mode: "readwrite"
    });

    return writeBackupToDirectoryHandle(directoryHandle, payload);
  }

  function createPreviewModel(options) {
    const supported = hasDirectoryPicker();
    return {
      marker: MARKER,
      title: PANEL_TITLE,
      folderPickerSupported: supported,
      backupKind: BACKUP_KIND,
      backupVersion: BACKUP_VERSION,
      copy: {
        intro: "Save your data locally.",
        privacy: "",
        warning: ""
      },
      actions: {
        chooseFolder: supported ? "Choose local backup folder" : "Folder picker not supported",
        downloadBackup: "Download backup file",
        previewRestore: "Preview backup file"
      }
    };
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function renderPreviewHtml(options) {
    const model = createPreviewModel(options);
    return [
      '<section class="private-card profile-card apc-profile-local-backups-panel" data-apc-profile-local-backups-panel="true">',
      '<h3>' + escapeHtml(model.title) + '</h3>',
      '<p class="apc-local-backup-short-copy">Save your data locally.</p>',
      '<div class="private-actions apc-local-backup-actions">',
      '<button type="button" data-apc-local-backup-choose-folder' + (model.folderPickerSupported ? "" : " disabled") + '>' + escapeHtml(model.actions.chooseFolder) + '</button>',
      '<button type="button" data-apc-local-backup-download>' + escapeHtml(model.actions.downloadBackup) + '</button>',
      '<button type="button" data-apc-local-backup-preview-restore>' + escapeHtml(model.actions.previewRestore) + '</button>',
      '</div>',
      '<pre data-apc-local-backup-restore-preview-output hidden></pre>',
      '<pre data-apc-local-backup-status hidden></pre>',
      '</section>'
    ].join("");
  }

  function mountPanel(host, options) {
    if (!host || typeof host.insertAdjacentHTML !== "function") {
      throw new Error("A valid host element is required.");
    }
    if (host.querySelector && host.querySelector("[data-apc-profile-local-backups-panel='true']")) {
      return host.querySelector("[data-apc-profile-local-backups-panel='true']");
    }
    host.insertAdjacentHTML("beforeend", renderPreviewHtml(options));
    return host.querySelector("[data-apc-profile-local-backups-panel='true']");
  }



  function legacyDocsArrayToObjectR12W(docs) {
    const out = {};
    if (!Array.isArray(docs)) return out;
    docs.forEach(function copyDoc(entry) {
      if (!entry || !entry.key) return;
      out[String(entry.key)] = entry.value === undefined ? null : entry.value;
    });
    return out;
  }

  function normalizeBackupPrivacyR12W(privacy) {
    const source = privacy && typeof privacy === "object" ? privacy : {};
    return Object.assign({}, source, {
      serverUpload: false,
      uploadsToServer: false,
      ankiSourceMutation: false,
      modifiesAnkiSourceFiles: false,
      sourceMutation: false,
      localOnly: true,
      includesAnkiSourceFileBytes: false,
      originalAnkiBytesIncluded: false
    });
  }

  function makeMediaAwareBackupPayloadR12W(payload, options) {
    const base = payload && typeof payload === "object" ? JSON.parse(JSON.stringify(payload)) : {};

    if (Array.isArray(base.docs)) {
      base.legacyDocs = base.docs;
      base.docs = legacyDocsArrayToObjectR12W(base.legacyDocs);
    } else if (!base.docs || typeof base.docs !== "object") {
      base.docs = {};
    }

    base.kind = base.kind || "buddies-who-study-local-backup";
    base.version = Math.max(Number(base.version || 1), 2);
    base.app = base.app || "Buddies Who Study";
    base.label = base.label || "Buddies Who Study local data";
    base.privacy = normalizeBackupPrivacyR12W(base.privacy);

    const exporter = root && root.APC_LOCAL_BACKUP_MEDIA_EXPORT;
    if (exporter && typeof exporter.augmentBackupPayload === "function") {
      return exporter.augmentBackupPayload(base, options || {});
    }

    const createdAt = base.createdAt || new Date().toISOString();
    const emptyPrivacy = normalizeBackupPrivacyR12W(base.privacy);
    const emptyDocs = {
      "study/media/v1": {
        kind: "buddies-who-study-media-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        items: [],
        privacy: emptyPrivacy
      },
      "study/media-blobs/v1": {
        kind: "buddies-who-study-media-blobs-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        blobs: [],
        privacy: emptyPrivacy
      },
      "study/card-media-refs/v1": {
        kind: "buddies-who-study-card-media-refs",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        refs: [],
        privacy: emptyPrivacy
      },
      "study/media-manifest/v1": {
        kind: "buddies-who-study-media-manifest",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        mediaCount: 0,
        totalBytes: 0,
        items: [],
        privacy: emptyPrivacy
      },
      "study/anki-media/v1": {
        kind: "buddies-who-study-anki-media-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        imports: [],
        items: [],
        privacy: emptyPrivacy
      },
      "study/anki-imports/v1": {
        kind: "buddies-who-study-anki-imports-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        imports: [],
        privacy: emptyPrivacy
      }
    };

    Object.keys(emptyDocs).forEach(function ensureDoc(key) {
      if (base.docs[key] === undefined || base.docs[key] === null) {
        base.docs[key] = emptyDocs[key];
      }
    });

    base.backupDocs = Object.keys(base.docs).sort();
    base.media = {
      manifestKey: "study/media-manifest/v1",
      blobsKey: "study/media-blobs/v1",
      refsKey: "study/card-media-refs/v1",
      count: 0,
      totalBytes: 0
    };

    return base;
  }

  const buildBackupPayloadBaseR12W = buildBackupPayload;
  buildBackupPayload = function buildBackupPayload(options) {
    return makeMediaAwareBackupPayloadR12W(buildBackupPayloadBaseR12W(options), options || {});
  };


  const api = Object.freeze({
    marker: MARKER,
    title: PANEL_TITLE,
    backupKind: BACKUP_KIND,
    backupVersion: BACKUP_VERSION,
    studyDocKeys: STUDY_DOC_KEYS.slice(),
    hasDirectoryPicker: hasDirectoryPicker,
    backupFileName: backupFileName,
    buildBackupPayload: buildBackupPayload,
    stringifyBackup: stringifyBackup,
    createDownloadUrl: createDownloadUrl,
    writeBackupToDirectoryHandle: writeBackupToDirectoryHandle,
    chooseFolderAndWriteBackup: chooseFolderAndWriteBackup,
    createPreviewModel: createPreviewModel,
    renderPreviewHtml: renderPreviewHtml,
    mountPanel: mountPanel
  });

  root.APC_PROFILE_LOCAL_BACKUPS_PANEL = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})();
/* APC_PROFILE_LOCAL_BACKUPS_PANEL_R12D_SOURCE_ONLY_END */
