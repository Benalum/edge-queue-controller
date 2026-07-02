/* APC_LOCAL_BACKUP_MEDIA_EXPORT_R12S_START */
(function attachLocalBackupMediaExport(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_MEDIA_EXPORT_R12S_SOURCE_ONLY";
  const EXPORT_ADAPTER_VERSION = 1;
  const BACKUP_KIND = "buddies-who-study-local-backup";

  const FALLBACK_PRIMARY_DOC_KEYS = Object.freeze([
    "study/cards/v1",
    "study/decks/v1",
    "study/progress/v1",
    "study/sessions/v1",
    "study/store-state/v1"
  ]);

  const FALLBACK_MEDIA_DOC_KEYS = Object.freeze([
    "study/media/v1",
    "study/media-blobs/v1",
    "study/card-media-refs/v1",
    "study/media-manifest/v1",
    "study/anki-media/v1",
    "study/anki-imports/v1"
  ]);

  function schemaApi() {
    return root && root.APC_LOCAL_BACKUP_MEDIA_SCHEMA ? root.APC_LOCAL_BACKUP_MEDIA_SCHEMA : null;
  }

  function vaultApi() {
    return root && root.APC_LOCAL_MEDIA_VAULT ? root.APC_LOCAL_MEDIA_VAULT : null;
  }

  function nowIso() {
    return new Date().toISOString();
  }

  function cloneJson(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function objectFromEntries(entries) {
    const out = {};
    entries.forEach(function assign(key) {
      out[key] = true;
    });
    return out;
  }

  function uniqueStrings(values) {
    const seen = objectFromEntries([]);
    const out = [];
    (values || []).forEach(function add(value) {
      const key = String(value);
      if (!seen[key]) {
        seen[key] = true;
        out.push(key);
      }
    });
    return out;
  }

  function primaryDocKeys() {
    const schema = schemaApi();
    return schema && Array.isArray(schema.primaryStudyDocKeys)
      ? schema.primaryStudyDocKeys.slice()
      : FALLBACK_PRIMARY_DOC_KEYS.slice();
  }

  function mediaDocKeys() {
    const schema = schemaApi();
    return schema && Array.isArray(schema.mediaDocKeys)
      ? schema.mediaDocKeys.slice()
      : FALLBACK_MEDIA_DOC_KEYS.slice();
  }

  function allBackupDocKeys() {
    return uniqueStrings(primaryDocKeys().concat(mediaDocKeys()));
  }

  function privacyFlags() {
    const schema = schemaApi();
    if (schema && typeof schema.privacyFlags === "function") {
      return schema.privacyFlags();
    }
    return {
      serverUpload: false,
      ankiSourceMutation: false,
      sourceMutation: false,
      localOnly: true,
      originalAnkiBytesIncluded: false
    };
  }

  function createEmptyMediaManifest(options) {
    const opts = options || {};
    const schema = schemaApi();
    if (schema && typeof schema.createEmptyMediaManifest === "function") {
      return schema.createEmptyMediaManifest(opts);
    }
    const createdAt = opts.createdAt || nowIso();
    return {
      kind: "buddies-who-study-media-manifest",
      version: 1,
      createdAt: createdAt,
      updatedAt: createdAt,
      mediaCount: 0,
      totalBytes: 0,
      items: [],
      privacy: privacyFlags()
    };
  }

  function createEmptyCardMediaRefs(options) {
    const opts = options || {};
    const schema = schemaApi();
    if (schema && typeof schema.createEmptyCardMediaRefs === "function") {
      return schema.createEmptyCardMediaRefs(opts);
    }
    const createdAt = opts.createdAt || nowIso();
    return {
      kind: "buddies-who-study-card-media-refs",
      version: 1,
      createdAt: createdAt,
      updatedAt: createdAt,
      refs: [],
      privacy: privacyFlags()
    };
  }

  function createEmptyMediaDoc(key, options) {
    const opts = options || {};
    const createdAt = opts.createdAt || nowIso();
    if (key === "study/media-manifest/v1") {
      return createEmptyMediaManifest({ createdAt: createdAt });
    }
    if (key === "study/card-media-refs/v1") {
      return createEmptyCardMediaRefs({ createdAt: createdAt });
    }
    if (key === "study/media/v1") {
      return {
        kind: "buddies-who-study-media-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        items: [],
        privacy: privacyFlags()
      };
    }
    if (key === "study/media-blobs/v1") {
      return {
        kind: "buddies-who-study-media-blobs-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        blobs: [],
        privacy: privacyFlags()
      };
    }
    if (key === "study/anki-media/v1") {
      return {
        kind: "buddies-who-study-anki-media-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        imports: [],
        items: [],
        privacy: privacyFlags()
      };
    }
    if (key === "study/anki-imports/v1") {
      return {
        kind: "buddies-who-study-anki-imports-index",
        version: 1,
        createdAt: createdAt,
        updatedAt: createdAt,
        imports: [],
        privacy: privacyFlags()
      };
    }
    return {
      kind: "buddies-who-study-empty-local-doc",
      version: 1,
      key: key,
      createdAt: createdAt,
      updatedAt: createdAt,
      privacy: privacyFlags()
    };
  }

  function ensureDocsObject(payload) {
    const next = payload && typeof payload === "object" ? cloneJson(payload) : {};
    if (!next.docs || typeof next.docs !== "object" || Array.isArray(next.docs)) {
      next.docs = {};
    }
    return next;
  }

  function existingDocKeys(payload) {
    if (!payload || !payload.docs || typeof payload.docs !== "object" || Array.isArray(payload.docs)) {
      return [];
    }
    return Object.keys(payload.docs);
  }

  function augmentBackupPayload(payload, options) {
    const opts = options || {};
    const createdAt = opts.createdAt || payload && payload.createdAt || nowIso();
    const next = ensureDocsObject(payload);
    const mediaKeys = mediaDocKeys();
    const allKeys = allBackupDocKeys();

    next.kind = next.kind || BACKUP_KIND;
    next.version = Math.max(Number(next.version || 1), 2);
    next.createdAt = next.createdAt || createdAt;
    next.label = next.label || "Buddies Who Study local data";
    next.privacy = Object.assign({}, privacyFlags(), next.privacy || {});

    mediaKeys.forEach(function ensureMediaDoc(key) {
      if (next.docs[key] === undefined || next.docs[key] === null) {
        next.docs[key] = createEmptyMediaDoc(key, { createdAt: createdAt });
      }
    });

    next.backupDocs = uniqueStrings((Array.isArray(next.backupDocs) ? next.backupDocs : existingDocKeys(next)).concat(allKeys));
    next.media = Object.assign({
      manifestKey: "study/media-manifest/v1",
      blobsKey: "study/media-blobs/v1",
      refsKey: "study/card-media-refs/v1",
      count: 0,
      totalBytes: 0
    }, next.media || {});

    next.media.count = Number(next.docs["study/media-manifest/v1"] && next.docs["study/media-manifest/v1"].mediaCount || next.media.count || 0);
    next.media.totalBytes = Number(next.docs["study/media-manifest/v1"] && next.docs["study/media-manifest/v1"].totalBytes || next.media.totalBytes || 0);

    return next;
  }

  function createEmptyMediaBackupPayload(options) {
    const opts = options || {};
    const schema = schemaApi();
    const createdAt = opts.createdAt || nowIso();
    const base = schema && typeof schema.createBackupManifest === "function"
      ? schema.createBackupManifest({ createdAt: createdAt, mediaCount: 0, totalMediaBytes: 0 })
      : {
          kind: BACKUP_KIND,
          version: 2,
          createdAt: createdAt,
          label: "Buddies Who Study local data",
          privacy: privacyFlags()
        };
    base.docs = {};
    return augmentBackupPayload(base, { createdAt: createdAt });
  }

  function validateAugmentedBackup(payload) {
    const errors = [];
    const warnings = [];
    const mediaKeys = mediaDocKeys();

    if (!payload || typeof payload !== "object") {
      errors.push("Backup payload must be an object.");
      return { ok: false, errors: errors, warnings: warnings };
    }

    if (!payload.docs || typeof payload.docs !== "object" || Array.isArray(payload.docs)) {
      errors.push("Backup payload docs must be an object.");
    }

    mediaKeys.forEach(function requireKey(key) {
      if (!payload.docs || payload.docs[key] === undefined) {
        errors.push("Missing media backup doc: " + key);
      }
    });

    if (!payload.privacy || payload.privacy.serverUpload !== false) {
      errors.push("Backup privacy.serverUpload must be false.");
    }

    if (payload.privacy && payload.privacy.ankiSourceMutation !== false) {
      errors.push("Backup privacy.ankiSourceMutation must be false.");
    }

    return { ok: errors.length === 0, errors: errors, warnings: warnings };
  }

  const api = Object.freeze({
    marker: MARKER,
    version: EXPORT_ADAPTER_VERSION,
    primaryDocKeys: primaryDocKeys,
    mediaDocKeys: mediaDocKeys,
    allBackupDocKeys: allBackupDocKeys,
    privacyFlags: privacyFlags,
    createEmptyMediaDoc: createEmptyMediaDoc,
    createEmptyMediaBackupPayload: createEmptyMediaBackupPayload,
    augmentBackupPayload: augmentBackupPayload,
    validateAugmentedBackup: validateAugmentedBackup,
    createEmptyMediaManifest: createEmptyMediaManifest,
    createEmptyCardMediaRefs: createEmptyCardMediaRefs,
    vaultEnabled: function vaultEnabled() {
      const vault = vaultApi();
      return Boolean(vault && vault.enabled === true);
    }
  });

  root.APC_LOCAL_BACKUP_MEDIA_EXPORT = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
/* APC_LOCAL_BACKUP_MEDIA_EXPORT_R12S_END */
