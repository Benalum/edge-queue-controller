/* APC_LOCAL_BACKUP_RESTORE_PREVIEW_R12T_START */
(function attachLocalBackupRestorePreview(root) {
  "use strict";

  const MARKER = "APC_LOCAL_BACKUP_RESTORE_PREVIEW_R12T_SOURCE_ONLY";
  const LEGACY_V1_COMPAT_MARKER_R12W = "APC_LOCAL_BACKUP_RESTORE_PREVIEW_LEGACY_V1_COMPAT_R12W";
  const VERSION = 1;
  const BACKUP_KIND = "buddies-who-study-local-backup";

  const FALLBACK_REQUIRED_DOC_KEYS = Object.freeze([
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

  function exportApi() {
    return root && root.APC_LOCAL_BACKUP_MEDIA_EXPORT ? root.APC_LOCAL_BACKUP_MEDIA_EXPORT : null;
  }

  function cloneJson(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function stringOrEmpty(value) {
    return value === undefined || value === null ? "" : String(value);
  }

  function requiredDocKeys() {
    const schema = schemaApi();
    return schema && Array.isArray(schema.primaryStudyDocKeys)
      ? schema.primaryStudyDocKeys.slice()
      : FALLBACK_REQUIRED_DOC_KEYS.slice();
  }

  function mediaDocKeys() {
    const exporter = exportApi();
    if (exporter && typeof exporter.mediaDocKeys === "function") {
      return exporter.mediaDocKeys();
    }
    const schema = schemaApi();
    return schema && Array.isArray(schema.mediaDocKeys)
      ? schema.mediaDocKeys.slice()
      : FALLBACK_MEDIA_DOC_KEYS.slice();
  }

  function parseBackupText(text) {
    if (typeof text !== "string") {
      throw new Error("Backup preview requires JSON text.");
    }
    if (!text.trim()) {
      throw new Error("Backup JSON text is empty.");
    }
    return JSON.parse(text);
  }

  function docsObject(payload) {
    if (!payload || payload.docs === undefined || payload.docs === null) {
      return {};
    }

    if (Array.isArray(payload.docs)) {
      const out = {};
      payload.docs.forEach(function copyLegacyDoc(entry) {
        if (!entry || !entry.key) return;
        out[String(entry.key)] = entry.value === undefined ? null : entry.value;
      });
      return out;
    }

    return typeof payload.docs === "object" ? payload.docs : {};
  }

  function normalizePrivacyR12W(privacy) {
    const source = privacy && typeof privacy === "object" ? privacy : {};
    return Object.assign({}, source, {
      serverUpload: source.serverUpload === false || source.uploadsToServer === false ? false : source.serverUpload,
      ankiSourceMutation: source.ankiSourceMutation === false || source.modifiesAnkiSourceFiles === false ? false : source.ankiSourceMutation,
      sourceMutation: source.sourceMutation === false || source.modifiesAnkiSourceFiles === false ? false : source.sourceMutation,
      localOnly: source.localOnly === true || source.uploadsToServer === false ? true : source.localOnly,
      originalAnkiBytesIncluded: source.originalAnkiBytesIncluded === false || source.includesAnkiSourceFileBytes === false ? false : source.originalAnkiBytesIncluded
    });
  }

  function listDocKeys(payload) {
    return Object.keys(docsObject(payload)).sort();
  }

  function docSizeEstimate(value) {
    try {
      return JSON.stringify(value).length;
    } catch (error) {
      return 0;
    }
  }

  function countArrayDoc(doc, names) {
    if (!doc || typeof doc !== "object") return 0;
    for (let i = 0; i < names.length; i += 1) {
      const name = names[i];
      if (Array.isArray(doc[name])) return doc[name].length;
    }
    if (Array.isArray(doc)) return doc.length;
    return 0;
  }

  function summarizeStudyDocs(payload) {
    const docs = docsObject(payload);
    return {
      decks: countArrayDoc(docs["study/decks/v1"], ["decks", "items", "records"]),
      cards: countArrayDoc(docs["study/cards/v1"], ["cards", "items", "records"]),
      progress: countArrayDoc(docs["study/progress/v1"], ["progress", "items", "records"]),
      sessions: countArrayDoc(docs["study/sessions/v1"], ["sessions", "items", "records"]),
      docBytesApprox: listDocKeys(payload).reduce(function sum(total, key) {
        return total + docSizeEstimate(docs[key]);
      }, 0)
    };
  }

  function summarizeMediaDocs(payload) {
    const docs = docsObject(payload);
    const manifest = docs["study/media-manifest/v1"] || {};
    const cardRefs = docs["study/card-media-refs/v1"] || {};
    const ankiMedia = docs["study/anki-media/v1"] || {};
    const mediaIndex = docs["study/media/v1"] || {};
    const mediaBlobs = docs["study/media-blobs/v1"] || {};

    return {
      mediaCount: Number(manifest.mediaCount || countArrayDoc(manifest, ["items"])),
      totalBytes: Number(manifest.totalBytes || 0),
      manifestItems: countArrayDoc(manifest, ["items"]),
      cardMediaRefs: countArrayDoc(cardRefs, ["refs", "items"]),
      ankiMediaItems: countArrayDoc(ankiMedia, ["items", "imports"]),
      mediaIndexItems: countArrayDoc(mediaIndex, ["items"]),
      mediaBlobRefs: countArrayDoc(mediaBlobs, ["blobs", "items"])
    };
  }

  function validatePrivacy(payload) {
    const errors = [];
    const warnings = [];
    const privacy = normalizePrivacyR12W(payload && payload.privacy ? payload.privacy : {});

    if (privacy.serverUpload !== false) {
      errors.push("Backup privacy.serverUpload must be false.");
    }
    if (privacy.ankiSourceMutation !== false) {
      errors.push("Backup privacy.ankiSourceMutation must be false.");
    }
    if (privacy.sourceMutation !== false && privacy.sourceMutation !== undefined) {
      errors.push("Backup privacy.sourceMutation must be false when present.");
    }
    if (privacy.localOnly !== true && privacy.localOnly !== undefined) {
      warnings.push("Backup privacy.localOnly is not explicitly true.");
    }

    return { errors: errors, warnings: warnings };
  }

  function validateRequiredDocs(payload, options) {
    const opts = options || {};
    const docs = docsObject(payload);
    const errors = [];
    const warnings = [];
    const required = opts.requirePrimaryDocs === false ? [] : requiredDocKeys();
    const mediaRequired = opts.requireMediaDocs === false ? [] : mediaDocKeys();

    required.forEach(function requireDoc(key) {
      if (docs[key] === undefined || docs[key] === null) {
        warnings.push("Missing primary Study doc: " + key);
      }
    });

    mediaRequired.forEach(function requireMediaDoc(key) {
      if (docs[key] === undefined || docs[key] === null) {
        warnings.push("Missing media doc: " + key);
      }
    });

    return { errors: errors, warnings: warnings };
  }

  function validateWithSchemaAndExporter(payload) {
    const errors = [];
    const warnings = [];
    const schema = schemaApi();
    const exporter = exportApi();

    if (schema && typeof schema.validateBackupEnvelope === "function") {
      const result = schema.validateBackupEnvelope(payload);
      (result.errors || []).forEach(function add(error) { errors.push(error); });
      (result.warnings || []).forEach(function add(warning) { warnings.push(warning); });
    }

    if (exporter && typeof exporter.validateAugmentedBackup === "function") {
      const result = exporter.validateAugmentedBackup(payload);
      (result.errors || []).forEach(function add(error) {
        if (String(error).indexOf("Missing media backup doc:") === 0) {
          warnings.push(error);
        } else {
          errors.push(error);
        }
      });
      (result.warnings || []).forEach(function add(warning) { warnings.push(warning); });
    }

    return { errors: errors, warnings: warnings };
  }

  function createRestorePreview(payload, options) {
    const opts = options || {};
    const errors = [];
    const warnings = [];

    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      return {
        ok: false,
        canWrite: false,
        marker: MARKER,
        errors: ["Backup payload must be an object."],
        warnings: [],
        summary: {}
      };
    }

    const copy = cloneJson(payload);

    if (copy.kind !== BACKUP_KIND) {
      errors.push("Backup kind is not recognized.");
    }

    copy.docs = docsObject(copy);
    copy.privacy = normalizePrivacyR12W(copy.privacy);

    if (!copy.docs || typeof copy.docs !== "object" || Array.isArray(copy.docs)) {
      errors.push("Backup docs must be an object or legacy docs array.");
    }

    const privacyResult = validatePrivacy(copy);
    privacyResult.errors.forEach(function add(error) { errors.push(error); });
    privacyResult.warnings.forEach(function add(warning) { warnings.push(warning); });

    const requiredResult = validateRequiredDocs(copy, opts);
    requiredResult.errors.forEach(function add(error) { errors.push(error); });
    requiredResult.warnings.forEach(function add(warning) { warnings.push(warning); });

    const sourceResult = validateWithSchemaAndExporter(copy);
    sourceResult.errors.forEach(function add(error) { errors.push(error); });
    sourceResult.warnings.forEach(function add(warning) { warnings.push(warning); });

    const docKeys = listDocKeys(copy);
    const studySummary = summarizeStudyDocs(copy);
    const mediaSummary = summarizeMediaDocs(copy);

    return {
      ok: errors.length === 0,
      canWrite: false,
      marker: MARKER,
      version: VERSION,
      backupKind: stringOrEmpty(copy.kind),
      backupVersion: Number(copy.version || 0),
      createdAt: stringOrEmpty(copy.createdAt),
      label: stringOrEmpty(copy.label),
      docKeys: docKeys,
      docCount: docKeys.length,
      requiredDocKeys: requiredDocKeys(),
      mediaDocKeys: mediaDocKeys(),
      summary: {
        study: studySummary,
        media: mediaSummary,
        approximateBytes: studySummary.docBytesApprox
      },
      privacy: copy.privacy || {},
      errors: errors,
      warnings: warnings,
      restorePlan: {
        writesEnabled: false,
        writeMode: "preview-only",
        requiresExplicitConfirmation: true,
        overwriteExistingLocalData: false
      }
    };
  }

  function previewBackupText(text, options) {
    try {
      return createRestorePreview(parseBackupText(text), options);
    } catch (error) {
      return {
        ok: false,
        canWrite: false,
        marker: MARKER,
        errors: [error && error.message ? error.message : String(error)],
        warnings: [],
        summary: {},
        restorePlan: {
          writesEnabled: false,
          writeMode: "preview-only",
          requiresExplicitConfirmation: true,
          overwriteExistingLocalData: false
        }
      };
    }
  }

  function assertPreviewOnly(preview) {
    if (!preview || preview.canWrite !== false) {
      throw new Error("Restore preview must not allow writes.");
    }
    if (!preview.restorePlan || preview.restorePlan.writesEnabled !== false) {
      throw new Error("Restore preview write plan must remain disabled.");
    }
    return true;
  }

  const api = Object.freeze({
    marker: MARKER,
    version: VERSION,
    parseBackupText: parseBackupText,
    createRestorePreview: createRestorePreview,
    previewBackupText: previewBackupText,
    assertPreviewOnly: assertPreviewOnly,
    summarizeStudyDocs: summarizeStudyDocs,
    summarizeMediaDocs: summarizeMediaDocs,
    requiredDocKeys: requiredDocKeys,
    mediaDocKeys: mediaDocKeys
  });

  root.APC_LOCAL_BACKUP_RESTORE_PREVIEW = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
/* APC_LOCAL_BACKUP_RESTORE_PREVIEW_R12T_END */
