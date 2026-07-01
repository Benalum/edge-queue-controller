/* APC_LOCAL_BACKUP_MEDIA_SCHEMA_R12Q_START */
(function attachLocalBackupMediaSchema(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_MEDIA_SCHEMA_R12Q";
  const BACKUP_KIND = "buddies-who-study-local-backup";
  const BACKUP_SCHEMA_VERSION = 2;
  const MEDIA_SCHEMA_VERSION = 1;

  const PRIMARY_STUDY_DOC_KEYS = Object.freeze([
    "study/cards/v1",
    "study/decks/v1",
    "study/progress/v1",
    "study/sessions/v1",
    "study/store-state/v1"
  ]);

  const MEDIA_DOC_KEYS = Object.freeze([
    "study/media/v1",
    "study/media-blobs/v1",
    "study/card-media-refs/v1",
    "study/media-manifest/v1",
    "study/anki-media/v1",
    "study/anki-imports/v1"
  ]);

  const ALL_BACKUP_DOC_KEYS = Object.freeze(PRIMARY_STUDY_DOC_KEYS.concat(MEDIA_DOC_KEYS));

  function nowIso() {
    return new Date().toISOString();
  }

  function stringOrEmpty(value) {
    return value === undefined || value === null ? "" : String(value);
  }

  function safeFilename(value) {
    const raw = stringOrEmpty(value).trim();
    const fallback = "media";
    const cleaned = raw
      .replace(/[\\/:*?"<>|]+/g, "-")
      .replace(/\s+/g, " ")
      .replace(/^\.+/, "")
      .trim();
    return cleaned || fallback;
  }

  function mediaKindFromMime(mimeType) {
    const value = stringOrEmpty(mimeType).toLowerCase();
    if (value.indexOf("image/") === 0) return "image";
    if (value.indexOf("audio/") === 0) return "audio";
    if (value.indexOf("video/") === 0) return "video";
    return "unknown";
  }

  function privacyFlags() {
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
    return {
      kind: "buddies-who-study-media-manifest",
      version: MEDIA_SCHEMA_VERSION,
      createdAt: opts.createdAt || nowIso(),
      updatedAt: opts.updatedAt || opts.createdAt || nowIso(),
      mediaCount: 0,
      totalBytes: 0,
      items: [],
      privacy: privacyFlags()
    };
  }

  function createEmptyCardMediaRefs(options) {
    const opts = options || {};
    return {
      kind: "buddies-who-study-card-media-refs",
      version: MEDIA_SCHEMA_VERSION,
      createdAt: opts.createdAt || nowIso(),
      updatedAt: opts.updatedAt || opts.createdAt || nowIso(),
      refs: [],
      privacy: privacyFlags()
    };
  }

  function createBackupManifest(options) {
    const opts = options || {};
    const docs = Array.isArray(opts.docs) && opts.docs.length ? opts.docs.slice() : ALL_BACKUP_DOC_KEYS.slice();
    return {
      kind: BACKUP_KIND,
      version: BACKUP_SCHEMA_VERSION,
      mediaSchemaVersion: MEDIA_SCHEMA_VERSION,
      createdAt: opts.createdAt || nowIso(),
      label: opts.label || "Buddies Who Study local data",
      docs: docs,
      media: {
        manifestKey: "study/media-manifest/v1",
        blobsKey: "study/media-blobs/v1",
        count: Number(opts.mediaCount || 0),
        totalBytes: Number(opts.totalMediaBytes || 0)
      },
      privacy: privacyFlags()
    };
  }

  function normalizeMediaItem(item) {
    const input = item || {};
    const mimeType = stringOrEmpty(input.mimeType);
    return {
      id: stringOrEmpty(input.id),
      sourceType: stringOrEmpty(input.sourceType || "bws-local"),
      sourceId: stringOrEmpty(input.sourceId),
      originalFilename: stringOrEmpty(input.originalFilename),
      safeFilename: safeFilename(input.safeFilename || input.originalFilename),
      mimeType: mimeType,
      kind: stringOrEmpty(input.kind || mediaKindFromMime(mimeType)),
      sizeBytes: Number(input.sizeBytes || 0),
      sha256: stringOrEmpty(input.sha256),
      createdAt: stringOrEmpty(input.createdAt || nowIso()),
      updatedAt: stringOrEmpty(input.updatedAt || input.createdAt || nowIso()),
      blobRef: stringOrEmpty(input.blobRef),
      objectUrl: "",
      ankiMediaName: stringOrEmpty(input.ankiMediaName),
      ankiMediaOrdinal: input.ankiMediaOrdinal === undefined || input.ankiMediaOrdinal === null ? null : String(input.ankiMediaOrdinal),
      status: stringOrEmpty(input.status || "available")
    };
  }

  function normalizeCardMediaRef(ref) {
    const input = ref || {};
    return {
      mediaId: stringOrEmpty(input.mediaId),
      cardId: stringOrEmpty(input.cardId),
      slot: stringOrEmpty(input.slot || "front"),
      role: stringOrEmpty(input.role || "inline"),
      alt: stringOrEmpty(input.alt),
      caption: stringOrEmpty(input.caption),
      sourceHtmlRef: stringOrEmpty(input.sourceHtmlRef),
      order: Number(input.order || 0)
    };
  }

  function validateBackupEnvelope(payload) {
    const errors = [];
    const warnings = [];

    if (!payload || typeof payload !== "object") {
      errors.push("Backup payload must be an object.");
      return { ok: false, errors: errors, warnings: warnings };
    }

    if (payload.kind !== BACKUP_KIND) {
      errors.push("Backup kind is not recognized.");
    }

    if (payload.version !== BACKUP_SCHEMA_VERSION && payload.version !== 1) {
      warnings.push("Backup version is not the current schema version.");
    }

    if (!payload.privacy || payload.privacy.serverUpload !== false) {
      errors.push("Backup privacy.serverUpload must be false.");
    }

    if (payload.privacy && payload.privacy.ankiSourceMutation !== false) {
      errors.push("Backup privacy.ankiSourceMutation must be false.");
    }

    return { ok: errors.length === 0, errors: errors, warnings: warnings };
  }

  function validateMediaManifest(manifest) {
    const errors = [];
    const warnings = [];

    if (!manifest || typeof manifest !== "object") {
      errors.push("Media manifest must be an object.");
      return { ok: false, errors: errors, warnings: warnings };
    }

    if (manifest.kind !== "buddies-who-study-media-manifest") {
      errors.push("Media manifest kind is not recognized.");
    }

    if (!Array.isArray(manifest.items)) {
      errors.push("Media manifest items must be an array.");
    }

    if (manifest.privacy && manifest.privacy.serverUpload !== false) {
      errors.push("Media manifest privacy.serverUpload must be false.");
    }

    return { ok: errors.length === 0, errors: errors, warnings: warnings };
  }

  function validateCardMediaRefs(doc) {
    const errors = [];
    const warnings = [];

    if (!doc || typeof doc !== "object") {
      errors.push("Card media refs document must be an object.");
      return { ok: false, errors: errors, warnings: warnings };
    }

    if (doc.kind !== "buddies-who-study-card-media-refs") {
      errors.push("Card media refs kind is not recognized.");
    }

    if (!Array.isArray(doc.refs)) {
      errors.push("Card media refs must be an array.");
    }

    return { ok: errors.length === 0, errors: errors, warnings: warnings };
  }

  const api = Object.freeze({
    marker: MARKER,
    backupKind: BACKUP_KIND,
    backupSchemaVersion: BACKUP_SCHEMA_VERSION,
    mediaSchemaVersion: MEDIA_SCHEMA_VERSION,
    primaryStudyDocKeys: PRIMARY_STUDY_DOC_KEYS,
    mediaDocKeys: MEDIA_DOC_KEYS,
    allBackupDocKeys: ALL_BACKUP_DOC_KEYS,
    privacyFlags: privacyFlags,
    safeFilename: safeFilename,
    mediaKindFromMime: mediaKindFromMime,
    createBackupManifest: createBackupManifest,
    createEmptyMediaManifest: createEmptyMediaManifest,
    createEmptyCardMediaRefs: createEmptyCardMediaRefs,
    normalizeMediaItem: normalizeMediaItem,
    normalizeCardMediaRef: normalizeCardMediaRef,
    validateBackupEnvelope: validateBackupEnvelope,
    validateMediaManifest: validateMediaManifest,
    validateCardMediaRefs: validateCardMediaRefs
  });

  root.APC_LOCAL_BACKUP_MEDIA_SCHEMA = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
/* APC_LOCAL_BACKUP_MEDIA_SCHEMA_R12Q_END */
