/* APC_LOCAL_MEDIA_VAULT_R12R_START */
(function attachLocalMediaVault(root) {
  "use strict";

  const MARKER = "APC_LOCAL_MEDIA_VAULT_R12R_DISABLED_SOURCE_ONLY";
  const ENABLED = false;
  const DEFAULT_MAX_BYTES = 25 * 1024 * 1024;
  const DEFAULT_SOURCE_TYPE = "bws-local";

  const IMAGE_MIME_TYPES = Object.freeze([
    "image/png",
    "image/jpeg",
    "image/gif",
    "image/webp",
    "image/svg+xml"
  ]);

  const IMAGE_EXTENSIONS = Object.freeze([
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".webp",
    ".svg"
  ]);

  function schemaApi() {
    return root && root.APC_LOCAL_BACKUP_MEDIA_SCHEMA ? root.APC_LOCAL_BACKUP_MEDIA_SCHEMA : null;
  }

  function stringOrEmpty(value) {
    return value === undefined || value === null ? "" : String(value);
  }

  function safeFilename(value) {
    const raw = stringOrEmpty(value).trim();
    const cleaned = raw
      .replace(/[\\/:*?"<>|]+/g, "-")
      .replace(/\s+/g, " ")
      .replace(/^\.+/, "")
      .trim();
    return cleaned || "media";
  }

  function lowerFilename(value) {
    return safeFilename(value).toLowerCase();
  }

  function extensionFromFilename(value) {
    const name = lowerFilename(value);
    const index = name.lastIndexOf(".");
    return index >= 0 ? name.slice(index) : "";
  }

  function mediaKindFromMime(mimeType) {
    const value = stringOrEmpty(mimeType).toLowerCase();
    if (value.indexOf("image/") === 0) return "image";
    if (value.indexOf("audio/") === 0) return "audio";
    if (value.indexOf("video/") === 0) return "video";
    return "unknown";
  }

  function isImageFileLike(file) {
    const mime = stringOrEmpty(file && file.type).toLowerCase();
    const ext = extensionFromFilename(file && file.name);
    return IMAGE_MIME_TYPES.indexOf(mime) >= 0 || IMAGE_EXTENSIONS.indexOf(ext) >= 0;
  }

  function requireExplicitUserAction(options) {
    const opts = options || {};
    if (opts.explicitUserAction !== true) {
      throw new Error("Local media vault requires explicit user action.");
    }
  }

  function validateMediaFile(file, options) {
    const opts = options || {};
    const errors = [];
    const warnings = [];
    const maxBytes = Number(opts.maxBytes || DEFAULT_MAX_BYTES);
    const imagesOnly = opts.imagesOnly !== false;

    if (!file || typeof file !== "object") {
      errors.push("Media file is required.");
      return { ok: false, errors: errors, warnings: warnings };
    }

    if (!stringOrEmpty(file.name)) {
      warnings.push("Media file has no filename.");
    }

    if (Number(file.size || 0) <= 0) {
      errors.push("Media file is empty.");
    }

    if (Number(file.size || 0) > maxBytes) {
      errors.push("Media file is larger than the allowed local limit.");
    }

    if (imagesOnly && !isImageFileLike(file)) {
      errors.push("Only image files are supported in this first local media vault stage.");
    }

    return { ok: errors.length === 0, errors: errors, warnings: warnings };
  }

  function bytesToHex(bytes) {
    return Array.prototype.map.call(bytes, function toHex(byte) {
      return byte.toString(16).padStart(2, "0");
    }).join("");
  }

  async function digestBlobSha256(file, options) {
    requireExplicitUserAction(options);

    if (!file || typeof file.arrayBuffer !== "function") {
      throw new Error("Media file does not support arrayBuffer.");
    }

    if (!root.crypto || !root.crypto.subtle || typeof root.crypto.subtle.digest !== "function") {
      throw new Error("Browser crypto digest is not available.");
    }

    const buffer = await file.arrayBuffer();
    const digest = await root.crypto.subtle.digest("SHA-256", buffer);
    return bytesToHex(new Uint8Array(digest));
  }

  function buildMediaId(input) {
    const value = input || {};
    const sha = stringOrEmpty(value.sha256).trim();
    if (sha) return "media-sha256-" + sha;
    const name = safeFilename(value.originalFilename || value.name || "media");
    const size = Number(value.sizeBytes || value.size || 0);
    return "media-local-" + name.toLowerCase().replace(/[^a-z0-9]+/g, "-") + "-" + size;
  }

  function fallbackNormalizeMediaItem(item) {
    const input = item || {};
    const mimeType = stringOrEmpty(input.mimeType);
    return {
      id: stringOrEmpty(input.id),
      sourceType: stringOrEmpty(input.sourceType || DEFAULT_SOURCE_TYPE),
      sourceId: stringOrEmpty(input.sourceId),
      originalFilename: stringOrEmpty(input.originalFilename),
      safeFilename: safeFilename(input.safeFilename || input.originalFilename),
      mimeType: mimeType,
      kind: stringOrEmpty(input.kind || mediaKindFromMime(mimeType)),
      sizeBytes: Number(input.sizeBytes || 0),
      sha256: stringOrEmpty(input.sha256),
      createdAt: stringOrEmpty(input.createdAt || new Date().toISOString()),
      updatedAt: stringOrEmpty(input.updatedAt || input.createdAt || new Date().toISOString()),
      blobRef: stringOrEmpty(input.blobRef),
      objectUrl: "",
      ankiMediaName: stringOrEmpty(input.ankiMediaName),
      ankiMediaOrdinal: input.ankiMediaOrdinal === undefined || input.ankiMediaOrdinal === null ? null : String(input.ankiMediaOrdinal),
      status: stringOrEmpty(input.status || "available")
    };
  }

  function normalizeMediaItem(item) {
    const schema = schemaApi();
    if (schema && typeof schema.normalizeMediaItem === "function") {
      return schema.normalizeMediaItem(item);
    }
    return fallbackNormalizeMediaItem(item);
  }

  function fallbackNormalizeCardMediaRef(ref) {
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

  function normalizeCardMediaRef(ref) {
    const schema = schemaApi();
    if (schema && typeof schema.normalizeCardMediaRef === "function") {
      return schema.normalizeCardMediaRef(ref);
    }
    return fallbackNormalizeCardMediaRef(ref);
  }

  async function createImageMediaRecordFromFile(file, options) {
    requireExplicitUserAction(options);

    const validation = validateMediaFile(file, options);
    if (!validation.ok) {
      throw new Error(validation.errors.join(" "));
    }

    const sha256 = await digestBlobSha256(file, options);
    const originalFilename = stringOrEmpty(file.name);
    const id = buildMediaId({ sha256: sha256, originalFilename: originalFilename, sizeBytes: file.size });

    return normalizeMediaItem({
      id: id,
      sourceType: stringOrEmpty(options && options.sourceType) || DEFAULT_SOURCE_TYPE,
      sourceId: stringOrEmpty(options && options.sourceId),
      originalFilename: originalFilename,
      safeFilename: safeFilename(originalFilename),
      mimeType: stringOrEmpty(file.type),
      kind: "image",
      sizeBytes: Number(file.size || 0),
      sha256: sha256,
      blobRef: "browser-local-disabled-r12r:" + id,
      status: "available"
    });
  }

  function createCardMediaRef(input) {
    return normalizeCardMediaRef(input);
  }

  function createEmptyVaultState(options) {
    const opts = options || {};
    const schema = schemaApi();
    const createdAt = opts.createdAt || new Date().toISOString();

    return {
      kind: "buddies-who-study-local-media-vault-state",
      version: 1,
      enabled: ENABLED,
      createdAt: createdAt,
      mediaManifest: schema && typeof schema.createEmptyMediaManifest === "function"
        ? schema.createEmptyMediaManifest({ createdAt: createdAt })
        : {
            kind: "buddies-who-study-media-manifest",
            version: 1,
            createdAt: createdAt,
            updatedAt: createdAt,
            mediaCount: 0,
            totalBytes: 0,
            items: [],
            privacy: { serverUpload: false, ankiSourceMutation: false, sourceMutation: false, localOnly: true }
          },
      cardMediaRefs: schema && typeof schema.createEmptyCardMediaRefs === "function"
        ? schema.createEmptyCardMediaRefs({ createdAt: createdAt })
        : {
            kind: "buddies-who-study-card-media-refs",
            version: 1,
            createdAt: createdAt,
            updatedAt: createdAt,
            refs: [],
            privacy: { serverUpload: false, ankiSourceMutation: false, sourceMutation: false, localOnly: true }
          }
    };
  }

  function addMediaRecordToManifest(manifest, record) {
    const base = manifest && typeof manifest === "object" ? manifest : createEmptyVaultState().mediaManifest;
    const item = normalizeMediaItem(record);
    const items = Array.isArray(base.items) ? base.items.slice() : [];
    items.push(item);

    return Object.assign({}, base, {
      updatedAt: new Date().toISOString(),
      mediaCount: items.length,
      totalBytes: items.reduce(function sumBytes(total, current) {
        return total + Number(current && current.sizeBytes || 0);
      }, 0),
      items: items
    });
  }

  function addCardMediaRef(refDoc, ref) {
    const base = refDoc && typeof refDoc === "object" ? refDoc : createEmptyVaultState().cardMediaRefs;
    const refs = Array.isArray(base.refs) ? base.refs.slice() : [];
    refs.push(normalizeCardMediaRef(ref));

    return Object.assign({}, base, {
      updatedAt: new Date().toISOString(),
      refs: refs
    });
  }

  function disabledPersistenceError() {
    return Promise.reject(new Error("R12R local media vault is source-only and does not persist media blobs."));
  }

  const api = Object.freeze({
    marker: MARKER,
    enabled: ENABLED,
    defaultMaxBytes: DEFAULT_MAX_BYTES,
    imageMimeTypes: IMAGE_MIME_TYPES,
    imageExtensions: IMAGE_EXTENSIONS,
    safeFilename: safeFilename,
    extensionFromFilename: extensionFromFilename,
    mediaKindFromMime: mediaKindFromMime,
    isImageFileLike: isImageFileLike,
    validateMediaFile: validateMediaFile,
    buildMediaId: buildMediaId,
    digestBlobSha256: digestBlobSha256,
    createImageMediaRecordFromFile: createImageMediaRecordFromFile,
    createCardMediaRef: createCardMediaRef,
    createEmptyVaultState: createEmptyVaultState,
    addMediaRecordToManifest: addMediaRecordToManifest,
    addCardMediaRef: addCardMediaRef,
    storeMediaBlob: disabledPersistenceError,
    loadMediaBlob: disabledPersistenceError,
    deleteMediaBlob: disabledPersistenceError
  });

  root.APC_LOCAL_MEDIA_VAULT = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof window !== "undefined" ? window : globalThis);
/* APC_LOCAL_MEDIA_VAULT_R12R_END */
